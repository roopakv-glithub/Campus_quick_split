import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/data_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/balance_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(globalStatsProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider);
    final groupBreakdownAsync = ref.watch(groupBreakdownProvider);
    final trendAsync = ref.watch(spendingTrendProvider(7));
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _buildMainStats(stats),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error: $e'),
            ),
            const SizedBox(height: 32),
            _buildChartSection(
              context,
              '7-Day Trend',
              trendAsync.when(
                data: (trend) => _buildLineChart(theme, trend),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 32),
            _buildChartSection(
              context,
              'Category Breakdown',
              breakdownAsync.when(
                data: (stats) => _buildDonutChart(theme, stats, true),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 32),
            _buildChartSection(
              context,
              'Group Breakdown',
              groupBreakdownAsync.when(
                data: (stats) => _buildDonutChart(theme, stats, false),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            insightsAsync.when(
              data: (insights) => Column(
                children: insights
                    .map((i) => _buildInsightTile(context, i))
                    .toList(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats(UserBalanceStats stats) {
    return Row(
      children: [
        Expanded(
          child: _InsightStatCard(
            label: 'Total Spending',
            value: '₹${stats.totalSpending.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _InsightStatCard(
            label: 'Net Balance',
            value: '₹${stats.netBalance.toStringAsFixed(0)}',
            isPositive: stats.netBalance >= 0,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, String title, Widget chart) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerTheme.color ?? AppColors.getBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 180, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme, Map<String, double> trend) {
    if (trend.isEmpty) return const Center(child: Text('Not enough data'));

    final entries = trend.entries.toList();
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.dividerColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (val, meta) {
                int index = val.toInt();
                if (index >= 0 && index < entries.length) {
                  // Only show 3-4 labels to avoid overlap
                  if (entries.length > 5 &&
                      index % 2 != 0 &&
                      index != entries.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      entries[index].key,
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.scaffoldBackgroundColor,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    ThemeData theme,
    List<CategoryStat> stats,
    bool useCategoryColors,
  ) {
    if (stats.isEmpty) return const Center(child: Text('No data found'));

    final sections = stats.asMap().entries.map((e) {
      final s = e.value;
      final color = useCategoryColors
          ? _getCategoryColor(s.category)
          : _getPaletteColor(theme, e.key);

      return PieChartSectionData(
        value: s.percentage,
        color: color,
        title: '${s.percentage.toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 30,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stats.take(5).toList().asMap().entries.map((e) {
              final s = e.value;
              final color = useCategoryColors
                  ? _getCategoryColor(s.category)
                  : _getPaletteColor(theme, e.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getPaletteColor(ThemeData theme, int index) {
    final List<Color> palette = [
      Colors.blueAccent,
      Colors.deepOrangeAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.amberAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.indigoAccent,
    ];
    return palette[index % palette.length];
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Food':
        return Colors.deepOrangeAccent;
      case 'Auto':
      case 'Travel':
        return Colors.blueAccent;
      case 'Print':
        return Colors.greenAccent;
      case 'Shop':
      case 'Shopping':
        return Colors.purpleAccent;
      case 'College':
        return Colors.redAccent;
      case 'Entertainment':
        return Colors.pinkAccent;
      default:
        return Colors.tealAccent;
    }
  }

  Widget _buildInsightTile(BuildContext context, String insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_rounded, color: Colors.amber),
        title: Text(insight, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}

class _InsightStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool? isPositive;

  const _InsightStatCard({
    required this.label,
    required this.value,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPositive == null
                  ? null
                  : (isPositive! ? AppColors.success : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
