// 🤖 نماذج بيانات الشات بوت الذكي
// تمثل الرسائل والكروت والأفعال السريعة — مع دعم Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

/// رسالة في المحادثة (مستخدم أو AI)
class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String agentUsed;
  final String sentiment;
  final List<AiQuickAction> quickActions;
  final List<AiRichCard> cards;
  final List<String> sources;
  final bool isStreaming;

  AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.agentUsed = '',
    this.sentiment = 'neutral',
    this.quickActions = const [],
    this.cards = const [],
    this.sources = const [],
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// إنشاء رسالة مستخدم
  factory AiChatMessage.user(String text) {
    return AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
    );
  }

  /// إنشاء رسالة AI من رد الباك إند
  factory AiChatMessage.fromApiResponse(Map<String, dynamic> json) {
    return AiChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      isUser: false,
      agentUsed:
          json['agent_used'] as String? ?? json['agent'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      quickActions: (json['quick_actions'] as List<dynamic>?)
              ?.map((qa) => AiQuickAction.fromJson(qa as Map<String, dynamic>))
              .toList() ??
          [],
      cards: (json['cards'] as List<dynamic>?)
              ?.map((c) => AiRichCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }

  /// ========================================
  /// 🔥 Firestore — تحويل من/إلى
  /// ========================================

  /// تحويل لـ Map للحفظ في Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'agentUsed': agentUsed,
      'sentiment': sentiment,
      'quickActions': quickActions.map((qa) => qa.toJson()).toList(),
      'cards': cards.map((c) => c.toJson()).toList(),
      'sources': sources,
    };
  }

  /// إنشاء من Firestore document
  factory AiChatMessage.fromFirestore(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      agentUsed: json['agentUsed'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'neutral',
      quickActions: (json['quickActions'] as List<dynamic>?)
              ?.map((qa) => AiQuickAction.fromJson(qa as Map<String, dynamic>))
              .toList() ??
          [],
      cards: (json['cards'] as List<dynamic>?)
              ?.map((c) => AiRichCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      sources: (json['sources'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }

  /// نسخة معدّلة
  AiChatMessage copyWith({
    String? text,
    bool? isStreaming,
    List<AiQuickAction>? quickActions,
    List<AiRichCard>? cards,
    String? agentUsed,
    String? sentiment,
    List<String>? sources,
  }) {
    return AiChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      agentUsed: agentUsed ?? this.agentUsed,
      sentiment: sentiment ?? this.sentiment,
      quickActions: quickActions ?? this.quickActions,
      cards: cards ?? this.cards,
      sources: sources ?? this.sources,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  /// اسم الوكيل للعرض بالعربي
  String get agentDisplayName {
    switch (agentUsed) {
      case 'product_agent':
        return '🛍️ خبير التسوق';
      case 'history_agent':
        return '📜 المؤرخ';
      case 'cart_agent':
        return '🛒 مساعد السلة';
      case 'tour_guide_agent':
        return '🗺️ المرشد السياحي';
      case 'web_research_agent':
        return '🌐 الباحث';
      case 'personalization_agent':
        return '✨ التخصيص';
      case 'general_agent':
        return '💬 المساعد';
      default:
        return '🤖 المساعد الذكي';
    }
  }
}

/// فعل سريع (زر اقتراح)
class AiQuickAction {
  final String label;
  final String message;

  const AiQuickAction({
    required this.label,
    required this.message,
  });

  factory AiQuickAction.fromJson(Map<String, dynamic> json) {
    return AiQuickAction(
      label: json['label'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'message': message};
}

/// كارت غني (منتج / أثر / بازار)
class AiRichCard {
  final String type;
  final Map<String, dynamic> data;
  final List<AiCardAction> actions;

  const AiRichCard({
    required this.type,
    required this.data,
    this.actions = const [],
  });

  factory AiRichCard.fromJson(Map<String, dynamic> json) {
    return AiRichCard(
      type: json['type'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => AiCardAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'actions': actions.map((a) => a.toJson()).toList(),
      };
}

/// فعل على كارت (أضف للسلة، تصفح، ...)
class AiCardAction {
  final String label;
  final String action;
  final Map<String, dynamic> params;

  const AiCardAction({
    required this.label,
    required this.action,
    this.params = const {},
  });

  factory AiCardAction.fromJson(Map<String, dynamic> json) {
    return AiCardAction(
      label: json['label'] as String? ?? '',
      action: json['action'] as String? ?? '',
      params: json['params'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'action': action,
        'params': params,
      };
}
