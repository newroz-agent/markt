import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/constants/german_cities.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/domain/profile_errors.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editProfileTitle)),
      body: switch (profile) {
        AsyncData<MyProfile?>(value: final value?) => _EditProfileForm(
          profile: value,
        ),
        AsyncData<MyProfile?>() => AppEmptyState(
          title: context.l10n.profileNotFoundTitle,
          message: context.l10n.profileNotFoundBody,
          icon: Icons.person_off_outlined,
        ),
        AsyncError<MyProfile?>() => AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final MyProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late final TextEditingController _displayName;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  String? _city;
  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(
      text: widget.profile.displayName ?? '',
    );
    _username = TextEditingController(text: widget.profile.username ?? '');
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    final city = widget.profile.city;
    _city = city != null && germanMarketplaceCities.contains(city)
        ? city
        : null;
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(editProfileControllerProvider.notifier).checkUsername(value);
    });
  }

  String? _availabilityError(AppLocalizations l10n, UsernameAvailability? a) {
    return switch (a) {
      UsernameAvailability.taken => l10n.profileUsernameTaken,
      UsernameAvailability.reserved => l10n.profileUsernameReserved,
      UsernameAvailability.invalid => l10n.profileUsernameInvalid,
      _ => null,
    };
  }

  String? _saveError(AppLocalizations l10n, ProfileFailureReason? reason) {
    return switch (reason) {
      ProfileFailureReason.usernameTaken => l10n.profileUsernameTaken,
      ProfileFailureReason.usernameReserved => l10n.profileUsernameReserved,
      ProfileFailureReason.usernameInvalid => l10n.profileUsernameInvalid,
      ProfileFailureReason.unsupportedCity => l10n.profileCityInvalid,
      ProfileFailureReason.invalidDisplayName => l10n.profileDisplayNameInvalid,
      ProfileFailureReason.bioTooLong => l10n.profileBioTooLong,
      _ => null,
    };
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final displayName = _displayName.text.trim();
    final username = _username.text.trim();
    final city = _city;
    if (displayName.isEmpty || displayName.characters.length > 80) {
      AppSnackBar.show(
        context,
        message: l10n.profileDisplayNameInvalid,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    if (city == null) {
      AppSnackBar.show(
        context,
        message: l10n.profileCityRequired,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .save(
          displayName: displayName,
          username: username,
          city: city,
          bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        );
    if (!mounted) return;
    if (saved) {
      AppSnackBar.show(
        context,
        message: l10n.profileSaved,
        variant: AppSnackBarVariant.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(editProfileControllerProvider);
    final myProfile = ref.watch(myProfileProvider).asData?.value;
    final avatarUrl = myProfile?.avatarUrl ?? widget.profile.avatarUrl;
    final usernameError =
        _saveError(
          l10n,
          state.error == ProfileFailureReason.usernameTaken ||
                  state.error == ProfileFailureReason.usernameReserved ||
                  state.error == ProfileFailureReason.usernameInvalid
              ? state.error
              : null,
        ) ??
        _availabilityError(l10n, state.availability);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      ProfileAvatar(
                        avatarUrl: avatarUrl,
                        radius: AppSizes.homeStoreAvatar,
                        isBusiness: widget.profile.seller?.isBusiness ?? false,
                        semanticLabel: widget.profile.displayName,
                      ),
                      if (state.avatarBusy)
                        const Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: AppSizes.iconMedium,
                              height: AppSizes.iconMedium,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: state.avatarBusy
                        ? null
                        : () => _showAvatarSheet(context, avatarUrl != null),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.profileEditAvatar),
                  ),
                  if (state.error == ProfileFailureReason.avatarUnavailable)
                    Text(
                      l10n.profileAvatarError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _displayName,
              label: l10n.profileDisplayNameLabel,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              error: state.error == ProfileFailureReason.invalidDisplayName
                  ? l10n.profileDisplayNameInvalid
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _username,
              label: l10n.profileUsernameLabel,
              helper: l10n.profileUsernameHelper,
              prefix: const Icon(Icons.alternate_email_rounded),
              maxLength: 30,
              autocorrect: false,
              enableSuggestions: false,
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(30),
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
              ],
              suffix: state.checkingUsername
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        width: AppSizes.iconSmall,
                        height: AppSizes.iconSmall,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : state.availability == UsernameAvailability.available
                  ? Icon(
                      Icons.check_circle_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              error: usernameError,
              onChanged: _onUsernameChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(
                labelText: l10n.profileCityLabel,
                errorText: state.error == ProfileFailureReason.unsupportedCity
                    ? l10n.profileCityInvalid
                    : null,
              ),
              items: <DropdownMenuItem<String>>[
                for (final city in germanMarketplaceCities)
                  DropdownMenuItem<String>(value: city, child: Text(city)),
              ],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _bio,
              label: l10n.profileBioLabel,
              hint: l10n.profileBioHint,
              maxLength: 500,
              maxLines: 4,
              error: state.error == ProfileFailureReason.bioTooLong
                  ? l10n.profileBioTooLong
                  : null,
            ),
            if (state.error != null &&
                state.error != ProfileFailureReason.avatarUnavailable &&
                _saveError(l10n, state.error) == null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.stateErrorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: l10n.profileSave,
              expand: true,
              loading: state.saving,
              onPressed: state.saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAvatarSheet(BuildContext context, bool hasAvatar) async {
    final l10n = context.l10n;
    final notifier = ref.read(editProfileControllerProvider.notifier);
    await showAppBottomSheet<void>(
      context: context,
      title: l10n.profileEditAvatar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.profileAvatarFromGallery),
            onTap: () {
              Navigator.of(context).pop();
              notifier.pickAvatarFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.profileAvatarFromCamera),
            onTap: () {
              Navigator.of(context).pop();
              notifier.takeAvatarPhoto();
            },
          ),
          if (hasAvatar)
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(l10n.profileAvatarRemove),
              onTap: () {
                Navigator.of(context).pop();
                notifier.clearAvatar();
              },
            ),
        ],
      ),
    );
  }
}
