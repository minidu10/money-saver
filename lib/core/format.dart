import 'package:intl/intl.dart';

String formatMoney(
  double amount, {
  required String symbol,
  int decimals = 2,
}) {
  final f = NumberFormat.currency(symbol: '$symbol ', decimalDigits: decimals);
  return f.format(amount);
}

String formatDate(DateTime date) =>
    DateFormat('d MMM y').format(date.toLocal());

String formatDateTime(DateTime date) =>
    DateFormat('d MMM y · h:mm a').format(date.toLocal());
