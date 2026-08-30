import '../models/isar_models.dart';

class MemberRepository {
  final Isar isar;
  MemberRepository(this.isar);

  Future<List<Member>> getAllMembers() async {
    return await isar.members.where().findAll();
  }

  Future<Member?> getMember(int id) async {
    return await isar.members.get(id);
  }

  Future<int> saveMember(Member member) async {
    return await isar.writeTxn(() async {
      return await isar.members.put(member);
    });
  }

  Future<void> deleteMember(int id) async {
    await isar.writeTxn(() async {
      await isar.members.delete(id);
    });
  }

  Future<Member?> getCurrentUser() async {
    return await isar.members.filter().isCurrentUserEqualTo(true).findFirst();
  }
}
