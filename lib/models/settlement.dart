import 'package:isar/isar.dart';
import 'member.dart';
import 'group.dart';

part 'settlement.g.dart';

@collection
class Settlement {
  Id id = Isar.autoIncrement;

  late double amount;
  late DateTime date;

  final fromMember = IsarLink<Member>();
  final toMember = IsarLink<Member>();
  final group = IsarLink<Group>();

  Settlement();
}
