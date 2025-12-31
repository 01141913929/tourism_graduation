import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة التقارير الشاملة
class ComprehensiveReportsScreen extends StatefulWidget {
  const ComprehensiveReportsScreen({super.key});

  @override
  State<ComprehensiveReportsScreen> createState() =>
      _ComprehensiveReportsScreenState();
}

class _ComprehensiveReportsScreenState
    extends State<ComprehensiveReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Summary stats
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  int _totalProducts = 0;
  int _deliveredOrders = 0;
  int _cancelledOrders = 0;
  double _cancellationRate = 0;

  // Top lists
  List<Map<String, dynamic>> _topBazaars = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          break;
        case 'quarter':
          _startDate = DateTime(now.year, now.month - 2, 1);
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          break;
      }
      _endDate = now;
    });
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      // Load orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: _startDate.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: _endDate.toIso8601String())
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Calculate stats
      double totalRevenue = 0;
      int deliveredCount = 0;
      int cancelledCount = 0;
      Map<String, double> bazaarRevenue = {};
      Map<String, Map<String, dynamic>> productSales = {};

      for (final order in orders) {
        final status = order['status'] ?? '';
        final total = (order['total'] as num?)?.toDouble() ?? 0;

        if (status == 'delivered') {
          deliveredCount++;
          totalRevenue += total;

          // Bazaar revenue
          final bazaarId = order['bazaarId'];
          if (bazaarId != null) {
            bazaarRevenue[bazaarId] = (bazaarRevenue[bazaarId] ?? 0) + total;
          }

          // Product sales
          final items = order['items'] as List<dynamic>? ?? [];
          for (final item in items) {
            final productId = item['productId'];
            if (productId != null) {
              if (productSales.containsKey(productId)) {
                productSales[productId]!['quantity'] += item['quantity'] ?? 1;
                productSales[productId]!['revenue'] +=
                    (item['totalPrice'] ?? 0.0);
              } else {
                productSales[productId] = {
                  'name': item['productName'] ?? 'منتج',
                  'quantity': item['quantity'] ?? 1,
                  'revenue': (item['totalPrice'] ?? 0.0).toDouble(),
                };
              }
            }
          }
        }

        if (status == 'cancelled' || status == 'rejected') {
          cancelledCount++;
        }
      }

      // Load customers count
      final customersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .count()
          .get();

      // Load products count
      final productsSnapshot =
          await _firestore.collection('products').count().get();

      // Top bazaars
      final sortedBazaars = bazaarRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      List<Map<String, dynamic>> topBazaars = [];
      for (final entry in sortedBazaars.take(5)) {
        final bazaarDoc =
            await _firestore.collection('bazaars').doc(entry.key).get();
        if (bazaarDoc.exists) {
          topBazaars.add({
            'id': entry.key,
            'name': bazaarDoc.data()?['nameAr'] ?? 'بازار',
            'revenue': entry.value,
          });
        }
      }

      // Top products
      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => (b.value['revenue'] as double)
            .compareTo(a.value['revenue'] as double));

      setState(() {
        _totalRevenue = totalRevenue;
        _totalOrders = orders.length;
        _totalCustomers = customersSnapshot.count ?? 0;
        _totalProducts = productsSnapshot.count ?? 0;
        _deliveredOrders = deliveredCount;
        _cancelledOrders = cancelledCount;
        _cancellationRate =
            orders.isNotEmpty ? (cancelledCount / orders.length * 100) : 0;
        _topBazaars = topBazaars;
        _topProducts = sortedProducts
            .take(5)
            .map((e) => {
                  'id': e.key,
                  ...e.value,
                })
            .toList();
        _recentOrders = orders.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير الشاملة'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.export_1),
            onPressed: _exportReport,
            tooltip: 'تصدير',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),

                  // Summary cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // Two columns layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTopBazaarsCard()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTopProductsCard()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Order stats
                  _buildOrderStatsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('week', 'أسبوع'),
          _buildPeriodButton('month', 'شهر'),
          _buildPeriodButton('quarter', 'ربع سنة'),
          _buildPeriodButton('year', 'سنة'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          icon: Iconsax.money_recive,
          title: 'إجمالي الإيرادات',
          value: '${NumberFormat('#,##0').format(_totalRevenue)} ج.م',
          color: AppColors.success,
        ),
        _buildStatCard(
          icon: Iconsax.shopping_bag,
          title: 'إجمالي الطلبات',
          value: _totalOrders.toString(),
          color: AppColors.primary,
        ),
        _buildStatCard(
          icon: Iconsax.people,
          title: 'العملاء',
          value: _totalCustomers.toString(),
          color: AppColors.info,
        ),
        _buildStatCard(
          icon: Iconsax.box,
          title: 'المنتجات',
          value: _totalProducts.toString(),
          color: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBazaarsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.crown, color: AppColors.secondary),
                const SizedBox(width: 8),
                const Text(
                  'أفضل البازارات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topBazaars.isEmpty)
              Text('لا توجد بيانات', style: TextStyle(color: Colors.grey[600]))
            else
              ...List.generate(_topBazaars.length, (index) {
                final bazaar = _topBazaars[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? [
                                  AppColors.secondary,
                                  AppColors.primary,
                                  AppColors.info
                                ][index]
                                  .withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: index < 3
                                  ? [
                                      AppColors.secondary,
                                      AppColors.primary,
                                      AppColors.info
                                    ][index]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bazaar['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(bazaar['revenue'])} ج.م',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Iconsax.star, color: AppColors.warning),
                const SizedBox(width: 8),
                const Text(
                  'أفضل المنتجات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topProducts.isEmpty)
              Text('لا توجد بيانات', style: TextStyle(color: Colors.grey[600]))
            else
              ...List.generate(_topProducts.length, (index) {
                final product = _topProducts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: index < 3
                              ? [
                                  AppColors.warning,
                                  AppColors.primary,
                                  AppColors.info
                                ][index]
                                  .withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: index < 3
                                  ? [
                                      AppColors.warning,
                                      AppColors.primary,
                                      AppColors.info
                                    ][index]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${product['quantity']} مبيعات',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(product['revenue'])} ج.م',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إحصائيات الطلبات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOrderStatItem(
                    'مكتملة',
                    _deliveredOrders,
                    AppColors.success,
                    Iconsax.tick_circle,
                  ),
                ),
                Expanded(
                  child: _buildOrderStatItem(
                    'ملغاة/مرفوضة',
                    _cancelledOrders,
                    AppColors.error,
                    Iconsax.close_circle,
                  ),
                ),
                Expanded(
                  child: _buildOrderStatItem(
                    'معدل الإلغاء',
                    '${_cancellationRate.toStringAsFixed(1)}%',
                    _cancellationRate > 20
                        ? AppColors.error
                        : AppColors.warning,
                    Iconsax.chart,
                    isPercentage: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatItem(
    String label,
    dynamic value,
    Color color,
    IconData icon, {
    bool isPercentage = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            isPercentage ? value : value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _exportReport() {
    // Generate report content
    final content = StringBuffer();
    content.writeln(
        'تقرير شامل - ${DateFormat('dd/MM/yyyy').format(_startDate)} إلى ${DateFormat('dd/MM/yyyy').format(_endDate)}');
    content.writeln('');
    content.writeln('إجمالي الإيرادات: $_totalRevenue ج.م');
    content.writeln('إجمالي الطلبات: $_totalOrders');
    content.writeln('الطلبات المكتملة: $_deliveredOrders');
    content.writeln('معدل الإلغاء: ${_cancellationRate.toStringAsFixed(1)}%');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Iconsax.export_1, color: Colors.white),
            SizedBox(width: 8),
            Text('تم تجهيز التقرير للتصدير'),
          ],
        ),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'مشاركة',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}
