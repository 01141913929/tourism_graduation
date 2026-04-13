/// 🤖 خدمة التواصل مع الباك إند الذكي
/// تدعم SSE Streaming + REST Fallback
/// الرابط قابل للتغيير من داخل التطبيق (بدون rebuild)
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_chat_models.dart';

class AiChatService {
  // === الإعدادات ===
  static const String _fallbackUrl = 'https://oozy-laboringly-taliyah.ngrok-free.dev';
  static const String _prefKey = 'ai_server_url';

  String _baseUrl;
  final String sessionId;
  final String? userId;
  final http.Client _client;

  AiChatService._({
    required String baseUrl,
    required this.sessionId,
    this.userId,
  })  : _baseUrl = baseUrl,
        _client = http.Client();

  /// ========================================
  /// 🏭 إنشاء instance مع تحميل الرابط المحفوظ
  /// ========================================
  static Future<AiChatService> create({
    String? sessionId,
    String? userId,
  }) async {
    final savedUrl = await getSavedUrl();
    return AiChatService._(
      baseUrl: savedUrl,
      sessionId:
          sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
    );
  }

  /// إنشاء سريع بدون async (يستخدم الرابط الافتراضي)
  factory AiChatService({
    String baseUrl = _fallbackUrl,
    String? sessionId,
    String? userId,
  }) {
    return AiChatService._(
      baseUrl: baseUrl,
      sessionId:
          sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
    );
  }

  /// الرابط الحالي
  String get baseUrl => _baseUrl;

  /// ========================================
  /// 💾 حفظ وتحميل رابط السيرفر
  /// ========================================

  /// حفظ رابط جديد
  static Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    await prefs.setString(_prefKey, cleaned);
  }

  /// تحميل الرابط المحفوظ
  static Future<String> getSavedUrl() async {
    return _fallbackUrl;
  }

  /// تحديث الرابط في الـ instance الحالي
  Future<void> updateUrl(String url) async {
    await saveUrl(url);
    _baseUrl = url.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
  }

  /// ========================================
  /// 📡 إرسال رسالة بالبث المباشر (SSE)
  /// ========================================
  Stream<AiStreamEvent> sendMessageStream(String message) async* {
    final url = Uri.parse('$_baseUrl/api/chat/stream');
    final body = jsonEncode({
      'message': message,
      'session_id': sessionId,
      'user_id': userId ?? '',
    });

    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      request.body = body;

      final response = await _client.send(request).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        yield AiStreamEvent.error('خطأ في السيرفر: ${response.statusCode}');
        return;
      }

      String buffer = '';
      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .timeout(const Duration(seconds: 45))) {
        buffer += chunk;

        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 2);

          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final type = data['type'] as String? ?? '';

              switch (type) {
                case 'status':
                  yield AiStreamEvent.status(
                    agent: data['agent'] as String? ?? '',
                    status: data['status'] as String? ?? '',
                  );
                  break;

                case 'chunk':
                  yield AiStreamEvent.chunk(
                    content: data['content'] as String? ?? '',
                  );
                  break;

                case 'done':
                  yield AiStreamEvent.done(
                    agent: data['agent'] as String? ?? '',
                    sentiment: data['sentiment'] as String? ?? 'neutral',
                    quickActions: (data['quick_actions'] as List<dynamic>?)
                            ?.map((qa) => AiQuickAction.fromJson(
                                qa as Map<String, dynamic>))
                            .toList() ??
                        [],
                    cached: data['cached'] as bool? ?? false,
                  );
                  break;
              }
            } catch (_) {
              // تجاهل JSON غير صالح
            }
          }
        }
      }
    } on TimeoutException {
      yield AiStreamEvent.error('انتهى وقت الانتظار. تأكد من تشغيل السيرفر.');
    } catch (e) {
      yield AiStreamEvent.error(
          'خطأ في الاتصال: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
    }
  }

  /// ========================================
  /// 💬 إرسال رسالة عادية (REST — بديل)
  /// ========================================
  Future<AiChatMessage> sendMessage(String message) async {
    final url = Uri.parse('$_baseUrl/api/chat');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'session_id': sessionId,
              'user_id': userId ?? '',
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AiChatMessage.fromApiResponse(data);
      } else {
        return AiChatMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'عذراً، حدث خطأ في السيرفر (${response.statusCode}). حاول مرة تانية.',
          isUser: false,
        );
      }
    } on TimeoutException {
      return AiChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text: 'انتهى وقت الانتظار ⏱️\nتأكد إن السيرفر شغال وحاول تاني.',
        isUser: false,
      );
    } catch (e) {
      return AiChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'مش قادر أوصل للسيرفر 😔\nتأكد من الاتصال بالإنترنت وإن السيرفر شغال.',
        isUser: false,
      );
    }
  }

  /// ========================================
  /// ❤️ فحص حالة السيرفر
  /// ========================================
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// ========================================
/// 📡 أنواع أحداث البث (SSE Events)
/// ========================================
enum AiStreamEventType { status, chunk, done, error }

class AiStreamEvent {
  final AiStreamEventType type;
  final String? content;
  final String? agent;
  final String? status;
  final String? sentiment;
  final List<AiQuickAction> quickActions;
  final bool cached;
  final String? errorMessage;

  const AiStreamEvent._({
    required this.type,
    this.content,
    this.agent,
    this.status,
    this.sentiment,
    this.quickActions = const [],
    this.cached = false,
    this.errorMessage,
  });

  factory AiStreamEvent.status({
    required String agent,
    required String status,
  }) {
    return AiStreamEvent._(
      type: AiStreamEventType.status,
      agent: agent,
      status: status,
    );
  }

  factory AiStreamEvent.chunk({required String content}) {
    return AiStreamEvent._(
      type: AiStreamEventType.chunk,
      content: content,
    );
  }

  factory AiStreamEvent.done({
    required String agent,
    required String sentiment,
    required List<AiQuickAction> quickActions,
    required bool cached,
  }) {
    return AiStreamEvent._(
      type: AiStreamEventType.done,
      agent: agent,
      sentiment: sentiment,
      quickActions: quickActions,
      cached: cached,
    );
  }

  factory AiStreamEvent.error(String message) {
    return AiStreamEvent._(
      type: AiStreamEventType.error,
      errorMessage: message,
    );
  }
}
