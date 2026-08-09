import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// App-level user shape decoupled from Supabase's SDK type, so viewmodels
/// and views never import `supabase_flutter` directly.
class AppUser {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  const AppUser({required this.id, this.email, this.name, this.avatarUrl});

  factory AppUser.fromSupabase(User user) {
    final metadata = user.userMetadata ?? const {};
    return AppUser(
      id: user.id,
      email: user.email,
      name: metadata['full_name'] as String? ?? metadata['name'] as String?,
      avatarUrl: metadata['avatar_url'] as String?,
    );
  }
}
