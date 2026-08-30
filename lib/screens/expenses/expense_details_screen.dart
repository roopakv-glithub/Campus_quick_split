import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/db_provider.dart';

class ExpenseDetailsScreen extends ConsumerWidget {
  final Expense expense;
  const ExpenseDetailsScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textSecondary = theme.textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'expense_icon_${expense.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            expense.categoryIcon,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${expense.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMMM yyyy, HH:mm').format(expense.date),
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoRow(
              'Category',
              expense.category,
              Icons.category_outlined,
            ),
            _buildInfoRow(
              'Group',
              expense.group.value?.name ?? 'No Group',
              Icons.group_outlined,
            ),
            _buildPaidBySection(context, theme),
            const SizedBox(height: 32),
            const Text(
              'Split Breakdown',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...expense.splits.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    s.memberName?[0] ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(s.memberName ?? 'Unknown'),
                trailing: Text(
                  '₹${s.amount?.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'QuickSplit supports multiple payers, so more than one member can contribute to the same bill.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidBySection(BuildContext context, ThemeData theme) {
    if (expense.contributions.length <= 1) {
      return _buildInfoRow(
        'Paid by',
        expense.contributions.firstOrNull?.memberName ?? 'Unknown',
        Icons.person_pin_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_pin_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 16),
              const Text(
                'Paid by',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...expense.contributions.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 8),
              child: Row(
                children: [
                  Text(
                    c.memberName ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '₹${c.amount?.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This will permanently remove this expense.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final db = ref.read(dbServiceProvider).isar;
              final expenseId = expense.id;

              // Capture data before deletion for undo
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
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop details screen

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted ${capturedExpense.title}'),
                    action: SnackBarAction(
                      label: 'Undo',
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
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
