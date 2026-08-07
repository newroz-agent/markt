import 'package:zerin_marketplace/l10n/l10n.dart';

typedef CheckoutQuantityLabelBuilder = String Function(int quantity);

class CheckoutCopy {
  const CheckoutCopy({
    required this.title,
    required this.deliveryAddressTitle,
    required this.chooseAddressLabel,
    required this.editLabel,
    required this.shippingMethodsTitle,
    required this.paymentMethodsTitle,
    required this.orderSummaryTitle,
    required this.subtotalLabel,
    required this.shippingLabel,
    required this.vatLabel,
    required this.totalLabel,
    required this.placeOrderLabel,
    required this.legalNotice,
    required this.loadingLabel,
    required this.errorTitle,
    required this.errorMessage,
    required this.offlineTitle,
    required this.offlineMessage,
    required this.retryLabel,
    required this.quantityLabel,
  });

  factory CheckoutCopy.fromLocalizations(
    AppLocalizations l10n, {
    required String chooseAddressLabel,
    required String shippingMethodsTitle,
    required String paymentMethodsTitle,
    required String orderSummaryTitle,
    required String placeOrderLabel,
    required String legalNotice,
    required CheckoutQuantityLabelBuilder quantityLabel,
  }) {
    return CheckoutCopy(
      title: l10n.cartCheckout,
      deliveryAddressTitle: l10n.accountAddresses,
      chooseAddressLabel: chooseAddressLabel,
      editLabel: l10n.actionEdit,
      shippingMethodsTitle: shippingMethodsTitle,
      paymentMethodsTitle: paymentMethodsTitle,
      orderSummaryTitle: orderSummaryTitle,
      subtotalLabel: l10n.cartSubtotal,
      shippingLabel: l10n.cartShipping,
      vatLabel: l10n.cartVatIncluded,
      totalLabel: l10n.cartTotal,
      placeOrderLabel: placeOrderLabel,
      legalNotice: legalNotice,
      loadingLabel: l10n.stateLoading,
      errorTitle: l10n.stateErrorTitle,
      errorMessage: l10n.stateErrorMessage,
      offlineTitle: l10n.stateOfflineTitle,
      offlineMessage: l10n.stateOfflineMessage,
      retryLabel: l10n.actionRetry,
      quantityLabel: quantityLabel,
    );
  }

  final String title;
  final String deliveryAddressTitle;
  final String chooseAddressLabel;
  final String editLabel;
  final String shippingMethodsTitle;
  final String paymentMethodsTitle;
  final String orderSummaryTitle;
  final String subtotalLabel;
  final String shippingLabel;
  final String vatLabel;
  final String totalLabel;
  final String placeOrderLabel;
  final String legalNotice;
  final String loadingLabel;
  final String errorTitle;
  final String errorMessage;
  final String offlineTitle;
  final String offlineMessage;
  final String retryLabel;
  final CheckoutQuantityLabelBuilder quantityLabel;
}

class OrderConfirmationCopy {
  const OrderConfirmationCopy({
    required this.title,
    required this.message,
    required this.orderNumberLabel,
    required this.totalLabel,
    required this.emailNotice,
    required this.viewOrderLabel,
    required this.continueShoppingLabel,
  });

  final String title;
  final String message;
  final String Function(String orderNumber) orderNumberLabel;
  final String totalLabel;
  final String emailNotice;
  final String viewOrderLabel;
  final String continueShoppingLabel;
}
