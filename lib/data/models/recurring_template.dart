import 'transaction.dart';

enum RecurInterval { daily, weekly, monthly }

class RecurringTemplate {
  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String? note;
  final RecurInterval interval;
  final DateTime nextDue;

  const RecurringTemplate({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.interval,
    required this.nextDue,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,
        'categoryId': categoryId,
        'note': note,
        'interval': interval.name,
        'nextDue': nextDue.toUtc().toIso8601String(),
      };

  factory RecurringTemplate.fromMap(String id, Map<String, dynamic> m) =>
      RecurringTemplate(
        id: id,
        type: TransactionType.values.byName(m['type'] as String),
        amount: (m['amount'] as num).toDouble(),
        categoryId: m['categoryId'] as String,
        note: m['note'] as String?,
        interval: RecurInterval.values.byName(m['interval'] as String),
        nextDue: DateTime.parse(m['nextDue'] as String),
      );

  DateTime advance(DateTime from) {
    switch (interval) {
      case RecurInterval.daily:
        return DateTime(from.year, from.month, from.day + 1);
      case RecurInterval.weekly:
        return DateTime(from.year, from.month, from.day + 7);
      case RecurInterval.monthly:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }
}
