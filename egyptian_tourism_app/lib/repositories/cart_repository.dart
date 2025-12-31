import '../models/models.dart';
import '../services/firestore_service.dart';

/// Repository for cart data operations
class CartRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'carts';

  CartRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Get cart items for user
  Future<List<CartItemModel>> getCartItems(String userId) async {
    final data = await _firestoreService.getSubCollection(
      parentCollection: _collection,
      parentDocId: userId,
      subCollection: 'items',
    );
    return data.map((e) => CartItemModel.fromJson(e)).toList();
  }

  /// Stream cart items
  Stream<List<CartItemModel>> streamCartItems(String userId) {
    return _firestoreService
        .streamSubCollection(
          parentCollection: _collection,
          parentDocId: userId,
          subCollection: 'items',
        )
        .map((data) => data.map((e) => CartItemModel.fromJson(e)).toList());
  }

  /// Add item to cart
  Future<void> addToCart(String userId, CartItemModel item) async {
    // Check if item already exists
    final existingItems = await getCartItems(userId);
    final existingItem =
        existingItems.where((i) => i.id == item.id).firstOrNull;

    if (existingItem != null) {
      // Update quantity
      await updateQuantity(
        userId,
        item.id,
        existingItem.quantity + item.quantity,
      );
    } else {
      // Add new item
      await _firestoreService.setSubDocument(
        parentCollection: _collection,
        parentDocId: userId,
        subCollection: 'items',
        docId: item.id,
        data: item.toJson(),
      );
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(
    String userId,
    String itemId,
    int quantity,
  ) async {
    if (quantity <= 0) {
      await removeFromCart(userId, itemId);
    } else {
      await _firestoreService.setSubDocument(
        parentCollection: _collection,
        parentDocId: userId,
        subCollection: 'items',
        docId: itemId,
        data: {'quantity': quantity},
        merge: true,
      );
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String userId, String itemId) async {
    await _firestoreService.deleteSubDocument(
      parentCollection: _collection,
      parentDocId: userId,
      subCollection: 'items',
      docId: itemId,
    );
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    final items = await getCartItems(userId);
    for (final item in items) {
      await removeFromCart(userId, item.id);
    }
  }

  /// Get cart item count
  Future<int> getCartItemCount(String userId) async {
    final items = await getCartItems(userId);
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Stream cart item count
  Stream<int> streamCartItemCount(String userId) {
    return streamCartItems(userId).map(
      (items) => items.fold(0, (sum, item) => sum + item.quantity),
    );
  }
}
