import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/colors.dart';
import '../models/sub_order_model.dart';

/// شاشة تعديل الطلب - الرفض الجزئي / تعديل الكميات
class PartialOrderEditScreen extends StatefulWidget {
  final SubOrder order;

  const PartialOrderEditScreen({super.key, required this.order});

  @override
  State<PartialOrderEditScreen> createState() => _PartialOrderEditScreenState();
}

class _PartialOrderEditScreenState extends State<PartialOrderEditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late List<OrderItemEdit> _editableItems;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editableItems = widget.order.items
        .map((item) => OrderItemEdit(
              item: item,
              isIncluded: true,
              newQuantity: item.quantity,
            ))
        .toList();
  }

  double get _newSubtotal {
    double total = 0;
    for (final edit in _editableItems) {
      if (edit.isIncluded) {
        total += edit.item.price * edit.newQuantity;
      }
    }
    return total;
  }

  int get _includedItemsCount {
    return _editableItems.where((e) => e.isIncluded).length;
  }

  Future<void> _saveChanges() async {
    if (_includedItemsCount == 0) {
      _showRejectAllDialog();
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Build new items list
      final newItems = _editableItems
          .where((e) => e.isIncluded)
          .map((e) => {
                'productId': e.item.productId,
                'productName': e.item.productName,
                'imageUrl': e.item.imageUrl,
                'price': e.item.price,
                'quantity': e.newQuantity,
                'selectedSize': e.item.selectedSize,
              })
          .toList();

      // Update order in Firestore
      await _firestore.collection('subOrders').doc(widget.order.id).update({
        'items': newItems,
        'subtotal': _newSubtotal,
        'status': 'accepted',
        'acceptedAt': DateTime.now().toIso8601String(),
        'modifiedByBazaar': true,
        'modificationNote': 'تم تعديل الطلب من قبل البازار',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات وقبول الطلب'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showRejectAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: Colors.orange),
            SizedBox(width: 8),
            Text('رفض الطلب'),
          ],
        ),
        content: const Text(
          'لقد ألغيت جميع المنتجات. هل تريد رفض الطلب بالكامل؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، رفض الطلب'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectOrder() async {
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('subOrders').doc(widget.order.id).update({
        'status': 'rejected',
        'rejectionReason': 'تم رفض جميع المنتجات',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفض الطلب'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تعديل الطلب'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Reset all to original
              setState(() {
                for (var edit in _editableItems) {
                  edit.isIncluded = true;
                  edit.newQuantity = edit.item.quantity;
                }
              });
            },
            icon: const Icon(Iconsax.refresh, size: 18),
            label: const Text('استعادة'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'يمكنك حذف منتجات أو تعديل الكميات قبل قبول الطلب',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _editableItems.length,
              itemBuilder: (context, index) {
                return _buildEditableItem(_editableItems[index], index);
              },
            ),
          ),

          // Bottom summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_includedItemsCount من ${_editableItems.length} منتجات',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'المجموع: ',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              Text(
                                '${_newSubtotal.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_newSubtotal != widget.order.subtotal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'تم التعديل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'حفظ التعديلات وقبول الطلب',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(OrderItemEdit edit, int index) {
    final item = edit.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: edit.isIncluded ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: edit.isIncluded
              ? Colors.transparent
              : Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: edit.isIncluded
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]
            : null,
      ),
      child: Row(
        children: [
          // Toggle inclusion
          Checkbox(
            value: edit.isIncluded,
            onChanged: (value) {
              setState(() {
                edit.isIncluded = value ?? false;
              });
            },
            activeColor: AppColors.success,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),

          // Product image
          Opacity(
            opacity: edit.isIncluded ? 1 : 0.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Iconsax.box, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product info
          Expanded(
            child: Opacity(
              opacity: edit.isIncluded ? 1 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          edit.isIncluded ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.price.toStringAsFixed(0)} ج.م × ${edit.newQuantity}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'المقاس: ${item.selectedSize}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),

          // Quantity controls
          if (edit.isIncluded)
            Column(
              children: [
                Row(
                  children: [
                    _buildQuantityButton(
                      icon: Iconsax.minus,
                      onPressed: edit.newQuantity > 1
                          ? () => setState(() => edit.newQuantity--)
                          : null,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${edit.newQuantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Iconsax.add,
                      onPressed: () => setState(() => edit.newQuantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(item.price * edit.newQuantity).toStringAsFixed(0)} ج.م',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'مستبعد',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}

/// Helper class for editable order items
class OrderItemEdit {
  final OrderItem item;
  bool isIncluded;
  int newQuantity;

  OrderItemEdit({
    required this.item,
    required this.isIncluded,
    required this.newQuantity,
  });
}
