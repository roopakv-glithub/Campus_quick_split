import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color slate900 = Color(0xFF0F172A);
  
  // Legacy aliases to fix compilation errors
  static const Color primary = Color(0xFF2563EB);
  static const Color iconBg = Color(0xFFF1F5F9);
  
  // Neutral Colors (Light)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  
  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Theme Palettes
  static const Map<String, Color> themeColors = {
    'Matte Ivory': Color(0xFF3F6212),
    'Fogstone': Color(0xFF475569),
    'Copper Light': Color(0xFF9A3412),
    'Slate Mist': Color(0xFF1E293B),
    'Rose Linen': Color(0xFF881337),
    'Peach Mist': Color(0xFFEA580C),
    'Midnight': Color(0xFF3B82F6),
    'Obsidian': Color(0xFFF97316),
    'Emerald': Color(0xFF10B981),
    'Pink Noir': Color(0xFFEC4899),
  };

  static Color getIconBg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9);
  }

  static Color getSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E293B) : Colors.white;
  }

  static Color getBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);
  }

  static Color getTextPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF0F172A);
  }

  static Color getTextSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xFF64748B);
  }
}
