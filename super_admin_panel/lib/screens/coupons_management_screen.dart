import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/colors.dart';

/// شاشة إدارة الكوبونات للمدير
class CouponsManagementScreen extends StatefulWidget {
  const CouponsManagementScreen({super.key});

  @override
  State<CouponsManagementScreen> createState() =>
      _CouponsManagementScreenState();
}

class _CouponsManagementScreenState extends State<CouponsManagementScreen> {
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
      final snapshot = await _firestore
          .collection('coupons')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _coupons =
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading coupons: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddCouponDialog(
        onSave: (coupon) async {
          try {
            await _firestore.collection('coupons').add({
              ...coupon,
              'createdAt': DateTime.now().toIso8601String(),
              'usedCount': 0,
            });
            _loadCoupons();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم إضافة الكوبون بنجاح'),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleCouponStatus(String id, bool isActive) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(id)
          .update({'isActive': !isActive});
      _loadCoupons();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCoupon(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكوبون'),
        content: const Text('هل أنت متأكد من حذف هذا الكوبون؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('coupons').doc(id).delete();
        _loadCoupons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم حذف الكوبون'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة الكوبونات'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: _showAddCouponDialog,
            tooltip: 'إضافة كوبون',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCoupons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _coupons.length,
                    itemBuilder: (context, index) =>
                        _buildCouponCard(_coupons[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: const Text('إضافة كوبون', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.ticket_discount, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد كوبونات'),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddCouponDialog,
            icon: const Icon(Iconsax.add),
            label: const Text('إضافة كوبون جديد'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isActive = coupon['isActive'] as bool? ?? true;
    final type = coupon['type'] as String? ?? 'percentage';
    final value = (coupon['value'] as num?)?.toDouble() ?? 0;
    final endDate = coupon['endDate'] != null
        ? DateTime.parse(coupon['endDate'] as String)
        : DateTime.now();
    final isExpired = endDate.isBefore(DateTime.now());
    final usedCount = coupon['usedCount'] as int? ?? 0;
    final usageLimit = coupon['usageLimit'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            isExpired ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive && !isExpired
                        ? AppColors.success.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon['code'] as String? ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isActive && !isExpired
                          ? AppColors.success
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    type == 'percentage'
                        ? '${value.toStringAsFixed(0)}%'
                        : '${value.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleCouponStatus(coupon['id'], isActive),
                  activeColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              coupon['nameAr'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            if (coupon['descriptionAr'] != null) ...[
              const SizedBox(height: 4),
              Text(
                coupon['descriptionAr'] as String,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                _buildStatChip(
                    Iconsax.calendar,
                    'ينتهي: ${DateFormat('dd/MM').format(endDate)}',
                    isExpired ? Colors.red : null),
                const SizedBox(width: 12),
                _buildStatChip(
                    Iconsax.chart,
                    'استخدام: $usedCount${usageLimit != null ? '/$usageLimit' : ''}',
                    null),
                if (coupon['minOrderAmount'] != null) ...[
                  const SizedBox(width: 12),
                  _buildStatChip(
                      Iconsax.money,
                      'حد أدنى: ${(coupon['minOrderAmount'] as num).toStringAsFixed(0)}',
                      null),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteCoupon(coupon['id']),
                  icon: Icon(Iconsax.trash, size: 18, color: Colors.red[400]),
                  label: Text('حذف', style: TextStyle(color: Colors.red[400])),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color? color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textSecondary).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: color ?? AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Dialog لإضافة كوبون جديد
class _AddCouponDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _AddCouponDialog({required this.onSave});

  @override
  State<_AddCouponDialog> createState() => _AddCouponDialogState();
}

class _AddCouponDialogState extends State<_AddCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _usageLimitController = TextEditingController();

  String _type = 'percentage';
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إضافة كوبون جديد',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Code
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'كود الخصم *', hintText: 'مثال: SAVE20'),
                  validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم الكوبون *'),
                  validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Type and Value
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        items: const [
                          DropdownMenuItem(
                              value: 'percentage', child: Text('نسبة مئوية')),
                          DropdownMenuItem(
                              value: 'fixed', child: Text('مبلغ ثابت')),
                        ],
                        onChanged: (v) => setState(() => _type = v!),
                        decoration:
                            const InputDecoration(labelText: 'نوع الخصم'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'القيمة *',
                          suffixText: _type == 'percentage' ? '%' : 'ج.م',
                        ),
                        validator: (v) => v?.isEmpty == true ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Min order and max discount
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'حد أدنى للطلب', suffixText: 'ج.م'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxDiscountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'حد أقصى للخصم', suffixText: 'ج.م'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // End date and usage limit
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'تاريخ الانتهاء'),
                          child:
                              Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _usageLimitController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'حد الاستخدام', hintText: 'غير محدود'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: const Text('حفظ',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave({
      'code': _codeController.text.trim().toUpperCase(),
      'nameAr': _nameController.text.trim(),
      'descriptionAr': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'type': _type,
      'value': double.tryParse(_valueController.text) ?? 0,
      'minOrderAmount': double.tryParse(_minOrderController.text),
      'maxDiscount': double.tryParse(_maxDiscountController.text),
      'startDate': DateTime.now().toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'usageLimit': int.tryParse(_usageLimitController.text),
      'isActive': true,
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _maxDiscountController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }
}
