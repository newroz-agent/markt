import 'package:flutter/material.dart';

import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/home_formatters.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

/// Horizontal listings have bounded cards and deliberately do not use heroes:
/// a product can appear in several sections on the same route.
class ProductRail extends StatelessWidget {
  const ProductRail({required this.products, super.key});

  final List<HomeProduct> products;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return SizedBox(
      height:
          AppSizes.categoryProductCardHeight +
          (scale > 1 ? (scale - 1) * 180 : 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final product = products[index];
          return SizedBox(
            width: AppSizes.homeProductCardWidth,
            child: ProductCard(
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
            ),
          );
        },
      ),
    );
  }
}
