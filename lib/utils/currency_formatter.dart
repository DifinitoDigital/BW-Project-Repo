import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static final NumberFormat _compactNairaFormat = NumberFormat.compactCurrency(
    locale: 'en_NG',
    symbol: '₦',
  );

  static String format(double amount) {
    return _nairaFormat.format(amount);
  }

  static String formatCompact(double amount) {
    return _compactNairaFormat.format(amount);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('dd MMM, hh:mm a').format(dt);
  }
}
