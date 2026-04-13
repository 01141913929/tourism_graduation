import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';

/// 🎨 Sidebar احترافي مع تأثيرات Hover
/// تصميم عصري مع انتقالات سلسة
class AnimatedSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onLogout;
  final String? userName;
  final String? userEmail;

  const AnimatedSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onLogout,
    this.userName,
    this.userEmail,
  });

  @override
  State<AnimatedSidebar> createState() => _AnimatedSidebarState();
}

class _AnimatedSidebarState extends State<AnimatedSidebar> {
  int? _hoveredIndex;

  final List<_SidebarItem> _mainItems = [
    _SidebarItem(icon: Iconsax.home_2, label: 'الرئيسية'),
    _SidebarItem(icon: Iconsax.box_1, label: 'المنتجات'),
    _SidebarItem(icon: Iconsax.category_2, label: 'الفئات'),
    _SidebarItem(icon: Iconsax.shop, label: 'البازارات'),
    _SidebarItem(icon: Iconsax.document_text, label: 'طلبات البازارات'),
    _SidebarItem(icon: Iconsax.shopping_cart, label: 'الطلبات'),
    _SidebarItem(icon: Iconsax.people, label: 'المستخدمين'),
    _SidebarItem(icon: Iconsax.clipboard_text, label: 'سجل النشاطات'),
    _SidebarItem(icon: Iconsax.setting_2, label: 'الإعدادات'),
    _SidebarItem(icon: Iconsax.cpu, label: '🤖 AI Dashboard'),
    _SidebarItem(icon: Iconsax.message_programming, label: '🤖 AI Chat'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: AppGradients.sidebar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          _buildLogoSection(),

          const SizedBox(height: 8),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: AppColors.sidebarDivider.withOpacity(0.5),
              thickness: 1,
            ),
          ),

          const SizedBox(height: 12),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: _mainItems.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index, _mainItems[index]);
              },
            ),
          ),

          // User Profile Section
          _buildUserSection(),

          // Logout Button
          _buildLogoutButton(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Logo Icon with Glow
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.crown_1,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.gold.createShader(bounds),
                  child: const Text(
                    'لوحة التحكم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, _SidebarItem item) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.defaultCurve,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => widget.onItemSelected(index),
              borderRadius: BorderRadius.circular(12),
              splashColor: AppColors.primary.withOpacity(0.1),
              hoverColor: Colors.transparent,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isHovered
                          ? AppColors.sidebarHover
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isHovered
                              ? AppColors.sidebarDivider.withOpacity(0.3)
                              : Colors.transparent,
                          width: 1,
                        ),
                ),
                child: Row(
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: AppDurations.fast,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : isHovered
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: isSelected
                            ? Colors.white
                            : isHovered
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Label
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: AppDurations.fast,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isHovered
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.6),
                        ),
                        child: Text(item.label),
                      ),
                    ),

                    // Arrow for selected
                    if (isSelected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.sidebarHover.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.sidebarDivider.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.userName?.isNotEmpty == true
                    ? widget.userName![0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'المدير',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userEmail ?? 'admin@example.com',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _HoverButton(
        onTap: widget.onLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.error.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.logout,
                size: 18,
                color: AppColors.error.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;

  const _SidebarItem({
    required this.icon,
    required this.label,
  });
}

class _HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HoverButton({
    required this.child,
    this.onTap,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: _isHovered ? 1.0 : 0.8,
          child: AnimatedScale(
            duration: AppDurations.fast,
            scale: _isHovered ? 1.02 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
