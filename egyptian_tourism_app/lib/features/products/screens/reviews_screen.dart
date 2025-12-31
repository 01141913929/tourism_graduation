import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../models/review_model.dart';
import '../../../repositories/review_repository.dart';
import '../../../repositories/sub_order_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/sub_order_model.dart';

/// شاشة التقييمات والمراجعات
class ReviewsScreen extends StatefulWidget {
  final String targetId;
  final String targetType; // 'product' or 'bazaar'
  final String? targetName;

  const ReviewsScreen({
    super.key,
    required this.targetId,
    this.targetType = 'product',
    this.targetName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewRepository _repository = ReviewRepository();
  final SubOrderRepository _subOrderRepository = SubOrderRepository();

  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  Review? _userReview;
  bool _hasVerifiedPurchase = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final reviews = await _repository.getReviews(widget.targetId,
          targetType: widget.targetType);
      final stats = ReviewStats.fromReviews(reviews);

      final userId = context.read<AuthProvider>().userId;
      Review? userReview;
      bool hasVerifiedPurchase = false;

      if (userId != null) {
        userReview = await _repository.getUserReview(userId, widget.targetId);

        // Check if user has purchased this product/bazaar item
        if (widget.targetType == 'product') {
          hasVerifiedPurchase =
              await _checkProductPurchase(userId, widget.targetId);
        } else {
          // For bazaar reviews, check if user has any delivered order from this bazaar
          hasVerifiedPurchase =
              await _checkBazaarPurchase(userId, widget.targetId);
        }
      }

      setState(() {
        _reviews = reviews;
        _stats = stats;
        _userReview = userReview;
        _hasVerifiedPurchase = hasVerifiedPurchase;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading reviews: $e');
    }
  }

  /// Check if user has purchased this product
  Future<bool> _checkProductPurchase(String userId, String productId) async {
    try {
      final subOrders = await _subOrderRepository.getCustomerSubOrders(userId);
      for (final order in subOrders) {
        if (order.status == SubOrderStatus.delivered) {
          for (final item in order.items) {
            if (item.productId == productId) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking product purchase: $e');
      return false;
    }
  }

  /// Check if user has purchased from this bazaar
  Future<bool> _checkBazaarPurchase(String userId, String bazaarId) async {
    try {
      final subOrders = await _subOrderRepository.getCustomerSubOrders(userId);
      for (final order in subOrders) {
        if (order.bazaarId == bazaarId &&
            order.status == SubOrderStatus.delivered) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking bazaar purchase: $e');
      return false;
    }
  }

  void _showAddReviewDialog() {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لإضافة تقييم')),
      );
      return;
    }

    // Check for verified purchase
    if (!_hasVerifiedPurchase && _userReview == null) {
      _showPurchaseRequiredDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddReviewSheet(
        targetId: widget.targetId,
        targetType: widget.targetType,
        existingReview: _userReview,
        isVerifiedPurchase: _hasVerifiedPurchase,
        onSubmit: (rating, comment) async {
          final authProvider = context.read<AuthProvider>();
          try {
            if (_userReview != null) {
              await _repository.updateReview(_userReview!.id, rating, comment);
            } else {
              await _repository.addReview(Review(
                id: '',
                userId: authProvider.userId!,
                userName: authProvider.user?.name ?? 'مستخدم',
                targetId: widget.targetId,
                targetType: widget.targetType,
                rating: rating,
                comment: comment,
                createdAt: DateTime.now(),
                isVerifiedPurchase: _hasVerifiedPurchase,
              ));
            }
            Navigator.pop(context);
            _loadData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('تم حفظ التقييم'),
                  backgroundColor: Colors.green),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showPurchaseRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.info_circle, color: AppColors.egyptianGold),
            const SizedBox(width: 8),
            const Text('مطلوب شراء'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'يجب أن تشتري هذا المنتج وتستلمه قبل أن تتمكن من تقييمه.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'التقييمات المعتمدة تساعد المشترين الآخرين',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
            'التقييمات${widget.targetName != null ? ' - ${widget.targetName}' : ''}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        icon: Icon(_userReview != null ? Iconsax.edit : Iconsax.star),
        label: Text(_userReview != null ? 'تعديل تقييمك' : 'أضف تقييم'),
        backgroundColor: AppColors.egyptianGold,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Stats Header
                if (_stats != null)
                  SliverToBoxAdapter(
                    child: _buildStatsHeader(),
                  ),

                // Reviews List
                _reviews.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildReviewCard(_reviews[index]),
                            childCount: _reviews.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          // Average Rating
          Column(
            children: [
              Text(
                _stats!.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.egyptianGold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _stats!.averageRating.round()
                        ? Iconsax.star1
                        : Iconsax.star,
                    color: AppColors.egyptianGold,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '${_stats!.totalReviews} تقييم',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(width: 32),

          // Rating Breakdown
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((rating) {
                final percentage = _stats!.getPercentage(rating);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('$rating',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 4),
                      Icon(Iconsax.star1, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.egyptianGold),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${(percentage * 100).toInt()}%',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
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
          Icon(Iconsax.star, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد تقييمات بعد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('كن أول من يقيم!', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final isUserReview = review.id == _userReview?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUserReview
            ? Border.all(color: AppColors.egyptianGold, width: 2)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.egyptianGold.withOpacity(0.2),
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: AppColors.egyptianGold,
                      fontWeight: FontWeight.w700),
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
                          review.userName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (isUserReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.egyptianGold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('تقييمك',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        ],
                        if (review.isVerifiedPurchase) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.verified,
                              size: 14, color: Colors.green[600]),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Iconsax.star1 : Iconsax.star,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment,
              style: TextStyle(color: Colors.grey[700], height: 1.5)),

          // Reply from seller
          if (review.replyText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.shop,
                          size: 14, color: AppColors.egyptianGreen),
                      const SizedBox(width: 4),
                      const Text('رد البائع',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.replyText!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sheet لإضافة/تعديل تقييم
class _AddReviewSheet extends StatefulWidget {
  final String targetId;
  final String targetType;
  final Review? existingReview;
  final bool isVerifiedPurchase;
  final Function(int rating, String comment) onSubmit;

  const _AddReviewSheet({
    required this.targetId,
    required this.targetType,
    this.existingReview,
    this.isVerifiedPurchase = false,
    required this.onSubmit,
  });

  @override
  State<_AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<_AddReviewSheet> {
  int _rating = 5;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 5;
    _commentController =
        TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              widget.existingReview != null ? 'تعديل التقييم' : 'أضف تقييمك',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),

            // Star Rating
            const Text('التقييم',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _rating ? Iconsax.star1 : Iconsax.star,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Comment
            const Text('تعليقك', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'شاركنا رأيك...',
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
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_commentController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى كتابة تعليق')),
                          );
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        widget.onSubmit(
                            _rating, _commentController.text.trim());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.egyptianGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('إرسال التقييم',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
