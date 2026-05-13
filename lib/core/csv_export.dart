import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/default_categories.dart';
import '../data/models/transaction.dart';

String buildTransactionsCsv(List<AppTransaction> txs) {
  final buf = StringBuffer();
  buf.writeln('Date,Type,Category,Amount,Note');
  for (final t in txs) {
    final cat = categoryById(t.categoryId).name;
    final date = t.date.toIso8601String().substring(0, 10);
    final type = t.type.name;
    final note = (t.note ?? '').replaceAll('"', '""');
    buf.writeln('$date,$type,"$cat",${t.amount},"$note"');
  }
  return buf.toString();
}

Future<void> exportTransactionsAsCsv(List<AppTransaction> txs) async {
  final csv = buildTransactionsCsv(txs);
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final file = File('${dir.path}/money-saver-$stamp.csv');
  await file.writeAsString(csv);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Money Saver export',
      text: 'Transactions exported from Money Saver',
    ),
  );
}
