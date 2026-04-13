import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/map/screens/interactive_map_screen.dart';
import '../features/products/screens/products_catalog_screen.dart';
import '../features/chatbot/screens/chatbot_screen.dart';
import '../providers/app_state.dart';
import '../providers/language_provider.dart';

/// Main app shell with bottom navigation + AI chatbot FAB
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 2; // Start with Home (center)
  late final NotchBottomBarController _notchController;

  @override
  void initState() {
    super.initState();
    _notchController = NotchBottomBarController(index: _currentIndex);
  }

  @override
  void dispose() {
    _notchController.dispose();
    super.dispose();
  }

  List<Widget> get _screens => [
        const ProfileScreen(), // 0 - Profile
        const CartScreen(), // 1 - Cart
        HomeScreen(
          onNavigateToStore: () {
            setState(() => _currentIndex = 4);
            _notchController.jumpTo(4);
          },
        ), // 2 - Home
        const InteractiveMapScreen(), // 3 - Map
        const ProductsCatalogScreen(), // 4 - Products
      ];

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false, // يمنع الناف بار من الصعود لمنتصف الشاشة مع الكيبورد
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // 🤖 زر الشات بوت الذكي — (Premium UI)
      floatingActionButton: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFD700), // Premium Gold
              Color(0xFFF39C12), // Dark Gold / Orange
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF39C12).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.4),
              blurRadius: 5,
              offset: const Offset(0, 0),
              blurStyle: BlurStyle.inner,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome, // A more AI-centric icon
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: AppBottomNavBar(
          controller: _notchController,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
