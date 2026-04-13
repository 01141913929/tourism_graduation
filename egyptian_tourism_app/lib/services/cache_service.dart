import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../models/bazaar_model.dart';

/// Cache Service for storing products, categories, and bazaars locally
/// Reduces Firebase queries and improves app performance
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  // Cache Keys
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _bazaarsKey = 'cached_bazaars';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _featuredProductsKey = 'cached_featured_products';

  // Cache Duration (in minutes)
  static const int _productsCacheDuration = 30;
  static const int _categoriesCacheDuration = 60;
  static const int _bazaarsCacheDuration = 30;

  // In-memory cache for faster access
  List<Product>? _cachedProducts;
  List<String>? _cachedCategories;
  List<Bazaar>? _cachedBazaars;
  List<Product>? _cachedFeaturedProducts;

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('✅ Cache service initialized');
  }

  /// Ensure SharedPreferences is ready
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== PRODUCTS ====================

  /// Cache products list
  Future<void> cacheProducts(List<Product> products) async {
    try {
      final prefs = await _preferences;
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_productsKey, jsonEncode(jsonList));
      await _updateLastSync(_productsKey);
      _cachedProducts = products;
      debugPrint('✅ Cached ${products.length} products');
    } catch (e) {
      debugPrint('❌ Error caching products: $e');
    }
  }

  /// Get cached products
  Future<List<Product>?> getCachedProducts() async {
    // Return in-memory cache if available
    if (_cachedProducts != null) {
      return _cachedProducts;
    }

    try {
      final prefs = await _preferences;

      // Check if cache is still valid
      if (!await _isCacheValid(_productsKey, _productsCacheDuration)) {
        debugPrint('⏰ Products cache expired');
        return null;
      }

      final jsonString = prefs.getString(_productsKey);
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      _cachedProducts = jsonList.map((json) => Product.fromJson(json)).toList();
      debugPrint('📦 Loaded ${_cachedProducts!.length} products from cache');
      return _cachedProducts;
    } catch (e) {
      debugPrint('❌ Error reading cached products: $e');
      return null;
    }
  }

  /// Get product by ID from cache
  Future<Product?> getCachedProduct(String productId) async {
    final products = await getCachedProducts();
    if (products == null) return null;

    try {
      return products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Cache featured products
  Future<void> cacheFeaturedProducts(List<Product> products) async {
    try {
      final prefs = await _preferences;
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_featuredProductsKey, jsonEncode(jsonList));
      await _updateLastSync(_featuredProductsKey);
      _cachedFeaturedProducts = products;
      debugPrint('✅ Cached ${products.length} featured products');
    } catch (e) {
      debugPrint('❌ Error caching featured products: $e');
    }
  }

  /// Get cached featured products
  Future<List<Product>?> getCachedFeaturedProducts() async {
    if (_cachedFeaturedProducts != null) {
      return _cachedFeaturedProducts;
    }

    try {
      final prefs = await _preferences;

      if (!await _isCacheValid(_featuredProductsKey, _productsCacheDuration)) {
        return null;
      }

      final jsonString = prefs.getString(_featuredProductsKey);
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      _cachedFeaturedProducts =
          jsonList.map((json) => Product.fromJson(json)).toList();
      return _cachedFeaturedProducts;
    } catch (e) {
      debugPrint('❌ Error reading cached featured products: $e');
      return null;
    }
  }

  // ==================== CATEGORIES ====================

  /// Cache categories list
  Future<void> cacheCategories(List<String> categories) async {
    try {
      final prefs = await _preferences;
      await prefs.setStringList(_categoriesKey, categories);
      await _updateLastSync(_categoriesKey);
      _cachedCategories = categories;
      debugPrint('✅ Cached ${categories.length} categories');
    } catch (e) {
      debugPrint('❌ Error caching categories: $e');
    }
  }

  /// Get cached categories
  Future<List<String>?> getCachedCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories;
    }

    try {
      final prefs = await _preferences;

      if (!await _isCacheValid(_categoriesKey, _categoriesCacheDuration)) {
        debugPrint('⏰ Categories cache expired');
        return null;
      }

      final categories = prefs.getStringList(_categoriesKey);
      if (categories == null) return null;

      _cachedCategories = categories;
      debugPrint(
          '📦 Loaded ${_cachedCategories!.length} categories from cache');
      return _cachedCategories;
    } catch (e) {
      debugPrint('❌ Error reading cached categories: $e');
      return null;
    }
  }

  // ==================== BAZAARS ====================

  /// Cache bazaars list
  Future<void> cacheBazaars(List<Bazaar> bazaars) async {
    try {
      final prefs = await _preferences;
      final jsonList = bazaars.map((b) => b.toJson()).toList();
      await prefs.setString(_bazaarsKey, jsonEncode(jsonList));
      await _updateLastSync(_bazaarsKey);
      _cachedBazaars = bazaars;
      debugPrint('✅ Cached ${bazaars.length} bazaars');
    } catch (e) {
      debugPrint('❌ Error caching bazaars: $e');
    }
  }

  /// Get cached bazaars
  Future<List<Bazaar>?> getCachedBazaars() async {
    if (_cachedBazaars != null) {
      return _cachedBazaars;
    }

    try {
      final prefs = await _preferences;

      if (!await _isCacheValid(_bazaarsKey, _bazaarsCacheDuration)) {
        debugPrint('⏰ Bazaars cache expired');
        return null;
      }

      final jsonString = prefs.getString(_bazaarsKey);
      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      _cachedBazaars = jsonList.map((json) => Bazaar.fromJson(json)).toList();
      debugPrint('📦 Loaded ${_cachedBazaars!.length} bazaars from cache');
      return _cachedBazaars;
    } catch (e) {
      debugPrint('❌ Error reading cached bazaars: $e');
      return null;
    }
  }

  /// Get bazaar by ID from cache
  Future<Bazaar?> getCachedBazaar(String bazaarId) async {
    final bazaars = await getCachedBazaars();
    if (bazaars == null) return null;

    try {
      return bazaars.firstWhere((b) => b.id == bazaarId);
    } catch (e) {
      return null;
    }
  }

  // ==================== UTILITIES ====================

  /// Update last sync time for a specific key
  Future<void> _updateLastSync(String key) async {
    final prefs = await _preferences;
    await prefs.setInt(
        '${_lastSyncKey}_$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if cache is still valid
  Future<bool> _isCacheValid(String key, int durationMinutes) async {
    final prefs = await _preferences;
    final lastSync = prefs.getInt('${_lastSyncKey}_$key');

    if (lastSync == null) return false;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime).inMinutes;

    return difference < durationMinutes;
  }

  /// Get time until cache expires (in minutes)
  Future<int?> getCacheExpiryTime(String cacheType) async {
    final prefs = await _preferences;
    String key;
    int duration;

    switch (cacheType) {
      case 'products':
        key = _productsKey;
        duration = _productsCacheDuration;
        break;
      case 'categories':
        key = _categoriesKey;
        duration = _categoriesCacheDuration;
        break;
      case 'bazaars':
        key = _bazaarsKey;
        duration = _bazaarsCacheDuration;
        break;
      default:
        return null;
    }

    final lastSync = prefs.getInt('${_lastSyncKey}_$key');
    if (lastSync == null) return null;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime).inMinutes;

    return duration - difference;
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await _preferences;
      await prefs.remove(_productsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_bazaarsKey);
      await prefs.remove(_featuredProductsKey);
      await prefs.remove('${_lastSyncKey}_$_productsKey');
      await prefs.remove('${_lastSyncKey}_$_categoriesKey');
      await prefs.remove('${_lastSyncKey}_$_bazaarsKey');
      await prefs.remove('${_lastSyncKey}_$_featuredProductsKey');

      // Clear in-memory cache
      _cachedProducts = null;
      _cachedCategories = null;
      _cachedBazaars = null;
      _cachedFeaturedProducts = null;

      debugPrint('🗑️ All cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String cacheType) async {
    try {
      final prefs = await _preferences;

      switch (cacheType) {
        case 'products':
          await prefs.remove(_productsKey);
          await prefs.remove('${_lastSyncKey}_$_productsKey');
          _cachedProducts = null;
          break;
        case 'categories':
          await prefs.remove(_categoriesKey);
          await prefs.remove('${_lastSyncKey}_$_categoriesKey');
          _cachedCategories = null;
          break;
        case 'bazaars':
          await prefs.remove(_bazaarsKey);
          await prefs.remove('${_lastSyncKey}_$_bazaarsKey');
          _cachedBazaars = null;
          break;
        case 'featured':
          await prefs.remove(_featuredProductsKey);
          await prefs.remove('${_lastSyncKey}_$_featuredProductsKey');
          _cachedFeaturedProducts = null;
          break;
      }

      debugPrint('🗑️ Cache cleared: $cacheType');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Invalidate product cache (when product is updated)
  Future<void> invalidateProduct(String productId) async {
    if (_cachedProducts == null) return;

    _cachedProducts!.removeWhere((p) => p.id == productId);
    await cacheProducts(_cachedProducts!);
  }

  /// Update single product in cache
  Future<void> updateCachedProduct(Product product) async {
    if (_cachedProducts == null) return;

    final index = _cachedProducts!.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _cachedProducts![index] = product;
      await cacheProducts(_cachedProducts!);
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'productsCount': _cachedProducts?.length ?? 0,
      'categoriesCount': _cachedCategories?.length ?? 0,
      'bazaarsCount': _cachedBazaars?.length ?? 0,
      'featuredCount': _cachedFeaturedProducts?.length ?? 0,
      'productsExpiry': await getCacheExpiryTime('products'),
      'categoriesExpiry': await getCacheExpiryTime('categories'),
      'bazaarsExpiry': await getCacheExpiryTime('bazaars'),
    };
  }
}
