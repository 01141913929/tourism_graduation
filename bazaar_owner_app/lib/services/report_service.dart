import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sub_order_model.dart';
import '../models/product_model.dart';

/// Service for generating PDF and Excel reports
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate sales report PDF for a bazaar
  Future<File> generateSalesReportPdf({
    required String bazaarId,
    required String bazaarName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Load orders data
    final ordersSnapshot = await _firestore
        .collection('subOrders')
        .where('bazaarId', isEqualTo: bazaarId)
        .where('status', isEqualTo: 'delivered')
        .get();

    final orders = ordersSnapshot.docs
        .map((doc) => SubOrder.fromJson({...doc.data(), 'id': doc.id}))
        .where((order) =>
            order.createdAt.isAfter(startDate) &&
            order.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    // Calculate totals
    double totalSales = 0;
    int totalOrders = orders.length;
    int totalItems = 0;

    for (var order in orders) {
      totalSales += order.subtotal;
      totalItems += order.items.fold(0, (sum, item) => sum + item.quantity);
    }

    // Create PDF
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Load Arabic font
    final arabicFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'تقرير المبيعات',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  bazaarName,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'من ${dateFormat.format(startDate)} إلى ${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildPdfStatCard('إجمالي المبيعات',
                  '${totalSales.toStringAsFixed(0)} ج.م', arabicFont),
              _buildPdfStatCard('عدد الطلبات', '$totalOrders', arabicFont),
              _buildPdfStatCard(
                  'عدد المنتجات المباعة', '$totalItems', arabicFont),
            ],
          ),

          pw.SizedBox(height: 24),

          // Orders Table
          pw.Text(
            'تفاصيل الطلبات',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          if (orders.isEmpty)
            pw.Text('لا توجد طلبات في هذه الفترة')
          else
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              headers: ['الإجمالي', 'عدد المنتجات', 'التاريخ', 'رقم الطلب'],
              data: orders
                  .map((order) => [
                        '${order.subtotal.toStringAsFixed(0)} ج.م',
                        '${order.items.fold(0, (sum, item) => sum + item.quantity)}',
                        dateFormat.format(order.createdAt),
                        order.id.substring(0, 8),
                      ])
                  .toList(),
            ),
        ],
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildPdfStatCard(String title, String value, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Generate products report Excel
  Future<File> generateProductsReportExcel({
    required String bazaarId,
    required String bazaarName,
  }) async {
    // Load products data
    final productsSnapshot = await _firestore
        .collection('products')
        .where('bazaarId', isEqualTo: bazaarId)
        .get();

    final products = productsSnapshot.docs
        .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    // Create Excel
    final excel = Excel.createExcel();
    final sheet = excel['المنتجات'];

    // Header row
    sheet.appendRow([
      TextCellValue('اسم المنتج'),
      TextCellValue('السعر'),
      TextCellValue('السعر القديم'),
      TextCellValue('التصنيف'),
      TextCellValue('متوفر'),
      TextCellValue('التقييم'),
      TextCellValue('عدد التقييمات'),
    ]);

    // Data rows
    for (var product in products) {
      sheet.appendRow([
        TextCellValue(product.nameAr),
        DoubleCellValue(product.price),
        product.oldPrice != null
            ? DoubleCellValue(product.oldPrice!)
            : TextCellValue('-'),
        TextCellValue(product.category),
        TextCellValue(product.isActive ? 'نعم' : 'لا'),
        DoubleCellValue(product.rating),
        IntCellValue(product.reviewCount),
      ]);
    }

    // Style header
    for (var i = 0; i < 7; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.amber100,
      );
    }

    // Save Excel
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/products_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  /// Generate orders report Excel
  Future<File> generateOrdersReportExcel({
    required String bazaarId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Load orders data
    final ordersSnapshot = await _firestore
        .collection('subOrders')
        .where('bazaarId', isEqualTo: bazaarId)
        .get();

    final orders = ordersSnapshot.docs
        .map((doc) => SubOrder.fromJson({...doc.data(), 'id': doc.id}))
        .where((order) =>
            order.createdAt.isAfter(startDate) &&
            order.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Create Excel
    final excel = Excel.createExcel();
    final sheet = excel['الطلبات'];

    // Header row
    sheet.appendRow([
      TextCellValue('رقم الطلب'),
      TextCellValue('اسم العميل'),
      TextCellValue('التاريخ'),
      TextCellValue('الحالة'),
      TextCellValue('عدد المنتجات'),
      TextCellValue('الإجمالي'),
    ]);

    // Data rows
    for (var order in orders) {
      sheet.appendRow([
        TextCellValue(order.id.substring(0, 8)),
        TextCellValue(order.customerName),
        TextCellValue(dateFormat.format(order.createdAt)),
        TextCellValue(_getStatusArabic(order.status)),
        IntCellValue(order.items.fold(0, (sum, item) => sum + item.quantity)),
        DoubleCellValue(order.subtotal),
      ]);
    }

    // Style header
    for (var i = 0; i < 6; i++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.amber100,
      );
    }

    // Save Excel
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/orders_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    return file;
  }

  String _getStatusArabic(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return 'قيد الانتظار';
      case SubOrderStatus.accepted:
        return 'مقبول';
      case SubOrderStatus.preparing:
        return 'جاري التحضير';
      case SubOrderStatus.readyForPickup:
        return 'جاهز للاستلام';
      case SubOrderStatus.shipping:
        return 'قيد الشحن';
      case SubOrderStatus.delivered:
        return 'تم التوصيل';
      case SubOrderStatus.cancelled:
        return 'ملغي';
      case SubOrderStatus.rejected:
        return 'مرفوض';
    }
  }
}
