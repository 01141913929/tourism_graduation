import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Service for managing products in Firebase Firestore
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloudinary configuration - to be set by user
  static String cloudinaryCloudName = '';
  static String cloudinaryUploadPreset = '';

  /// Configure Cloudinary credentials
  static void configureCloudinary({
    required String cloudName,
    required String uploadPreset,
  }) {
    cloudinaryCloudName = cloudName;
    cloudinaryUploadPreset = uploadPreset;
  }

  /// Get all products from all bazaars
  Future<List<Product>> getAllProducts() async {
    try {
      debugPrint('📦 Loading all products...');
      final snapshot = await _firestore.collection('products').get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();

      // Sort by creation date (newest first)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('📦 Loaded ${products.length} products');
      return products;
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      rethrow;
    }
  }

  /// Get products by bazaar ID
  Future<List<Product>> getProductsByBazaar(String bazaarId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('bazaarId', isEqualTo: bazaarId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading products by bazaar: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading products by category: $e');
      rethrow;
    }
  }

  /// Create a new product
  Future<String?> createProduct(Product product) async {
    try {
      debugPrint('➕ Creating product: ${product.nameAr}');

      final docRef = _firestore.collection('products').doc();
      final productData = product
          .copyWith(
            id: docRef.id,
            createdAt: DateTime.now(),
          )
          .toJson();

      await docRef.set(productData);

      // Update bazaar's productIds list
      if (product.bazaarId.isNotEmpty) {
        await _firestore.collection('bazaars').doc(product.bazaarId).update({
          'productIds': FieldValue.arrayUnion([docRef.id]),
        });
      }

      debugPrint('✅ Product created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating product: $e');
      return null;
    }
  }

  /// Update an existing product
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      debugPrint('✏️ Updating product: $productId');

      data['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('products').doc(productId).update(data);

      debugPrint('✅ Product updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      return false;
    }
  }

  /// Delete a product
  Future<bool> deleteProduct(String productId) async {
    try {
      debugPrint('🗑️ Deleting product: $productId');

      // Get product to find bazaar ID
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final bazaarId = doc.data()?['bazaarId'] as String?;

        // Remove from bazaar's productIds list
        if (bazaarId != null && bazaarId.isNotEmpty) {
          await _firestore.collection('bazaars').doc(bazaarId).update({
            'productIds': FieldValue.arrayRemove([productId]),
          });
        }
      }

      await _firestore.collection('products').doc(productId).delete();

      debugPrint('✅ Product deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      return false;
    }
  }

  /// Toggle product active status
  Future<bool> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error toggling product status: $e');
      return false;
    }
  }

  /// Bulk update products
  Future<bool> bulkUpdateProducts(
    List<String> productIds,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('📦 Bulk updating ${productIds.length} products');

      final batch = _firestore.batch();
      data['updatedAt'] = DateTime.now().toIso8601String();

      for (final productId in productIds) {
        final docRef = _firestore.collection('products').doc(productId);
        batch.update(docRef, data);
      }

      await batch.commit();

      debugPrint('✅ Bulk update completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error in bulk update: $e');
      return false;
    }
  }

  /// Bulk delete products
  Future<bool> bulkDeleteProducts(List<String> productIds) async {
    try {
      debugPrint('🗑️ Bulk deleting ${productIds.length} products');

      final batch = _firestore.batch();

      for (final productId in productIds) {
        final docRef = _firestore.collection('products').doc(productId);
        batch.delete(docRef);
      }

      await batch.commit();

      debugPrint('✅ Bulk delete completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error in bulk delete: $e');
      return false;
    }
  }

  /// Upload image to Cloudinary
  Future<String?> uploadImageToCloudinary(
      Uint8List imageBytes, String fileName) async {
    try {
      if (cloudinaryCloudName.isEmpty || cloudinaryUploadPreset.isEmpty) {
        debugPrint('⚠️ Cloudinary not configured');
        return null;
      }

      debugPrint('📤 Uploading image to Cloudinary...');

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        final imageUrl = jsonData['secure_url'] as String;

        debugPrint('✅ Image uploaded: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  // ============ Categories ============

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    try {
      final snapshot =
          await _firestore.collection('categories').orderBy('order').get();

      if (snapshot.docs.isEmpty) {
        // Initialize default categories if none exist
        await _initializeDefaultCategories();
        return getAllCategories();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Category.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      rethrow;
    }
  }

  /// Initialize default categories
  Future<void> _initializeDefaultCategories() async {
    try {
      debugPrint('📁 Initializing default categories...');

      final batch = _firestore.batch();

      for (final catData in DefaultCategories.categories) {
        final docRef = _firestore.collection('categories').doc();
        batch.set(docRef, {
          ...catData,
          'id': docRef.id,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('✅ Default categories created');
    } catch (e) {
      debugPrint('❌ Error initializing categories: $e');
    }
  }

  /// Create a new category
  Future<String?> createCategory(Category category) async {
    try {
      final docRef = _firestore.collection('categories').doc();
      final categoryData = category
          .copyWith(
            id: docRef.id,
            createdAt: DateTime.now(),
          )
          .toJson();

      await docRef.set(categoryData);
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating category: $e');
      return null;
    }
  }

  /// Update a category
  Future<bool> updateCategory(
      String categoryId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update(data);
      return true;
    } catch (e) {
      debugPrint('❌ Error updating category: $e');
      return false;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting category: $e');
      return false;
    }
  }

  /// Get product count by category
  Future<Map<String, int>> getProductCountByCategory() async {
    try {
      final products = await getAllProducts();
      final Map<String, int> counts = {};

      for (final product in products) {
        counts[product.category] = (counts[product.category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('❌ Error counting products by category: $e');
      return {};
    }
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final products = await getAllProducts();

      final total = products.length;
      final active = products.where((p) => p.isActive).length;
      final inactive = total - active;
      final featured = products.where((p) => p.isFeatured).length;
      final outOfStock = products.where((p) => !p.isInStock).length;

      return {
        'total': total,
        'active': active,
        'inactive': inactive,
        'featured': featured,
        'outOfStock': outOfStock,
      };
    } catch (e) {
      debugPrint('❌ Error getting product statistics: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
        'featured': 0,
        'outOfStock': 0,
      };
    }
  }
}
