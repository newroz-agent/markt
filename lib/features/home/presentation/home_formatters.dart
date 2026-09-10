import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:zerin_marketplace/l10n/l10n.dart';

String formatMarketplacePrice(Locale locale, int amountCents, String currency) {
  final symbol = currency == 'EUR' ? '€' : currency;
  final numberLocale = Intl.canonicalizedLocale(locale.toLanguageTag());
  // intl has no Kurdish number symbols. Keep app strings in Kurdish while
  // using the marketplace's German fallback for unsupported number locales.
  return NumberFormat.currency(
    locale: NumberFormat.localeExists(numberLocale)
        ? numberLocale
        : AppLocale.defaultLocale.languageCode,
    symbol: symbol,
    decimalDigits: 2,
  ).format(amountCents / 100);
}
