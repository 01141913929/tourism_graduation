import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../models/models.dart';
import '../../../models/bazaar_model.dart';
import '../../../repositories/bazaar_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../services/share_service.dart';
import '../../products/screens/product_details_screen.dart';
import '../../../core/widgets/product_card.dart';

/// شاشة تفاصيل البازار
class BazaarDetailsScreen extends StatefulWidget {
  final String bazaarId;

  const BazaarDetailsScreen({super.key, required this.bazaarId});

  @override
  State<BazaarDetailsScreen> createState() => _BazaarDetailsScreenState();
}

class _BazaarDetailsScreenState extends State<BazaarDetailsScreen> {
  final BazaarRepository _bazaarRepository = BazaarRepository();
  final ProductRepository _productRepository = ProductRepository();

  Bazaar? _bazaar;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bazaar = await _bazaarRepository.getBazaar(widget.bazaarId);
      final products =
          await _productRepository.getProductsByBazaar(widget.bazaarId);
      setState(() {
        _bazaar = bazaar;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading bazaar: $e');
    }
  }

  Future<void> _launchPhone() async {
    if (_bazaar?.phone == null) return;
    final uri = Uri.parse('tel:${_bazaar!.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMap() async {
    if (_bazaar == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_bazaar!.latitude},${_bazaar!.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareBazaar() async {
    if (_bazaar == null) return;
    await ShareService.copyBazaarShareText(_bazaar!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('تم نسخ رابط البازار'),
            ],
          ),
          backgroundColor: AppColors.egyptianGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bazaar == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.shop, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('البازار غير موجود',
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.egyptianGold,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _bazaar!.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Colors.grey[300]),
                    errorWidget: (c, u, e) => Container(
                      color: Colors.grey[300],
                      child:
                          Icon(Iconsax.shop, size: 64, color: Colors.grey[500]),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Bazaar info
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_bazaar!.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.egyptianGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text('موثق',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    _bazaar!.isOpen ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _bazaar!.isOpen ? 'مفتوح' : 'مغلق',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bazaar!.nameAr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Iconsax.star1, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _bazaar!.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              ' (${_bazaar!.reviewCount} تقييم)',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.call,
                          label: 'اتصل',
                          onTap: _launchPhone,
                          color: AppColors.egyptianGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.location,
                          label: 'الموقع',
                          onTap: _launchMap,
                          color: AppColors.egyptianBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Iconsax.share,
                          label: 'مشاركة',
                          onTap: _shareBazaar,
                          color: AppColors.egyptianGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSection(
                    title: 'عن البازار',
                    child: Text(
                      _bazaar!.descriptionAr,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info Section
                  _buildSection(
                    title: 'معلومات',
                    child: Column(
                      children: [
                        _buildInfoRow(
                            Iconsax.location, 'العنوان', _bazaar!.address),
                        _buildInfoRow(
                            Iconsax.map, 'المحافظة', _bazaar!.governorate),
                        _buildInfoRow(Iconsax.clock, 'ساعات العمل',
                            _bazaar!.workingHours),
                        _buildInfoRow(Iconsax.call, 'الهاتف', _bazaar!.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Products Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'المنتجات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      Text(
                        '${_products.length} منتج',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Products Grid
          _products.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Iconsax.box, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('لا توجد منتجات',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = _products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailsScreen(product: product),
                            ),
                          ),
                        );
                      },
                      childCount: _products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.egyptianGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.egyptianGold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
