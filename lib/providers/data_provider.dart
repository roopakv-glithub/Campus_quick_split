import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/isar_models.dart';
import '../providers/db_provider.dart';
import '../services/analytics_service.dart';
import '../services/balance_service.dart';

// Provides the stream of expenses
final expensesProvider = StreamProvider<List<Expense>>((ref) {
  final db = ref.watch(dbServiceProvider).isar;
  return db
      .collection<Expense>()
      .where()
      .sortByDateDesc()
      .watch(fireImmediately: true)
      .asyncMap((expenses) async {
        // Ensure group links are loaded for every expense
        for (var e in expenses) {
          if (!e.group.isLoaded) {
            await e.group.load();
          }
        }
        return expenses;
      });
});

// Provides the stream of groups
final groupsProvider = StreamProvider<List<Group>>((ref) {
  final db = ref.watch(dbServiceProvider).isar;
  return db.collection<Group>().where().watch(fireImmediately: true);
});

// Provides the stream of settlements
final settlementsProvider = StreamProvider<List<Settlement>>((ref) {
  final db = ref.watch(dbServiceProvider).isar;
  return db.collection<Settlement>().where().watch(fireImmediately: true);
});

// Provides global balance stats
final globalStatsProvider = FutureProvider<UserBalanceStats>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  final user = await dbService.getCurrentUser();
  if (user == null) return UserBalanceStats();

  // Watch for changes in expenses or settlements to refresh
  ref.watch(expensesProvider);
  ref.watch(settlementsProvider);

  return await BalanceService.calculateGlobalStats(dbService.isar, user.id);
});

// Provides the current user reactively
final currentUserProvider = StreamProvider<Member?>((ref) {
  final db = ref.watch(dbServiceProvider).isar;
  return db
      .collection<Member>()
      .filter()
      .isCurrentUserEqualTo(true)
      .watch(fireImmediately: true)
      .map((list) => list.isNotEmpty ? list.first : null);
});

// Provides category breakdown for analytics
final categoryBreakdownProvider = FutureProvider<List<CategoryStat>>((
  ref,
) async {
  final dbService = ref.watch(dbServiceProvider);
  final user = await dbService.getCurrentUser();
  if (user == null) return [];

  ref.watch(expensesProvider);
  ref.watch(settlementsProvider);

  return await AnalyticsService.getCategoryBreakdown(dbService.isar, user.id);
});

// Provides group breakdown for analytics
final groupBreakdownProvider = FutureProvider<List<CategoryStat>>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  final user = await dbService.getCurrentUser();
  if (user == null) return [];

  ref.watch(expensesProvider);
  ref.watch(settlementsProvider);

  return await AnalyticsService.getGroupBreakdown(dbService.isar, user.id);
});

// Provides spending trend for analytics
final spendingTrendProvider = FutureProviderFamily<Map<String, double>, int>((
  ref,
  days,
) async {
  final dbService = ref.watch(dbServiceProvider);
  final user = await dbService.getCurrentUser();
  if (user == null) return {};

  ref.watch(expensesProvider);

  return await AnalyticsService.getSpendingTrend(dbService.isar, user.id, days);
});

// Provides insights
final insightsProvider = FutureProvider<List<String>>((ref) async {
  final dbService = ref.watch(dbServiceProvider);
  final user = await dbService.getCurrentUser();
  if (user == null) return [];

  ref.watch(expensesProvider);

  return await AnalyticsService.getInsights(dbService.isar, user.id);
});
