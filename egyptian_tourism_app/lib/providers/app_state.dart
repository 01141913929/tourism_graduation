import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/coupon_model.dart';
import '../repositories/cart_repository.dart';
import '../repositories/product_repository.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';

/// App state provider for cart and user data
class AppState extends ChangeNotifier {
  AuthProvider? _authProvider;
  final CartRepository _cartRepository;
  final ProductRepository _productRepository;

  // Local cart items (synced with Firebase when logged in)
  List<CartItem> _cartItems = [];

  // Selected navigation index
  int _selectedNavIndex = 0;

  // Favorite artifacts (local when not logged in)
  final List<String> _favoriteArtifactIds = [];

  // Applied coupon for discount
  Coupon? _appliedCoupon;

  // Stream subscriptions
  StreamSubscription? _cartSubscription;

  AppState({
    CartRepository? cartRepository,
    ProductRepository? productRepository,
  })  : _cartRepository = cartRepository ?? CartRepository(),
        _productRepository = productRepository ?? ProductRepository();

  // Set auth provider (called from ProxyProvider)
  void setAuthProvider(AuthProvider authProvider) {
    if (_authProvider?.userId != authProvider.userId) {
      _authProvider = authProvider;
      _syncCart();
    }
  }

  // Sync cart with Firebase when user logs in
  void _syncCart() {
    _cartSubscription?.cancel();

    final userId = _authProvider?.userId;
    if (userId != null) {
      // Initialize Notifications
      NotificationService().initialize(userId);

      _cartSubscription = _cartRepository.streamCartItems(userId).listen(
        (cartItemModels) async {
          // Convert CartItemModel to CartItem with full product data
          final newCartItems = <CartItem>[];
          for (final model in cartItemModels) {
            final product =
                await _productRepository.getProduct(model.productId);
            if (product != null) {
              newCartItems.add(CartItem(
                product: product,
                selectedSize: model.selectedSize,
                quantity: model.quantity,
              ));
            }
          }
          _cartItems = newCartItems;
          notifyListeners();
        },
      );
    } else {
      // Clear cart when logged out
      _cartItems = [];
      notifyListeners();
    }
  }

  // Getters
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get selectedNavIndex => _selectedNavIndex;
  List<String> get favoriteArtifactIds =>
      List.unmodifiable(_favoriteArtifactIds);

  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get cartSubtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  double get cartTaxes => cartSubtotal * 0.14; // 14% VAT in Egypt

  double get cartShipping => cartSubtotal > 0 ? 20.0 : 0;

  Coupon? get appliedCoupon => _appliedCoupon;

  double get cartDiscount {
    if (_appliedCoupon == null) return 0;
    return _appliedCoupon!.calculateDiscount(cartSubtotal);
  }

  double get cartTotal =>
      cartSubtotal + cartTaxes + cartShipping - cartDiscount;

  bool get isLoggedIn => _authProvider?.isAuthenticated ?? false;

  // Methods
  void setNavIndex(int index) {
    _selectedNavIndex = index;
    notifyListeners();
  }

  Future<void> addToCart(Product product, String size) async {
    final userId = _authProvider?.userId;

    if (userId != null) {
      // Sync with Firebase
      final cartItemModel = CartItemModel(
        id: '${product.id}_$size',
        productId: product.id,
        selectedSize: size,
        quantity: 1,
      );
      await _cartRepository.addToCart(userId, cartItemModel);
    } else {
      // Local only
      final existingIndex = _cartItems.indexWhere(
        (item) => item.product.id == product.id && item.selectedSize == size,
      );

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          product: product,
          selectedSize: size,
        ));
      }
      notifyListeners();
    }
  }

  Future<void> removeFromCart(int index) async {
    if (index < 0 || index >= _cartItems.length) return;

    final userId = _authProvider?.userId;
    final item = _cartItems[index];

    if (userId != null) {
      // Sync with Firebase
      final itemId = '${item.product.id}_${item.selectedSize}';
      await _cartRepository.removeFromCart(userId, itemId);
    } else {
      // Local only
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int index, int quantity) async {
    if (index < 0 || index >= _cartItems.length) return;

    final userId = _authProvider?.userId;
    final item = _cartItems[index];

    if (userId != null) {
      // Sync with Firebase
      final itemId = '${item.product.id}_${item.selectedSize}';
      await _cartRepository.updateQuantity(userId, itemId, quantity);
    } else {
      // Local only
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    final userId = _authProvider?.userId;

    if (userId != null) {
      // Sync with Firebase
      await _cartRepository.clearCart(userId);
    } else {
      // Local only
      _cartItems.clear();
      notifyListeners();
    }
  }

  // Coupon methods
  void applyCoupon(Coupon coupon) {
    if (coupon.isValid && coupon.calculateDiscount(cartSubtotal) > 0) {
      _appliedCoupon = coupon;
      notifyListeners();
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  void toggleFavorite(String artifactId) {
    if (_favoriteArtifactIds.contains(artifactId)) {
      _favoriteArtifactIds.remove(artifactId);
    } else {
      _favoriteArtifactIds.add(artifactId);
    }
    notifyListeners();
  }

  bool isFavorite(String artifactId) {
    return _favoriteArtifactIds.contains(artifactId);
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
  }
}
