import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../services/settlement_service.dart';
import '../expenses/expense_details_screen.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(dbServiceProvider).isar;
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildGroupStatsCard(theme, db),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.textTheme.titleLarge?.color,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, db),
                _buildExpensesTab(theme, expensesAsync),
                _buildBalancesTab(theme, db),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatsCard(ThemeData theme, Isar db) {
    return FutureBuilder<double>(
      future: _getGroupTotalSpent(db),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0.0;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerTheme.color ?? AppColors.getBorder(context),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.group.members.length} Members',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double> _getGroupTotalSpent(Isar db) async {
    final expenses = await db
        .collection<Expense>()
        .filter()
        .group((q) => q.idEqualTo(widget.group.id))
        .findAll();
    double sum = 0;
    for (var e in expenses) {
      sum += e.totalAmount;
    }
    return sum;
  }

  Widget _buildOverviewTab(ThemeData theme, Isar db) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Optimization Result',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, int>>(
          future: SettlementService.getOptimizationStats(db, widget.group.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final stats = snapshot.data!;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Manual', '${stats['manual']}'),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.textSecondary,
                  ),
                  _buildStatColumn('Optimized', '${stats['optimized']}'),
                  _buildStatColumn(
                    'Saved',
                    '${stats['saved']}',
                    isHighlight: true,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.success : null,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab(
    ThemeData theme,
    AsyncValue<List<Expense>> expensesAsync,
  ) {
    return expensesAsync.when(
      data: (allExpenses) {
        final groupExpenses = allExpenses
            .where((e) => e.group.value?.id == widget.group.id)
            .toList();
        if (groupExpenses.isEmpty)
          return const Center(child: Text('No expenses yet.'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: groupExpenses.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe left to delete expense',
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
            final e = groupExpenses[i - 1];
            return Dismissible(
              key: Key('group_exp_${e.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
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
              onDismissed: (dir) => _deleteExpense(e),
              child: _buildExpenseTile(theme, e),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildExpenseTile(ThemeData theme, Expense e) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExpenseDetailsScreen(expense: e),
        ),
      ),
      leading: CircleAvatar(
        child: Hero(
          tag: 'expense_icon_${e.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(e.categoryIcon),
          ),
        ),
      ),
      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(DateFormat('dd MMM • HH:mm').format(e.date)),
      trailing: Text(
        '₹${e.totalAmount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  void _deleteExpense(Expense e) async {
    final db = ref.read(dbServiceProvider).isar;
    final expenseId = e.id;

    // Capture data before deletion for undo
    final capturedExpense = Expense()
      ..id = e.id
      ..title = e.title
      ..totalAmount = e.totalAmount
      ..category = e.category
      ..categoryIcon = e.categoryIcon
      ..date = e.date
      ..splitMode = e.splitMode
      ..splits = e.splits
      ..contributions = e.contributions;
    final capturedGroup = e.group.value;

    await db.writeTxn(() async {
      await db.collection<Expense>().delete(expenseId);
    });

    if (mounted) {
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
  }

  Widget _buildBalancesTab(ThemeData theme, Isar db) {
    return FutureBuilder<List<OptimizedTransfer>>(
      future: SettlementService.calculateOptimizedTransfers(
        db,
        widget.group.id,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final transfers = snapshot.data!;
        if (transfers.isEmpty)
          return const Center(child: Text('All settled up!'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: transfers.length,
          itemBuilder: (context, i) {
            final t = transfers[i];
            return Card(
              child: ListTile(
                leading: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primary,
                ),
                title: Text('${t.from.name} → ${t.to.name}'),
                trailing: Text(
                  '₹${t.amount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                onTap: () => _markAsSettled(t),
              ),
            );
          },
        );
      },
    );
  }

  void _markAsSettled(OptimizedTransfer t) async {
    final db = ref.read(dbServiceProvider).isar;
    final settlement = Settlement()..amount = t.amount;
    settlement.fromMember.value = t.from;
    settlement.toMember.value = t.to;
    settlement.group.value = widget.group;

    await db.writeTxn(() async {
      await db.collection<Settlement>().put(settlement);
      await settlement.fromMember.save();
      await settlement.toMember.save();
      await settlement.group.save();
    });

    setState(() {}); // Refresh balances
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settlement recorded!')));
  }
}
