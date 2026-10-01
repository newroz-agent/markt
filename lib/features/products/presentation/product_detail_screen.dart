import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/auth/presentation/controllers/auth_controller.dart';
import 'package:zerin_marketplace/features/categories/presentation/controllers/category_products_controller.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/features/products/presentation/contact_seller_button.dart';
import 'package:zerin_marketplace/features/products/presentation/controllers/product_favorite_controller.dart';
import 'package:zerin_marketplace/features/products/presentation/product_rail.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, this.heroTag, super.key});

  final String productId;
  final String? heroTag;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Record the view exactly once per explicit detail open. Preview cards
    // never mount this screen, so they never record a view. Anonymous users
    // and RPC failures are silently ignored.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authRepositoryProvider).currentUser == null) return;
      unawaited(
        ref
            .read(homeRepositoryProvider)
            .recordProductView(widget.productId)
            .catchError((_) {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.productId;
    final heroTag = widget.heroTag;
    final ref = this.ref;
    final product = ref.watch(homeProductProvider(productId: productId));
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          ...switch (product) {
            AsyncData<HomeProduct?>(value: final value?) => <Widget>[
              _FavoriteButton(productId: value.id),
              Builder(
                builder: (buttonContext) => IconButton(
                  tooltip: context.l10n.productShare,
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _share(buttonContext, value),
                ),
              ),
              _ReportMenu(productId: value.id),
            ],
            _ => const <Widget>[],
          },
        ],
      ),
      // Primary CTA stays reachable while scrolling content.
      bottomNavigationBar: switch (product) {
        AsyncData<HomeProduct?>(value: final value?) when value.store != null =>
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: ContactSellerButton(
                sellerId: value.store!.id,
                productId: value.id,
              ),
            ),
          ),
        _ => null,
      },
      body: switch (product) {
        AsyncData<HomeProduct?>(value: final value?) => _ProductDetail(
          product: value,
          heroTag: heroTag ?? 'product-${value.id}',
        ),
        AsyncData<HomeProduct?>() => AppEmptyState(
          title: context.l10n.productUnavailableTitle,
          message: context.l10n.productUnavailableBody,
          icon: Icons.inventory_2_outlined,
        ),
        AsyncError<HomeProduct?>() => AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () =>
              ref.invalidate(homeProductProvider(productId: productId)),
        ),
        _ => const _ProductDetailSkeleton(),
      },
    );
  }

  Future<void> _share(BuildContext context, HomeProduct product) async {
    final locale = Localizations.localeOf(context);
    final price = formatMarketplacePrice(
      locale,
      product.priceCents,
      product.currency,
    );
    final l10n = context.l10n;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final uri = Uri.parse(
      'de.zerin.marketplace:///products/${Uri.encodeComponent(product.id)}',
    );
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${l10n.productShareText(title: product.title, price: price)}\n$uri',
          title: product.title,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.show(
        context,
        message: context.l10n.stateErrorMessage,
        variant: AppSnackBarVariant.error,
      );
    }
  }
}

class _ProductDetail extends ConsumerWidget {
  const _ProductDetail({required this.product, required this.heroTag});

