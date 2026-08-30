import 'package:isar/isar.dart';
import 'member.dart';

part 'group.g.dart';

@collection
class Group {
  Id id = Isar.autoIncrement;

  late String name;
  late String icon;
  late DateTime createdAt;

  final members = IsarLinks<Member>();

  Group();
}
