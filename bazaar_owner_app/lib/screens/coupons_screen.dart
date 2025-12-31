import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// شاشة إدارة الكوبونات
class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      if (bazaarId == null) return;

      final snapshot = await _firestore
          .collection('coupons')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      _coupons =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      // ترتيب حسب التاريخ
      _coupons.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('Error loading coupons: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleCouponStatus(String couponId, bool isActive) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update({
        'isActive': isActive,
      });
      _loadCoupons();
    } catch (e) {
      debugPrint('Error toggling coupon: $e');
    }
  }

  Future<void> _deleteCoupon(String couponId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكوبون'),
        content: const Text('هل أنت متأكد من حذف هذا الكوبون؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('coupons').doc(couponId).delete();
        _loadCoupons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الكوبون'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting coupon: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الكوبونات'),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: AppColors.white),
        label:
            const Text('كوبون جديد', style: TextStyle(color: AppColors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: _coupons.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _coupons.length,
                      itemBuilder: (context, index) =>
                          _buildCouponCard(_coupons[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.ticket_discount,
              size: 64,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد كوبونات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ كوبون خصم لجذب العملاء',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCouponDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Iconsax.add),
            label: const Text('إنشاء كوبون'),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final code = coupon['code'] as String? ?? '';
    final discount = (coupon['discount'] as num?)?.toInt() ?? 0;
    final discountType = coupon['discountType'] as String? ?? 'percentage';
    final usageCount = (coupon['usageCount'] as num?)?.toInt() ?? 0;
    final maxUsage = (coupon['maxUsage'] as num?)?.toInt();
    final isActive = coupon['isActive'] as bool? ?? true;
    final expiresAt = coupon['expiresAt'] != null
        ? DateTime.tryParse(coupon['expiresAt'])
        : null;
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isActive && !isExpired ? AppColors.primaryGradient : null,
        color: isActive && !isExpired ? null : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive && !isExpired
            ? AppColors.primaryShadow
            : AppColors.softShadow,
      ),
      child: Stack(
        children: [
          // التصميم المزخرف
          if (isActive && !isExpired)
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withOpacity(0.1),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // أيقونة الكوبون
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive && !isExpired
                            ? AppColors.white.withOpacity(0.2)
                            : AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.ticket_discount,
                        color: isActive && !isExpired
                            ? AppColors.white
                            : AppColors.warning,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // الكود والخصم
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isActive && !isExpired
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            discountType == 'percentage'
                                ? 'خصم $discount%'
                                : 'خصم $discount ج.م',
                            style: TextStyle(
                              fontSize: 14,
                              color: isActive && !isExpired
                                  ? AppColors.white.withOpacity(0.9)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toggle
                    Switch(
                      value: isActive && !isExpired,
                      onChanged: isExpired
                          ? null
                          : (value) => _toggleCouponStatus(coupon['id'], value),
                      activeColor: AppColors.white,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات الاستخدام
                Row(
                  children: [
                    _buildCouponStat(
                      icon: Iconsax.people,
                      label: 'استخدام',
                      value: maxUsage != null
                          ? '$usageCount / $maxUsage'
                          : '$usageCount',
                      isActive: isActive && !isExpired,
                    ),
                    const SizedBox(width: 24),
                    if (expiresAt != null)
                      _buildCouponStat(
                        icon: Iconsax.calendar,
                        label: isExpired ? 'انتهى' : 'ينتهي',
                        value: dateFormat.format(expiresAt),
                        isActive: isActive && !isExpired,
                        isWarning: isExpired,
                      ),
                    const Spacer(),

                    // حذف
                    IconButton(
                      onPressed: () => _deleteCoupon(coupon['id']),
                      icon: Icon(
                        Iconsax.trash,
                        color: isActive && !isExpired
                            ? AppColors.white.withOpacity(0.8)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),

                // تحذير انتهاء الصلاحية
                if (isExpired)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.warning_2,
                            size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text(
                          'انتهت صلاحية هذا الكوبون',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponStat({
    required IconData icon,
    required String label,
    required String value,
    bool isActive = true,
    bool isWarning = false,
  }) {
    final color = isWarning
        ? AppColors.error
        : (isActive ? AppColors.white : AppColors.textSecondary);

    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.8)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final maxUsageController = TextEditingController();
    String discountType = 'percentage';
    DateTime? expiresAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
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

              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'إنشاء كوبون جديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // كود الكوبون
                      const Text('كود الكوبون',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'مثال: SAVE20',
                          prefixIcon: const Icon(Iconsax.ticket),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // نوع الخصم
                      const Text('نوع الخصم',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setDialogState(
                                  () => discountType = 'percentage'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: discountType == 'percentage'
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: discountType == 'percentage'
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.percentage_square,
                                      color: discountType == 'percentage'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'نسبة مئوية',
                                      style: TextStyle(
                                        color: discountType == 'percentage'
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => discountType = 'fixed'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: discountType == 'fixed'
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: discountType == 'fixed'
                                        ? AppColors.primary
                                        : AppColors.divider,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.money,
                                      color: discountType == 'fixed'
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'مبلغ ثابت',
                                      style: TextStyle(
                                        color: discountType == 'fixed'
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // قيمة الخصم
                      Text(
                        discountType == 'percentage'
                            ? 'النسبة (%)'
                            : 'المبلغ (ج.م)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: discountType == 'percentage' ? '10' : '50',
                          suffixText:
                              discountType == 'percentage' ? '%' : 'ج.م',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // الحد الأقصى للاستخدام
                      const Text('الحد الأقصى للاستخدام (اختياري)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: maxUsageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'غير محدود',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // تاريخ الانتهاء
                      const Text('تاريخ الانتهاء (اختياري)',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => expiresAt = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.calendar,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                expiresAt != null
                                    ? DateFormat('dd MMM yyyy', 'ar')
                                        .format(expiresAt!)
                                    : 'اختيار التاريخ',
                                style: TextStyle(
                                  color: expiresAt != null
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Save button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _saveCoupon(
                        code: codeController.text.trim().toUpperCase(),
                        discount: int.tryParse(discountController.text) ?? 0,
                        discountType: discountType,
                        maxUsage: int.tryParse(maxUsageController.text),
                        expiresAt: expiresAt,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إنشاء الكوبون',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
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

  Future<void> _saveCoupon({
    required String code,
    required int discount,
    required String discountType,
    int? maxUsage,
    DateTime? expiresAt,
  }) async {
    if (code.isEmpty || discount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال كود وقيمة خصم صحيحة'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      await _firestore.collection('coupons').add({
        'code': code,
        'discount': discount,
        'discountType': discountType,
        'maxUsage': maxUsage,
        'usageCount': 0,
        'bazaarId': bazaarId,
        'isActive': true,
        'expiresAt': expiresAt?.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      _loadCoupons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الكوبون بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving coupon: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إنشاء الكوبون'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
