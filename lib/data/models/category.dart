import 'transaction.dart';

class AppCategory {
  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final TransactionType type;

  const AppCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.type,
  });
}
