import 'package:flutter/material.dart';

/// App color palette based on Egyptian tourism theme
class AppColors {
  // Primary Colors
  static const Color primaryOrange = Color(0xFFE87A2B);
  static const Color primaryOrangeLight = Color(0xFFF5A623);
  static const Color primaryOrangeDark = Color(0xFFD4651F);

  // Secondary Colors
  static const Color secondaryTeal = Color(0xFF1A8B7C);
  static const Color secondaryTealLight = Color(0xFF2AA89A);
  static const Color secondaryTealDark = Color(0xFF14665A);

  // Egyptian Theme Colors
  static const Color gold = Color(0xFFC4942B);
  static const Color primaryGold = gold; // alias for consistency
  static const Color goldLight = Color(0xFFD4A84B);
  static const Color pharaohBlue = Color(0xFF1E3A5F);
  static const Color sandBeige = Color(0xFFF5E6D3);

  // Egyptian Theme Aliases (mapping to existing colors)
  static const Color egyptianGold = gold;
  static const Color egyptianGreen = secondaryTeal;
  static const Color egyptianBlue = pharaohBlue;

  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [secondaryTeal, secondaryTealLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
