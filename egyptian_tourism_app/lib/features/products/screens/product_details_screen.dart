import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/review_repository.dart';
import '../../../models/models.dart';
import '../../../models/review_model.dart';
import '../../../providers/app_state.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedImageIndex = 0;
  String? _selectedSize;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _showFullDescription = false;
  List<Product> _relatedProducts = [];
  List<Review> _reviews = [];
  final ProductRepository _productRepository = ProductRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();

  // Mock image gallery
  late List<String> _productImages;

  @override
  void initState() {
    super.initState();

    _productImages = [
      widget.product.imageUrl,
      widget.product.imageUrl,
      widget.product.imageUrl,
    ];

    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }

    // Initialize animations FIRST (must be sync in initState)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();

    // Load related products and reviews from Firebase
    _loadRelatedProducts();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewRepository.getReviews(
        widget.product.id,
        targetType: 'product',
      );
      if (mounted) {
        setState(() => _reviews = reviews);
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final products = await _productRepository.getProducts();
      if (mounted) {
        setState(() {
          _relatedProducts =
              products.where((p) => p.id != widget.product.id).take(4).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading related products: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Image Gallery App Bar
              _buildImageGalleryAppBar(),

              // Product Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildProductContent(),
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGalleryAppBar() {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: true,
      backgroundColor: AppColors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: _buildCircleButton(
        icon: Icons.arrow_forward_ios,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _buildCircleButton(
          icon: _isFavorite ? Iconsax.heart5 : Iconsax.heart,
          iconColor: _isFavorite ? AppColors.error : null,
          onTap: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
            HapticFeedback.lightImpact();
          },
        ),
        const SizedBox(width: 8),
        _buildCircleButton(
          icon: Iconsax.share,
          onTap: () {},
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.white,
          child: Column(
            children: [
              // Main Image
              Expanded(
                child: Stack(
                  children: [
                    // Image with hero animation
                    Hero(
                      tag: 'product_${widget.product.id}',
                      child: PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        itemCount: _productImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            child: CachedNetworkImage(
                              imageUrl: _productImages[index],
                              fit: BoxFit.contain,
                            ),
                          );
                        },
                      ),
                    ),

                    // Discount Badge
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 100,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.error,
                                AppColors.error.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.discount_shape,
                                color: AppColors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'خصم ${widget.product.discountPercentage.toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 360° View Button
                    Positioned(
                      bottom: 60,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.rotate_left,
                              color: AppColors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'عرض 360°',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Indicators & Thumbnails
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_productImages.length, (index) {
                    final isSelected = _selectedImageIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryOrange
                                : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryOrange
                                        .withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: _productImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProductContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Category & Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '(128 تقييم)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.9',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'تماثيل فرعونية',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  widget.product.nameAr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),

                // Price Section
                _buildPriceSection(),
                const SizedBox(height: 24),

                // Size Selection
                if (widget.product.sizes.isNotEmpty) ...[
                  _buildSizeSelection(),
                  const SizedBox(height: 24),
                ],

                // Quantity Selector
                _buildQuantitySelector(),
                const SizedBox(height: 24),

                // Bazaar/Shop Information
                if (widget.product.bazaarId.isNotEmpty) _buildBazaarSection(),
                if (widget.product.bazaarId.isNotEmpty)
                  const SizedBox(height: 24),

                // Description
                _buildDescription(),
                const SizedBox(height: 24),

                // Specifications
                _buildSpecifications(),
                const SizedBox(height: 24),

                // Features
                _buildFeatures(),
                const SizedBox(height: 24),

                // Reviews Section
                _buildReviewsSection(),
                const SizedBox(height: 24),

                // Related Products
                _buildRelatedProducts(),

                // Bottom padding for floating bar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange.withValues(alpha: 0.08),
            AppColors.primaryOrange.withValues(alpha: 0.02),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Installment info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.card,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'تقسيط متاح',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${(widget.product.price / 4).toStringAsFixed(0)} ج.م / شهر',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          // Main price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.product.hasDiscount)
                Text(
                  '${widget.product.oldPrice!.toStringAsFixed(0)} ج.م',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ج.م',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.product.price.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'دليل المقاسات',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryOrange,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text(
              'اختر المقاس',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: widget.product.sizes.map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryOrange : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primaryOrange.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الكمية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () {
                  if (_quantity > 1) {
                    setState(() => _quantity--);
                    HapticFeedback.selectionClick();
                  }
                },
                enabled: _quantity > 1,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () {
                  setState(() => _quantity++);
                  HapticFeedback.selectionClick();
                },
                enabled: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryOrange : AppColors.divider,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.white : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الوصف',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _showFullDescription
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.product.descriptionAr,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          secondChild: Text(
            widget.product.descriptionAr,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _showFullDescription = !_showFullDescription;
            });
          },
          child: Text(
            _showFullDescription ? 'عرض أقل' : 'عرض المزيد',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecifications() {
    final specs = [
      {
        'icon': Iconsax.weight,
        'label': 'الوزن',
        'value': widget.product.weight ?? '800g'
      },
      {
        'icon': Iconsax.ruler,
        'label': 'الأبعاد',
        'value': widget.product.dimensions ?? '20×20×24 سم'
      },
      {
        'icon': Iconsax.box_1,
        'label': 'الخامة',
        'value': widget.product.material ?? 'بوليستر مطلي'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'المواصفات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: specs.asMap().entries.map((entry) {
              final spec = entry.value;
              final isLast = entry.key == specs.length - 1;
              return Column(
                children: [
                  Row(
                    children: [
                      Text(
                        spec['value'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        spec['label'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        spec['icon'] as IconData,
                        size: 20,
                        color: AppColors.primaryOrange,
                      ),
                    ],
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    Divider(color: AppColors.divider),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBazaarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'متوفر في',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryTeal.withValues(alpha: 0.08),
                AppColors.secondaryTeal.withValues(alpha: 0.02),
              ],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondaryTeal.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // View on map button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'عرض على الخريطة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.map_outlined,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bazaar info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.bazaarName.isNotEmpty
                                ? widget.product.bazaarName
                                : 'بزار خان الخليلي',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryTeal
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: AppColors.secondaryTeal,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'مفتوح الآن',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Contact info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildContactButton(
                      icon: Icons.phone,
                      label: 'اتصال',
                      onTap: () {},
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.divider,
                    ),
                    _buildContactButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'رسالة',
                      onTap: () {},
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.divider,
                    ),
                    _buildContactButton(
                      icon: Icons.share,
                      label: 'مشاركة',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.secondaryTeal,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      {
        'icon': Iconsax.verify,
        'text': 'ضمان الأصالة',
        'color': AppColors.success
      },
      {
        'icon': Iconsax.truck_fast,
        'text': 'شحن مجاني',
        'color': AppColors.primaryOrange
      },
      {
        'icon': Iconsax.refresh,
        'text': 'إرجاع مجاني',
        'color': AppColors.secondaryTeal
      },
      {
        'icon': Iconsax.shield_tick,
        'text': 'دفع آمن',
        'color': AppColors.pharaohBlue
      },
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return Container(
            width: 100,
            margin:
                EdgeInsets.only(left: index == features.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (feature['color'] as Color).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  feature['icon'] as IconData,
                  size: 28,
                  color: feature['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  feature['text'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: feature['color'] as Color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                // TODO: Navigate to all reviews screen
              },
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  '(${_reviews.length} تقييم)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'تقييمات العملاء',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Iconsax.message_text,
                      size: 40, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  const Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'كن أول من يقيم هذا المنتج',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _reviews
                .take(3)
                .map((review) => _buildReviewCard(review))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              // Date
              Text(
                DateFormat.yMMMd('ar').format(review.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              // User info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (review.isVerifiedPurchase)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 12,
                            color: AppColors.success,
                          ),
                        ),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: AppColors.gold,
                        );
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.background,
                backgroundImage: review.userImageUrl != null
                    ? NetworkImage(review.userImageUrl!)
                    : null,
                child: review.userImageUrl == null
                    ? const Icon(Iconsax.user,
                        size: 20, color: AppColors.textHint)
                    : null,
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    final related = _relatedProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 14,
                    color: AppColors.primaryOrange,
                  ),
                  Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'منتجات مشابهة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: related.length,
            itemBuilder: (context, index) {
              final product = related[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsScreen(product: product),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  margin: EdgeInsets.only(
                      left: index == related.length - 1 ? 0 : 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                product.nameAr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${product.price.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Total price
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإجمالي',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.product.price * _quantity).toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),

            // Add to cart button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  if (_selectedSize != null) {
                    for (int i = 0; i < _quantity; i++) {
                      context.read<AppState>().addToCart(
                            widget.product,
                            _selectedSize!,
                          );
                    }
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Iconsax.tick_circle,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'تمت الإضافة إلى السلة بنجاح',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'عرض السلة',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryOrange,
                        Color(0xFFD4651F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryOrange.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'أضف للسلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Iconsax.shopping_cart,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
