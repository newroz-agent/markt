import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class SellFoundationScreen extends StatelessWidget {
  const SellFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.sellTitle)),
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
              _SellOption(
                icon: Icons.sell_outlined,
                title: l10n.sellPrivateTitle,
                body: l10n.sellPrivateBody,
              ),
              const SizedBox(height: AppSpacing.md),
              _SellOption(
                icon: Icons.storefront_outlined,
                title: l10n.sellVendorTitle,
                body: l10n.sellVendorBody,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellOption extends StatelessWidget {
  const _SellOption({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => PressScale(
    onTap: () => AppSnackBar.show(
      context,
      message: context.l10n.foundationPreviewBody,
      variant: AppSnackBarVariant.info,
    ),
    semanticLabel: title,
    child: Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: <Widget>[
            Container(
              width: AppSizes.stateIllustration,
              height: AppSizes.stateIllustration,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: AppRadius.large,
              ),
              child: Icon(
                icon,
                size: AppSizes.iconState,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    ),
  );
}
