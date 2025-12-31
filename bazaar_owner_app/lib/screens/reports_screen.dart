import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../services/report_service.dart';
import 'package:intl/intl.dart';

/// شاشة التقارير
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _loadingType;

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport(String type) async {
    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;
    // Note: UserModel only has bazaarId, not bazaarName.
    // To get the actual bazaar name, fetch it from Firestore using bazaarId.
    const bazaarName = 'البازار';

    if (bazaarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم العثور على معرف البازار'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingType = type;
    });

    try {
      dynamic file;
      String fileName;

      switch (type) {
        case 'sales_pdf':
          file = await _reportService.generateSalesReportPdf(
            bazaarId: bazaarId,
            bazaarName: bazaarName,
            startDate: _startDate,
            endDate: _endDate,
          );
          fileName = 'تقرير_المبيعات.pdf';
          break;
        case 'products_excel':
          file = await _reportService.generateProductsReportExcel(
            bazaarId: bazaarId,
            bazaarName: bazaarName,
          );
          fileName = 'تقرير_المنتجات.xlsx';
          break;
        case 'orders_excel':
          file = await _reportService.generateOrdersReportExcel(
            bazaarId: bazaarId,
            startDate: _startDate,
            endDate: _endDate,
          );
          fileName = 'تقرير_الطلبات.xlsx';
          break;
        default:
          return;
      }

      if (!mounted) return;

      // Show options dialog
      _showReportOptionsDialog(file.path, fileName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إنشاء التقرير: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingType = null;
        });
      }
    }
  }

  void _showReportOptionsDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'تم إنشاء التقرير',
                style: TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.right,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.success),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Share.shareXFiles([XFile(filePath)], text: fileName);
                    },
                    icon: const Icon(Iconsax.share),
                    label: const Text('مشاركة'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      OpenFile.open(filePath);
                    },
                    icon: const Icon(Iconsax.document_text),
                    label: const Text('فتح'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير'),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'الفترة الزمنية',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.calendar, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit,
                            size: 16, color: AppColors.textSecondary),
                        const Spacer(),
                        Text(
                          '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Report cards
          const Text(
            'اختر نوع التقرير',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16),

          _buildReportCard(
            icon: Iconsax.chart_21,
            title: 'تقرير المبيعات',
            subtitle: 'تقرير PDF يحتوي على إحصائيات المبيعات',
            color: AppColors.success,
            type: 'sales_pdf',
            format: 'PDF',
          ),

          const SizedBox(height: 12),

          _buildReportCard(
            icon: Iconsax.box,
            title: 'تقرير المنتجات',
            subtitle: 'جدول Excel بجميع المنتجات',
            color: AppColors.info,
            type: 'products_excel',
            format: 'Excel',
          ),

          const SizedBox(height: 12),

          _buildReportCard(
            icon: Iconsax.receipt_item,
            title: 'تقرير الطلبات',
            subtitle: 'جدول Excel بجميع الطلبات في الفترة المحددة',
            color: AppColors.warning,
            type: 'orders_excel',
            format: 'Excel',
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String type,
    required String format,
  }) {
    final isLoading = _isLoading && _loadingType == type;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _generateReport(type),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Generate Button
                if (isLoading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Iconsax.document_download,
                      color: AppColors.white,
                    ),
                  ),

                const SizedBox(width: 12),

                // Format Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    format,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
