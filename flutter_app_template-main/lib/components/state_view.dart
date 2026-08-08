import 'package:flutter/material.dart';

import '../enums/view_state.dart';
import '../viewmodels/base_view_model.dart';
import '../widgets/app_error_view.dart';
import '../widgets/app_loader.dart';

/// Renders the four states of a screen from its view model.
///
/// This is the single most useful component in the template. Without it, every
/// screen grows the same ladder:
///
/// ```dart
/// if (vm.isLoading) return const Spinner();
/// if (vm.error != null) return ErrorWidget(...);   // sometimes forgotten
/// if (vm.items.isEmpty) return const Empty();      // often forgotten
/// return ListView(...);
/// ```
///
/// …and each copy forgets a different branch. Here the exhaustive `switch` on
/// [ViewState] makes forgetting one a compile error.
///
/// ```dart
/// StateView(
///   viewModel: vm,
///   onRetry: vm.load,
///   builder: (context) => ListView(...),
/// )
/// ```
class StateView extends StatelessWidget {
  const StateView({
    required this.viewModel,
    required this.builder,
    this.onRetry,
    this.loading,
    this.empty,
    this.emptyMessage,
    super.key,
  });

  final BaseViewModel viewModel;

  /// Built for [ViewState.success].
  final WidgetBuilder builder;

  /// Called by the error view's retry button. Usually `viewModel.load`.
  final VoidCallback? onRetry;

  /// Overrides for screens that need something bespoke — a shimmer skeleton
  /// instead of a spinner, an illustrated empty state.
  final Widget? loading;
  final Widget? empty;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.state) {
      ViewState.idle ||
      ViewState.loading => loading ?? const AppLoader.fullscreen(),
      ViewState.empty =>
        empty ?? AppEmptyView(message: emptyMessage, onAction: onRetry),
      ViewState.error => AppErrorView(
        // Non-null by construction: setError is the only path to this state.
        exception: viewModel.exception!,
        onRetry: onRetry,
      ),
      ViewState.success => builder(context),
    };
  }
}
