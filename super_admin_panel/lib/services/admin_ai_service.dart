import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🤖 Admin AI Service — التواصل مع API الأدمن
class AdminAIService {
  static String _baseUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev/api/admin/ai';

  static void setBaseUrl(String url) {
    _baseUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev/api/admin/ai';
  }

  // ============================================================
  // 1. Admin Chat
  // ============================================================

  static Future<Map<String, dynamic>> chat({
    required String message,
    String sessionId = 'admin_default',
    String? context,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'session_id': sessionId,
              'context': context,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Admin AI Chat Error: $e');
      rethrow;
    }
  }

  /// SSE Streaming chat
  static Stream<Map<String, dynamic>> chatStream({
    required String message,
    String sessionId = 'admin_default',
    String? context,
  }) async* {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/stream'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'message': message,
        'session_id': sessionId,
        'context': context,
      });

      final client = http.Client();
      final response = await client.send(request);

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              yield data;
            } catch (_) {}
          }
        }
      }

      client.close();
    } catch (e) {
      debugPrint('❌ Admin AI Chat Stream Error: $e');
      yield {'type': 'error', 'content': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================================
  // 2. Moderate Product
  // ============================================================

  static Future<Map<String, dynamic>> moderateProduct(
      String productId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/moderate-product/$productId'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Moderation Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 3. Analyze Application
  // ============================================================

  static Future<Map<String, dynamic>> analyzeApplication(
      String applicationId) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/analyze-application/$applicationId'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Application Analysis Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 4. Business Report
  // ============================================================

  static Future<Map<String, dynamic>> getBusinessReport({
    String period = 'month',
    String? focus,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/business-report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'period': period,
              'focus': focus,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Business Report Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. Platform Insights
  static Future<Map<String, dynamic>> getPlatformInsights() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/platform-insights?t=${DateTime.now().millisecondsSinceEpoch}'),
            headers: {
              'ngrok-skip-browser-warning': 'true',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Platform Insights Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 6. Generate Message
  // ============================================================

  static Future<Map<String, dynamic>> generateMessage({
    required String messageType,
    required String bazaarName,
    String? context,
    String? customNotes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate-message'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message_type': messageType,
              'bazaar_name': bazaarName,
              'context': context,
              'custom_notes': customNotes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Generate Message Error: $e');
      rethrow;
    }
  }

  // ============================================================
  // 7. Promotion Suggestions
  // ============================================================

  static Future<Map<String, dynamic>> getPromotionSuggestions() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/promotion-suggestions'))
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ AI Promotion Suggestions Error: $e');
      rethrow;
    }
  }
}
