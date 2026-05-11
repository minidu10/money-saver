import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/default_categories.dart';
import '../../data/models/budget.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final txAsync = ref.watch(transactionsStreamProvider);
    final currency = currencyFor(ref.watch(currencyProvider));

    return Scaffold(
      appBar: AppBar(title: Text('Budgets · ${_monthLabel(now)}')),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          final currentBudgets = budgets
              .where((b) => b.year == now.year && b.month == now.month)
              .toList();
          final txs = txAsync.value ?? const [];
          final expenseCats = defaultCategories
              .where((c) => c.type == TransactionType.expense)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final cat in expenseCats)
                _BudgetRow(
                  cat: cat,
                  budget: currentBudgets
                      .where((b) => b.categoryId == cat.id)
                      .cast<Budget?>()
                      .firstWhere((_) => true, orElse: () => null),
                  spent: txs
                      .where((t) =>
                          t.type == TransactionType.expense &&
                          t.categoryId == cat.id &&
                          t.date.year == now.year &&
                          t.date.month == now.month)
                      .fold(0.0, (a, t) => a + t.amount),
                  currencySymbol: currency.symbol,
                ),
            ],
          );
        },
      ),
    );
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({
    required this.cat,
    required this.budget,
    required this.spent,
    required this.currencySymbol,
  });

  final AppCategory cat;
  final Budget? budget;
  final double spent;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = budget?.limit;
    final progress = (limit == null || limit == 0)
        ? 0.0
        : (spent / limit).clamp(0.0, 1.0);
    final over = limit != null && spent > limit;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSetBudget(context, ref, cat, budget),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cat.color.withValues(alpha: 0.2),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    limit == null
                        ? 'No limit set'
                        : '${formatMoney(spent, symbol: currencySymbol, decimals: 0)} / ${formatMoney(limit, symbol: currencySymbol, decimals: 0)}',
                    style: TextStyle(
                      color: over ? Colors.red.shade700 : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (limit != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: over ? Colors.red.shade600 : null,
                  ),
                ),
                if (over)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Over by ${formatMoney(spent - limit, symbol: currencySymbol, decimals: 0)}',
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showSetBudget(
    BuildContext context, WidgetRef ref, AppCategory cat, Budget? existing) {
  final ctrl = TextEditingController(
      text: existing?.limit.toStringAsFixed(0) ?? '');
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Set monthly limit for ${cat.name}'),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Limit',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () async {
              await ref.read(budgetRepositoryProvider)?.delete(existing.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final v = double.tryParse(ctrl.text);
            if (v == null || v <= 0) return;
            final now = DateTime.now();
            final budget = Budget(
              id: '',
              categoryId: cat.id,
              limit: v,
              year: now.year,
              month: now.month,
            );
            await ref.read(budgetRepositoryProvider)?.upsert(budget);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
