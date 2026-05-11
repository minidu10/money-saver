import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recurring_template.dart';
import '../models/transaction.dart';
import 'auth_repository.dart';
import 'transaction_repository.dart';

final recurringRepositoryProvider = Provider<RecurringRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return RecurringRepository(
    firestore: ref.watch(firestoreProvider),
    uid: user.uid,
  );
});

final recurringStreamProvider =
    StreamProvider<List<RecurringTemplate>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAll();
});

class RecurringRepository {
  RecurringRepository({required this.firestore, required this.uid});
  final FirebaseFirestore firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col => firestore
      .collection('users')
      .doc(uid)
      .collection('recurring_templates');

  CollectionReference<Map<String, dynamic>> get _txCol =>
      firestore.collection('users').doc(uid).collection('transactions');

  Stream<List<RecurringTemplate>> watchAll() {
    return _col.snapshots().map(
          (s) => s.docs
              .map((d) => RecurringTemplate.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> add(RecurringTemplate t) async => await _col.add(t.toMap());

  Future<void> delete(String id) async => await _col.doc(id).delete();

  /// Generate due transactions from each template and bump nextDue forward.
  /// Safe to call multiple times — each template advances independently.
  Future<int> processDue() async {
    final snap = await _col.get();
    int generated = 0;
    final today = DateTime.now();
    final batch = firestore.batch();

    for (final doc in snap.docs) {
      var template = RecurringTemplate.fromMap(doc.id, doc.data());
      while (!template.nextDue.isAfter(today)) {
        batch.set(_txCol.doc(), AppTransaction(
          id: '',
          type: template.type,
          amount: template.amount,
          categoryId: template.categoryId,
          date: template.nextDue,
          note: template.note,
          isRecurring: true,
        ).toMap());
        generated++;
        template = RecurringTemplate(
          id: template.id,
          type: template.type,
          amount: template.amount,
          categoryId: template.categoryId,
          note: template.note,
          interval: template.interval,
          nextDue: template.advance(template.nextDue),
        );
      }
      if (generated > 0) {
        batch.update(doc.reference, {
          'nextDue': template.nextDue.toUtc().toIso8601String(),
        });
      }
    }

    if (generated > 0) await batch.commit();
    return generated;
  }
}
