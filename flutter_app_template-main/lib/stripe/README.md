# stripe/

## Why it exists

Payments behind the `PaymentService` interface, so no screen ever names a
payment provider.

## The security model — read this first

**The Stripe secret key must never be in the app.** A mobile binary is public;
anything compiled into it can be extracted. The flow is therefore:

```
app  ──► your backend  ──► Stripe (secret key)
     ◄── client secret ◄──
app  ──► confirm with the client secret
Stripe ──► webhook ──► your backend  ──► grants the entitlement
```

The client secret is single-use and safe to hold; the secret key is not. And a
client-reported "payment succeeded" is a claim, not proof — **grant paid
features from the webhook**, never from the app's return value.

## What belongs here

| File | Purpose |
| --- | --- |
| `payment_service.dart` | Provider-agnostic interface |
| `stripe_payment_service.dart` | Backend-first implementation |
| `payment_intent.dart` | `PaymentIntentModel`, `PaymentRequest` |

## Why there is no `flutter_stripe` dependency

The architecture is identical whether confirmation happens in Stripe's native
`PaymentSheet` or a hosted Checkout page. The template ships the part that never
changes, so the project builds on every platform with no Gradle or CocoaPods
setup on day one. `stripe_payment_service.dart` documents exactly the three
places to edit when you add the SDK — nothing above the interface changes.

## Naming conventions

- Amounts are always **minor units** (integer cents) and named accordingly:
  `amountMinorUnits`. This is the single most effective guard against a 100×
  pricing bug.
- Stripe's status strings are mapped to `PaymentStatus` at the boundary.

## Example usage

```dart
final result = await paymentService.checkout(
  const PaymentRequest(
    amountMinorUnits: 1999,
    currency: 'USD',
    productId: 'pro_monthly',
  ),
);
result.when(
  success: (intent) => showPending(intent.status),
  failure: (error) => showError(error),
);
```

## Best practices

- The backend must recompute the price from its own data. A client that names
  its own price will eventually be asked to pay one cent.
- Never log a client secret or any card data.
- Handle `requiresAction` (3-D Secure): call `refreshStatus` when the app
  resumes rather than assuming failure.
- Guard on `isAvailable` so an unconfigured build fails with a clear message
  instead of a confusing network error.

Full checklist: `docs/integrations/stripe.md`.
