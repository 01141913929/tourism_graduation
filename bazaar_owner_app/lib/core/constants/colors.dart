import 'package:flutter/material.dart';

/// ألوان تطبيق صاحب البازار - نسخة احترافية
class AppColors {
  // ===== الألوان الأساسية =====
  static const Color primary = Color(0xFFD4A574); // ذهبي فاخر
  static const Color primaryDark = Color(0xFFB8956A);
  static const Color primaryLight = Color(0xFFE8C9A8);
  static const Color secondary = Color(0xFF1A5F52); // أخضر فرعوني
  static const Color secondaryLight = Color(0xFF2D8B7A);
  static const Color accent = Color(0xFFE8442E); // أحمر مميز

  // ===== ألوان الخلفية =====
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ===== ألوان النص =====
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ===== ألوان الحالة =====
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ===== ألوان إضافية =====
  static const Color divider = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x80000000);

  // ===== ألوان حالات الطلبات =====
  static const Color pending = Color(0xFFF59E0B);
  static const Color accepted = Color(0xFF3B82F6);
  static const Color preparing = Color(0xFF8B5CF6);
  static const Color readyForPickup = Color(0xFFD4A574);
  static const Color shipping = Color(0xFF6366F1);
  static const Color delivered = Color(0xFF10B981);
  static const Color rejected = Color(0xFFEF4444);
  static const Color cancelled = Color(0xFF6B7280);

  // ===== التدرجات الاحترافية =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD4A574), Color(0xFFB8956A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFD4A574)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A5F52), Color(0xFF0F3D35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A5F52), Color(0xFFD4A574)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ===== ظلال احترافية =====
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get mediumShadow => [
        BoxShadow(
          color: black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get successShadow => [
        BoxShadow(
          color: success.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];

  // ===== تأثيرات Glassmorphism =====
  static BoxDecoration get glassCard => BoxDecoration(
        color: white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: white.withOpacity(0.2)),
        boxShadow: softShadow,
      );

  static BoxDecoration get gradientCard => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: primaryShadow,
      );
}
