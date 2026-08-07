import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/data/supabase_auth_repository.dart';
import 'package:zerin_marketplace/features/auth/data/unconfigured_auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';

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
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
