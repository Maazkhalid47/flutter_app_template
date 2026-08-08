# onboarding/

## Why it exists

First-run onboarding, kept as a self-contained feature because it owns all three
layers — a repository (the persisted flag), a view model (page state) and a
screen. It is the template's example of **feature-first** organisation, in
contrast to the layer-first folders around it.

## What belongs here

| File | Purpose |
| --- | --- |
| `onboarding_repository.dart` | The "has completed onboarding" flag |
| `onboarding_page_data.dart` | Slide content, resolved from localization |
| `onboarding_view.dart` | The carousel, indicator and buttons |

The view model is in `viewmodels/onboarding_view_model.dart` so all view models
stay discoverable in one place. Either choice is defensible — the important
thing is that the codebase picks one and is consistent.

## Naming conventions

- Add a slide by adding an entry to `OnboardingPageData.pagesFor` and two ARB
  keys. The page count in the view model comes from the same list, so "is this
  the last page?" cannot fall out of sync.

## Example usage

```dart
// The route guard reads this synchronously, so it is hydrated in bootstrap.
if (!onboardingRepository.hasCompletedOnboarding) {
  return AppRoutes.onboarding;
}
```

Replay onboarding while developing:

```dart
await onboardingRepository.reset();
```

## Best practices

- Completing onboarding flips a flag; it does not navigate. `RouteGuard` moves
  the user on. One source of navigation truth.
- `complete()` returns `true` even when the write fails — blocking a user at
  the door because a preference did not persist is worse than showing
  onboarding once more.
- `hasCompletedOnboarding` is synchronous because the guard runs on every
  navigation. `load()` in bootstrap is what makes that safe.
- Missing illustrations fall back to an icon, so the flow is presentable before
  the artwork exists.
