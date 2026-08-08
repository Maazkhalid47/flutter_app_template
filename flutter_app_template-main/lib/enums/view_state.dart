/// The lifecycle of a single screen's data.
///
/// Every [BaseViewModel] exposes one of these so views can render loading,
/// empty, error and success states through the same widget
/// (`components/state_view.dart`) instead of ad-hoc `if (isLoading)` chains.
enum ViewState {
  /// Nothing has been requested yet.
  idle,

  /// A first load is in flight and there is no data to show.
  loading,

  /// Data loaded successfully and is non-empty.
  success,

  /// Data loaded successfully but the result set is empty.
  empty,

  /// The last operation failed. The view model holds the failure message.
  error;

  bool get isLoading => this == ViewState.loading;
  bool get isError => this == ViewState.error;
  bool get isSuccess => this == ViewState.success;
  bool get isEmpty => this == ViewState.empty;
}
