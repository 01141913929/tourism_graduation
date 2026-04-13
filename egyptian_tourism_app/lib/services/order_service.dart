import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/models.dart';
import '../models/sub_order_model.dart';
import '../repositories/order_repository.dart';
import '../repositories/sub_order_repository.dart';
import '../repositories/bazaar_repository.dart';
import '../repositories/product_repository.dart';
import 'notification_service.dart';

/// Enhanced Order Service with Batch Writes, Pagination, and Real-time Listeners
class OrderService {
  final OrderRepository _orderRepository;
  final SubOrderRepository _subOrderRepository;
  final BazaarRepository _bazaarRepository;
  final ProductRepository _productRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real-time stream subscriptions
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  final StreamController<List<Order>> _ordersStreamController =
      StreamController<List<Order>>.broadcast();

  // Pagination configuration
  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreOrders = true;

  OrderService({
    OrderRepository? orderRepository,
    SubOrderRepository? subOrderRepository,
    BazaarRepository? bazaarRepository,
    ProductRepository? productRepository,
  })  : _orderRepository = orderRepository ?? OrderRepository(),
        _subOrderRepository = subOrderRepository ?? SubOrderRepository(),
        _bazaarRepository = bazaarRepository ?? BazaarRepository(),
        _productRepository = productRepository ?? ProductRepository();

  /// Stream of orders for real-time updates
  Stream<List<Order>> get ordersStream => _ordersStreamController.stream;

  /// Check if more orders are available for pagination
  bool get hasMoreOrders => _hasMoreOrders;

  // ==================== BATCH OPERATIONS ====================

  /// Create order with split sub-orders by bazaar using Batch Writes
  /// This ensures atomic operations for better reliability
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
    // Create a batch for atomic operations
    final WriteBatch batch = _firestore.batch();

    try {
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
      final List<String> subOrderIds = [];
      final List<Map<String, dynamic>> notificationData = [];

      // 4. Prepare sub-orders for batch
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

        // Add sub-order to batch
        final subOrderRef = _firestore.collection('subOrders').doc(subOrderId);
        batch.set(subOrderRef, subOrder.toJson());
        subOrderIds.add(subOrderId);

        // Store notification data for later
        notificationData.add({
          'ownerId': bazaar.ownerUserId,
          'userName': userName,
          'subtotal': subtotal,
          'subOrderId': subOrderId,
        });

        // Update product stock in batch
        for (final item in bazaarItems) {
          final productRef =
              _firestore.collection('products').doc(item.product.id);
          batch.update(productRef, {
            'stock': FieldValue.increment(-item.quantity),
            'soldCount': FieldValue.increment(item.quantity),
          });
        }
      }

      // 5. Create parent order in batch
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

      final orderRef = _firestore.collection('orders').doc(parentOrderId);
      batch.set(orderRef, parentOrder.toJson());

