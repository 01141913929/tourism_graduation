import 'dart:convert';

/// حالة الدفع
enum PaymentStatus {
  pending, // لم يُدفع بعد
  paid, // تم الدفع إلكترونياً
  payOnPickup, // الدفع عند الاستلام
  refunded, // تم الاسترداد
}

/// حالة الطلب الفرعي (لكل بازار)
enum SubOrderStatus {
  pending, // بانتظار موافقة البازار
  accepted, // تمت الموافقة
  preparing, // قيد التحضير
  readyForPickup, // جاهز للاستلام
  shipping, // قيد الشحن
  delivered, // تم التسليم
  rejected, // مرفوض من البازار
  cancelled, // ملغي من العميل
}

/// الطلب الفرعي - يُنشأ لكل بازار عند الشراء
class SubOrder {
  final String id;
  final String parentOrderId; // معرف الطلب الأب
  final String bazaarId;
  final String bazaarName;
  final String bazaarOwnerId; // لسهولة الاستعلام
  final String customerId; // معرف العميل
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final SubOrderStatus status;
  final String? rejectionReason; // سبب الرفض إن وجد
  final String? qrCode; // كود QR للاستلام
  final bool qrScanned; // هل تم مسح الـ QR
  final DateTime? scannedAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? preparedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const SubOrder({
    required this.id,
    required this.parentOrderId,
    required this.bazaarId,
    required this.bazaarName,
    required this.bazaarOwnerId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.status,
    this.rejectionReason,
    this.qrCode,
    this.qrScanned = false,
    this.scannedAt,
    required this.createdAt,
    this.acceptedAt,
    this.preparedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  /// الحصول على نص الحالة بالعربية
  String get statusText {
    switch (status) {
      case SubOrderStatus.pending:
        return 'بانتظار الموافقة';
      case SubOrderStatus.accepted:
        return 'تمت الموافقة';
      case SubOrderStatus.preparing:
        return 'قيد التحضير';
      case SubOrderStatus.readyForPickup:
        return 'جاهز للاستلام';
      case SubOrderStatus.shipping:
        return 'قيد الشحن';
      case SubOrderStatus.delivered:
        return 'تم التسليم';
      case SubOrderStatus.rejected:
        return 'مرفوض';
      case SubOrderStatus.cancelled:
        return 'ملغي';
    }
  }

  /// عدد المنتجات
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory SubOrder.fromJson(Map<String, dynamic> json) {
    return SubOrder(
      id: json['id'] as String,
      parentOrderId: json['parentOrderId'] as String,
      bazaarId: json['bazaarId'] as String,
      bazaarName: json['bazaarName'] as String,
      bazaarOwnerId: json['bazaarOwnerId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      status: SubOrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubOrderStatus.pending,
      ),
      rejectionReason: json['rejectionReason'] as String?,
      qrCode: json['qrCode'] as String?,
      qrScanned: json['qrScanned'] as bool? ?? false,
      scannedAt: json['scannedAt'] != null
          ? DateTime.parse(json['scannedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      preparedAt: json['preparedAt'] != null
          ? DateTime.parse(json['preparedAt'] as String)
          : null,
      shippedAt: json['shippedAt'] != null
          ? DateTime.parse(json['shippedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentOrderId': parentOrderId,
      'bazaarId': bazaarId,
      'bazaarName': bazaarName,
      'bazaarOwnerId': bazaarOwnerId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'qrCode': qrCode,
      'qrScanned': qrScanned,
      'scannedAt': scannedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'preparedAt': preparedAt?.toIso8601String(),
      'shippedAt': shippedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  SubOrder copyWith({
    String? id,
    String? parentOrderId,
    String? bazaarId,
    String? bazaarName,
    String? bazaarOwnerId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    SubOrderStatus? status,
    String? rejectionReason,
    String? qrCode,
    bool? qrScanned,
    DateTime? scannedAt,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? preparedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) {
    return SubOrder(
      id: id ?? this.id,
      parentOrderId: parentOrderId ?? this.parentOrderId,
      bazaarId: bazaarId ?? this.bazaarId,
      bazaarName: bazaarName ?? this.bazaarName,
      bazaarOwnerId: bazaarOwnerId ?? this.bazaarOwnerId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      qrCode: qrCode ?? this.qrCode,
      qrScanned: qrScanned ?? this.qrScanned,
      scannedAt: scannedAt ?? this.scannedAt,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      preparedAt: preparedAt ?? this.preparedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

/// بيانات QR Code للطلب
class OrderQRData {
  final String subOrderId;
  final String parentOrderId;
  final String bazaarId;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime expiresAt;

  const OrderQRData({
    required this.subOrderId,
    required this.parentOrderId,
    required this.bazaarId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentStatus,
    required this.createdAt,
    required this.expiresAt,
  });

  /// هل الـ QR صالح
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// هل تم الدفع
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  /// تحويل إلى JSON string للـ QR
  String toQRString() {
    final data = {
      'soid': subOrderId,
      'poid': parentOrderId,
      'bid': bazaarId,
      'cid': customerId,
      'cn': customerName,
      'amt': amount,
      'ps': paymentStatus.name,
      'ca': createdAt.millisecondsSinceEpoch,
      'ea': expiresAt.millisecondsSinceEpoch,
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// فك التشفير من QR string
  factory OrderQRData.fromQRString(String qrString) {
    try {
      final decoded = utf8.decode(base64Decode(qrString));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return OrderQRData(
        subOrderId: json['soid'] as String,
        parentOrderId: json['poid'] as String,
        bazaarId: json['bid'] as String,
        customerId: json['cid'] as String,
        customerName: json['cn'] as String,
        amount: (json['amt'] as num).toDouble(),
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == json['ps'],
          orElse: () => PaymentStatus.pending,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['ca'] as int),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(json['ea'] as int),
      );
    } catch (e) {
      throw FormatException('Invalid QR code format: $e');
    }
  }

  factory OrderQRData.fromJson(Map<String, dynamic> json) {
    return OrderQRData(
      subOrderId: json['subOrderId'] as String,
      parentOrderId: json['parentOrderId'] as String,
      bazaarId: json['bazaarId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subOrderId': subOrderId,
      'parentOrderId': parentOrderId,
      'bazaarId': bazaarId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentStatus': paymentStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}

/// OrderItem model - عنصر في الطلب (مُحدث)
class OrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double price;
  final String selectedSize;
  final int quantity;
  final String bazaarId; // جديد: معرف البازار
  final String bazaarName; // جديد: اسم البازار

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.selectedSize,
    required this.quantity,
    this.bazaarId = '',
    this.bazaarName = '',
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      selectedSize: json['selectedSize'] as String,
      quantity: json['quantity'] as int,
      bazaarId: json['bazaarId'] as String? ?? '',
      bazaarName: json['bazaarName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'price': price,
      'selectedSize': selectedSize,
      'quantity': quantity,
      'bazaarId': bazaarId,
      'bazaarName': bazaarName,
    };
  }
}
