import '../models/isar_models.dart';
import '../utils/monetary_math.dart';

class OptimizedTransfer {
  final Member from;
  final Member to;
  final double amount;

  OptimizedTransfer({required this.from, required this.to, required this.amount});
}

class SettlementService {
  static Future<void> recordSettlement(
    Isar isar,
    int groupId,
    int fromId,
    int toId,
    double amount,
  ) async {
    final group = await isar.collection<Group>().get(groupId);
    final from = await isar.collection<Member>().get(fromId);
    final to = await isar.collection<Member>().get(toId);

    if (group == null || from == null || to == null) return;

    final settlement = Settlement()
      ..amount = amount
      ..date = DateTime.now();

    settlement.group.value = group;
    settlement.fromMember.value = from;
    settlement.toMember.value = to;

    await isar.writeTxn(() async {
      await isar.collection<Settlement>().put(settlement);
      await settlement.group.save();
      await settlement.fromMember.save();
      await settlement.toMember.save();
    });
  }

  static Future<List<OptimizedTransfer>> calculateOptimizedTransfers(
    Isar isar,
    int groupId,
  ) async {
    final group = await isar.collection<Group>().get(groupId);
    if (group == null) return [];

    final members = await group.members.filter().findAll();
    Map<int, double> netBalances = {};

    for (var member in members) {
      final balance = await _calculateMemberNetBalance(isar, groupId, member.id);
      if (balance.abs() > 0.01) {
        netBalances[member.id] = balance;
      }
    }

    List<OptimizedTransfer> transfers = [];
    
    List<MapEntry<int, double>> debtors = netBalances.entries
        .where((e) => e.value < -0.01)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Most negative first

    List<MapEntry<int, double>> creditors = netBalances.entries
        .where((e) => e.value > 0.01)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Most positive first

    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtorId = debtors[dIdx].key;
      final creditorId = creditors[cIdx].key;
      
      double dAmount = debtors[dIdx].value.abs();
      double cAmount = creditors[cIdx].value;

      double transferAmount = dAmount < cAmount ? dAmount : cAmount;
      transferAmount = MonetaryMath.round(transferAmount);

      if (transferAmount > 0) {
        final fromMember = members.firstWhere((m) => m.id == debtorId);
        final toMember = members.firstWhere((m) => m.id == creditorId);
        
        transfers.add(OptimizedTransfer(
          from: fromMember,
          to: toMember,
          amount: transferAmount,
        ));
      }

      // Update remaining amounts
      if (dAmount < cAmount) {
        creditors[cIdx] = MapEntry(creditorId, MonetaryMath.round(cAmount - dAmount));
        dIdx++;
      } else if (dAmount > cAmount) {
        debtors[dIdx] = MapEntry(debtorId, -MonetaryMath.round(dAmount - cAmount));
        cIdx++;
      } else {
        dIdx++;
        cIdx++;
      }
    }

    return transfers;
  }

  static Future<double> _calculateMemberNetBalance(Isar isar, int groupId, int userId) async {
    final expenses = await isar.collection<Expense>().filter().group((q) => q.idEqualTo(groupId)).findAll();
    final settlements = await isar.collection<Settlement>().filter().group((q) => q.idEqualTo(groupId)).findAll();

    double share = 0;
    double paid = 0;

    for (var e in expenses) {
      for (var s in e.splits) {
        if (s.memberId == userId) share += s.amount ?? 0;
      }
      for (var c in e.contributions) {
        if (c.memberId == userId) paid += c.amount ?? 0;
      }
    }

    double settledPaid = 0;
    double settledReceived = 0;

    for (var s in settlements) {
      if (s.fromMember.value?.id == userId) settledPaid += s.amount;
      if (s.toMember.value?.id == userId) settledReceived += s.amount;
    }

    return MonetaryMath.round(paid - share + settledPaid - settledReceived);
  }

  /// Estimates the number of transfers saved.
  /// Simple heuristic: Before = number of unique (debtor, creditor) pairs across all expenses.
  /// After = length of optimized transfers list.
  static Future<Map<String, int>> getOptimizationStats(Isar isar, int groupId) async {
    final expenses = await isar.expenses.filter().group((q) => q.idEqualTo(groupId)).findAll();
    
    Set<String> manualPairs = {};
    for (var e in expenses) {
      final payers = e.contributions.where((c) => (c.amount ?? 0) > 0).map((c) => c.memberId).toSet();
      final debtors = e.splits.where((s) => (s.amount ?? 0) > 0).map((s) => s.memberId).toSet();
      
      for (var p in payers) {
        for (var d in debtors) {
          if (p != d) manualPairs.add('$d-$p');
        }
      }
    }

    final optimized = await calculateOptimizedTransfers(isar, groupId);
    
    return {
      'manual': manualPairs.length,
      'optimized': optimized.length,
      'saved': (manualPairs.length - optimized.length).clamp(0, 999),
    };
  }
}
