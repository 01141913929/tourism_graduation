import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings_ar.dart';
import '../../../core/constants/assets.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/product_card.dart';
import '../../../models/models.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/artifact_repository.dart';
import '../../../services/firestore_service.dart';
import '../../artifacts/screens/artifacts_screen.dart';
import '../../artifacts/screens/artifact_details_screen.dart';
import '../../shop/screens/boutique_screen.dart';
import '../../products/screens/product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _carouselController = PageController();
  final ProductRepository _productRepository = ProductRepository();
  final ArtifactRepository _artifactRepository = ArtifactRepository();
  final FirestoreService _firestoreService = FirestoreService();

  List<Product> _products = [];
  List<Artifact> _artifacts = [];
  List<ExhibitionHall> _exhibitionHalls = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      debugPrint('🏠 HomeScreen: Loading data...');

      // Load products from Firestore
      final products = await _productRepository.getProducts();
      debugPrint('🏠 HomeScreen: Loaded ${products.length} products');

      // Load artifacts from Firestore
      final artifacts = await _artifactRepository.getArtifacts();
      debugPrint('🏠 HomeScreen: Loaded ${artifacts.length} artifacts');

      // Load exhibition halls from Firestore (camelCase collection name)
      final hallsData =
          await _firestoreService.getCollection(collection: 'exhibitionHalls');
      final halls = hallsData.map((e) => ExhibitionHall.fromJson(e)).toList();
      debugPrint('🏠 HomeScreen: Loaded ${halls.length} exhibition halls');

      if (mounted) {
        setState(() {
          _products = products;
          _artifacts = artifacts;
          _exhibitionHalls = halls;

          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ HomeScreen Error loading data: $e');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.secondaryTeal, Color(0xFF2AA89A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with logo
              _buildHeader(),

              // Exhibition Halls Carousel
              _buildExhibitionCarousel(),

              // Featured Artifacts Section
              _buildFeaturedArtifacts(),

              // New Experience Section
              _buildNewExperienceSection(),

              // Interactive Map Banner
              _buildInteractiveMapBanner(),

              // Gift Boutique Section
              _buildGiftBoutiqueSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'En',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Logo
          Row(
            children: [
              const Text(
                'المتحف المصري الكبير',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.museum,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _exhibitionHalls.isEmpty ? 1 : _exhibitionHalls.length,
            reverse: true,
            itemBuilder: (context, index) {
              if (_exhibitionHalls.isEmpty) {
                return _buildLoadingCard();
              }
              final hall = _exhibitionHalls[index];
              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryTeal, Color(0xFF2AA89A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative pattern
                    Positioned(
                      left: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 40,
                      bottom: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: hall.imageUrl,
                                fit: BoxFit.cover,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStringsAr.mainHalls,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_back,
                                        color: AppColors.secondaryTeal,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppStringsAr.exploreNow,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Page indicator
        Center(
          child: SmoothPageIndicator(
            controller: _carouselController,
            count: _exhibitionHalls.isEmpty ? 1 : _exhibitionHalls.length,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              spacing: 6,
              activeDotColor: AppColors.primaryOrange,
              dotColor: AppColors.divider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedArtifacts() {
    final artifacts = _artifacts.take(3).toList();

    return Column(
      children: [
        SectionHeader(
          title: AppStringsAr.featuredArtifacts,
          actionText: AppStringsAr.viewAll,
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ArtifactsScreen(),
              ),
            );
          },
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: artifacts.length,
            itemBuilder: (context, index) {
              final artifact = artifacts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtifactDetailsScreen(artifact: artifact),
                    ),
                  );
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: artifact.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artifact.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _buildNewExperienceSection() {
    final newProducts = _products.where((p) => p.isNew).take(5).toList();

    if (newProducts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'جديد',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'وصل حديثاً',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: newProducts.length,
              itemBuilder: (context, index) {
                final product = newProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: _buildSmallProductCard(product),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMapBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.secondaryTeal, Color(0xFF14665A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: 0.3,
                child: CachedNetworkImage(
                  imageUrl: AppAssets.mapPlaceholder,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // CTA Button
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back,
                            color: AppColors.white, size: 14),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'المتاحف',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'الخريطة التفاعلية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftBoutiqueSection() {
    final products = _products.take(6).toList();

    return Column(
      children: [
        SectionHeader(
          title: AppStringsAr.giftBoutique,
          actionText: AppStringsAr.viewAll,
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BoutiqueScreen(),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildSmallProductCard(product);
          },
        ),
      ],
    );
  }

  Widget _buildSmallProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    '${product.price.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      fontSize: 10,
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
    );
  }
}
