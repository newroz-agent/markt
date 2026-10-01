import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/core/errors/app_exception.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_repository.dart';
import 'package:zerin_marketplace/features/auth/domain/auth_user.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/data/active_identity_store.dart';
import 'package:zerin_marketplace/features/identity/domain/identity.dart';
import 'package:zerin_marketplace/features/identity/domain/identity_repository.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';

const _alice = AuthUser(id: 'account-a', email: 'a@example.invalid');
const _bob = AuthUser(id: 'account-b', email: 'b@example.invalid');

const _person = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: '11111111-1111-4111-8111-111111111111',
  sellerKind: 'private',
  sellerStatus: 'approved',
  label: 'Alice Person',
  avatarUrl: null,
  username: 'alice',
);
const _business = MarketplaceIdentity(
  type: MarketplaceIdentityType.business,
  sellerId: '22222222-2222-4222-8222-222222222222',
  sellerKind: 'business',
  sellerStatus: 'pending',
  label: 'Alice Business',
  avatarUrl: null,
  username: null,
);
const _bobPerson = MarketplaceIdentity(
  type: MarketplaceIdentityType.person,
  sellerId: null,
  sellerKind: 'private',
  sellerStatus: null,
  label: 'Bob Person',
  avatarUrl: null,
  username: 'bob',
);

class _AuthRepository implements AuthRepository {
  _AuthRepository(this.user);

  final changes = StreamController<AuthUser?>.broadcast(sync: true);
  AuthUser? user;

  void emit(AuthUser? next) {
    user = next;
    changes.add(next);
  }

  @override
  AuthUser? get currentUser => user;

  @override
  Stream<AuthUser?> get authStateChanges => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _CatalogRepository implements IdentityCatalogRepository {
  _CatalogRepository(this.auth, this.load);

  final _AuthRepository auth;
  Future<IdentityCatalog> Function(String userId) load;
  final calls = <String>[];

  @override
  Future<IdentityCatalog> fetchMyIdentityCatalog() {
    final userId = auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(AppFailureCode.notAuthenticated);
    }
    calls.add(userId);
    return load(userId);
  }
}

class _Store implements ActiveIdentityStore {
  final values = <String, String>{};
  final reads = <String>[];
  final writes = <({String userId, String selectionKey})>[];
  final removals = <String>[];

  @override
  String? read(String userId) {
    reads.add(userId);
    return values[userId];
  }

  @override
  Future<void> write(String userId, String selectionKey) async {
    writes.add((userId: userId, selectionKey: selectionKey));
    values[userId] = selectionKey;
  }

  @override
  Future<void> remove(String userId) async {
    removals.add(userId);
    values.remove(userId);
  }
}

Future<IdentitySessionState?> _loaded(ProviderContainer container) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await container.pump();
    final state = container.read(activeIdentityControllerProvider);
    if (state.hasError && !state.isLoading) {
      Error.throwWithStackTrace(state.error!, state.stackTrace!);
    }
    if (!state.isLoading && state.hasValue) return state.requireValue;
  }
  fail('Identity provider did not settle.');
}

