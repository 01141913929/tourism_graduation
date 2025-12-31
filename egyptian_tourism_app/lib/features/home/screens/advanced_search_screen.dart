import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/bazaar_model.dart';
import '../../products/screens/product_details_screen.dart';
import '../../shop/screens/bazaar_details_screen.dart';

/// شاشة البحث المتقدم
class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Product> _products = [];
  List<Bazaar> _bazaars = [];
  bool _isLoading = false;
  String _searchQuery = '';

  // Filters
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedGovernorate;
  double? _minRating;
  String? _selectedBazaarId;
  String _sortBy = 'الأحدث';

  List<Map<String, dynamic>> _bazaarsList = [];

  final List<String> _categories = [
    'الكل',
    'تماثيل',
    'مجوهرات',
    'ملابس تقليدية',
    'أواني',
    'لوحات',
    'هدايا تذكارية',
  ];

  final List<String> _governorates = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الأقصر',
    'أسوان',
    'الإسكندرية',
  ];

  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBazaars();
  }

  Future<void> _loadBazaars() async {
    try {
      final snapshot = await _firestore.collection('bazaars').get();
      setState(() {
        _bazaarsList = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc.data()['nameAr'] ?? 'بازار',
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading bazaars: $e');
    }
  }

  Future<void> _search() async {
    if (_searchQuery.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Search products
      final productsSnapshot = await _firestore.collection('products').get();

      final products = productsSnapshot.docs
          .map((doc) => Product.fromJson({...doc.data(), 'id': doc.id}))
          .where((product) {
        final matchesSearch = product.nameAr
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            product.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.descriptionAr
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesCategory = _selectedCategory == null ||
            _selectedCategory == 'الكل' ||
            product.category == _selectedCategory;

        final matchesMinPrice =
            _minPrice == null || product.price >= _minPrice!;
        final matchesMaxPrice =
            _maxPrice == null || product.price <= _maxPrice!;

        final matchesRating =
            _minRating == null || product.rating >= _minRating!;

        final matchesBazaar =
            _selectedBazaarId == null || product.bazaarId == _selectedBazaarId;

        return matchesSearch &&
            matchesCategory &&
            matchesMinPrice &&
            matchesMaxPrice &&
            matchesRating &&
            matchesBazaar;
      }).toList();

      // Sort products
      switch (_sortBy) {
        case 'الأقل سعراً':
          products.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'الأعلى سعراً':
          products.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'الأعلى تقييماً':
          products.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'الأحدث':
        default:
          // Keep default order
          break;
      }

      // Search bazaars
      final bazaarsSnapshot = await _firestore.collection('bazaars').get();

      final bazaars = bazaarsSnapshot.docs
          .map((doc) => Bazaar.fromJson({...doc.data(), 'id': doc.id}))
          .where((bazaar) {
        final matchesSearch = bazaar.nameAr
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            bazaar.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            bazaar.descriptionAr
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        final matchesGovernorate = _selectedGovernorate == null ||
            _selectedGovernorate == 'الكل' ||
            bazaar.governorate == _selectedGovernorate;

        return matchesSearch && matchesGovernorate;
      }).toList();

      // Save to recent searches
      if (!_recentSearches.contains(_searchQuery)) {
        _recentSearches.insert(0, _searchQuery);
        if (_recentSearches.length > 5) {
          _recentSearches = _recentSearches.sublist(0, 5);
        }
      }

      setState(() {
        _products = products;
        _bazaars = bazaars;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersSheet(
        categories: _categories,
        governorates: _governorates,
        bazaars: _bazaarsList,
        selectedCategory: _selectedCategory,
        selectedGovernorate: _selectedGovernorate,
        selectedBazaarId: _selectedBazaarId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        sortBy: _sortBy,
        onApply: (category, governorate, bazaarId, minPrice, maxPrice,
            minRating, sortBy) {
          setState(() {
            _selectedCategory = category;
            _selectedGovernorate = governorate;
            _selectedBazaarId = bazaarId;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _minRating = minRating;
            _sortBy = sortBy;
          });
          Navigator.pop(context);
          if (_searchQuery.isNotEmpty) _search();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            _searchQuery = value;
          },
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'ابحث عن منتجات أو بازارات...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _products = [];
                        _bazaars = [];
                      });
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: _search,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.gold,
          tabs: [
            Tab(text: 'المنتجات (${_products.length})'),
            Tab(text: 'البازارات (${_bazaars.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchQuery.isEmpty
              ? _buildRecentSearches()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProductsResults(),
                    _buildBazaarsResults(),
                  ],
                ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('بحث سابق',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: const Text('مسح'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _searchQuery = search;
                    _search();
                  },
                  child: Chip(
                    label: Text(search),
                    avatar: const Icon(Iconsax.clock, size: 16),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          const Text('اقتراحات', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'تماثيل فرعونية',
              'مجوهرات',
              'هدايا تذكارية',
              'ملابس تقليدية',
              'أواني نحاسية'
            ].map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = suggestion;
                  _searchQuery = suggestion;
                  _search();
                },
                child: Chip(
                  label: Text(suggestion),
                  backgroundColor: AppColors.gold.withOpacity(0.1),
                  side: BorderSide.none,
                  labelStyle: TextStyle(color: AppColors.gold),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsResults() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('لا توجد منتجات مطابقة'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.grey[200]),
                errorWidget: (c, u, e) => Container(
                  color: Colors.grey[200],
                  child: Icon(Iconsax.image, color: Colors.grey[400]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameAr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.bazaarName ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price.toStringAsFixed(0)} ج.م',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBazaarsResults() {
    if (_bazaars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.shop, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('لا توجد بازارات مطابقة'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bazaars.length,
      itemBuilder: (context, index) {
        final bazaar = _bazaars[index];
        return _buildBazaarCard(bazaar);
      },
    );
  }

  Widget _buildBazaarCard(Bazaar bazaar) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BazaarDetailsScreen(bazaarId: bazaar.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: bazaar.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(color: Colors.grey[200]),
                errorWidget: (c, u, e) => Container(
                  color: Colors.grey[200],
                  child: Icon(Iconsax.shop, color: Colors.grey[400]),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bazaar.nameAr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        if (bazaar.isVerified)
                          Icon(Icons.verified,
                              color: Colors.green[600], size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bazaar.governorate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Iconsax.star1,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(bazaar.rating.toStringAsFixed(1)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: bazaar.isOpen
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            bazaar.isOpen ? 'مفتوح' : 'مغلق',
                            style: TextStyle(
                              color: bazaar.isOpen ? Colors.green : Colors.red,
                              fontSize: 11,
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

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

/// Sheet للفلاتر
class _FiltersSheet extends StatefulWidget {
  final List<String> categories;
  final List<String> governorates;
  final List<Map<String, dynamic>> bazaars;
  final String? selectedCategory;
  final String? selectedGovernorate;
  final String? selectedBazaarId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String sortBy;
  final Function(String?, String?, String?, double?, double?, double?, String)
      onApply;

  const _FiltersSheet({
    required this.categories,
    required this.governorates,
    required this.bazaars,
    this.selectedCategory,
    this.selectedGovernorate,
    this.selectedBazaarId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _category;
  late String? _governorate;
  late String? _bazaarId;
  late double? _rating;
  late String _sortBy;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;

  final List<String> _sortOptions = [
    'الأحدث',
    'الأقل سعراً',
    'الأعلى سعراً',
    'الأعلى تقييماً',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _governorate = widget.selectedGovernorate;
    _bazaarId = widget.selectedBazaarId;
    _rating = widget.minRating;
    _sortBy = widget.sortBy;
    _minPriceController =
        TextEditingController(text: widget.minPrice?.toString() ?? '');
    _maxPriceController =
        TextEditingController(text: widget.maxPrice?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الفلاتر',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _category = null;
                      _governorate = null;
                      _bazaarId = null;
                      _rating = null;
                      _sortBy = 'الأحدث';
                      _minPriceController.clear();
                      _maxPriceController.clear();
                    });
                  },
                  child: const Text('مسح الكل'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sort by
            const Text('ترتيب حسب',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((opt) {
                final isSelected = opt == _sortBy;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _sortBy = opt),
                  selectedColor: AppColors.primaryOrange,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Category
            const Text('التصنيف',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.categories.map((cat) {
                final isSelected = cat == _category;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Bazaar
            if (widget.bazaars.isNotEmpty) ...[
              const Text('البازار',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String?>(
                  value: _bazaarId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('اختر بازار'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('جميع البازارات'),
                    ),
                    ...widget.bazaars.map((b) => DropdownMenuItem<String?>(
                          value: b['id'] as String,
                          child: Text(b['name'] as String),
                        )),
                  ],
                  onChanged: (value) => setState(() => _bazaarId = value),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Governorate
            const Text('المحافظة',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.governorates.map((gov) {
                final isSelected = gov == _governorate;
                return ChoiceChip(
                  label: Text(gov),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _governorate = gov),
                  selectedColor: AppColors.gold,
                  labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Rating
            const Text('التقييم (على الأقل)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _rating != null && rating <= _rating!;
                return GestureDetector(
                  onTap: () => setState(() => _rating = rating.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            if (_rating != null)
              TextButton(
                onPressed: () => setState(() => _rating = null),
                child: const Text('مسح التقييم'),
              ),
            const SizedBox(height: 20),

            // Price
            const Text('السعر', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'من',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'إلى',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(
                    _category,
                    _governorate,
                    _bazaarId,
                    double.tryParse(_minPriceController.text),
                    double.tryParse(_maxPriceController.text),
                    _rating,
                    _sortBy,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('تطبيق الفلاتر',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
