import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/sub_order_model.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/sub_order_repository.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final SubOrderRepository _subOrderRepository = SubOrderRepository();

  Order? _order;
  List<SubOrder> _subOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    debugPrint('🔍 OrderTracking: Loading order ID: ${widget.orderId}');
    try {
      final order = await _orderRepository.getOrder(widget.orderId);
      debugPrint(
          '📦 OrderTracking: Order ${order != null ? 'FOUND - ${order.id}' : 'NOT FOUND'}');
      List<SubOrder> subOrders = [];
      if (order != null) {
        // Pass customerId to satisfy Firebase security rules
        subOrders = await _subOrderRepository.getSubOrdersByParent(
          order.id,
          customerId: order.userId,
        );
        debugPrint('📦 OrderTracking: Found ${subOrders.length} sub-orders');
      }
      setState(() {
        _order = order;
        _subOrders = subOrders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ OrderTracking Error: $e');
      debugPrint('📍 StackTrace: $stackTrace');
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

  Color _getStatusColor(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.pending:
        return Colors.orange;
      case SubOrderStatus.accepted:
        return Colors.blue;
      case SubOrderStatus.preparing:
        return Colors.purple;
      case SubOrderStatus.readyForPickup:
        return AppColors.egyptianGold;
      case SubOrderStatus.shipping:
        return Colors.indigo;
      case SubOrderStatus.delivered:
        return Colors.green;
      case SubOrderStatus.rejected:
        return Colors.red;
      case SubOrderStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('تتبع الطلب',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildNotFound()
              : RefreshIndicator(
                  onRefresh: _loadOrder,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Header
                        _buildOrderHeader(),
                        const SizedBox(height: 20),

                        // Sub Orders
                        const Text('طلبات البازارات',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ..._subOrders
                            .map((subOrder) => _buildSubOrderCard(subOrder)),

                        // Payment Info
                        if (_order != null) ...[
                          const SizedBox(height: 20),
                          _buildPaymentInfo(),
                        ],
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
          Icon(Iconsax.box_remove, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('الطلب غير موجود', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.egyptianGold,
            const Color.fromRGBO(196, 148, 43, 0.8)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color.fromRGBO(196, 148, 43, 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رقم الطلب',
                      style: TextStyle(
                          color: const Color.fromRGBO(255, 255, 255, 0.8),
                          fontSize: 13)),
                  Text('#${_order!.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30)),
                child: Text(_getOverallStatus(),
                    style: TextStyle(
                        color: AppColors.egyptianGold,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Iconsax.calendar,
                  color: const Color.fromRGBO(255, 255, 255, 0.8), size: 18),
              const SizedBox(width: 8),
              Text(DateFormat('dd/MM/yyyy - HH:mm').format(_order!.createdAt),
                  style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.9))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Iconsax.location,
                  color: const Color.fromRGBO(255, 255, 255, 0.8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_order!.address,
                    style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.9)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubOrderCard(SubOrder subOrder) {
    final statusColor = _getStatusColor(subOrder.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Iconsax.shop, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subOrder.bazaarName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(subOrder.statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Text('${subOrder.subtotal.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.egyptianGold)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${subOrder.itemCount} منتج',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 12),
                // Timeline
                _buildMiniTimeline(subOrder.status),
              ],
            ),
          ),

          // QR Code Section
          if (subOrder.qrCode != null &&
              (subOrder.status == SubOrderStatus.readyForPickup ||
                  subOrder.status == SubOrderStatus.accepted)) ...[
            const Divider(height: 1),
            ExpansionTile(
              title: const Text('عرض كود الاستلام',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              leading: const Icon(Iconsax.scan_barcode),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!)),
                        child: QrImageView(data: subOrder.qrCode!, size: 180),
                      ),
                      const SizedBox(height: 12),
                      Text('امسح هذا الكود عند الاستلام',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniTimeline(SubOrderStatus currentStatus) {
    final steps = [
      ('معلق', SubOrderStatus.pending),
      ('مقبول', SubOrderStatus.accepted),
      ('قيد التجهيز', SubOrderStatus.preparing),
      ('جاهز', SubOrderStatus.readyForPickup),
      ('تم التسليم', SubOrderStatus.delivered),
    ];

    int currentIndex = 0;
    for (int i = 0; i < steps.length; i++) {
      if (steps[i].$2 == currentStatus) {
        currentIndex = i;
        break;
      }
      if (currentStatus == SubOrderStatus.shipping &&
          steps[i].$2 == SubOrderStatus.readyForPickup) {
        currentIndex = i;
        break;
      }
    }

    if (currentStatus == SubOrderStatus.rejected ||
        currentStatus == SubOrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(244, 67, 54, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.close_circle, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              currentStatus == SubOrderStatus.rejected
                  ? 'تم رفض الطلب'
                  : 'تم إلغاء الطلب',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentIndex;
        final isActive = index == currentIndex;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.egyptianGold
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(
                                color: AppColors.egyptianGold, width: 2)
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted
                            ? AppColors.egyptianGold
                            : Colors.grey[400],
                        fontWeight:
                            isCompleted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentIndex
                        ? AppColors.egyptianGold
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 10)
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
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                color: isDiscount
                    ? Colors.green
                    : (isTotal ? AppColors.egyptianGold : Colors.black),
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                fontSize: isTotal ? 18 : 14,
              )),
        ],
      ),
    );
  }
}
