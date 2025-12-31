import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج كود الخصم
class Coupon {
  final String id;
  final String code;
  final String nameAr;
  final String? descriptionAr;
  final CouponType type;
  final double value; // percentage or fixed amount
  final double? minOrderAmount;
  final double? maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;
  final List<String>? applicableBazaarIds;
  final List<String>? applicableCategoryIds;

  const Coupon({
    required this.id,
    required this.code,
    required this.nameAr,
    this.descriptionAr,
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    this.usedCount = 0,
    this.isActive = true,
    this.applicableBazaarIds,
    this.applicableCategoryIds,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String?,
      type: CouponType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CouponType.percentage,
      ),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now().add(const Duration(days: 30)),
      usageLimit: json['usageLimit'] as int?,
      usedCount: json['usedCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      applicableBazaarIds:
          (json['applicableBazaarIds'] as List?)?.cast<String>(),
      applicableCategoryIds:
          (json['applicableCategoryIds'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'nameAr': nameAr,
      'descriptionAr': descriptionAr,
      'type': type.name,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'applicableBazaarIds': applicableBazaarIds,
      'applicableCategoryIds': applicableCategoryIds,
    };
  }

  /// Check if coupon is valid
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (usageLimit == null || usedCount < usageLimit!);
  }

  /// Get discount text
  String get discountText {
    if (type == CouponType.percentage) {
      return '${value.toStringAsFixed(0)}%';
    } else {
      return '${value.toStringAsFixed(0)} ج.م';
    }
  }

  /// Calculate discount for order amount
  double calculateDiscount(double orderAmount) {
    if (!isValid) return 0;
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return 0;

    double discount;
    if (type == CouponType.percentage) {
      discount = orderAmount * (value / 100);
    } else {
      discount = value;
    }

    if (maxDiscount != null && discount > maxDiscount!) {
      discount = maxDiscount!;
    }

    return discount;
  }

  Coupon copyWith({
    String? id,
    String? code,
    String? nameAr,
    String? descriptionAr,
    CouponType? type,
    double? value,
    double? minOrderAmount,
    double? maxDiscount,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
    List<String>? applicableBazaarIds,
    List<String>? applicableCategoryIds,
  }) {
    return Coupon(
      id: id ?? this.id,
      code: code ?? this.code,
      nameAr: nameAr ?? this.nameAr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
      applicableBazaarIds: applicableBazaarIds ?? this.applicableBazaarIds,
      applicableCategoryIds:
          applicableCategoryIds ?? this.applicableCategoryIds,
    );
  }
}

/// نوع كود الخصم
enum CouponType {
  percentage, // نسبة مئوية
  fixed, // مبلغ ثابت
}

/// Repository for coupons
class CouponRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('coupons');

  /// Validate and get coupon by code
  Future<Coupon?> getCouponByCode(String code) async {
    try {
      final snapshot = await _collection
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return Coupon.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      return null;
    }
  }

  /// Get all active coupons
  Future<List<Coupon>> getActiveCoupons() async {
    try {
      final now = DateTime.now();
      final snapshot = await _collection
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: now.toIso8601String())
          .get();

      return snapshot.docs
          .map((doc) => Coupon.fromJson({...doc.data(), 'id': doc.id}))
          .where((coupon) => coupon.isValid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Increment coupon usage
  Future<void> incrementUsage(String couponId) async {
    try {
      await _collection.doc(couponId).update({
        'usedCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Handle error
    }
  }

  /// Create new coupon (for admin)
  Future<String?> createCoupon(Coupon coupon) async {
    try {
      final doc = await _collection.add(coupon.toJson());
      return doc.id;
    } catch (e) {
      return null;
    }
  }

  /// Update coupon (for admin)
  Future<bool> updateCoupon(Coupon coupon) async {
    try {
      await _collection.doc(coupon.id).update(coupon.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete coupon (for admin)
  Future<bool> deleteCoupon(String couponId) async {
    try {
      await _collection.doc(couponId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
