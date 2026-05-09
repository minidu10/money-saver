enum TransactionType { income, expense }

class AppTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? note;
  final bool isRecurring;

  const AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toUtc().toIso8601String(),
        'note': note,
        'isRecurring': isRecurring,
      };

  factory AppTransaction.fromMap(String id, Map<String, dynamic> m) =>
      AppTransaction(
        id: id,
        type: TransactionType.values.byName(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['categoryId'] as String,
        date: DateTime.parse(m['date'] as String),
        note: m['note'] as String?,
        isRecurring: (m['isRecurring'] as bool?) ?? false,
      );
}
