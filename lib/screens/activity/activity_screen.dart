import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../expenses/expense_details_screen.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('No activity yet.'));
          }

          // Group by date
          Map<String, List<Expense>> grouped = {};
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));

          for (var e in expenses) {
            final eDate = DateTime(e.date.year, e.date.month, e.date.day);
            String label;
            if (eDate == today)
              label = 'Today';
            else if (eDate == yesterday)
              label = 'Yesterday';
            else
              label = DateFormat('dd MMM yyyy').format(e.date);

            if (!grouped.containsKey(label)) grouped[label] = [];
            grouped[label]!.add(e);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: grouped.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Swipe left on an item to delete it',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }

              String label = grouped.keys.elementAt(i - 1);
              List<Expense> dayExpenses = grouped[label]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDayHeader(context, label),
                  ...dayExpenses
                      .map((e) => _DismissibleExpenseItem(expense: e))
                      .toList(),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, String day) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        day,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Expense e) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Hero(
                tag: 'expense_icon_${e.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    e.categoryIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${e.group.value?.name ?? 'No Group'} • Paid by ${e.contributions.isNotEmpty ? e.contributions.first.memberName : 'Unknown'}',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${e.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                DateFormat('HH:mm').format(e.date),
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DismissibleExpenseItem extends ConsumerWidget {
  final Expense expense;
  const _DismissibleExpenseItem({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key('activity_${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (dir) => _deleteExpense(context, ref),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseDetailsScreen(expense: expense),
          ),
        ),
        child: const ActivityScreen()._buildActivityItem(context, expense),
      ),
    );
  }

  void _deleteExpense(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dbServiceProvider).isar;
    final expenseId = expense.id;

    // Capture data for undo
    final capturedExpense = Expense()
      ..id = expense.id
      ..title = expense.title
      ..totalAmount = expense.totalAmount
      ..category = expense.category
      ..categoryIcon = expense.categoryIcon
      ..date = expense.date
      ..splitMode = expense.splitMode
      ..splits = expense.splits
      ..contributions = expense.contributions;
    final capturedGroup = expense.group.value;

    await db.writeTxn(() async {
      await db.collection<Expense>().delete(expenseId);
    });

    if (context.mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${capturedExpense.title}'),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: theme.colorScheme.primary,
            onPressed: () async {
              await db.writeTxn(() async {
                await db.collection<Expense>().put(capturedExpense);
                if (capturedGroup != null) {
                  capturedExpense.group.value = capturedGroup;
                  await capturedExpense.group.save();
                }
              });
            },
          ),
        ),
      );
    }
  }
}
