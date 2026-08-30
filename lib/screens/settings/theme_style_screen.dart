import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';

class ThemeStyleScreen extends ConsumerWidget {
  const ThemeStyleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Theme & Style',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : AppColors.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: themeState.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Themes'),
                  Tab(text: 'Fonts'),
                  Tab(text: 'Custom'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildThemesTab(context, ref),
            const Center(child: Text('Fonts Tab')),
            const Center(child: Text('Custom Tab')),
          ],
        ),
      ),
    );
  }

  Widget _buildThemesTab(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final themeState = ref.watch(themeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThemeSection(
            context,
            'Light Themes',
            'Clean, bright, and minimalist surfaces',
            [
              'Matte Ivory',
              'Fogstone',
              'Copper Light',
              'Rose Linen',
              'Peach Mist',
            ],
            ThemeMode.light,
            themeState,
            themeNotifier,
          ),
          const SizedBox(height: 40),
          _buildThemeSection(
            context,
            'Dark Themes',
            'Deep, focused, and modern surfaces',
            ['Midnight', 'Obsidian', 'Emerald', 'Pink Noir', 'Slate Mist'],
            ThemeMode.dark,
            themeState,
            themeNotifier,
          ),
          const SizedBox(height: 40),
          _buildLivePreview(context, themeState),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    String title,
    String subtitle,
    List<String> themeNames,
    ThemeMode mode,
    AppThemeState currentTheme,
    ThemeNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: themeNames.length,
          itemBuilder: (context, index) {
            final name = themeNames[index];
            final color = AppColors.themeColors[name] ?? AppColors.primaryBlue;
            final isSelected =
                currentTheme.primaryColor == color &&
                currentTheme.themeMode == mode;

            return GestureDetector(
              onTap: () {
                notifier.setThemeMode(mode);
                notifier.setPrimaryColor(color);
              },
              child: _ThemeCard(
                name: name,
                primaryColor: color,
                isSelected: isSelected,
                isDark: mode == ThemeMode.dark,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLivePreview(BuildContext context, AppThemeState themeState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'System Sync',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Adapt to device settings',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Switch(
                value: themeState.themeMode == ThemeMode.system,
                onChanged: (val) {
                  // Handle system sync
                },
                activeColor: themeState.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String name;
  final Color primaryColor;
  final bool isSelected;
  final bool isDark;

  const _ThemeCard({
    required this.name,
    required this.primaryColor,
    required this.isSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isSelected ? primaryColor : AppColors.border.withOpacity(0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
