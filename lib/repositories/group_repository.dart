import '../models/isar_models.dart';

class GroupRepository {
  final Isar isar;
  GroupRepository(this.isar);

  Future<List<Group>> getAllGroups() async {
    return await isar.groups.where().findAll();
  }

  Future<Group?> getGroup(int id) async {
    return await isar.groups.get(id);
  }

  Future<int> saveGroup(Group group, List<Member> members) async {
    return await isar.writeTxn(() async {
      final id = await isar.groups.put(group);
      group.members.clear();
      group.members.addAll(members);
      await group.members.save();
      return id;
    });
  }

  Future<void> deleteGroup(int id) async {
    await isar.writeTxn(() async {
      // Note: Financial records remain, but group is gone. 
      // In a real app, we might prevent deletion if active balances exist.
      await isar.groups.delete(id);
    });
  }
}
