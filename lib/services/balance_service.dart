import '../models/isar_models.dart';
import '../utils/monetary_math.dart';

class UserBalanceStats {
  final double totalSpending; // totalShare across all expenses
  final double youPaid; // totalPaid across all expenses
  final double youOwe; // Sum of negative net balances in groups
  final double youAreOwed; // Sum of positive net balances in groups
  final double netBalance;

  UserBalanceStats({
    this.totalSpending = 0.0,
    this.youPaid = 0.0,
    this.youOwe = 0.0,
    this.youAreOwed = 0.0,
    this.netBalance = 0.0,
  });
}

class BalanceService {
  static Future<UserBalanceStats> calculateGlobalStats(Isar isar, int userId) async {
    final expenses = await isar.collection<Expense>().where().findAll();
    final settlements = await isar.collection<Settlement>().where().findAll();

    double totalShare = 0;
    double totalPaid = 0;

    for (var expense in expenses) {
      for (var split in expense.splits) {
        if (split.memberId == userId) {
          totalShare = MonetaryMath.round(totalShare + (split.amount ?? 0));
        }
      }
      for (var contribution in expense.contributions) {
        if (contribution.memberId == userId) {
          totalPaid = MonetaryMath.round(totalPaid + (contribution.amount ?? 0));
        }
      }
    }

    double settledPaid = 0;
    double settledReceived = 0;

    for (var settlement in settlements) {
      if (settlement.fromMember.value?.id == userId) {
        settledPaid = MonetaryMath.round(settledPaid + settlement.amount);
      }
      if (settlement.toMember.value?.id == userId) {
        settledReceived = MonetaryMath.round(settledReceived + settlement.amount);
      }
    }

    // To calculate youOwe and youAreOwed, we need to look at group-level balances
    // because a user might owe in one group and be owed in another.
    final groups = await isar.collection<Group>().where().findAll();
    double youOweTotal = 0;
    double youAreOwedTotal = 0;

    for (var group in groups) {
      final groupBalance = await calculateGroupMemberBalance(isar, group.id, userId);
      if (groupBalance > 0) {
        youAreOwedTotal = MonetaryMath.round(youAreOwedTotal + groupBalance);
      } else if (groupBalance < 0) {
        youOweTotal = MonetaryMath.round(youOweTotal + groupBalance.abs());
      }
    }

    return UserBalanceStats(
      totalSpending: totalShare,
      youPaid: totalPaid,
      youOwe: youOweTotal,
      youAreOwed: youAreOwedTotal,
      netBalance: MonetaryMath.round(totalPaid - totalShare + settledPaid - settledReceived),
    );
  }

  static Future<double> calculateGroupMemberBalance(Isar isar, int groupId, int userId) async {
    final expenses = await isar.collection<Expense>().filter().group((q) => q.idEqualTo(groupId)).findAll();
    final settlements = await isar.collection<Settlement>().filter().group((q) => q.idEqualTo(groupId)).findAll();

    double totalShare = 0;
    double totalPaid = 0;

    for (var expense in expenses) {
      for (var split in expense.splits) {
        if (split.memberId == userId) {
          totalShare = MonetaryMath.round(totalShare + (split.amount ?? 0));
        }
      }
      for (var contribution in expense.contributions) {
        if (contribution.memberId == userId) {
          totalPaid = MonetaryMath.round(totalPaid + (contribution.amount ?? 0));
        }
      }
    }

    double settledPaid = 0;
    double settledReceived = 0;

    for (var settlement in settlements) {
      if (settlement.fromMember.value?.id == userId) {
        settledPaid = MonetaryMath.round(settledPaid + settlement.amount);
      }
      if (settlement.toMember.value?.id == userId) {
        settledReceived = MonetaryMath.round(settledReceived + settlement.amount);
      }
    }

    return MonetaryMath.round(totalPaid - totalShare + settledPaid - settledReceived);
  }
}
