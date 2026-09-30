import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/data/supabase_identity_catalog_repository.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';

part 'identity_controller.g.dart';

@Riverpod(keepAlive: true)
IdentityCatalogRepository identityCatalogRepository(
  IdentityCatalogRepositoryRef ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredIdentityCatalogRepository()
      : SupabaseIdentityCatalogRepository(client);
}

@Riverpod(keepAlive: true)
class IdentityCatalogRevision extends _$IdentityCatalogRevision {
  @override
  int build() => 0;

  void bump() => state++;
}

// Object identity is intentional: A -> signed out -> A is a fresh session even
// when an old auto-dispose family has not finished disposal yet.
class _IdentitySession {
  _IdentitySession(this.userId);

  final String? userId;
}

@riverpod
_IdentitySession _identitySession(_IdentitySessionRef ref) {
  final auth = ref.watch(authRepositoryProvider);
  final userId = ref.watch(
    authStateProvider.select(
      (state) => state.hasValue ? state.valueOrNull?.id : auth.currentUser?.id,
    ),
  );
  return _IdentitySession(userId);
}

@riverpod
Future<IdentitySessionState?> validatedIdentitySession(
  ValidatedIdentitySessionRef ref,
) {
  final session = ref.watch(_identitySessionProvider);
  if (session.userId == null) return Future<IdentitySessionState?>.value();
  return ref.watch(_accountIdentityControllerProvider(session: session).future);
}

/// Synchronous facade that never retains one account's value while another
/// account's freshly server-validated catalog is loading.
@riverpod
class ActiveIdentityController extends _$ActiveIdentityController {
  @override
  AsyncValue<IdentitySessionState?> build() {
    final session = ref.watch(_identitySessionProvider);
    if (session.userId == null) {
      return const AsyncData<IdentitySessionState?>(null);
    }
    return ref.watch(_accountIdentityControllerProvider(session: session));
  }

  Future<void> select(MarketplaceIdentity identity) async {
    final session = ref.read(_identitySessionProvider);
    if (session.userId == null) return;
    await ref
        .read(_accountIdentityControllerProvider(session: session).notifier)
        .select(identity.selectionKey);
  }

  /// Re-fetches the server catalog and revalidates the stored selection.
  void refresh() => ref.read(identityCatalogRevisionProvider.notifier).bump();
}

@riverpod
class _AccountIdentityController extends _$AccountIdentityController {
  int _generation = 0;
  bool _saving = false;
  bool _disposed = false;

  @override
  Future<IdentitySessionState> build({
    required _IdentitySession session,
  }) async {
    final generation = ++_generation;
    _disposed = false;
    _saving = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });

    final userId = session.userId;
    final auth = ref.watch(authRepositoryProvider);
    if (userId == null || auth.currentUser?.id != userId) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }

    ref.watch(identityCatalogRevisionProvider);
    // Server validation intentionally happens before reading device preference.
    final catalog = await ref
        .watch(identityCatalogRepositoryProvider)
        .fetchMyIdentityCatalog();
    _ensureCurrent(auth, userId, generation);

    final store = ref.read(activeIdentityStoreProvider);
    final storedSelection = store.read(userId);
    final active =
        catalog.identityForSelectionKey(storedSelection) ??
        catalog.fallbackIdentity;

    if (active == null) {
      if (storedSelection != null) await store.remove(userId);
    } else if (storedSelection != active.selectionKey) {
      await store.write(userId, active.selectionKey);
    }
    _ensureCurrent(auth, userId, generation);

    return IdentitySessionState(catalog: catalog, activeIdentity: active);
  }

  Future<void> select(String selectionKey) async {
    if (_saving || state.isLoading || !state.hasValue) return;
    final current = state.requireValue;
    final identity = current.catalog.identityForSelectionKey(selectionKey);
    if (identity == null) {
      throw ArgumentError.value(
        selectionKey,
        'selectionKey',
        'Identity is not in the freshly validated catalog.',
      );
    }

    final userId = session.userId;
    final auth = ref.read(authRepositoryProvider);
    if (userId == null ||
        auth.currentUser?.id != userId ||
        !identical(ref.read(_identitySessionProvider), session)) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    if (current.activeIdentity?.selectionKey == identity.selectionKey) return;

    final generation = _generation;
    _saving = true;
    try {
      await ref
          .read(activeIdentityStoreProvider)
          .write(userId, identity.selectionKey);
      if (_isCurrent(auth, userId, generation)) {
        state = AsyncData(current.copyWith(activeIdentity: identity));
      }
    } finally {
      if (_isCurrent(auth, userId, generation)) _saving = false;
    }
  }

  void _ensureCurrent(AuthRepository auth, String userId, int generation) {
    if (!_isCurrent(auth, userId, generation)) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
  }

  bool _isCurrent(AuthRepository auth, String userId, int generation) {
    if (_disposed || generation != _generation) return false;
    final repository = ref.read(authRepositoryProvider);
    return identical(auth, repository) &&
        repository.currentUser?.id == userId &&
        identical(ref.read(_identitySessionProvider), session);
  }
}
