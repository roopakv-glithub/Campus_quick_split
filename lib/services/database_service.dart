import 'package:path_provider/path_provider.dart';

import '../models/isar_models.dart';

class DatabaseService {
  late Isar _isar;
  Isar get isar => _isar;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      MemberSchema,
      GroupSchema,
      ExpenseSchema,
      SettlementSchema,
      AppSettingsSchema,
    ], directory: dir.path);

    // Initialize default settings if not exists
    final settingsCount = await _isar.collection<AppSettings>().count();
    if (settingsCount == 0) {
      await _isar.writeTxn(() async {
        await _isar.collection<AppSettings>().put(AppSettings());

        // Create initial members
        await _isar.collection<Member>().putAll([
          Member(
            name: '',
            initials: '?',
            email: '',
            isCurrentUser: true,
            colorValue: 0xFF2563EB,
          ),
          Member(
            name: 'Arun',
            initials: 'AS',
            email: 'arun@univ.edu',
            colorValue: 0xFF10B981,
          ),
          Member(
            name: 'Priya',
            initials: 'PY',
            email: 'priya@univ.edu',
            colorValue: 0xFFF59E0B,
          ),
          Member(
            name: 'Rahul',
            initials: 'RV',
            email: 'rahul@univ.edu',
            colorValue: 0xFFEF4444,
          ),
        ]);
      });
    }
  }

  // Helper methods for easy access
  Future<Member?> getCurrentUser() async {
    return await _isar
        .collection<Member>()
        .filter()
        .isCurrentUserEqualTo(true)
        .findFirst();
  }

  Future<AppSettings> getSettings() async {
    return (await _isar.collection<AppSettings>().get(0)) ?? AppSettings();
  }
}
