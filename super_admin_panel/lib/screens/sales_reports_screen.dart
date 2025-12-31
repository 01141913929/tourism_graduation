import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/colors.dart';

// Alias for AdminColors
typedef AdminColors = AppColors;

/// شاشة تقارير المبيعات
class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month, year

  // Statistics
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  List<double> _revenueData = [];
  Map<String, double> _bazaarRevenue = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Calculate date range
      final now = DateTime.now();
      DateTime startDate;
      switch (_selectedPeriod) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      // Get orders in date range
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('createdAt',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get();

      // Get sub-orders for bazaar revenue breakdown
      final subOrdersSnapshot = await _firestore
          .collection('subOrders')
          .where('createdAt',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get();

      // Calculate statistics
      double totalRevenue = 0;
      List<double> dailyRevenue = List.filled(7, 0);
      Map<String, double> bazaarRev = {};

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;

        // Daily breakdown
        final createdAt = DateTime.parse(data['createdAt'] as String);
        final daysAgo = now.difference(createdAt).inDays;
        if (daysAgo < 7) {
          dailyRevenue[6 - daysAgo] += amount;
        }
      }

      for (final doc in subOrdersSnapshot.docs) {
        final data = doc.data();
        final bazaarName = data['bazaarName'] as String? ?? 'غير معروف';
        final amount = (data['subtotal'] as num?)?.toDouble() ?? 0;
        bazaarRev[bazaarName] = (bazaarRev[bazaarName] ?? 0) + amount;
      }

      // Get product and customer counts
      final productsCount =
          await _firestore.collection('products').count().get();
      final customersCount = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .count()
          .get();

      setState(() {
        _totalRevenue = totalRevenue;
        _totalOrders = ordersSnapshot.docs.length;
        _totalProducts = productsCount.count ?? 0;
        _totalCustomers = customersCount.count ?? 0;
        _revenueData = dailyRevenue;
        _bazaarRevenue = bazaarRev;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        title: const Text('تقارير المبيعات'),
        backgroundColor: AdminColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.export_1),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('سيتم ايضافة تصدير التقارير قريباً')),
              );
            },
            tooltip: 'تصدير',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),

                    // Stats Overview
                    _buildStatsOverview(),
                    const SizedBox(height: 24),

                    // Revenue Chart
                    _buildRevenueChart(),
                    const SizedBox(height: 24),

                    // Bazaar Revenue Breakdown
                    _buildBazaarBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodChip('الأسبوع', 'week'),
        const SizedBox(width: 8),
        _buildPeriodChip('الشهر', 'month'),
        const SizedBox(width: 8),
        _buildPeriodChip('السنة', 'year'),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadStatistics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : AdminColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: AdminColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AdminColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'إجمالي الإيرادات',
                '${_formatNumber(_totalRevenue)} ج.م',
                Iconsax.money,
                AdminColors.primary)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('عدد الطلبات', '$_totalOrders', Iconsax.bag_2,
                AdminColors.success)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('عدد المنتجات', '$_totalProducts',
                Iconsax.box, AdminColors.info)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('عدد العملاء', '$_totalCustomers',
                Iconsax.user, AdminColors.warning)),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الإيرادات اليومية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('آخر 7 أيام',
                  style: TextStyle(color: AdminColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _revenueData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AdminColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
                        final dayIndex =
                            (DateTime.now().weekday - 7 + value.toInt()) % 7;
                        return Text(days[dayIndex],
                            style: TextStyle(
                                color: AdminColors.textSecondary,
                                fontSize: 12));
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBazaarBreakdown() {
    final sortedBazaars = _bazaarRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إيرادات البازارات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (sortedBazaars.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('لا توجد بيانات',
                    style: TextStyle(color: AdminColors.textSecondary)),
              ),
            )
          else
            ...sortedBazaars.take(10).map((entry) {
              final percentage =
                  _totalRevenue > 0 ? (entry.value / _totalRevenue) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                        Text('${_formatNumber(entry.value)} ج.م',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AdminColors.divider,
                        valueColor: AlwaysStoppedAnimation(AdminColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
