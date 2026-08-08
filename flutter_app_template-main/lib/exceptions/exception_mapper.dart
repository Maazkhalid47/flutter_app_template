import 'dart:async' as async;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'app_exception.dart';

/// Converts third-party errors into the app's own [AppException] hierarchy.
///
/// This is the single place that knows about Dio, Supabase and platform error
/// shapes. Keeping the knowledge here is what allows the rest of the app to
/// stay independent of those packages — swapping Dio out means editing this
/// file and nothing else.
abstract final class ExceptionMapper {
  /// Maps any [error] to an [AppException], never throwing itself.
  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    if (error is DioException) return _fromDio(error, stackTrace);
    if (error is supabase.AuthException) {
      return _fromSupabaseAuth(error, stackTrace);
    }
    if (error is supabase.PostgrestException) {
      return _fromPostgrest(error, stackTrace);
    }
    if (error is supabase.StorageException) {
      return StorageException(
        message: error.message,
        code: error.statusCode,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is SocketException) {
      return NetworkException(cause: error, stackTrace: stackTrace);
    }
    if (error is async.TimeoutException) {
      return TimeoutException(cause: error, stackTrace: stackTrace);
    }
    if (error is FormatException) {
      return ParsingException(
        message: 'Malformed response: ${error.message}',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return UnknownException(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromDio(DioException error, StackTrace? stackTrace) {
    final status = error.response?.statusCode;
    final serverMessage = _extractServerMessage(error.response?.data);

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => TimeoutException(
        cause: error,
        stackTrace: stackTrace,
      ),
      DioExceptionType.connectionError => NetworkException(
        cause: error,
        stackTrace: stackTrace,
      ),
      DioExceptionType.cancel => CancelledException(
        cause: error,
        stackTrace: stackTrace,
      ),
      DioExceptionType.badCertificate => NetworkException(
        message: 'The server certificate could not be verified.',
        cause: error,
        stackTrace: stackTrace,
      ),
      DioExceptionType.badResponse => _fromStatusCode(
        status,
        serverMessage,
        error,
        stackTrace,
      ),
      DioExceptionType.unknown =>
        error.error is SocketException
            ? NetworkException(cause: error, stackTrace: stackTrace)
            : UnknownException(
                message: error.message ?? 'Request failed.',
                cause: error,
                stackTrace: stackTrace,
              ),
    };
  }

  static AppException _fromStatusCode(
    int? status,
    String? serverMessage,
    Object cause,
    StackTrace? stackTrace,
  ) {
    final code = status?.toString();
    final message = serverMessage ?? 'Request failed with status $status.';

    if (status == null) {
      return UnknownException(
        message: message,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    if (status == 401 || status == 403) {
      return UnauthorizedException(
        message: message,
        code: code,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    if (status == 404) {
      return NotFoundException(
        message: message,
        code: code,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    if (status == 422 || status == 400) {
      return ValidationException(
        message: message,
        code: code,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    if (status >= 500) {
      return ServerException(
        message: message,
        code: code,
        cause: cause,
        stackTrace: stackTrace,
      );
    }
    return UnknownException(
      message: message,
      code: code,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromSupabaseAuth(
    supabase.AuthException error,
    StackTrace? stackTrace,
  ) {
    final status = int.tryParse(error.statusCode ?? '');
    if (status == 401 || status == 403) {
      return UnauthorizedException(
        message: error.message,
        code: error.statusCode,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AuthException(
      message: error.message,
      code: error.statusCode,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromPostgrest(
    supabase.PostgrestException error,
    StackTrace? stackTrace,
  ) {
    // PGRST116 is "no rows returned" for a .single() query.
    if (error.code == 'PGRST116') {
      return NotFoundException(
        message: error.message,
        code: error.code,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return ServerException(
      message: error.message,
      code: error.code,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Pulls a message out of the common error body shapes without assuming one.
  static String? _extractServerMessage(Object? data) {
    if (data is String && data.isNotEmpty) return data;
    if (data is Map) {
      for (final key in const [
        'message',
        'error',
        'detail',
        'error_description',
      ]) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is Map && value['message'] is String) {
          return value['message'] as String;
        }
      }
    }
    return null;
  }
}
