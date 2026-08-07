import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:zerin_marketplace/core/theme/theme.dart';
import 'package:zerin_marketplace/core/widgets/widgets.dart';
import 'package:zerin_marketplace/features/orders/domain/marketplace_order.dart';
import 'package:zerin_marketplace/features/orders/presentation/orders_copy.dart';

sealed class OrderDetailViewState {
  const OrderDetailViewState();
}

final class OrderDetailLoading extends OrderDetailViewState {
  const OrderDetailLoading();
}

final class OrderDetailFailure extends OrderDetailViewState {
  const OrderDetailFailure({this.message});

  final String? message;
}

final class OrderDetailOffline extends OrderDetailViewState {
  const OrderDetailOffline();
}

final class OrderDetailData extends OrderDetailViewState {
  const OrderDetailData({required this.order, this.actionInProgress = false});

  final MarketplaceOrder order;
  final bool actionInProgress;
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    required this.state,
    required this.copy,
    required this.formatMoney,
    required this.formatDate,
    this.onRetry,
    this.onOpenTracking,
    this.onDownloadInvoice,
    this.onCancelOrder,
    this.onReturnOrder,
    super.key,
  });

  final OrderDetailViewState state;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;
  final OrderDateFormatter formatDate;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenTracking;
  final VoidCallback? onDownloadInvoice;
  final VoidCallback? onCancelOrder;
  final VoidCallback? onReturnOrder;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      OrderDetailData(:final order) => copy.detailTitle(order.orderNumber),
      _ => copy.title,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (state) {
        OrderDetailLoading() => _OrderDetailSkeleton(label: copy.loadingLabel),
        OrderDetailFailure(:final message) => AppErrorState(
          title: copy.errorTitle,
          message: message ?? copy.errorMessage,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        OrderDetailOffline() => AppErrorState(
          title: copy.offlineTitle,
          message: copy.offlineMessage,
          icon: Icons.wifi_off_rounded,
          retryLabel: onRetry == null ? null : copy.retryLabel,
          onRetry: onRetry,
        ),
        OrderDetailData(:final order, :final actionInProgress) =>
          _OrderDetailContent(
            order: order,
            copy: copy,
            formatMoney: formatMoney,
            formatDate: formatDate,
            actionInProgress: actionInProgress,
            onOpenTracking: onOpenTracking,
            onDownloadInvoice: onDownloadInvoice,
            onCancelOrder: onCancelOrder,
            onReturnOrder: onReturnOrder,
          ),
      },
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent({
    required this.order,
    required this.copy,
    required this.formatMoney,
    required this.formatDate,
    required this.actionInProgress,
    required this.onOpenTracking,
    required this.onDownloadInvoice,
    required this.onCancelOrder,
    required this.onReturnOrder,
  });

  final MarketplaceOrder order;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;
  final OrderDateFormatter formatDate;
  final bool actionInProgress;
  final VoidCallback? onOpenTracking;
  final VoidCallback? onDownloadInvoice;
  final VoidCallback? onCancelOrder;
  final VoidCallback? onReturnOrder;

  @override
  Widget build(BuildContext context) {
    final showActions =
        (order.invoiceUri != null && onDownloadInvoice != null) ||
        (order.canCancel && onCancelOrder != null) ||
        (order.canReturn && onReturnOrder != null);
    return SafeArea(
      top: false,
      child: Align(
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
              _OrderHeadline(
                order: order,
                copy: copy,
                formattedDate: formatDate(order.placedAt),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                title: copy.timelineTitle,
                child: _OrderTimeline(
                  order: order,
                  copy: copy,
                  formatDate: formatDate,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                title: copy.itemsTitle,
                child: _OrderItems(
                  order: order,
                  copy: copy,
                  formatMoney: formatMoney,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                title: copy.deliveryAddressTitle,
                child: _OrderAddress(address: order.deliveryAddress),
              ),
              if (order.shipment case final shipment?) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _DetailSection(
                  title: copy.shipmentTitle,
                  child: _ShipmentDetails(
                    shipment: shipment,
                    copy: copy,
                    formatDate: formatDate,
                    onOpenTracking: shipment.trackingUri == null
                        ? null
                        : onOpenTracking,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _DetailSection(
                title: copy.orderSummaryTitle,
                child: _OrderSummary(
                  totals: order.totals,
                  copy: copy,
                  formatMoney: formatMoney,
                ),
              ),
              if (order.canReturn) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        copy.withdrawalNotice(
                          order.returnDeadline == null
                              ? null
                              : formatDate(order.returnDeadline!),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showActions) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                if (order.invoiceUri != null && onDownloadInvoice != null)
                  AppButton.secondary(
                    label: copy.downloadInvoiceLabel,
                    leading: const Icon(Icons.download_outlined),
                    onPressed: onDownloadInvoice,
                    loading: actionInProgress,
                    expand: true,
                  ),
                if (order.canReturn && onReturnOrder != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.secondary(
                    label: copy.returnOrderLabel,
                    leading: const Icon(Icons.assignment_return_outlined),
                    onPressed: onReturnOrder,
                    loading: actionInProgress,
                    expand: true,
                  ),
                ],
                if (order.canCancel && onCancelOrder != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.destructive(
                    label: copy.cancelOrderLabel,
                    leading: const Icon(Icons.cancel_outlined),
                    onPressed: onCancelOrder,
                    loading: actionInProgress,
                    expand: true,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHeadline extends StatelessWidget {
  const _OrderHeadline({
    required this.order,
    required this.copy,
    required this.formattedDate,
  });

  final MarketplaceOrder order;
  final OrdersCopy copy;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                copy.orderNumberLabel(order.orderNumber),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                copy.placedAtLabel(formattedDate),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _DetailStatusBadge(
          status: order.status,
          label: copy.statusLabel(order.status),
        ),
      ],
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({
    required this.order,
    required this.copy,
    required this.formatDate,
  });

  final MarketplaceOrder order;
  final OrdersCopy copy;
  final OrderDateFormatter formatDate;

  @override
  Widget build(BuildContext context) {
    final history = order.statusHistory.isEmpty
        ? <MarketplaceOrderStatusEvent>[
            MarketplaceOrderStatusEvent(
              status: order.status,
              occurredAt: order.placedAt,
            ),
          ]
        : order.statusHistory;
    return Column(
      children: <Widget>[
        for (var index = 0; index < history.length; index++)
          _TimelineEntry(
            event: history[index],
            label: copy.statusLabel(history[index].status),
            formattedDate: formatDate(history[index].occurredAt),
            isLast: index == history.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.label,
    required this.formattedDate,
    required this.isLast,
  });

  final MarketplaceOrderStatusEvent event;
  final String label;
  final String formattedDate;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context, event.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: AppSizes.iconLarge,
          child: Column(
            children: <Widget>[
              Icon(
                isLast ? Icons.radio_button_checked : Icons.check_circle,
                size: AppSizes.iconMedium,
                color: color,
              ),
              if (!isLast)
                Container(
                  width: AppStrokes.progress,
                  height: AppSpacing.xl,
                  color: color,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  formattedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (event.note case final note?) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(note, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItems extends StatelessWidget {
  const _OrderItems({
    required this.order,
    required this.copy,
    required this.formatMoney,
  });

  final MarketplaceOrder order;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var index = 0; index < order.items.length; index++) ...<Widget>[
          _OrderItemRow(
            item: order.items[index],
            quantityLabel: copy.quantityLabel(order.items[index].quantity),
            formattedTotal: formatMoney(
              order.items[index].lineTotalMinor,
              order.items[index].currencyCode,
            ),
          ),
          if (index < order.items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
        ],
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.quantityLabel,
    required this.formattedTotal,
  });

  final MarketplaceOrderItem item;
  final String quantityLabel;
  final String formattedTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        _DetailThumbnail(imageUrl: item.imageUrl, semanticLabel: item.title),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                quantityLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(formattedTotal, style: theme.textTheme.labelLarge),
      ],
    );
  }
}

class _OrderAddress extends StatelessWidget {
  const _OrderAddress({required this.address});

  final MarketplaceOrderAddress address;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryStyle = textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.location_on_outlined),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(address.recipientName, style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${address.street} ${address.houseNumber}',
                style: secondaryStyle,
              ),
              if (address.additionalLine case final additionalLine?)
                Text(additionalLine, style: secondaryStyle),
              Text(
                '${address.postalCode} ${address.city}',
                style: secondaryStyle,
              ),
              Text(address.countryName, style: secondaryStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShipmentDetails extends StatelessWidget {
  const _ShipmentDetails({
    required this.shipment,
    required this.copy,
    required this.formatDate,
    required this.onOpenTracking,
  });

  final MarketplaceOrderShipment shipment;
  final OrdersCopy copy;
  final OrderDateFormatter formatDate;
  final VoidCallback? onOpenTracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.local_shipping_outlined),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(shipment.carrierName, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    copy.trackingCodeLabel(shipment.trackingCode),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (shipment.estimatedDelivery
                      case final estimate?) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      copy.estimatedDeliveryLabel(formatDate(estimate)),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (onOpenTracking != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: copy.openTrackingLabel,
            leading: const Icon(Icons.open_in_new_rounded),
            onPressed: onOpenTracking,
            expand: true,
          ),
        ],
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.totals,
    required this.copy,
    required this.formatMoney,
  });

  final MarketplaceOrderTotals totals;
  final OrdersCopy copy;
  final OrderMoneyFormatter formatMoney;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _DetailSummaryRow(
          label: copy.subtotalLabel,
          value: formatMoney(totals.subtotalMinor, totals.currencyCode),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DetailSummaryRow(
          label: copy.shippingLabel,
          value: formatMoney(totals.shippingMinor, totals.currencyCode),
        ),
        const SizedBox(height: AppSpacing.xs),
        _DetailSummaryRow(
          label: copy.vatLabel,
          value: formatMoney(totals.vatMinor, totals.currencyCode),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Divider(),
        ),
        _DetailSummaryRow(
          label: copy.totalLabel,
          value: formatMoney(totals.totalMinor, totals.currencyCode),
          emphasized: true,
        ),
      ],
    );
  }
}

class _DetailSummaryRow extends StatelessWidget {
  const _DetailSummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.titleMedium : textTheme.bodyMedium;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: AppSpacing.md),
        Text(value, style: style),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.status, required this.label});

  final MarketplaceOrderStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppOpacity.disabledSurface),
        borderRadius: AppRadius.pill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _DetailThumbnail extends StatelessWidget {
  const _DetailThumbnail({required this.imageUrl, required this.semanticLabel});

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

class _OrderDetailSkeleton extends StatelessWidget {
  const _OrderDetailSkeleton({required this.label});

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
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const <Widget>[
                AppSkeletonBox(height: AppSizes.controlLarge, animate: false),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.onboardingVisual,
                  animate: false,
                ),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.onboardingVisual,
                  animate: false,
                ),
                SizedBox(height: AppSpacing.md),
                AppSkeletonBox(
                  height: AppSizes.stateIllustration * 2,
                  animate: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _statusColor(BuildContext context, MarketplaceOrderStatus status) {
  final semantic = context.semanticColors;
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    MarketplaceOrderStatus.ordered ||
    MarketplaceOrderStatus.shipped => semantic.info,
    MarketplaceOrderStatus.paid ||
    MarketplaceOrderStatus.delivered => semantic.success,
    MarketplaceOrderStatus.returnRequested => semantic.warning,
    MarketplaceOrderStatus.cancelled => scheme.error,
    MarketplaceOrderStatus.returned => scheme.onSurfaceVariant,
  };
}
