import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings_ar.dart';

/// Bottom navigation bar widget matching the design
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Iconsax.user,
                activeIcon: Iconsax.user5,
                label: AppStringsAr.profile,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Iconsax.shopping_bag,
                activeIcon: Iconsax.shopping_bag5,
                label: AppStringsAr.cart,
              ),
              _buildHomeItem(context),
              _buildNavItem(
                context,
                index: 3,
                icon: Iconsax.map,
                activeIcon: Iconsax.map5,
                label: AppStringsAr.map,
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Iconsax.shop,
                activeIcon: Iconsax.shop5,
                label: 'المتجر',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? AppColors.primaryOrange
                  : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primaryOrange
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeItem(BuildContext context) {
    final isSelected = currentIndex == 2;

    return InkWell(
      onTap: () => onTap(2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange
              : AppColors.primaryOrange.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? Iconsax.home5 : Iconsax.home,
          color: isSelected ? AppColors.white : AppColors.primaryOrange,
          size: 26,
        ),
      ),
    );
  }
}
