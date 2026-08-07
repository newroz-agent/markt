import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';

class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  Stream<AuthUser?> get authStateChanges => Stream<AuthUser?>.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => Future<AuthUser>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<AuthUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) => Future<AuthUser?>.error(
    const AppException(AppFailureCode.backendNotConfigured),
  );

  @override
  Future<void> signInWithSocialProvider(SocialAuthProvider provider) =>
      Future<void>.error(
        const AppException(AppFailureCode.backendNotConfigured),
      );

  @override
  Future<void> signOut() async {}
}
