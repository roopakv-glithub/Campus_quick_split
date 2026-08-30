import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/isar_models.dart';
import '../../providers/data_provider.dart';
import '../../providers/db_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/onboarding_screen.dart';
import 'theme_style_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }

  void _simulateExport(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(dbServiceProvider);
      final groups = await db.isar.groups.where().findAll();
      final expenses = await db.isar.expenses.where().findAll();

      final buffer = StringBuffer();
      buffer.writeln('Type,ID,Title/Name,Amount,Date,Category');

      for (var g in groups) {
        buffer.writeln('GROUP,${g.id},${g.name},,,');
      }

      for (var e in expenses) {
        buffer.writeln(
          'EXPENSE,${e.id},${e.title},${e.totalAmount},${DateFormat('yyyy-MM-dd').format(e.date)},${e.category}',
        );
      }

      final directory = await getExternalStorageDirectory();
      final file = File(
        '${directory?.path ?? getApplicationDocumentsDirectory().then((d) => d.path)}/quicksplit_export.csv',
      );
      await file.writeAsString(buffer.toString());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: ${file.path}'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeProvider).currencySymbol;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPickerOption(
              context,
              'Indian Rupee',
              '₹',
              current == '₹',
              () {
                ref.read(themeProvider.notifier).setCurrency('₹');
                Navigator.pop(context);
              },
            ),
            _buildPickerOption(context, 'US Dollar', '\$', current == '\$', () {
              ref.read(themeProvider.notifier).setCurrency('\$');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  void _showSplitPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeProvider).defaultSplitType;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Split Variation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPickerOption(
              context,
              'Equally',
              'Split evenly among all',
              current == 'Equally',
              () {
                ref.read(themeProvider.notifier).setDefaultSplit('Equally');
                Navigator.pop(context);
              },
            ),
            _buildPickerOption(
              context,
              'Percentage',
              'Split by specified %',
              current == 'Percentage',
              () {
                ref.read(themeProvider.notifier).setDefaultSplit('Percentage');
                Navigator.pop(context);
              },
            ),
            _buildPickerOption(
              context,
              'Exact Amount',
              'Specify exact shares',
              current == 'Exact Amount',
              () {
                ref
                    .read(themeProvider.notifier)
                    .setDefaultSplit('Exact Amount');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(
    BuildContext context,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
    );
  }

  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data?'),
        content: const Text(
          'This will delete all groups and expenses. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final isar = ref.read(dbServiceProvider).isar;
              await isar.writeTxn(() async {
                await isar.collection<Expense>().clear();
                await isar.collection<Group>().clear();
                await isar.collection<Settlement>().clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local data cleared.')),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            userAsync.when(
              data: (user) => _buildProfileHeader(theme, user),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Error loading profile'),
            ),
            const SizedBox(height: 32),
            _buildSection(context, 'APPEARANCE', [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme & Style',
                subtitle: 'Customize colors and vibes',
                value: themeState.themeMode == ThemeMode.dark
                    ? 'Dark'
                    : 'Light',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ThemeStyleScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.font_download_outlined,
                title: 'Font Family',
                subtitle: 'Roboto',
                value: 'System',
                onTap: () => _showComingSoon(context),
              ),
            ]),
            _buildSection(context, 'PREFERENCES', [
              _SettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Currency',
                subtitle: themeState.currencySymbol == '₹'
                    ? 'Indian Rupee'
                    : 'US Dollar',
                value: themeState.currencySymbol,
                onTap: () => _showCurrencyPicker(context, ref),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Default Split',
                subtitle: 'Variation for new expenses',
                value: themeState.defaultSplitType,
                onTap: () => _showSplitPicker(context, ref),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'On',
                value: 'Enabled',
                onTap: () => _showComingSoon(context),
              ),
            ]),
            _buildSection(context, 'DATA', [
              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Export Data',
                subtitle: 'Summarize groups & expenses',
                value: 'CSV/JSON',
                onTap: () => _simulateExport(context, ref),
              ),
              _SettingsTile(
                icon: Icons.storage_outlined,
                title: 'Clear Local Cache',
                subtitle: 'Reset all data',
                value: 'Clear',
                onTap: () => _confirmClearCache(context, ref),
              ),
            ]),
            _buildSection(context, 'ABOUT', [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: 'QuickSplit Stable',
                value: '1.0.0 stable',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'GitHub Repository',
                subtitle: 'Open Source',
                value: 'System',
                onTap: () => _showComingSoon(context),
              ),
            ]),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(),
                ),
                (route) => false,
              ),
              child: Text(
                'Sign Out',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/logo.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Campus QuickSplit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              'Made for GDG Round 2',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, Member? user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Guest User',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          user?.email ?? 'No email provided',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8, top: 16),
          child: Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerTheme.color ?? AppColors.getBorder(context),
            ),
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: 11,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ],
      ),
    );
  }
}
