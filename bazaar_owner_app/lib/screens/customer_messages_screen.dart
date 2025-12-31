import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// شاشة رسائل العملاء
class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      if (bazaarId == null) return;

      final snapshot = await _firestore
          .collection('messages')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      _messages =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      // ترتيب حسب التاريخ
      _messages.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _unreadMessages =>
      _messages.where((m) => m['isRead'] != true).toList();

  List<Map<String, dynamic>> get _readMessages =>
      _messages.where((m) => m['isRead'] == true).toList();

  Future<void> _markAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      _loadMessages();
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadMessages.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('رسائل العملاء'),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('غير مقروءة'),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'مقروءة'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesList(_unreadMessages, showUnreadBadge: true),
                _buildMessagesList(_readMessages),
              ],
            ),
    );
  }

  Widget _buildMessagesList(List<Map<String, dynamic>> messages,
      {bool showUnreadBadge = false}) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.message,
                size: 64,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              showUnreadBadge ? 'لا توجد رسائل جديدة' : 'لا توجد رسائل',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) => _buildMessageCard(
          messages[index],
          showUnreadBadge: showUnreadBadge,
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message,
      {bool showUnreadBadge = false}) {
    final customerName = message['customerName'] as String? ?? 'عميل';
    final subject = message['subject'] as String? ?? 'استفسار';
    final content = message['content'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(message['createdAt'] ?? '') ?? DateTime.now();
    final dateFormat = DateFormat('dd MMM - HH:mm', 'ar');
    final isUnread = message['isRead'] != true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.info.withOpacity(0.05) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnread
            ? Border.all(color: AppColors.info.withOpacity(0.2))
            : null,
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMessageDialog(message),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      radius: 24,
                      child: Text(
                        customerName.isNotEmpty
                            ? customerName[0].toUpperCase()
                            : 'ع',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            customerName,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            dateFormat.format(createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageDialog(Map<String, dynamic> message) {
    final messageId = message['id'] as String;
    final customerName = message['customerName'] as String? ?? 'عميل';
    final subject = message['subject'] as String? ?? 'استفسار';
    final content = message['content'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(message['createdAt'] ?? '') ?? DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy - HH:mm', 'ar');

    // تعيين كمقروءة
    if (message['isRead'] != true) {
      _markAsRead(messageId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    radius: 24,
                    child: Text(
                      customerName.isNotEmpty
                          ? customerName[0].toUpperCase()
                          : 'ع',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          dateFormat.format(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Reply button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('سيتم إضافة الرد قريباً'),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Iconsax.send_1),
                    label: const Text('الرد على الرسالة'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
