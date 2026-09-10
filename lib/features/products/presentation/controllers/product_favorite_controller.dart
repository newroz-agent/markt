import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';

part 'product_favorite_controller.g.dart';

// Identity is intentional: signing back into the same account starts a fresh
// session, even if its old auto-dispose provider has not been destroyed yet.
class _FavoriteSession {
  _FavoriteSession(this.userId);

  final String? userId;
}

@riverpod
_FavoriteSession _favoriteSession(_FavoriteSessionRef ref) {
  final auth = ref.watch(authRepositoryProvider);
  final userId = ref.watch(
    authStateProvider.select(
      (state) => state.hasValue ? state.valueOrNull?.id : auth.currentUser?.id,
    ),
  );
  return _FavoriteSession(userId);
}

/// A synchronous facade avoids AsyncNotifier's previous-data retention across
/// accounts. Each auth session owns an independent async favorite notifier.
@riverpod
class ProductFavorite extends _$ProductFavorite {
  bool _disposed = false;

  @override
  AsyncValue<bool> build({required String productId}) {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final session = ref.watch(_favoriteSessionProvider);
    return ref.watch(
      _accountFavoriteProvider(productId: productId, session: session),
    );
  }

  Future<void> toggle() async {
    if (_disposed) return;
    final session = ref.read(_favoriteSessionProvider);
    await ref
        .read(
          _accountFavoriteProvider(
            productId: productId,
            session: session,
          ).notifier,
        )
        .toggle();
  }

  void retry() {
    final session = ref.read(_favoriteSessionProvider);
    ref.invalidate(_accountFavoriteProvider(productId: productId, session: session));
  }
}

// Keep the public provider.future API without assigning state inside build or
// completing the caller's future with a fabricated neutral value.
extension ProductFavoriteFuture on ProductFavoriteProvider {
  Refreshable<Future<bool>> get future =>
      _productFavoriteFutureProvider(productId: productId).future;
}

@riverpod
Future<bool> _productFavoriteFuture(
  _ProductFavoriteFutureRef ref, {
  required String productId,
}) {
  final session = ref.watch(_favoriteSessionProvider);
  return ref.watch(
    _accountFavoriteProvider(productId: productId, session: session).future,
  );
}

@riverpod
class _AccountFavorite extends _$AccountFavorite {
  int _generation = 0;
  bool _saving = false;
  bool _disposed = false;

  @override
  FutureOr<bool> build({
    required String productId,
    required _FavoriteSession session,
  }) {
    final auth = ref.watch(authRepositoryProvider);
    _generation++;
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    _saving = false;
    if (session.userId == null) return false;
    if (session.userId != auth.currentUser?.id) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    return ref.watch(homeRepositoryProvider).fetchFavoriteState(productId);
  }

  Future<void> toggle() async {
    if (_disposed) return;
    final auth = ref.read(authRepositoryProvider);
    final userId = auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    // One write at a time; never guess the initial value or reuse another
    // account's state while its auth-triggered rebuild is pending.
    if (_saving ||
        userId != session.userId ||
        !identical(ref.read(_favoriteSessionProvider), session) ||
        state.isLoading ||
        !state.hasValue) {
      return;
    }
    final generation = _generation;
    bool isCurrent() =>
        !_disposed &&
        generation == _generation &&
        auth.currentUser?.id == userId &&
        identical(ref.read(_favoriteSessionProvider), session);
    final current = state.requireValue;
    _saving = true;
    // Optimistic flip; rollback restores the previous favorite state.
    state = AsyncData(!current);
    try {
      await ref
          .read(homeRepositoryProvider)
          .setFavorite(productId: productId, favorite: !current);
    } catch (error, stackTrace) {
      if (!isCurrent()) return;
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      if (isCurrent()) _saving = false;
    }
  }
}
