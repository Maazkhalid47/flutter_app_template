# models/

## Why it exists

The app's own vocabulary. Models are immutable data types, independent of any
backend's field names, that every layer above the repository speaks in.

## What belongs here

- `app_user.dart` — the authenticated user, in app shape (not Supabase's).
- `paginated_result.dart` — one page of a list plus its pagination state.
- `article.dart` — example domain model; delete it with the rest of the sample
  slice.

## What does NOT belong here

- Anything with a `build` method or a `BuildContext`.
- Network calls or storage access. A model has no dependencies.
- Screen state such as "is this row selected" (→ `viewmodels/`).

## Naming conventions

- Type: `PascalCase` singular — `Article`, not `Articles` or `ArticleModel`
  (the `Model` suffix adds nothing when the folder already says so; the one
  exception in this template is `PaymentIntentModel`, which would otherwise
  collide with Stripe's type name).
- File: `snake_case.dart` matching the type.
- JSON keys keep the server's casing inside `fromJson`/`toJson`; Dart fields use
  `lowerCamelCase`.

## Example usage

```dart
class Order {
  const Order({required this.id, required this.totalMinorUnits});

  factory Order.fromJson(Json json) => Order(
        id: json['id'].toString(),
        totalMinorUnits: (json['total'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final int totalMinorUnits;

  Json toJson() => {'id': id, 'total': totalMinorUnits};

  Order copyWith({String? id, int? totalMinorUnits}) => Order(
        id: id ?? this.id,
        totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

## Best practices

- Every field `final`; every model gets `copyWith` and value equality. Without
  `==`, Provider's `select` and list diffing rebuild constantly.
- Parse defensively: `json['id'].toString()` survives a backend changing an int
  to a string; a hard cast crashes the screen.
- A parse that genuinely cannot proceed should throw — the repository turns it
  into `ParsingException`, which is a loud, findable signal of a contract
  mismatch.
- Keep derived display logic (`excerpt`, `displayLabel`) on the model, but
  formatting (`Formatters.date`) out of it — formatting is locale-dependent.
- Never let a Supabase or Stripe type past the repository. Map at the boundary.
