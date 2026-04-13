import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:egyptian_tourism_app/core/constants/colors.dart';
import 'package:egyptian_tourism_app/models/ai_chat_models.dart';
import 'package:egyptian_tourism_app/models/models.dart';
import 'package:egyptian_tourism_app/services/ai_chat_service.dart';
import 'package:egyptian_tourism_app/repositories/cart_repository.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/rich_card_widget.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  // === الحالة ===
  final List<AiChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  AiChatService? _chatService;
  final CartRepository _cartRepo = CartRepository();
  bool _isLoading = false;
  bool _isConnected = true;
  StreamSubscription? _streamSubscription;

  // معرف المستخدم
  String? _userId;

  // أنيميشن الخلفية
  late final AnimationController _bgAnimController;
  late final Animation<double> _bgAnimation;

  // Firestore reference
  CollectionReference? _chatCollection;

  @override
  void initState() {
    super.initState();

    // أنيميشن الخلفية
    _bgAnimController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgAnimController, curve: Curves.easeInOut),
    );

    _initService();
  }

  /// تهيئة الخدمة + تحميل المحادثات المحفوظة
  Future<void> _initService() async {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
    _chatService = await AiChatService.create(userId: _userId);

    // إعداد Firestore collection لهذا المستخدم
    if (_userId != null) {
      _chatCollection = FirebaseFirestore.instance
          .collection('chats')
          .doc(_userId)
          .collection('messages');

      // تحميل المحادثات المحفوظة
      await _loadSavedMessages();
    }

    if (mounted) {
      _initializeChat();
    }
  }

  /// تحميل الرسائل المحفوظة من Firestore
  Future<void> _loadSavedMessages() async {
    if (_chatCollection == null) return;

    try {
      final snapshot = await _chatCollection!
          .orderBy('timestamp', descending: false)
          .limit(100) // آخر 100 رسالة
          .get();

      if (snapshot.docs.isNotEmpty && mounted) {
        setState(() {
          _messages.clear();
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _messages.add(AiChatMessage.fromFirestore(data));
          }
        });
        
        // الانتقال لآخر المحادثة مباشرة عند التحميل لتفادي الـ Scroll اليدوي
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        });
      }

    } catch (e) {
      debugPrint('⚠️ خطأ في تحميل المحادثات: $e');
    }
  }

  /// حفظ رسالة في Firestore
  Future<void> _saveMessage(AiChatMessage message) async {
    if (_chatCollection == null) return;
    try {
      await _chatCollection!.doc(message.id).set(message.toJson());
    } catch (e) {
      debugPrint('⚠️ خطأ في حفظ الرسالة: $e');
    }
  }

  Future<void> _initializeChat() async {
    if (_chatService == null) return;
    final healthy = await _chatService!.checkHealth();
    if (mounted) {
      setState(() => _isConnected = healthy);
    }
    if (healthy) {
      // لو مفيش رسائل محفوظة → رسالة ترحيب
      if (_messages.isEmpty) {
        _sendMessage('مرحبا', isWelcome: true);
      }
    } else if (_messages.isEmpty) {
      setState(() {
        _messages.add(AiChatMessage(
          id: 'system_offline',
          text:
              '⚠️ السيرفر مش شغال حالياً.\n\nتأكد من تشغيل الباك إند وحاول تاني.',
          isUser: false,
        ));
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _bgAnimController.dispose();
    _streamSubscription?.cancel();
    _chatService?.dispose();
    super.dispose();
  }

  /// ========================================
  /// 📤 إرسال رسالة
  /// ========================================
  Future<void> _sendMessage(String text, {bool isWelcome = false}) async {
    if (text.trim().isEmpty || _isLoading || _chatService == null) return;

    final userMessage = AiChatMessage.user(text.trim());

    setState(() {
      if (!isWelcome) {
        _messages.add(userMessage);
      }
      _isLoading = true;
      _textController.clear();
    });

    // حفظ رسالة المستخدم في Firestore
    if (!isWelcome) {
      _saveMessage(userMessage);
    }

    _scrollToBottom();

    // إنشاء رسالة AI فارغة للبث
    final aiMessageId = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    String accumulatedText = '';
    String detectedAgent = '';
    String detectedSentiment = 'neutral';
    List<AiQuickAction> quickActions = [];

    setState(() {
      _messages.add(AiChatMessage(
        id: aiMessageId,
        text: '',
        isUser: false,
        isStreaming: true,
      ));
    });
    _scrollToBottom();

    // === محاولة البث أولاً ===
    bool streamWorked = false;

    try {
      await for (final event in _chatService!.sendMessageStream(text.trim())) {
        if (!mounted) return;

        switch (event.type) {
          case AiStreamEventType.status:
            detectedAgent = event.agent ?? '';
            _updateAiMessage(aiMessageId, (msg) {
              return msg.copyWith(agentUsed: detectedAgent);
            });
            break;

          case AiStreamEventType.chunk:
            streamWorked = true;
            accumulatedText += event.content ?? '';
            _updateAiMessage(aiMessageId, (msg) {
              return msg.copyWith(
                text: accumulatedText,
                agentUsed: detectedAgent,
              );
            });
            _scrollToBottom();
            break;

          case AiStreamEventType.done:
            detectedAgent = event.agent ?? detectedAgent;
            detectedSentiment = event.sentiment ?? 'neutral';
            quickActions = event.quickActions;
            _updateAiMessage(aiMessageId, (msg) {
              return msg.copyWith(
                isStreaming: false,
                agentUsed: detectedAgent,
                sentiment: detectedSentiment,
                quickActions: quickActions,
              );
            });
            // حفظ الرد النهائي في Firestore
            _saveCompleteAiMessage(
              aiMessageId,
              accumulatedText,
              detectedAgent,
              detectedSentiment,
              quickActions,
            );
            break;

          case AiStreamEventType.error:
            if (!streamWorked) {
              _removeMessage(aiMessageId);
              final restResponse = await _chatService!.sendMessage(text.trim());
              if (mounted) {
                setState(() {
                  _messages.add(restResponse);
                });
                _saveMessage(restResponse);
              }
            } else {
              _updateAiMessage(aiMessageId, (msg) {
                return msg.copyWith(
                  text: accumulatedText.isNotEmpty
                      ? accumulatedText
                      : event.errorMessage ?? 'حدث خطأ',
                  isStreaming: false,
                );
              });
            }
            break;
        }
      }

      // لو البث انتهى بدون chunk واحد
      if (!streamWorked && mounted) {
        _removeMessage(aiMessageId);
        final restResponse = await _chatService!.sendMessage(text.trim());
        if (mounted) {
          setState(() {
            _messages.add(restResponse);
          });
          _saveMessage(restResponse);
        }
      }
    } catch (e) {
      if (mounted) {
        _removeMessage(aiMessageId);
        final restResponse = await _chatService!.sendMessage(text.trim());
        if (mounted) {
          setState(() {
            _messages.add(restResponse);
          });
          _saveMessage(restResponse);
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  /// حفظ رسالة AI المكتملة
  void _saveCompleteAiMessage(
    String id,
    String text,
    String agent,
    String sentiment,
    List<AiQuickAction> quickActions,
  ) {
    final message = AiChatMessage(
      id: id,
      text: text,
      isUser: false,
      agentUsed: agent,
      sentiment: sentiment,
      quickActions: quickActions,
    );
    _saveMessage(message);
  }

  /// تحديث رسالة AI بالبث
  void _updateAiMessage(
      String messageId, AiChatMessage Function(AiChatMessage) updater) {
    if (!mounted) return;
    setState(() {
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = updater(_messages[index]);
      }
    });
  }

  /// حذف رسالة
  void _removeMessage(String messageId) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.id == messageId);
    });
  }

  /// التمرير لآخر رسالة
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// إعادة الاتصال
  Future<void> _reconnect() async {
    if (_chatService == null) return;
    final healthy = await _chatService!.checkHealth();
    if (mounted) {
      setState(() => _isConnected = healthy);
      if (healthy && _messages.isEmpty) {
        _sendMessage('مرحبا', isWelcome: true);
      }
    }
  }

  /// مسح المحادثة — محلي + Firestore
  Future<void> _clearChat() async {
    setState(() => _messages.clear());

    if (_chatCollection != null) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final snapshot = await _chatCollection!.get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('⚠️ خطأ في مسح المحادثة: $e');
      }
    }
  }

  /// ========================================
  /// 🎨 بناء الواجهة
  /// ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.sandBeige.withValues(alpha: 0.3),
              AppColors.background,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (!_isConnected) _buildConnectionBanner(),
              Expanded(child: _buildMessagesList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// الشريط العلوي بتدرج مصري
  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryTeal.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryTeal.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مساعد البازار الذكي',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? AppColors.success
                                : AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isConnected ? 'متصل' : 'غير متصل',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!_isConnected)
                IconButton(
                  onPressed: _reconnect,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'إعادة الاتصال',
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearConfirmation();
                  } else if (value == 'server_settings') {
                    _showServerSettingsDialog();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'server_settings',
                    child: Row(
                      children: [
                        const Icon(Icons.dns_outlined,
                            color: AppColors.secondaryTeal, size: 18),
                        const SizedBox(width: 8),
                        Text('إعدادات السيرفر',
                            style: GoogleFonts.cairo(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Text('مسح المحادثة',
                            style: GoogleFonts.cairo(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تأكيد مسح المحادثة
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('مسح المحادثة؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text(
          'هيتم مسح كل الرسائل نهائياً. هل أنت متأكد؟',
          style: GoogleFonts.cairo(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('مسح',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// إشعار عدم الاتصال
  Widget _buildConnectionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warning.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'مش قادر أوصل للسيرفر — تأكد إنه شغال',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _reconnect,
            child: Text(
              'إعادة المحاولة',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// قائمة الرسائل
  Widget _buildMessagesList() {
    if (_messages.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Column(
          children: [
            ChatBubble(message: message),
            if (!message.isUser)
              ...message.cards.map((card) => RichCardWidget(
                    card: card,
                    onAction: (action) => _handleCardAction(action),
                  )),
            if (!message.isUser &&
                message.quickActions.isNotEmpty &&
                index == _messages.length - 1 &&
                !message.isStreaming)
              QuickActionsBar(
                actions: message.quickActions,
                onActionTapped: (msg) => _sendMessage(msg),
              ),
            if (index == _messages.length - 1 && _isLoading && message.isUser)
              const TypingIndicator(),
          ],
        );
      },
    );
  }

  /// الحالة الفارغة
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bgAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_bgAnimation.value * 0.05),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.secondaryTeal,
                          AppColors.secondaryTealLight
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryTeal.withValues(alpha: 0.3 + (_bgAnimation.value * 0.2)),
                          blurRadius: 20 + (_bgAnimation.value * 10),
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(-2, -2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.smart_toy_rounded,
                        color: Colors.white, size: 40),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'مساعد البازار الذكي 🇪🇬',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اسألني عن أي حاجة تخص السياحة المصرية!\n'
              'منتجات • تاريخ • بازارات • إرشاد',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('🛍️ عايز أشتري هدية'),
                _buildSuggestionChip('📜 احكيلي عن توت عنخ آمون'),
                _buildSuggestionChip('🗺️ بازارات قريبة'),
                _buildSuggestionChip('🏺 أشهر الآثار المصرية'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(text.replaceAll(RegExp(r'[🛍️📜🗺️🏺] '), '')),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondaryTeal.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryTeal.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryTealDark,
            ),
          ),
        ),
      ),
    );
  }

  /// شريط الإدخال
  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: !_isLoading,
                
                maxLines: 4,
                minLines: 1,
                style: GoogleFonts.cairo(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك هنا...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: _isLoading
                  ? null
                  : const LinearGradient(
                      colors: [
                        AppColors.secondaryTeal,
                        AppColors.secondaryTealLight,
                      ],
                    ),
              color: _isLoading ? AppColors.divider : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: _isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.secondaryTeal.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        if (_textController.text.trim().isNotEmpty) {
                          _sendMessage(_textController.text);
                        }
                      },
                borderRadius: BorderRadius.circular(22),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textHint),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
}

  /// ========================================
  /// 🛒 معالجة أفعال الكروت — مع ربط السلة
  /// ========================================
  void _handleCardAction(AiCardAction action) {
    switch (action.action) {
      case 'add_to_cart':
        _addToCartFromChat(action);
        break;
      case 'navigate':
        final target = action.params['target'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الانتقال لـ $target',
                style: GoogleFonts.cairo(fontSize: 13)),
            backgroundColor: AppColors.secondaryTeal,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        break;
      case 'send_message':
        final msg = action.params['message'] ?? action.label;
        _sendMessage(msg);
        break;
      default:
        break;
    }
  }

  /// إضافة للسلة فعلياً عبر CartRepository
  Future<void> _addToCartFromChat(AiCardAction action) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سجّل دخول الأول عشان تضيف للسلة 🔐',
              style: GoogleFonts.cairo(fontSize: 13)),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final productId = action.params['product_id'] as String? ?? '';
    final productName = action.params['name'] as String? ?? 'منتج';
    final selectedSize = action.params['size'] as String? ?? 'default';

    if (productId.isEmpty) {
      // لو مفيش product_id → نبعت رسالة للشات
      _sendMessage('أضف المنتج $productName للسلة');
      return;
    }

    try {
      final cartItem = CartItemModel(
        id: '${productId}_$selectedSize',
        productId: productId,
        selectedSize: selectedSize,
        quantity: 1,
      );

      await _cartRepo.addToCart(_userId!, cartItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ تم إضافة "$productName" للسلة',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: '🛒 عرض السلة',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إضافة المنتج: $e',
                style: GoogleFonts.cairo(fontSize: 13)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  /// ========================================
  /// ⚙️ دايلوج إعدادات السيرفر
  /// ========================================
  void _showServerSettingsDialog() {
    final urlController = TextEditingController(
      text: _chatService?.baseUrl ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.dns_outlined, color: AppColors.secondaryTeal),
            const SizedBox(width: 8),
            Text(
              'إعدادات السيرفر',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حط رابط السيرفر (ngrok أو IP المحلي):',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              textDirection: TextDirection.ltr,
              style: GoogleFonts.cairo(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://abc123.ngrok-free.app',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
                prefixIcon: const Icon(Icons.link, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 أمثلة:\n'
              '• ngrok: https://abc123.ngrok-free.app\n'
              '• محلي: http://192.168.1.5:8000\n'
              '• محاكي: http://10.0.2.2:8000',
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: AppColors.textHint,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty && _chatService != null) {
                await _chatService!.updateUrl(newUrl);
                if (mounted) {
                  Navigator.pop(ctx);
                  _reconnect();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ تم تحديث رابط السيرفر',
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: Text(
              'حفظ واتصال',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
