import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/orders/domain/marketplace_order.dart';
import 'package:zerin_marketplace/features/orders/presentation/orders_copy.dart';

sealed class OrdersViewState {
  const OrdersViewState();
}

final class OrdersLoading extends OrdersViewState {
  const OrdersLoading();
}

final class OrdersFailure extends OrdersViewState {
  const OrdersFailure({this.message});

  final String? message;
}

final class OrdersOffline extends OrdersViewState {
  const OrdersOffline();
}

final class OrdersData extends OrdersViewState {
  const OrdersData(this.orders);

  final List<MarketplaceOrder> orders;
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({
    required this.state,
    required this.copy,
    required this.formatMoney,
    required this.formatDate,
    required this.onOrderPressed,
    this.onRetry,
    super.key,
  });

  final OrdersViewState state;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;
  final OrderDateFormatter formatDate;
  final ValueChanged<MarketplaceOrder> onOrderPressed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: switch (state) {
        OrdersLoading() => _OrdersSkeleton(label: copy.loadingLabel),
        OrdersFailure(:final message) => AppErrorState(
          title: copy.errorTitle,
          message: message ?? copy.errorMessage,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        OrdersOffline() => AppErrorState(
          title: copy.offlineTitle,
          message: copy.offlineMessage,
          icon: Icons.wifi_off_rounded,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        OrdersData(:final orders) when orders.isEmpty => AppEmptyState(
          title: copy.emptyTitle,
          message: copy.emptyMessage,
          icon: Icons.receipt_long_outlined,
        ),
        OrdersData(:final orders) => _OrdersList(
          orders: orders,
          copy: copy,
          formatMoney: formatMoney,
          formatDate: formatDate,
          onOrderPressed: onOrderPressed,
        ),
      },
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.copy,
    required this.formatMoney,
    required this.formatDate,
    required this.onOrderPressed,
  });

  final List<MarketplaceOrder> orders;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;
  final OrderDateFormatter formatDate;
  final ValueChanged<MarketplaceOrder> onOrderPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                copy: copy,
                formattedDate: formatDate(order.placedAt),
                formattedTotal: formatMoney(
                  order.totals.totalMinor,
                  order.totals.currencyCode,
                ),
                onPressed: () => onOrderPressed(order),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.copy,
    required this.formattedDate,
    required this.formattedTotal,
    required this.onPressed,
  });

  final MarketplaceOrder order;
  final OrdersCopy copy;
  final String formattedDate;
  final String formattedTotal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstItem = order.items.isEmpty ? null : order.items.first;
    return Semantics(
      button: true,
      label: copy.orderNumberLabel(order.orderNumber),
      child: Card(
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            copy.orderNumberLabel(order.orderNumber),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            copy.placedAtLabel(formattedDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _OrderStatusBadge(
                      status: order.status,
                      label: copy.statusLabel(order.status),
                    ),
                  ],
                ),
                if (firstItem != null) ...<Widget>[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Divider(),
                  ),
                  Row(
                    children: <Widget>[
                      _OrderThumbnail(
                        imageUrl: firstItem.imageUrl,
                        semanticLabel: firstItem.title,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              firstItem.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              copy.quantityLabel(firstItem.quantity),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (order.items.length > 1)
                              Text(
                                copy.additionalItemsLabel(
                                  order.items.length - 1,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Divider(),
                ),
                Row(
                  children: <Widget>[
                    const Icon(Icons.storefront_outlined),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        order.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(formattedTotal, style: theme.textTheme.titleMedium),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status, required this.label});

  final MarketplaceOrderStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.$1, borderRadius: AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colors.$2),
        ),
      ),
    );
  }

  (Color, Color) _colors(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      MarketplaceOrderStatus.ordered || MarketplaceOrderStatus.shipped => (
        semantic.infoContainer,
        semantic.onInfoContainer,
      ),
      MarketplaceOrderStatus.paid || MarketplaceOrderStatus.delivered => (
        semantic.successContainer,
        semantic.onSuccessContainer,
      ),
      MarketplaceOrderStatus.returnRequested => (
        semantic.warningContainer,
        semantic.onWarningContainer,
      ),
      MarketplaceOrderStatus.cancelled => (
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      MarketplaceOrderStatus.returned => (
        semantic.surfaceMuted,
        scheme.onSurfaceVariant,
      ),
    };
  }
}

class _OrderThumbnail extends StatelessWidget {
  const _OrderThumbnail({required this.imageUrl, required this.semanticLabel});

  final String? imageUrl;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl == null
        ? _fallback(context)
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, _) => const AppSkeletonBox(
              animate: false,
              borderRadius: BorderRadius.zero,
            ),
            errorWidget: (_, _, _) => _fallback(context),
          );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: AppRadius.small,
        child: SizedBox.square(dimension: AppSizes.brandIcon, child: image),
      ),
    );
  }

  static Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: context.semanticColors.surfaceMuted,
      child: Icon(
        Icons.inventory_2_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: AppSkeletonLoader(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, _) => const AppSkeletonBox(
                height: AppSizes.onboardingVisual,
                animate: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
