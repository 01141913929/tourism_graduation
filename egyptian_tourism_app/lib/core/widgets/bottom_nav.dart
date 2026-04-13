import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_strings.dart';

/// Bottom navigation bar using animated_notch_bottom_bar package
/// Full-width, non-floating style that fills the bottom area
class AppBottomNavBar extends StatelessWidget {
  final NotchBottomBarController controller;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedNotchBottomBar(
      notchBottomBarController: controller,
      onTap: onTap,
      kIconSize: 24,
      kBottomRadius: 0,
      // --- Full-width, non-floating style ---
      removeMargins: true,
      showTopRadius: false,
      showBottomRadius: false,
      // --- Styling ---
      color: AppColors.background,
      notchColor: AppColors.primaryOrange,
      notchGradient: const LinearGradient(
        colors: [AppColors.primaryOrange, AppColors.primaryOrangeLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      showShadow: true,
      elevation: 1.0,
      bottomBarHeight: 62,
      durationInMilliSeconds: 250,
      showLabel: true,
      itemLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      // --- Nav Items ---
      bottomBarItems: [
        BottomBarItem(
          inActiveItem:
              const Icon(Iconsax.user, color: AppColors.textSecondary),
          activeItem: const Icon(Iconsax.user5, color: Colors.white),
          itemLabel: AppStrings.profile,
        ),
        BottomBarItem(
          inActiveItem:
              const Icon(Iconsax.shopping_bag, color: AppColors.textSecondary),
          activeItem: const Icon(Iconsax.shopping_bag5, color: Colors.white),
          itemLabel: AppStrings.cart,
        ),
        BottomBarItem(
          inActiveItem:
              const Icon(Iconsax.home, color: AppColors.textSecondary),
          activeItem: const Icon(Iconsax.home5, color: Colors.white),
          itemLabel: AppStrings.isArabic ? 'الرئيسية' : 'Home',
        ),
        BottomBarItem(
          inActiveItem: const Icon(Iconsax.map, color: AppColors.textSecondary),
          activeItem: const Icon(Iconsax.map5, color: Colors.white),
          itemLabel: AppStrings.isArabic ? 'الخريطة' : 'Map',
        ),
        BottomBarItem(
          inActiveItem:
              const Icon(Iconsax.shop, color: AppColors.textSecondary),
          activeItem: const Icon(Iconsax.shop5, color: Colors.white),
          itemLabel: AppStrings.isArabic ? 'المتجر' : 'Store',
        ),
      ],
    );
  }
}
