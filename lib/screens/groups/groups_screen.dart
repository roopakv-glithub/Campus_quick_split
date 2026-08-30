import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../services/balance_service.dart';
import 'create_group_screen.dart';
import 'group_details_screen.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(groupsProvider);
    final db = ref.watch(dbServiceProvider).isar;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Groups',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your shared expenses',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            groupsAsync.when(
              data: (groups) => Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Groups',
                      value: groups.length.toString().padLeft(2, '0'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, child) {
                        final statsAsync = ref.watch(globalStatsProvider);
                        return statsAsync.when(
                          data: (stats) => _StatCard(
                            label: 'Active Balances',
                            value: '₹${stats.netBalance.toStringAsFixed(0)}',
                            isAmount: true,
                            isNegative: stats.netBalance < 0,
                          ),
                          loading: () => const _StatCard(
                            label: 'Active Balances',
                            value: '₹...',
                          ),
                          error: (e, s) => const _StatCard(
                            label: 'Active Balances',
                            value: 'Error',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Text('No groups yet. Create one!'),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(20 * (1 - value), 0),
                          child: child,
                        ),
                      ),
                      child: _GroupListItem(
                        group: group,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GroupDetailsScreen(group: group),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              ),
              child: const Text('Create New Group'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.group_add_rounded),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isAmount;
  final bool isNegative;

  const _StatCard({
    required this.label,
    required this.value,
    this.isAmount = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isAmount
                  ? (isNegative ? AppColors.error : AppColors.success)
                  : theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupListItem extends ConsumerWidget {
  final Group group;
  final VoidCallback onTap;

  const _GroupListItem({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(dbServiceProvider).isar;

    return FutureBuilder<double>(
      future: _getBalance(db, ref),
      builder: (context, snapshot) {
        double balance = snapshot.data ?? 0;
        bool isPositive = balance >= 0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        group.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${group.members.length} members',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isPositive ? AppColors.success : AppColors.error)
                                .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}₹${balance.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          color: isPositive
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      balance == 0
                          ? 'Settled'
                          : (isPositive ? 'You are owed' : 'You owe'),
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<double> _getBalance(Isar isar, WidgetRef ref) async {
    final user = await ref.read(dbServiceProvider).getCurrentUser();
    if (user == null) return 0;
    return await BalanceService.calculateGroupMemberBalance(
      isar,
      group.id,
      user.id,
    );
  }
}
