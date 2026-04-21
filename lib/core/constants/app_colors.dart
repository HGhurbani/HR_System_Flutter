import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF1B4F72);
  static const Color primaryLight = Color(0xFF2E86C1);
  static const Color primaryDark = Color(0xFF154360);

  static const Color secondary = Color(0xFF27AE60);
  static const Color secondaryLight = Color(0xFF2ECC71);
  static const Color secondaryDark = Color(0xFF1E8449);

  static const Color accent = Color(0xFFE67E22);
  static const Color accentLight = Color(0xFFF39C12);

  // Semantic Colors
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF2980B9);

  // Status Colors
  static const Color statusNew = Color(0xFF3498DB);
  static const Color statusAvailable = Color(0xFF27AE60);
  static const Color statusInProgress = Color(0xFFE67E22);
  static const Color statusReserved = Color(0xFF8E44AD);
  static const Color statusCompleted = Color(0xFF2ECC71);
  static const Color statusCancelled = Color(0xFFE74C3C);

  // Attendance Status Colors
  static const Color attendancePresent = Color(0xFF27AE60);
  static const Color attendanceAbsent = Color(0xFFE74C3C);
  static const Color attendanceLate = Color(0xFFF39C12);
  static const Color attendanceLeave = Color(0xFF3498DB);

  // Leave Status Colors
  static const Color leavePending = Color(0xFFF39C12);
  static const Color leaveApproved = Color(0xFF27AE60);
  static const Color leaveRejected = Color(0xFFE74C3C);

  // Light Theme Surfaces
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFEFF2F5);
  static const Color borderLight = Color(0xFFDEE2E6);
  static const Color dividerLight = Color(0xFFE9ECEF);

  // Dark Theme Surfaces
  static const Color surfaceDark = Color(0xFF1A1D23);
  static const Color cardDark = Color(0xFF242832);
  static const Color backgroundDark = Color(0xFF13151A);
  static const Color borderDark = Color(0xFF343A40);
  static const Color dividerDark = Color(0xFF2C3038);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE9ECEF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [secondaryDark, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
