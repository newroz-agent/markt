import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/chat/presentation/controllers/chat_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/features/profile/domain/profile.dart';
import 'package:zerin_marketplace/features/profile/presentation/controllers/profile_controller.dart';
import 'package:zerin_marketplace/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Public person profile at `/profile/:username`. Renders only safe fields and
/// active/approved listings. Distinct from the business [SellerProfileRoute].
class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({required this.username, super.key});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(username: username));
    return Scaffold(
      appBar: AppBar(),
      body: switch (profile) {
        AsyncData<PublicProfile?>(value: final value?) => _PublicProfile(
          profile: value,
        ),
        AsyncData<PublicProfile?>() => AppEmptyState(
          title: context.l10n.profileNotFoundTitle,
          message: context.l10n.profileNotFoundBody,
          icon: Icons.person_off_outlined,
        ),
        AsyncError<PublicProfile?>() => AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () =>
              ref.invalidate(publicProfileProvider(username: username)),
        ),
        _ => const _PublicProfileSkeleton(),
      },
    );
  }
}

class _PublicProfile extends StatelessWidget {
  const _PublicProfile({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final seller = profile.seller;
    final kindLabel = switch (seller?.kind) {
      'private' => l10n.sellerTypePrivate,
      'business' => l10n.sellerTypeBusiness,
      _ => null,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  ProfileAvatar(
                    avatarUrl: profile.avatarUrl,
                    radius: AppSizes.homeStoreAvatar,
                    isBusiness: seller?.isBusiness ?? false,
                    semanticLabel: profile.displayName,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          profile.displayName ?? l10n.profileFallbackName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (profile.username != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '@${profile.username}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            if (kindLabel != null) AppChip(label: kindLabel),
                            if (seller?.verified == true)
                              AppChip(
                                label: l10n.sellerVerified,
                                leading: const Icon(
                                  Icons.verified_rounded,
                                  size: AppSizes.iconSmall,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  if (profile.city != null)
                    _IconStat(
                      icon: Icons.location_on_outlined,
                      label: profile.city!,
                    ),
                  _IconStat(
                    icon: Icons.inventory_2_outlined,
                    label: l10n.profileListingCount(
                      count: profile.listingCount,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.profileAboutTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    profile.bio?.trim().isNotEmpty == true
                        ? profile.bio!
                        : l10n.profileNoBio,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (seller != null &&
                seller.isApproved &&
                !profile.isSelf) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _MessageProfileButton(
                  sellerId: seller.id,
                  username: profile.username ?? '',
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.profileListingsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (seller != null)
              _ProfileListingsSection(
                key: ValueKey(seller.id),
                sellerId: seller.id,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(l10n.profileNoListings),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: AppSizes.iconSmall, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xxs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Opens the existing productless seller chat and navigates to it.
class _MessageProfileButton extends ConsumerStatefulWidget {
  const _MessageProfileButton({required this.sellerId, required this.username});

  final String sellerId;
  final String username;

  @override
  ConsumerState<_MessageProfileButton> createState() =>
      _MessageProfileButtonState();
}

class _MessageProfileButtonState extends ConsumerState<_MessageProfileButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      await AuthRoute(
        redirectTo: PublicProfileRoute(username: widget.username).location,
      ).push<void>(context);
      return;
    }
    setState(() => _opening = true);
    try {
      final conversation = await ref
          .read(chatRepositoryProvider)
          .openChatWithSeller(widget.sellerId);
      if (!mounted ||
          ref.read(authRepositoryProvider).currentUser?.id != user.id) {
        return;
      }
      ref.invalidate(chatInboxProvider);
      await ChatConversationRoute(
        chatId: conversation.chatId,
      ).push<void>(context);
    } catch (_) {
      if (mounted) {
        AppSnackBar.show(
          context,
          message: context.l10n.stateErrorMessage,
          variant: AppSnackBarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.profileSendMessage,
      leading: const Icon(Icons.chat_bubble_outline_rounded),
      loading: _opening,
      expand: true,
      onPressed: _opening ? null : _open,
    );
  }
}

class _ProfileListingsSection extends ConsumerStatefulWidget {
  const _ProfileListingsSection({required this.sellerId, super.key});

  final String sellerId;

  @override
  ConsumerState<_ProfileListingsSection> createState() =>
      _ProfileListingsSectionState();
}

class _ProfileListingsSectionState
    extends ConsumerState<_ProfileListingsSection> {
  int _pages = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = <String, HomeProduct>{};
    Widget? footer;
    for (var page = 0; page < _pages; page++) {
      final provider = sellerProductsProvider(
        sellerId: widget.sellerId,
        offset: page * 24,
      );
      final result = ref.watch(provider);
      if (result.hasError) {
        footer = AppErrorState(
          title: l10n.stateErrorTitle,
          message: l10n.stateErrorMessage,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(provider),
        );
        break;
      }
      final items = result.asData?.value;
      if (items == null) {
        footer = const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: AppSkeletonBox(height: 180),
        );
        break;
      }
      for (final product in items) {
        products[product.id] = product;
      }
      if (items.length < 24) break;
      if (page == _pages - 1) {
        footer = Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AppButton.secondary(
            label: l10n.categoryProductsLoadMore,
            onPressed: () => setState(() => _pages++),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (products.isNotEmpty)
          ProductRail(products: products.values.toList()),
        if (products.isEmpty && footer == null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(l10n.profileNoListings),
          ),
        ?footer,
      ],
    );
  }
}

class _PublicProfileSkeleton extends StatelessWidget {
  const _PublicProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AppSkeletonBox(
                  width: AppSizes.homeStoreAvatar * 2,
                  height: AppSizes.homeStoreAvatar * 2,
                  borderRadius: AppRadius.pill,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppSkeletonBox(height: AppSizes.pageIndicatorSelected),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            AppSkeletonBox(height: AppSizes.productDetailBodySkeletonHeight),
          ],
        ),
      ),
    );
  }
}
