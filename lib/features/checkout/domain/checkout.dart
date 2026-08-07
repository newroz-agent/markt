enum CheckoutPaymentKind {
  card,
  paypal,
  klarna,
  sepaDebit,
  applePay,
  googlePay,
}

class CheckoutAddress {
  const CheckoutAddress({
    required this.id,
    required this.recipientName,
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.city,
    required this.countryName,
    this.additionalLine,
    this.isDefault = false,
  });

  final String id;
  final String recipientName;
  final String street;
  final String houseNumber;
  final String postalCode;
  final String city;
  final String countryName;
  final String? additionalLine;
  final bool isDefault;
}

class CheckoutLineItem {
  const CheckoutLineItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.unitPriceMinor,
    required this.currencyCode,
    this.imageUrl,
  }) : assert(quantity > 0),
       assert(unitPriceMinor >= 0);

  final String id;
  final String title;
  final int quantity;
  final int unitPriceMinor;
  final String currencyCode;
  final String? imageUrl;

  int get lineTotalMinor => unitPriceMinor * quantity;
}

class CheckoutShippingOption {
  const CheckoutShippingOption({
    required this.id,
    required this.label,
    required this.priceMinor,
    required this.currencyCode,
    this.description,
    this.estimatedDelivery,
    this.enabled = true,
  }) : assert(priceMinor >= 0);

  final String id;
  final String label;
  final int priceMinor;
  final String currencyCode;
  final String? description;
  final String? estimatedDelivery;
  final bool enabled;
}

class CheckoutSellerGroup {
  const CheckoutSellerGroup({
    required this.sellerId,
    required this.sellerName,
    required this.items,
    required this.shippingOptions,
    this.selectedShippingOptionId,
  });

  final String sellerId;
  final String sellerName;
  final List<CheckoutLineItem> items;
  final List<CheckoutShippingOption> shippingOptions;
  final String? selectedShippingOptionId;

  CheckoutShippingOption? get selectedShippingOption {
    for (final option in shippingOptions) {
      if (option.id == selectedShippingOptionId) return option;
    }
    return null;
  }

  bool get hasValidShippingSelection {
    final option = selectedShippingOption;
    return option != null && option.enabled;
  }
}

class CheckoutPaymentOption {
  const CheckoutPaymentOption({
    required this.kind,
    required this.label,
    this.description,
    this.enabled = true,
  });

  final CheckoutPaymentKind kind;
  final String label;
  final String? description;
  final bool enabled;
}

class CheckoutTotals {
  const CheckoutTotals({
    required this.subtotalMinor,
    required this.shippingMinor,
    required this.vatMinor,
    required this.totalMinor,
    required this.currencyCode,
  }) : assert(subtotalMinor >= 0),
       assert(shippingMinor >= 0),
       assert(vatMinor >= 0),
       assert(totalMinor >= 0);

  final int subtotalMinor;
  final int shippingMinor;
  final int vatMinor;
  final int totalMinor;
  final String currencyCode;
}

class CheckoutSession {
  const CheckoutSession({
    required this.sellerGroups,
    required this.paymentOptions,
    required this.totals,
    this.deliveryAddress,
    this.selectedPaymentKind,
  });

  final CheckoutAddress? deliveryAddress;
  final List<CheckoutSellerGroup> sellerGroups;
  final List<CheckoutPaymentOption> paymentOptions;
  final CheckoutPaymentKind? selectedPaymentKind;
  final CheckoutTotals totals;

  CheckoutPaymentOption? get selectedPaymentOption {
    for (final option in paymentOptions) {
      if (option.kind == selectedPaymentKind) return option;
    }
    return null;
  }

  bool get canSubmit {
    final paymentOption = selectedPaymentOption;
    return deliveryAddress != null &&
        sellerGroups.isNotEmpty &&
        sellerGroups.every((group) => group.hasValidShippingSelection) &&
        paymentOption != null &&
        paymentOption.enabled;
  }
}

class CheckoutConfirmation {
  const CheckoutConfirmation({
    required this.orderNumber,
    required this.totalMinor,
    required this.currencyCode,
  }) : assert(totalMinor >= 0);

  final String orderNumber;
  final int totalMinor;
  final String currencyCode;
}
