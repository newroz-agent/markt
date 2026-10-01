import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';

abstract interface class ActiveIdentityStore {
  String? read(String userId);

  Future<void> write(String userId, String selectionKey);

  Future<void> remove(String userId);
}

class SharedPreferencesActiveIdentityStore implements ActiveIdentityStore {
  const SharedPreferencesActiveIdentityStore(this._preferences);

  static const keyPrefix = 'identity.active.v1.';

  final SharedPreferences _preferences;

  @override
  String? read(String userId) => _preferences.getString(_key(userId));

  @override
  Future<void> write(String userId, String selectionKey) async {
    final didWrite = await _preferences.setString(_key(userId), selectionKey);
    if (!didWrite) {
      throw StateError('Could not persist the active identity.');
    }
  }

  @override
  Future<void> remove(String userId) async {
    final didRemove = await _preferences.remove(_key(userId));
    if (!didRemove) {
      throw StateError('Could not clear the active identity.');
    }
  }

  static String _key(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must not be empty.');
    }
    return '$keyPrefix$userId';
  }
}

final activeIdentityStoreProvider = Provider<ActiveIdentityStore>(
  (ref) => SharedPreferencesActiveIdentityStore(
    ref.watch(sharedPreferencesProvider),
  ),
);
