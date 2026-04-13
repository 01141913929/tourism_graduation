import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/bazaar_model.dart';

/// خدمة مشاركة المنتجات والبازارات مع Deep Links
class ShareService {
  // Base URL for the app deep links
  static const String _baseUrl = 'https://egyptiantourism.app';

  /// Generate a deep link for a product
  static String generateProductLink(Product product) {
    return '$_baseUrl/product/${product.id}';
  }

  /// Generate a deep link for a bazaar
  static String generateBazaarLink(Bazaar bazaar) {
    return '$_baseUrl/bazaar/${bazaar.id}';
  }

  /// Generate share text for product
  static String generateProductShareText(Product product) {
    final link = generateProductLink(product);
    return '''
🛍️ ${product.nameAr}

💰 السعر: ${product.price.toStringAsFixed(0)} ج.م
${product.hasDiscount ? '🔥 خصم ${product.discountPercentage.toInt()}%!' : ''}
📍 البازار: ${product.bazaarName}
⭐ التقييم: ${product.rating.toStringAsFixed(1)} (${product.reviewCount} تقييم)

${product.descriptionAr.length > 100 ? '${product.descriptionAr.substring(0, 100)}...' : product.descriptionAr}

👇 اطلع على المنتج:
$link
'''
        .trim();
  }

  /// Generate share text for bazaar
  static String generateBazaarShareText(Bazaar bazaar) {
    final link = generateBazaarLink(bazaar);
    return '''
🏪 ${bazaar.nameAr}

📍 الموقع: ${bazaar.address}، ${bazaar.governorate}
⭐ التقييم: ${bazaar.rating.toStringAsFixed(1)} (${bazaar.reviewCount} تقييم)
${bazaar.isVerified ? '✅ موثق' : ''}

${bazaar.descriptionAr.length > 100 ? '${bazaar.descriptionAr.substring(0, 100)}...' : bazaar.descriptionAr}

👇 زر البازار:
$link
'''
        .trim();
  }

  /// Copy product link to clipboard
  static Future<void> copyProductLink(Product product) async {
    final link = generateProductLink(product);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Copy bazaar link to clipboard
  static Future<void> copyBazaarLink(Bazaar bazaar) async {
    final link = generateBazaarLink(bazaar);
    await Clipboard.setData(ClipboardData(text: link));
  }

  /// Copy product share text to clipboard
  static Future<void> copyProductShareText(Product product) async {
    final text = generateProductShareText(product);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copy bazaar share text to clipboard
  static Future<void> copyBazaarShareText(Bazaar bazaar) async {
    final text = generateBazaarShareText(bazaar);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share app with friends
  static Future<void> shareApp() async {
    const appShareText = '''
🛍️ تطبيق سوق مصر - متجر التحف المصرية

اكتشف روائع الحضارة الفرعونية واقتني قطعاً فريدة من تاريخ مصر العريق!

✨ تحف أصيلة وهدايا تذكارية
🏪 بازارات موثقة في جميع المحافظات
💰 أسعار تنافسية مع خصومات حصرية

حمّل التطبيق الآن:
https://egyptiantourism.app/download
''';
    await Clipboard.setData(const ClipboardData(text: appShareText));
  }
}
