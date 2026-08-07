import 'package:flutter/material.dart';
import 'package:zerin_marketplace/app/router/app_router.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class CartFoundationScreen extends StatelessWidget {
  const CartFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cartTitle)),
      body: AppEmptyState(
        title: l10n.cartEmptyTitle,
        message: l10n.cartEmptyBody,
        icon: Icons.shopping_bag_outlined,
        actionLabel: l10n.navigationHome,
        onAction: () => const MarketplaceRoute().go(context),
      ),
    );
  }
}
