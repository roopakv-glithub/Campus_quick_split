import 'package:campus_quicksplit/core/theme/app_colors.dart';
import 'package:campus_quicksplit/providers/db_provider.dart';
import 'package:campus_quicksplit/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/isar_models.dart';
import '../../models/member.dart';
import '../../utils/sample_data.dart';
import '../main_navigation.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _loadSampleData = true;

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = themeState.themeData;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Campus QuickSplit', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Split expenses. Settle smarter.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What\'s your name?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  hintText: 'e.g. Roopak',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                style: TextStyle(color: theme.textTheme.titleLarge?.color),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _loadSampleData,
                onChanged: (val) =>
                    setState(() => _loadSampleData = val ?? false),
                title: const Text(
                  'Pre-load sample data',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Start with groups and expenses already setup',
                  style: TextStyle(fontSize: 12),
                ),
                activeColor: themeState.primaryColor,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose your vibe',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _VibeCard(
                    title: 'System',
                    icon: Icons.settings_brightness_rounded,
                    isSelected: themeState.themeMode == ThemeMode.system,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 12),
                  _VibeCard(
                    title: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: themeState.themeMode == ThemeMode.light,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _VibeCard(
                    title: 'Dark',
                    icon: Icons.dark_mode_rounded,
                    isSelected: themeState.themeMode == ThemeMode.dark,
                    onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shared expenses without the hassle',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Built for students, by students',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.titleLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onGetStarted() async {
    if (_nameController.text.isEmpty) return;

    final db = ref.read(dbServiceProvider);

    // Always load sample data if checked, BEFORE updating the user name
    if (_loadSampleData) {
      await SampleData.load(db.isar);
    }

    final user = await db.getCurrentUser();
    if (user != null) {
      await db.isar.writeTxn(() async {
        user.name = _nameController.text;
        user.initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U';
        await db.isar.collection<Member>().put(user);
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }
}

class _VibeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _VibeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.08)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : AppColors.getBorder(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleLarge?.color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.titleLarge?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
