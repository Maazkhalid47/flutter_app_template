# How to add a new screen

A worked example: a **Profile** screen showing the signed-in user, with an
editable display name.

## 1. Add the strings

`lib/l10n/app_en.arb` (and every other `app_*.arb`):

```json
"profileTitle": "Profile",
"profileSave": "Save changes"
```

```bash
flutter gen-l10n
```

## 2. Add the route

`lib/routes/app_routes.dart`:

```dart
static const String profile = '/profile';
static const String profileName = 'profile';
```

The screen is private by default — do **not** add it to `publicPaths` unless a
signed-out user should reach it.

`lib/routes/app_router.dart`:

```dart
GoRoute(
  path: AppRoutes.profile,
  name: AppRoutes.profileName,
  builder: (context, state) => ChangeNotifierProvider(
    create: (context) =>
        ProfileViewModel(context.read<ProfileRepository>())..load(),
    child: const ProfileView(),
  ),
),
```

Creating the view model here — not inside the widget — is what ties its
lifetime to the route.

## 3. Add the view model

`lib/viewmodels/profile_view_model.dart` — see
[add-a-viewmodel.md](add-a-viewmodel.md).

## 4. Add the view

`lib/views/profile/profile_view.dart`:

```dart
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.profileTitle),
        leading: BackButton(onPressed: context.pop),
      ),
      body: SafeArea(
        child: StateView(
          viewModel: viewModel,
          onRetry: viewModel.load,
          builder: (context) => ContentContainer(
            child: _ProfileForm(profile: viewModel.profile!),
          ),
        ),
      ),
    );
  }
}
```

`StateView` is what makes loading, empty and error states impossible to forget.

## 5. Navigate to it

```dart
context.pushNamed(AppRoutes.profileName);   // push onto the stack
context.goNamed(AppRoutes.homeName);        // replace the stack
```

## 6. Test it

Test the **view model**, not the screen:

```dart
test('load() populates the profile', () async {
  when(() => repository.fetchProfile())
      .thenAnswer((_) async => Result.success(profile));

  await viewModel.load();

  expect(viewModel.state, ViewState.success);
});
```

A widget test is only worth writing here if the screen has interaction logic of
its own that the view model does not cover.

## Checklist

- [ ] Strings in ARB, `flutter gen-l10n` run
- [ ] Path + name constants added
- [ ] Route registered, view model created in the route builder
- [ ] Body wrapped in `StateView`
- [ ] Every controller disposed
- [ ] `if (!mounted) return;` after each `await`
- [ ] No hardcoded colours, sizes or strings
- [ ] `flutter analyze` clean, tests green
