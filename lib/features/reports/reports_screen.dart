import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/default_categories.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final currency = currencyFor(ref.watch(currencyProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (txs) {
          if (txs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_chart_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Charts appear once you add some transactions'),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('This month by category',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _CategoryPie(txs: txs, currencySymbol: currency.symbol),
              const SizedBox(height: 32),
              Text('Last 6 months',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _MonthlyBars(txs: txs, currencySymbol: currency.symbol),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.txs, required this.currencySymbol});
  final List<AppTransaction> txs;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpenses = txs.where((t) =>
        t.type == TransactionType.expense &&
        t.date.year == now.year &&
        t.date.month == now.month);

    if (monthExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No expenses this month yet')),
        ),
      );
    }

    final byCat = <String, double>{};
    for (final t in monthExpenses) {
      byCat.update(t.categoryId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final total = byCat.values.fold(0.0, (a, v) => a + v);
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    for (final e in entries)
                      PieChartSectionData(
                        value: e.value,
                        color: categoryById(e.key).color,
                        title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
                        radius: 56,
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryById(e.key).color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(categoryById(e.key).name)),
                    Text(
                      formatMoney(e.value,
                          symbol: currencySymbol, decimals: 0),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({required this.txs, required this.currencySymbol});
  final List<AppTransaction> txs;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - 5 + i);
      return DateTime(m.year, m.month);
    });

    double income(DateTime m) => txs
        .where((t) =>
            t.type == TransactionType.income &&
            t.date.year == m.year &&
            t.date.month == m.month)
        .fold(0.0, (a, t) => a + t.amount);

    double expense(DateTime m) => txs
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == m.year &&
            t.date.month == m.month)
        .fold(0.0, (a, t) => a + t.amount);

    final maxVal = months
        .map((m) => [income(m), expense(m)].reduce((a, b) => a > b ? a : b))
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxVal == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No data for the last 6 months')),
        ),
      );
    }

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              monthNames[months[i].month - 1],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: income(months[i]),
                            color: Colors.green.shade600,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: expense(months[i]),
                            color: Colors.red.shade400,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: Colors.green.shade600, label: 'Income'),
                const SizedBox(width: 20),
                _Legend(color: Colors.red.shade400, label: 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
