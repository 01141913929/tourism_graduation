import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../core/constants/colors.dart';
import '../models/sub_order_model.dart';
import 'qr_scanner_screen.dart';
import 'order_details_screen.dart';
import 'login_screen.dart';
import 'products_management_screen.dart';
import 'bazaar_settings_screen.dart';
import 'bazaar_statistics_screen.dart';
import 'reviews_screen.dart';
import 'customer_messages_screen.dart';
import 'coupons_screen.dart';
import 'reports_screen.dart';
import 'ai_insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;

  // أيقونات الـ navbar
  final List<IconData> _iconList = [
    Iconsax.home_2,
    Iconsax.bag_2,
    Iconsax.user,
    Iconsax.setting_2,
  ];

  // تسميات الـ navbar
  final List<String> _labelList = [
    'الرئيسية',
    'الطلبات',
    'الحساب',
    'الإعدادات',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeDashboard();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    final authProvider = context.read<BazaarAuthProvider>();
    if (authProvider.user?.bazaarId != null) {
      context.read<OrderProvider>().setBazaarId(authProvider.user!.bazaarId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
          const BazaarSettingsScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child:
            const Icon(Iconsax.scan_barcode, color: AppColors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? AppColors.primary : AppColors.textHint;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconList[index], size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                _labelList[index],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        },
        activeIndex: _currentIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 24,
        rightCornerRadius: 24,
        backgroundColor: AppColors.white,
        splashColor: AppColors.primary.withOpacity(0.1),
        splashSpeedInMilliseconds: 300,
        elevation: 8,
        onTap: (index) => setState(() => _currentIndex = index),
        height: 70,
        shadow: BoxShadow(
          color: AppColors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Consumer2<BazaarAuthProvider, OrderProvider>(
      builder: (context, auth, orders, _) {
        return RefreshIndicator(
          onRefresh: () => orders.loadOrders(),
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header احترافي مع gradient
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.darkGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Top row
                          Row(
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.2),
                                  child: Text(
                                    auth.user?.name.isNotEmpty == true
                                        ? auth.user!.name[0].toUpperCase()
                                        : 'B',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'مرحباً، ${auth.user?.name ?? "صاحب البازار"}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'البازار مفتوح',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.white
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Notifications
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Iconsax.notification,
                                          color: AppColors.white),
                                      onPressed: () {},
                                    ),
                                    if (orders.pendingCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${orders.pendingCount}',
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // إيرادات اليوم - بطاقة كبيرة
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'إيرادات اليوم',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              AppColors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${orders.todayRevenue.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.white,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.only(
                                                bottom: 6, right: 4),
                                            child: Text(
                                              'ج.م',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Iconsax.money_recive,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Stat cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Row
                      Row(
                        children: [
                          Expanded(
                              child: _buildMiniStatCard(
                            icon: Iconsax.bag_tick,
                            title: 'طلبات اليوم',
                            value: '${orders.todayOrdersCount}',
                            color: AppColors.success,
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildMiniStatCard(
                            icon: Iconsax.timer_1,
                            title: 'معلقة',
                            value: '${orders.pendingCount}',
                            color: AppColors.warning,
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildMiniStatCard(
                            icon: Iconsax.activity,
                            title: 'نشطة',
                            value: '${orders.activeCount}',
                            color: AppColors.info,
                          )),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        '⚡ اختصارات سريعة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.box_add,
                            title: 'إضافة منتج',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ProductsManagementScreen()),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.chart_2,
                            title: 'الإحصائيات',
                            color: AppColors.info,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const BazaarStatisticsScreen()),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.ticket_discount,
                            title: 'الكوبونات',
                            color: AppColors.success,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CouponsScreen()),
                            ),
                          )),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Second row: Reports, Reviews, Messages
                      Row(
                        children: [
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.document_text,
                            title: 'التقارير',
                            color: AppColors.warning,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReportsScreen()),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.star,
                            title: 'التقييمات',
                            color: Colors.amber,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ReviewsScreen()),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.message,
                            title: 'الرسائل',
                            color: Colors.purple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const CustomerMessagesScreen()),
                            ),
                          )),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Third row: AI Insights (Premium)
                      Row(
                        children: [
                          Expanded(
                              child: _buildQuickAction(
                            icon: Iconsax.cpu,
                            title: 'تحليلات AI',
                            color: const Color(0xFF667eea),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const AIInsightsScreen()),
                            ),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: Container()),
                          const SizedBox(width: 12),
                          Expanded(child: Container()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Pending orders section
                      if (orders.pendingOrders.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Iconsax.notification_bing,
                                      color: AppColors.warning, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'طلبات تحتاج موافقتك',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _currentIndex = 1),
                              child: const Text('عرض الكل'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...orders.pendingOrders.take(3).map(
                              (order) =>
                                  _buildOrderCard(order, isPending: true),
                            ),
                      ] else ...[
                        // Empty state with tip
                        _buildTipCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.lamp_on, color: AppColors.info, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 نصيحة اليوم',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'أضف صور عالية الجودة لمنتجاتك لزيادة المبيعات بنسبة 40%!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, orders, _) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('الطلبات'),
              bottom: TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'معلقة (${orders.pendingOrders.length})'),
                  Tab(text: 'نشطة (${orders.activeOrders.length})'),
                  Tab(text: 'مكتملة (${orders.completedOrders.length})'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOrdersList(orders.pendingOrders, isPending: true),
                _buildOrdersList(orders.activeOrders),
                _buildOrdersList(orders.completedOrders),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(List<SubOrder> ordersList, {bool isPending = false}) {
    if (ordersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 60, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ordersList.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(ordersList[index], isPending: isPending);
      },
    );
  }

  Widget _buildOrderCard(SubOrder order, {bool isPending = false}) {
    final dateFormat = DateFormat('dd/MM - HH:mm', 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(order.status),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${order.id.substring(0, 8)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.user, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                order.customerName,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                dateFormat.format(order.createdAt),
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${order.itemCount} منتج',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '${order.subtotal.toStringAsFixed(0)} ج.م',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('رفض'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('قبول'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
                child: const Text('عرض التفاصيل'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptOrder(SubOrder order) async {
    final orderProvider = context.read<OrderProvider>();
    final success = await orderProvider.acceptOrder(order.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم قبول الطلب' : 'حدث خطأ'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectOrder(SubOrder order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('سبب الرفض'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'أدخل سبب رفض الطلب'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('رفض'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.rejectOrder(order.id, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم رفض الطلب' : 'حدث خطأ'),
            backgroundColor: success ? AppColors.info : AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return AppColors.pending;
      case SubOrderStatus.accepted:
        return AppColors.accepted;
      case SubOrderStatus.preparing:
        return AppColors.preparing;
      case SubOrderStatus.readyForPickup:
        return AppColors.readyForPickup;
      case SubOrderStatus.shipping:
        return AppColors.shipping;
      case SubOrderStatus.delivered:
        return AppColors.delivered;
      case SubOrderStatus.rejected:
        return AppColors.rejected;
      case SubOrderStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  Widget _buildProfileTab() {
    return Consumer<BazaarAuthProvider>(
      builder: (context, auth, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Profile header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        auth.user?.name.substring(0, 1).toUpperCase() ?? 'B',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.user?.name ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      auth.user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items
              _buildProfileMenuItem(
                icon: Iconsax.box,
                title: 'إدارة المنتجات',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsManagementScreen(),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.chart,
                title: 'التقارير والإحصائيات',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BazaarStatisticsScreen(),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.setting_2,
                title: 'إعدادات البازار',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BazaarSettingsScreen(),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.star,
                title: 'تقييمات العملاء',
                subtitle: 'شاهد آراء عملائك',
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.message,
                title: 'رسائل العملاء',
                subtitle: 'استفسارات ورسائل',
                color: AppColors.info,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerMessagesScreen()),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.ticket_discount,
                title: 'الكوبونات',
                subtitle: 'إدارة كوبونات الخصم',
                color: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CouponsScreen()),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Iconsax.support,
                title: 'الدعم الفني',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  icon: const Icon(Iconsax.logout, color: AppColors.error),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final iconColor = color ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
