import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🤖 Owner AI Service — التواصل مع API الـ AI
class OwnerAIService {
  static String _baseUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev/api/owner/ai';

  static void setBaseUrl(String url) {
    _baseUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev/api/owner/ai';
  }

  static String get baseUrl => _baseUrl;

  // ============================================================
  // 1. Generate Product Description
  // ============================================================

  static Future<Map<String, dynamic>> generateDescription({
    required String productName,
    String? category,
    String? material,
    String? imageUrl,
    String? bazaarId,
    String? extraDetails,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate-description'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_name': productName,
              'category': category,
              'material': material,
              'image_url': imageUrl,
              'bazaar_id': bazaarId,
              'extra_details': extraDetails,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Generate Description Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 2. Suggest Price
  // ============================================================

  static Future<Map<String, dynamic>> suggestPrice({
    required String productName,
    required String category,
    String? material,
    String? bazaarId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/suggest-price'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'product_name': productName,
              'category': category,
              'material': material,
              'bazaar_id': bazaarId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Suggest Price Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 3. Suggest Replies
  // ============================================================

  static Future<Map<String, dynamic>> suggestReplies({
    required String customerMessage,
    String? customerName,
    String? context,
    String? bazaarId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/suggest-replies'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customer_message': customerMessage,
              'customer_name': customerName,
              'context': context,
              'bazaar_id': bazaarId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Suggest Replies Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 4. Daily Digest
  // ============================================================

  static Future<Map<String, dynamic>> getDailyDigest(String bazaarId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/daily-digest/$bazaarId'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Daily Digest Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. Analytics
  // ============================================================

  static Future<Map<String, dynamic>> getAnalytics(
    String bazaarId, {
    String period = 'week',
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/analytics/$bazaarId?period=$period'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Analytics Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 6. Generate Content
  // ============================================================

  static Future<Map<String, dynamic>> generateContent({
    required String contentType,
    String? productName,
    String? offerDetails,
    String? bazaarName,
    String targetAudience = 'tourists',
    String language = 'ar',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate-content'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'content_type': contentType,
              'product_name': productName,
              'offer_details': offerDetails,
              'bazaar_name': bazaarName,
              'target_audience': targetAudience,
              'language': language,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Generate Content Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 7. Product Suggestions
  // ============================================================

  static Future<Map<String, dynamic>> getProductSuggestions(
      String bazaarId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/product-suggestions/$bazaarId'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Product Suggestions Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 8. Translate
  // ============================================================

  static Future<String> translate({
    required String text,
    String sourceLang = 'ar',
    String targetLang = 'en',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'source_lang': sourceLang,
              'target_lang': targetLang,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['translated_text'] ?? '';
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Translate Error: $e');
      rethrow;
    }
  }
}
