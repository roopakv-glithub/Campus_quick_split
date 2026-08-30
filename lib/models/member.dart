import 'package:isar/isar.dart';

part 'member.g.dart';

@collection
class Member {
  Id id = Isar.autoIncrement;

  late String name;
  late String initials;
  int? colorValue;

  @Index(unique: true)
  String? email;

  bool isCurrentUser = false;

  Member({this.name = '', this.initials = '', this.colorValue, this.email, this.isCurrentUser = false});
}
