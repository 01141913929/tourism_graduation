import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// شاشة تقييمات العملاء
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<BazaarAuthProvider>();
      final bazaarId = authProvider.user?.bazaarId;

      if (bazaarId == null) return;

      final snapshot = await _firestore
          .collection('reviews')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      _reviews =
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      // حساب المتوسط والتوزيع
      if (_reviews.isNotEmpty) {
        double total = 0;
        _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

        for (var review in _reviews) {
          final rating = (review['rating'] as num?)?.toInt() ?? 0;
          total += rating;
          if (rating >= 1 && rating <= 5) {
            _ratingDistribution[rating] =
                (_ratingDistribution[rating] ?? 0) + 1;
          }
        }
        _averageRating = total / _reviews.length;
      }

      // ترتيب حسب التاريخ
      _reviews.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقييمات العملاء'),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: CustomScrollView(
                slivers: [
                  // ملخص التقييمات
                  SliverToBoxAdapter(
                    child: _buildRatingSummary(),
                  ),

                  // قائمة التقييمات
                  if (_reviews.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildReviewCard(_reviews[index]),
                          childCount: _reviews.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // التقييم العام
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.white,
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_reviews.length} تقييم',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // توزيع التقييمات
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = _ratingDistribution[rating] ?? 0;
                    final percentage =
                        _reviews.isEmpty ? 0.0 : count / _reviews.length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.star_rounded,
                              color: AppColors.white, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor:
                                    AppColors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.white),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.star,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر تقييمات العملاء هنا',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final customerName = review['userName'] as String? ??
        review['customerName'] as String? ??
        'عميل';
    final comment = review['comment'] as String? ?? '';
    final replyText = review['replyText'] as String?;
    final reviewId = review['id'] as String?;
    final createdAt =
        DateTime.tryParse(review['createdAt'] ?? '') ?? DateTime.now();
    final dateFormat = DateFormat('dd MMM yyyy', 'ar');
    final isVerified = review['isVerifiedPurchase'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                radius: 24,
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'ع',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified,
                              size: 16, color: Colors.green[600]),
                        ],
                      ],
                    ),
                    Text(
                      dateFormat.format(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // النجوم
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: _getRatingColor(rating), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$rating',
                      style: TextStyle(
                        color: _getRatingColor(rating),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          ],

          // Reply section
          if (replyText != null && replyText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.shop, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ردك',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _showReplyDialog(reviewId!, replyText),
                        child:
                            Icon(Iconsax.edit_2, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    replyText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(reviewId!, null),
                icon: const Icon(Iconsax.message_text, size: 18),
                label: const Text('رد على التقييم'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(String reviewId, String? existingReply) {
    final controller = TextEditingController(text: existingReply ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              existingReply != null ? 'تعديل الرد' : 'رد على التقييم',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'شكراً لتقييمك! نحن سعداء بخدمتك...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (existingReply != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteReply(reviewId);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('حذف الرد'),
                    ),
                  ),
                if (existingReply != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      Navigator.pop(context);
                      await _submitReply(reviewId, text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                        existingReply != null ? 'حفظ التعديل' : 'إرسال الرد'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReply(String reviewId, String replyText) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'replyText': replyText,
        'replyAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الرد بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteReply(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'replyText': FieldValue.delete(),
        'replyAt': FieldValue.delete(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الرد'),
          backgroundColor: AppColors.warning,
        ),
      );

      _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return AppColors.success;
    if (rating >= 3) return AppColors.warning;
    return AppColors.error;
  }
}
