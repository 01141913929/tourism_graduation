import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';

/// شاشة تعليق/حظر البازارات
class BazaarSuspensionScreen extends StatefulWidget {
  const BazaarSuspensionScreen({super.key});

  @override
  State<BazaarSuspensionScreen> createState() => _BazaarSuspensionScreenState();
}

class _BazaarSuspensionScreenState extends State<BazaarSuspensionScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<Map<String, dynamic>> _activeBazaars = [];
  List<Map<String, dynamic>> _suspendedBazaars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBazaars();
  }

  Future<void> _loadBazaars() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('bazaars').get();

      final allBazaars = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      _activeBazaars = allBazaars
          .where((b) => b['status'] != 'suspended' && b['isVerified'] == true)
          .toList();

      _suspendedBazaars =
          allBazaars.where((b) => b['status'] == 'suspended').toList();
    } catch (e) {
      debugPrint('Error loading bazaars: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuspendDialog(Map<String, dynamic> bazaar) {
    final reasonController = TextEditingController();
    DateTime? suspensionEndDate;
    bool isPermanent = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Iconsax.warning_2, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('تعليق البازار'),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bazaar info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          (bazaar['nameAr'] ?? 'B')[0],
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bazaar['nameAr'] ?? 'بازار',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              bazaar['governorate'] ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reason
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'سبب التعليق *',
                    hintText: 'اذكر سبب تعليق البازار...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Permanent or temporary
                CheckboxListTile(
                  value: isPermanent,
                  onChanged: (v) =>
                      setDialogState(() => isPermanent = v ?? false),
                  title: const Text('تعليق دائم'),
                  subtitle: Text(
                    isPermanent
                        ? 'سيتطلب إعادة التفعيل يدوياً'
                        : 'يمكنك تحديد تاريخ انتهاء',
                    style: const TextStyle(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                // End date (if not permanent)
                if (!isPermanent) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() => suspensionEndDate = date);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.calendar, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            suspensionEndDate != null
                                ? 'ينتهي في: ${DateFormat('dd/MM/yyyy').format(suspensionEndDate!)}'
                                : 'اختر تاريخ انتهاء التعليق',
                            style: TextStyle(
                              color: suspensionEndDate != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى كتابة سبب التعليق')),
                  );
                  return;
                }
                Navigator.pop(context);
                _suspendBazaar(
                  bazaar['id'],
                  reasonController.text,
                  isPermanent ? null : suspensionEndDate,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('تعليق البازار'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suspendBazaar(
      String bazaarId, String reason, DateTime? endDate) async {
    try {
      await _firestore.collection('bazaars').doc(bazaarId).update({
        'status': 'suspended',
        'suspensionReason': reason,
        'suspendedAt': DateTime.now().toIso8601String(),
        'suspensionEndDate': endDate?.toIso8601String(),
        'isOpen': false,
      });

      // Send notification to bazaar owner
      await _firestore.collection('adminNotifications').add({
        'title': 'تم تعليق بازارك',
        'message':
            'سبب التعليق: $reason${endDate != null ? '\nينتهي في: ${DateFormat('dd/MM/yyyy').format(endDate)}' : ''}',
        'targetType': 'single',
        'targetBazaarId': bazaarId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'suspension',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعليق البازار وإرسال إشعار للمالك'),
          backgroundColor: AppColors.warning,
        ),
      );

      _loadBazaars();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _reactivateBazaar(String bazaarId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إعادة تفعيل البازار'),
        content: const Text('هل أنت متأكد من إعادة تفعيل هذا البازار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.collection('bazaars').doc(bazaarId).update({
        'status': 'active',
        'suspensionReason': FieldValue.delete(),
        'suspendedAt': FieldValue.delete(),
        'suspensionEndDate': FieldValue.delete(),
        'isOpen': true,
      });

      // Send notification
      await _firestore.collection('adminNotifications').add({
        'title': 'تم إعادة تفعيل بازارك',
        'message': 'يمكنك الآن استقبال الطلبات مجدداً',
        'targetType': 'single',
        'targetBazaarId': bazaarId,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'type': 'reactivation',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة تفعيل البازار'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadBazaars();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
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
        title: const Text('إدارة التعليقات'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadBazaars,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.shop, size: 18),
                  const SizedBox(width: 6),
                  Text('نشط (${_activeBazaars.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.shield_slash, size: 18),
                  const SizedBox(width: 6),
                  Text('معلق (${_suspendedBazaars.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveTab(),
                _buildSuspendedTab(),
              ],
            ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeBazaars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.shop, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد بازارات نشطة',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeBazaars.length,
      itemBuilder: (context, index) {
        final bazaar = _activeBazaars[index];
        return _buildBazaarCard(bazaar, false);
      },
    );
  }

  Widget _buildSuspendedTab() {
    if (_suspendedBazaars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.tick_circle,
                size: 64, color: AppColors.success.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('لا توجد بازارات معلقة',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suspendedBazaars.length,
      itemBuilder: (context, index) {
        final bazaar = _suspendedBazaars[index];
        return _buildBazaarCard(bazaar, true);
      },
    );
  }

  Widget _buildBazaarCard(Map<String, dynamic> bazaar, bool isSuspended) {
    final suspendedAt = bazaar['suspendedAt'] != null
        ? DateTime.tryParse(bazaar['suspendedAt'])
        : null;
    final suspensionEndDate = bazaar['suspensionEndDate'] != null
        ? DateTime.tryParse(bazaar['suspensionEndDate'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isSuspended
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (bazaar['nameAr'] ?? 'B')[0],
                    style: TextStyle(
                      color: isSuspended ? AppColors.error : AppColors.primary,
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
                        bazaar['nameAr'] ?? 'بازار',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        bazaar['governorate'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isSuspended)
                  ElevatedButton.icon(
                    onPressed: () => _reactivateBazaar(bazaar['id']),
                    icon: const Icon(Iconsax.refresh, size: 16),
                    label: const Text('إعادة تفعيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _showSuspendDialog(bazaar),
                    icon: const Icon(Iconsax.shield_slash, size: 16),
                    label: const Text('تعليق'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
            if (isSuspended && bazaar['suspensionReason'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.warning_2,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        const Text(
                          'سبب التعليق:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bazaar['suspensionReason'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    if (suspendedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'معلق منذ: ${DateFormat('dd/MM/yyyy').format(suspendedAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                    if (suspensionEndDate != null) ...[
                      Text(
                        'ينتهي في: ${DateFormat('dd/MM/yyyy').format(suspensionEndDate)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.info),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
