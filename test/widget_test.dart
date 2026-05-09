import 'package:flutter_test/flutter_test.dart';
import 'package:money_saver/data/models/transaction.dart';

void main() {
  test('AppTransaction round-trips through map', () {
    final tx = AppTransaction(
      id: 'abc',
      type: TransactionType.expense,
      amount: 1500.50,
      categoryId: 'food',
      date: DateTime.utc(2026, 5, 10, 12, 0),
      note: 'lunch',
    );

    final restored = AppTransaction.fromMap('abc', tx.toMap());

    expect(restored.id, tx.id);
    expect(restored.type, tx.type);
    expect(restored.amount, tx.amount);
    expect(restored.categoryId, tx.categoryId);
    expect(restored.date, tx.date);
    expect(restored.note, tx.note);
    expect(restored.isRecurring, tx.isRecurring);
  });
}
