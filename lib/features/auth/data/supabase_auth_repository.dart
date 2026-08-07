import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:zerin_marketplace/core/config/app_environment.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
    (event) => _mapUser(event.session?.user),
  );

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AppException(AppFailureCode.unknown);
      }
      return user;
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<AuthUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: <String, dynamic>{'display_name': displayName.trim()},
        emailRedirectTo: AppEnvironment.authRedirectUrl,
      );
      return _mapUser(response.user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> signInWithSocialProvider(SocialAuthProvider provider) async {
    try {
      await _client.auth.signInWithOAuth(switch (provider) {
        SocialAuthProvider.apple => OAuthProvider.apple,
        SocialAuthProvider.google => OAuthProvider.google,
      }, redirectTo: AppEnvironment.authRedirectUrl);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName:
          (metadata['display_name'] ?? metadata['full_name']) as String?,
      avatarUrl: (metadata['avatar_url'] ?? metadata['picture']) as String?,
    );
  }

  AppException _mapAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    final code = switch (message) {
      final value when value.contains('invalid login') =>
        AppFailureCode.invalidCredentials,
      final value when value.contains('email not confirmed') =>
        AppFailureCode.emailNotConfirmed,
      final value when value.contains('already registered') =>
        AppFailureCode.emailAlreadyRegistered,
      final value when value.contains('password') =>
        AppFailureCode.weakPassword,
      final value when value.contains('network') => AppFailureCode.network,
      _ => AppFailureCode.unknown,
    };
    return AppException(code, cause: error);
  }
}
