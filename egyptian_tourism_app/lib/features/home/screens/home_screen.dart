import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/widgets/premium_effects.dart';
import '../../../models/models.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/product_repository.dart';
import '../../../repositories/artifact_repository.dart';
import '../../../services/firestore_service.dart';
import '../../../services/recommendation_service.dart';
import '../../artifacts/screens/artifacts_screen.dart';
import '../../artifacts/screens/artifact_details_screen.dart';
import '../../products/screens/product_details_screen.dart';
import '../../profile/screens/favorites_screen.dart';
import '../../profile/screens/notifications_screen.dart';

/// Premium Home Screen - World-Class E-Commerce Design
/// تصميم عالمي احترافي مستوحى من أفضل التطبيقات
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToStore;

  const HomeScreen({super.key, this.onNavigateToStore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Controllers
  final PageController _heroController = PageController(viewportFraction: 1.0);
  final ScrollController _scrollController = ScrollController();

  // Repositories & Services
  final ProductRepository _productRepository = ProductRepository();
  final ArtifactRepository _artifactRepository = ArtifactRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final RecommendationService _recommendationService = RecommendationService();

  // Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Data
  List<Product> _products = [];
  List<Artifact> _artifacts = [];
  // ignore: unused_field
  List<ExhibitionHall> _categories = [];
  bool _isLoading = true;

  // AI Recommendations
  RecommendationResult? _recommendations;
  bool _isLoadingRecs = true;

  // State
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _loadRecommendations();
    _startAutoScroll();

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _heroController.hasClients) {
        final nextPage = (_currentHeroIndex + 1) % 3;
        _heroController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final products = await _productRepository.getProducts();
      final artifacts = await _artifactRepository.getArtifacts();
      final categoriesData =
          await _firestoreService.getCollection(collection: 'exhibitionHalls');
      final categories =
          categoriesData.map((e) => ExhibitionHall.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _products = products;
          _artifacts = artifacts;
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ HomeScreen Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🎯 تحميل الاقتراحات الذكية
  Future<void> _loadRecommendations() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId ?? 'guest';

      final result = await _recommendationService.getRecommendations(
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _recommendations = result;
          _isLoadingRecs = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Recommendations Error: $e');
      if (mounted) setState(() => _isLoadingRecs = false);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          _isScrolled ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,
        body: _isLoading ? _buildLoadingScreen() : _buildContent(),
      ),
    );
  }

  // ==================== LOADING SCREEN ====================
  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Iconsax.shop, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: AppColors.primaryOrange,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MAIN CONTENT ====================
  Widget _buildContent() {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeroSection(),
                    _buildCategoriesSection(),
                    _buildRecommendationsSection(),
                    _buildTrendingSection(),
                    _buildExclusiveSection(),
                    _buildNewArrivalsSection(),
                    _buildCollectionsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Floating Header
        _buildFloatingHeader(),
      ],
    );
  }

  // ==================== FLOATING HEADER ====================
  Widget _buildFloatingHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: _isScrolled ? AppColors.white : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Left Icons
          Row(
            children: [
              _buildHeaderIcon(
                Iconsax.notification,
                badge: 3,
                isLight: !_isScrolled,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderIcon(
                Iconsax.heart,
                isLight: !_isScrolled,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Logo & Title
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EGYPT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: _isScrolled
                          ? AppColors.textSecondary
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _isScrolled ? AppColors.textPrimary : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Iconsax.shop, color: Colors.white, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon,
      {int badge = 0, bool isLight = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withOpacity(0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: isLight
                  ? Border.all(color: Colors.white.withOpacity(0.2))
                  : null,
            ),
            child: Icon(
              icon,
              color: isLight ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (badge > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLight ? const Color(0xFF1A1A2E) : AppColors.white,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== HERO SECTION ====================
  Widget _buildHeroSection() {
    // صور فرعونية عالية الجودة
    final heroes = [
      {
        'title': AppStrings.isArabic
            ? 'اكتشف روائع\nالحضارة المصرية'
            : 'Discover the Wonders\nof Egyptian Civilization',
        'subtitle': AppStrings.isArabic
            ? 'تحف أصلية وهدايا تذكارية فريدة'
            : 'Authentic artifacts & unique souvenirs',
        'cta': AppStrings.isArabic ? 'تسوق الآن' : 'Shop Now',
        'image':
            'https://images.unsplash.com/photo-1539650116574-8efeb43e2750?w=800&q=80',
        'accent': AppColors.primaryOrange,
      },
      {
        'title': AppStrings.isArabic
            ? 'عروض حصرية\nلفترة محدودة'
            : 'Exclusive Offers\nLimited Time',
        'subtitle': AppStrings.isArabic
            ? 'خصومات تصل إلى 50% على المنتجات المميزة'
            : 'Up to 50% off on featured products',
        'cta': AppStrings.isArabic ? 'اكتشف العروض' : 'Discover Offers',
        'image':
            'https://images.unsplash.com/photo-1568322445389-f64ac2515020?w=800&q=80',
        'accent': AppColors.gold,
      },
      {
        'title': AppStrings.isArabic
            ? 'مجموعة الفراعنة\nالجديدة'
            : 'New Pharaohs\nCollection',
        'subtitle': AppStrings.isArabic
            ? 'قطع فنية مستوحاة من الملوك'
            : 'Art pieces inspired by Kings',
        'cta': AppStrings.isArabic ? 'شاهد المجموعة' : 'View Collection',
        'image':
            'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=800&q=80',
        'accent': AppColors.gold,
      },
    ];

    return SizedBox(
      height: 480,
      child: Stack(
        children: [
          PageView.builder(
            controller: _heroController,
            onPageChanged: (i) => setState(() => _currentHeroIndex = i),
            itemCount: heroes.length,
            itemBuilder: (context, index) {
              final hero = heroes[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image with Blur
                  CachedNetworkImage(
                    imageUrl: hero['image'] as String,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                  // Dark Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Subtle Gold Accent Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          (hero['accent'] as Color).withOpacity(0.15),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Title with Shadow for better readability
                          Text(
                            hero['title'] as String,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              hero['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          BounceTap(
                            onTap: widget.onNavigateToStore,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: hero['accent'] as Color,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: (hero['accent'] as Color)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.arrow_left_2,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    hero['cta'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Indicator
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(heroes.length, (i) {
                final isActive = i == _currentHeroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CATEGORIES ====================
  Widget _buildCategoriesSection() {
    final categories = [
      {
        'icon': Iconsax.crown_1,
        'name': AppStrings.isArabic ? 'تحف' : 'Artifacts',
        'color': const Color(0xFFFFD700), // Gold
        'bg': const Color(0xFF16213E), // Deep Pharaoh Blue
      },
      {
        'icon': Iconsax.gift,
        'name': AppStrings.isArabic ? 'هدايا' : 'Gifts',
        'color': const Color(0xFFF39C12), // Orange/Gold
        'bg': const Color(0xFF2C3E50), // Slate
      },
      {
        'icon': Iconsax.diamonds,
        'name': AppStrings.isArabic ? 'مجوهرات' : 'Jewelry',
        'color': const Color(0xFF00E5FF), // Cyan/Teal
        'bg': const Color(0xFF003D4D), // Dark Teal
      },
      {
        'icon': Iconsax.book_1,
        'name': AppStrings.isArabic ? 'كتب' : 'Books',
        'color': const Color(0xFFE0E0E0), // Silver
        'bg': const Color(0xFF2B2B2B), // Dark Grey
      },
      {
        'icon': Iconsax.brush_1,
        'name': AppStrings.isArabic ? 'فنون' : 'Arts',
        'color': const Color(0xFFD4AF37), // Metallic Gold
        'bg': const Color(0xFF3E2723), // Dark Brown
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF39C12)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.isArabic ? 'استكشف الفئات' : 'Explore Categories',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Iconsax.category5, size: 22, color: AppColors.textSecondary.withValues(alpha: 0.7)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final color = cat['color'] as Color;
                final bgColor = cat['bg'] as Color;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: BounceTap(
                    onTap: widget.onNavigateToStore,
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                bgColor.withValues(alpha: 0.8),
                                bgColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: bgColor.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: color.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                                spreadRadius: 1,
                              ),
                            ],
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              cat['icon'] as IconData,
                              color: color,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary.withValues(alpha: 0.85),
                            letterSpacing: 0.3,
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
      ),
    );
  }

  // ==================== AI RECOMMENDATIONS ====================
  Widget _buildRecommendationsSection() {
    // حالة التحميل — Shimmer Loading
    if (_isLoadingRecs) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.magic_star, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.isArabic ? 'مقترحة لك 💎' : 'Picked for You 💎',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: 3,
                itemBuilder: (_, i) => Container(
                  width: 170,
                  margin: EdgeInsets.only(left: i == 2 ? 0 : 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // لو مفيش اقتراحات
    if (_recommendations == null || _recommendations!.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final section in _recommendations!.sections)
          if (section.products.isNotEmpty) _buildRecSection(section),
      ],
    );
  }

  Widget _buildRecSection(RecommendationSection section) {
    final isArabic = AppStrings.isArabic;

    return Column(
      children: [
        // === Header ===
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              // See All
              GestureDetector(
                onTap: widget.onNavigateToStore,
                child: Row(
                  children: [
                    Icon(Iconsax.arrow_left_2, size: 18, color: AppColors.primaryOrange),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.all,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryOrange),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // AI Badge (لقسم AI فقط)
              if (section.type == 'ai')
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.magic_star, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              // Title
              Text(
                section.getTitle(isArabic),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        // Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              section.getSubtitle(isArabic),
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        // === Product Cards ===
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: section.products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(left: index == section.products.length - 1 ? 0 : 14),
                child: _buildRecommendationCard(section.products[index], section.type),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Product product, String sectionType) {
    return BounceTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: sectionType == 'ai'
                  ? const Color(0xFF6C63FF).withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: sectionType == 'ai'
              ? Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === الصورة ===
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[100],
                          child: const Center(child: Icon(Iconsax.image, color: Colors.grey)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Center(child: Icon(Iconsax.gallery_slash, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  // AI Sparkle badge
                  if (sectionType == 'ai')
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Iconsax.magic_star, size: 16, color: Colors.white),
                      ),
                    ),
                  // Discount badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '-${product.discountPercentage.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // === معلومات المنتج ===
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // اسم المنتج
                    Flexible(
                      child: Text(
                        product.getName(AppStrings.isArabic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // السعر + التقييم
                    Row(
                      children: [
                        // تقييم
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 2),
                            Icon(Iconsax.star1, size: 13, color: AppColors.gold),
                          ],
                        ),
                        const Spacer(),
                        // السعر
                        if (product.hasDiscount)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '${product.oldPrice!.toInt()} ج',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        Text(
                          '${product.price.toInt()} ج',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: product.hasDiscount ? AppColors.error : AppColors.primaryOrange,
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

  // ==================== TRENDING ====================
  Widget _buildTrendingSection() {
    final trending = _products.take(4).toList();
    if (trending.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionTitle(AppStrings.isArabic ? 'الأكثر رواجاً' : 'Trending',
            onSeeAll: widget.onNavigateToStore),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: trending.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == trending.length - 1 ? 0 : 16,
                ),
                child: _buildProductCard(trending[index], large: true),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== EXCLUSIVE ====================
  Widget _buildExclusiveSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppStrings.isArabic ? '✨ حصرياً' : '✨ Exclusive',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.isArabic
                            ? 'مجموعة الملوك'
                            : 'Kings Collection',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.isArabic
                            ? 'قطع محدودة الإصدار'
                            : 'Limited Edition Pieces',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BounceTap(
                        onTap: widget.onNavigateToStore,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.arrow_left_2,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.isArabic ? 'اكتشف' : 'Explore',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
  }

  // ==================== NEW ARRIVALS ====================
  Widget _buildNewArrivalsSection() {
    final newItems = _products.where((p) => p.isNew).take(6).toList();
    if (newItems.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSectionTitle(AppStrings.isArabic ? 'وصل حديثاً' : 'New Arrivals',
            showBadge: true, onSeeAll: widget.onNavigateToStore),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: newItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  left: index == newItems.length - 1 ? 0 : 14,
                ),
                child: _buildProductCard(newItems[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== COLLECTIONS ====================
  Widget _buildCollectionsSection() {
    final featured = _artifacts.take(6).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSectionTitle(
            AppStrings.isArabic ? 'مجموعات مميزة' : 'Featured Collections',
            onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ArtifactsScreen()),
          );
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: featured.length,
            itemBuilder: (context, index) {
              return _buildCollectionCard(featured[index]);
            },
          ),
        ),
      ],
    );
  }

  // ==================== SHARED WIDGETS ====================
  Widget _buildSectionTitle(String title,
      {VoidCallback? onSeeAll, bool showBadge = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Icon(
                    Iconsax.arrow_left_2,
                    size: 18,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.all,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (showBadge)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppStrings.isArabic ? 'جديد' : 'New',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {bool large = false}) {
    return BounceTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product)),
      ),
      child: Container(
        width: large ? 180 : 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: SizedBox.expand(
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (product.isNew)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppStrings.isArabic ? 'جديد' : 'New',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 36,
                      height: 36,
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
                  if (product.rating > 0)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        product.nameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.bag_2,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.oldPrice != null)
                              Text(
                                '${product.oldPrice!.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.6),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '${product.price.toStringAsFixed(0)} ج.م',
                              style: const TextStyle(
                                fontSize: 16,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(Artifact artifact) {
    return BounceTap(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtifactDetailsScreen(artifact: artifact),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: artifact.imageUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artifact.era,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.crown_1,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
