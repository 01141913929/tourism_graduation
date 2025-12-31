import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/message_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/notification_service.dart';

/// Chat screen for customer-bazaar communication
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String bazaarName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.bazaarName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageService _messageService = MessageService();

  ConversationMessage? _conversation;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);

    try {
      final doc = await _firestore
          .collection('messages')
          .doc(widget.conversationId)
          .get();

      if (doc.exists) {
        _conversation =
            ConversationMessage.fromJson({...doc.data()!, 'id': doc.id});
      }
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;
    final userName = authProvider.user?.name ?? 'عميل';

    if (userId == null) return;

    setState(() => _isSending = true);

    try {
      await _messageService.addReply(
        messageId: widget.conversationId,
        senderId: userId,
        senderName: userName,
        senderType: 'customer',
        content: text,
      );

      // Send Notification to Bazaar Owner
      if (_conversation != null) {
        NotificationService().sendNotification(
          targetUserId: _conversation!.bazaarId,
          title: 'رسالة جديدة من $userName',
          body: text,
          data: {
            'type': 'chat',
            'conversationId': widget.conversationId,
          },
        );
      }

      _messageController.clear();
      await _loadConversation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
        ),
        title: Column(
          children: [
            Text(
              widget.bazaarName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_conversation != null)
              Text(
                _conversation!.subject,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.shop,
              color: AppColors.primaryOrange,
              size: 20,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversation == null
              ? const Center(child: Text('لم يتم العثور على المحادثة'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Initial message
                          _buildMessageBubble(
                            content: _conversation!.initialMessage,
                            isMe: true,
                            senderName: _conversation!.customerName,
                            timestamp: _conversation!.createdAt,
                          ),

                          // Replies
                          ..._conversation!.replies
                              .map((reply) => _buildMessageBubble(
                                    content: reply.content,
                                    isMe: reply.senderType == 'customer',
                                    senderName: reply.senderName,
                                    timestamp: reply.createdAt,
                                  )),
                        ],
                      ),
                    ),

                    // Input bar
                    _buildInputBar(),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required bool isMe,
    required String senderName,
    required DateTime timestamp,
  }) {
    final timeFormat = intl.DateFormat('HH:mm');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, right: 8),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryOrange : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isMe ? AppColors.white : AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8, left: 8),
              child: Text(
                timeFormat.format(timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Send button
          GestureDetector(
            onTap: _isSending ? null : _sendReply,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isSending ? AppColors.textHint : AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.white),
                      ),
                    )
                  : const Icon(
                      Iconsax.send_1,
                      color: AppColors.white,
                      size: 20,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
