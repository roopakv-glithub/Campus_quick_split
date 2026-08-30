import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import 'home/home_screen.dart';
import 'groups/groups_screen.dart';
import 'activity/activity_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const GroupsScreen(),
    const ActivityScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, -5)
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          backgroundColor: theme.navigationBarTheme.backgroundColor,
          elevation: 0,
          indicatorColor: themeState.primaryColor.withOpacity(0.1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_filled, color: themeState.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group, color: themeState.primaryColor),
              label: 'Groups',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: themeState.primaryColor),
              label: 'Activity',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: themeState.primaryColor),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
