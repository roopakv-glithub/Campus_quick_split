import 'package:animations/animations.dart';
import 'package:campus_quicksplit/core/theme/app_colors.dart';
import 'package:campus_quicksplit/providers/data_provider.dart';
import 'package:campus_quicksplit/providers/db_provider.dart';
import 'package:campus_quicksplit/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/isar_models.dart';
import '../../services/balance_service.dart';
import '../analytics/analytics_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_details_screen.dart';
import '../groups/create_group_screen.dart';
import '../groups/group_details_screen.dart';
import '../groups/groups_screen.dart';
import '../settlement/smart_settlement_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  final String narutoAvatar =
      'https://i.pinimg.com/736x/8b/11/d8/8b11d88590623a6f98c8c7f3b79f8099.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final statsAsync = ref.watch(globalStatsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QuickSplit',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  userAsync.when(
                    data: (user) => Text(
                      'Welcome, ${user?.name ?? 'User'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statsAsync.when(
                    data: (stats) => PageTransitionSwitcher(
                      transitionBuilder: (child, primary, secondary) =>
                          FadeThroughTransition(
                            animation: primary,
                            secondaryAnimation: secondary,
                            child: child,
                          ),
                      child: _buildBalanceCard(
                        context,
                        stats,
                        themeState.currencySymbol,
                      ),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),
                  _buildQuickActionGrid(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Your Groups',
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  groupsAsync.when(
                    data: (groups) => _buildGroupsScroll(groups),
                    loading: () => const SizedBox(height: 160),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  expensesAsync.when(
                    data: (expenses) => _buildActivityList(
                      context,
                      theme,
                      expenses,
                      themeState.currencySymbol,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 24),
                  _buildReminderCard(
                    theme,
                    statsAsync,
                    themeState.currencySymbol,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    UserBalanceStats stats,
    String currencySymbol,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: primaryColor, // Simple solid primary color as requested
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Net Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${stats.netBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildBalanceSubItem(
                'You owe',
                '$currencySymbol${stats.youOwe.toStringAsFixed(2)}',
                Colors.red.shade100,
                Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 16),
              _buildBalanceSubItem(
                'Owed to you',
                '$currencySymbol${stats.youAreOwed.toStringAsFixed(2)}',
                Colors.green.shade100,
                Colors.white.withValues(alpha: 0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSubItem(
    String label,
    String amount,
    Color amountColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionBtn(
          icon: Icons.add_rounded,
          label: 'Add',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          ),
        ),
        _ActionBtn(
          icon: Icons.sync_alt_rounded,
          label: 'Settle',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartSettlementScreen(),
            ),
          ),
        ),
        _ActionBtn(
          icon: Icons.group_add_rounded,
          label: 'Group',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          ),
        ),
        _ActionBtn(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text(
            'See All',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsScroll(List<Group> groups) {
    if (groups.isEmpty) {
      return const Center(child: Text('No groups yet. Create one to start!'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: groups
            .map(
              (g) => Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _HomeGroupCard(group: g),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    ThemeData theme,
    List<Expense> expenses,
    String currencySymbol,
  ) {
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses recorded yet.'));
    }
    return Column(
      children: expenses
          .take(5)
          .map(
            (e) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseDetailsScreen(expense: e),
                ),
              ),
              child: _ActivityTile(
                title: e.title,
                subtitle:
                    '${e.category} • ${DateFormat('HH:mm').format(e.date)}',
                amount: '$currencySymbol${e.totalAmount.toStringAsFixed(0)}',
                isNegative: true,
                icon: e.categoryIcon,
                expenseId: e.id,
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _getCategoryIcon(String iconStr) {
    switch (iconStr) {
      case '🍕':
        return Icons.local_pizza_rounded;
      case '🍕':
        return Icons.restaurant_rounded;
      case '🛺':
        return Icons.electric_bolt_rounded;
      case '🚗':
        return Icons.directions_car_rounded;
      case '🌐':
        return Icons.language_rounded;
      case '🎓':
        return Icons.school_rounded;
      case '🏠':
        return Icons.home_rounded;
      default:
        return Icons.notes_rounded;
    }
  }

  Widget _buildReminderCard(
    ThemeData theme,
    AsyncValue<UserBalanceStats> statsAsync,
    String currencySymbol,
  ) {
    return statsAsync.when(
      data: (stats) {
        if (stats.youOwe <= 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settlement Tip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'You owe $currencySymbol${stats.youOwe.toStringAsFixed(2)} across groups. Gentle reminders work best!',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _HomeGroupCard extends ConsumerWidget {
  final Group group;
  const _HomeGroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final db = ref.watch(dbServiceProvider).isar;

    return FutureBuilder<double>(
      future: _getBalance(ref),
      builder: (context, snapshot) {
        double balance = snapshot.data ?? 0;
        bool isPositive = balance >= 0;
        final color = isPositive ? Colors.blue : Colors.indigo;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsScreen(group: group),
            ),
          ),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.dividerTheme.color ?? AppColors.getBorder(context),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Hero(
                    tag: 'group_icon_${group.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        group.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}${themeState.currencySymbol}${balance.abs().toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<double> _getBalance(WidgetRef ref) async {
    final user = await ref.read(dbServiceProvider).getCurrentUser();
    if (user == null) return 0;
    return await BalanceService.calculateGroupMemberBalance(
      ref.read(dbServiceProvider).isar,
      group.id,
      user.id,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String name;
  final String balance;
  final IconData icon;
  final Color color;

  const _GroupCard({
    required this.name,
    required this.balance,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.getBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            balance,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: balance.contains('+')
                  ? AppColors.success
                  : AppColors.error,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;
  final String icon;
  final int expenseId;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isNegative,
    required this.icon,
    required this.expenseId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Hero(
                tag: 'expense_icon_$expenseId',
                child: Material(
                  color: Colors.transparent,
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isNegative ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
