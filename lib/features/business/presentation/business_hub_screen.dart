import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/constants/german_cities.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/business/domain/business_models.dart';
import 'package:zerin_marketplace/features/business/domain/business_repository.dart';
import 'package:zerin_marketplace/features/business/domain/business_seller_id.dart';
import 'package:zerin_marketplace/features/business/presentation/business_labels.dart';
import 'package:zerin_marketplace/features/business/presentation/business_scope_error.dart';
import 'package:zerin_marketplace/features/business/presentation/controllers/business_controller.dart';
import 'package:zerin_marketplace/features/identity/presentation/controllers/identity_controller.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Pre-business onboarding. The required nullable private ID distinguishes a
/// person without a private seller row from a private seller adding a business.
class BusinessStartScreen extends ConsumerWidget {
  const BusinessStartScreen({required this.existingPrivateSellerId, super.key});

  final String? existingPrivateSellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (existingPrivateSellerId != null &&
        !BusinessSellerId.isValid(existingPrivateSellerId)) {
      return BusinessScopeErrorScreen(title: l10n.businessStartTitle);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessStartTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _CreateBusinessCard(
                existingPrivateSellerId: existingPrivateSellerId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBusinessCard extends ConsumerStatefulWidget {
  const _CreateBusinessCard({required this.existingPrivateSellerId});

  final String? existingPrivateSellerId;

  @override
  ConsumerState<_CreateBusinessCard> createState() =>
      _CreateBusinessCardState();
}

class _CreateBusinessCardState extends ConsumerState<_CreateBusinessCard> {
  final _name = TextEditingController();
  DirectoryType? _type;
  String? _city;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final type = _type;
    if (type == null) return;
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 100) {
      AppSnackBar.show(
        context,
        message: l10n.businessErrorName,
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    if (_city == null) {
      AppSnackBar.show(
        context,
        message: l10n.businessErrorCity,
        variant: AppSnackBarVariant.error,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final onboarding = await ref
          .read(businessRepositoryProvider)
          .createBusiness(
            existingPrivateSellerId: widget.existingPrivateSellerId,
            type: type,
            shopName: name,
            city: _city!,
          );
      final businessSellerId = onboarding.seller?.id;
      if (businessSellerId == null ||
          onboarding.seller?.kind != 'business' ||
          !BusinessSellerId.isValid(businessSellerId)) {
        throw const BusinessException(BusinessFailureReason.invalidInput);
      }
      ref.read(identityCatalogRevisionProvider.notifier).bump();
      if (mounted) {
        BusinessDocumentsRoute(businessSellerId: businessSellerId).go(context);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.businessStartTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.businessStartBody),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.businessTypeLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            DirectoryTypeChoice(
              selected: _type,
              onSelected: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _name,
              label: l10n.businessNameLabel,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(labelText: l10n.profileCityLabel),
              items: <DropdownMenuItem<String>>[
                for (final city in germanMarketplaceCities)
                  DropdownMenuItem<String>(value: city, child: Text(city)),
              ],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l10n.businessStartAction,
              loading: _busy,
              expand: true,
              onPressed: _type == null || _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Mein Unternehmen" for one explicit owned business identity.
class BusinessHubScreen extends ConsumerWidget {
  const BusinessHubScreen({required this.businessSellerId, super.key});

  final String businessSellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (!BusinessSellerId.isValid(businessSellerId)) {
      return BusinessScopeErrorScreen(title: l10n.businessHubTitle);
    }
    final provider = directoryOnboardingProvider(businessSellerId);
    final onboarding = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessHubTitle)),
      body: switch (onboarding) {
        AsyncData(:final value) => _HubBody(
          businessSellerId: businessSellerId,
          onboarding: value,
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

class _HubBody extends StatelessWidget {
  const _HubBody({required this.businessSellerId, required this.onboarding});

  final String businessSellerId;
  final DirectoryOnboarding onboarding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seller = onboarding.seller;
    if (seller == null ||
        seller.id != businessSellerId ||
        seller.kind != 'business') {
      return AppErrorState(
        title: l10n.stateErrorTitle,
        message: l10n.stateErrorMessage,
      );
    }
    final type = onboarding.directoryType;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: type == null
              ? <Widget>[_DeclareTypeCard(businessSellerId: businessSellerId)]
              : <Widget>[
                  _StatusHeader(onboarding: onboarding, type: type),
                  const SizedBox(height: AppSpacing.md),
                  _SectionsCard(
                    businessSellerId: businessSellerId,
                    onboarding: onboarding,
                    type: type,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PublishCard(
                    businessSellerId: businessSellerId,
                    onboarding: onboarding,
                  ),
                  if (!onboarding.isVerified) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.businessDraftNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
        ),
      ),
    );
  }
}

class _DeclareTypeCard extends ConsumerStatefulWidget {
  const _DeclareTypeCard({required this.businessSellerId});

  final String businessSellerId;

  @override
  ConsumerState<_DeclareTypeCard> createState() => _DeclareTypeCardState();
}

class _DeclareTypeCardState extends ConsumerState<_DeclareTypeCard> {
  DirectoryType? _type;
  bool _busy = false;

  Future<void> _submit() async {
    final type = _type;
    if (type == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .setDirectoryType(sellerId: widget.businessSellerId, type: type);
      ref.invalidate(directoryOnboardingProvider(widget.businessSellerId));
      if (mounted) {
        BusinessDocumentsRoute(
          businessSellerId: widget.businessSellerId,
        ).go(context);
      }
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(context.l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.businessStartTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.businessStartBody),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.businessTypeLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            DirectoryTypeChoice(
              selected: _type,
              onSelected: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: l10n.businessStartAction,
              loading: _busy,
              expand: true,
              onPressed: _type == null || _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable directory types, shared by onboarding, documents and profile.
class DirectoryTypeChoice extends StatelessWidget {
  const DirectoryTypeChoice({
    required this.selected,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final DirectoryType? selected;
  final ValueChanged<DirectoryType> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final type in DirectoryType.values)
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(type.icon, size: AppSizes.iconMedium),
            label: Text(type.label(l10n)),
            selected: selected == type,
            onSelected: enabled ? (_) => onSelected(type) : null,
          ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.onboarding, required this.type});

  final DirectoryOnboarding onboarding;
  final DirectoryType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final allUploaded = onboarding.requiredDocumentKinds.every((kind) {
      final status = onboarding.latestDocument(kind)?.status;
      return status == SellerDocumentStatus.pending ||
          status == SellerDocumentStatus.approved;
    });
    final (label, icon, color) = onboarding.isVerified
        ? (
            l10n.businessStatusVerified,
            Icons.verified_rounded,
            theme.colorScheme.primary,
          )
        : allUploaded
        ? (
            l10n.businessStatusInReview,
            Icons.hourglass_top_rounded,
            theme.colorScheme.tertiary,
          )
        : (
            l10n.businessStatusDocumentsMissing,
            Icons.error_outline_rounded,
            theme.colorScheme.error,
          );
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: <Widget>[
            CircleAvatar(child: Icon(type.icon)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    onboarding.seller!.shopName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(type.label(l10n), style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Chip(
                    avatar: Icon(icon, size: AppSizes.iconSmall, color: color),
                    label: Text(label),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionsCard extends StatelessWidget {
  const _SectionsCard({
    required this.businessSellerId,
    required this.onboarding,
    required this.type,
  });

  final String businessSellerId;
  final DirectoryOnboarding onboarding;
  final DirectoryType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = onboarding.profile;
    final itemCount = onboarding.menu.fold<int>(
      0,
      (sum, section) => sum + section.items.length,
    );
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l10n.businessDocumentsTile),
            subtitle: Text(
              l10n.businessDocumentsProgress(
                approved: onboarding.approvedRequiredDocuments,
                total: onboarding.requiredDocumentKinds.length,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => BusinessDocumentsRoute(
              businessSellerId: businessSellerId,
            ).push<void>(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: Text(l10n.businessProfileTile),
            subtitle: Text(
              profile == null
                  ? l10n.businessProfileMissing
                  : profile.isPublished
                  ? l10n.businessProfilePublished
                  : l10n.businessProfileDraft,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => BusinessProfileRoute(
              businessSellerId: businessSellerId,
            ).push<void>(context),
          ),
          const Divider(),
          ListTile(
            enabled: profile != null,
            leading: const Icon(Icons.schedule_rounded),
            title: Text(l10n.businessHoursTile),
            subtitle: Text(
              profile == null
                  ? l10n.businessNeedsProfileFirst
                  : onboarding.hours.isEmpty
                  ? l10n.businessHoursClosed
                  : l10n.businessHoursSummary(count: onboarding.hours.length),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => BusinessHoursRoute(
              businessSellerId: businessSellerId,
            ).push<void>(context),
          ),
          if (type.isFood) ...<Widget>[
            const Divider(),
            ListTile(
              enabled: profile != null,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.businessMenuTile),
              subtitle: Text(
                profile == null
                    ? l10n.businessNeedsProfileFirst
                    : l10n.businessMenuSummary(
                        sections: onboarding.menu.length,
                        items: itemCount,
                      ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => BusinessMenuRoute(
                businessSellerId: businessSellerId,
              ).push<void>(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublishCard extends ConsumerStatefulWidget {
  const _PublishCard({
    required this.businessSellerId,
    required this.onboarding,
  });

  final String businessSellerId;
  final DirectoryOnboarding onboarding;

  @override
  ConsumerState<_PublishCard> createState() => _PublishCardState();
}

class _PublishCardState extends ConsumerState<_PublishCard> {
  bool _busy = false;

  Future<void> _toggle(bool published) async {
    final profile = widget.onboarding.profile;
    if (profile == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(businessRepositoryProvider)
          .saveProfile(
            sellerId: widget.businessSellerId,
            profile: profile.copyWith(isPublished: published),
          );
      ref.invalidate(directoryOnboardingProvider(widget.businessSellerId));
    } on Exception catch (error) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: businessFailureMessage(context.l10n, error),
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.onboarding.profile;
    final published = profile?.isPublished ?? false;
    final canToggle =
        !_busy &&
        profile != null &&
        (published || widget.onboarding.isVerified);
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.public_rounded),
        title: Text(l10n.businessPublishTitle),
        subtitle: Text(
          profile == null
              ? l10n.businessNeedsProfileFirst
              : !widget.onboarding.isVerified && !published
              ? l10n.businessPublishHintUnverified
              : published
              ? l10n.businessPublishOn
              : l10n.businessPublishOff,
        ),
        value: published,
        onChanged: canToggle ? _toggle : null,
      ),
    );
  }
}
