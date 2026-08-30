import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../models/isar_models.dart';
import '../providers/db_provider.dart';

class AppThemeState {
  final Color primaryColor;
  final ThemeMode themeMode;
  final String currencySymbol;
  final String defaultSplitType;

  AppThemeState({
    required this.primaryColor,
    required this.themeMode,
    this.currencySymbol = '₹',
    this.defaultSplitType = 'Equally',
  });

  AppThemeState copyWith({
    Color? primaryColor,
    ThemeMode? themeMode,
    String? currencySymbol,
    String? defaultSplitType,
  }) {
    return AppThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultSplitType: defaultSplitType ?? this.defaultSplitType,
    );
  }

  ThemeData get themeData {
    final isDark = themeMode == ThemeMode.dark;
    final baseColor = primaryColor;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: baseColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: baseColor,
      surface: isDark ? const Color(0xFF1E293B) : Colors.white,
      onSurface: isDark ? Colors.white : AppColors.slate900,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0F172A)
          : AppColors.background,

      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.slate900,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.slate900,
        ),
        bodyLarge: GoogleFonts.inter(
          color: isDark ? Colors.white.withOpacity(0.9) : AppColors.slate900,
        ),
        bodyMedium: GoogleFonts.inter(
          color: isDark
              ? Colors.white.withOpacity(0.7)
              : AppColors.textSecondary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.border,
          ),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        indicatorColor: baseColor.withOpacity(0.1),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: baseColor);
          }
          return IconThemeData(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
          );
        }),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(0.05) : AppColors.border,
        thickness: 1,
      ),
    );
  }
}

class ThemeNotifier extends StateNotifier<AppThemeState> {
  final Isar _isar;

  ThemeNotifier(this._isar)
    : super(
        AppThemeState(
          primaryColor: AppColors.primaryBlue,
          themeMode: ThemeMode.light,
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _isar.appSettings.get(0);
    if (settings != null) {
      state = state.copyWith(
        primaryColor: Color(settings.primaryColorValue),
        themeMode: _parseThemeMode(settings.themeMode),
        currencySymbol: settings.currencySymbol,
        defaultSplitType: settings.defaultSplitType,
      );
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
    _saveSettings();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  void setCurrency(String symbol) {
    state = state.copyWith(currencySymbol: symbol);
    _saveSettings();
  }

  void setDefaultSplit(String type) {
    state = state.copyWith(defaultSplitType: type);
    _saveSettings();
  }

  Future<void> _saveSettings() async {
    final settings = AppSettings(
      themeMode: state.themeMode.name,
      primaryColorValue: state.primaryColor.value,
      currencySymbol: state.currencySymbol,
      defaultSplitType: state.defaultSplitType,
    );
    await _isar.writeTxn(() async {
      await _isar.appSettings.put(settings);
    });
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeState>((
  ref,
) {
  final isar = ref.watch(dbServiceProvider).isar;
  return ThemeNotifier(isar);
});
