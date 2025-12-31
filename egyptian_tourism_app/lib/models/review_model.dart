import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج التقييم/المراجعة
class Review {
  final String id;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String targetId; // productId or bazaarId
  final String targetType; // 'product' or 'bazaar'
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final String? replyText;
  final DateTime? replyAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.targetId,
    required this.targetType,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isVerifiedPurchase = false,
    this.replyText,
    this.replyAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userImageUrl: json['userImageUrl'] as String?,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String? ?? 'product',
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      isVerifiedPurchase: json['isVerifiedPurchase'] as bool? ?? false,
      replyText: json['replyText'] as String?,
      replyAt: json['replyAt'] != null
          ? (json['replyAt'] is Timestamp
              ? (json['replyAt'] as Timestamp).toDate()
              : DateTime.parse(json['replyAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'isVerifiedPurchase': isVerifiedPurchase,
      'replyText': replyText,
      'replyAt': replyAt?.toIso8601String(),
    };
  }
}

/// إحصائيات التقييمات
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown; // 5 -> count, 4 -> count, etc.

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
  });

  factory ReviewStats.fromReviews(List<Review> reviews) {
    if (reviews.isEmpty) {
      return ReviewStats(
        averageRating: 0,
        totalReviews: 0,
        ratingBreakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    double totalRating = 0;

    for (final review in reviews) {
      totalRating += review.rating;
      breakdown[review.rating] = (breakdown[review.rating] ?? 0) + 1;
    }

    return ReviewStats(
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingBreakdown: breakdown,
    );
  }

  double getPercentage(int rating) {
    if (totalReviews == 0) return 0;
    return (ratingBreakdown[rating] ?? 0) / totalReviews;
  }
}
