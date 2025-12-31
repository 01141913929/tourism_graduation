import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/sub_order_model.dart';
import '../services/firestore_service.dart';

/// Repository for parent order data operations
class OrderRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'orders';

  OrderRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Create a new parent order
  Future<Order> createOrder(Order order) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: order.id,
      data: order.toJson(),
    );
    return order;
  }

  /// Get order by ID
  Future<Order?> getOrder(String orderId) async {
    debugPrint('🔍 OrderRepository.getOrder: Fetching orderId: $orderId');
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: orderId,
    );
    debugPrint(
        '📥 OrderRepository.getOrder: Data received: ${data != null ? 'EXISTS' : 'NULL'}');
    if (data == null) return null;
    return Order.fromJson({...data, 'id': orderId});
  }

  /// Stream single order
  Stream<Order?> streamOrder(String orderId) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: orderId)
        .map((data) {
      if (data == null) return null;
      return Order.fromJson({...data, 'id': orderId});
    });
  }

  /// Get orders for user
  Future<List<Order>> getUserOrders(String userId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true),
    );
    return data.map((e) => Order.fromJson(e)).toList();
  }

  /// Stream orders for user
  Stream<List<Order>> streamUserOrders(String userId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true),
        )
        .map((data) => data.map((e) => Order.fromJson(e)).toList());
  }

  /// Get orders by payment status
  Future<List<Order>> getOrdersByPaymentStatus(
      String userId, PaymentStatus status) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('userId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: status.name),
    );
    return data.map((e) => Order.fromJson(e)).toList();
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: orderId,
      data: {'paymentStatus': status.name},
    );
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: orderId,
    );
  }

  /// Get recent orders (for admin dashboard)
  Future<List<Order>> getRecentOrders({int limit = 10}) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) =>
          ref.orderBy('createdAt', descending: true).limit(limit),
    );
    return data.map((e) => Order.fromJson(e)).toList();
  }

  /// Generate unique order ID
  String generateOrderId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'ORD-$timestamp';
  }

  /// Add subOrder ID to parent order
  Future<void> addSubOrderId(String orderId, String subOrderId) async {
    final order = await getOrder(orderId);
    if (order != null) {
      final updatedIds = [...order.subOrderIds, subOrderId];
      await _firestoreService.updateDocument(
        collection: _collection,
        docId: orderId,
        data: {'subOrderIds': updatedIds},
      );
    }
  }
}
