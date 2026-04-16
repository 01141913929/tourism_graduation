/// 🤖 خدمة التواصل مع الباك إند الذكي
/// تدعم SSE Streaming + REST Fallback
/// الرابط قابل للتغيير من داخل التطبيق (بدون rebuild)
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/ai_chat_models.dart';

class AiChatService {
  // === الإعدادات ===
  static const String _fallbackHttpUrl = 'https://4071i39q50.execute-api.us-east-1.amazonaws.com/deployment-test';
  static const String _wsUrl = 'wss://zm6it1qy02.execute-api.us-east-1.amazonaws.com/deployment-test';
  static const String _prefKey = 'ai_server_url';

  String _baseUrl;
  final String sessionId;
  final String? userId;
  final http.Client _client;
  WebSocketChannel? _channel;
  Timer? _pingTimer;

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

  factory AiChatService({
    String baseUrl = _fallbackHttpUrl,
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

  String get baseUrl => _baseUrl;

  static Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String cleaned = url.trim();
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    await prefs.setString(_prefKey, cleaned);
  }

  static Future<String> getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) ?? _fallbackHttpUrl;
  }

  Future<void> updateUrl(String url) async {
    await saveUrl(url);
    _baseUrl = url.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
  }

  /// ========================================
  /// 📡 إرسال رسالة بالبث المباشر (WebSockets)
  /// ========================================
  Stream<AiStreamEvent> sendMessageStream(String message) async* {
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
    }

    try {
      // Derive WS URL from base URL or use the hardcoded fallback
      final wsEndpoint = _deriveWsUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsEndpoint));
      
      final payload = jsonEncode({
        'action': 'sendMessage',
        'message': message,
        'session_id': sessionId,
        'user_id': userId ?? '',
      });
      _channel!.sink.add(payload);
      
      _startPingTimer();

      await for (final dynamic message in _channel!.stream) {
        String dataStr = message.toString();
        try {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
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
              // ✅ إغلاق الاتصال والخروج — عشان الـ stream يخلص
              _channel?.sink.close(status.normalClosure);
              _channel = null;
              return;

            case 'error':
              yield AiStreamEvent.error(data['message'] as String? ?? 'حدث خطأ غير معروف في السيرفر');
              _channel?.sink.close(status.normalClosure);
              _channel = null;
              return;
          }
        } catch (_) {
          // تجاهل JSON غير صالح
        }
      }
    } catch (e) {
      yield AiStreamEvent.error(
          'خطأ في الاتصال: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
    } finally {
      _stopPingTimer();
      _channel?.sink.close(status.normalClosure);
      _channel = null;
    }
  }

  /// Start a ping timer to keep AWS API Gateway WebSocket connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'action': 'ping'}));
        } catch (_) {}
      } else {
        timer.cancel();
      }
    });
  }

  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
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

  /// Derive WebSocket URL from the HTTP base URL
  String _deriveWsUrl() {
    // If base URL matches known HTTP endpoint, use matching WS endpoint
    if (_baseUrl == _fallbackHttpUrl) return _wsUrl;
    // Convert http(s):// to ws(s)://
    final wsUrl = _baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return wsUrl;
  }

  void dispose() {
    _stopPingTimer();
    _client.close();
    _channel?.sink.close(status.normalClosure);
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
