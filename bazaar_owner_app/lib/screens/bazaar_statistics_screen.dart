import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';

/// شاشة إحصائيات البازار
class BazaarStatisticsScreen extends StatefulWidget {
  const BazaarStatisticsScreen({super.key});

  @override
  State<BazaarStatisticsScreen> createState() => _BazaarStatisticsScreenState();
}

class _BazaarStatisticsScreenState extends State<BazaarStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = 'week';

  // Statistics
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  int _completedOrders = 0;
  int _pendingOrders = 0;
  List<double> _dailyRevenue = List.filled(7, 0);
  Map<String, int> _ordersByStatus = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      if (bazaarId == null) {
        setState(() => _isLoading = false);
        return;
      }

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

      // Get sub-orders for this bazaar
      final subOrdersSnapshot = await _firestore
          .collection('subOrders')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      // Calculate statistics
      double totalRevenue = 0;
      int totalOrders = 0;
      int completedOrders = 0;
      int pendingOrders = 0;
      List<double> dailyRevenue = List.filled(7, 0);
      Map<String, int> ordersByStatus = {};

      for (final doc in subOrdersSnapshot.docs) {
        final data = doc.data();
        final createdAt = DateTime.parse(data['createdAt'] as String);

        // Only count orders in date range
        if (createdAt.isAfter(startDate)) {
          totalOrders++;
          final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0;
          totalRevenue += subtotal;

          final status = data['status'] as String? ?? 'pending';
          ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;

          if (status == 'delivered') {
            completedOrders++;
          } else if (status == 'pending') {
            pendingOrders++;
          }

          // Daily breakdown
          final daysAgo = now.difference(createdAt).inDays;
          if (daysAgo < 7) {
            dailyRevenue[6 - daysAgo] += subtotal;
          }
        }
      }

      // Get product count
      final productsCount = await _firestore
          .collection('products')
          .where('bazaarId', isEqualTo: bazaarId)
          .count()
          .get();

      setState(() {
        _totalRevenue = totalRevenue;
        _totalOrders = totalOrders;
        _totalProducts = productsCount.count ?? 0;
        _completedOrders = completedOrders;
        _pendingOrders = pendingOrders;
        _dailyRevenue = dailyRevenue;
        _ordersByStatus = ordersByStatus;
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('الإحصائيات والتقارير'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // Stats Cards
                    _buildStatsCards(),
                    const SizedBox(height: 20),

                    // Revenue Chart
                    _buildRevenueChart(),
                    const SizedBox(height: 20),

                    // Orders by Status
                    _buildOrdersBreakdown(),
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
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'الإيرادات',
                '${_formatNumber(_totalRevenue)} ج.م',
                Iconsax.money,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'إجمالي الطلبات',
                '$_totalOrders',
                Iconsax.bag_2,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'طلبات مكتملة',
                '$_completedOrders',
                Iconsax.tick_circle,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'طلبات معلقة',
                '$_pendingOrders',
                Iconsax.timer,
                AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'عدد المنتجات',
          '$_totalProducts منتج',
          Iconsax.box,
          AppColors.info,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: fullWidth ? 20 : 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('آخر 7 أيام',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: _dailyRevenue.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.primary,
                        width: 16,
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
                        return Text(
                            days[dayIndex < 0 ? dayIndex + 7 : dayIndex],
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 11));
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

  Widget _buildOrdersBreakdown() {
    final statusLabels = {
      'pending': 'معلق',
      'accepted': 'مقبول',
      'preparing': 'قيد التجهيز',
      'readyForPickup': 'جاهز للاستلام',
      'delivered': 'تم التسليم',
      'rejected': 'مرفوض',
      'cancelled': 'ملغي',
    };

    final statusColors = {
      'pending': Colors.orange,
      'accepted': Colors.blue,
      'preparing': Colors.purple,
      'readyForPickup': AppColors.primary,
      'delivered': AppColors.success,
      'rejected': AppColors.error,
      'cancelled': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الطلبات حسب الحالة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (_ordersByStatus.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('لا توجد طلبات',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...statusLabels.entries.map((entry) {
              final count = _ordersByStatus[entry.key] ?? 0;
              if (count == 0) return const SizedBox.shrink();

              final percentage = _totalOrders > 0 ? count / _totalOrders : 0.0;
              final color = statusColors[entry.key] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    Text('$count',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
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
