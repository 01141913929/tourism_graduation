/// Review model for product and bazaar reviews
class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String targetId;
  final ReviewType targetType;
  final double rating;
  final String? comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int helpfulCount;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.targetId,
    required this.targetType,
    required this.rating,
    this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    this.helpfulCount = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      targetId: json['targetId'] as String,
      targetType: ReviewType.values.firstWhere(
        (e) => e.name == json['targetType'],
        orElse: () => ReviewType.product,
      ),
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      helpfulCount: json['helpfulCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'targetId': targetId,
      'targetType': targetType.name,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'helpfulCount': helpfulCount,
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? targetId,
    ReviewType? targetType,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    int? helpfulCount,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }
}

enum ReviewType {
  product,
  bazaar,
}

/// Coupon model for discount codes
class Coupon {
  final String id;
  final String code;
  final String descriptionAr;
  final String descriptionEn;
  final CouponType type;
  final double value;
  final double? minOrderAmount;
  final double? maxDiscount;
  final DateTime? startDate;
  final DateTime expiryDate;
  final int? usageLimit;
  final int usedCount;
  final List<String>? applicableProductIds;
  final List<String>? applicableCategoryIds;
  final bool isActive;

  const Coupon({
    required this.id,
    required this.code,
    required this.descriptionAr,
    this.descriptionEn = '',
    required this.type,
    required this.value,
    this.minOrderAmount,
    this.maxDiscount,
    this.startDate,
    required this.expiryDate,
    this.usageLimit,
    this.usedCount = 0,
    this.applicableProductIds,
    this.applicableCategoryIds,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isStarted => startDate == null || DateTime.now().isAfter(startDate!);
  bool get isValid =>
      isActive &&
      isStarted &&
      !isExpired &&
      (usageLimit == null || usedCount < usageLimit!);

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

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      descriptionAr: json['descriptionAr'] as String,
      descriptionEn: json['descriptionEn'] as String? ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CouponType.percentage,
      ),
      value: (json['value'] as num).toDouble(),
      minOrderAmount: json['minOrderAmount'] != null
          ? (json['minOrderAmount'] as num).toDouble()
          : null,
      maxDiscount: json['maxDiscount'] != null
          ? (json['maxDiscount'] as num).toDouble()
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      usageLimit: json['usageLimit'] as int?,
      usedCount: json['usedCount'] as int? ?? 0,
      applicableProductIds:
          (json['applicableProductIds'] as List<dynamic>?)?.cast<String>(),
      applicableCategoryIds:
          (json['applicableCategoryIds'] as List<dynamic>?)?.cast<String>(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'type': type.name,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'startDate': startDate?.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
      'isActive': isActive,
    };
  }
}

enum CouponType {
  percentage,
  fixed,
}
