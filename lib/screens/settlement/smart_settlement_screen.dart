import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../services/settlement_service.dart';

class SmartSettlementScreen extends ConsumerStatefulWidget {
  const SmartSettlementScreen({super.key});

  @override
  ConsumerState<SmartSettlementScreen> createState() =>
      _SmartSettlementScreenState();
}

class _SmartSettlementScreenState extends ConsumerState<SmartSettlementScreen>
    with SingleTickerProviderStateMixin {
  Group? _selectedGroup;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final theme = Theme.of(context);
    final db = ref.watch(dbServiceProvider).isar;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Smart Settlement',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Group',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                groupsAsync.when(
                  data: (groups) => DropdownButtonFormField<Group>(
                    value: _selectedGroup,
                    dropdownColor: theme.cardTheme.color,
                    items: groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g.name,
                              style: TextStyle(
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (g) => setState(() => _selectedGroup = g),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          if (_selectedGroup != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                tabs: const [
                  Tab(text: 'Optimized'),
                  Tab(text: 'Manual Way'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildOptimizedSection(db, theme, true),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildOptimizedSection(db, theme, false),
                  ),
                ],
              ),
            ),
          ] else
            const Expanded(
              child: Center(child: Text('Select a group to see optimization')),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizedSection(Isar db, ThemeData theme, bool isOptimized) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOptimized) _buildOptimizedInsightBox(theme),
        const SizedBox(height: 32),
        Text(
          isOptimized ? 'Optimized Transfers' : 'Individual Debts',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<OptimizedTransfer>>(
          future: isOptimized
              ? SettlementService.calculateOptimizedTransfers(
                  db,
                  _selectedGroup!.id,
                )
              : _calculateManualTransfers(db),
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final transfers = snapshot.data!;
            if (transfers.isEmpty)
              return const Center(child: Text('No transfers needed!'));

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transfers.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: _buildTransferCard(
                    context,
                    transfers[index],
                    isOptimized,
                  ),
                );
              },
            );
          },
        ),
        if (isOptimized) ...[
          const SizedBox(height: 32),
          FutureBuilder<Map<String, int>>(
            future: SettlementService.getOptimizationStats(
              db,
              _selectedGroup!.id,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _buildComparisonCard(theme, snapshot.data!);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOptimizedInsightBox(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Optimized Settlement Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'We simplify the debts to save you time and transfers.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<OptimizedTransfer>> _calculateManualTransfers(Isar db) async {
    final expenses = await db.expenses
        .filter()
        .group((q) => q.idEqualTo(_selectedGroup!.id))
        .findAll();
    final members = await _selectedGroup!.members.filter().findAll();

    Map<String, double> pairs = {};
    for (var e in expenses) {
      final payers = e.contributions.where((c) => (c.amount ?? 0) > 0);
      for (var p in payers) {
        for (var s in e.splits) {
          if (s.memberId != p.memberId && (s.amount ?? 0) > 0) {
            final key = '${s.memberId}-${p.memberId}';
            pairs[key] = (pairs[key] ?? 0) + (s.amount ?? 0);
          }
        }
      }
    }

    return pairs.entries.map((e) {
      final ids = e.key.split('-');
      final from = members.firstWhere((m) => m.id == int.parse(ids[0]));
      final to = members.firstWhere((m) => m.id == int.parse(ids[1]));
      return OptimizedTransfer(from: from, to: to, amount: e.value);
    }).toList();
  }

  Widget _buildTransferCard(
    BuildContext context,
    OptimizedTransfer t,
    bool isOptimized,
  ) {
    final theme = Theme.of(context);
    final db = ref.read(dbServiceProvider).isar;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarWithLabel(
                name: t.from.name,
                label: t.from.isCurrentUser ? 'You' : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isOptimized ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isOptimized
                                    ? theme.colorScheme.primary
                                    : Colors.grey)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOptimized ? 'Optimized' : 'Direct Debt',
                        style: TextStyle(
                          fontSize: 10,
                          color: isOptimized ? AppColors.primary : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _AvatarWithLabel(
                name: t.to.name,
                label: t.to.isCurrentUser ? 'You' : null,
                isPrimary: isOptimized,
              ),
              const SizedBox(width: 16),
              Text(
                '₹${t.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isOptimized
                      ? AppColors.success
                      : theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          if (isOptimized) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Mark as Settled'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await SettlementService.recordSettlement(
                    db,
                    _selectedGroup!.id,
                    t.from.id,
                    t.to.id,
                    t.amount,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settlement recorded!')),
                    );
                    setState(() {}); // Refresh list
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme, Map<String, int> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getIconBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manual Way',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${stats['manual']} Transfers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.getBorder(context)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QuickSplit',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${stats['optimized']} Transfers',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithLabel extends StatelessWidget {
  final String name;
  final String? label;
  final bool isPrimary;

  const _AvatarWithLabel({
    required this.name,
    this.label,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            name[0],
            style: TextStyle(
              color: isPrimary ? Colors.white : theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label ?? name,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
