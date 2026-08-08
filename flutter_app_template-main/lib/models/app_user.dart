import '../core/typedefs.dart';

/// The authenticated user, in the app's own shape.
///
/// Deliberately not Supabase's `User`: mapping at the boundary means a change
/// of auth provider touches one adapter instead of every screen, and the UI
/// only sees fields it actually needs.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.phone,
    this.emailVerified = false,
    this.createdAt,
    this.metadata = const {},
  });

  factory AppUser.fromJson(Json json) => AppUser(
    id: json['id'] as String,
    email: json['email'] as String? ?? '',
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    phone: json['phone'] as String?,
    emailVerified: json['email_verified'] as bool? ?? false,
    createdAt: switch (json['created_at']) {
      final String value => DateTime.tryParse(value),
      _ => null,
    },
    metadata: switch (json['metadata']) {
      final Map<String, dynamic> value => value,
      _ => const {},
    },
  );

  /// A signed-out placeholder. Lets the UI render a shape without null checks
  /// in the brief window before the session is known.
  static const AppUser empty = AppUser(id: '', email: '');

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? phone;
  final bool emailVerified;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  bool get isEmpty => id.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Best available label for the UI, falling back through the fields most
  /// likely to be populated.
  String get displayLabel {
    final name = displayName;
    if (name != null && name.trim().isNotEmpty) return name;
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  Json toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'phone': phone,
    'email_verified': emailVerified,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'metadata': metadata,
  };

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? phone,
    bool? emailVerified,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) => AppUser(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    phone: phone ?? this.phone,
    emailVerified: emailVerified ?? this.emailVerified,
    createdAt: createdAt ?? this.createdAt,
    metadata: metadata ?? this.metadata,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.avatarUrl == avatarUrl &&
          other.emailVerified == emailVerified;

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, avatarUrl, emailVerified);

  @override
  String toString() => 'AppUser(id: $id, email: $email)';
}
