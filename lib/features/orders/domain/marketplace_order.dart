enum MarketplaceOrderStatus {
  ordered,
  paid,
  shipped,
  delivered,
  cancelled,
  returnRequested,
  returned,
}

class MarketplaceOrderAddress {
  const MarketplaceOrderAddress({
    required this.recipientName,
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.city,
    required this.countryName,
    this.additionalLine,
  });

  final String recipientName;
  final String street;
  final String houseNumber;
  final String postalCode;
  final String city;
  final String countryName;
  final String? additionalLine;
}

class MarketplaceOrderItem {
  const MarketplaceOrderItem({
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

class MarketplaceOrderStatusEvent {
  const MarketplaceOrderStatusEvent({
    required this.status,
    required this.occurredAt,
    this.note,
  });

  final MarketplaceOrderStatus status;
  final DateTime occurredAt;
  final String? note;
}

class MarketplaceOrderShipment {
  const MarketplaceOrderShipment({
    required this.carrierName,
    required this.trackingCode,
    this.trackingUri,
    this.estimatedDelivery,
  });

  final String carrierName;
  final String trackingCode;
  final Uri? trackingUri;
  final DateTime? estimatedDelivery;
}

class MarketplaceOrderTotals {
  const MarketplaceOrderTotals({
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

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.id,
    required this.orderNumber,
    required this.sellerName,
    required this.placedAt,
    required this.status,
    required this.items,
    required this.statusHistory,
    required this.deliveryAddress,
    required this.totals,
    this.shipment,
    this.invoiceUri,
    this.returnDeadline,
    this.canCancel = false,
    this.canReturn = false,
  });

  final String id;
  final String orderNumber;
  final String sellerName;
  final DateTime placedAt;
  final MarketplaceOrderStatus status;
  final List<MarketplaceOrderItem> items;
  final List<MarketplaceOrderStatusEvent> statusHistory;
  final MarketplaceOrderAddress deliveryAddress;
  final MarketplaceOrderTotals totals;
  final MarketplaceOrderShipment? shipment;
  final Uri? invoiceUri;
  final DateTime? returnDeadline;
  final bool canCancel;
  final bool canReturn;

  int get itemCount {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}
