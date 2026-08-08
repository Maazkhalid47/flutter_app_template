# Stripe integration

## The security model — read this before writing any code

**The secret key never goes in the app.** A mobile binary is public; anything
compiled into it can be extracted in minutes.

```
app  ──► your backend ──► Stripe        (secret key lives here, only here)
     ◄── client_secret ◄──
app  ──► confirm using the client secret
Stripe ──► webhook ──► your backend ──► grants the entitlement
```

Two rules follow from this:

1. The **backend recomputes the price** from its own data. A client that names
   its own price will eventually be asked to pay one cent.
2. **Entitlements are granted by the webhook**, never by the app's return
   value. A client saying "payment succeeded" is a claim, not proof.

## What the template provides

| File | Role |
| --- | --- |
| `stripe/payment_service.dart` | Provider-agnostic interface |
| `stripe/stripe_payment_service.dart` | Backend-first implementation |
| `stripe/payment_intent.dart` | `PaymentIntentModel`, `PaymentRequest` |
| `enums/payment_status.dart` | Stripe statuses mapped to app vocabulary |

There is no `flutter_stripe` dependency yet — see below for why, and how to add
it.

## 1. Configure

```json
{
  "STRIPE_PUBLISHABLE_KEY": "pk_test_...",
  "STRIPE_MERCHANT_ID": "merchant.com.yourcompany.app"
}
```

Only the **publishable** key. `paymentService.isAvailable` is false without it,
and calls fail with a clear `PaymentException` instead of a confusing network
error.

## 2. Backend endpoints

The app expects two, defined in `constants/api_constants.dart`:

```
POST /payments/intent    → { id, client_secret, amount, currency, status }
POST /payments/confirm   → { id, status, ... }
GET  /payments/intent/:id → { id, status, ... }
```

A Supabase Edge Function is a good home for these:

```ts
// supabase/functions/create-payment-intent/index.ts
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

// Price comes from YOUR database, not from the request body.
const price = await priceFor(body.product_id);

const intent = await stripe.paymentIntents.create({
  amount: price,
  currency: 'usd',
  automatic_payment_methods: { enabled: true },
  metadata: { user_id: user.id, product_id: body.product_id },
});

return Response.json({
  id: intent.id,
  client_secret: intent.client_secret,
  amount: intent.amount,
  currency: intent.currency,
  status: intent.status,
});
```

## 3. Call it from the app

```dart
final result = await paymentService.checkout(
  const PaymentRequest(
    amountMinorUnits: 1999,        // display + sanity check only
    currency: 'USD',
    productId: 'pro_monthly',
  ),
);

result.when(
  success: (intent) => switch (intent.status) {
    PaymentStatus.succeeded      => showPendingActivation(),
    PaymentStatus.requiresAction => awaitThreeDSecure(intent),
    _                            => showFailure(),
  },
  failure: (error) => FeedbackHelper.showError(context, error),
);
```

Note `showPendingActivation()` rather than "unlocked" — the webhook grants the
entitlement, and the app polls or refreshes to see it.

## 4. The webhook (the part that matters)

```ts
const event = stripe.webhooks.constructEvent(
  rawBody,
  signature,
  Deno.env.get('STRIPE_WEBHOOK_SECRET')!,   // verify, always
);

switch (event.type) {
  case 'payment_intent.succeeded':
    await grantEntitlement(event.data.object.metadata.user_id);
    break;
  case 'payment_intent.payment_failed':
    await recordFailure(event.data.object);
    break;
}
```

Verify the signature on every webhook, and make the handler idempotent —
Stripe retries, and you will receive duplicates.

## Adding the native payment sheet

The template deliberately ships without `flutter_stripe`, so the project builds
on every platform with no Gradle or CocoaPods work on day one. The architecture
is identical either way. To add it:

1. `flutter pub add flutter_stripe`, then follow its Android/iOS setup
   (Android `minSdkVersion` 21+, Kotlin version, `Theme.AppCompat` activity).
2. In `StripePaymentService.initialize`, set `Stripe.publishableKey` and
   `Stripe.merchantIdentifier` from `AppConfig`.
3. In `confirmPayment`, replace `_confirmOnBackend` with
   `Stripe.instance.initPaymentSheet(...)` + `presentPaymentSheet()`.

Nothing above the `PaymentService` interface changes.

## Testing

Test card `4242 4242 4242 4242`, any future expiry, any CVC.
3-D Secure: `4000 0025 0000 3155`. Decline: `4000 0000 0000 9995`.

Forward webhooks locally with `stripe listen --forward-to <url>`.

## Production checklist

- [ ] Live publishable key in `env/prod.json`; secret key only on the backend
- [ ] Webhook signature verification enabled
- [ ] Webhook handler idempotent
- [ ] Prices computed server-side
- [ ] Amounts in minor units end to end
- [ ] No client secret or card data in any log
- [ ] `requiresAction` / 3-D Secure path tested on a real device
- [ ] Refund and dispute flows agreed with the backend
