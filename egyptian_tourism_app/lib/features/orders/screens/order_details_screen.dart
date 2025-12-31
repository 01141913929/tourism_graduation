import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/sub_order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/sub_order_repository.dart';
import '../../cart/screens/order_tracking_screen.dart';

/// شاشة تفاصيل الطلب للعميل
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final SubOrderRepository _subOrderRepository = SubOrderRepository();

  Order? _order;
  List<SubOrder> _subOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final order = await _orderRepository.getOrder(widget.orderId);
      List<SubOrder> subOrders = [];
      if (order != null) {
        subOrders = await _subOrderRepository.getSubOrdersByParent(order.id);
      }
      setState(() {
        _order = order;
        _subOrders = subOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getOverallStatus() {
    if (_subOrders.isEmpty) return 'جاري المعالجة';

    final statuses = _subOrders.map((s) => s.status).toList();

    if (statuses.every((s) => s == SubOrderStatus.delivered))
      return 'تم التسليم';
    if (statuses.every((s) => s == SubOrderStatus.cancelled)) return 'ملغي';
    if (statuses.every((s) => s == SubOrderStatus.rejected)) return 'مرفوض';
    if (statuses.any((s) => s == SubOrderStatus.shipping)) return 'قيد الشحن';
    if (statuses.any((s) => s == SubOrderStatus.readyForPickup))
      return 'جاهز للاستلام';
    if (statuses.any((s) => s == SubOrderStatus.preparing))
      return 'قيد التجهيز';
    if (statuses.any((s) => s == SubOrderStatus.accepted)) return 'تم القبول';

    return 'في انتظار التأكيد';
  }

  Color _getStatusColor() {
    final status = _getOverallStatus();
    switch (status) {
      case 'تم التسليم':
        return Colors.green;
      case 'ملغي':
      case 'مرفوض':
        return Colors.red;
      case 'قيد الشحن':
      case 'جاهز للاستلام':
        return AppColors.gold;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Iconsax.location),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderTrackingScreen(orderId: widget.orderId),
                ),
              ),
              tooltip: 'تتبع الطلب',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildNotFound()
              : RefreshIndicator(
                  onRefresh: _loadOrderDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header
                        _buildOrderHeader(),
                        const SizedBox(height: 20),

                        // Timeline Summary
                        _buildTimelineSummary(),
                        const SizedBox(height: 20),

                        // Sub Orders
                        const Text('تفاصيل الطلبات',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ..._subOrders
                            .map((subOrder) => _buildSubOrderCard(subOrder)),

                        // Delivery Address
                        const SizedBox(height: 20),
                        _buildAddressCard(),

                        // Payment Summary
                        const SizedBox(height: 20),
                        _buildPaymentSummary(),

                        // Actions
                        const SizedBox(height: 24),
                        _buildActions(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.bag_cross, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('الطلب غير موجود'),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final statusColor = _getStatusColor();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الطلب',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '#${_order!.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getOverallStatus(),
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Iconsax.calendar,
                  DateFormat('dd/MM/yyyy').format(_order!.createdAt)),
              const SizedBox(width: 24),
              _buildInfoItem(Iconsax.clock,
                  DateFormat('hh:mm a').format(_order!.createdAt)),
              const SizedBox(width: 24),
              _buildInfoItem(Iconsax.shop, '${_order!.bazaarCount} بازار'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ],
    );
  }

  Widget _buildTimelineSummary() {
    final steps = [
      ('تم الطلب', true),
      (
        'تم القبول',
        _subOrders.any((s) => s.status.index >= SubOrderStatus.accepted.index)
      ),
      (
        'قيد التجهيز',
        _subOrders.any((s) => s.status.index >= SubOrderStatus.preparing.index)
      ),
      (
        'تم التسليم',
        _subOrders.every((s) => s.status == SubOrderStatus.delivered)
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: steps.asMap().entries.expand((entry) {
          final isLast = entry.key == steps.length - 1;
          final step = entry.value;
          final isCompleted = step.$2;

          return [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.gold : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  step.$1,
                  style: TextStyle(
                    fontSize: 10,
                    color: isCompleted ? AppColors.gold : Colors.grey[400],
                    fontWeight:
                        isCompleted ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: isCompleted && steps[entry.key + 1].$2
                      ? AppColors.gold
                      : Colors.grey[300],
                ),
              ),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildSubOrderCard(SubOrder subOrder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Iconsax.shop, color: AppColors.gold),
        ),
        title: Text(subOrder.bazaarName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getSubOrderStatusColor(subOrder.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subOrder.statusText,
            style: TextStyle(
              color: _getSubOrderStatusColor(subOrder.status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Text(
          '${subOrder.subtotal.toStringAsFixed(0)} ج.م',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
                  subOrder.items.map((item) => _buildOrderItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: Icon(Iconsax.image, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (item.selectedSize.isNotEmpty)
                  Text('المقاس: ${item.selectedSize}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${item.price.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('x${item.quantity}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSubOrderStatusColor(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return Colors.orange;
      case SubOrderStatus.accepted:
        return Colors.blue;
      case SubOrderStatus.preparing:
        return Colors.purple;
      case SubOrderStatus.readyForPickup:
        return AppColors.gold;
      case SubOrderStatus.shipping:
        return Colors.indigo;
      case SubOrderStatus.delivered:
        return Colors.green;
      case SubOrderStatus.rejected:
      case SubOrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.location, color: AppColors.secondaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('عنوان التوصيل',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_order!.address,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الدفع',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildPaymentRow('المجموع الفرعي',
              '${_order!.totalAmount.toStringAsFixed(0)} ج.م'),
          _buildPaymentRow(
              'الشحن', '${_order!.shipping.toStringAsFixed(0)} ج.م'),
          _buildPaymentRow(
              'الضريبة', '${_order!.taxes.toStringAsFixed(0)} ج.م'),
          if (_order!.discount > 0)
            _buildPaymentRow(
                'الخصم', '-${_order!.discount.toStringAsFixed(0)} ج.م',
                isDiscount: true),
          const Divider(height: 24),
          _buildPaymentRow(
              'الإجمالي', '${_order!.total.toStringAsFixed(0)} ج.م',
              isTotal: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.card, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(_order!.paymentMethod,
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: isTotal ? Colors.black : Colors.grey[600],
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                color: isDiscount
                    ? Colors.green
                    : (isTotal ? AppColors.gold : Colors.black),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                fontSize: isTotal ? 18 : 14,
              )),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final canCancel = _subOrders.any((s) => s.status == SubOrderStatus.pending);
    final isDelivered =
        _subOrders.every((s) => s.status == SubOrderStatus.delivered);

    return Row(
      children: [
        if (canCancel)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showCancelDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Iconsax.close_circle, size: 20),
              label: const Text('إلغاء الطلب'),
            ),
          ),
        if (canCancel && isDelivered) const SizedBox(width: 12),
        if (isDelivered)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to reviews
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Iconsax.star, size: 20),
              label: const Text('تقييم الطلب'),
            ),
          ),
        if (!canCancel && !isDelivered)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        OrderTrackingScreen(orderId: widget.orderId)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Iconsax.location, size: 20),
              label: const Text('تتبع الطلب'),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement order cancellation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال طلب الإلغاء')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('نعم، إلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