      // 6. Update user's order count in batch
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'orderCount': FieldValue.increment(1),
        'totalSpent': FieldValue.increment(totalAmount),
        'lastOrderAt': FieldValue.serverTimestamp(),
      });

      // 7. Commit the batch
      await batch.commit();
      debugPrint('✅ Order batch committed successfully');

      // 8. Send notifications after batch commit
      _sendOrderNotifications(notificationData);

      return parentOrder;
    } catch (e) {
      debugPrint('❌ Error creating order batch: $e');
      rethrow;
    }
  }

  /// Send notifications in parallel (non-blocking)
  void _sendOrderNotifications(List<Map<String, dynamic>> notificationData) {
    for (final data in notificationData) {
      NotificationService().sendNotification(
        targetUserId: data['ownerId'],
        title: '🌟 طلب جديد وصل يا مدير! 🎉',
        body:
            'عظيم جداً! 🥳<br>السائح ✨ <b>${data['userName']}</b> ✨ لسه طالب أوردر جديد بقيمة 💰 <b>${data['subtotal'].toStringAsFixed(2)} ج.م</b>.<br>جهّز الطلب بسرعة عشان تكسب تقييم خمس نجوم! ⭐',
        data: {
          'type': 'new_order',
          'orderId': data['subOrderId'],
        },
      );
    }
  }

  // ==================== PAGINATION ====================

  /// Get orders with pagination
  Future<List<Order>> getOrdersPaginated({
    required String userId,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _lastDocument = null;
        _hasMoreOrders = true;
      }

      Query query = _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) {
        return Order.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMoreOrders = snapshot.docs.length >= _pageSize;

      debugPrint(
          '📦 Loaded ${orders.length} orders (hasMore: $_hasMoreOrders)');
      return orders;
    } catch (e) {
      debugPrint('❌ Error fetching paginated orders: $e');
      return [];
    }
  }

  /// Load next page of orders
  Future<List<Order>> loadMoreOrders({required String userId}) async {
    if (!_hasMoreOrders) {
      debugPrint('⚠️ No more orders to load');
      return [];
    }
    return getOrdersPaginated(userId: userId);
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Start listening to orders in real-time
  void startOrdersRealTimeListener(String userId) {
    _ordersSubscription?.cancel();

    _ordersSubscription = _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        final orders = snapshot.docs.map((doc) {
          return Order.fromJson(doc.data());
        }).toList();

        _ordersStreamController.add(orders);
        debugPrint('🔄 Real-time update: ${orders.length} orders');
      },
      onError: (error) {
        debugPrint('❌ Orders listener error: $error');
        _ordersStreamController.addError(error);
      },
    );

    debugPrint('👂 Started orders real-time listener for user: $userId');
  }

  /// Listen to a specific order's sub-orders in real-time
  Stream<List<SubOrder>> getSubOrdersStream(String parentOrderId) {
    return _firestore
        .collection('subOrders')
        .where('parentOrderId', isEqualTo: parentOrderId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SubOrder.fromJson(doc.data());
      }).toList();
    });
  }

  /// Listen to a single sub-order status changes
  Stream<SubOrder?> getSubOrderStatusStream(String subOrderId) {
    return _firestore
        .collection('subOrders')
        .doc(subOrderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SubOrder.fromJson(doc.data()!);
    });
  }

  /// Stop real-time listener
  void stopOrdersRealTimeListener() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    debugPrint('🛑 Stopped orders real-time listener');
  }

  // ==================== ORDER OPERATIONS ====================

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

  /// Cancel an entire order using batch (cancels all sub-orders)
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    final WriteBatch batch = _firestore.batch();

    try {
      final subOrders = await _subOrderRepository.getSubOrdersByParent(orderId);

      for (final subOrder in subOrders) {
        final subOrderRef = _firestore.collection('subOrders').doc(subOrder.id);
        batch.update(subOrderRef, {
          'status': SubOrderStatus.cancelled.name,
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // Restore product stock
        for (final item in subOrder.items) {
          final productRef =
              _firestore.collection('products').doc(item.productId);
          batch.update(productRef, {
            'stock': FieldValue.increment(item.quantity),
            'soldCount': FieldValue.increment(-item.quantity),
          });
        }
      }

      final orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'isCancelled': true,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint('✅ Order cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      rethrow;
    }
  }

  /// Update sub-order status with notification
  Future<void> updateSubOrderStatus(
    String subOrderId,
    SubOrderStatus status, {
    String? note,
  }) async {
    try {
      await _firestore.collection('subOrders').doc(subOrderId).update({
        'status': status.name,
        'statusNote': note,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get sub-order to send notification to customer
      final subOrderDoc =
          await _firestore.collection('subOrders').doc(subOrderId).get();
      if (subOrderDoc.exists) {
        final subOrder = SubOrder.fromJson(subOrderDoc.data()!);

        // Send notification to customer
        await NotificationService().sendNotification(
          targetUserId: subOrder.customerId,
          title: _getStatusNotificationTitle(status),
          body: _getStatusNotificationBody(status, subOrder.bazaarName),
          data: {
            'type': 'order_status_update',
            'orderId': subOrderId,
            'status': status.name,
          },
        );
      }

      debugPrint('✅ Sub-order status updated to: ${status.name}');
    } catch (e) {
      debugPrint('❌ Error updating sub-order status: $e');
      rethrow;
    }
  }

  String _getStatusNotificationTitle(SubOrderStatus status) {
    switch (status) {
      case SubOrderStatus.accepted:
        return '✨ تم قبول طلبك بنجاح! ✅';
      case SubOrderStatus.preparing:
        return '👨‍🍳 جارٍ تحضير طلبك الرائع!';
      case SubOrderStatus.readyForPickup:
        return '🛍️ طلبك جاهز للاستلام!';
      case SubOrderStatus.shipping:
        return '🚚 طلبك في الطريق إليك!';
      case SubOrderStatus.delivered:
        return '🎉 تم توصيل طلبك بنجاح!';
      case SubOrderStatus.rejected:
        return '😔 نأسف، تم رفض طلبك ❌';
      case SubOrderStatus.cancelled:
        return '⚠️ تم إلغاء طلبك';
      default:
        return '🔔 تحديث جديد لطلبك';
    }
  }

  String _getStatusNotificationBody(SubOrderStatus status, String bazaarName) {
    switch (status) {
      case SubOrderStatus.accepted:
        return 'أخبار رائعة! 🥳<br>بازار <b>$bazaarName</b> وافق على طلبك وبدأ في تجهيزه فوراً.';
      case SubOrderStatus.preparing:
        return 'بازار <b>$bazaarName</b> يقوم الآن بتجهيز طلبك وتغليفه بكل حب 🎁.<br>استعد لاستلامه قريباً!';
      case SubOrderStatus.readyForPickup:
        return 'طلبك من <b>$bazaarName</b> جاهز الآن وينتظرك للاستلام في المحل 🏪.<br>نتمنى لك يوم سعيد!';
      case SubOrderStatus.shipping:
        return 'طلبك من <b>$bazaarName</b> غادر المحل وهو الآن في الطريق إليك 🛵.<br>تتبع طلبك من التطبيق.';
      case SubOrderStatus.delivered:
        return 'نتمنى أن ينال إعجابك! 😍<br>تم تسليم طلبك من <b>$bazaarName</b> بنجاح.<br>لا تنسَ تقييم تجربتك! ⭐';
      case SubOrderStatus.rejected:
        return 'نعتذر منك، لم يتمكن بازار <b>$bazaarName</b> من تلبية طلبك في الوقت الحالي.<br>الرجاء المحاولة لاحقاً أو اختيار منتجات أخرى.';
      case SubOrderStatus.cancelled:
        return 'لقد تم إلغاء طلبك من <b>$bazaarName</b> بناءً على رغبتك أو لوجود مشكلة.';
      default:
        return 'هناك تحديث جديد لحالة طلبك من <b>$bazaarName</b>.<br>افتح التطبيق لمعرفة التفاصيل.';
    }
  }

  /// Get overall order status based on sub-orders
  String getOverallOrderStatus(List<SubOrder> subOrders) {
    if (subOrders.isEmpty) return 'غير معروف';

    final allDelivered = subOrders.every(
      (s) => s.status == SubOrderStatus.delivered,
    );
    if (allDelivered) return 'تم التسليم';

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

  /// Get order statistics for a user
  Future<Map<String, dynamic>> getOrderStatistics(String userId) async {
    try {
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      double totalSpent = 0;
      int totalOrders = ordersSnapshot.docs.length;
      int completedOrders = 0;
      int cancelledOrders = 0;

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        totalSpent += (data['totalAmount'] ?? 0).toDouble();
        if (data['isCancelled'] == true) {
          cancelledOrders++;
        }
      }

      // Get completed sub-orders count
      final subOrdersSnapshot = await _firestore
          .collection('subOrders')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: SubOrderStatus.delivered.name)
          .get();

      completedOrders = subOrdersSnapshot.docs.length;

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting order statistics: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    stopOrdersRealTimeListener();
    _ordersStreamController.close();
  }
}
