import '../exceptions/app_exception.dart';

/// The return type of every repository method.
///
/// Repositories never throw across the layer boundary: they convert failures
/// into [Failure] so view models are forced to handle the error path at the
/// call site. Use [when] to collapse both branches into a single value.
sealed class Result<T> {
  const Result();

  /// Convenience constructors so call sites read as `Result.success(x)`.
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppException exception) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// The value on success, or `null` on failure.
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// The exception on failure, or `null` on success.
  AppException? get exceptionOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final exception) => exception,
  };

  /// Collapses both branches into a single [R].
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) => switch (this) {
    Success<T>(:final data) => success(data),
    Failure<T>(:final exception) => failure(exception),
  };

  /// Transforms the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Result<R>.success(transform(data)),
    Failure<T>(:final exception) => Result<R>.failure(exception),
  };
}

/// A successful [Result] carrying [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// A failed [Result] carrying the typed [exception].
final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  final AppException exception;
}
