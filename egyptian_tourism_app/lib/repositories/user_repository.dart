import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Repository for user data operations
class UserRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'users';

  UserRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: uid,
    );
    if (data == null) return null;
    return UserModel.fromJson({...data, 'uid': uid});
  }

  /// Stream user data
  Stream<UserModel?> streamUser(String uid) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: uid)
        .map((data) {
      if (data == null) return null;
      return UserModel.fromJson({...data, 'uid': uid});
    });
  }

  /// Create user
  Future<void> createUser(UserModel user) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: user.uid,
      data: user.toJson(),
    );
  }

  /// Update user
  Future<void> updateUser(UserModel user) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: user.uid,
      data: user.toJson(),
    );
  }

  /// Update specific fields
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: uid,
      data: fields,
    );
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: uid,
    );
  }

  // Favorites

  /// Add product to favorites
  Future<void> addToFavorites(String uid, String productId) async {
    final user = await getUser(uid);
    if (user != null) {
      final favorites = List<String>.from(user.favoriteProductIds);
      if (!favorites.contains(productId)) {
        favorites.add(productId);
        await updateUserFields(uid, {'favoriteProductIds': favorites});
      }
    }
  }

  /// Remove product from favorites
  Future<void> removeFromFavorites(String uid, String productId) async {
    final user = await getUser(uid);
    if (user != null) {
      final favorites = List<String>.from(user.favoriteProductIds);
      favorites.remove(productId);
      await updateUserFields(uid, {'favoriteProductIds': favorites});
    }
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(String uid, String productId) async {
    final user = await getUser(uid);
    if (user != null) {
      final favorites = List<String>.from(user.favoriteProductIds);
      bool isFavorite;
      if (favorites.contains(productId)) {
        favorites.remove(productId);
        isFavorite = false;
      } else {
        favorites.add(productId);
        isFavorite = true;
      }
      await updateUserFields(uid, {'favoriteProductIds': favorites});
      return isFavorite;
    }
    return false;
  }

  /// Check if product is favorite
  Future<bool> isFavorite(String uid, String productId) async {
    final user = await getUser(uid);
    return user?.favoriteProductIds.contains(productId) ?? false;
  }

  /// Toggle artifact favorite
  Future<bool> toggleArtifactFavorite(String uid, String artifactId) async {
    final user = await getUser(uid);
    if (user != null) {
      final favorites = List<String>.from(user.favoriteArtifactIds);
      bool isFavorite;
      if (favorites.contains(artifactId)) {
        favorites.remove(artifactId);
        isFavorite = false;
      } else {
        favorites.add(artifactId);
        isFavorite = true;
      }
      await updateUserFields(uid, {'favoriteArtifactIds': favorites});
      return isFavorite;
    }
    return false;
  }

  // Addresses

  /// Add address
  Future<void> addAddress(String uid, Address address) async {
    await _firestoreService.setSubDocument(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'addresses',
      docId: address.id,
      data: address.toJson(),
    );
  }

  /// Get all addresses
  Future<List<Address>> getAddresses(String uid) async {
    final data = await _firestoreService.getSubCollection(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'addresses',
    );
    return data.map((e) => Address.fromJson(e)).toList();
  }

  /// Stream addresses
  Stream<List<Address>> streamAddresses(String uid) {
    return _firestoreService
        .streamSubCollection(
          parentCollection: _collection,
          parentDocId: uid,
          subCollection: 'addresses',
        )
        .map((data) => data.map((e) => Address.fromJson(e)).toList());
  }

  /// Update address
  Future<void> updateAddress(String uid, Address address) async {
    await _firestoreService.setSubDocument(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'addresses',
      docId: address.id,
      data: address.toJson(),
      merge: true,
    );
  }

  /// Delete address
  Future<void> deleteAddress(String uid, String addressId) async {
    await _firestoreService.deleteSubDocument(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'addresses',
      docId: addressId,
    );
  }

  /// Set default address
  Future<void> setDefaultAddress(String uid, String addressId) async {
    final addresses = await getAddresses(uid);
    for (final address in addresses) {
      await updateAddress(
        uid,
        address.copyWith(isDefault: address.id == addressId),
      );
    }
  }

  // Payment Methods

  /// Add payment method
  Future<void> addPaymentMethod(String uid, PaymentMethod paymentMethod) async {
    await _firestoreService.setSubDocument(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'payment_methods',
      docId: paymentMethod.id,
      data: paymentMethod.toJson(),
    );
  }

  /// Get all payment methods
  Future<List<PaymentMethod>> getPaymentMethods(String uid) async {
    final data = await _firestoreService.getSubCollection(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'payment_methods',
    );
    return data.map((e) => PaymentMethod.fromJson(e)).toList();
  }

  /// Stream payment methods
  Stream<List<PaymentMethod>> streamPaymentMethods(String uid) {
    return _firestoreService
        .streamSubCollection(
          parentCollection: _collection,
          parentDocId: uid,
          subCollection: 'payment_methods',
        )
        .map((data) => data.map((e) => PaymentMethod.fromJson(e)).toList());
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String uid, String paymentMethodId) async {
    await _firestoreService.deleteSubDocument(
      parentCollection: _collection,
      parentDocId: uid,
      subCollection: 'payment_methods',
      docId: paymentMethodId,
    );
  }

  /// Set default payment method
  Future<void> setDefaultPaymentMethod(
      String uid, String paymentMethodId) async {
    final methods = await getPaymentMethods(uid);
    for (final method in methods) {
      await _firestoreService.setSubDocument(
        parentCollection: _collection,
        parentDocId: uid,
        subCollection: 'payment_methods',
        docId: method.id,
        data: method.copyWith(isDefault: method.id == paymentMethodId).toJson(),
        merge: true,
      );
    }
  }
}
