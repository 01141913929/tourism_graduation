import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sub_order_model.dart';
import '../services/notification_service.dart';

/// Provider لإدارة الطلبات في تطبيق صاحب البازار
class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<SubOrder> _pendingOrders = [];
  List<SubOrder> _activeOrders = [];
  List<SubOrder> _completedOrders = [];
  bool _isLoading = false;
  String? _bazaarId;

  // Statistics
  int _todayOrdersCount = 0;
  double _todayRevenue = 0;
  double _totalRevenue = 0;

  List<SubOrder> get pendingOrders => _pendingOrders;
  List<SubOrder> get activeOrders => _activeOrders;
  List<SubOrder> get completedOrders => _completedOrders;
  bool get isLoading => _isLoading;
  int get todayOrdersCount => _todayOrdersCount;
  double get todayRevenue => _todayRevenue;
  double get totalRevenue => _totalRevenue;
  int get pendingCount => _pendingOrders.length;
  int get activeCount => _activeOrders.length;

  /// تعيين معرف البازار وتحميل الطلبات
  void setBazaarId(String bazaarId) {
    if (_bazaarId == bazaarId) return; // تجنب إعادة التحميل
    _bazaarId = bazaarId;
    // تأجيل loadOrders لتجنب notifyListeners أثناء build
    Future.microtask(() => loadOrders());
  }

  /// تحميل الطلبات
  Future<void> loadOrders() async {
    if (_bazaarId == null) return;

    // تجنب استدعاء notifyListeners إذا كنا في الحالة نفسها
    if (!_isLoading) {
      _isLoading = true;
      // استخدام SchedulerBinding لضمان عدم الاستدعاء أثناء build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final snapshot = await _firestore
          .collection('subOrders')
          .where('bazaarId', isEqualTo: _bazaarId)
          .orderBy('createdAt', descending: true)
          .get();

      final allOrders = snapshot.docs
          .map((doc) => SubOrder.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // تصنيف الطلبات
      _pendingOrders =
          allOrders.where((o) => o.status == SubOrderStatus.pending).toList();

      _activeOrders = allOrders
          .where(
            (o) =>
                o.status == SubOrderStatus.accepted ||
                o.status == SubOrderStatus.preparing ||
                o.status == SubOrderStatus.readyForPickup ||
                o.status == SubOrderStatus.shipping,
          )
          .toList();

      _completedOrders =
          allOrders.where((o) => o.status == SubOrderStatus.delivered).toList();

      // حساب الإحصائيات
      _calculateStatistics(allOrders);

      _isLoading = false;
      // استخدام addPostFrameCallback لضمان عدم الاستدعاء أثناء build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _calculateStatistics(List<SubOrder> orders) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    _todayOrdersCount = 0;
    _todayRevenue = 0;
    _totalRevenue = 0;

    for (final order in orders) {
      if (order.status == SubOrderStatus.delivered) {
        _totalRevenue += order.subtotal;

        if (order.deliveredAt != null &&
            order.deliveredAt!.isAfter(todayStart)) {
          _todayOrdersCount++;
          _todayRevenue += order.subtotal;
        }
      }
    }
  }

  /// قبول الطلب
  Future<bool> acceptOrder(String subOrderId) async {
    try {
      // Generate QR code data
      final subOrder = _pendingOrders.firstWhere((o) => o.id == subOrderId);

      final qrData = OrderQRData(
        subOrderId: subOrderId,
        parentOrderId: subOrder.parentOrderId,
        bazaarId: subOrder.bazaarId,
        customerId: subOrder.customerId,
        customerName: subOrder.customerName,
        amount: subOrder.subtotal,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await _firestore.collection('subOrders').doc(subOrderId).update({
        'status': SubOrderStatus.accepted.name,
        'acceptedAt': DateTime.now().toIso8601String(),
        'qrCode': qrData.toQRString(),
      });

      // Notify Customer
      NotificationService().sendNotification(
        targetUserId: subOrder.customerId,
        title: 'تم قبول طلبك',
        body: 'تم قبول طلبك من قبل ${qrData.bazaarId} وجاري التجهيز.',
        data: {'type': 'order', 'orderId': subOrderId},
      );

      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Error accepting order: $e');
      return false;
    }
  }

  /// رفض الطلب
  Future<bool> rejectOrder(String subOrderId, String reason) async {
    try {
      await _firestore.collection('subOrders').doc(subOrderId).update({
        'status': SubOrderStatus.rejected.name,
        'rejectionReason': reason,
      });

      // Notify Customer
      final subOrder = _pendingOrders.firstWhere((o) => o.id == subOrderId);
      NotificationService().sendNotification(
        targetUserId: subOrder.customerId,
        title: 'تم رفض طلبك',
        body: 'نعتذر، تم رفض طلبك. السبب: $reason',
        data: {'type': 'order', 'orderId': subOrderId},
      );

      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      return false;
    }
  }

  /// تحديث حالة الطلب
  Future<bool> updateOrderStatus(
    String subOrderId,
    SubOrderStatus newStatus,
  ) async {
    try {
      final Map<String, dynamic> updates = {'status': newStatus.name};

      switch (newStatus) {
        case SubOrderStatus.preparing:
          updates['preparedAt'] = DateTime.now().toIso8601String();
          break;
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

      await _firestore.collection('subOrders').doc(subOrderId).update(updates);

      // Notify Customer
      // Find order to get customerId. Check active orders first.
      SubOrder? subOrder;
      try {
        subOrder = _activeOrders.firstWhere((o) => o.id == subOrderId);
      } catch (_) {
        // If not in active, maybe try fetching or ignore
      }

      if (subOrder != null) {
        String statusText = '';
        if (newStatus == SubOrderStatus.preparing)
          statusText = 'طلبك قيد التجهيز';
        if (newStatus == SubOrderStatus.readyForPickup)
          statusText = 'طلبك جاهز للاستلام';
        if (newStatus == SubOrderStatus.shipping) statusText = 'طلبك في الطريق';

        if (statusText.isNotEmpty) {
          NotificationService().sendNotification(
            targetUserId: subOrder.customerId,
            title: 'تحديث حالة الطلب',
            body: statusText,
            data: {'type': 'order', 'orderId': subOrderId},
          );
        }
      }

      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// تأكيد استلام الطلب بمسح QR
  Future<SubOrder?> confirmPickupWithQR(String qrCodeString) async {
    try {
      // فك تشفير الـ QR
      final qrData = OrderQRData.fromQRString(qrCodeString);

      // التحقق من صلاحية الـ QR
      if (!qrData.isValid) {
        throw Exception('رمز QR منتهي الصلاحية');
      }

      // التحقق من أن الطلب يخص هذا البازار
      if (qrData.bazaarId != _bazaarId) {
        throw Exception('هذا الطلب ليس من البازار الخاص بك');
      }

      // الحصول على بيانات الطلب
      final subOrderDoc =
          await _firestore.collection('subOrders').doc(qrData.subOrderId).get();

      if (!subOrderDoc.exists) {
        throw Exception('الطلب غير موجود');
      }

      final subOrder = SubOrder.fromJson({
        ...subOrderDoc.data()!,
        'id': subOrderDoc.id,
      });

      // تحديث حالة المسح
      await _firestore.collection('subOrders').doc(qrData.subOrderId).update({
        'qrScanned': true,
        'scannedAt': DateTime.now().toIso8601String(),
        'status': SubOrderStatus
            .delivered.name, // Assume pickup = delivered/completed
        'deliveredAt': DateTime.now().toIso8601String(),
      });

      // Notify Customer
      NotificationService().sendNotification(
        targetUserId: subOrder.customerId,
        title: 'تم استلام الطلب',
        body: 'شكراً لك! نتمنى أن تستمتع بمشترياتك.',
        data: {'type': 'order', 'orderId': subOrder.id},
      );

      await loadOrders();

      return subOrder;
    } catch (e) {
      debugPrint('Error confirming pickup: $e');
      rethrow;
    }
  }

  /// تأكيد التسليم
  Future<bool> confirmDelivery(String subOrderId) async {
    try {
      await _firestore.collection('subOrders').doc(subOrderId).update({
        'status': SubOrderStatus.delivered.name,
        'deliveredAt': DateTime.now().toIso8601String(),
      });

      // Notify Customer
      // Check active orders
      SubOrder? subOrder;
      try {
        subOrder = _activeOrders.firstWhere((o) => o.id == subOrderId);
      } catch (_) {}

      if (subOrder != null) {
        NotificationService().sendNotification(
          targetUserId: subOrder.customerId,
          title: 'تم توصيل الطلب',
          body: 'تم توصيل طلبك بنجاح. شكراً لتسوقك معنا!',
          data: {'type': 'order', 'orderId': subOrderId},
        );
      }

      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Error confirming delivery: $e');
      return false;
    }
  }

  /// Stream للطلبات الجديدة (للإشعارات)
  Stream<List<SubOrder>> streamPendingOrders() {
    if (_bazaarId == null) return Stream.value([]);

    return _firestore
        .collection('subOrders')
        .where('bazaarId', isEqualTo: _bazaarId)
        .where('status', isEqualTo: SubOrderStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubOrder.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }
}
