import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String _arabicFont = 'Tajawal';
  static const String _englishFont = 'Tajawal';

  static String _fontFamily(bool isArabic) =>
      isArabic ? _arabicFont : _englishFont;

  // ─── Light Theme ─────────────────────────────────────────────────────────
  static ThemeData lightTheme({bool isArabic = true}) {
    final font = _fontFamily(isArabic);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.cardLight,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: font,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.goldLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.goldLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.goldLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.gold),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontFamily: font,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: font,
          color: AppColors.textDisabled,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          fontFamily: font,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: font,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        selectedItemColor: AppColors.goldDark,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      // TabBar على خلفية فاتحة (داخل body)
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.goldDark,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.gold,
        dividerColor: AppColors.dividerLight,
        labelStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      // NavigationBar (Material 3) لا يعتمد على BottomNavigationBarTheme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardLight,
        indicatorColor: AppColors.gold.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: font,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.goldDark : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.goldDark : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      textTheme: _buildTextTheme(font, AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────
  static ThemeData darkTheme({bool isArabic = true}) {
    final font = _fontFamily(isArabic);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      primary: AppColors.goldLight,
      onPrimary: AppColors.primaryDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.cardDark,
      onSurface: AppColors.textOnDark,
      error: AppColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: font,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.goldLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: font,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.goldLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: TextStyle(fontFamily: font, color: AppColors.textSecondary),
        hintStyle: TextStyle(fontFamily: font, color: AppColors.textDisabled),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.gold.withValues(alpha: 0.22),
        labelStyle: TextStyle(
          fontFamily: font,
          fontSize: 13,
          color: AppColors.textOnDark,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: font,
          fontSize: 13,
          color: AppColors.textOnDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.goldLight,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.goldLight,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.gold,
        dividerColor: AppColors.dividerDark,
        labelStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: font,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.cardDark,
        indicatorColor: AppColors.gold.withValues(alpha: 0.26),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: font,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.goldLight : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.goldLight : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      textTheme: _buildTextTheme(font, AppColors.textOnDark),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }

  static TextTheme _buildTextTheme(String font, Color color) {
    return TextTheme(
      displayLarge: TextStyle(
          fontFamily: font,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: color),
      displayMedium: TextStyle(
          fontFamily: font,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color),
      displaySmall: TextStyle(
          fontFamily: font,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color),
      headlineLarge: TextStyle(
          fontFamily: font,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: color),
      headlineMedium: TextStyle(
          fontFamily: font,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: color),
      headlineSmall: TextStyle(
          fontFamily: font,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color),
      titleLarge: TextStyle(
          fontFamily: font,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color),
      titleMedium: TextStyle(
          fontFamily: font,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color),
      titleSmall: TextStyle(
          fontFamily: font,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color),
      bodyLarge: TextStyle(
          fontFamily: font,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: color),
      bodyMedium: TextStyle(
          fontFamily: font,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: color),
      bodySmall: TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color),
      labelLarge: TextStyle(
          fontFamily: font,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color),
      labelMedium: TextStyle(
          fontFamily: font,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color),
      labelSmall: TextStyle(
          fontFamily: font,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color),
    );
  }
}
