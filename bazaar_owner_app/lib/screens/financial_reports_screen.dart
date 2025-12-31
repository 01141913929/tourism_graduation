import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../models/sub_order_model.dart';

/// شاشة التقارير المالية التفصيلية
class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = 'week'; // day, week, month, year
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Report data
  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _deliveredOrders = 0;
  int _cancelledOrders = 0;
  double _averageOrderValue = 0;
  Map<String, double> _revenueByDay = {};
  Map<String, int> _ordersByStatus = {};
  List<Map<String, dynamic>> _topProducts = [];

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
        case 'day':
          _startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
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
    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;

    if (bazaarId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('subOrders')
          .where('bazaarId', isEqualTo: bazaarId)
          .where('createdAt',
              isGreaterThanOrEqualTo: _startDate.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: _endDate.toIso8601String())
          .get();

      final orders = snapshot.docs.map((doc) {
        return SubOrder.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      // Calculate metrics
      double totalRevenue = 0;
      int deliveredCount = 0;
      int cancelledCount = 0;
      Map<String, double> revenueByDay = {};
      Map<String, int> ordersByStatus = {};
      Map<String, Map<String, dynamic>> productSales = {};

      for (final order in orders) {
        // Status counts
        final statusKey = order.status.name;
        ordersByStatus[statusKey] = (ordersByStatus[statusKey] ?? 0) + 1;

        if (order.status == SubOrderStatus.delivered) {
          deliveredCount++;
          totalRevenue += order.subtotal;

          // Revenue by day
          final dayKey = DateFormat('MM/dd').format(order.createdAt);
          revenueByDay[dayKey] = (revenueByDay[dayKey] ?? 0) + order.subtotal;

          // Top products
          for (final item in order.items) {
            if (productSales.containsKey(item.productId)) {
              productSales[item.productId]!['quantity'] += item.quantity;
              productSales[item.productId]!['revenue'] += item.totalPrice;
            } else {
              productSales[item.productId] = {
                'name': item.productName,
                'imageUrl': item.imageUrl,
                'quantity': item.quantity,
                'revenue': item.totalPrice,
              };
            }
          }
        }

        if (order.status == SubOrderStatus.cancelled ||
            order.status == SubOrderStatus.rejected) {
          cancelledCount++;
        }
      }

      // Sort top products
      final sortedProducts = productSales.entries.toList()
        ..sort((a, b) => (b.value['revenue'] as double)
            .compareTo(a.value['revenue'] as double));

      setState(() {
        _totalRevenue = totalRevenue;
        _totalOrders = orders.length;
        _deliveredOrders = deliveredCount;
        _cancelledOrders = cancelledCount;
        _averageOrderValue =
            deliveredCount > 0 ? totalRevenue / deliveredCount : 0;
        _revenueByDay = revenueByDay;
        _ordersByStatus = ordersByStatus;
        _topProducts = sortedProducts.take(5).map((e) => e.value).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading report: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    // Generate CSV content
    final csvContent = StringBuffer();
    csvContent.writeln(
        'تقرير المبيعات - ${DateFormat('dd/MM/yyyy').format(_startDate)} إلى ${DateFormat('dd/MM/yyyy').format(_endDate)}');
    csvContent.writeln('');
    csvContent.writeln('إجمالي الإيرادات,$_totalRevenue ج.م');
    csvContent.writeln('إجمالي الطلبات,$_totalOrders');
    csvContent.writeln('الطلبات المكتملة,$_deliveredOrders');
    csvContent.writeln('الطلبات الملغاة,$_cancelledOrders');
    csvContent.writeln(
        'متوسط قيمة الطلب,${_averageOrderValue.toStringAsFixed(0)} ج.م');
    csvContent.writeln('');
    csvContent.writeln('أفضل المنتجات');
    csvContent.writeln('المنتج,الكمية,الإيرادات');
    for (final product in _topProducts) {
      csvContent.writeln(
          '${product['name']},${product['quantity']},${product['revenue']} ج.م');
    }

    // Show export dialog (in real app, would save to file)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Iconsax.document_download, color: Colors.white),
            SizedBox(width: 8),
            Text('تم تجهيز التقرير للتصدير'),
          ],
        ),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'مشاركة',
          textColor: Colors.white,
          onPressed: () {
            // Share the report
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('التقارير المالية'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.document_download),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),

                  // Summary cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // Revenue chart
                  _buildRevenueChart(),
                  const SizedBox(height: 24),

                  // Order status breakdown
                  _buildOrderStatusChart(),
                  const SizedBox(height: 24),

                  // Top products
                  _buildTopProducts(),
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
          _buildPeriodButton('day', 'اليوم'),
          _buildPeriodButton('week', 'أسبوع'),
          _buildPeriodButton('month', 'شهر'),
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
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard(
          icon: Iconsax.money_recive,
          title: 'الإيرادات',
          value: '${_totalRevenue.toStringAsFixed(0)} ج.م',
          color: AppColors.success,
        ),
        _buildSummaryCard(
          icon: Iconsax.shopping_bag,
          title: 'الطلبات',
          value: '$_totalOrders',
          color: AppColors.primary,
        ),
        _buildSummaryCard(
          icon: Iconsax.tick_circle,
          title: 'مكتملة',
          value: '$_deliveredOrders',
          color: AppColors.info,
        ),
        _buildSummaryCard(
          icon: Iconsax.chart,
          title: 'متوسط الطلب',
          value: '${_averageOrderValue.toStringAsFixed(0)} ج.م',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(title,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_revenueByDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Iconsax.chart, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('لا توجد بيانات', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    final spots = _revenueByDay.entries.toList().asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الإيرادات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حالات الطلبات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ordersByStatus.entries.map((entry) {
              final color = _getStatusColor(entry.key);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusName(entry.key),
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${entry.value})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (_topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أفضل المنتجات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...List.generate(_topProducts.length, (index) {
            final product = _topProducts[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: index < 3 ? AppColors.primary : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: index < 3 ? Colors.white : Colors.grey[600],
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${product['quantity']} مبيعات',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(product['revenue'] as double).toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return AppColors.info;
      case 'preparing':
        return Colors.purple;
      case 'readyForPickup':
        return AppColors.primary;
      case 'delivered':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'accepted':
        return 'مقبول';
      case 'preparing':
        return 'جاري التحضير';
      case 'readyForPickup':
        return 'جاهز للاستلام';
      case 'delivered':
        return 'تم التسليم';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
