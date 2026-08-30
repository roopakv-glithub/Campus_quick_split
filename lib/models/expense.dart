import 'package:isar/isar.dart';
import 'group.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late String title;
  late double totalAmount;
  late String category;
  late String categoryIcon;
  late DateTime date;
  late String splitMode; // 'uniform', 'specific', 'ratio'

  final group = IsarLink<Group>();
  
  late List<Split> splits;
  late List<Contribution> contributions;

  Expense();
}

@embedded
class Split {
  int? memberId;
  String? memberName;
  double? amount;
  double? ratio;
}

@embedded
class Contribution {
  int? memberId;
  String? memberName;
  double? amount;
}
