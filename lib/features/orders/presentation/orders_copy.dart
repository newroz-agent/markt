import 'package:zerin_marketplace/features/orders/domain/marketplace_order.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

typedef OrderMoneyFormatter =
    String Function(int amountMinor, String currencyCode);
typedef OrderDateFormatter = String Function(DateTime dateTime);
typedef OrderStatusLabelBuilder =
    String Function(MarketplaceOrderStatus status);
typedef OrderQuantityLabelBuilder = String Function(int quantity);
typedef OrderWithdrawalNoticeBuilder =
    String Function(String? formattedDeadline);

class OrdersCopy {
  const OrdersCopy({
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.loadingLabel,
    required this.errorTitle,
    required this.errorMessage,
    required this.offlineTitle,
    required this.offlineMessage,
    required this.retryLabel,
    required this.orderNumberLabel,
    required this.placedAtLabel,
    required this.statusLabel,
    required this.quantityLabel,
    required this.additionalItemsLabel,
    required this.detailTitle,
    required this.timelineTitle,
    required this.itemsTitle,
    required this.deliveryAddressTitle,
    required this.shipmentTitle,
    required this.trackingCodeLabel,
    required this.estimatedDeliveryLabel,
    required this.openTrackingLabel,
    required this.orderSummaryTitle,
    required this.subtotalLabel,
    required this.shippingLabel,
    required this.vatLabel,
    required this.totalLabel,
    required this.downloadInvoiceLabel,
    required this.cancelOrderLabel,
    required this.returnOrderLabel,
    required this.withdrawalNotice,
  });

  factory OrdersCopy.fromLocalizations(
    AppLocalizations l10n, {
    required String emptyTitle,
    required String emptyMessage,
    required String Function(String orderNumber) orderNumberLabel,
    required String Function(String formattedDate) placedAtLabel,
    required OrderStatusLabelBuilder statusLabel,
    required OrderQuantityLabelBuilder quantityLabel,
    required String Function(int count) additionalItemsLabel,
    required String Function(String orderNumber) detailTitle,
    required String timelineTitle,
    required String itemsTitle,
    required String deliveryAddressTitle,
    required String shipmentTitle,
    required String Function(String trackingCode) trackingCodeLabel,
    required String Function(String formattedDate) estimatedDeliveryLabel,
    required String openTrackingLabel,
    required String orderSummaryTitle,
    required String downloadInvoiceLabel,
    required String cancelOrderLabel,
    required String returnOrderLabel,
    required OrderWithdrawalNoticeBuilder withdrawalNotice,
  }) {
    return OrdersCopy(
      title: l10n.navigationOrders,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      loadingLabel: l10n.stateLoading,
      errorTitle: l10n.stateErrorTitle,
      errorMessage: l10n.stateErrorMessage,
      offlineTitle: l10n.stateOfflineTitle,
      offlineMessage: l10n.stateOfflineMessage,
      retryLabel: l10n.actionRetry,
      orderNumberLabel: orderNumberLabel,
      placedAtLabel: placedAtLabel,
      statusLabel: statusLabel,
      quantityLabel: quantityLabel,
      additionalItemsLabel: additionalItemsLabel,
      detailTitle: detailTitle,
      timelineTitle: timelineTitle,
      itemsTitle: itemsTitle,
      deliveryAddressTitle: deliveryAddressTitle,
      shipmentTitle: shipmentTitle,
      trackingCodeLabel: trackingCodeLabel,
      estimatedDeliveryLabel: estimatedDeliveryLabel,
      openTrackingLabel: openTrackingLabel,
      orderSummaryTitle: orderSummaryTitle,
      subtotalLabel: l10n.cartSubtotal,
      shippingLabel: l10n.cartShipping,
      vatLabel: l10n.cartVatIncluded,
      totalLabel: l10n.cartTotal,
      downloadInvoiceLabel: downloadInvoiceLabel,
      cancelOrderLabel: cancelOrderLabel,
      returnOrderLabel: returnOrderLabel,
      withdrawalNotice: withdrawalNotice,
    );
  }

  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final String loadingLabel;
  final String errorTitle;
  final String errorMessage;
  final String offlineTitle;
  final String offlineMessage;
  final String retryLabel;
  final String Function(String orderNumber) orderNumberLabel;
  final String Function(String formattedDate) placedAtLabel;
  final OrderStatusLabelBuilder statusLabel;
  final OrderQuantityLabelBuilder quantityLabel;
  final String Function(int count) additionalItemsLabel;
  final String Function(String orderNumber) detailTitle;
  final String timelineTitle;
  final String itemsTitle;
  final String deliveryAddressTitle;
  final String shipmentTitle;
  final String Function(String trackingCode) trackingCodeLabel;
  final String Function(String formattedDate) estimatedDeliveryLabel;
  final String openTrackingLabel;
  final String orderSummaryTitle;
  final String subtotalLabel;
  final String shippingLabel;
  final String vatLabel;
  final String totalLabel;
  final String downloadInvoiceLabel;
  final String cancelOrderLabel;
  final String returnOrderLabel;
  final OrderWithdrawalNoticeBuilder withdrawalNotice;
}
