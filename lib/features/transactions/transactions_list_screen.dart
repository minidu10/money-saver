import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/default_categories.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  String _query = '';
  TransactionType? _typeFilter;
  String? _categoryFilter;
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final currency = currencyFor(ref.watch(currencyProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All transactions'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _typeFilter != null ||
                  _categoryFilter != null ||
                  _range != null,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: 'Filter',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final filtered = _applyFilters(all);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search note or category',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _query = ''),
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 56, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No transactions match'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _TxRow(
                          tx: filtered[i],
                          currencySymbol: currency.symbol,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppTransaction> _applyFilters(List<AppTransaction> all) {
    Iterable<AppTransaction> r = all;
    if (_typeFilter != null) {
      r = r.where((t) => t.type == _typeFilter);
    }
    if (_categoryFilter != null) {
      r = r.where((t) => t.categoryId == _categoryFilter);
    }
    if (_range != null) {
      final start = DateTime(_range!.start.year, _range!.start.month,
          _range!.start.day);
      final end = DateTime(_range!.end.year, _range!.end.month,
              _range!.end.day)
          .add(const Duration(days: 1));
      r = r.where((t) => !t.date.isBefore(start) && t.date.isBefore(end));
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      r = r.where((t) {
        final note = (t.note ?? '').toLowerCase();
        final cat = categoryById(t.categoryId).name.toLowerCase();
        return note.contains(q) || cat.contains(q);
      });
    }
    return r.toList();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final allCats = defaultCategories;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                const Text('Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _typeFilter == null,
                      onSelected: (_) => setSheet(() => _typeFilter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: _typeFilter == TransactionType.income,
                      onSelected: (_) => setSheet(
                          () => _typeFilter = TransactionType.income),
                    ),
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: _typeFilter == TransactionType.expense,
                      onSelected: (_) => setSheet(
                          () => _typeFilter = TransactionType.expense),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setSheet(() => _categoryFilter = null),
                    ),
                    for (final c in allCats)
                      ChoiceChip(
                        avatar: Icon(c.icon, size: 16, color: c.color),
                        label: Text(c.name),
                        selected: _categoryFilter == c.id,
                        onSelected: (_) =>
                            setSheet(() => _categoryFilter = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: ctx,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 1)),
                            initialDateRange: _range,
                          );
                          if (picked != null) setSheet(() => _range = picked);
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(_range == null
                            ? 'Any date'
                            : '${formatDate(_range!.start)} – ${formatDate(_range!.end)}'),
                      ),
                    ),
                    if (_range != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setSheet(() => _range = null),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setSheet(() {
                            _typeFilter = null;
                            _categoryFilter = null;
                            _range = null;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TxRow extends ConsumerWidget {
  const _TxRow({required this.tx, required this.currencySymbol});
  final AppTransaction tx;
  final String currencySymbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = categoryById(tx.categoryId);
    final isIncome = tx.type == TransactionType.income;
    final sign = isIncome ? '+' : '-';
    final color = isIncome ? Colors.green.shade700 : Colors.red.shade700;

    return ListTile(
      onTap: () => context.push('/edit-transaction/${tx.id}'),
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
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
