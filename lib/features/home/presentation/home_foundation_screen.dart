import 'package:flutter/material.dart';
import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

class HomeFoundationScreen extends StatelessWidget {
  const HomeFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: RefreshIndicator(
        onRefresh: () => Future<void>.delayed(AppDurations.standard),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: <Widget>[
                AppTextField(
                  hint: l10n.homeSearchHint,
                  prefix: const Icon(Icons.search_rounded),
                  readOnly: true,
                  onTap: () => AppSnackBar.show(
                    context,
                    message: l10n.foundationPreviewBody,
                    variant: AppSnackBarVariant.info,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: AppSizes.brandIcon,
                          height: AppSizes.brandIcon,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: AppRadius.medium,
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                l10n.foundationPreviewTitle,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.foundationPreviewBody,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(title: l10n.homeCategoriesTitle),
                const SizedBox(height: AppSpacing.sm),
                const _CategorySkeletonRow(),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(title: l10n.homeDealsTitle),
                const SizedBox(height: AppSpacing.sm),
                const _ProductSkeletonRow(),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(title: l10n.homeNewArrivalsTitle),
                const SizedBox(height: AppSpacing.sm),
                const _ProductSkeletonRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _CategorySkeletonRow extends StatelessWidget {
  const _CategorySkeletonRow();

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (var index = 0; index < 3; index++) ...<Widget>[
        const Expanded(
          child: AppSkeletonBox(height: AppSizes.categoryImageHeight),
        ),
        if (index < 2) const SizedBox(width: AppSpacing.sm),
      ],
    ],
  );
}

class _ProductSkeletonRow extends StatelessWidget {
  const _ProductSkeletonRow();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (var index = 0; index < 2; index++) ...<Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              AppSkeletonBox(height: AppSizes.productImageHeight),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(height: AppSizes.iconMedium),
              SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: 0.6,
                child: AppSkeletonBox(height: AppSizes.iconSmall),
              ),
            ],
          ),
        ),
        if (index < 1) const SizedBox(width: AppSpacing.md),
      ],
    ],
  );
}
