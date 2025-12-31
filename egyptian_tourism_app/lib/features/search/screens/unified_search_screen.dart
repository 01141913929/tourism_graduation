import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/bazaar_model.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/bazaar_repository.dart';
import '../../products/screens/product_details_screen.dart';
import '../../shop/screens/bazaar_details_screen.dart';

/// شاشة البحث الموحد - منتجات وبازارات
class UnifiedSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const UnifiedSearchScreen({super.key, this.initialQuery});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ProductRepository _productRepository = ProductRepository();
  final BazaarRepository _bazaarRepository = BazaarRepository();

  List<Product> _productResults = [];
  List<Bazaar> _bazaarResults = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];

  bool _isSearching = false;
  bool _showHistory = true;
  String _currentQuery = '';

  // Popular search terms
  final List<String> _popularSearches = [
    'حلي فرعونية',
    'تحف يدوية',
    'سجاد',
    'بازار خان الخليلي',
    'تماثيل',
    'أواني نحاسية',
    'ملابس تقليدية',
    'عطور شرقية',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    } else {
      // Focus on search field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await prefs.setStringList('search_history', _searchHistory);
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _showHistory = true;
        _suggestions = [];
        _productResults = [];
        _bazaarResults = [];
      });
      return;
    }

    // Generate suggestions
    setState(() {
      _showHistory = false;
      _suggestions =
          _popularSearches.where((s) => s.contains(query)).take(5).toList();
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showHistory = false;
      _currentQuery = query;
    });

    await _saveSearchHistory(query);

    try {
      // Search products and bazaars in parallel
      final results = await Future.wait([
        _productRepository.searchProducts(query),
        _bazaarRepository.searchBazaars(query),
      ]);

      setState(() {
        _productResults = results[0] as List<Product>;
        _bazaarResults = results[1] as List<Bazaar>;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showHistory = true;
      _productResults = [];
      _bazaarResults = [];
      _suggestions = [];
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _showHistory ? _buildHistoryView() : _buildResultsView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_right_3, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتجات أو بازارات...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon:
                Icon(Iconsax.search_normal, color: Colors.grey[500], size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Iconsax.close_circle,
                        color: Colors.grey[500], size: 20),
                    onPressed: _clearSearch,
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onSubmitted: _performSearch,
        ),
      ),
      bottom: !_showHistory
          ? TabBar(
              controller: _tabController,
              labelColor: AppColors.egyptianGold,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.egyptianGold,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.box, size: 18),
                      const SizedBox(width: 8),
                      Text('المنتجات (${_productResults.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.shop, size: 18),
                      const SizedBox(width: 8),
                      Text('البازارات (${_bazaarResults.length})'),
                    ],
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildHistoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suggestions (if typing)
          if (_suggestions.isNotEmpty) ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: Icon(Iconsax.search_normal,
                      color: Colors.grey[500], size: 20),
                  title: Text(suggestion),
                  onTap: () {
                    _searchController.text = suggestion;
                    _performSearch(suggestion);
                  },
                );
              },
            ),
            const Divider(height: 32),
          ],

          // Search History
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'عمليات البحث السابقة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: Text(
                    'مسح الكل',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return InkWell(
                  onTap: () {
                    _searchController.text = query;
                    _performSearch(query);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.clock, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(query),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular Searches
          const Text(
            'عمليات بحث شائعة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((query) {
              return InkWell(
                onTap: () {
                  _searchController.text = query;
                  _performSearch(query);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.egyptianGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.trend_up,
                          size: 16, color: AppColors.egyptianGold),
                      const SizedBox(width: 8),
                      Text(
                        query,
                        style: TextStyle(color: AppColors.egyptianGold),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_productResults.isEmpty && _bazaarResults.isEmpty) {
      return _buildEmptyResults();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsTab(),
        _buildBazaarsTab(),
      ],
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.search_status, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'لا توجد نتائج لـ "$_currentQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب كلمات بحث مختلفة',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_productResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد منتجات',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _productResults.length,
      itemBuilder: (context, index) {
        final product = _productResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(
                        color: Colors.grey[200],
                        child: Icon(Iconsax.image,
                            color: Colors.grey[400], size: 32),
                      ),
                      errorWidget: (c, u, e) => Container(
                        color: Colors.grey[200],
                        child: Icon(Iconsax.image,
                            color: Colors.grey[400], size: 32),
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.egyptianGold,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${product.oldPrice!.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
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

  Widget _buildBazaarsTab() {
    if (_bazaarResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.shop, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'لا توجد بازارات',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bazaarResults.length,
      itemBuilder: (context, index) {
        final bazaar = _bazaarResults[index];
        return _buildBazaarCard(bazaar);
      },
    );
  }

  Widget _buildBazaarCard(Bazaar bazaar) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BazaarDetailsScreen(bazaarId: bazaar.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: bazaar.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: Icon(Iconsax.shop, color: Colors.grey[400]),
                ),
                errorWidget: (c, u, e) => Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey[200],
                  child: Icon(Iconsax.shop, color: Colors.grey[400]),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bazaar.nameAr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (bazaar.isVerified)
                          Icon(Icons.verified,
                              color: AppColors.egyptianGreen, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bazaar.governorate,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Iconsax.star1, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          bazaar.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          ' (${bazaar.reviewCount})',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bazaar.isOpen
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bazaar.isOpen ? 'مفتوح' : 'مغلق',
                            style: TextStyle(
                              color: bazaar.isOpen ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
