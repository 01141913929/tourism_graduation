import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/premium_effects.dart';
import '../../../models/models.dart';
import '../../../repositories/product_repository.dart';
import 'product_details_screen.dart';

/// World-Class Products Catalog with Collapsing Header
/// كتالوج منتجات احترافي مع Header متحرك
class ProductsCatalogScreen extends StatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ProductRepository _productRepository = ProductRepository();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  String _selectedCategory = 'all';
  String _sortBy = 'popular';
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isCollapsed = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'الكل',
      'icon': Iconsax.category,
      'color': const Color(0xFF6C5CE7)
    },
    {
      'id': 'statues',
      'name': 'تماثيل',
      'icon': Iconsax.crown_1,
      'color': AppColors.gold
    },
    {
      'id': 'jewelry',
      'name': 'مجوهرات',
      'icon': Iconsax.diamonds,
      'color': const Color(0xFFE84393)
    },
    {
      'id': 'accessories',
      'name': 'إكسسوارات',
      'icon': Iconsax.watch,
      'color': AppColors.primaryOrange
    },
    {
      'id': 'books',
      'name': 'كتب',
      'icon': Iconsax.book_1,
      'color': const Color(0xFF00B894)
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scrollController.addListener(_onScroll);
    _loadProducts();
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 50;
    if (shouldCollapse != _isCollapsed) {
      setState(() => _isCollapsed = shouldCollapse);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productRepository.getProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var products = _products.toList();
    if (_selectedCategory != 'all') {
      products =
          products.where((p) => p.category == _selectedCategory).toList();
    }
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        products = products.where((p) => p.isNew).toList() +
            products.where((p) => !p.isNew).toList();
        break;
      default:
        products.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Collapsing Header
              _buildCollapsibleHeader(),
              // Scrollable Content
              Expanded(
                child: _isLoading ? _buildLoading() : _buildProductsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: _isCollapsed
            ? [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: Column(
        children: [
          // Top Bar - Always Visible
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                // Sort Button
                _buildHeaderButton(
                  icon: Iconsax.sort,
                  onTap: _showSortSheet,
                ),
                const Spacer(),
                // Title
                const Text(
                  'المتجر',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Cart
                _buildHeaderButton(
                  icon: Iconsax.bag_2,
                  badge: 2,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('جاري فتح السلة...')),
                    );
                  },
                ),
                const SizedBox(width: 10),
                // Back
                _buildHeaderButton(
                  icon: Iconsax.arrow_right_3,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search Bar - Always Visible
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Iconsax.search_normal,
                      size: 20, color: Color(0xFFAAAAAA)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlign: TextAlign.start,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن منتج...',
                        hintStyle:
                            TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
          // Categories - Collapsible
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isCollapsed ? 0 : 64,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isCollapsed ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[_categories.length - 1 - index];
                      final isSelected = _selectedCategory == cat['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BounceTap(
                          onTap: () =>
                              setState(() => _selectedCategory = cat['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF888888),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Results Info - Always Visible but Compact
          Padding(
            padding: EdgeInsets.fromLTRB(20, _isCollapsed ? 12 : 16, 20, 12),
            child: Row(
              children: [
                // Selected category chip when collapsed
                if (_isCollapsed && _selectedCategory != 'all')
                  GestureDetector(
                    onTap: () => setState(() => _isCollapsed = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: _categories.firstWhere(
                                (c) => c['id'] == _selectedCategory)['color']
                            as Color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _categories.firstWhere(
                                    (c) => c['id'] == _selectedCategory)['name']
                                as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Sort indicator
                GestureDetector(
                  onTap: _showSortSheet,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.arrow_down_1,
                            size: 12, color: Color(0xFF888888)),
                        const SizedBox(width: 4),
                        Text(
                          _getSortLabel(),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredProducts.length} منتج',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    int badge = 0,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text('$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':
        return 'الأقل سعراً';
      case 'price_high':
        return 'الأعلى سعراً';
      case 'newest':
        return 'الأحدث';
      default:
        return 'الأكثر شعبية';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'ترتيب المنتجات',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            _buildSortOption('popular', 'الأكثر شعبية', Iconsax.star_15,
                const Color(0xFFFFB800)),
            _buildSortOption(
                'newest', 'الأحدث', Iconsax.flash_15, const Color(0xFF6C5CE7)),
            _buildSortOption('price_low', 'السعر من الأقل', Iconsax.arrow_up_15,
                const Color(0xFF00B894)),
            _buildSortOption('price_high', 'السعر من الأعلى',
                Iconsax.arrow_down5, const Color(0xFFE84393)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
      String value, String label, IconData icon, Color color) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFF0F0F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? color : const Color(0xFFDDDDDD),
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
          color: AppColors.primaryOrange, strokeWidth: 2.5),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  const Icon(Iconsax.box, size: 48, color: Color(0xFFCCCCCC)),
            ),
            const SizedBox(height: 24),
            const Text('لا توجد منتجات',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('جرب البحث عن شيء آخر',
                style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.6,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              (index / _filteredProducts.length) * 0.5,
              0.5 + (index / _filteredProducts.length) * 0.5,
              curve: Curves.easeOut,
            ),
          )),
          child: FadeTransition(
            opacity: _animationController,
            child: _buildProductCard(_filteredProducts[index]),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return BounceTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      child: SizedBox.expand(
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryOrange),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.35)
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge
                  if (product.isNew || product.hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: product.hasDiscount
                              ? const Color(0xFFFF4757)
                              : AppColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.hasDiscount
                              ? '-${product.discountPercentage.toInt()}%'
                              : 'جديد',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  // Favorite
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Iconsax.heart,
                          size: 16, color: Color(0xFF888888)),
                    ),
                  ),
                  // Add to Cart
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Iconsax.bag_25,
                          size: 18, color: Colors.white),
                    ),
                  ),
                  // Rating
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.star_rounded,
                              size: 12, color: Color(0xFFFFB800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Section
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (product.hasDiscount) ...[
                          Text(
                            '${product.oldPrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFAAAAAA),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