void main() {
  late _AuthRepository auth;
  late _CatalogRepository repository;
  late _Store store;
  late ProviderContainer container;
  ProviderSubscription<AsyncValue<IdentitySessionState?>>? subscription;
  late Map<String, IdentityCatalog> catalogs;

  setUp(() {
    auth = _AuthRepository(_alice);
    catalogs = <String, IdentityCatalog>{
      _alice.id: IdentityCatalog(<MarketplaceIdentity>[_person, _business]),
      _bob.id: IdentityCatalog(<MarketplaceIdentity>[_bobPerson]),
    };
    repository = _CatalogRepository(auth, (userId) async => catalogs[userId]!);
    store = _Store();
    container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        identityCatalogRepositoryProvider.overrideWithValue(repository),
        activeIdentityStoreProvider.overrideWithValue(store),
      ],
    );
  });

  void start() {
    subscription = container.listen(
      activeIdentityControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }

  tearDown(() async {
    subscription?.close();
    container.dispose();
    await auth.changes.close();
  });

  test('restores a valid business only after a fresh server catalog', () async {
    store.values[_alice.id] = _business.selectionKey;
    start();

    final state = await _loaded(container);

    expect(repository.calls, [_alice.id]);
    expect(store.reads, [_alice.id]);
    expect(state!.activeIdentity?.selectionKey, _business.selectionKey);
    expect(store.writes, isEmpty);
  });

  test(
    'invalid stored selection falls back to person and is repaired',
    () async {
      store.values[_alice.id] = 'business:missing';
      start();

      final state = await _loaded(container);

      expect(state!.activeIdentity?.selectionKey, _person.selectionKey);
      expect(store.values[_alice.id], MarketplaceIdentity.personSelectionKey);
      expect(store.writes.single.userId, _alice.id);
    },
  );

  test('fallback order is person then business then none', () async {
    catalogs[_alice.id] = IdentityCatalog(<MarketplaceIdentity>[_business]);
    store.values[_alice.id] = 'stale';
    start();
    expect(
      (await _loaded(container))!.activeIdentity?.selectionKey,
      _business.selectionKey,
    );

    catalogs[_alice.id] = IdentityCatalog(const <MarketplaceIdentity>[]);
    store.values[_alice.id] = 'stale-again';
    container.read(activeIdentityControllerProvider.notifier).refresh();
    expect((await _loaded(container))!.activeIdentity, isNull);
    expect(store.values.containsKey(_alice.id), isFalse);
    expect(store.removals, contains(_alice.id));
  });

  test(
    'refresh removes a missing active business and falls back to person',
    () async {
      store.values[_alice.id] = _business.selectionKey;
      start();
      expect(
        (await _loaded(container))!.activeIdentity?.selectionKey,
        _business.selectionKey,
      );

      catalogs[_alice.id] = IdentityCatalog(<MarketplaceIdentity>[_person]);
      container.read(activeIdentityControllerProvider.notifier).refresh();
      final refreshed = await _loaded(container);

      expect(refreshed!.activeIdentity?.selectionKey, _person.selectionKey);
      expect(store.values[_alice.id], MarketplaceIdentity.personSelectionKey);
    },
  );

  test(
    'account A to B exposes loading without A data and reads only B key',
    () async {
      store.values[_alice.id] = _business.selectionKey;
      start();
      expect(
        (await _loaded(container))!.activeIdentity?.label,
        _business.label,
      );

      final bobLoad = Completer<IdentityCatalog>();
      repository.load = (userId) => userId == _bob.id
          ? bobLoad.future
          : Future<IdentityCatalog>.value(catalogs[userId]!);
      auth.emit(_bob);
      await container.pump();

      final switching = container.read(activeIdentityControllerProvider);
      expect(switching.isLoading, isTrue);
      expect(switching.hasValue, isFalse);
      expect(store.reads.where((id) => id == _bob.id), isEmpty);

      bobLoad.complete(catalogs[_bob.id]!);
      final bobState = await _loaded(container);
      expect(bobState!.activeIdentity?.label, _bobPerson.label);
      expect(store.reads.last, _bob.id);
      expect(store.values[_alice.id], _business.selectionKey);
      expect(store.values[_bob.id], MarketplaceIdentity.personSelectionKey);
    },
  );

  test('a stale A fetch cannot overwrite account B', () async {
    final aliceLoad = Completer<IdentityCatalog>();
    repository.load = (userId) => userId == _alice.id
        ? aliceLoad.future
        : Future<IdentityCatalog>.value(catalogs[userId]!);
    start();
    await container.pump();
    expect(container.read(activeIdentityControllerProvider).isLoading, isTrue);

    auth.emit(_bob);
    final bobState = await _loaded(container);
    expect(bobState!.activeIdentity?.label, _bobPerson.label);

    aliceLoad.complete(catalogs[_alice.id]!);
    await container.pump();
    expect(
      container
          .read(activeIdentityControllerProvider)
          .requireValue
          ?.activeIdentity
          ?.label,
      _bobPerson.label,
    );
  });
}
