import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/default_categories.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transactionId});
  final String transactionId;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  AppCategory? _category;
  DateTime _date = DateTime.now();
  bool _busy = false;
  bool _loaded = false;

  List<AppCategory> get _categoriesForType =>
      defaultCategories.where((c) => c.type == _type).toList();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _populate(AppTransaction tx) {
    _type = tx.type;
    _amountCtrl.text = tx.amount.toString();
    _noteCtrl.text = tx.note ?? '';
    _date = tx.date;
    _category = _categoriesForType.firstWhere(
      (c) => c.id == tx.categoryId,
      orElse: () => _categoriesForType.first,
    );
    _loaded = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null) return;

    setState(() => _busy = true);
    try {
      final updated = AppTransaction(
        id: widget.transactionId,
        type: _type,
        amount: double.parse(_amountCtrl.text),
        categoryId: _category!.id,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      await repo.update(updated);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null) return;
    await repo.delete(widget.transactionId);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsStreamProvider);
    final tx = txAsync.value
        ?.where((t) => t.id == widget.transactionId)
        .cast<AppTransaction?>()
        .firstWhere((_) => true, orElse: () => null);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit transaction')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_loaded) _populate(tx);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _busy ? null : _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _category = _categoriesForType.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Enter a number greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AppCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categoriesForType
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: c.color.withValues(alpha: 0.2),
                              child: Icon(c.icon, size: 16, color: c.color),
                            ),
                            const SizedBox(width: 12),
                            Text(c.name),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (c) => setState(() => _category = c),
                validator: (v) => v == null ? 'Pick a category' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.note_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
