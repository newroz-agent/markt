import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/profile/domain/avatar_image_service.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';

MyProfile _profile() => const MyProfile(
  displayName: 'Alice',
  username: 'alice',
  city: 'Berlin',
  bio: null,
  avatarUrl: null,
  listingCount: 0,
  seller: null,
);

class _FakeRepo implements ProfileRepository {
  UsernameAvailability availability = UsernameAvailability.available;
  ProfileException? updateError;
  ProfileException? avatarError;
  int uploads = 0;
  int clears = 0;
  Uint8List? uploaded;

  @override
  Future<UsernameAvailability> checkUsername(String username) async =>
      availability;

  @override
  Future<MyProfile> updateMyProfile({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  }) async {
    if (updateError != null) throw updateError!;
    return _profile();
  }

  @override
  Future<MyProfile> uploadAvatar(Uint8List bytes) async {
    uploads++;
    uploaded = bytes;
    if (avatarError != null) throw avatarError!;
    return _profile();
  }

  @override
  Future<MyProfile> clearAvatar() async {
    clears++;
    return _profile();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeImageService implements AvatarImageService {
  Uint8List? gallery;
  Uint8List? camera;

  @override
  Future<Uint8List?> pickFromGallery() async => gallery;

  @override
  Future<Uint8List?> takePhoto() async => camera;
}

void main() {
  late _FakeRepo repo;
  late _FakeImageService images;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    images = _FakeImageService();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        avatarImageServiceProvider.overrideWithValue(images),
      ],
    );
    addTearDown(container.dispose);
  });

  EditProfileController controller() =>
      container.read(editProfileControllerProvider.notifier);

  test('checkUsername records advisory availability', () async {
    repo.availability = UsernameAvailability.taken;
    await controller().checkUsername('taken');
    expect(
      container.read(editProfileControllerProvider).availability,
      UsernameAvailability.taken,
    );
  });

  test('empty username clears availability without querying', () async {
    await controller().checkUsername('   ');
    expect(container.read(editProfileControllerProvider).availability, isNull);
  });

  test('save success sets saved flag', () async {
    final ok = await controller().save(
      displayName: 'Alice',
      username: 'alice',
      city: 'Berlin',
    );
    expect(ok, isTrue);
    expect(container.read(editProfileControllerProvider).saved, isTrue);
    expect(container.read(editProfileControllerProvider).error, isNull);
  });

  test('save surfaces the typed conflict reason inline', () async {
    repo.updateError = const ProfileException(
      ProfileFailureReason.usernameTaken,
    );
    final ok = await controller().save(
      displayName: 'Alice',
      username: 'taken',
      city: 'Berlin',
    );
    expect(ok, isFalse);
    expect(
      container.read(editProfileControllerProvider).error,
      ProfileFailureReason.usernameTaken,
    );
  });

  test('gallery avatar upload passes bytes to the repository', () async {
    images.gallery = Uint8List.fromList(<int>[9, 9]);
    await controller().pickAvatarFromGallery();
    expect(repo.uploads, 1);
    expect(repo.uploaded, <int>[9, 9]);
    expect(container.read(editProfileControllerProvider).avatarBusy, isFalse);
  });

  test('cancelled avatar pick uploads nothing', () async {
    images.gallery = null;
    await controller().pickAvatarFromGallery();
    expect(repo.uploads, 0);
  });

  test('avatar failure surfaces avatarUnavailable', () async {
    images.camera = Uint8List.fromList(<int>[1]);
    repo.avatarError = const ProfileException(
      ProfileFailureReason.avatarUnavailable,
    );
    await controller().takeAvatarPhoto();
    expect(
      container.read(editProfileControllerProvider).error,
      ProfileFailureReason.avatarUnavailable,
    );
  });

  test('clearAvatar calls the repository', () async {
    await controller().clearAvatar();
    expect(repo.clears, 1);
  });
}
