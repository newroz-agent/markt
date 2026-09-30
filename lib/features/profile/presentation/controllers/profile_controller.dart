import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:zerin_marketplace/core/providers/infrastructure_providers.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/features/profile/data/flutter_avatar_image_service.dart';
import 'package:zerin_marketplace/features/profile/data/supabase_profile_repository.dart';
import 'package:zerin_marketplace/features/profile/data/unconfigured_profile_repository.dart';
import 'package:zerin_marketplace/features/profile/domain/avatar_image_service.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';
import 'package:zerin_marketplace/features/profile/domain/public_identity_resolver.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? const UnconfiguredProfileRepository()
      : SupabaseProfileRepository(client);
}

@Riverpod(keepAlive: true)
AvatarImageService avatarImageService(AvatarImageServiceRef ref) {
  // Image plugins are unavailable on the web/test harness; fall back safely.
  if (kIsWeb) return const UnavailableAvatarImageService();
  return FlutterAvatarImageService();
}

@Riverpod(keepAlive: true)
PublicIdentityResolver publicIdentityResolver(PublicIdentityResolverRef ref) {
  return PublicIdentityResolver(ref.watch(profileRepositoryProvider));
}

/// The signed-in user's own profile. Rebuilds when the auth session changes and
/// never retains a previous account's data.
@riverpod
Future<MyProfile?> myProfile(MyProfileRef ref) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  if (ref.read(authRepositoryProvider).currentUser == null) {
    return Future<MyProfile?>.value();
  }
  return ref.watch(profileRepositoryProvider).fetchMyProfile();
}

@riverpod
Future<PublicProfile?> publicProfile(
  PublicProfileRef ref, {
  required String username,
}) {
  ref.watch(authStateProvider.select((state) => state.valueOrNull?.id));
  return ref.watch(profileRepositoryProvider).fetchPublicProfile(username);
}

/// Immutable snapshot of the edit-profile screen's async state.
@immutable
class EditProfileState {
  const EditProfileState({
    this.avatarBusy = false,
    this.saving = false,
    this.saved = false,
    this.availability,
    this.checkingUsername = false,
    this.error,
  });

  final bool avatarBusy;
  final bool saving;
  final bool saved;

  /// Advisory availability of the last checked username.
  final UsernameAvailability? availability;
  final bool checkingUsername;

  /// The last save/avatar failure, for inline conflict/reserved/invalid copy.
  final ProfileFailureReason? error;

  EditProfileState copyWith({
    bool? avatarBusy,
    bool? saving,
    bool? saved,
    Object? availability = _sentinel,
    bool? checkingUsername,
    Object? error = _sentinel,
  }) {
    return EditProfileState(
      avatarBusy: avatarBusy ?? this.avatarBusy,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      availability: availability == _sentinel
          ? this.availability
          : availability as UsernameAvailability?,
      checkingUsername: checkingUsername ?? this.checkingUsername,
      error: error == _sentinel ? this.error : error as ProfileFailureReason?,
    );
  }

  static const _sentinel = Object();
}

@riverpod
class EditProfileController extends _$EditProfileController {
  int _usernameCheckSerial = 0;

  @override
  EditProfileState build() => const EditProfileState();

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  /// Advisory availability check. The save operation is DB-authoritative, so a
  /// failure here is swallowed rather than blocking the user.
  Future<void> checkUsername(String username) async {
    final serial = ++_usernameCheckSerial;
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(availability: null, checkingUsername: false);
      return;
    }
    state = state.copyWith(checkingUsername: true);
    try {
      final availability = await _repository.checkUsername(trimmed);
      if (serial != _usernameCheckSerial) return;
      state = state.copyWith(
        availability: availability,
        checkingUsername: false,
      );
    } on Object {
      if (serial != _usernameCheckSerial) return;
      state = state.copyWith(availability: null, checkingUsername: false);
    }
  }

  Future<void> pickAvatarFromGallery() =>
      _withAvatar((service) => service.pickFromGallery());

  Future<void> takeAvatarPhoto() =>
      _withAvatar((service) => service.takePhoto());

  Future<void> _withAvatar(
    Future<Uint8List?> Function(AvatarImageService) pick,
  ) async {
    if (state.avatarBusy || state.saving) return;
    final service = ref.read(avatarImageServiceProvider);
    Uint8List? bytes;
    state = state.copyWith(avatarBusy: true, error: null);
    try {
      bytes = await pick(service);
      if (bytes == null) {
        state = state.copyWith(avatarBusy: false);
        return;
      }
      await _repository.uploadAvatar(bytes);
      ref.invalidate(myProfileProvider);
      ref.read(identityCatalogRevisionProvider.notifier).bump();
      state = state.copyWith(avatarBusy: false);
    } on ProfileException catch (error) {
      state = state.copyWith(avatarBusy: false, error: error.reason);
    } on Object {
      state = state.copyWith(
        avatarBusy: false,
        error: ProfileFailureReason.avatarUnavailable,
      );
    }
  }

  Future<void> clearAvatar() async {
    if (state.avatarBusy || state.saving) return;
    state = state.copyWith(avatarBusy: true, error: null);
    try {
      await _repository.clearAvatar();
      ref.invalidate(myProfileProvider);
      ref.read(identityCatalogRevisionProvider.notifier).bump();
      state = state.copyWith(avatarBusy: false);
    } on ProfileException catch (error) {
      state = state.copyWith(avatarBusy: false, error: error.reason);
    } on Object {
      state = state.copyWith(
        avatarBusy: false,
        error: ProfileFailureReason.avatarUnavailable,
      );
    }
  }

  /// Saves the profile. Returns true on success; inline errors are placed on
  /// [EditProfileState.error] for conflict/reserved/invalid handling.
  Future<bool> save({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  }) async {
    if (state.saving) return false;
    state = state.copyWith(saving: true, saved: false, error: null);
    try {
      await _repository.updateMyProfile(
        displayName: displayName,
        username: username,
        city: city,
        bio: bio,
      );
      ref.invalidate(myProfileProvider);
      ref.read(identityCatalogRevisionProvider.notifier).bump();
      state = state.copyWith(saving: false, saved: true);
      return true;
    } on ProfileException catch (error) {
      state = state.copyWith(saving: false, error: error.reason);
      return false;
    } on Object {
      state = state.copyWith(
        saving: false,
        error: ProfileFailureReason.unknown,
      );
      return false;
    }
  }
}
