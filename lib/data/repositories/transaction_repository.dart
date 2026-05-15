import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_cache.dart';
import '../models/transaction.dart';
import 'auth_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return TransactionRepository(
    firestore: ref.watch(firestoreProvider),
    uid: user.uid,
  );
});

/// Reads from the Hive cache first (instant cold start), then merges with the
/// Firestore live stream. Each Firestore emission is also written back to Hive
/// so the next cold start renders the latest known data immediately.
final transactionsStreamProvider =
    StreamProvider<List<AppTransaction>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield const [];
    return;
  }

  final cache = ref.read(localTransactionsCacheProvider);
  final cached = cache.load(user.uid);
  if (cached != null) yield cached;

  final repo = ref.watch(transactionRepositoryProvider);
  if (repo == null) return;

  await for (final list in repo.watchAll()) {
    await cache.save(user.uid, list);
    yield list;
  }
});

class TransactionRepository {
  TransactionRepository({required this.firestore, required this.uid});

  final FirebaseFirestore firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('transactions');

  Stream<List<AppTransaction>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map(
          (s) => s.docs
              .map((d) => AppTransaction.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> add(AppTransaction tx) async {
    await _col.add(tx.toMap());
  }

  Future<void> update(AppTransaction tx) async {
    await _col.doc(tx.id).set(tx.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
