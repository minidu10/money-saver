import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import 'auth_repository.dart';
import 'transaction_repository.dart';

final goalRepositoryProvider = Provider<GoalRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return GoalRepository(
    firestore: ref.watch(firestoreProvider),
    uid: user.uid,
  );
});

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  if (repo == null) return Stream.value(const []);
  return repo.watchAll();
});

class GoalRepository {
  GoalRepository({required this.firestore, required this.uid});
  final FirebaseFirestore firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('goals');

  Stream<List<Goal>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs.map((d) => Goal.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> add(Goal goal) async => await _col.add(goal.toMap());

  Future<void> update(Goal goal) async =>
      await _col.doc(goal.id).set(goal.toMap());

  Future<void> delete(String id) async => await _col.doc(id).delete();

  Future<void> addDeposit(String id, double amount) async {
    await _col.doc(id).update({
      'saved': FieldValue.increment(amount),
    });
  }
}
