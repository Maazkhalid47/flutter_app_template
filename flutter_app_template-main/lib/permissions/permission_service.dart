import 'package:permission_handler/permission_handler.dart';

import '../core/result.dart';
import '../core/typedefs.dart';
import '../exceptions/app_exception.dart';
import '../utils/logger.dart';

/// The permissions this app can ask for.
///
/// A closed set rather than exposing `permission_handler`'s full enum: every
/// permission you request must be declared in the Android manifest and iOS
/// Info.plist with a usage string, so adding one should be a deliberate edit
/// here, not an accident at a call site.
enum AppPermission {
  camera,
  photos,
  location,
  notifications,
  microphone,
  storage;

  Permission get _platformPermission => switch (this) {
    AppPermission.camera => Permission.camera,
    AppPermission.photos => Permission.photos,
    AppPermission.location => Permission.locationWhenInUse,
    AppPermission.notifications => Permission.notification,
    AppPermission.microphone => Permission.microphone,
    AppPermission.storage => Permission.storage,
  };
}

/// Requests and inspects OS permissions.
///
/// Returns `Result` so a denial is an ordinary, handleable outcome rather than
/// an exception — being told "no" is not an error condition.
abstract interface class PermissionService {
  Future<bool> isGranted(AppPermission permission);

  /// Requests [permission]. On success the value is whether it was granted.
  /// Fails with [PermissionException] only when permanently denied, so the UI
  /// knows to offer "Open settings" instead of asking again.
  AsyncResult<bool> request(AppPermission permission);

  /// Opens the OS settings page for this app.
  Future<bool> openSettings();
}

class PermissionServiceImpl implements PermissionService {
  const PermissionServiceImpl(this._logger);

  final AppLogger _logger;

  @override
  Future<bool> isGranted(AppPermission permission) async =>
      permission._platformPermission.isGranted;

  @override
  AsyncResult<bool> request(AppPermission permission) async {
    try {
      final status = await permission._platformPermission.request();
      _logger.debug('Permission ${permission.name}: ${status.name}');

      if (status.isPermanentlyDenied || status.isRestricted) {
        return Result<bool>.failure(
          PermissionException(
            message: '${permission.name} was permanently denied.',
            isPermanentlyDenied: true,
          ),
        );
      }
      return Result<bool>.success(status.isGranted || status.isLimited);
    } catch (error, stackTrace) {
      _logger.error(
        'Permission request failed: ${permission.name}',
        error: error,
        stackTrace: stackTrace,
      );
      return Result<bool>.failure(
        PermissionException(
          message: 'Could not request ${permission.name}.',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
