import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/default_categories.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final txAsync = ref.watch(transactionsStreamProvider);
    final currency = currencyFor(ref.watch(currencyProvider));

    final greeting = user?.displayName?.isNotEmpty == true
        ? 'Hi, ${user!.displayName}'
        : 'Hi 👋';

    return Scaffold(
      appBar: AppBar(title: const Text('Money Saver')),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load transactions:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (transactions) => _HomeBody(
          greeting: greeting,
          transactions: transactions,
          currencySymbol: currency.symbol,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({
    required this.greeting,
    required this.transactions,
    required this.currencySymbol,
  });

  final String greeting;
  final List<AppTransaction> transactions;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthTx = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final income = monthTx
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (a, t) => a + t.amount);
    final expense = monthTx
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (a, t) => a + t.amount);
    final balance = income - expense;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(greeting, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _BalanceCard(
          balance: balance,
          income: income,
          expense: expense,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent transactions',
                style: Theme.of(context).textTheme.titleMedium),
            if (transactions.length > 20)
              const Text('Showing 20', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No transactions yet'),
                  SizedBox(height: 4),
                  Text('Tap + to add your first one',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          ...transactions
              .take(20)
              .map((t) => _TransactionTile(tx: t, currencySymbol: currencySymbol)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currencySymbol,
  });

  final double balance;
  final double income;
  final double expense;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              formatMoney(balance, symbol: currencySymbol),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _InOutLine(
                    label: 'Income',
                    amount: income,
                    icon: Icons.arrow_upward,
                    color: Colors.green.shade700,
                    currencySymbol: currencySymbol,
                  ),
                ),
                Expanded(
                  child: _InOutLine(
                    label: 'Expense',
                    amount: expense,
                    icon: Icons.arrow_downward,
                    color: Colors.red.shade700,
                    currencySymbol: currencySymbol,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InOutLine extends StatelessWidget {
  const _InOutLine({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currencySymbol,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              formatMoney(amount, symbol: currencySymbol, decimals: 0),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.tx, required this.currencySymbol});
  final AppTransaction tx;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = categoryById(tx.categoryId);
    final isIncome = tx.type == TransactionType.income;
    final sign = isIncome ? '+' : '-';
    final amountColor = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final repo = ref.read(transactionRepositoryProvider);
        if (repo == null) return;
        final snapshot = tx;
        await repo.delete(tx.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => repo.add(snapshot),
            ),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.color.withValues(alpha: 0.2),
          child: Icon(cat.icon, color: cat.color),
        ),
        title: Text(cat.name),
        subtitle: Text(
          tx.note?.isNotEmpty == true
              ? '${formatDate(tx.date)} · ${tx.note}'
              : formatDate(tx.date),
        ),
        trailing: Text(
          '$sign${formatMoney(tx.amount, symbol: currencySymbol)}',
          style: TextStyle(color: amountColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
