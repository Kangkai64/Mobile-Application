import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'RM',
    decimalDigits: 2,
    locale: 'ms_MY',
  );

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatNullable(double? amount) {
    if (amount == null) return 'RM0.00';
    return _currencyFormat.format(amount);
  }
}
