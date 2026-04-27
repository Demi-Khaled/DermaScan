import 'package:flutter/material.dart';

class AppColors {
  // Primary palette (remains mostly same, but can be adjusted for dark mode if needed)
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF3B82F6);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Light Mode Colors
  static const Color background = Color(0xFFF0F4FF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDarkBody = Color(0xFF1E293B);
  static const Color cardDarkHeader = Color(0xFF0F172A);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color dividerDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);

  // Risk colors
  static const Color riskLow = Color(0xFF10B981);
  static const Color riskLowBg = Color(0xFFD1FAE5);
  static const Color riskMedium = Color(0xFFF59E0B);
  static const Color riskMediumBg = Color(0xFFFEF3C7);
  static const Color riskHigh = Color(0xFFEF4444);
  static const Color riskHighBg = Color(0xFFFEE2E2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static Color getAdaptiveTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimary;

  static Color getAdaptiveTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondary;

  static Color getAdaptiveTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textMutedDark : textMuted;
}

class AppTextStyles {
  static TextStyle getH1(bool isDark) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle getH2(bool isDark) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle getH3(bool isDark) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
  );

  static TextStyle getBody(bool isDark) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle getCaption(bool isDark) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle getSmall(bool isDark) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
  );

  // Backward compatibility static getters (using light mode by default or global context if possible, 
  // but better to use the methods above in build methods)
  static const TextStyle h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5);
  static const TextStyle h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
  static const TextStyle body = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5);
  static const TextStyle caption = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.4);
  static const TextStyle small = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
}

ThemeData buildLightTheme() {
  return _buildTheme(isDark: false);
}

ThemeData buildDarkTheme() {
  return _buildTheme(isDark: true);
}

ThemeData _buildTheme({required bool isDark}) {
  final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
  final cardColor = isDark ? AppColors.cardDarkBody : AppColors.card;
  final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;
  final borderColor = isDark ? AppColors.borderDark : AppColors.border;

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: cardColor,
      onSurface: textColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: bgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.backgroundDark : AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: AppTextStyles.getCaption(isDark),
      hintStyle: AppTextStyles.getSmall(isDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? AppColors.cardDarkBody : Colors.white,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: isDark ? AppColors.textMutedDark : AppColors.textMuted,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerColor: dividerColor,
    listTileTheme: ListTileThemeData(
      iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
      titleTextStyle: AppTextStyles.getBody(isDark),
      subtitleTextStyle: AppTextStyles.getCaption(isDark),
    ),
    textTheme: TextTheme(
      headlineLarge: AppTextStyles.getH1(isDark),
      headlineMedium: AppTextStyles.getH2(isDark),
      titleLarge: AppTextStyles.getH3(isDark),
      bodyLarge: AppTextStyles.getBody(isDark),
      bodyMedium: AppTextStyles.getBody(isDark).copyWith(fontSize: 15),
      bodySmall: AppTextStyles.getCaption(isDark),
      labelSmall: AppTextStyles.getSmall(isDark),
    ),
  );
}

// Keep the old name for compatibility during migration if needed
ThemeData buildAppTheme() => buildLightTheme();
