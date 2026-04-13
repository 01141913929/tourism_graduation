import 'package:flutter/material.dart';

/// 🎨 نظام الألوان الاحترافي - Egyptian Tourism Admin Panel
/// تصميم مستوحى من الحضارة المصرية مع لمسات عصرية
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // الألوان الأساسية - Egyptian Theme
  // ═══════════════════════════════════════════════════════════════

  /// الأخضر الزمردي - اللون الرئيسي
  static const Color primary = Color(0xFF1A5F52);
  static const Color primaryLight = Color(0xFF2D8B7A);
  static const Color primaryDark = Color(0xFF0D3830);
  static const Color primarySurface = Color(0xFFE8F5F2);

  /// الذهبي الفرعوني - اللون الثانوي
  static const Color secondary = Color(0xFFD4A574);
  static const Color secondaryLight = Color(0xFFE8C9A8);
  static const Color secondaryDark = Color(0xFFB8894E);

  /// الأحمر المصري
  static const Color accent = Color(0xFFE8442E);
  static const Color accentLight = Color(0xFFFF6B5B);

  // ═══════════════════════════════════════════════════════════════
  // Sidebar - تدرج داكن أنيق
  // ═══════════════════════════════════════════════════════════════

  static const Color sidebarBg = Color(0xFF0F1419);
  static const Color sidebarHover = Color(0xFF1C2733);
  static const Color sidebarActive = Color(0xFF1A5F52);
  static const Color sidebarDivider = Color(0xFF2F3336);

  // ═══════════════════════════════════════════════════════════════
  // ألوان الخلفية
  // ═══════════════════════════════════════════════════════════════

  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color elevated = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════
  // ألوان النص
  // ═══════════════════════════════════════════════════════════════

  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFFBBC0C5);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════
  // ألوان الحالة
  // ═══════════════════════════════════════════════════════════════

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // ═══════════════════════════════════════════════════════════════
  // ألوان إضافية
  // ═══════════════════════════════════════════════════════════════

  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE5E7EB);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // حالات الطلبات
  static const Color pending = warning;
  static const Color approved = success;
  static const Color rejected = error;
  static const Color processing = info;
}

/// 🎨 التدرجات اللونية الاحترافية
class AppGradients {
  AppGradients._();

  /// تدرج الـ Sidebar
  static const LinearGradient sidebar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F1419),
      Color(0xFF1A1D26),
    ],
  );

  /// تدرج ذهبي فرعوني
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4A574),
      Color(0xFFE8C9A8),
      Color(0xFFD4A574),
    ],
  );

  /// تدرج زمردي
  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A5F52),
      Color(0xFF2D8B7A),
    ],
  );

  /// تدرج للـ Cards
  static const LinearGradient cardShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  /// تدرج للإحصائيات - Revenue
  static const LinearGradient revenue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );

  /// تدرج للإحصائيات - Orders
  static const LinearGradient orders = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );

  /// تدرج للإحصائيات - Users
  static const LinearGradient users = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF7C3AED),
    ],
  );

  /// تدرج للإحصائيات - Products
  static const LinearGradient products = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );
}

/// 🎨 الظلال الاحترافية
class AppShadows {
  AppShadows._();

  /// ظل خفيف للبطاقات
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// ظل متوسط للعناصر المرتفعة
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// ظل عميق للعناصر المحددة
  static List<BoxShadow> get deep => [
        BoxShadow(
          color: AppColors.black.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  /// ظل ملون للأزرار
  static List<BoxShadow> primaryButton(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
