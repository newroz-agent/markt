import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_repository.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/controllers/product_favorite_controller.dart';

class _Auth extends Mock implements AuthRepository {}

class _Home extends Mock implements HomeRepository {}

const _user = AuthUser(id: 'user-1', email: 'one@example.invalid');
const _other = AuthUser(id: 'user-2', email: 'two@example.invalid');

void main() {
  late _Auth auth;
  late _Home home;
  late StreamController<AuthUser?> authChanges;
  late ProviderContainer container;
  late AuthUser? currentUser;
  final provider = productFavoriteProvider(productId: 'p1');

  setUp(() {
    auth = _Auth();
    home = _Home();
    currentUser = _user;
    authChanges = StreamController<AuthUser?>.broadcast(sync: true);
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(() => auth.authStateChanges).thenAnswer((_) => authChanges.stream);
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) async => false);
    when(
      () => home.setFavorite(
        productId: 'p1',
        favorite: any(named: 'favorite'),
      ),
    ).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        homeRepositoryProvider.overrideWithValue(home),
      ],
    );
  });

  void listen() => container.listen(provider, (_, _) {});

  tearDown(() async {
    container.dispose();
    await authChanges.close();
  });

  test('favorite is optimistic and repeated taps are single-flight', () async {
    listen();
    expect(await container.read(provider.future), isFalse);
    final write = Completer<void>();
    when(
      () => home.setFavorite(productId: 'p1', favorite: true),
    ).thenAnswer((_) => write.future);

    final notifier = container.read(provider.notifier);
    final pending = notifier.toggle();
    expect(container.read(provider).requireValue, isTrue);
    await notifier.toggle();
    verify(() => home.setFavorite(productId: 'p1', favorite: true)).called(1);
    write.complete();
    await pending;
    await notifier.toggle();
    expect(container.read(provider).requireValue, isFalse);
    verify(() => home.setFavorite(productId: 'p1', favorite: false)).called(1);
  });

  test('failure rolls back and releases the single-flight guard', () async {
    listen();
    await container.read(provider.future);
    final write = Completer<void>();
    when(
      () => home.setFavorite(productId: 'p1', favorite: true),
    ).thenAnswer((_) => write.future);
    final pending = container.read(provider.notifier).toggle();
    expect(container.read(provider).requireValue, isTrue);
    final assertion = expectLater(pending, throwsA(isA<AppException>()));
    write.completeError(const AppException(AppFailureCode.unknown));
    await assertion;
    expect(container.read(provider).requireValue, isFalse);
    when(
      () => home.setFavorite(productId: 'p1', favorite: true),
    ).thenAnswer((_) async {});
    await container.read(provider.notifier).toggle();
    expect(container.read(provider).requireValue, isTrue);
  });

  test('initial fetch must finish before a toggle can write', () async {
    final load = Completer<bool>();
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) => load.future);
    listen();
    await container.read(provider.notifier).toggle();
    verifyNever(
      () => home.setFavorite(
        productId: 'p1',
        favorite: any(named: 'favorite'),
      ),
    );
    load.complete(true);
    expect(await container.read(provider.future), isTrue);
  });

  test('anonymous state never reads or writes favorites', () async {
    currentUser = null;
    listen();
    expect(await container.read(provider.future), isFalse);
    await expectLater(
      container.read(provider.notifier).toggle(),
      throwsA(
        isA<AppException>().having(
          (e) => e.code,
          'code',
          AppFailureCode.notAuthenticated,
        ),
      ),
    );
    verifyNever(() => home.fetchFavoriteState(any()));
    verifyNever(
      () => home.setFavorite(
        productId: 'p1',
        favorite: any(named: 'favorite'),
      ),
    );
  });

  test(
    'account switch ignores an old write failure and loads new state',
    () async {
      listen();
      await container.read(provider.future);
      final write = Completer<void>();
      when(
        () => home.setFavorite(productId: 'p1', favorite: true),
      ).thenAnswer((_) => write.future);
      final pending = container.read(provider.notifier).toggle();
      currentUser = _other;
      when(() => home.fetchFavoriteState('p1')).thenAnswer((_) async => true);
      authChanges.add(_other);
      await container.pump();
      expect(await container.read(provider.future), isTrue);
      write.completeError(const AppException(AppFailureCode.unknown));
      await pending;
      expect(container.read(provider).requireValue, isTrue);
      await container.read(provider.notifier).toggle();
      expect(container.read(provider).requireValue, isFalse);
    },
  );

  test(
    'logout clears optimistic state and ignores pending completion',
    () async {
      listen();
      await container.read(provider.future);
      final write = Completer<void>();
      when(
        () => home.setFavorite(productId: 'p1', favorite: true),
      ).thenAnswer((_) => write.future);
      final pending = container.read(provider.notifier).toggle();
      currentUser = null;
      authChanges.add(null);
      await container.pump();
      expect(await container.read(provider.future), isFalse);
      write.completeError(const AppException(AppFailureCode.unknown));
      await pending;
      expect(container.read(provider).requireValue, isFalse);
    },
  );

  test(
    'account change before auth stream delivery cannot use old state',
    () async {
      listen();
      await container.read(provider.future);
      currentUser = _other;
      await container.read(provider.notifier).toggle();
      verifyNever(
        () => home.setFavorite(
          productId: 'p1',
          favorite: any(named: 'favorite'),
        ),
      );
    },
  );

  test('stale initial fetch cannot overwrite the new account', () async {
    final oldLoad = Completer<bool>();
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) => oldLoad.future);
    listen();
    currentUser = _other;
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) async => true);
    authChanges.add(_other);
    await container.pump();
    expect(await container.read(provider.future), isTrue);
    oldLoad.complete(false);
    await container.pump();
    expect(container.read(provider).requireValue, isTrue);
  });

  test('new account loading state does not retain the old favorite', () async {
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) async => true);
    listen();
    expect(await container.read(provider.future), isTrue);
    final newLoad = Completer<bool>();
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) => newLoad.future);
    currentUser = _other;
    authChanges.add(_other);
    await container.pump();
    expect(container.read(provider).isLoading, isTrue);
    expect(container.read(provider).hasValue, isFalse);
    expect(container.read(provider).valueOrNull, isNull);
    var completed = false;
    final loaded = container.read(provider.future).then((value) {
      completed = true;
      return value;
    });
    await container.pump();
    expect(completed, isFalse, reason: 'No fabricated value completes future');
    await container.read(provider.notifier).toggle();
    verifyNever(
      () => home.setFavorite(
        productId: 'p1',
        favorite: any(named: 'favorite'),
      ),
    );
    newLoad.complete(false);
    expect(await loaded, isFalse);
  });

  test('disposed provider ignores a late write failure', () async {
    listen();
    await container.read(provider.future);
    final write = Completer<void>();
    when(
      () => home.setFavorite(productId: 'p1', favorite: true),
    ).thenAnswer((_) => write.future);
    final pending = container.read(provider.notifier).toggle();
    container.dispose();
    // Replace the disposed container for the common teardown.
    container = ProviderContainer();
    write.completeError(const AppException(AppFailureCode.unknown));
    await pending;
  });

  test(
    'signing back into the same account creates fresh favorite state',
    () async {
      listen();
      await container.read(provider.future);
      final write = Completer<void>();
      when(
        () => home.setFavorite(productId: 'p1', favorite: true),
      ).thenAnswer((_) => write.future);
      final pending = container.read(provider.notifier).toggle();
      currentUser = null;
      authChanges.add(null);
      expect(container.read(provider).requireValue, isFalse);

      final load = Completer<bool>();
      when(() => home.fetchFavoriteState('p1')).thenAnswer((_) => load.future);
      currentUser = _user;
      authChanges.add(_user);
      expect(container.read(provider).isLoading, isTrue);
      expect(container.read(provider).hasValue, isFalse);
      write.completeError(const AppException(AppFailureCode.unknown));
      await pending;
      expect(container.read(provider).hasValue, isFalse);
      load.complete(true);
      expect(await container.read(provider.future), isTrue);
      await container.read(provider.notifier).toggle();
      expect(container.read(provider).requireValue, isFalse);
    },
  );

  test(
    'failed initial fetch does not permit a guessed favorite write',
    () async {
      when(() => home.fetchFavoriteState('p1')).thenAnswer(
        (_) async => throw const AppException(AppFailureCode.unknown),
      );
      listen();
      await expectLater(
        container.read(provider.future),
        throwsA(isA<AppException>()),
      );
      expect(container.read(provider).hasError, isTrue);
      await container.read(provider.notifier).toggle();
      verifyNever(
        () => home.setFavorite(
          productId: 'p1',
          favorite: any(named: 'favorite'),
        ),
      );
    },
  );

  test(
    'disposed notifier ignores successful completion and subsequent taps',
    () async {
      listen();
      await container.read(provider.future);
      final write = Completer<void>();
      when(
        () => home.setFavorite(productId: 'p1', favorite: true),
      ).thenAnswer((_) => write.future);
      final notifier = container.read(provider.notifier);
      final pending = notifier.toggle();
      container.dispose();
      container = ProviderContainer();
      write.complete();
      await pending;
      await notifier.toggle();
      verify(() => home.setFavorite(productId: 'p1', favorite: true)).called(1);
    },
  );

  test('failed initial favorite read can retry without claiming a save', () async {
    when(() => home.fetchFavoriteState('p1')).thenThrow(
      const AppException(AppFailureCode.network),
    );
    listen();
    await expectLater(container.read(provider.future), throwsA(isA<AppException>()));
    expect(container.read(provider).hasError, isTrue);
    when(() => home.fetchFavoriteState('p1')).thenAnswer((_) async => true);
    container.read(provider.notifier).retry();
    await container.pump();
    expect(await container.read(provider.future), isTrue);
    verifyNever(() => home.setFavorite(productId: 'p1', favorite: any(named: 'favorite')));
  });

  test('seller provider forwards paging and exclusion unchanged', () async {
    when(
      () => home.fetchSellerProducts(
        'seller-1',
        offset: 24,
        limit: 12,
        excludeProductId: 'p1',
      ),
    ).thenAnswer((_) async => []);
    final page = sellerProductsProvider(
      sellerId: 'seller-1',
      offset: 24,
      limit: 12,
      excludeProductId: 'p1',
    );
    final subscription = container.listen(page, (_, _) {});
    addTearDown(subscription.close);
    expect(await container.read(page.future), isEmpty);
    verify(
      () => home.fetchSellerProducts(
        'seller-1',
        offset: 24,
        limit: 12,
        excludeProductId: 'p1',
      ),
    ).called(1);
  });
}
