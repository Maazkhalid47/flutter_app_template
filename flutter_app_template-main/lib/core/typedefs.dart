import 'result.dart';

/// A decoded JSON object. Used everywhere instead of repeating the map type.
typedef Json = Map<String, dynamic>;

/// A decoded JSON array of objects.
typedef JsonList = List<Json>;

/// Converts a [Json] payload into a model instance.
typedef JsonDecoder<T> = T Function(Json json);

/// The signature of an asynchronous repository call.
typedef AsyncResult<T> = Future<Result<T>>;

/// A callback with no arguments and no return value.
typedef VoidAction = void Function();
