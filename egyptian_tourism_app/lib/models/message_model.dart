import 'package:cloud_firestore/cloud_firestore.dart';

/// Message status enum
enum MessageStatus {
  sent,
  read,
  replied,
}

/// Reply model for conversation thread
class MessageReply {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // 'customer' or 'bazaar'
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageReply({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageReply.fromJson(Map<String, dynamic> json) {
    return MessageReply(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      senderType: json['senderType'] as String? ?? 'customer',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// Conversation message model with replies support
class ConversationMessage {
  final String id;
  final String bazaarId;
  final String bazaarName;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String subject;
  final String initialMessage;
  final List<MessageReply> replies;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final MessageStatus status;
  final bool isRead;
  final int unreadCount;
  final String? productId;
  final String? productName;

  const ConversationMessage({
    required this.id,
    required this.bazaarId,
    required this.bazaarName,
    required this.customerId,
    required this.customerName,
    this.customerEmail = '',
    required this.subject,
    required this.initialMessage,
    this.replies = const [],
    required this.createdAt,
    DateTime? lastMessageAt,
    this.status = MessageStatus.sent,
    this.isRead = false,
    this.unreadCount = 0,
    this.productId,
    this.productName,
  }) : lastMessageAt = lastMessageAt ?? createdAt;

  String get lastMessageContent {
    if (replies.isEmpty) return initialMessage;
    return replies.last.content;
  }

  int get totalMessages => 1 + replies.length;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final repliesJson = json['replies'] as List<dynamic>? ?? [];

    return ConversationMessage(
      id: json['id'] as String? ?? '',
      bazaarId: json['bazaarId'] as String? ?? '',
      bazaarName: json['bazaarName'] as String? ?? '',
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      initialMessage:
          json['content'] as String? ?? json['initialMessage'] as String? ?? '',
      replies: repliesJson
          .map((r) => MessageReply.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastMessageAt:
          DateTime.tryParse(json['lastMessageAt'] ?? '') ?? DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isRead: json['isRead'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
      productId: json['productId'] as String?,
      productName: json['productName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bazaarId': bazaarId,
      'bazaarName': bazaarName,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'subject': subject,
      'content': initialMessage,
      'initialMessage': initialMessage,
      'replies': replies.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'status': status.name,
      'isRead': isRead,
      'unreadCount': unreadCount,
      'productId': productId,
      'productName': productName,
    };
  }

  ConversationMessage copyWith({
    String? id,
    String? bazaarId,
    String? bazaarName,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? subject,
    String? initialMessage,
    List<MessageReply>? replies,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    MessageStatus? status,
    bool? isRead,
    int? unreadCount,
    String? productId,
    String? productName,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      bazaarId: bazaarId ?? this.bazaarId,
      bazaarName: bazaarName ?? this.bazaarName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      subject: subject ?? this.subject,
      initialMessage: initialMessage ?? this.initialMessage,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      unreadCount: unreadCount ?? this.unreadCount,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
    );
  }
}

/// Service for managing messages
class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a new message from customer to bazaar
  Future<String> sendMessage({
    required String bazaarId,
    required String bazaarName,
    required String customerId,
    required String customerName,
    required String subject,
    required String content,
    String? productId,
    String? productName,
  }) async {
    final docRef = _firestore.collection('messages').doc();
    final now = DateTime.now();

    final message = ConversationMessage(
      id: docRef.id,
      bazaarId: bazaarId,
      bazaarName: bazaarName,
      customerId: customerId,
      customerName: customerName,
      subject: subject,
      initialMessage: content,
      createdAt: now,
      productId: productId,
      productName: productName,
    );

    await docRef.set(message.toJson());
    return docRef.id;
  }

  /// Add a reply to a conversation
  Future<void> addReply({
    required String messageId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String content,
  }) async {
    final docRef = _firestore.collection('messages').doc(messageId);
    final now = DateTime.now();

    final reply = MessageReply(
      id: '${messageId}_${now.millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      content: content,
      createdAt: now,
    );

    await docRef.update({
      'replies': FieldValue.arrayUnion([reply.toJson()]),
      'lastMessageAt': now.toIso8601String(),
      'status': MessageStatus.replied.name,
    });
  }

  /// Mark conversation as read
  Future<void> markAsRead(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  /// Stream messages for a customer
  Stream<List<ConversationMessage>> streamCustomerMessages(String customerId) {
    return _firestore
        .collection('messages')
        .where('customerId', isEqualTo: customerId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ConversationMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Stream messages for a bazaar
  Stream<List<ConversationMessage>> streamBazaarMessages(String bazaarId) {
    return _firestore
        .collection('messages')
        .where('bazaarId', isEqualTo: bazaarId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ConversationMessage.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
