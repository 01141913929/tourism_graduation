/// 🎯 AI Recommendation Service — خدمة الاقتراحات الذكية
/// تتصل بالـ AI Backend + Fallback محلي
/// تدعم Caching (5 دقائق)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../repositories/product_repository.dart';

/// نموذج قسم اقتراحات واحد
class RecommendationSection {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String type; // 'ai', 'content', 'popularity'
  final List<Product> products;

  const RecommendationSection({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.type,
    required this.products,
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String getSubtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;

  factory RecommendationSection.fromJson(Map<String, dynamic> json) {
    return RecommendationSection(
      id: json['id'] as String? ?? '',
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      subtitleAr: json['subtitle_ar'] as String? ?? '',
      subtitleEn: json['subtitle_en'] as String? ?? '',
      type: json['type'] as String? ?? 'content',
      products: (json['products'] as List<dynamic>?)
              ?.map((p) => Product.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// نتيجة الاقتراحات
class RecommendationResult {
  final List<RecommendationSection> sections;
  final int totalProducts;
  final DateTime fetchedAt;

  const RecommendationResult({
    required this.sections,
    required this.totalProducts,
    required this.fetchedAt,
  });

  /// هل الـ Cache لسه صالح (5 دقائق)
  bool get isStale =>
      DateTime.now().difference(fetchedAt).inMinutes > 5;

  /// كل المنتجات المقترحة (flat list)
  List<Product> get allProducts =>
      sections.expand((s) => s.products).toList();
}

/// 🎯 خدمة الاقتراحات الذكية
class RecommendationService {
  static const String _fallbackUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev';
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _quickTimeout = Duration(seconds: 10);

  final ProductRepository _productRepo;
  final http.Client _client;

  // Cache
  RecommendationResult? _cachedResult;
  String? _cachedUserId;

  RecommendationService({
    ProductRepository? productRepo,
    http.Client? client,
  })  : _productRepo = productRepo ?? ProductRepository(),
        _client = client ?? http.Client();

  /// 🌐 الحصول على الرابط المحفوظ
  Future<String> _getBaseUrl() async {
    return _fallbackUrl;
  }

  /// ============================================================
  /// 🎯 الاقتراحات الكاملة (LLM + Content + Popularity)
  /// ============================================================
  Future<RecommendationResult> getRecommendations({
    required String userId,
    int limit = 6,
    bool forceRefresh = false,
  }) async {
    // === التحقق من الـ Cache ===
    if (!forceRefresh &&
        _cachedResult != null &&
        _cachedUserId == userId &&
        !_cachedResult!.isStale) {
      debugPrint('💎 توصيات من الـ Cache');
      return _cachedResult!;
    }

    // === محاولة 1: الاقتراحات الكاملة من AI Backend ===
    try {
      final baseUrl = await _getBaseUrl();
      final url = Uri.parse('$baseUrl/api/recommendations/$userId?limit=$limit');

      final response = await _client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sections = (data['sections'] as List<dynamic>?)
                ?.map((s) =>
                    RecommendationSection.fromJson(s as Map<String, dynamic>))
                .where((s) => s.products.isNotEmpty)
                .toList() ??
            [];

        final result = RecommendationResult(
          sections: sections,
          totalProducts: data['total_recommendations'] as int? ?? 0,
          fetchedAt: DateTime.now(),
        );

        _cachedResult = result;
        _cachedUserId = userId;

        debugPrint('✅ ${result.totalProducts} توصيات ذكية (${sections.length} أقسام)');
        return result;
      }
    } catch (e) {
      debugPrint('⚠️ AI recommendations failed: $e');
    }

    // === محاولة 2: اقتراحات سريعة (بدون LLM) ===
    try {
      final baseUrl = await _getBaseUrl();
      final url =
          Uri.parse('$baseUrl/api/recommendations/$userId/quick?limit=$limit');

      final response = await _client
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_quickTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final products = (data['products'] as List<dynamic>?)
                ?.map((p) => Product.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];

        if (products.isNotEmpty) {
          final result = RecommendationResult(
            sections: [
              RecommendationSection(
                id: 'quick',
                titleAr: 'مقترحة لك ✨',
                titleEn: 'Suggested for You ✨',
                subtitleAr: 'منتجات تناسب ذوقك',
                subtitleEn: 'Products that match your taste',
                type: 'content',
                products: products,
              ),
            ],
            totalProducts: products.length,
            fetchedAt: DateTime.now(),
          );

          _cachedResult = result;
          _cachedUserId = userId;
          return result;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Quick recommendations failed: $e');
    }

    // === Fallback محلي: أعلى تقييم + أحدث ===
    return _localFallback();
  }

  /// ============================================================
  /// 🏠 Fallback محلي (لو السيرفر مش شغال)
  /// ============================================================
  Future<RecommendationResult> _localFallback() async {
    debugPrint('📱 Fallback محلي للاقتراحات');

    try {
      final allProducts = await _productRepo.getProducts();

      if (allProducts.isEmpty) {
        return RecommendationResult(
          sections: [],
          totalProducts: 0,
          fetchedAt: DateTime.now(),
        );
      }

      // أعلى تقييم
      final topRated = List<Product>.from(allProducts)
        ..sort((a, b) => b.rating.compareTo(a.rating));

      // أحدث المنتجات
      final newest = allProducts.where((p) => p.isNew).take(6).toList();

      // عليها خصم
      final discounted =
          allProducts.where((p) => p.hasDiscount).take(6).toList();

      final sections = <RecommendationSection>[];

      if (topRated.isNotEmpty) {
        sections.add(RecommendationSection(
          id: 'top_rated',
          titleAr: 'الأعلى تقييماً ⭐',
          titleEn: 'Top Rated ⭐',
          subtitleAr: 'منتجات يحبها الجميع',
          subtitleEn: 'Products everyone loves',
          type: 'popularity',
          products: topRated.take(6).toList(),
        ));
      }

      if (newest.isNotEmpty) {
        sections.add(RecommendationSection(
          id: 'new_arrivals',
          titleAr: 'وصل حديثاً 🆕',
          titleEn: 'New Arrivals 🆕',
          subtitleAr: 'أحدث ما لدينا',
          subtitleEn: 'Our latest additions',
          type: 'content',
          products: newest,
        ));
      }

      if (discounted.isNotEmpty) {
        sections.add(RecommendationSection(
          id: 'deals',
          titleAr: 'عروض مميزة 🏷️',
          titleEn: 'Special Deals 🏷️',
          subtitleAr: 'خصومات حصرية',
          subtitleEn: 'Exclusive discounts',
          type: 'content',
          products: discounted,
        ));
      }

      final result = RecommendationResult(
        sections: sections,
        totalProducts:
            sections.fold(0, (sum, s) => sum + s.products.length),
        fetchedAt: DateTime.now(),
      );

      _cachedResult = result;
      return result;
    } catch (e) {
      debugPrint('❌ Local fallback failed: $e');
      return RecommendationResult(
        sections: [],
        totalProducts: 0,
        fetchedAt: DateTime.now(),
      );
    }
  }

  /// مسح الـ Cache
  void clearCache() {
    _cachedResult = null;
    _cachedUserId = null;
  }

  void dispose() {
    _client.close();
  }
}
