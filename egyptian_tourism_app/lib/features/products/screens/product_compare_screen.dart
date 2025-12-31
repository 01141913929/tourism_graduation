import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import 'product_details_screen.dart';

/// مزود لتتبع المنتجات المختارة للمقارنة
class CompareProvider extends ChangeNotifier {
  final List<Product> _products = [];
  static const int maxProducts = 3;

  List<Product> get products => List.unmodifiable(_products);
  int get count => _products.length;
  bool get isEmpty => _products.isEmpty;
  bool get canAdd => _products.length < maxProducts;

  bool isSelected(String productId) {
    return _products.any((p) => p.id == productId);
  }

  void toggle(Product product) {
    if (isSelected(product.id)) {
      _products.removeWhere((p) => p.id == product.id);
    } else if (_products.length < maxProducts) {
      _products.add(product);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void clear() {
    _products.clear();
    notifyListeners();
  }
}

/// شاشة مقارنة المنتجات
class ProductCompareScreen extends StatelessWidget {
  final List<Product> products;

  const ProductCompareScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('مقارنة ${products.length} منتجات'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: products.length < 2
          ? _buildNotEnoughProducts(context)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 200,
                  dataRowMaxHeight: double.infinity,
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  columns: products
                      .map((p) => DataColumn(
                            label: _buildProductHeader(context, p),
                          ))
                      .toList(),
                  rows: _buildComparisonRows(),
                ),
              ),
            ),
    );
  }

  Widget _buildNotEnoughProducts(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.chart_2, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'أضف منتجين على الأقل للمقارنة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك مقارنة حتى 3 منتجات',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.egyptianGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('العودة للتسوق'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, Product product) {
    return SizedBox(
      width: 150,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  child: Icon(Iconsax.image, color: Colors.grey[400]),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: Icon(Iconsax.image, color: Colors.grey[400]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.nameAr,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.price.toStringAsFixed(0)} ج.م',
            style: TextStyle(
              color: AppColors.egyptianGold,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  List<DataRow> _buildComparisonRows() {
    return [
      // Price row
      DataRow(
        cells: products.map((p) => DataCell(_buildPriceCell(p))).toList(),
      ),
      // Category row
      DataRow(
        cells: products
            .map((p) => DataCell(
                  _buildValueCell('الفئة', p.category),
                ))
            .toList(),
      ),
      // Rating row
      DataRow(
        cells: products.map((p) => DataCell(_buildRatingCell(p))).toList(),
      ),
      // Bazaar row
      DataRow(
        cells: products
            .map((p) => DataCell(
                  _buildValueCell('البازار', p.bazaarName),
                ))
            .toList(),
      ),
      // Stock row
      DataRow(
        cells: products.map((p) => DataCell(_buildStockCell(p))).toList(),
      ),
      // Description row
      DataRow(
        cells: products
            .map((p) => DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      p.descriptionAr,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ))
            .toList(),
      ),
    ];
  }

  Widget _buildPriceCell(Product product) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('السعر',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${product.price.toStringAsFixed(0)} ج.م',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${product.discountPercentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (product.hasDiscount)
            Text(
              '${product.oldPrice!.toStringAsFixed(0)} ج.م',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildValueCell(String label, String value) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCell(Product product) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('التقييم',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < product.rating.round() ? Iconsax.star1 : Iconsax.star,
                  size: 14,
                  color: Colors.amber,
                );
              }),
              const SizedBox(width: 4),
              Text(
                product.rating.toStringAsFixed(1),
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          Text(
            '(${product.reviewCount} تقييم)',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCell(Product product) {
    final inStock = product.stockQuantity > 0;
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('التوفر',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: inStock ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                inStock ? 'متوفر (${product.stockQuantity})' : 'غير متوفر',
                style: TextStyle(
                  color: inStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget للفلتر العائم للمقارنة
class CompareFloatingButton extends StatelessWidget {
  final CompareProvider provider;
  final VoidCallback onPressed;

  const CompareFloatingButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.egyptianGold,
      foregroundColor: Colors.white,
      icon: Badge(
        label: Text('${provider.count}'),
        child: const Icon(Iconsax.chart_2),
      ),
      label: const Text('قارن المنتجات'),
    );
  }
}
