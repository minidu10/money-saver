import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/transaction.dart';

const String _txBoxName = 'transactions_cache_v1';

class LocalTransactionsCache {
  LocalTransactionsCache(this._box);
  final Box<dynamic> _box;

  static Future<LocalTransactionsCache> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<dynamic>(_txBoxName);
    return LocalTransactionsCache(box);
  }

  List<AppTransaction>? load(String uid) {
    final raw = _box.get(uid);
    if (raw == null) return null;
    try {
      return (raw as List)
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final id = m.remove('id') as String;
            return AppTransaction.fromMap(id, m);
          })
          .toList(growable: false);
    } catch (_) {
      // Corrupted entry — drop it and re-cache on next sync.
      _box.delete(uid);
      return null;
    }
  }

  Future<void> save(String uid, List<AppTransaction> txs) async {
    final list = txs.map((t) {
      final m = t.toMap();
      m['id'] = t.id;
      return m;
    }).toList();
    await _box.put(uid, list);
  }

  Future<void> clear(String uid) async => _box.delete(uid);
}

final localTransactionsCacheProvider = Provider<LocalTransactionsCache>(
  (_) => throw UnimplementedError(
    'Override localTransactionsCacheProvider in main() with the initialized cache.',
  ),
);
