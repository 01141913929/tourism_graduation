import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_strings.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../models/models.dart';
import '../../services/cache_service.dart';

/// Advanced Search Screen with Filters, Sorting, and Real-time Search
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final CacheService _cacheService = CacheService();

  // Search State
  List<Product> _searchResults = [];
  List<Product> _allProducts = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  // Filter State
  bool _showFilters = false;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minRating = 0;
  String? _selectedCategory;
  String? _selectedBazaar;
  SortOption _sortOption = SortOption.newest;

  // Categories and Bazaars for filters
  List<String> _categories = [];
  List<String> _bazaarNames = [];

  // Animation
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );
    _loadInitialData();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Try cache first
      final cachedProducts = await _cacheService.getCachedProducts();
      if (cachedProducts != null) {
        _allProducts = cachedProducts;
      }

      // Extract unique categories from products
      _categories = _allProducts
          .map((p) => p.category)
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList();

      // Extract unique bazaar names
      _bazaarNames = _allProducts
          .map((p) => p.bazaarName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      // Update price range based on products
      if (_allProducts.isNotEmpty) {
        final prices = _allProducts.map((p) => p.price).toList();
        final minPrice = prices.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.reduce((a, b) => a > b ? a : b);
        _priceRange = RangeValues(minPrice, maxPrice);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }

    setState(() => _isLoading = false);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    // Filter products based on query
    List<Product> results = _allProducts.where((product) {
      final nameMatch =
          product.nameAr.toLowerCase().contains(query.toLowerCase()) ||
              product.nameEn.toLowerCase().contains(query.toLowerCase());
      final descMatch = product.descriptionAr.toLowerCase().contains(
          query.toLowerCase()); // Changed from description to descriptionAr
      final categoryMatch = product.category.toLowerCase().contains(
          query.toLowerCase()); // Changed from categoryName to category
      final bazaarMatch =
          product.bazaarName.toLowerCase().contains(query.toLowerCase());

      return nameMatch || descMatch || categoryMatch || bazaarMatch;
    }).toList();

    // Apply filters
    results = _applyFilters(results);

    // Apply sorting
    results = _applySorting(results);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });

    // Save to recent searches
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    return products.where((product) {
      // Price filter
      if (product.price < _priceRange.start ||
          product.price > _priceRange.end) {
        return false;
      }

      // Rating filter
      if (product.rating < _minRating) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && product.category != _selectedCategory) {
        // Changed from categoryId to category
        return false;
      }

      // Bazaar filter
      if (_selectedBazaar != null && product.bazaarName != _selectedBazaar) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Product> _applySorting(List<Product> products) {
    switch (_sortOption) {
      case SortOption.priceLowToHigh:
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.topRated:
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.newest:
        products.sort((a, b) => b.isNew ? 1 : -1);
        break;
    }
    return products;
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _minRating = 0;
      _selectedCategory = null;
      _selectedBazaar = null;
      _sortOption = SortOption.newest;
    });
    _performSearch(_searchController.text);
  }

  void _applyFiltersAndSearch() {
    _performSearch(_searchController.text);
    _toggleFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Panel
          _buildFilterPanel(),

          // Results
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_right_3, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: AppStrings.searchProducts,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon: const Icon(Iconsax.search_normal_1,
                color: AppColors.textHint, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle,
                        color: AppColors.textHint, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                        _hasSearched = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                _showFilters ? Iconsax.filter_tick : Iconsax.filter,
                color: _hasActiveFilters
                    ? AppColors.primaryOrange
                    : AppColors.textPrimary,
              ),
              onPressed: _toggleFilters,
            ),
            if (_hasActiveFilters)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool get _hasActiveFilters {
    return _selectedCategory != null ||
        _selectedBazaar != null ||
        _minRating > 0 ||
        _priceRange.start > 0 ||
        _priceRange.end < 10000;
  }

  Widget _buildFilterPanel() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _filterAnimation.value,
            child: _buildFilterContent(),
          ),
        );
      },
    );
  }

  Widget _buildFilterContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
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
          // Sort Options
          Text(AppStrings.sortBy,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SortOption.values.map((option) {
              return ChoiceChip(
                label: Text(_getSortLabel(option)),
                selected: _sortOption == option,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _sortOption = option);
                  }
                },
                selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _sortOption == option
                      ? AppColors.primaryOrange
                      : AppColors.textSecondary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.priceRange,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} ${AppStrings.currency}',
                style: const TextStyle(
                    color: AppColors.primaryOrange, fontSize: 12),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.primaryOrange,
            inactiveColor: AppColors.divider,
            onChanged: (values) {
              setState(() => _priceRange = values);
            },
          ),

          const SizedBox(height: 16),

          // Rating Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.rating,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                '${_minRating.toInt()}+ ⭐',
                style: const TextStyle(
                    color: AppColors.primaryOrange, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 5,
            activeColor: AppColors.primaryOrange,
            inactiveColor: AppColors.divider,
            onChanged: (value) {
              setState(() => _minRating = value);
            },
          ),

          const SizedBox(height: 16),

          // Category Filter
          if (_categories.isNotEmpty) ...[
            Text(AppStrings.category,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 35,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(AppStrings.all),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                        selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                      ),
                    );
                  }
                  final category = _categories[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.divider),
                  ),
                  child: Text(AppStrings.clearFilters),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFiltersAndSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppStrings.applyFilters),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.priceLowToHigh:
        return AppStrings.priceLowToHigh;
      case SortOption.priceHighToLow:
        return AppStrings.priceHighToLow;
      case SortOption.topRated:
        return AppStrings.topRated;
      case SortOption.newest:
        return AppStrings.newest;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const ShimmerProductCard();
      },
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.recentSearches,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: Text(AppStrings.clearFilters),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return StaggeredListAnimation(
                  index: _recentSearches.indexOf(search),
                  child: ActionChip(
                    avatar: const Icon(Iconsax.clock, size: 16),
                    label: Text(search),
                    onPressed: () {
                      _searchController.text = search;
                      _performSearch(search);
                    },
                    backgroundColor: AppColors.background,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular Categories
          Text(
            AppStrings.categories,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_categories.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.take(6).map((category) {
                return StaggeredListAnimation(
                  index: _categories.indexOf(category),
                  child: ActionChip(
                    avatar: const Icon(Iconsax.category, size: 16),
                    label: Text(category),
                    onPressed: () {
                      _searchController.text = category;
                      _performSearch(category);
                    },
                    backgroundColor: AppColors.primaryOrange.withOpacity(0.1),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInAnimation(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_status,
              size: 80,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noSearchResults,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.tryDifferentKeywords,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (_hasActiveFilters)
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Iconsax.filter_remove),
                label: Text(AppStrings.clearFilters),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.background,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} ${AppStrings.products}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                _getSortLabel(_sortOption),
                style: const TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return StaggeredListAnimation(
                index: index,
                child: HeroProductCard(
                  productId: product.id,
                  child: _buildProductCard(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return BounceAnimation(
      onTap: () {
        // Navigate to product details
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
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
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: HeroProductImage(
                      productId: product.id,
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Discount Badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.heart,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.bazaarName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.formatPrice(product.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

/// Sort options enum
enum SortOption {
  priceLowToHigh,
  priceHighToLow,
  topRated,
  newest,
}
