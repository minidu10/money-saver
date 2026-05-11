import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/preferences.dart';
import '../../data/models/goal.dart';
import '../../data/repositories/goal_repository.dart';

class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load goals:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.savings_outlined,
                        size: 72, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No savings goals yet'),
                    SizedBox(height: 4),
                    Text('Tap + to set your first one',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-goal'),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currency = currencyFor(ref.watch(currencyProvider));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showGoalSheet(context, ref, goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (goal.isComplete)
                    Chip(
                      label: const Text('Done'),
                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatMoney(goal.saved, symbol: currency.symbol, decimals: 0)} '
                'of ${formatMoney(goal.target, symbol: currency.symbol, decimals: 0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(goal.progress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (goal.deadline != null)
                    Text(
                      'By ${formatDate(goal.deadline!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showGoalSheet(BuildContext context, WidgetRef ref, Goal goal) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add deposit'),
            onTap: () {
              Navigator.pop(ctx);
              _showAddDepositDialog(context, ref, goal);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete goal'),
            onTap: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Delete this goal?'),
                  content: Text('"${goal.title}" will be deleted permanently.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text('Cancel')),
                    FilledButton.tonal(
                        onPressed: () => Navigator.pop(dctx, true),
                        child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(goalRepositoryProvider)?.delete(goal.id);
              }
            },
          ),
        ],
      ),
    ),
  );
}

void _showAddDepositDialog(
    BuildContext context, WidgetRef ref, Goal goal) {
  final ctrl = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Add to "${goal.title}"'),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Amount',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final amount = double.tryParse(ctrl.text);
            if (amount == null || amount <= 0) return;
            await ref
                .read(goalRepositoryProvider)
                ?.addDeposit(goal.id, amount);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
