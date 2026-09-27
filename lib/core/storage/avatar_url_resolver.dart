import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves opaque `avatars` object paths to public URLs. The `avatars` bucket
/// is public, so a stable public URL is generated without signing. Domain/UI
/// layers only ever receive resolved URLs, never raw object paths.
class AvatarUrlResolver {
  const AvatarUrlResolver(this._client);

  final SupabaseClient _client;

  /// Returns a public URL for an avatar object path, or null when [object] is
  /// null/empty. Absolute URLs (already resolved elsewhere) pass through.
  String? resolve(String? object) {
    if (object == null) return null;
    final trimmed = object.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return _client.storage.from('avatars').getPublicUrl(trimmed);
  }
}
