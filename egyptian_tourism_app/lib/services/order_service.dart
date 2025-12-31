import '../models/models.dart';
import '../models/sub_order_model.dart';
import '../models/bazaar_model.dart';
import '../repositories/order_repository.dart';
import '../repositories/sub_order_repository.dart';
import '../repositories/bazaar_repository.dart';
import '../repositories/product_repository.dart';
import 'notification_service.dart';

/// Service for handling order creation with split orders
class OrderService {
  final OrderRepository _orderRepository;
  final SubOrderRepository _subOrderRepository;
  final BazaarRepository _bazaarRepository;
  final ProductRepository _productRepository;

  OrderService({
    OrderRepository? orderRepository,
    SubOrderRepository? subOrderRepository,
    BazaarRepository? bazaarRepository,
    ProductRepository? productRepository,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _subOrderRepository = subOrderRepository ?? SubOrderRepository(),
        _bazaarRepository = bazaarRepository ?? BazaarRepository(),
        _productRepository = productRepository ?? ProductRepository();

  /// Create order with split sub-orders by bazaar
  /// This is the main method to call when customer completes checkout
  Future<Order> createOrderWithSubOrders({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required List<CartItem> cartItems,
    required String address,
    required String paymentMethod,
    required PaymentStatus paymentStatus,
    double discount = 0,
  }) async {
    // 1. Group items by bazaar
    final Map<String, List<CartItem>> itemsByBazaar = {};
    for (final item in cartItems) {
      final bazaarId = item.product.bazaarId;
      itemsByBazaar.putIfAbsent(bazaarId, () => []);
      itemsByBazaar[bazaarId]!.add(item);
    }

    // 2. Calculate totals
    final totalAmount = cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final taxes = totalAmount * 0.14; // 14% VAT
    final shipping = totalAmount > 0 ? 20.0 : 0.0;
    final totalItemCount = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // 3. Generate parent order ID
    final parentOrderId = _orderRepository.generateOrderId();

    // 4. Create sub-orders for each bazaar
    final List<String> subOrderIds = [];

    for (final entry in itemsByBazaar.entries) {
      final bazaarId = entry.key;
      final bazaarItems = entry.value;

      // Get bazaar info
      final bazaar = await _bazaarRepository.getBazaar(bazaarId);
      if (bazaar == null) continue;

      // Calculate sub-order subtotal
      final subtotal = bazaarItems.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );

      // Create order items
      final orderItems = bazaarItems
          .map((item) => OrderItem(
                productId: item.product.id,
                productName: item.product.nameAr,
                imageUrl: item.product.imageUrl,
                price: item.product.price,
                selectedSize: item.selectedSize,
                quantity: item.quantity,
                bazaarId: bazaarId,
                bazaarName: bazaar.nameAr,
              ))
          .toList();

      // Generate sub-order ID
      final subOrderId = _subOrderRepository.generateSubOrderId();

      // Create sub-order
      final subOrder = SubOrder(
        id: subOrderId,
        parentOrderId: parentOrderId,
        bazaarId: bazaarId,
        bazaarName: bazaar.nameAr,
        bazaarOwnerId: bazaar.ownerUserId,
        customerId: userId,
        customerName: userName,
        customerPhone: userPhone,
        deliveryAddress: address,
        items: orderItems,
        subtotal: subtotal,
        status: SubOrderStatus.pending,
        createdAt: DateTime.now(),
      );

      await _subOrderRepository.createSubOrder(subOrder);
      subOrderIds.add(subOrderId);

      // Notify Bazaar Owner
      try {
        await NotificationService().sendNotification(
          targetUserId: bazaar.ownerUserId,
          title: 'طلب جديد! 🎉',
          body:
              'لقد تلقيت طلبًا جديدًا من $userName بقيمة ${subtotal.toStringAsFixed(2)} ج.م',
          data: {
            'type': 'new_order',
            'orderId': subOrderId,
          },
        );
      } catch (e) {
        print('Error sending new order notification: $e');
      }
    }

    // 5. Create parent order
    final parentOrder = Order(
      id: parentOrderId,
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      subOrderIds: subOrderIds,
      totalAmount: totalAmount,
      taxes: taxes,
      shipping: shipping,
      discount: discount,
      address: address,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      createdAt: DateTime.now(),
      totalItemCount: totalItemCount,
      bazaarCount: itemsByBazaar.length,
    );

    await _orderRepository.createOrder(parentOrder);

    return parentOrder;
  }

  /// Get order with all sub-orders populated
  Future<Map<String, dynamic>?> getOrderWithSubOrders(String orderId) async {
    final order = await _orderRepository.getOrder(orderId);
    if (order == null) return null;

    final subOrders = await _subOrderRepository.getSubOrdersByParent(orderId);

    return {
      'order': order,
      'subOrders': subOrders,
    };
  }

  /// Cancel an entire order (cancels all sub-orders)
  Future<void> cancelOrder(String orderId) async {
    final subOrders = await _subOrderRepository.getSubOrdersByParent(orderId);

    for (final subOrder in subOrders) {
      await _subOrderRepository.updateSubOrderStatus(
        subOrder.id,
        SubOrderStatus.cancelled,
      );
    }

    await _orderRepository.cancelOrder(orderId);
  }

  /// Get overall order status based on sub-orders
  String getOverallOrderStatus(List<SubOrder> subOrders) {
    if (subOrders.isEmpty) return 'غير معروف';

    final allDelivered = subOrders.every(
      (s) => s.status == SubOrderStatus.delivered,
    );
    if (allDelivered) return 'تم التسليم';

    final anyRejected = subOrders.any(
      (s) => s.status == SubOrderStatus.rejected,
    );
    final allCancelled = subOrders.every(
      (s) => s.status == SubOrderStatus.cancelled,
    );
    if (allCancelled) return 'ملغي';

    final anyShipping = subOrders.any(
      (s) => s.status == SubOrderStatus.shipping,
    );
    if (anyShipping) return 'قيد الشحن';

    final anyPreparing = subOrders.any(
      (s) =>
          s.status == SubOrderStatus.preparing ||
          s.status == SubOrderStatus.readyForPickup,
    );
    if (anyPreparing) return 'قيد التحضير';

    final anyAccepted = subOrders.any(
      (s) => s.status == SubOrderStatus.accepted,
    );
    if (anyAccepted) return 'تمت الموافقة';

    final anyPending = subOrders.any(
      (s) => s.status == SubOrderStatus.pending,
    );
    if (anyPending) return 'بانتظار الموافقة';

    return 'قيد المعالجة';
  }
}
