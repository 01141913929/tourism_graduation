import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/colors.dart';
import '../providers/admin_data_provider.dart';
import '../models/product_model.dart';
import '../models/bazaar_model.dart';
import 'add_edit_product_screen.dart';

/// شاشة إدارة المنتجات للـ Super Admin
class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() =>
      _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';
  String _selectedBazaar = 'الكل';
  String _selectedStatus = 'الكل';
  bool _isGridView = false;
  Set<String> _selectedProductIds = {};

  final List<String> _categories = [
    'الكل',
    'تماثيل',
    'مجوهرات',
    'ملابس تقليدية',
    'أواني',
    'لوحات',
    'هدايا تذكارية',
    'بردي',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminDataProvider>().loadAllProducts();
    });
  }

  List<Product> _getFilteredProducts(AdminDataProvider provider) {
    final query = _searchController.text.toLowerCase();

    return provider.allProducts.where((product) {
      // Search filter
      final matchesSearch = query.isEmpty ||
          product.nameAr.toLowerCase().contains(query) ||
          product.nameEn.toLowerCase().contains(query) ||
          product.bazaarName.toLowerCase().contains(query);

      // Category filter
      final matchesCategory =
          _selectedCategory == 'الكل' || product.category == _selectedCategory;

      // Bazaar filter
      final matchesBazaar =
          _selectedBazaar == 'الكل' || product.bazaarId == _selectedBazaar;

      // Status filter
      final matchesStatus = _selectedStatus == 'الكل' ||
          (_selectedStatus == 'نشط' && product.isActive) ||
          (_selectedStatus == 'معطل' && !product.isActive);

      return matchesSearch && matchesCategory && matchesBazaar && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Filters
          _buildFilters(),

          // Statistics Bar
          _buildStatsBar(),

          // Bulk Actions (if items selected)
          if (_selectedProductIds.isNotEmpty) _buildBulkActions(),

          // Products List/Grid
          Expanded(child: _buildProductsList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📦 إدارة المنتجات',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<AdminDataProvider>(
                  builder: (context, provider, _) => Text(
                    'إجمالي ${provider.allProducts.length} منتج من جميع البازارات',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // View Toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.menu_1,
                    color:
                        !_isGridView ? AppColors.primary : AppColors.textHint,
                  ),
                  onPressed: () => setState(() => _isGridView = false),
                  tooltip: 'عرض قائمة',
                ),
                IconButton(
                  icon: Icon(
                    Iconsax.grid_2,
                    color: _isGridView ? AppColors.primary : AppColors.textHint,
                  ),
                  onPressed: () => setState(() => _isGridView = true),
                  tooltip: 'عرض شبكة',
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Refresh Button
          Consumer<AdminDataProvider>(
            builder: (context, provider, _) => OutlinedButton.icon(
              onPressed:
                  provider.isLoading ? null : () => provider.loadAllProducts(),
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('تحديث'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Add Product Button
          ElevatedButton.icon(
            onPressed: () => _navigateToAddProduct(),
            icon: const Icon(Iconsax.add, size: 18),
            label: const Text('إضافة منتج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.white,
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'بحث عن منتج...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Category Filter
          Expanded(
            flex: 2,
            child: _buildDropdown(
              value: _selectedCategory,
              hint: 'الفئة',
              items: _categories,
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
          ),
          const SizedBox(width: 16),

          // Bazaar Filter
          Expanded(
            flex: 2,
            child: Consumer<AdminDataProvider>(
              builder: (context, provider, _) {
                final bazaars = [
                  'الكل',
                  ...provider.allBazaars.map((b) => b.nameAr)
                ];
                return _buildDropdown(
                  value: _selectedBazaar == 'الكل'
                      ? 'الكل'
                      : provider.allBazaars
                          .firstWhere(
                            (b) => b.id == _selectedBazaar,
                            orElse: () => Bazaar(
                              id: 'الكل',
                              nameAr: 'الكل',
                              descriptionAr: '',
                              imageUrl: '',
                              address: '',
                              latitude: 0,
                              longitude: 0,
                              phone: '',
                              ownerUserId: '',
                              createdAt: DateTime.now(),
                            ),
                          )
                          .nameAr,
                  hint: 'البازار',
                  items: bazaars,
                  onChanged: (value) {
                    setState(() {
                      if (value == 'الكل') {
                        _selectedBazaar = 'الكل';
                      } else {
                        final bazaar = provider.allBazaars.firstWhere(
                          (b) => b.nameAr == value,
                          orElse: () => Bazaar(
                            id: 'الكل',
                            nameAr: 'الكل',
                            descriptionAr: '',
                            imageUrl: '',
                            address: '',
                            latitude: 0,
                            longitude: 0,
                            phone: '',
                            ownerUserId: '',
                            createdAt: DateTime.now(),
                          ),
                        );
                        _selectedBazaar = bazaar.id;
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Status Filter
          Expanded(
            flex: 1,
            child: _buildDropdown(
              value: _selectedStatus,
              hint: 'الحالة',
              items: const ['الكل', 'نشط', 'معطل'],
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<AdminDataProvider>(
      builder: (context, provider, _) {
        final products = _getFilteredProducts(provider);
        final activeCount = products.where((p) => p.isActive).length;
        final inactiveCount = products.length - activeCount;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppColors.primary.withOpacity(0.05),
          child: Row(
            children: [
              _buildStatChip(
                icon: Iconsax.box_1,
                label: '${products.length} منتج',
                color: AppColors.primary,
              ),
              const SizedBox(width: 24),
              _buildStatChip(
                icon: Iconsax.tick_circle,
                label: '$activeCount نشط',
                color: AppColors.success,
              ),
              const SizedBox(width: 24),
              _buildStatChip(
                icon: Iconsax.close_circle,
                label: '$inactiveCount معطل',
                color: AppColors.error,
              ),
              const Spacer(),
              if (_selectedProductIds.isNotEmpty)
                Text(
                  'محدد: ${_selectedProductIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.warning.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            'تم تحديد ${_selectedProductIds.length} منتج',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _bulkToggleStatus(true),
            icon: const Icon(Iconsax.tick_circle, size: 16),
            label: const Text('تفعيل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.success,
              side: const BorderSide(color: AppColors.success),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _bulkToggleStatus(false),
            icon: const Icon(Iconsax.close_circle, size: 16),
            label: const Text('إيقاف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _bulkDelete,
            icon: const Icon(Iconsax.trash, size: 16),
            label: const Text('حذف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _selectedProductIds.clear()),
            child: const Text('إلغاء التحديد'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Consumer<AdminDataProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'جاري تحميل المنتجات...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        final products = _getFilteredProducts(provider);

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        if (_isGridView) {
          return _buildProductsGrid(products);
        } else {
          return _buildProductsTable(products);
        }
      },
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
              Iconsax.box_remove,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد منتجات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'لم يتم العثور على نتائج للبحث'
                : 'ابدأ بإضافة منتج جديد',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isEmpty)
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Iconsax.add),
              label: const Text('إضافة منتج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTable(List<Product> products) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: _selectedProductIds.length == products.length &&
                          products.isNotEmpty,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedProductIds =
                                products.map((p) => p.id).toSet();
                          } else {
                            _selectedProductIds.clear();
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 60), // Image
                  const Expanded(
                    flex: 2,
                    child: Text(
                      'المنتج',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'البازار',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'الفئة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'السعر',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'المخزون',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'الحالة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 120), // Actions
                ],
              ),
            ),
            const Divider(height: 1),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductRow(product);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return InkWell(
      onTap: () => _navigateToEditProduct(product),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedProductIds.add(product.id);
                    } else {
                      _selectedProductIds.remove(product.id);
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            ),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.background,
                  child: const Icon(Iconsax.image, color: AppColors.textHint),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.background,
                  child: const Icon(Iconsax.image, color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameAr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.nameEn.isNotEmpty)
                    Text(
                      product.nameEn,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Bazaar
            Expanded(
              child: Text(
                product.bazaarName,
                style: const TextStyle(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Category
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Price
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.price.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.hasDiscount)
                    Text(
                      '${product.oldPrice!.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ),
            // Stock
            SizedBox(
              width: 80,
              child: Text(
                product.isInStock ? '${product.stockQuantity}' : 'نفذ',
                style: TextStyle(
                  color:
                      product.isInStock ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Status
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.isActive ? 'نشط' : 'معطل',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        product.isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Actions
            SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.edit_2, size: 18),
                    onPressed: () => _navigateToEditProduct(product),
                    color: AppColors.primary,
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    icon: Icon(
                      product.isActive ? Iconsax.eye_slash : Iconsax.eye,
                      size: 18,
                    ),
                    onPressed: () => _toggleProductStatus(product),
                    color: AppColors.warning,
                    tooltip: product.isActive ? 'إيقاف' : 'تفعيل',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 18),
                    onPressed: () => _deleteProduct(product),
                    color: AppColors.error,
                    tooltip: 'حذف',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return GestureDetector(
      onTap: () => _navigateToEditProduct(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.background,
                      child: const Icon(
                        Iconsax.image,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                // Checkbox
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedProductIds.remove(product.id);
                        } else {
                          _selectedProductIds.add(product.id);
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                // Status Badge
                if (!product.isActive)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'معطل',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.bazaarName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} ج.م',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        // Quick Actions
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToEditProduct(product);
                            } else if (value == 'toggle') {
                              _toggleProductStatus(product);
                            } else if (value == 'delete') {
                              _deleteProduct(product);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Iconsax.edit_2, size: 18),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    product.isActive
                                        ? Iconsax.eye_slash
                                        : Iconsax.eye,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(product.isActive ? 'إيقاف' : 'تفعيل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Iconsax.trash,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف',
                                      style: TextStyle(color: Colors.red)),
                                ],
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

  // ============ Actions ============

  void _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditProductScreen(),
      ),
    );
    if (result == true && mounted) {
      context.read<AdminDataProvider>().loadAllProducts();
    }
  }

  void _navigateToEditProduct(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );
    if (result == true && mounted) {
      context.read<AdminDataProvider>().loadAllProducts();
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    final provider = context.read<AdminDataProvider>();
    final success = await provider.toggleProductStatus(
      product.id,
      !product.isActive,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (product.isActive ? 'تم إيقاف المنتج' : 'تم تفعيل المنتج')
                : 'حدث خطأ',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: Text(
            'هل أنت متأكد من حذف "${product.nameAr}"؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AdminDataProvider>();
      final success = await provider.deleteProduct(product.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم حذف المنتج' : 'حدث خطأ'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _bulkToggleStatus(bool isActive) async {
    final provider = context.read<AdminDataProvider>();
    final success = await provider.bulkUpdateProducts(
      _selectedProductIds.toList(),
      {'isActive': isActive},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم تحديث ${_selectedProductIds.length} منتج' : 'حدث خطأ',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        setState(() => _selectedProductIds.clear());
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتجات'),
        content: Text(
          'هل أنت متأكد من حذف ${_selectedProductIds.length} منتج؟\nلا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AdminDataProvider>();
      final success =
          await provider.bulkDeleteProducts(_selectedProductIds.toList());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'تم حذف المنتجات' : 'حدث خطأ'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
      if (success) {
        setState(() => _selectedProductIds.clear());
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
