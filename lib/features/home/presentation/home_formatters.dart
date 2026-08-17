import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String formatMarketplacePrice(Locale locale, int amountCents, String currency) {
  final symbol = currency == 'EUR' ? '€' : currency;
  return NumberFormat.currency(
    locale: locale.toLanguageTag(),
    symbol: symbol,
    decimalDigits: 2,
  ).format(amountCents / 100);
}
