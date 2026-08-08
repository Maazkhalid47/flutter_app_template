import 'package:flutter_app_template/api/cancellation_token.dart';
import 'package:flutter_app_template/core/result.dart';
import 'package:flutter_app_template/enums/view_state.dart';
import 'package:flutter_app_template/exceptions/app_exception.dart';
import 'package:flutter_app_template/models/article.dart';
import 'package:flutter_app_template/models/paginated_result.dart';
import 'package:flutter_app_template/repositories/article_repository.dart';
import 'package:flutter_app_template/viewmodels/article_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockArticleRepository extends Mock implements ArticleRepository {}

/// View models are plain [ChangeNotifier]s with no Flutter dependency, so they
/// test like ordinary Dart classes — no `pumpWidget`, no `tester`.
void main() {
  late _MockArticleRepository repository;
  late ArticleListViewModel viewModel;

  Article article(String id) => Article(id: id, title: 'T$id', body: 'B$id');

  PaginatedResult<Article> page(List<Article> items, {int pageNumber = 1}) =>
      PaginatedResult<Article>(
        items: items,
        page: pageNumber,
        pageSize: 20,
        totalCount: 40,
      );

  void stubFetch(Result<PaginatedResult<Article>> result) {
    when(
      () => repository.fetchArticles(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        forceRefresh: any(named: 'forceRefresh'),
        cancellationToken: any(named: 'cancellationToken'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUpAll(() {
    registerFallbackValue(CancellationToken());
  });

  setUp(() {
    repository = _MockArticleRepository();
    viewModel = ArticleListViewModel(repository);
  });

  tearDown(() => viewModel.dispose());

  test('starts idle', () {
    expect(viewModel.state, ViewState.idle);
    expect(viewModel.articles, isEmpty);
  });

  test('load() ends in success with items', () async {
    stubFetch(Result.success(page([article('1'), article('2')])));

    await viewModel.load();

    expect(viewModel.state, ViewState.success);
    expect(viewModel.articles, hasLength(2));
    expect(viewModel.exception, isNull);
  });

  test('load() ends in empty when the page has no items', () async {
    stubFetch(Result.success(page([])));

    await viewModel.load();

    // Empty is not success: the UI must show "nothing here", not a blank list.
    expect(viewModel.state, ViewState.empty);
  });

  test('load() ends in error and keeps the exception', () async {
    stubFetch(const Result.failure(NetworkException()));

    await viewModel.load();

    expect(viewModel.state, ViewState.error);
    expect(viewModel.exception, isA<NetworkException>());
  });

  test('a cancelled request does not surface as an error', () async {
    stubFetch(const Result.failure(CancelledException()));

    await viewModel.load();

    expect(viewModel.exception, isNull);
    expect(viewModel.state, isNot(ViewState.error));
  });

  test('loadMore() appends the next page', () async {
    stubFetch(Result.success(page([article('1')])));
    await viewModel.load();

    stubFetch(Result.success(page([article('2')], pageNumber: 2)));
    await viewModel.loadMore();

    expect(viewModel.articles.map((a) => a.id), ['1', '2']);
    expect(viewModel.isLoadingMore, isFalse);
  });

  test('a failed loadMore() keeps the pages already loaded', () async {
    stubFetch(Result.success(page([article('1')])));
    await viewModel.load();

    stubFetch(
      const Result<PaginatedResult<Article>>.failure(ServerException()),
    );
    await viewModel.loadMore();

    // The list survives; only the error is reported.
    expect(viewModel.articles, hasLength(1));
    expect(viewModel.exception, isA<ServerException>());
  });

  test('loadMore() is a no-op when there is nothing more to load', () async {
    stubFetch(
      const Result.success(
        PaginatedResult<Article>(
          items: [],
          page: 1,
          pageSize: 20,
          totalCount: 0,
        ),
      ),
    );
    await viewModel.load();
    clearInteractions(repository);

    await viewModel.loadMore();

    verifyNever(
      () => repository.fetchArticles(
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        search: any(named: 'search'),
        forceRefresh: any(named: 'forceRefresh'),
        cancellationToken: any(named: 'cancellationToken'),
      ),
    );
  });

  test('notifies listeners on state changes', () async {
    var notifications = 0;
    viewModel.addListener(() => notifications++);

    stubFetch(Result.success(page([article('1')])));
    await viewModel.load();

    expect(notifications, greaterThan(0));
  });
}
