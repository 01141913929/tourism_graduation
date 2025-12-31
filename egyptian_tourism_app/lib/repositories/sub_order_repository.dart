import '../models/sub_order_model.dart';
import '../services/firestore_service.dart';

/// Repository for sub-order data operations
class SubOrderRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'subOrders';

  SubOrderRepository({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  /// Create a new sub-order
  Future<SubOrder> createSubOrder(SubOrder subOrder) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: subOrder.id,
      data: subOrder.toJson(),
    );
    return subOrder;
  }

  /// Get sub-order by ID
  Future<SubOrder?> getSubOrder(String subOrderId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: subOrderId,
    );
    if (data == null) return null;
    return SubOrder.fromJson({...data, 'id': subOrderId});
  }

  /// Stream single sub-order
  Stream<SubOrder?> streamSubOrder(String subOrderId) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: subOrderId)
        .map((data) {
      if (data == null) return null;
      return SubOrder.fromJson({...data, 'id': subOrderId});
    });
  }

  /// Get sub-orders by parent order ID
  /// Note: customerId is required for Firebase security rules compliance
  Future<List<SubOrder>> getSubOrdersByParent(String parentOrderId,
      {String? customerId}) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) {
        var query = ref.where('parentOrderId', isEqualTo: parentOrderId);
        // Add customerId filter to satisfy Firebase security rules
        if (customerId != null) {
          query = query.where('customerId', isEqualTo: customerId);
        }
        return query;
      },
    );
    return data.map((e) => SubOrder.fromJson(e)).toList();
  }

  /// Stream sub-orders by parent order
  Stream<List<SubOrder>> streamSubOrdersByParent(String parentOrderId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) =>
              ref.where('parentOrderId', isEqualTo: parentOrderId),
        )
        .map((data) => data.map((e) => SubOrder.fromJson(e)).toList());
  }

  /// Get sub-orders for a bazaar
  Future<List<SubOrder>> getBazaarSubOrders(String bazaarId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('bazaarId', isEqualTo: bazaarId)
          .orderBy('createdAt', descending: true),
    );
    return data.map((e) => SubOrder.fromJson(e)).toList();
  }

  /// Stream sub-orders for a bazaar
  Stream<List<SubOrder>> streamBazaarSubOrders(String bazaarId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref
              .where('bazaarId', isEqualTo: bazaarId)
              .orderBy('createdAt', descending: true),
        )
        .map((data) => data.map((e) => SubOrder.fromJson(e)).toList());
  }

  /// Get pending sub-orders for a bazaar
  Future<List<SubOrder>> getPendingBazaarSubOrders(String bazaarId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('bazaarId', isEqualTo: bazaarId)
          .where('status', isEqualTo: SubOrderStatus.pending.name),
    );
    return data.map((e) => SubOrder.fromJson(e)).toList();
  }

  /// Stream pending sub-orders for a bazaar (for notifications)
  Stream<List<SubOrder>> streamPendingBazaarSubOrders(String bazaarId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref
              .where('bazaarId', isEqualTo: bazaarId)
              .where('status', isEqualTo: SubOrderStatus.pending.name),
        )
        .map((data) => data.map((e) => SubOrder.fromJson(e)).toList());
  }

  /// Get sub-orders by status for a bazaar
  Future<List<SubOrder>> getBazaarSubOrdersByStatus(
      String bazaarId, SubOrderStatus status) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('bazaarId', isEqualTo: bazaarId)
          .where('status', isEqualTo: status.name),
    );
    return data.map((e) => SubOrder.fromJson(e)).toList();
  }

  /// Get customer's sub-orders
  Future<List<SubOrder>> getCustomerSubOrders(String customerId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true),
    );
    return data.map((e) => SubOrder.fromJson(e)).toList();
  }

  /// Stream customer's sub-orders
  Stream<List<SubOrder>> streamCustomerSubOrders(String customerId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref
              .where('customerId', isEqualTo: customerId)
              .orderBy('createdAt', descending: true),
        )
        .map((data) => data.map((e) => SubOrder.fromJson(e)).toList());
  }

  /// Update sub-order status
  Future<void> updateSubOrderStatus(
      String subOrderId, SubOrderStatus status) async {
    final Map<String, dynamic> updates = {'status': status.name};

    // Add timestamp based on status
    switch (status) {
      case SubOrderStatus.accepted:
        updates['acceptedAt'] = DateTime.now().toIso8601String();
        break;
      case SubOrderStatus.preparing:
      case SubOrderStatus.readyForPickup:
        updates['preparedAt'] = DateTime.now().toIso8601String();
        break;
      case SubOrderStatus.shipping:
        updates['shippedAt'] = DateTime.now().toIso8601String();
        break;
      case SubOrderStatus.delivered:
        updates['deliveredAt'] = DateTime.now().toIso8601String();
        break;
      default:
        break;
    }

    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: updates,
    );
  }

  /// Reject sub-order with reason
  Future<void> rejectSubOrder(String subOrderId, String reason) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: {
        'status': SubOrderStatus.rejected.name,
        'rejectionReason': reason,
      },
    );
  }

  /// Cancel sub-order by customer (only allowed for pending orders)
  Future<bool> cancelSubOrder(String subOrderId) async {
    final subOrder = await getSubOrder(subOrderId);
    if (subOrder == null) return false;

    // Only allow cancellation for pending orders
    if (subOrder.status != SubOrderStatus.pending) {
      return false;
    }

    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: {
        'status': SubOrderStatus.cancelled.name,
        'cancelledAt': DateTime.now().toIso8601String(),
      },
    );
    return true;
  }

  /// Check if sub-order can be cancelled
  bool canCancelSubOrder(SubOrder subOrder) {
    return subOrder.status == SubOrderStatus.pending;
  }

  /// Accept sub-order and generate QR code
  Future<SubOrder> acceptSubOrder(String subOrderId) async {
    final subOrder = await getSubOrder(subOrderId);
    if (subOrder == null) throw Exception('SubOrder not found');

    // Generate QR data
    final qrData = OrderQRData(
      subOrderId: subOrderId,
      parentOrderId: subOrder.parentOrderId,
      bazaarId: subOrder.bazaarId,
      customerId: subOrder.customerId,
      customerName: subOrder.customerName,
      amount: subOrder.subtotal,
      paymentStatus: PaymentStatus.pending, // Will be updated when paid
      createdAt: DateTime.now(),
      expiresAt:
          DateTime.now().add(const Duration(days: 7)), // Valid for 7 days
    );

    final qrString = qrData.toQRString();

    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: {
        'status': SubOrderStatus.accepted.name,
        'acceptedAt': DateTime.now().toIso8601String(),
        'qrCode': qrString,
      },
    );

    return subOrder.copyWith(
      status: SubOrderStatus.accepted,
      acceptedAt: DateTime.now(),
      qrCode: qrString,
    );
  }

  /// Mark QR as scanned
  Future<void> markQRScanned(String subOrderId) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: {
        'qrScanned': true,
        'scannedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Confirm delivery (mark as delivered)
  Future<void> confirmDelivery(String subOrderId) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: subOrderId,
      data: {
        'status': SubOrderStatus.delivered.name,
        'deliveredAt': DateTime.now().toIso8601String(),
        'qrScanned': true,
        'scannedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Generate unique sub-order ID
  String generateSubOrderId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'SUB-$timestamp';
  }

  /// Get statistics for a bazaar
  Future<Map<String, dynamic>> getBazaarStatistics(String bazaarId) async {
    final allOrders = await getBazaarSubOrders(bazaarId);

    int pendingCount = 0;
    int acceptedCount = 0;
    int preparingCount = 0;
    int deliveredCount = 0;
    double totalRevenue = 0;
    double todayRevenue = 0;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    for (final order in allOrders) {
      switch (order.status) {
        case SubOrderStatus.pending:
          pendingCount++;
          break;
        case SubOrderStatus.accepted:
          acceptedCount++;
          break;
        case SubOrderStatus.preparing:
        case SubOrderStatus.readyForPickup:
          preparingCount++;
          break;
        case SubOrderStatus.delivered:
          deliveredCount++;
          totalRevenue += order.subtotal;
          if (order.deliveredAt != null &&
              order.deliveredAt!.isAfter(todayStart)) {
            todayRevenue += order.subtotal;
          }
          break;
        default:
          break;
      }
    }

    return {
      'pendingCount': pendingCount,
      'acceptedCount': acceptedCount,
      'preparingCount': preparingCount,
      'deliveredCount': deliveredCount,
      'totalOrdersCount': allOrders.length,
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
    };
  }
}
