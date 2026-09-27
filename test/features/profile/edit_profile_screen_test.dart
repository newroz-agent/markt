import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zerin_marketplace/features/profile/domain/avatar_image_service.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_repository.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/features/profile/presentation/edit_profile_screen.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

const _profile = MyProfile(
  displayName: 'Alice Public',
  username: 'alice_name',
  city: 'Berlin',
  bio: 'Short public bio',
  avatarUrl: null,
  listingCount: 2,
  seller: null,
);

class _Repository implements ProfileRepository {
  ProfileException? error;
  Completer<MyProfile>? pendingSave;
  String? displayName;
  String? username;
  String? city;
  String? bio;

  @override
  Future<MyProfile> updateMyProfile({
    required String displayName,
    required String username,
    required String city,
    String? bio,
  }) async {
    this.displayName = displayName;
    this.username = username;
    this.city = city;
    this.bio = bio;
    if (error != null) throw error!;
    return pendingSave?.future ?? _profile;
  }

  @override
  Future<UsernameAvailability> checkUsername(String username) async =>
      UsernameAvailability.available;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Images implements AvatarImageService {
  @override
  Future<Uint8List?> pickFromGallery() async => null;

  @override
  Future<Uint8List?> takePhoto() async => null;
}

Future<void> _pump(WidgetTester tester, _Repository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        profileRepositoryProvider.overrideWithValue(repository),
        avatarImageServiceProvider.overrideWithValue(_Images()),
        myProfileProvider.overrideWith((ref) async => _profile),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: AppLocale.localizationsDelegates,
        home: EditProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Save profile'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Save profile'));
}

void main() {
  testWidgets(
    'shows existing values, shared city picker and both photo sources',
    (tester) async {
      await _pump(tester, _Repository());
      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields.elementAt(0).controller!.text, 'Alice Public');
      expect(fields.elementAt(1).controller!.text, 'alice_name');
      expect(fields.elementAt(2).controller!.text, 'Short public bio');
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'Berlin',
      );

      await tester.tap(find.text('Change photo'));
      await tester.pumpAndSettle();
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Take a photo'), findsOneWidget);
    },
  );

  testWidgets('database username conflict is rendered inline', (tester) async {
    final repository = _Repository()
      ..error = const ProfileException(ProfileFailureReason.usernameTaken);
    await _pump(tester, repository);
    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text('This username is already taken.'), findsOneWidget);
  });

  testWidgets('save shows loading and localized success', (tester) async {
    final repository = _Repository()..pendingSave = Completer<MyProfile>();
    await _pump(tester, repository);
    await _tapSave(tester);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.displayName, 'Alice Public');
    expect(repository.username, 'alice_name');
    expect(repository.city, 'Berlin');
    expect(repository.bio, 'Short public bio');

    repository.pendingSave!.complete(_profile);
    await tester.pumpAndSettle();
    expect(find.text('Profile saved.'), findsOneWidget);
  });

  testWidgets('unexpected save failure is visible and localized', (
    tester,
  ) async {
    final repository = _Repository()
      ..error = const ProfileException(ProfileFailureReason.network);
    await _pump(tester, repository);
    await _tapSave(tester);
    await tester.pumpAndSettle();
    expect(find.text('Please try again in a moment.'), findsOneWidget);
  });
}
