import 'package:intl/intl.dart';

import '../models/isar_models.dart';
import '../utils/monetary_math.dart';

class AnalyticsSummary {
  final double totalSpending;
  final int transactionCount;
  final double averageTransaction;
  final double averageDailySpending;
  final double highestExpense;
  final double amountPaidForOthers;
  final double amountOthersPaidForYou;

  AnalyticsSummary({
    this.totalSpending = 0.0,
    this.transactionCount = 0,
    this.averageTransaction = 0.0,
    this.averageDailySpending = 0.0,
    this.highestExpense = 0.0,
    this.amountPaidForOthers = 0.0,
    this.amountOthersPaidForYou = 0.0,
  });
}

class CategoryStat {
  final String category;
  final String icon;
  final double amount;
  final double percentage;
  final int count;

  CategoryStat({
    required this.category,
    required this.icon,
    this.amount = 0.0,
    this.percentage = 0.0,
    this.count = 0,
  });
}

class AnalyticsService {
  static Future<AnalyticsSummary> getSummary(Isar isar, int userId) async {
    final expenses = await isar.collection<Expense>().where().findAll();

    double totalShare = 0;
    double totalPaid = 0;
    double highest = 0;
    int count = 0;

    DateTime? firstDate;

    for (var e in expenses) {
      double userShare = 0;
      double userPaid = 0;

      for (var s in e.splits) {
        if (s.memberId == userId) userShare = s.amount ?? 0;
      }
      for (var c in e.contributions) {
        if (c.memberId == userId) userPaid = c.amount ?? 0;
      }

      if (userShare > 0 || userPaid > 0) {
        totalShare += userShare;
        totalPaid += userPaid;
        count++;
        if (userShare > highest) highest = userShare;

        if (firstDate == null || e.date.isBefore(firstDate)) firstDate = e.date;
      }
    }

    int days = 1;
    if (firstDate != null) {
      days = DateTime.now().difference(firstDate).inDays + 1;
    }

    return AnalyticsSummary(
      totalSpending: MonetaryMath.round(totalShare),
      transactionCount: count,
      averageTransaction: count > 0
          ? MonetaryMath.round(totalShare / count)
          : 0,
      averageDailySpending: MonetaryMath.round(totalShare / days),
      highestExpense: highest,
      amountPaidForOthers: MonetaryMath.round(
        totalPaid - totalShare,
      ).clamp(0, double.infinity),
      amountOthersPaidForYou: MonetaryMath.round(
        totalShare - totalPaid,
      ).clamp(0, double.infinity),
    );
  }

  static Future<List<CategoryStat>> getCategoryBreakdown(
    Isar isar,
    int userId,
  ) async {
    final expenses = await isar.collection<Expense>().where().findAll();
    Map<String, double> amounts = {};
    Map<String, int> counts = {};
    Map<String, String> icons = {};
    double total = 0;

    for (var e in expenses) {
      double share = 0;
      for (var s in e.splits) {
        if (s.memberId == userId) share = s.amount ?? 0;
      }

      if (share > 0) {
        amounts[e.category] = (amounts[e.category] ?? 0) + share;
        counts[e.category] = (counts[e.category] ?? 0) + 1;
        icons[e.category] = e.categoryIcon;
        total += share;
      }
    }

    List<CategoryStat> stats = [];
    amounts.forEach((cat, amount) {
      stats.add(
        CategoryStat(
          category: cat,
          icon: icons[cat] ?? '📝',
          amount: MonetaryMath.round(amount),
          percentage: total > 0 ? (amount / total * 100) : 0,
          count: counts[cat] ?? 0,
        ),
      );
    });

    return stats..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static Future<List<CategoryStat>> getGroupBreakdown(
    Isar isar,
    int userId,
  ) async {
    final expenses = await isar.collection<Expense>().where().findAll();
    Map<String, double> amounts = {};
    double total = 0;

    for (var e in expenses) {
      if (!e.group.isLoaded) await e.group.load();
      final groupName = e.group.value?.name ?? 'No Group';

      double share = 0;
      for (var s in e.splits) {
        if (s.memberId == userId) share = s.amount ?? 0;
      }

      if (share > 0) {
        amounts[groupName] = (amounts[groupName] ?? 0) + share;
        total += share;
      }
    }

    List<CategoryStat> stats = [];
    amounts.forEach((name, amount) {
      stats.add(
        CategoryStat(
          category: name,
          icon: '📁',
          amount: MonetaryMath.round(amount),
          percentage: total > 0 ? (amount / total * 100) : 0,
        ),
      );
    });

    return stats..sort((a, b) => b.amount.compareTo(a.amount));
  }

  static Future<Map<String, double>> getSpendingTrend(
    Isar isar,
    int userId,
    int days,
  ) async {
    final threshold = DateTime.now().subtract(Duration(days: days));
    final expenses = await isar
        .collection<Expense>()
        .filter()
        .dateGreaterThan(threshold)
        .findAll();

    Map<String, double> trend = {};
    final dateFormat = DateFormat('dd MMM');

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      trend[dateFormat.format(date)] = 0.0;
    }

    for (var e in expenses) {
      double share = 0;
      for (var s in e.splits) {
        if (s.memberId == userId) share = s.amount ?? 0;
      }
      if (share > 0) {
        final key = dateFormat.format(e.date);
        trend[key] = (trend[key] ?? 0) + share;
      }
    }

    return trend;
  }

  static Future<List<String>> getInsights(Isar isar, int userId) async {
    final summary = await getSummary(isar, userId);
    final categoryBreakdown = await getCategoryBreakdown(isar, userId);

    List<String> insights = [];

    if (categoryBreakdown.isNotEmpty) {
      final top = categoryBreakdown.first;
      insights.add(
        '${top.category} represents ${top.percentage.toStringAsFixed(0)}% of your spending.',
      );
    }

    final now = DateTime.now();
    final thisMonthExpenses = await isar.expenses
        .filter()
        .dateGreaterThan(DateTime(now.year, now.month, 1))
        .findAll();
    double thisMonthSpending = 0;
    for (var e in thisMonthExpenses) {
      for (var s in e.splits)
        if (s.memberId == userId) thisMonthSpending += s.amount ?? 0;
    }

    insights.add(
      'You have spent ₹${MonetaryMath.round(thisMonthSpending)} so far this month.',
    );

    if (summary.amountPaidForOthers > 0) {
      insights.add(
        'You paid ₹${summary.amountPaidForOthers} for others recently.',
      );
    }

    return insights;
  }
}
