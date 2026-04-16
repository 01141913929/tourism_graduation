import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../services/admin_ai_service.dart';

/// 🧠 AI Business Intelligence Dashboard — Premium Admin Analytics
class AIInsightsDashboardScreen extends StatefulWidget {
  const AIInsightsDashboardScreen({super.key});

  @override
  State<AIInsightsDashboardScreen> createState() =>
      _AIInsightsDashboardScreenState();
}

class _AIInsightsDashboardScreenState extends State<AIInsightsDashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _report;
  Map<String, dynamic>? _insights;
  bool _isLoading = true;
  String _selectedPeriod = 'month';
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminAIService.getBusinessReport(period: _selectedPeriod),
        AdminAIService.getPlatformInsights(),
      ]);

      setState(() {
        _report = results[0];
        _insights = results[1];
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading AI dashboard: $e');
      setState(() => _isLoading = false);
      _fadeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Iconsax.cpu, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('AI Business Intelligence'),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          // Period selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildPeriodChip('week', 'أسبوع'),
                _buildPeriodChip('month', 'شهر'),
                _buildPeriodChip('quarter', 'ربع سنة'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    '🤖 AI يحلل بيانات المنصة...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: CurvedAnimation(
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Executive Summary ===
                    if (_report?['executive_summary'] != null)
                      _buildExecutiveSummary(),
                    const SizedBox(height: 24),

                    // === Key Metrics ===
                    _buildKeyMetrics(),
                    const SizedBox(height: 24),

                    // === Platform Health ===
                    _buildHealthScore(),
                    const SizedBox(height: 24),

                    // === Two Column: Revenue Chart + Category Pie ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRevenueChart()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildCategoryPie()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // === AI Insights + Alerts ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildInsightsCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 1, child: _buildAlertsCard()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // === Bazaar Rankings ===
                    _buildBazaarRankings(),
                    const SizedBox(height: 24),

                    // === Recommendations ===
                    if ((_report?['recommendations'] as List?)?.isNotEmpty ??
                        false)
                      _buildRecommendations(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String key, String label) {
    final selected = _selectedPeriod == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = key);
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Executive Summary
  // ============================================================
  Widget _buildExecutiveSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Iconsax.cpu, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص تنفيذي — $_selectedPeriod',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _report?['executive_summary'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Key Metrics (4 cards)
  // ============================================================
  Widget _buildKeyMetrics() {
    final m = _report?['key_metrics'] ?? {};

    final metrics = [
      {
        'icon': Iconsax.money_recive,
        'title': 'إجمالي الإيرادات',
        'value': '${NumberFormat('#,##0').format(m['total_revenue'] ?? 0)} ج.م',
        'gradient': AppGradients.revenue,
        'color': AppColors.success,
      },
      {
        'icon': Iconsax.shopping_bag,
        'title': 'إجمالي الطلبات',
        'value': '${m['total_orders'] ?? 0}',
        'gradient': AppGradients.orders,
        'color': AppColors.info,
      },
      {
        'icon': Iconsax.people,
        'title': 'العملاء',
        'value': '${m['total_customers'] ?? 0}',
        'gradient': AppGradients.users,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Iconsax.shop,
        'title': 'البازارات النشطة',
        'value': '${m['active_bazaars'] ?? 0} / ${m['total_bazaars'] ?? 0}',
        'gradient': AppGradients.products,
        'color': AppColors.warning,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final metric = metrics[i];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (i * 150)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: metric['gradient'] as LinearGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (metric['color'] as Color).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  metric['icon'] as IconData,
                  color: Colors.white.withOpacity(0.9),
                  size: 26,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric['value'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      metric['title'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
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

  // ============================================================
  // Platform Health Score
  // ============================================================
  Widget _buildHealthScore() {
    final score = _insights?['health_score'] ?? 0;
    final Color scoreColor = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Score Ring
          SizedBox(
            width: 80,
            height: 80,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: score / 100),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scoreColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                    ),
                    Text(
                      '${(value * 100).toInt()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'صحة المنصة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? '🟢 المنصة في حالة ممتازة'
                      : score >= 50
                          ? '🟡 تحتاج بعض التحسينات'
                          : '🔴 تحتاج اهتمام فوري',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Quick stats — resilient to both flattened and nested response formats
          _buildQuickStat(
            'بازارات نشطة',
            '${_insights?['active_bazaars'] ?? _insights?['quick_stats']?['active_bazaars'] ?? 0}/${_insights?['total_bazaars'] ?? _insights?['quick_stats']?['total_bazaars'] ?? 0}',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ============================================================
  // Revenue Line Chart
  // ============================================================
  Widget _buildRevenueChart() {
    final data = (_report?['charts_data']?['revenue_line'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_1, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'اتجاه الإيرادات',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: data.isEmpty
                ? const Center(child: Text('لا توجد بيانات'))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (v, _) => Text(
                              v >= 1000
                                  ? '${(v / 1000).toStringAsFixed(0)}K'
                                  : v.toStringAsFixed(0),
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: (data.length / 6).ceilToDouble(),
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= data.length)
                                return const SizedBox();
                              final d = data[idx]['date'] ?? '';
                              return Text(
                                d.length >= 10 ? d.substring(5, 10) : '',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 9),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(data.length, (i) => FlSpot(
                            i.toDouble(),
                            (data[i]['revenue'] ?? 0).toDouble(),
                          )),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 800),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Category Pie Chart
  // ============================================================
  Widget _buildCategoryPie() {
    final data =
        (_report?['charts_data']?['categories_pie'] as List?) ?? [];

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
      const Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'توزيع الفئات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: data.isEmpty
                ? const Center(child: Text('لا توجد بيانات'))
                : PieChart(
                    PieChartData(
                      sections: List.generate(data.length.clamp(0, 6), (i) {
                        final item = data[i];
                        final total = data.fold<double>(
                            0.0, (s, d) => s + (d['revenue'] ?? 0).toDouble());
                        final pct = total > 0
                            ? (item['revenue'] / total * 100)
                            : 0.0;

                        return PieChartSectionData(
                          value: (item['revenue'] ?? 0).toDouble(),
                          color: colors[i % colors.length],
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          radius: 45,
                        );
                      }),
                      sectionsSpace: 3,
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 800),
                  ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: List.generate(data.length.clamp(0, 6), (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data[i]['category'] ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Insights Card
  // ============================================================
  Widget _buildInsightsCard() {
    final insights = (_insights?['insights'] as List?) ??
        (_report?['insights'] as List?) ??
        [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.cpu,
                    color: Color(0xFF667eea), size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Insights',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.take(5).map((insight) {
            final type = insight['type'] ?? 'tip';
            Color borderColor;
            Color bgColor;
            switch (type) {
              case 'success':
                borderColor = AppColors.success;
                bgColor = AppColors.successLight;
                break;
              case 'warning':
                borderColor = AppColors.warning;
                bgColor = AppColors.warningLight;
                break;
              case 'danger':
                borderColor = AppColors.error;
                bgColor = AppColors.errorLight;
                break;
              default:
                borderColor = AppColors.info;
                bgColor = AppColors.infoLight;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  right: BorderSide(color: borderColor, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight['icon'] ?? '💡', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight['text'] ?? '',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (insights.isEmpty)
            const Text('لا توجد insights حالياً',
                style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ============================================================
  // Alerts Card
  // ============================================================
  Widget _buildAlertsCard() {
    final alerts = (_insights?['alerts'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.danger,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'التنبيهات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...alerts.take(5).map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  right: BorderSide(color: AppColors.error, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert['icon'] ?? '⚠️',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert['text'] ?? '',
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (alerts.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(Iconsax.tick_circle, color: AppColors.success, size: 32),
                  SizedBox(height: 8),
                  Text('لا توجد تنبيهات 🎉',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // Bazaar Rankings
  // ============================================================
  Widget _buildBazaarRankings() {
    final rankings = (_report?['bazaar_rankings'] as List?) ?? [];
    if (rankings.isEmpty) return const SizedBox();

    final maxRevenue = rankings
        .map((b) => (b['revenue'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.crown, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ترتيب البازارات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(rankings.length.clamp(0, 5), (i) {
            final b = rankings[i];
            final revenue = (b['revenue'] ?? 0).toDouble();
            final ratio = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
            final tier = b['tier'] ?? 'bronze';
            final tierEmoji =
                tier == 'gold' ? '🥇' : tier == 'silver' ? '🥈' : '🥉';
            final tierColor = tier == 'gold'
                ? AppColors.secondary
                : tier == 'silver'
                    ? AppColors.info
                    : AppColors.textSecondary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(tierEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              b['name'] ?? 'بازار',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,##0').format(revenue)} ج.م',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tierColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: ratio),
                          duration: Duration(milliseconds: 800 + (i * 200)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: tierColor.withOpacity(0.1),
                                valueColor:
                                    AlwaysStoppedAnimation(tierColor),
                                minHeight: 6,
                              ),
                            );
                          },
                        ),
                      ],
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

  // ============================================================
  // Recommendations
  // ============================================================
  Widget _buildRecommendations() {
    final recs = (_report?['recommendations'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp_charge, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'التوصيات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recs.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec.toString(),
                      style: const TextStyle(fontSize: 13, height: 1.5),
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
}
