import '../models/isar_models.dart';
import '../utils/monetary_math.dart';

class SplitService {
  /// Validates a list of splits against the total amount.
  static bool validateSplits(double total, List<Split> splits) {
    double sum = 0;
    for (var s in splits) {
      sum = MonetaryMath.round(sum + (s.amount ?? 0));
    }
    return sum == total;
  }

  /// Calculates uniform splits.
  static List<Split> calculateUniform(double total, List<Member> members) {
    final amounts = MonetaryMath.distributeEqually(total, members.length);
    return List.generate(members.length, (i) {
      return Split()
        ..memberId = members[i].id
        ..memberName = members[i].name
        ..amount = amounts[i];
    });
  }

  /// Calculates splits from ratios (percentages).
  static List<Split> calculateFromRatios(double total, Map<int, double> ratios, List<Member> members) {
    // ratios: memberId -> ratio (0.0 to 100.0)
    List<Split> splits = [];
    double allocatedAmount = 0;
    
    for (int i = 0; i < members.length; i++) {
      final member = members[i];
      final ratio = ratios[member.id] ?? 0;
      double amount = MonetaryMath.round((ratio / 100) * total);
      
      if (i == members.length - 1) {
        // Last member takes the rounding difference to ensure total matches
        amount = MonetaryMath.round(total - allocatedAmount);
      }
      
      splits.add(Split()
        ..memberId = member.id
        ..memberName = member.name
        ..amount = amount
        ..ratio = ratio);
      
      allocatedAmount = MonetaryMath.round(allocatedAmount + amount);
    }
    
    return splits;
  }
}
