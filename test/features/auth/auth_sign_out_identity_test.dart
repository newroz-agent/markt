import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';

const _alice = AuthUser(id: 'account-a', email: 'a@example.invalid');
const _bob = AuthUser(id: 'account-b', email: 'b@example.invalid');

class _AuthRepository implements AuthRepository {
  AuthUser? user = _alice;
  Future<void> Function() signOutAction = () async {};
  int signOutCalls = 0;

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() {
    signOutCalls++;
    return signOutAction();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Store implements ActiveIdentityStore {
  final values = <String, String>{};
  final removals = <String>[];
  int removeFailuresRemaining = 0;

  @override
  String? read(String userId) => values[userId];

  @override
  Future<void> write(String userId, String selectionKey) async {
    values[userId] = selectionKey;
  }

  @override
  Future<void> remove(String userId) async {
    removals.add(userId);
    if (removeFailuresRemaining > 0) {
      removeFailuresRemaining--;
      throw StateError('simulated persistence failure');
    }
    values.remove(userId);
  }
}

void main() {
  late _AuthRepository auth;
  late _Store store;
  late ProviderContainer container;

  setUp(() {
    auth = _AuthRepository();
    store = _Store()..values[_alice.id] = 'business:seller-a';
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        activeIdentityStoreProvider.overrideWithValue(store),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('successful sign-out clears only the captured auth UID', () async {
    store.values[_bob.id] = 'business:seller-b';
    auth.signOutAction = () async => auth.user = null;

    await container.read(authControllerProvider.notifier).signOut();

    expect(container.read(authControllerProvider).hasError, isFalse);
    expect(store.removals, [_alice.id]);
    expect(store.values.containsKey(_alice.id), isFalse);
    expect(store.values[_bob.id], 'business:seller-b');
  });

  test('failed sign-out keeps the active identity preference', () async {
    auth.signOutAction = () async {
      throw const AppException(AppFailureCode.network);
    };

    await container.read(authControllerProvider.notifier).signOut();

    expect(container.read(authControllerProvider).hasError, isTrue);
    expect(store.removals, isEmpty);
    expect(store.values[_alice.id], 'business:seller-a');
    expect(auth.currentUser, _alice);
  });

  test(
    'local cleanup can retry without repeating successful sign-out',
    () async {
      store.removeFailuresRemaining = 1;
      auth.signOutAction = () async => auth.user = null;

      final notifier = container.read(authControllerProvider.notifier);
      await notifier.signOut();
      expect(container.read(authControllerProvider).hasError, isTrue);
      expect(store.values[_alice.id], 'business:seller-a');
      expect(auth.signOutCalls, 1);

      await notifier.retryIdentityCleanup();

      expect(container.read(authControllerProvider).hasError, isFalse);
      expect(store.values.containsKey(_alice.id), isFalse);
      expect(auth.signOutCalls, 1);
    },
  );

  test(
    'UID is captured before asynchronous sign-out clears the session',
    () async {
      final remoteSignOut = Completer<void>();
      auth.signOutAction = () => remoteSignOut.future;

      final pending = container.read(authControllerProvider.notifier).signOut();
      auth.user = _bob;
      remoteSignOut.complete();
      await pending;

      expect(store.removals, [_alice.id]);
      expect(store.removals, isNot(contains(_bob.id)));
    },
  );
}