  final HomeProduct product;
  final String heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final price = formatMarketplacePrice(
      locale,
      product.priceCents,
      product.currency,
    );
    final condition = product.condition == 'new'
        ? l10n.productConditionNew
        : l10n.productConditionUsed;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            _Gallery(
              key: ValueKey(product.id),
              imageUrls: product.imageUrls,
              heroTag: heroTag,
              title: product.title,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(letterSpacing: 0),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Price is visually dominant (display family, largest size).
                  Text(
                    price,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: AppTypography.displayFamily,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      AppChip(label: condition),
                      if (product.freeShipping)
                        AppChip(label: l10n.productFreeShipping),
                      if (product.city != null)
                        AppChip(
                          label: product.city!,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: AppSizes.iconSmall,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (product.store != null) ...<Widget>[
                    _SellerCard(store: product.store!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _Description(text: product.description),
                  const SizedBox(height: AppSpacing.xl),
                  _ProductDetails(product: product),
                ],
              ),
            ),
            if (product.store != null)
              _SectionRail.seller(
                title: l10n.productSellerListingsTitle,
                emptyLabel: l10n.sellerProfileEmptyListings,
                sellerId: product.store!.id,
                excludeProductId: product.id,
              ),
            if (product.categoryId != null)
              _SectionRail.similar(
                title: l10n.productSimilarTitle,
                emptyLabel: l10n.productSimilarEmpty,
                similarProductId: product.id,
                similarCategoryId: product.categoryId!,
              ),
          ],
        ),
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.imageUrls,
    required this.heroTag,
    required this.title,
    super.key,
  });

  final List<String> imageUrls;
  final String heroTag;
  final String title;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;
    if (images.isEmpty) {
      return const AspectRatio(
        aspectRatio: AppRatios.square,
        child: _ProductImageFallback(),
      );
    }
    return AspectRatio(
      aspectRatio: AppRatios.square,
      child: Stack(
        children: <Widget>[
          Hero(
            tag: widget.heroTag,
            child: PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => Semantics(
                image: true,
                label: widget.title,
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const AppSkeletonBox(borderRadius: BorderRadius.zero),
                  errorWidget: (_, _, _) => const _ProductImageFallback(),
                ),
              ),
            ),
          ),
          if (images.length > 1)
            PositionedDirectional(
              end: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Semantics(
                key: const ValueKey('product-gallery-position'),
                liveRegion: true,
                label: widget.title,
                value: context.l10n.productGalleryPosition(
                  current: _page + 1,
                  total: images.length,
                ),
                excludeSemantics: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Text(
                      '${_page + 1} / ${images.length}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(productFavoriteProvider(productId: productId));
    final isFavorite = favorite.asData?.value ?? false;
    return IconButton(
      tooltip: favorite.hasError
          ? context.l10n.actionRetry
          : isFavorite
          ? context.l10n.favoriteRemove
          : context.l10n.favoriteAdd,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
        color: isFavorite ? Theme.of(context).colorScheme.error : null,
      ),
      onPressed: () async {
        final auth = ref.read(authRepositoryProvider).currentUser;
        if (auth == null) {
          await AuthRoute(
            redirectTo: ProductDetailRoute(productId: productId).location,
          ).push<void>(context);
          return;
        }
        if (favorite.hasError) {
          ref
              .read(productFavoriteProvider(productId: productId).notifier)
              .retry();
          return;
        }
        if (favorite.isLoading) return;
        try {
          await ref
              .read(productFavoriteProvider(productId: productId).notifier)
              .toggle();
        } catch (_) {
          if (context.mounted) {
            AppSnackBar.show(
              context,
              message: context.l10n.stateErrorMessage,
              variant: AppSnackBarVariant.error,
            );
          }
        }
      },
    );
  }
}

class _ReportMenu extends ConsumerStatefulWidget {
  const _ReportMenu({required this.productId});

  final String productId;

  @override
  ConsumerState<_ReportMenu> createState() => _ReportMenuState();
}

class _ReportMenuState extends ConsumerState<_ReportMenu> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.productReport,
      icon: const Icon(Icons.flag_outlined),
      onSelected: (value) {
        if (value == 'report') _showReportSheet(context);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'report',
          child: Text(context.l10n.productReport),
        ),
      ],
    );
  }

  Future<void> _showReportSheet(BuildContext context) async {
    if (_opening) return;
    _opening = true;
    try {
      if (ref.read(authRepositoryProvider).currentUser == null) {
        await AuthRoute(
          redirectTo: ProductDetailRoute(productId: widget.productId).location,
        ).push<void>(context);
        return;
      }
      final submitted = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _ReportSheet(productId: widget.productId),
      );
      if (!context.mounted || submitted != true) return;
      AppSnackBar.show(context, message: context.l10n.productReportSubmitted);
    } finally {
      _opening = false;
    }
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.productId});

  final String productId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _detailsController = TextEditingController();
  String? _reason;
  bool _pending = false;
  bool _failed = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reasons = <(String, String)>[
      ('spam', l10n.reportReasonSpam),
      ('fraud', l10n.reportReasonFraud),
      ('counterfeit', l10n.reportReasonCounterfeit),
      ('prohibited_item', l10n.reportReasonProhibited),
      ('harassment', l10n.reportReasonHarassment),
      ('inappropriate_content', l10n.reportReasonInappropriate),
      ('other', l10n.reportReasonOther),
    ];
    return PopScope(
      canPop: !_pending,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom:
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.productReportTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) {
                  if (value == null || _pending) return;
                  setState(() => _reason = value);
                },
                child: Column(
                  children: <Widget>[
                    for (final (value, label) in reasons)
                      RadioListTile<String>(
                        value: value,
                        title: Text(label),
                        dense: true,
                        enabled: !_pending,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _detailsController,
                hint: l10n.productReportDetailsHint,
                maxLines: 3,
                maxLength: 3000,
                enabled: !_pending,
              ),
              if (_failed)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.stateErrorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.productReportSubmit,
                expand: true,
                loading: _pending,
                onPressed: _pending || _reason == null ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pending || _reason == null) return;
    if (ref.read(authRepositoryProvider).currentUser == null) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _pending = true;
      _failed = false;
    });
    try {
      await ref
          .read(homeRepositoryProvider)
          .reportProduct(
            productId: widget.productId,
            reason: _reason!,
            details: _detailsController.text.trim(),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pending = false;
        _failed = true;
      });
      return;
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() => _pending = false);
    Navigator.of(context).pop(true);
  }
}

