import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/db_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  await dbService.init();

  runApp(
    ProviderScope(
      overrides: [dbServiceProvider.overrideWithValue(dbService)],
      child: const CampusQuickSplitApp(),
    ),
  );
}

class CampusQuickSplitApp extends ConsumerWidget {
  const CampusQuickSplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Campus QuickSplit',
      debugShowCheckedModeBanner: false,
      theme: themeState.themeData,
      themeMode: themeState.themeMode,
      home: const SplashScreen(),
    );
  }
}
