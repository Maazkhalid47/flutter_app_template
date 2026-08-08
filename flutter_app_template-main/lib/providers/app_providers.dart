import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../api/api_client.dart';
import '../dependency_injection/service_locator.dart';
import '../repositories/article_repository.dart';
import '../storage/key_value_store.dart';
import '../viewmodels/article_list_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import 'locale_provider.dart';
import 'theme_provider.dart';

/// The app-wide provider list.
///
/// Only three things belong here: state the whole app reads (auth), state the
/// root widget needs to rebuild on (theme, locale), and nothing else. A view
/// model used by one screen is created by that screen, so it is disposed when
/// the user leaves — putting every view model at the root is the most common
/// way a Provider app starts leaking memory and stale state.
///
/// Note the two shapes in use:
/// * `ChangeNotifierProvider` — the root owns and disposes the instance.
/// * `ChangeNotifierProvider(create: ...)` inside a screen — that screen owns it.
abstract final class AppProviders {
  /// Providers installed above `MaterialApp`.
  ///
  /// [themeProvider] and [localeProvider] are passed in already hydrated:
  /// bootstrap loads them before the first frame so the app does not start in
  /// the wrong theme and repaint.
  static List<SingleChildWidget> root({
    required ThemeProvider themeProvider,
    required LocaleProvider localeProvider,
  }) => [
    ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
    ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(getIt()),
    ),

    // Repositories are exposed as plain Providers so a screen can create
    // its own view model without reaching into the service locator.
    Provider<ArticleRepository>(create: (_) => getIt<ArticleRepository>()),
    Provider<ApiClient>(create: (_) => getIt<ApiClient>()),
    Provider<KeyValueStore>(create: (_) => getIt<KeyValueStore>()),
  ];

  /// Builds a screen-scoped view model.
  ///
  /// Use this from a route builder so the view model lives and dies with the
  /// screen:
  ///
  /// ```dart
  /// GoRoute(
  ///   path: AppRoutes.articles,
  ///   builder: (context, state) => ChangeNotifierProvider(
  ///     create: AppProviders.articleList,
  ///     child: const ArticleListView(),
  ///   ),
  /// )
  /// ```
  static ArticleListViewModel articleList(BuildContext context) =>
      ArticleListViewModel(context.read<ArticleRepository>())..load();
}
