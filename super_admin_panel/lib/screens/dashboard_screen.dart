import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../core/constants/colors.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_data_provider.dart';
import 'bazaars_list_screen.dart';
import 'bazaar_applications_screen.dart';
import 'all_orders_screen.dart';
import 'users_management_screen.dart';
import 'audit_logs_screen.dart';
import 'products_management_screen.dart';
import 'categories_management_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Iconsax.home, label: 'الرئيسية'),
    _NavItem(icon: Iconsax.box_1, label: 'المنتجات'),
    _NavItem(icon: Iconsax.category, label: 'الفئات'),
    _NavItem(icon: Iconsax.shop, label: 'البازارات'),
    _NavItem(icon: Iconsax.document, label: 'طلبات البازارات'),
    _NavItem(icon: Iconsax.shopping_cart, label: 'الطلبات'),
    _NavItem(icon: Iconsax.people, label: 'المستخدمين'),
    _NavItem(icon: Iconsax.clipboard_text, label: 'سجل النشاطات'),
    _NavItem(icon: Iconsax.setting_2, label: 'الإعدادات'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDataProvider>().loadAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),

          // Main content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: index == 2
                        ? Consumer<AdminDataProvider>(
                            builder: (context, provider, _) {
                              if (provider.pendingApprovals == 0) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${provider.pendingApprovals}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              },
            ),
          ),

          // User info & logout
          Consumer<AdminAuthProvider>(
            builder: (context, auth, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        auth.user?.name.isNotEmpty == true
                            ? auth.user!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.user?.name ?? 'مدير النظام',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            auth.user?.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.logout, color: AppColors.error),
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const ProductsManagementScreen();
      case 2:
        return const CategoriesManagementScreen();
      case 3:
        return const BazaarsListScreen();
      case 4:
        return const BazaarApplicationsScreen();
      case 5:
        return const AllOrdersScreen();
      case 6:
        return const UsersManagementScreen();
      case 7:
        return const AuditLogsScreen();
      case 8:
        return const SettingsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Consumer<AdminDataProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('جاري تحميل البيانات...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // عرض رسالة خطأ إذا وجدت
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadAllData(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  icon: const Icon(Iconsax.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً بك في لوحة التحكم 👋',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'إحصائيات المنصة وآخر المستجدات',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadAllData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Iconsax.refresh, size: 18),
                    label: const Text('تحديث البيانات'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Statistics cards - Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.box_1,
                      title: 'إجمالي المنتجات',
                      value: '${provider.totalProducts}',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.shop,
                      title: 'البازارات النشطة',
                      value: '${provider.totalBazaars}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.document_text,
                      title: 'طلبات بازارات جديدة',
                      value: '${provider.pendingApprovals}',
                      color: AppColors.warning,
                      showBadge: provider.pendingApprovals > 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.shopping_cart,
                      title: 'إجمالي الطلبات',
                      value: '${provider.totalOrders}',
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Iconsax.money,
                      title: 'إجمالي الإيرادات',
                      value: '${provider.totalRevenue.toStringAsFixed(0)} ج.م',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Pending applications section
              if (provider.pendingApplications.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📋 طلبات بازارات جديدة تحتاج موافقة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedIndex = 2),
                      icon: const Icon(Iconsax.arrow_left_2),
                      label: const Text('عرض الكل'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.pendingApplications
                    .take(3)
                    .map((app) => _buildApplicationCard(app, provider)),
              ],

              const SizedBox(height: 32),

              // Recent bazaars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🏪 أحدث البازارات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    icon: const Icon(Iconsax.arrow_left_2),
                    label: const Text('عرض الكل'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBazaarsTable(provider.allBazaars.take(5).toList()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool showBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(icon, color: color, size: 28),
                if (showBadge)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
    BazaarApplication app,
    AdminDataProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.shop, color: AppColors.warning),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.bazaarName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${app.ownerName} • ${app.governorate}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showRejectDialog(app, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Iconsax.close_circle, size: 18),
                label: const Text('رفض'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _handleApprove(app, provider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Iconsax.tick_circle, size: 18),
                label: const Text('موافقة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBazaarsTable(List<dynamic> bazaars) {
    if (bazaars.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'لا توجد بازارات حتى الآن',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            children: [
              _buildTableHeader('البازار'),
              _buildTableHeader('المحافظة'),
              _buildTableHeader('الحالة'),
              _buildTableHeader('التقييم'),
            ],
          ),
          ...bazaars.map(
            (bazaar) => TableRow(
              children: [
                _buildTableCell(bazaar.nameAr),
                _buildTableCell(bazaar.governorate),
                _buildStatusCell(bazaar.isVerified),
                _buildRatingCell(bazaar.rating),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }

  Widget _buildStatusCell(bool isVerified) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isVerified
              ? AppColors.success.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isVerified ? 'نشط' : 'معطل',
          style: TextStyle(
            color: isVerified ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRatingCell(double rating) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.warning, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
    BazaarApplication app,
    AdminDataProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text(
          'هل أنت متأكد من الموافقة على بازار "${app.bazaarName}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.approveApplication(app);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تمت الموافقة بنجاح' : 'حدث خطأ'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BazaarApplication app, AdminDataProvider provider) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('سبب رفض بازار "${app.bazaarName}":'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'أدخل سبب الرفض...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال سبب الرفض')),
                );
                return;
              }
              Navigator.pop(context);
              final success = await provider.rejectApplication(
                app,
                reasonController.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'تم الرفض بنجاح' : 'حدث خطأ'),
                    backgroundColor:
                        success ? AppColors.warning : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
