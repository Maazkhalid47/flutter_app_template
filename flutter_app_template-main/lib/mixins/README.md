# mixins/

## Why it exists

Behaviour shared across classes that cannot share a base class — a `State`
subclass already extends `State`, a view model already extends
`BaseViewModel`. Mixins add the missing behaviour without a second inheritance
chain.

## What belongs here

| File | Mixed into | Provides |
| --- | --- | --- |
| `form_validation_mixin.dart` | `State<T>` | Form key, deferred autovalidate, `fieldValidator` |
| `subscription_mixin.dart` | `ChangeNotifier` | Tracked subscriptions/timers, auto-cancelled |

## What does NOT belong here

- Anything used by exactly one class — put it in that class.
- Stateless helpers (→ `utils/`) or extensions (→ `extensions/`).
- Business logic. A mixin that knows your domain is a hidden dependency.

## Naming conventions

- `<Behaviour>Mixin`, always constrained with `on`:
  `mixin SubscriptionMixin on ChangeNotifier`. The constraint is what lets the
  mixin call `notifyListeners` and override `dispose` safely.

## Example usage

```dart
class _LoginViewState extends State<LoginView> with FormValidationMixin {
  void _submit() {
    if (!validateForm()) return;   // switches to live validation after a fail
    context.read<AuthViewModel>().signIn(...);
  }

  // formKey and autovalidateMode come from the mixin
}
```

```dart
class OrdersViewModel extends BaseViewModel with SubscriptionMixin {
  OrdersViewModel(this._repo) {
    listenTo(_repo.orderStream, _onOrders);   // cancelled automatically
  }
}
```

## Best practices

- Always call `super.dispose()` last when a mixin overrides `dispose`. Mixin
  order determines the chain; getting it wrong leaks the very thing the mixin
  exists to clean up.
- `FormValidationMixin` deliberately keeps validation quiet until the first
  failed submit — validating on the first keystroke is hostile.
- Register every stream with `listenTo`. A subscription you hold yourself is a
  subscription you will forget to cancel.
- Two mixins defining the same member is a silent override decided by order.
  Keep member names distinctive.
