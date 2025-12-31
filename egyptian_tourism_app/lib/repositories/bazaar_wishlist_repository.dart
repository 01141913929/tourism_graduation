import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository for managing bazaar wishlists/favorites
class BazaarWishlistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'users';

  /// Get user's favorite bazaar IDs
  Future<List<String>> getUserFavoriteBazaars(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data();
      final bazaarIds = data?['favoriteBazaarIds'] as List<dynamic>?;
      return bazaarIds?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      throw Exception('Failed to get favorite bazaars: $e');
    }
  }

  /// Stream user's favorite bazaar IDs
  Stream<List<String>> streamUserFavoriteBazaars(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      final bazaarIds = data?['favoriteBazaarIds'] as List<dynamic>?;
      return bazaarIds?.map((e) => e.toString()).toList() ?? [];
    });
  }

  /// Check if a bazaar is in user's favorites
  Future<bool> isBazaarFavorite(String userId, String bazaarId) async {
    try {
      final favorites = await getUserFavoriteBazaars(userId);
      return favorites.contains(bazaarId);
    } catch (e) {
      return false;
    }
  }

  /// Add bazaar to favorites
  Future<void> addBazaarToFavorites(String userId, String bazaarId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteBazaarIds': FieldValue.arrayUnion([bazaarId]),
      });
    } catch (e) {
      throw Exception('Failed to add bazaar to favorites: $e');
    }
  }

  /// Remove bazaar from favorites
  Future<void> removeBazaarFromFavorites(String userId, String bazaarId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteBazaarIds': FieldValue.arrayRemove([bazaarId]),
      });
    } catch (e) {
      throw Exception('Failed to remove bazaar from favorites: $e');
    }
  }

  /// Toggle bazaar favorite status
  Future<bool> toggleBazaarFavorite(String userId, String bazaarId) async {
    final isFavorite = await isBazaarFavorite(userId, bazaarId);
    if (isFavorite) {
      await removeBazaarFromFavorites(userId, bazaarId);
      return false;
    } else {
      await addBazaarToFavorites(userId, bazaarId);
      return true;
    }
  }

  /// Clear all favorite bazaars
  Future<void> clearFavoriteBazaars(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteBazaarIds': [],
      });
    } catch (e) {
      throw Exception('Failed to clear favorite bazaars: $e');
    }
  }

  /// Get count of favorite bazaars
  Future<int> getFavoriteBazaarsCount(String userId) async {
    final favorites = await getUserFavoriteBazaars(userId);
    return favorites.length;
  }
}
