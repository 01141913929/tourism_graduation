import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

/// Repository for product data operations
class ProductRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'products';

  ProductRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Get all products
  Future<List<Product>> getProducts() async {
    final data = await _firestoreService.getCollection(collection: _collection);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Get products with pagination
  /// Returns a PaginatedProductResult containing products, lastDoc, and hasMore
  Future<PaginatedProductResult> getProductsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? category,
    String? bazaarId,
  }) async {
    final result = await _firestoreService.getPaginatedCollection(
      collection: _collection,
      limit: limit,
      startAfter: startAfter,
      queryBuilder: (ref) {
        Query<Map<String, dynamic>> query = ref;
        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }
        if (bazaarId != null) {
          query = query.where('bazaarId', isEqualTo: bazaarId);
        }
        return query.orderBy('createdAt', descending: true);
      },
    );

    return PaginatedProductResult(
      products: result.documents.map((e) => Product.fromJson(e)).toList(),
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
    );
  }

  /// Stream all products
  Stream<List<Product>> streamProducts() {
    return _firestoreService
        .streamCollection(collection: _collection)
        .map((data) => data.map((e) => Product.fromJson(e)).toList());
  }

  /// Get product by ID
  Future<Product?> getProduct(String productId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: productId,
    );
    if (data == null) return null;
    return Product.fromJson({...data, 'id': productId});
  }

  /// Stream single product
  Stream<Product?> streamProduct(String productId) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: productId)
        .map((data) {
      if (data == null) return null;
      return Product.fromJson({...data, 'id': productId});
    });
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('category', isEqualTo: category),
    );
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Stream products by category
  Stream<List<Product>> streamProductsByCategory(String category) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('category', isEqualTo: category),
        )
        .map((data) => data.map((e) => Product.fromJson(e)).toList());
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts() async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('isFeatured', isEqualTo: true),
    );
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Stream featured products
  Stream<List<Product>> streamFeaturedProducts() {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('isFeatured', isEqualTo: true),
        )
        .map((data) => data.map((e) => Product.fromJson(e)).toList());
  }

  /// Get new products
  Future<List<Product>> getNewProducts() async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('isNew', isEqualTo: true),
    );
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Stream new products
  Stream<List<Product>> streamNewProducts() {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('isNew', isEqualTo: true),
        )
        .map((data) => data.map((e) => Product.fromJson(e)).toList());
  }

  /// Search products by name
  Future<List<Product>> searchProducts(String query) async {
    // Note: Firestore doesn't support full-text search natively
    // For production, consider using Algolia or Elasticsearch
    final data = await _firestoreService.getCollection(collection: _collection);
    final products = data.map((e) => Product.fromJson(e)).toList();

    final lowerQuery = query.toLowerCase();
    return products.where((p) {
      return p.nameAr.toLowerCase().contains(lowerQuery) ||
          p.descriptionAr.toLowerCase().contains(lowerQuery) ||
          p.nameEn.toLowerCase().contains(lowerQuery) ||
          p.bazaarName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get products by bazaar ID
  Future<List<Product>> getProductsByBazaar(String bazaarId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('bazaarId', isEqualTo: bazaarId),
    );
    return data.map((e) => Product.fromJson(e)).toList();
  }

  /// Stream products by bazaar
  Stream<List<Product>> streamProductsByBazaar(String bazaarId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('bazaarId', isEqualTo: bazaarId),
        )
        .map((data) => data.map((e) => Product.fromJson(e)).toList());
  }

  /// Search products with filters
  Future<List<Product>> searchProductsAdvanced({
    String? query,
    String? bazaarId,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    final data = await _firestoreService.getCollection(collection: _collection);
    var products = data.map((e) => Product.fromJson(e)).toList();

    // Apply filters
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      products = products.where((p) {
        return p.nameAr.toLowerCase().contains(lowerQuery) ||
            p.descriptionAr.toLowerCase().contains(lowerQuery) ||
            p.nameEn.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (bazaarId != null && bazaarId.isNotEmpty) {
      products = products.where((p) => p.bazaarId == bazaarId).toList();
    }

    if (category != null && category.isNotEmpty) {
      products = products.where((p) => p.category == category).toList();
    }

    if (minPrice != null) {
      products = products.where((p) => p.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      products = products.where((p) => p.price <= maxPrice).toList();
    }

    return products;
  }

  /// Get products by IDs (for favorites)
  Future<List<Product>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    final products = <Product>[];
    for (final id in productIds) {
      final product = await getProduct(id);
      if (product != null) {
        products.add(product);
      }
    }
    return products;
  }

  // Admin operations (for seeding data)

  /// Create product
  Future<void> createProduct(Product product) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: product.id,
      data: product.toJson(),
    );
  }

  /// Update product
  Future<void> updateProduct(Product product) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: product.id,
      data: product.toJson(),
    );
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: productId,
    );
  }

  /// Seed products from mock data
  Future<void> seedProducts(List<Product> products) async {
    for (final product in products) {
      await createProduct(product);
    }
  }
}

/// Result class for paginated product queries
class PaginatedProductResult {
  final List<Product> products;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedProductResult({
    required this.products,
    this.lastDocument,
    required this.hasMore,
  });
}
