import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/home/domain/home_feed.dart';
import 'package:zerin_marketplace/features/home/presentation/controllers/home_controller.dart';
import 'package:zerin_marketplace/features/profile/presentation/widgets/profile_product_grid.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteProductsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.favoritesTitle)),
      body: switch (favorites) {
        AsyncData<List<HomeProduct>>(value: final items)
            when items.isNotEmpty =>
          ProfileProductGrid(products: items),
        AsyncData<List<HomeProduct>>() => AppEmptyState(
          title: context.l10n.favoritesEmptyTitle,
          message: context.l10n.favoritesEmptyBody,
          icon: Icons.favorite_outline_rounded,
        ),
        AsyncError<List<HomeProduct>>() => AppErrorState(
          title: context.l10n.stateErrorTitle,
          message: context.l10n.stateErrorMessage,
          retryLabel: context.l10n.actionRetry,
          onRetry: () => ref.invalidate(favoriteProductsProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
