import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings_ar.dart';
import '../../../providers/auth_provider.dart';
import '../../../app/app_shell.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

/// Animated splash screen with Egyptian theme
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _circleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _circle1Scale;
  late Animation<double> _circle2Scale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNextScreen();
  }

  void _initAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Circle animations
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _circle1Scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );
    _circle2Scale = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textController.forward();
    });
  }

  void _navigateToNextScreen() {
    Future.delayed(const Duration(milliseconds: 3000), () async {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final prefs = await SharedPreferences.getInstance();
        final bool onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

        // Check if user is already logged in
        final isLoggedIn = authProvider.isAuthenticated;

        Widget nextScreen;
        if (isLoggedIn) {
          nextScreen = const AppShell();
        } else if (onboardingSeen) {
          nextScreen = const LoginScreen();
        } else {
          nextScreen = const OnboardingScreen();
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => nextScreen,
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryOrange,
              Color(0xFFD4651F),
              Color(0xFFB85518),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Stack(
          children: [
            _buildDecorativeCircles(),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 32),
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: _buildWelcomeText(),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textOpacity,
                child: _buildLoadingIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return AnimatedBuilder(
      animation: _circleController,
      builder: (context, _) {
        return Stack(
          children: [
            // Top right circle
            Positioned(
              top: -80,
              right: -80,
              child: Transform.scale(
                scale: _circle1Scale.value,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            // Bottom left circle
            Positioned(
              bottom: -60,
              left: -60,
              child: Transform.scale(
                scale: _circle2Scale.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            // Center small circle
            Positioned(
              top: 150,
              left: 50,
              child: Transform.scale(
                scale: _circle1Scale.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            // Right side circle
            Positioned(
              bottom: 200,
              right: 30,
              child: Transform.scale(
                scale: _circle2Scale.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Museum Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.museum_rounded,
              color: AppColors.primaryOrange,
              size: 60,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // App Name
        const Text(
          'المتحف المصري الكبير',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.crown5,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                AppStringsAr.discoverHistory,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
