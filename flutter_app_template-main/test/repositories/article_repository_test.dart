import 'package:dio/dio.dart';
import 'package:flutter_app_template/api/api_response.dart';
import 'package:flutter_app_template/core/result.dart';
import 'package:flutter_app_template/enums/log_level.dart';
import 'package:flutter_app_template/exceptions/app_exception.dart';
import 'package:flutter_app_template/repositories/article_repository.dart';
import 'package:flutter_app_template/services/article_api_service.dart';
import 'package:flutter_app_template/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockArticleApiService extends Mock implements ArticleApiService {}

/// Repository tests are the highest-value tests in this architecture: they
/// cover the mapping from transport errors to typed failures, which is the
/// contract every view model above depends on.
///
/// No cache is injected here, so `cachedFetch` goes straight to the network —
/// keeping these tests about error mapping rather than caching.
void main() {
  late _MockArticleApiService service;
  late ArticleRepository repository;

  setUp(() {
    service = _MockArticleApiService();
    repository = ArticleRepositoryImpl(
      service: service,
      logger: AppLogger(minimumLevel: LogLevel.fatal),
    );
  });

  ApiResponse<List<Map<String, dynamic>>> listResponse(
    List<Map<String, dynamic>> items,
  ) => ApiResponse(data: items, statusCode: 200);

  group('fetchArticles', () {
    test('maps a JSON array into models', () async {
      when(
        () => service.fetchArticles(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer(
        (_) async => listResponse([
          {'id': 1, 'title': 'First', 'body': 'Body one', 'userId': 7},
          {'id': 2, 'title': 'Second', 'body': 'Body two'},
        ]),
      );

      final result = await repository.fetchArticles();

      expect(result.isSuccess, isTrue);
      final page = result.dataOrNull!;
      expect(page.items, hasLength(2));
      expect(page.items.first.title, 'First');
      // Ints from the API become strings in the model, deliberately.
      expect(page.items.first.id, '1');
      expect(page.items.first.authorId, '7');
    });

    test('reports an empty page rather than failing', () async {
      when(
        () => service.fetchArticles(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          search: any(named: 'search'),
          cancellationToken: any(named: 'cancellationToken'),
        ),
      ).thenAnswer((_) async => listResponse([]));

      final result = await repository.fetchArticles();

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull!.isEmpty, isTrue);
    });

    test(
      'converts a connection error into a retryable NetworkException',
      () async {
        when(
          () => service.fetchArticles(
            page: any(named: 'page'),
            pageSize: any(named: 'pageSize'),
            search: any(named: 'search'),
            cancellationToken: any(named: 'cancellationToken'),
          ),
        ).thenThrow(
          DioException.connectionError(
            requestOptions: RequestOptions(path: '/posts'),
            reason: 'offline',
          ),
        );

        final result = await repository.fetchArticles();

        expect(result.isFailure, isTrue);
        final exception = result.exceptionOrNull!;
        expect(exception, isA<NetworkException>());
        expect(exception.isRetryable, isTrue);
      },
    );

    test('converts a 404 into a non-retryable NotFoundException', () async {
      final options = RequestOptions(path: '/posts/999');
      when(() => service.fetchArticle(any())).thenThrow(
        DioException.badResponse(
          statusCode: 404,
          requestOptions: options,
          response: Response<dynamic>(requestOptions: options, statusCode: 404),
        ),
      );

      final result = await repository.fetchArticle('999');

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotFoundException>());
      expect(result.exceptionOrNull!.isRetryable, isFalse);
    });

    test('converts a 500 into a retryable ServerException', () async {
      final options = RequestOptions(path: '/posts/1');
      when(() => service.fetchArticle(any())).thenThrow(
        DioException.badResponse(
          statusCode: 500,
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'boom'},
          ),
        ),
      );

      final result = await repository.fetchArticle('1');

      expect(result.exceptionOrNull, isA<ServerException>());
      // The server's own message is preserved for logs.
      expect(result.exceptionOrNull!.message, 'boom');
    });
  });

  group('Result', () {
    test('when() collapses both branches', () {
      const success = Result<int>.success(42);
      const failure = Result<int>.failure(UnknownException());

      expect(success.when(success: (v) => v * 2, failure: (_) => -1), 84);
      expect(failure.when(success: (v) => v * 2, failure: (_) => -1), -1);
    });

    test('map() transforms success and passes failure through', () {
      const success = Result<int>.success(2);
      const failure = Result<int>.failure(NetworkException());

      expect(success.map((v) => v.toString()).dataOrNull, '2');
      expect(
        failure.map((v) => v.toString()).exceptionOrNull,
        isA<NetworkException>(),
      );
    });
  });
}
