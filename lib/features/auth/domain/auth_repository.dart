import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';

enum SocialAuthProvider { apple, google }

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signInWithSocialProvider(SocialAuthProvider provider);

  Future<void> signOut();
}
