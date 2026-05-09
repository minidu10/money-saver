import 'package:intl/intl.dart';

const String defaultCurrencyCode = 'LKR';
const String defaultCurrencySymbol = 'Rs';

String formatMoney(double amount,
    {String symbol = defaultCurrencySymbol, int decimals = 2}) {
  final f = NumberFormat.currency(
    symbol: '$symbol ',
    decimalDigits: decimals,
  );
  return f.format(amount);
}

String formatDate(DateTime date) =>
    DateFormat('d MMM y').format(date.toLocal());

String formatDateTime(DateTime date) =>
    DateFormat('d MMM y · h:mm a').format(date.toLocal());