class _SellerCard extends ConsumerWidget {
  const _SellerCard({required this.store});

  final MarketplaceStore store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicSeller = ref.watch(sellerProfileProvider(sellerId: store.id));
    final seller = publicSeller.asData?.value ?? store;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final kindLabel = switch (seller.sellerKind) {
      'private' => l10n.sellerTypePrivate,
      'business' => l10n.sellerTypeBusiness,
      _ => null,
    };

    return Semantics(
      label: l10n.viewSellerProfile,
      button: true,
      child: InkWell(
        borderRadius: AppRadius.large,
        onTap: () {
          // Private sellers with a public @username navigate to the person
          // profile; business stores keep their distinct seller profile.
          if (seller.hasPublicProfile) {
            PublicProfileRoute(
              username: seller.profileUsername!,
            ).push<void>(context);
          } else {
            SellerProfileRoute(sellerId: store.id).push<void>(context);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.semanticColors.surfaceRaised,
            borderRadius: AppRadius.large,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: AppSizes.homeStoreAvatar / 2,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: store.avatarUrl == null
                      ? null
                      : CachedNetworkImageProvider(store.avatarUrl!),
                  child: store.avatarUrl == null
                      ? Icon(
                          store.isBusiness
                              ? Icons.storefront_rounded
                              : Icons.person_rounded,
                          color: scheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        store.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (kindLabel != null) Text(kindLabel),
                          if (publicSeller.asData?.value?.verified == true)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.verified_rounded,
                                  size: AppSizes.iconSmall,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(l10n.sellerVerified),
                              ],
                            ),
                          if (store.ratingCount > 0)
                            Text(
                              '${store.ratingAverage.toStringAsFixed(1)} '
                              '(${store.ratingCount})',
                            ),
                        ],
                      ),
                      if (seller.city?.trim().isNotEmpty == true)
                        Text(
                          seller.city!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  static const _foldAt = 280;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = widget.text;
    final isLong = text.characters.length > _foldAt;
    final display = !_expanded && isLong
        ? '${text.characters.take(_foldAt)}…'
        : text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          display,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
        if (isLong)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? l10n.productDescriptionLess
                  : l10n.productDescriptionMore,
            ),
          ),
      ],
    );
  }
}

