# How to add a new ViewModel

A view model holds a screen's state and the commands that change it — with no
Flutter UI, no `BuildContext`, and no direct data access.

## The shape

```dart
// lib/viewmodels/order_list_view_model.dart
class OrderListViewModel extends BaseViewModel {
  OrderListViewModel(this._repository);

  final OrderRepository _repository;

  PaginatedResult<Order> _page = const PaginatedResult<Order>.empty();
  List<Order> get orders => _page.items;
  bool get hasMore => _page.hasMore;

  Future<void> load() => runGuarded<PaginatedResult<Order>>(
        () => _repository.fetchOrders(),
        onSuccess: (result) {
          _page = result;
          // false ⇒ ViewState.empty, so the UI shows "nothing here"
          // instead of a blank success screen.
          return result.isNotEmpty;
        },
      );

  Future<void> refresh() => runGuarded<PaginatedResult<Order>>(
        () => _repository.fetchOrders(forceRefresh: true),
        asBusy: true,          // keeps the current list on screen
        onSuccess: (result) {
          _page = result;
          return result.isNotEmpty;
        },
      );
}
```

## `runGuarded` does four things

1. Sets `ViewState.loading` (or `isBusy` when `asBusy: true`).
2. Awaits the repository call.
3. On success: applies `onSuccess`, sets `success` or `empty`.
4. On failure: stores the exception and sets `error` — except
   `CancelledException`, which it ignores, because the user simply moved on.

It also checks `isDisposed` before touching state, so a late response cannot
crash a closed screen.

## `state` vs `isBusy`

| | Meaning | UI |
| --- | --- | --- |
| `ViewState.loading` | Nothing to show yet | Full-screen spinner |
| `isBusy` | Data on screen, action running | Button spinner, list stays |

Using `loading` for a pull-to-refresh is why lists flash empty. Use `asBusy`.

## Streams

Mix in `SubscriptionMixin` and register with `listenTo` — it cancels everything
on dispose:

```dart
class OrdersViewModel extends BaseViewModel with SubscriptionMixin {
  OrdersViewModel(this._repository) {
    listenTo(_repository.orderStream, _onOrders);
  }
}
```

## Cancellation

Anything the user can navigate away from should carry a token:

```dart
CancellationToken? _inFlight;

Future<void> load() async {
  _inFlight?.cancel();
  final token = _inFlight = CancellationToken();
  await runGuarded(() => _repository.fetchOrders(cancellationToken: token));
}

@override
void dispose() {
  _inFlight?.cancel();
  super.dispose();
}
```

## Wiring it up

Screen-scoped — created in the route builder, disposed with the route:

```dart
ChangeNotifierProvider(
  create: (context) => OrderListViewModel(context.read<OrderRepository>())..load(),
  child: const OrderListView(),
)
```

App-wide (rare — auth is the only one here) goes in `AppProviders.root`.

## Never do this

```dart
// ✗ no Flutter UI in a view model
import 'package:flutter/material.dart';

// ✗ no context
void submit(BuildContext context) { ... }

// ✗ no navigation, snackbars or dialogs
Navigator.of(context).push(...);

// ✗ no direct service or HTTP access
final response = await _apiClient.requestJson(...);
```

Each of these makes the view model untestable without a widget tree, which is
the one thing the layer exists to avoid.

## Testing

No `pumpWidget`, no `tester` — a view model is a plain Dart object:

```dart
test('load() ends in empty when the page has no items', () async {
  when(() => repository.fetchOrders(...))
      .thenAnswer((_) async => Result.success(emptyPage));

  await viewModel.load();

  expect(viewModel.state, ViewState.empty);
});
```

Always `tearDown(() => viewModel.dispose())`, or timers leak between tests.
Copy `test/viewmodels/article_list_view_model_test.dart`.
