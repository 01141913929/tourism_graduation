import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة الرسائل الإدارية لأصحاب البازارات
class AdminMessagingScreen extends StatefulWidget {
  const AdminMessagingScreen({super.key});

  @override
  State<AdminMessagingScreen> createState() => _AdminMessagingScreenState();
}

class _AdminMessagingScreenState extends State<AdminMessagingScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _bazaars = [];
  List<Map<String, dynamic>> _sentMessages = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load bazaars
      final bazaarsSnapshot = await _firestore
          .collection('bazaars')
          .where('isVerified', isEqualTo: true)
          .get();

      _bazaars = bazaarsSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      // Load sent messages
      final messagesSnapshot = await _firestore
          .collection('adminNotifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _sentMessages = messagesSnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showComposeDialog({String? targetBazaarId, String? targetBazaarName}) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String selectedType = targetBazaarId != null ? 'single' : 'all';
    String? selectedBazaarId = targetBazaarId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.message_text, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('إرسال رسالة إدارية'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target selection
                  const Text('إرسال إلى:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'all',
                          groupValue: selectedType,
                          onChanged: (v) => setDialogState(() {
                            selectedType = v!;
                            selectedBazaarId = null;
                          }),
                          title: const Text('جميع البازارات'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          value: 'single',
                          groupValue: selectedType,
                          onChanged: (v) =>
                              setDialogState(() => selectedType = v!),
                          title: const Text('بازار محدد'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),

                  // Bazaar dropdown
                  if (selectedType == 'single') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedBazaarId,
                      decoration: InputDecoration(
                        labelText: 'اختر البازار',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _bazaars
                          .map((b) => DropdownMenuItem(
                                value: b['id'] as String,
                                child: Text(b['nameAr'] ?? 'بازار'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedBazaarId = v),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان الرسالة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'نص الرسالة',
                      hintText: 'اكتب رسالتك هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول')),
                  );
                  return;
                }

                Navigator.pop(context);
                await _sendMessage(
                  title: titleController.text,
                  message: messageController.text,
                  targetType: selectedType,
                  targetBazaarId: selectedBazaarId,
                );
              },
              icon: const Icon(Iconsax.send_1),
              label: const Text('إرسال'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage({
    required String title,
    required String message,
    required String targetType,
    String? targetBazaarId,
  }) async {
    try {
      if (targetType == 'all') {
        // Send to all bazaars
        final batch = _firestore.batch();

        for (final bazaar in _bazaars) {
          final docRef = _firestore.collection('adminNotifications').doc();
          batch.set(docRef, {
            'title': title,
            'message': message,
            'targetType': 'all',
            'targetBazaarId': bazaar['id'],
            'createdAt': DateTime.now().toIso8601String(),
            'isRead': false,
          });
        }

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال الرسالة إلى ${_bazaars.length} بازار'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // Send to single bazaar
        await _firestore.collection('adminNotifications').add({
          'title': title,
          'message': message,
          'targetType': 'single',
          'targetBazaarId': targetBazaarId,
          'createdAt': DateTime.now().toIso8601String(),
          'isRead': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرسالة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showBroadcastNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.notification, color: AppColors.primary),
            SizedBox(width: 8),
            Text('إرسال إشعار عام'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'عنوان الإشعار',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'نص الإشعار',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  bodyController.text.isNotEmpty) {
                Navigator.pop(context);
                // Save notification to Firestore for all bazaars
                for (final bazaar in _bazaars) {
                  await _firestore.collection('adminNotifications').add({
                    'title': titleController.text,
                    'message': bodyController.text,
                    'targetType': 'broadcast',
                    'targetBazaarId': bazaar['id'],
                    'createdAt': DateTime.now().toIso8601String(),
                    'isRead': false,
                  });
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('تم إرسال الإشعار لـ ${_bazaars.length} بازار'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadData();
              }
            },
            icon: const Icon(Iconsax.send_1),
            label: const Text('إرسال للجميع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredBazaars {
    if (_searchQuery.isEmpty) return _bazaars;
    return _bazaars
        .where((b) => (b['nameAr'] ?? '')
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الرسائل الإدارية'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'البازارات', icon: Icon(Iconsax.shop, size: 18)),
            Tab(text: 'الرسائل المرسلة', icon: Icon(Iconsax.message, size: 18)),
            Tab(text: 'الإشعارات', icon: Icon(Iconsax.notification, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showComposeDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.edit, color: Colors.white),
        label: const Text('رسالة جديدة', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBazaarsTab(),
                _buildSentMessagesTab(),
                _buildNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildBazaarsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'البحث في البازارات...',
              prefixIcon: const Icon(Iconsax.search_normal),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredBazaars.length,
            itemBuilder: (context, index) {
              final bazaar = _filteredBazaars[index];
              return _buildBazaarCard(bazaar);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBazaarCard(Map<String, dynamic> bazaar) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            (bazaar['nameAr'] ?? 'B')[0],
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          bazaar['nameAr'] ?? 'بازار',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          bazaar['governorate'] ?? '',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Iconsax.message_add),
          color: AppColors.primary,
          onPressed: () => _showComposeDialog(
            targetBazaarId: bazaar['id'],
            targetBazaarName: bazaar['nameAr'],
          ),
        ),
      ),
    );
  }

  Widget _buildSentMessagesTab() {
    if (_sentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.message, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد رسائل مرسلة',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sentMessages.length,
      itemBuilder: (context, index) {
        final msg = _sentMessages[index];
        final createdAt =
            DateTime.tryParse(msg['createdAt'] ?? '') ?? DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: msg['targetType'] == 'all'
                            ? AppColors.info.withOpacity(0.1)
                            : AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        msg['targetType'] == 'all' ? 'للجميع' : 'بازار محدد',
                        style: TextStyle(
                          fontSize: 11,
                          color: msg['targetType'] == 'all'
                              ? AppColors.info
                              : AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM HH:mm').format(createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  msg['title'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  msg['message'] ?? '',
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.notification, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Push Notifications',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showBroadcastNotificationDialog(),
            icon: const Icon(Iconsax.send_2),
            label: const Text('إرسال إشعار عام'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
