import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

/// Repository للتعامل مع التقييمات
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';

  /// إضافة تقييم جديد
  Future<Review> addReview(Review review) async {
    final docRef = _firestore.collection(_collection).doc();
    final reviewWithId = Review(
      id: docRef.id,
      userId: review.userId,
      userName: review.userName,
      userImageUrl: review.userImageUrl,
      targetId: review.targetId,
      targetType: review.targetType,
      rating: review.rating,
      comment: review.comment,
      createdAt: review.createdAt,
      isVerifiedPurchase: review.isVerifiedPurchase,
    );

    await docRef.set(reviewWithId.toJson());

    // Update target rating
    await _updateTargetRating(review.targetId, review.targetType);

    return reviewWithId;
  }

  /// الحصول على تقييمات منتج أو بازار
  Future<List<Review>> getReviews(String targetId,
      {String targetType = 'product'}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Stream للتقييمات
  Stream<List<Review>> streamReviews(String targetId,
      {String targetType = 'product'}) {
    return _firestore
        .collection(_collection)
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// التحقق من وجود تقييم سابق
  Future<Review?> getUserReview(String userId, String targetId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Review.fromJson(
        {...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
  }

  /// تحديث تقييم
  Future<void> updateReview(String reviewId, int rating, String comment) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'rating': rating,
      'comment': comment,
    });
  }

  /// حذف تقييم
  Future<void> deleteReview(
      String reviewId, String targetId, String targetType) async {
    await _firestore.collection(_collection).doc(reviewId).delete();
    await _updateTargetRating(targetId, targetType);
  }

  /// إضافة رد من البائع
  Future<void> addReply(String reviewId, String replyText) async {
    await _firestore.collection(_collection).doc(reviewId).update({
      'replyText': replyText,
      'replyAt': DateTime.now().toIso8601String(),
    });
  }

  /// تحديث متوسط التقييم للمنتج/البازار
  Future<void> _updateTargetRating(String targetId, String targetType) async {
    final reviews = await getReviews(targetId, targetType: targetType);
    final stats = ReviewStats.fromReviews(reviews);

    final collection = targetType == 'product' ? 'products' : 'bazaars';
    await _firestore.collection(collection).doc(targetId).update({
      'rating': stats.averageRating,
      'reviewCount': stats.totalReviews,
    });
  }

  /// الحصول على إحصائيات التقييمات
  Future<ReviewStats> getReviewStats(String targetId,
      {String targetType = 'product'}) async {
    final reviews = await getReviews(targetId, targetType: targetType);
    return ReviewStats.fromReviews(reviews);
  }
}
