import '../api/cancellation_token.dart';
import '../constants/app_constants.dart';
import '../models/article.dart';
import '../models/paginated_result.dart';
import '../repositories/article_repository.dart';
import '../utils/debouncer.dart';
import 'base_view_model.dart';

/// EXAMPLE VIEW MODEL — a paginated, searchable, refreshable list.
///
/// This is the reference for list screens: it shows how pagination, pull to
/// refresh, debounced search and request cancellation fit together on top of
/// [BaseViewModel] without any of it leaking into the widget.
class ArticleListViewModel extends BaseViewModel {
  ArticleListViewModel(this._repository);

  final ArticleRepository _repository;
  final Debouncer _searchDebouncer = Debouncer(AppConstants.searchDebounce);

  PaginatedResult<Article> _page = const PaginatedResult<Article>.empty();
  String _searchQuery = '';
  bool _isLoadingMore = false;
  CancellationToken? _inFlight;

  List<Article> get articles => _page.items;

  bool get hasMore => _page.hasMore;

  bool get isLoadingMore => _isLoadingMore;

  String get searchQuery => _searchQuery;

  /// First load, and the target of the error view's retry button.
  Future<void> load({bool forceRefresh = false}) async {
    _cancelInFlight();
    final token = _inFlight = CancellationToken();

    await runGuarded<PaginatedResult<Article>>(
      () => _repository.fetchArticles(
        page: 1,
        search: _searchQuery,
        forceRefresh: forceRefresh,
        cancellationToken: token,
      ),
      onSuccess: (result) {
        _page = result;
        // Returning false puts the view model in ViewState.empty, so the view
        // shows an empty state instead of a blank success screen.
        return result.isNotEmpty;
      },
    );
  }

  /// Pull to refresh. Bypasses the cache and keeps the current list visible
  /// while it runs.
  Future<void> refresh() async {
    _cancelInFlight();
    final token = _inFlight = CancellationToken();

    await runGuarded<PaginatedResult<Article>>(
      () => _repository.fetchArticles(
        page: 1,
        search: _searchQuery,
        forceRefresh: true,
        cancellationToken: token,
      ),
      asBusy: true,
      onSuccess: (result) {
        _page = result;
        return result.isNotEmpty;
      },
    );
  }

  /// Loads the next page. Guarded against the double-fire that scroll
  /// listeners produce near the bottom of a list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || isBusy) return;
    _isLoadingMore = true;
    notify();

    final result = await _repository.fetchArticles(
      page: _page.nextPage,
      search: _searchQuery,
      cancellationToken: _inFlight,
    );

    if (isDisposed) return;

    result.when(
      success: (next) => _page = _page.merge(next),
      // A failed *additional* page must not wipe the pages already shown, so
      // this failure is surfaced without clearing state.
      failure: setError,
    );

    _isLoadingMore = false;
    notify();
  }

  /// Search-as-you-type. Debounced so a five-letter word is one request.
  void search(String query) {
    if (query == _searchQuery) return;
    _searchQuery = query;
    notify();
    _searchDebouncer.run(load);
  }

  void clearSearch() => search('');

  void _cancelInFlight() {
    _inFlight?.cancel();
    _inFlight = null;
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _cancelInFlight();
    super.dispose();
  }
}
