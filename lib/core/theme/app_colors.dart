import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF003629);
  static const Color accent = Color(0xFF00D4AA);
  static const Color indigo = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFFFFFF);
  static const Color buttonText = Color(0xFF003629);
  static const Color background = Color(0xFFF3FBF7);
  static const Color appBar = Color(0xFFE8F8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFEEF8F3);
  static const Color card = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF003629);
  static const Color divider = Color(0xFFD7E6DF);
  static const Color success = Color(0xFF003629);
  static const Color mutedSuccess = Color(0xFF9DB8AF);
  static const Color warning = Color(0xFFF4845F);
  static const Color error = Color(0xFFC01818);
  static const Color textPrimary = Color(0xFF111817);
  static const Color textSecondary = Color(0xFF687A75);
  static const Color textOnButton = Color(0xFFFFFFFF);

  static const MaterialColor primarySwatch = MaterialColor(0xFF003629, {
    50: Color(0xFFE6F2EE),
    100: Color(0xFFC1DDD4),
    200: Color(0xFF98C6B7),
    300: Color(0xFF6EAF9A),
    400: Color(0xFF4F9E85),
    500: Color(0xFF2F8D70),
    600: Color(0xFF247F64),
    700: Color(0xFF176D55),
    800: Color(0xFF0C5C47),
    900: Color(0xFF003629),
  });

  static Color get primaryGlow => primary.withValues(alpha: 0.12);
  static Color get accentGlow => accent.withValues(alpha: 0.18);
}
