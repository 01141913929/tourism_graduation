import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة إدارة الشكاوى
class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _loadComplaints();
  }

  void _onTabChanged(int index) {
    final statuses = ['all', 'pending', 'inProgress', 'resolved'];
    setState(() => _selectedStatus = statuses[index]);
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      Query query = _firestore
          .collection('complaints')
          .orderBy('createdAt', descending: true);

      if (_selectedStatus != 'all') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      final snapshot = await query.get();

      _complaints = snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('Error loading complaints: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateComplaintStatus(String id, String newStatus,
      {String? response}) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (response != null) {
        updateData['adminResponse'] = response;
      }

      await _firestore.collection('complaints').doc(id).update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getStatusMessage(newStatus)),
          backgroundColor: AppColors.success,
        ),
      );

      _loadComplaints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'inProgress':
        return 'تم تحديث الحالة إلى "قيد المعالجة"';
      case 'resolved':
        return 'تم حل الشكوى';
      case 'rejected':
        return 'تم رفض الشكوى';
      default:
        return 'تم تحديث الحالة';
    }
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    final responseController = TextEditingController(
      text: complaint['adminResponse'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getComplaintTypeColor(complaint['type'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getComplaintTypeIcon(complaint['type']),
                      color: _getComplaintTypeColor(complaint['type']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint['subject'] ?? 'شكوى',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '#${complaint['id']?.substring(0, 8)}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(complaint['status'] ?? 'pending'),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info cards
                    _buildInfoCard('المستخدم',
                        complaint['userName'] ?? 'غير معروف', Iconsax.user),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                        'البريد', complaint['userEmail'] ?? '-', Iconsax.sms),
                    const SizedBox(height: 12),
                    if (complaint['orderId'] != null)
                      _buildInfoCard(
                          'رقم الطلب', '#${complaint['orderId']}', Iconsax.box),
                    if (complaint['orderId'] != null)
                      const SizedBox(height: 12),
                    if (complaint['bazaarId'] != null)
                      _buildInfoCard(
                          'البازار',
                          complaint['bazaarName'] ?? complaint['bazaarId'],
                          Iconsax.shop),
                    if (complaint['bazaarId'] != null)
                      const SizedBox(height: 12),

                    // Complaint message
                    const SizedBox(height: 8),
                    const Text('تفاصيل الشكوى:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        complaint['message'] ?? '',
                        style: const TextStyle(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Admin response
                    const Text('رد الإدارة:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب رد الإدارة هنا...',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    if (complaint['status'] != 'resolved')
                      Row(
                        children: [
                          if (complaint['status'] == 'pending')
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateComplaintStatus(
                                    complaint['id'],
                                    'inProgress',
                                    response: responseController.text.isEmpty
                                        ? null
                                        : responseController.text,
                                  );
                                },
                                icon: const Icon(Iconsax.timer_1),
                                label: const Text('قيد المعالجة'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.warning,
                                  side: const BorderSide(
                                      color: AppColors.warning),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          if (complaint['status'] == 'pending')
                            const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updateComplaintStatus(
                                  complaint['id'],
                                  'resolved',
                                  response: responseController.text,
                                );
                              },
                              icon: const Icon(Iconsax.tick_circle),
                              label: const Text('تم الحل'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
        title: const Text('إدارة الشكاوى'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadComplaints,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          onTap: (index) {
            final statuses = ['all', 'pending', 'inProgress', 'resolved'];
            setState(() => _selectedStatus = statuses[index]);
            _loadComplaints();
          },
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'جديدة'),
            Tab(text: 'قيد المعالجة'),
            Tab(text: 'تم الحل'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _complaints.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    return _buildComplaintCard(_complaints[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_question, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('لا توجد شكاوى',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final createdAt =
        DateTime.tryParse(complaint['createdAt'] ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showComplaintDetails(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getComplaintTypeColor(complaint['type'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getComplaintTypeIcon(complaint['type']),
                      color: _getComplaintTypeColor(complaint['type']),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint['subject'] ?? 'شكوى',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          complaint['userName'] ?? 'مستخدم',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(complaint['status'] ?? 'pending'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint['message'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Iconsax.clock, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Text(
                    'اضغط للتفاصيل',
                    style: TextStyle(fontSize: 11, color: AppColors.primary),
                  ),
                  const Icon(Iconsax.arrow_left_2,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'جديدة';
        break;
      case 'inProgress':
        color = AppColors.info;
        text = 'قيد المعالجة';
        break;
      case 'resolved':
        color = AppColors.success;
        text = 'تم الحل';
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'مرفوضة';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getComplaintTypeColor(String? type) {
    switch (type) {
      case 'order':
        return AppColors.primary;
      case 'product':
        return AppColors.secondary;
      case 'bazaar':
        return AppColors.info;
      case 'payment':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getComplaintTypeIcon(String? type) {
    switch (type) {
      case 'order':
        return Iconsax.box;
      case 'product':
        return Iconsax.shopping_bag;
      case 'bazaar':
        return Iconsax.shop;
      case 'payment':
        return Iconsax.money;
      default:
        return Iconsax.message_question;
    }
  }
}
