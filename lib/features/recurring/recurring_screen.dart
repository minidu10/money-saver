import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/default_categories.dart';
import '../../data/models/category.dart';
import '../../data/models/recurring_template.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/recurring_repository.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recurringStreamProvider);
    final currency = currencyFor(ref.watch(currencyProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No recurring transactions yet'),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to add salary, rent, etc.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = items[i];
              final cat = categoryById(t.categoryId);
              final isIncome = t.type == TransactionType.income;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: cat.color.withValues(alpha: 0.2),
                  child: Icon(cat.icon, color: cat.color),
                ),
                title: Text(cat.name),
                subtitle: Text(
                  '${_intervalLabel(t.interval)} · next ${formatDate(t.nextDue)}'
                  '${t.note?.isNotEmpty == true ? " · ${t.note}" : ""}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isIncome ? "+" : "-"}${formatMoney(t.amount, symbol: currency.symbol, decimals: 0)}',
                      style: TextStyle(
                        color: isIncome
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(recurringRepositoryProvider)
                          ?.delete(t.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecurring(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  static String _intervalLabel(RecurInterval i) => switch (i) {
        RecurInterval.daily => 'Daily',
        RecurInterval.weekly => 'Weekly',
        RecurInterval.monthly => 'Monthly',
      };
}

void _showAddRecurring(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: const _RecurringForm(),
    ),
  );
}

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm();

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  AppCategory? _cat;
  RecurInterval _interval = RecurInterval.monthly;
  DateTime _nextDue = DateTime.now();

  List<AppCategory> get _cats =>
      defaultCategories.where((c) => c.type == _type).toList();

  @override
  void initState() {
    super.initState();
    _cat = _cats.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(recurringRepositoryProvider);
    if (repo == null) return;
    await repo.add(RecurringTemplate(
      id: '',
      type: _type,
      amount: double.parse(_amountCtrl.text),
      categoryId: _cat!.id,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      interval: _interval,
      nextDue: _nextDue,
    ));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                    value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(
                    value: TransactionType.income, label: Text('Income')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _cat = _cats.first;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0
                  ? null
                  : 'Enter an amount > 0',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppCategory>(
              initialValue: _cat,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _cats
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18, color: c.color),
                          const SizedBox(width: 8),
                          Text(c.name),
                        ],
                      )))
                  .toList(),
              onChanged: (c) => setState(() => _cat = c),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecurInterval>(
              initialValue: _interval,
              decoration: const InputDecoration(
                labelText: 'Repeats',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: RecurInterval.daily, child: Text('Daily')),
                DropdownMenuItem(
                    value: RecurInterval.weekly, child: Text('Weekly')),
                DropdownMenuItem(
                    value: RecurInterval.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _interval = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDue,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) setState(() => _nextDue = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'First occurrence',
                  border: OutlineInputBorder(),
                ),
                child: Text(formatDate(_nextDue)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Create'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
