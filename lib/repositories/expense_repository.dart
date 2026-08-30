import '../models/isar_models.dart';

class ExpenseRepository {
  final Isar isar;
  ExpenseRepository(this.isar);

  Future<List<Expense>> getAllExpenses() async {
    return await isar.expenses.where().sortByDateDesc().findAll();
  }

  Future<List<Expense>> getExpensesByGroup(int groupId) async {
    return await isar.expenses.filter().group((q) => q.idEqualTo(groupId)).sortByDateDesc().findAll();
  }

  Future<int> saveExpense(Expense expense) async {
    return await isar.writeTxn(() async {
      return await isar.expenses.put(expense);
    });
  }

  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() async {
      await isar.expenses.delete(id);
    });
  }

  Future<void> undoDelete(Expense expense) async {
    await isar.writeTxn(() async {
      // Re-insert with existing ID if possible, or just put it back
      await isar.expenses.put(expense);
    });
  }
}
