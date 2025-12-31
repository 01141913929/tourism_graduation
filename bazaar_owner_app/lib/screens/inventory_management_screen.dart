import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';

/// شاشة إدارة المخزون
class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  List<Product> _outOfStockProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Low stock threshold setting
  int _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final authProvider = context.read<BazaarAuthProvider>();
    final bazaarId = authProvider.user?.bazaarId;

    if (bazaarId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('products')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      final products = snapshot.docs.map((doc) {
        return Product.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      // Sort by stock quantity
      products.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

      setState(() {
        _allProducts = products;
        _lowStockProducts = products
            .where((p) =>
                p.stockQuantity > 0 && p.stockQuantity <= _lowStockThreshold)
            .toList();
        _outOfStockProducts = products
            .where((p) => p.stockQuantity <= 0 || !p.isInStock)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading inventory: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((p) =>
            p.nameAr.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.nameEn.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _updateStock(Product product, int newQuantity) async {
    try {
      await _firestore.collection('products').doc(product.id).update({
        'stockQuantity': newQuantity,
        'isInStock': newQuantity > 0,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث مخزون "${product.nameAr}"'),
          backgroundColor: AppColors.success,
        ),
      );

      _loadInventory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في التحديث: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showUpdateStockDialog(Product product) {
    final controller =
        TextEditingController(text: product.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.box, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text('تحديث مخزون', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.nameAr,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الكمية الجديدة',
                prefixIcon: const Icon(Iconsax.box),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAdjustButton('-10', () {
                  int current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current - 10).clamp(0, 9999).toString();
                }),
                _buildQuickAdjustButton('-1', () {
                  int current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current - 1).clamp(0, 9999).toString();
                }),
                _buildQuickAdjustButton('+1', () {
                  int current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 1).clamp(0, 9999).toString();
                }),
                _buildQuickAdjustButton('+10', () {
                  int current = int.tryParse(controller.text) ?? 0;
                  controller.text = (current + 10).clamp(0, 9999).toString();
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _updateStock(product, newQty);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdjustButton(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showLowStockSettingsDialog() {
    final controller =
        TextEditingController(text: _lowStockThreshold.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إعدادات التنبيهات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('حد التنبيه للمخزون المنخفض'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الكمية',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newThreshold = int.tryParse(controller.text) ?? 10;
              setState(() => _lowStockThreshold = newThreshold);
              Navigator.pop(context);
              _loadInventory();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_4),
            onPressed: _showLowStockSettingsDialog,
            tooltip: 'إعدادات التنبيهات',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadInventory,
            tooltip: 'تحديث',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'البحث في المنتجات...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('الكل'),
                        const SizedBox(width: 4),
                        _buildBadge(_allProducts.length, Colors.grey),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('منخفض'),
                        const SizedBox(width: 4),
                        _buildBadge(_lowStockProducts.length, Colors.orange),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('نفذ'),
                        const SizedBox(width: 4),
                        _buildBadge(_outOfStockProducts.length, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_getFilteredProducts(_allProducts)),
                _buildProductList(_getFilteredProducts(_lowStockProducts)),
                _buildProductList(_getFilteredProducts(_outOfStockProducts)),
              ],
            ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.box, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('لا توجد منتجات', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    final stockColor = product.stockQuantity <= 0
        ? Colors.red
        : product.stockQuantity <= _lowStockThreshold
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUpdateStockDialog(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameAr,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.box, size: 14, color: stockColor),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stockQuantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.stockQuantity <= 0
                        ? 'نفذ!'
                        : product.stockQuantity <= _lowStockThreshold
                            ? 'منخفض!'
                            : 'متوفر',
                    style: TextStyle(
                      fontSize: 11,
                      color: stockColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Iconsax.edit_2, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Iconsax.image, color: Colors.grey[400]),
    );
  }
}
