import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import 'auth_repository.dart';
import 'transaction_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return BudgetRepository(
    firestore: ref.watch(firestoreProvider),
    uid: user.uid,
  );
});

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAll();
});

class BudgetRepository {
  BudgetRepository({required this.firestore, required this.uid});
  final FirebaseFirestore firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('budgets');

  Stream<List<Budget>> watchAll() {
    return _col.snapshots().map(
          (s) => s.docs.map((d) => Budget.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> upsert(Budget b) async {
    await _col.doc(b.key).set(b.toMap());
  }

  Future<void> delete(String id) async => await _col.doc(id).delete();
}
