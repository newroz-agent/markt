import 'package:flutter/material.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Responsive product grid used by the favorites and recently-viewed screens.
/// Cards navigate to the shared product detail route.
class ProfileProductGrid extends StatelessWidget {
  const ProfileProductGrid({required this.products, super.key});

  final List<HomeProduct> products;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppSizes.homeProductCardWidth,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.62,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              title: product.title,
              priceLabel: formatMarketplacePrice(
                Localizations.localeOf(context),
                product.priceCents,
                product.currency,
              ),
              imageUrl: product.imageUrls.firstOrNull,
              imagePlaceholder: product.imageUrls.isEmpty
                  ? const Center(child: Icon(Icons.image_outlined))
                  : null,
              conditionLabel: product.condition == 'new'
                  ? context.l10n.productConditionNew
                  : context.l10n.productConditionUsed,
              sellerLabel: product.store?.shopName,
              aspectRatio: AppRatios.widescreen,
              semanticLabel: product.title,
              onTap: () =>
                  ProductDetailRoute(productId: product.id).push<void>(context),
            );
          },
        ),
      ),
    );
  }
}