class _ProductDetails extends ConsumerWidget {
  const _ProductDetails({required this.product});

  final HomeProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final category = product.categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(product.categoryId!)).asData?.value;
    final shippingLabel = product.freeShipping
        ? l10n.productDetailsFreeShipping
        : product.shippingCostCents > 0
        ? l10n.productDetailsPaidShipping
        : l10n.productShippingArrangement;

    final rows = <(String, String)>[
      (
        l10n.productDetailsCondition,
        product.condition == 'new'
            ? l10n.productConditionNew
            : l10n.productConditionUsed,
      ),
      if (product.city != null) (l10n.productDetailsCity, product.city!),
      (l10n.productDetailsShipping, shippingLabel),
      for (final entry in product.specifications.entries)
        if (entry.key.trim().isNotEmpty &&
            (entry.value is String || entry.value is num) &&
            entry.value.toString().trim().isNotEmpty)
          (entry.key, entry.value.toString()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.productDetailsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (product.brandName?.trim().isNotEmpty == true)
          AppChip(
            label: product.brandName!,
            semanticLabel: '${l10n.productDetailsBrand}: ${product.brandName}',
          ),
        if (category != null)
          TextButton.icon(
            onPressed: () => CategoryProductsRoute(
              categoryId: category.id,
            ).push<void>(context),
            icon: const Icon(Icons.category_outlined),
            label: Text(
              '${l10n.productDetailsCategory}: '
              '${category.nameForLanguage(Localizations.localeOf(context).languageCode)}',
            ),
          ),
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 110,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionRail extends ConsumerWidget {
  const _SectionRail.seller({
    required this.title,
    required this.emptyLabel,
    required this.sellerId,
    required this.excludeProductId,
  }) : similarProductId = null,
       similarCategoryId = null;

  const _SectionRail.similar({
    required this.title,
    required this.emptyLabel,
    required this.similarProductId,
    required this.similarCategoryId,
  }) : sellerId = null,
       excludeProductId = similarProductId;

  final String title;
  final String emptyLabel;
  final String? sellerId;
  final String? excludeProductId;
  final String? similarProductId;
  final String? similarCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sellerId != null
        ? sellerProductsProvider(
            sellerId: sellerId!,
            excludeProductId: excludeProductId,
          )
        : similarProductsProvider(
            productId: similarProductId!,
            categoryId: similarCategoryId!,
          );
    final products = ref
        .watch(provider)
        .whenData(
          (items) =>
              items.where((item) => item.id != excludeProductId).toList(),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        switch (products) {
          AsyncData<List<HomeProduct>>(:final value) when value.isNotEmpty =>
            ProductRail(products: value),
          AsyncData<List<HomeProduct>>() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          AsyncError<List<HomeProduct>>() => AppErrorState(
            title: context.l10n.stateErrorTitle,
            message: context.l10n.stateErrorMessage,
            retryLabel: context.l10n.actionRetry,
            onRetry: () => ref.invalidate(provider),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AppSkeletonBox(height: 180),
          ),
        },
      ],
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.semanticColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          semanticLabel: context.l10n.productImageUnavailable,
          size: AppSizes.iconState,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: ListView(
          children: <Widget>[
            const AspectRatio(
              aspectRatio: AppRatios.square,
              child: AppSkeletonBox(borderRadius: BorderRadius.zero),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppSkeletonBox(height: AppSizes.pageIndicatorSelected),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeletonBox(
                    width: AppSizes.productDetailPriceSkeletonWidth,
                    height: AppSizes.iconLarge,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  AppSkeletonBox(
                    height: AppSizes.productDetailBodySkeletonHeight,
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
