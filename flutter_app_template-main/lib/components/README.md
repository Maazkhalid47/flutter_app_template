# components/

## Why it exists

Composed, app-aware UI. A component knows your domain models or your view
models; a `widgets/` widget does not. Keeping the two apart means the generic
layer stays reusable and the app-specific layer is free to be opinionated.

## What belongs here

| File | Purpose |
| --- | --- |
| `state_view.dart` | Renders loading / empty / error / success from a `BaseViewModel` |
| `responsive_layout.dart` | `ResponsiveLayout`, `ContentContainer` |
| `article_card.dart` | Example model-aware list row |

## What does NOT belong here

- Generic controls with no domain knowledge (→ `widgets/`).
- Whole screens with a `Scaffold` (→ `views/`).
- Data fetching. A component receives data; it never loads it.

## Naming conventions

- Named for what they show: `ArticleCard`, `OrderSummary`, `UserAvatar`.
- No `App` prefix — that is reserved for the generic `widgets/` layer.
- One public component per file.

## Example usage

```dart
StateView(
  viewModel: viewModel,
  onRetry: viewModel.load,
  builder: (context) => ListView.builder(
    itemBuilder: (context, i) => ArticleCard(
      article: viewModel.articles[i],
      onTap: () => context.pushNamed(...),
    ),
  ),
);

ResponsiveLayout(
  mobile: const _OrderList(),
  tablet: const Row(children: [_OrderList(), _OrderDetail()]),
);
```

## Best practices

- `StateView` is the default body for any screen backed by a view model. Use
  the `loading`/`empty` overrides for a bespoke skeleton rather than
  reintroducing an `if` ladder.
- A component takes a model plus callbacks. If it needs three or more
  callbacks, consider passing the view model instead — or splitting it.
- Prefer `ContentContainer` over a raw `Padding` for screen bodies; it also
  caps line length on tablet and desktop.
- Use `ResponsiveLayout` only when the two layouts genuinely differ in
  structure. For different values in the same structure, use
  `context.responsive(...)`.
