import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/widgets/bottom_nav.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/map/screens/interactive_map_screen.dart';
import '../features/products/screens/products_catalog_screen.dart';
import '../providers/app_state.dart';

/// Main app shell with bottom navigation
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 2; // Start with Home (center)

  final List<Widget> _screens = const [
    ProfileScreen(), // 0 - Profile
    CartScreen(), // 1 - Cart
    HomeScreen(), // 2 - Home (center)
    InteractiveMapScreen(), // 3 - Map
    ProductsCatalogScreen(), // 4 - Products
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
