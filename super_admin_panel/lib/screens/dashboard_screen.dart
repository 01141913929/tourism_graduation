import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/theme/app_theme.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_data_provider.dart';
import '../widgets/animated_sidebar.dart';
import '../widgets/stat_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/hover_scale_widget.dart';
import '../widgets/animated_chart.dart';
import 'bazaars_list_screen.dart';
import 'bazaar_applications_screen.dart';
import 'all_orders_screen.dart';
import 'users_management_screen.dart';
import 'audit_logs_screen.dart';
import 'products_management_screen.dart';
import 'categories_management_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'ai_insights_dashboard_screen.dart';
import 'ai_chat_screen.dart';

/// 🏠 شاشة Dashboard الرئيسية - تصميم احترافي
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
          // Sidebar الاحترافي
          Consumer<AdminAuthProvider>(
            builder: (context, auth, _) {
              return AnimatedSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                userName: auth.user?.name,
                userEmail: auth.user?.email,
                onLogout: () => _handleLogout(context, auth),
              );
            },
          ),

          // المحتوى الرئيسي
          Expanded(
            child: _buildContent(),
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
      case 9:
        return const AIInsightsDashboardScreen();
      case 10:
        return const AIChatScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Consumer<AdminDataProvider>(
      builder: (context, dataProvider, _) {
        return RefreshIndicator(
          onRefresh: () => dataProvider.loadAllData(),
          child: SingleChildScrollView(
            padding: AppSpacing.pagePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ترحيب الهيدر
                _buildWelcomeHeader(),
                const SizedBox(height: 28),

                // بطاقات الإحصائيات
                if (dataProvider.isLoading)
                  const ShimmerStatsRow(count: 4)
                else
                  _buildStatsCards(dataProvider),
                const SizedBox(height: 28),

                // الرسوم البيانية
                if (!dataProvider.isLoading) _buildChartsSection(dataProvider),
                const SizedBox(height: 28),

                // طلبات البازارات المعلقة + آخر البازارات
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // طلبات معلقة
                    Expanded(
                      flex: 3,
                      child: dataProvider.isLoading
                          ? _buildShimmerCard(350)
                          : _buildPendingApplicationsCard(dataProvider),
                    ),
                    const SizedBox(width: 24),
                    // إجراءات سريعة
                    Expanded(
                      flex: 2,
                      child: _buildQuickActionsCard(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'صباح الخير'
        : now.hour < 17
            ? 'مساء الخير'
            : 'مساء الخير';

    return FadeInWidget(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$greeting 👋',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'هذه نظرة عامة على أداء منصتك اليوم',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // التاريخ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(now),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AdminDataProvider dataProvider) {
    final formatter = NumberFormat('#,###', 'ar');

    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: StatsRow(
        cards: [
          StatCard(
            icon: Iconsax.money_recive,
            title: 'إجمالي الإيرادات',
            value: '${formatter.format(dataProvider.totalRevenue)} ج.م',
            gradient: AppGradients.revenue,
            showTrend: true,
            trendValue: 12.5,
            isPositiveTrend: true,
            onTap: () => setState(() => _selectedIndex = 5),
          ),
          StatCard(
            icon: Iconsax.shopping_bag,
            title: 'إجمالي الطلبات',
            value: formatter.format(dataProvider.totalOrders),
            gradient: AppGradients.orders,
            showTrend: true,
            trendValue: 8.2,
            isPositiveTrend: true,
            onTap: () => setState(() => _selectedIndex = 5),
          ),
          StatCard(
            icon: Iconsax.people,
            title: 'إجمالي المستخدمين',
            value: formatter.format(dataProvider.totalUsers),
            gradient: AppGradients.users,
            onTap: () => setState(() => _selectedIndex = 6),
          ),
          StatCard(
            icon: Iconsax.shop,
            title: 'إجمالي البازارات',
            value: formatter.format(dataProvider.totalBazaars),
            gradient: AppGradients.products,
            subtitle: '${dataProvider.pendingApplications.length} طلب معلق',
            onTap: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(AdminDataProvider dataProvider) {
    // بيانات تجريبية للرسوم البيانية
    final weeklyOrders = [
      FlSpot(0, 30),
      FlSpot(1, 45),
      FlSpot(2, 35),
      FlSpot(3, 60),
      FlSpot(4, 50),
      FlSpot(5, 75),
      FlSpot(6, 65),
    ];

    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رسم بياني للطلبات
          Expanded(
            flex: 2,
            child: AnimatedLineChart(
              spots: weeklyOrders,
              title: '📈 الطلبات خلال الأسبوع',
              lineColor: AppColors.primary,
              gradientColor: AppColors.primaryLight,
              height: 280,
            ),
          ),
          const SizedBox(width: 24),
          // رسم بياني للتوزيع
          Expanded(
            child: AnimatedPieChart(
              title: '📊 توزيع المبيعات',
              height: 280,
              items: [
                PieChartItem(
                  label: 'الحرف اليدوية',
                  value: 35,
                  color: AppColors.primary,
                ),
                PieChartItem(
                  label: 'التحف',
                  value: 25,
                  color: AppColors.secondary,
                ),
                PieChartItem(
                  label: 'المنسوجات',
                  value: 20,
                  color: AppColors.info,
                ),
                PieChartItem(
                  label: 'أخرى',
                  value: 20,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApplicationsCard(AdminDataProvider dataProvider) {
    final pendingApps = dataProvider.pendingApplications;

    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Iconsax.document_text,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلبات البازارات المعلقة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${pendingApps.length} طلب ينتظر المراجعة',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 4),
                  icon: const Text('عرض الكل'),
                  label: Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),

            // قائمة الطلبات
            if (pendingApps.isEmpty)
              _buildEmptyState('لا توجد طلبات معلقة', Iconsax.document_text)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pendingApps.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final app = pendingApps[index];
                  return _buildApplicationItem(app);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationItem(BazaarApplication app) {
    return HoverScaleWidget(
      scaleOnHover: 1.01,
      onTap: () => setState(() => _selectedIndex = 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  app.bazaarName.isNotEmpty
                      ? app.bazaarName[0].toUpperCase()
                      : 'ب',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // معلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.bazaarName.isNotEmpty ? app.bazaarName : 'بازار جديد',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.ownerName.isNotEmpty ? app.ownerName : 'اسم المالك',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // الحالة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'معلق',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.flash_1,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQuickAction(
              icon: Iconsax.box_add,
              label: 'إضافة منتج جديد',
              color: AppColors.primary,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              icon: Iconsax.category_2,
              label: 'إدارة الفئات',
              color: AppColors.info,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              icon: Iconsax.user_add,
              label: 'عرض المستخدمين',
              color: AppColors.secondary,
              onTap: () => setState(() => _selectedIndex = 6),
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              icon: Iconsax.setting_2,
              label: 'إعدادات المنصة',
              color: AppColors.textSecondary,
              onTap: () => setState(() => _selectedIndex = 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HoverScaleWidget(
      scaleOnHover: 1.02,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(
          5,
          (index) => const ShimmerListItem(),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, AdminAuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}
