import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_seller_id.dart';
import 'package:zerin_marketplace/features/business/presentation/business_hub_screen.dart';
import 'package:zerin_marketplace/features/business/presentation/business_labels.dart';
import 'package:zerin_marketplace/features/business/presentation/business_scope_error.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Type-aware directory profile editor. Saving never changes the publish
/// state; publishing lives on the hub.
class BusinessProfileEditorScreen extends ConsumerWidget {
  const BusinessProfileEditorScreen({
    required this.businessSellerId,
    super.key,
  });

  final String businessSellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!BusinessSellerId.isValid(businessSellerId)) {
      return BusinessScopeErrorScreen(title: l10n.businessProfileTile);
    }
    final provider = directoryOnboardingProvider(businessSellerId);
    final onboarding = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessProfileTile)),
      body: switch (onboarding) {
        AsyncData(:final value)
            when value.seller?.id == businessSellerId &&
                value.seller?.kind == 'business' &&
                value.directoryType != null =>
          _ProfileForm(
            sellerId: businessSellerId,
            type: value.directoryType!,
            profile: value.profile,
          ),
        AsyncData() => AppEmptyState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          icon: Icons.storefront_outlined,
        ),
        AsyncError() => AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(provider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({
    required this.sellerId,
    required this.type,
    required this.profile,
  });

  final String sellerId;
  final DirectoryType type;
  final DirectoryProfile? profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  static final _website = RegExp(r'^https://\S+$');

  late DirectoryType _type = widget.profile?.type ?? widget.type;
  late final _description = TextEditingController(
    text: widget.profile?.description,
  );
  late final _phone = TextEditingController(text: widget.profile?.phone);
  late final _websiteField = TextEditingController(
    text: widget.profile?.website,
  );
  late String? _coverPath = widget.profile?.coverImagePath;
  late final Set<SpokenLanguage> _languages = {...?widget.profile?.languages};
  late final Set<DirectoryCuisine> _cuisines = {...?widget.profile?.cuisines};
  late int? _priceLevel = widget.profile?.priceLevel;
  late bool _halal = widget.profile?.hasHalal ?? false;
  late bool _vegetarian = widget.profile?.hasVegetarianOptions ?? false;
  late bool _vegan = widget.profile?.hasVeganOptions ?? false;
  late DoctorSpecialty? _specialty = widget.profile?.specialty;
  late InsuranceAcceptance? _insurance = widget.profile?.insurance;
  bool _saving = false;
  bool _coverBusy = false;

  @override
  void dispose() {
    _description.dispose();
    _phone.dispose();
    _websiteField.dispose();
    super.dispose();
  }

  /// Mirrors the server's type checks so errors are caught before saving.
  String? _validationError(AppLocalizations l10n) {
    final description = _description.text.trim();
    final phone = _phone.text.trim();
    final website = _websiteField.text.trim();
    if (description.length < 20 || description.length > 3000) {
      return l10n.businessDescriptionInvalid;
    }
    if (phone.length < 5 || phone.length > 40) return l10n.businessPhoneInvalid;
    if (website.isNotEmpty && !_website.hasMatch(website)) {
      return l10n.businessWebsiteInvalid;
    }
    if (_languages.isEmpty) return l10n.businessLanguagesRequired;
    if (_type.isFood) {
      if (_cuisines.isEmpty) return l10n.businessCuisinesRequired;
      if (_priceLevel == null) return l10n.businessPriceRequired;
    } else {
      if (_specialty == null) return l10n.businessSpecialtyRequired;
      if (_insurance == null) return l10n.businessInsuranceRequired;
    }
    return null;
  }

  Future<void> _pickCover() async {
    final bytes = await ref.read(documentFileServiceProvider).pickCoverImage();
    if (bytes == null || !mounted) return;
    setState(() => _coverBusy = true);
    try {
      final path = await ref
          .read(businessRepositoryProvider)
          .uploadCover(sellerId: widget.sellerId, webpBytes: bytes);
      if (mounted) setState(() => _coverPath = path);
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(context.l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _coverBusy = false);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final error = _validationError(l10n);
    if (error != null) {
      AppSnackBar.show(
        context,
        message: error,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    final website = _websiteField.text.trim();
    setState(() => _saving = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .saveProfile(
            sellerId: widget.sellerId,
            profile: DirectoryProfile(
              type: _type,
              description: _description.text,
              phone: _phone.text,
              website: website.isEmpty ? null : website,
              coverImagePath: _coverPath,
              languages: _languages,
              cuisines: _cuisines,
              priceLevel: _priceLevel,
              hasHalal: _halal,
              hasVegetarianOptions: _vegetarian || _vegan,
              hasVeganOptions: _vegan,
              specialty: _specialty,
              insurance: _insurance,
              isPublished: widget.profile?.isPublished ?? false,
            ),
          );
      ref.invalidate(directoryOnboardingProvider(widget.sellerId));
      if (mounted) {
        AppSnackBar.show(
          context,
          message: l10n.businessSaved,
          variant: AppSnackBarVariant.success,
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final coverUrl = ref.read(businessRepositoryProvider).coverUrl(_coverPath);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            heading(l10n.businessTypeLabel),
            DirectoryTypeChoice(
              selected: _type,
              onSelected: (type) => setState(() => _type = type),
            ),
            heading(l10n.businessCoverLabel),
            ClipRRect(
              borderRadius: AppRadius.medium,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: coverUrl == null
                      ? Icon(
                          _type.icon,
                          size: AppSizes.iconHero,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton.ghost(
                label: l10n.businessCoverAction,
                leading: const Icon(Icons.image_outlined),
                loading: _coverBusy,
                onPressed: _coverBusy ? null : _pickCover,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _description,
              label: l10n.businessDescriptionLabel,
              helper: l10n.businessDescriptionHelper,
              minLines: 3,
              maxLines: 8,
              maxLength: 3000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phone,
              label: l10n.businessPhoneLabel,
              keyboardType: TextInputType.phone,
              maxLength: 40,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _websiteField,
              label: l10n.businessWebsiteLabel,
              helper: l10n.businessWebsiteHelper,
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            heading(l10n.businessLanguagesLabel),
            _MultiChoice<SpokenLanguage>(
              values: SpokenLanguage.values,
              selected: _languages,
              label: (language) => language.label(l10n),
              onChanged: () => setState(() {}),
            ),
            if (_type.isFood) ...<Widget>[
              heading(l10n.businessCuisinesLabel),
              _MultiChoice<DirectoryCuisine>(
                values: DirectoryCuisine.values,
                selected: _cuisines,
                label: (cuisine) => cuisine.label(l10n),
                onChanged: () => setState(() {}),
              ),
              heading(l10n.businessPriceLevelLabel),
              SegmentedButton<int>(
                emptySelectionAllowed: true,
                segments: <ButtonSegment<int>>[
                  for (var level = 1; level <= 4; level++)
                    ButtonSegment<int>(value: level, label: Text('€' * level)),
                ],
                selected: {?_priceLevel},
                onSelectionChanged: (selection) =>
                    setState(() => _priceLevel = selection.firstOrNull),
              ),
              heading(l10n.businessDietLabel),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.businessHalal),
                value: _halal,
                onChanged: (value) => setState(() => _halal = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.businessVegetarian),
                value: _vegetarian || _vegan,
                onChanged: _vegan
                    ? null
                    : (value) => setState(() => _vegetarian = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.businessVegan),
                value: _vegan,
                onChanged: (value) => setState(() => _vegan = value),
              ),
            ] else ...<Widget>[
              heading(l10n.businessSpecialtyLabel),
              DropdownButtonFormField<DoctorSpecialty>(
                initialValue: _specialty,
                decoration: InputDecoration(
                  labelText: l10n.businessSpecialtyLabel,
                ),
                items: <DropdownMenuItem<DoctorSpecialty>>[
                  for (final specialty in DoctorSpecialty.values)
                    DropdownMenuItem<DoctorSpecialty>(
                      value: specialty,
                      child: Text(specialty.label(l10n)),
                    ),
                ],
                onChanged: (value) => setState(() => _specialty = value),
              ),
              heading(l10n.businessInsuranceLabel),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final insurance in InsuranceAcceptance.values)
                    ChoiceChip(
                      label: Text(insurance.label(l10n)),
                      selected: _insurance == insurance,
                      onSelected: (_) => setState(() => _insurance = insurance),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l10n.actionSave,
              loading: _saving,
              expand: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiChoice<T> extends StatelessWidget {
  const _MultiChoice({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final Set<T> selected;
  final String Function(T) label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: <Widget>[
      for (final value in values)
        FilterChip(
          label: Text(label(value)),
          selected: selected.contains(value),
          onSelected: (on) {
            on ? selected.add(value) : selected.remove(value);
            onChanged();
          },
        ),
    ],
  );
}
