import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/data/supabase_auth_repository.dart';
import 'package:zerin_marketplace/features/auth/data/unconfigured_auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredAuthRepository()
      : SupabaseAuthRepository(client);
}

@Riverpod(keepAlive: true)
Stream<AuthUser?> authState(AuthStateRef ref) =>
    ref.watch(authRepositoryProvider).authStateChanges;

@riverpod
class AuthController extends _$AuthController {
  final Set<String> _pendingIdentityCleanupUserIds = <String>{};

  @override
  FutureOr<void> build() {}

  Future<bool> signIn({required String email, required String password}) =>
      _run(
        () => ref
            .read(authRepositoryProvider)
            .signInWithEmail(email: email, password: password),
      );

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ),
  );

  Future<bool> signInWithSocialProvider(SocialAuthProvider provider) => _run(
    () => ref.read(authRepositoryProvider).signInWithSocialProvider(provider),
  );

  Future<void> signOut() async {
    state = const AsyncLoading();
    final auth = ref.read(authRepositoryProvider);
    final userId = auth.currentUser?.id;
    try {
      await auth.signOut();
    } catch (error, stackTrace) {
      // A failed auth sign-out keeps the per-user identity preference.
      state = AsyncError(error, stackTrace);
      return;
    }

    if (userId != null) _pendingIdentityCleanupUserIds.add(userId);
    await _retryIdentityCleanup();
  }

  /// Retries local cleanup without repeating the already-successful remote
  /// sign-out. The captured UID remains available until deletion succeeds.
  Future<void> retryIdentityCleanup() async {
    if (_pendingIdentityCleanupUserIds.isEmpty) return;
    state = const AsyncLoading();
    await _retryIdentityCleanup();
  }

  Future<void> _retryIdentityCleanup() async {
    try {
      for (final userId in _pendingIdentityCleanupUserIds.toList()) {
        await ref.read(activeIdentityStoreProvider).remove(userId);
        _pendingIdentityCleanupUserIds.remove(userId);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
