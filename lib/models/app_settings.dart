import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0; // Only one instance

  late String themeMode; // 'light', 'dark', 'system'
  late int primaryColorValue;
  late String userName;
  late String userEmail;
  late String currencySymbol;
  late String defaultSplitType;

  AppSettings({
    this.themeMode = 'system',
    this.primaryColorValue = 0xFF2563EB,
    this.userName = '',
    this.userEmail = '',
    this.currencySymbol = '₹',
    this.defaultSplitType = 'Equally',
  });
}
