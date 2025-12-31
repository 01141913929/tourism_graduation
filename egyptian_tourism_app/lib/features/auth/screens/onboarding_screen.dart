import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings_ar.dart';
import 'login_screen.dart';

/// Onboarding screen with Egyptian theme
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: AppStringsAr.onboardingTitle1,
      description: AppStringsAr.onboardingDesc1,
      imageUrl:
          'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?w=800',
      icon: Iconsax.discover,
      gradient: const LinearGradient(
        colors: [Color(0xFF1A8B7C), Color(0xFF14665A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    OnboardingData(
      title: AppStringsAr.onboardingTitle2,
      description: AppStringsAr.onboardingDesc2,
      imageUrl:
          'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=800',
      icon: Iconsax.scan,
      gradient: const LinearGradient(
        colors: [Color(0xFFE87A2B), Color(0xFFD4651F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    OnboardingData(
      title: AppStringsAr.onboardingTitle3,
      description: AppStringsAr.onboardingDesc3,
      imageUrl:
          'https://images.unsplash.com/photo-1551918120-9739cb430c6d?w=800',
      icon: Iconsax.shopping_bag,
      gradient: const LinearGradient(
        colors: [Color(0xFFC4942B), Color(0xFF9A7422)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
  ];

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  Future<void> _navigateToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            reverse: true, // RTL support
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: _currentPage < _pages.length - 1
                ? TextButton(
                    onPressed: _navigateToLogin,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      AppStringsAr.skip,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const SizedBox(),
          ),

          // Bottom Section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        CachedNetworkImage(
          imageUrl: data.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            decoration: BoxDecoration(gradient: data.gradient),
          ),
          errorWidget: (_, __, ___) => Container(
            decoration: BoxDecoration(gradient: data.gradient),
          ),
        ),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.3, 0.6, 1.0],
            ),
          ),
        ),

        // Decorative Elements
        _buildDecorativeElements(data),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Icon Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    data.icon,
                    color: AppColors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  data.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  data.description,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.85),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 140), // Space for bottom section
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeElements(OnboardingData data) {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: 100,
          right: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ),
        // Left side small circles
        Positioned(
          top: 200,
          left: 30,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          top: 250,
          left: 60,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Page Indicator
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                  spacing: 8,
                  activeDotColor: AppColors.primaryOrange,
                  dotColor: AppColors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Next / Get Started Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _goToNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPage < _pages.length - 1) ...[
                      const Icon(Icons.arrow_back, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _currentPage == _pages.length - 1
                          ? AppStringsAr.getStarted
                          : AppStringsAr.next,
                      style: const TextStyle(
                        fontSize: 18,
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
    );
  }
}

/// Data model for onboarding pages
class OnboardingData {
  final String title;
  final String description;
  final String imageUrl;
  final IconData icon;
  final Gradient gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.gradient,
  });
}
