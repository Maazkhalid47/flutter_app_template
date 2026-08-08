import '../core/typedefs.dart';

/// A push notification, normalised.
///
/// FCM, APNs and OneSignal all deliver a different shape. Normalising at the
/// edge means the rest of the app — routing, analytics, badge counts — reads
/// one set of fields regardless of which provider you end up using.
class NotificationPayload {
  const NotificationPayload({
    required this.id,
    this.title,
    this.body,
    this.deepLink,
    this.imageUrl,
    this.data = const {},
    this.receivedAt,
  });

  factory NotificationPayload.fromData(Json data, {String? id}) =>
      NotificationPayload(
        id: id ?? data['id']?.toString() ?? '',
        title: data['title'] as String?,
        body: data['body'] as String?,
        // `route` is the app's own convention: the server sends the in-app path
        // to open, so deep-link handling is data, not a growing switch.
        deepLink: data['route'] as String? ?? data['deep_link'] as String?,
        imageUrl: data['image'] as String?,
        data: data,
        receivedAt: DateTime.now(),
      );

  final String id;
  final String? title;
  final String? body;

  /// In-app route to open on tap, e.g. `/articles/42`.
  final String? deepLink;

  final String? imageUrl;
  final Json data;
  final DateTime? receivedAt;

  bool get hasDeepLink => deepLink != null && deepLink!.isNotEmpty;

  @override
  String toString() =>
      'NotificationPayload(id: $id, title: $title, deepLink: $deepLink)';
}
