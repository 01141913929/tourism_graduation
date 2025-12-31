import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/order_provider.dart';
import '../core/constants/colors.dart';
import '../models/sub_order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final SubOrder order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy - HH:mm', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('#${order.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.call),
            onPressed: () {
              // Call customer
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStatusColor(order.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.statusText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                        Text(
                          dateFormat.format(order.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer info
            const Text(
              'معلومات العميل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Iconsax.user, 'الاسم', order.customerName),
                  const Divider(height: 24),
                  _buildInfoRow(Iconsax.call, 'الهاتف', order.customerPhone),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Iconsax.location,
                    'العنوان',
                    order.deliveryAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Products
            const Text(
              'المنتجات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children:
                    order.items.map((item) => _buildProductItem(item)).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المجموع',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${order.subtotal.toStringAsFixed(0)} ج.م',
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
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (order.status != SubOrderStatus.delivered &&
                order.status != SubOrderStatus.rejected &&
                order.status != SubOrderStatus.cancelled)
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(OrderItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppColors.background,
                child: const Icon(Iconsax.box, color: AppColors.textHint),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'المقاس: ${item.selectedSize} • الكمية: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.totalPrice.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    SubOrderStatus? nextStatus;
    String buttonText = '';

    switch (order.status) {
      case SubOrderStatus.accepted:
        nextStatus = SubOrderStatus.preparing;
        buttonText = 'بدء التحضير';
        break;
      case SubOrderStatus.preparing:
        nextStatus = SubOrderStatus.readyForPickup;
        buttonText = 'جاهز للاستلام';
        break;
      case SubOrderStatus.readyForPickup:
        nextStatus = SubOrderStatus.delivered;
        buttonText = 'تم التسليم';
        break;
      case SubOrderStatus.shipping:
        nextStatus = SubOrderStatus.delivered;
        buttonText = 'تم التسليم';
        break;
      default:
        return const SizedBox();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () async {
          if (nextStatus != null) {
            final orderProvider = context.read<OrderProvider>();
            final success = await orderProvider.updateOrderStatus(
              order.id,
              nextStatus,
            );
            if (context.mounted) {
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث حالة الطلب'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return AppColors.pending;
      case SubOrderStatus.accepted:
        return AppColors.accepted;
      case SubOrderStatus.preparing:
        return AppColors.preparing;
      case SubOrderStatus.readyForPickup:
        return AppColors.readyForPickup;
      case SubOrderStatus.shipping:
        return AppColors.shipping;
      case SubOrderStatus.delivered:
        return AppColors.delivered;
      case SubOrderStatus.rejected:
        return AppColors.rejected;
      case SubOrderStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  IconData _getStatusIcon(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return Iconsax.timer_1;
      case SubOrderStatus.accepted:
        return Iconsax.tick_circle;
      case SubOrderStatus.preparing:
        return Iconsax.box;
      case SubOrderStatus.readyForPickup:
        return Iconsax.archive_tick;
      case SubOrderStatus.shipping:
        return Iconsax.truck_fast;
      case SubOrderStatus.delivered:
        return Iconsax.tick_circle5;
      case SubOrderStatus.rejected:
        return Iconsax.close_circle;
      case SubOrderStatus.cancelled:
        return Iconsax.close_circle;
    }
  }
}
