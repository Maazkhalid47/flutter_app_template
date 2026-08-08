import 'package:flutter_app_template/cache/cache_entry.dart';
import 'package:flutter_app_template/enums/app_environment.dart';
import 'package:flutter_app_template/extensions/string_extensions.dart';
import 'package:flutter_app_template/utils/logger.dart';
import 'package:flutter_app_template/utils/responsive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke tests for the small pieces of core that everything else stands on.
///
/// Feature tests live in the folders beside this file; keep this one focused on
/// primitives whose breakage would be confusing to diagnose from a failure
/// higher up.
void main() {
  group('AppEnvironment', () {
    test('parses known keys', () {
      expect(AppEnvironment.fromKey('prod'), AppEnvironment.prod);
      expect(AppEnvironment.fromKey('staging'), AppEnvironment.staging);
    });

    test('falls back to dev for anything unrecognised', () {
      // A missing --dart-define must not stop a local run.
      expect(AppEnvironment.fromKey(''), AppEnvironment.dev);
      expect(AppEnvironment.fromKey('production'), AppEnvironment.dev);
    });
  });

  group('AppLogger.redact', () {
    test('masks sensitive keys at any depth', () {
      final redacted =
          AppLogger.redact({
                'email': 'user@example.com',
                'password': 'hunter2',
                'headers': {'Authorization': 'Bearer abc.def'},
                'items': [
                  {'token': 'secret'},
                ],
              })
              as Map<Object?, Object?>;

      expect(redacted['email'], 'user@example.com');
      expect(redacted['password'], '***');
      expect(
        (redacted['headers'] as Map<Object?, Object?>)['Authorization'],
        '***',
      );
      expect(
        ((redacted['items'] as List<Object?>).first
            as Map<Object?, Object?>)['token'],
        '***',
      );
    });
  });

  group('CacheEntry', () {
    test('is fresh inside its TTL and expired after it', () {
      final fresh = CacheEntry(
        value: 1,
        storedAt: DateTime.now(),
        ttl: const Duration(minutes: 5),
      );
      final stale = CacheEntry(
        value: 1,
        storedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ttl: const Duration(minutes: 5),
      );

      expect(fresh.isFresh, isTrue);
      expect(stale.isExpired, isTrue);
    });

    test('survives a JSON round trip', () {
      final entry = CacheEntry(
        value: {'a': 1},
        storedAt: DateTime.now(),
        ttl: const Duration(minutes: 1),
      );

      final decoded = CacheEntry.tryDecode(entry.encode());

      expect(decoded, isNotNull);
      expect((decoded!.value! as Map<Object?, Object?>)['a'], 1);
    });

    test('returns null instead of throwing on corrupt data', () {
      // A bad cache entry must degrade to a miss, never crash the app.
      expect(CacheEntry.tryDecode('not json'), isNull);
      expect(CacheEntry.tryDecode('[1,2,3]'), isNull);
    });
  });

  group('Responsive.sizeForWidth', () {
    test('classifies widths by breakpoint', () {
      expect(Responsive.sizeForWidth(390), ScreenSize.mobile);
      expect(Responsive.sizeForWidth(800), ScreenSize.tablet);
      expect(Responsive.sizeForWidth(1600), ScreenSize.desktop);
    });
  });

  group('StringX', () {
    test('initials take the first letter of the first two words', () {
      expect('maaz khalid'.initials, 'MK');
      expect('single'.initials, 'S');
      expect('   '.initials, '');
    });

    test('maskedEmail keeps only the first character and the domain', () {
      expect('user@example.com'.maskedEmail, 'u***@example.com');
    });
  });
}
