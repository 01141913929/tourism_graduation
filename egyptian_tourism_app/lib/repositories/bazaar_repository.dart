import '../models/bazaar_model.dart';
import '../services/firestore_service.dart';

/// Repository for bazaar data operations
class BazaarRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'bazaars';

  BazaarRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Get all bazaars
  Future<List<Bazaar>> getBazaars() async {
    final data = await _firestoreService.getCollection(collection: _collection);
    return data.map((e) => Bazaar.fromJson(e)).toList();
  }

  /// Stream all bazaars
  Stream<List<Bazaar>> streamBazaars() {
    return _firestoreService
        .streamCollection(collection: _collection)
        .map((data) => data.map((e) => Bazaar.fromJson(e)).toList());
  }

  /// Get bazaar by ID
  Future<Bazaar?> getBazaar(String bazaarId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: bazaarId,
    );
    if (data == null) return null;
    return Bazaar.fromJson({...data, 'id': bazaarId});
  }

  /// Stream single bazaar
  Stream<Bazaar?> streamBazaar(String bazaarId) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: bazaarId)
        .map((data) {
      if (data == null) return null;
      return Bazaar.fromJson({...data, 'id': bazaarId});
    });
  }

  /// Get bazaars by owner
  Future<List<Bazaar>> getBazaarsByOwner(String ownerUserId) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('ownerUserId', isEqualTo: ownerUserId),
    );
    return data.map((e) => Bazaar.fromJson(e)).toList();
  }

  /// Stream bazaars by owner
  Stream<List<Bazaar>> streamBazaarsByOwner(String ownerUserId) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) =>
              ref.where('ownerUserId', isEqualTo: ownerUserId),
        )
        .map((data) => data.map((e) => Bazaar.fromJson(e)).toList());
  }

  /// Get open bazaars only
  Future<List<Bazaar>> getOpenBazaars() async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('isOpen', isEqualTo: true),
    );
    return data.map((e) => Bazaar.fromJson(e)).toList();
  }

  /// Get verified bazaars only
  Future<List<Bazaar>> getVerifiedBazaars() async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('isVerified', isEqualTo: true),
    );
    return data.map((e) => Bazaar.fromJson(e)).toList();
  }

  /// Search bazaars by name
  Future<List<Bazaar>> searchBazaars(String query) async {
    final data = await _firestoreService.getCollection(collection: _collection);
    final bazaars = data.map((e) => Bazaar.fromJson(e)).toList();

    final lowerQuery = query.toLowerCase();
    return bazaars.where((b) {
      return b.nameAr.toLowerCase().contains(lowerQuery) ||
          b.nameEn.toLowerCase().contains(lowerQuery) ||
          b.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get nearby bazaars (simple distance filter)
  Future<List<Bazaar>> getNearbyBazaars({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final bazaars = await getBazaars();

    return bazaars.where((bazaar) {
      final distance = _calculateDistance(
        latitude,
        longitude,
        bazaar.latitude,
        bazaar.longitude,
      );
      return distance <= radiusKm;
    }).toList()
      ..sort((a, b) {
        final distA =
            _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB =
            _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
  }

  /// Simple distance calculation (Haversine formula approximation)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double kmPerDegree = 111.0;
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return (dLat + dLon) * kmPerDegree / 2;
  }

  // Admin operations

  /// Create bazaar
  Future<void> createBazaar(Bazaar bazaar) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: bazaar.id,
      data: bazaar.toJson(),
    );
  }

  /// Update bazaar
  Future<void> updateBazaar(Bazaar bazaar) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: bazaar.id,
      data: bazaar.toJson(),
    );
  }

  /// Delete bazaar
  Future<void> deleteBazaar(String bazaarId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: bazaarId,
    );
  }

  /// Update bazaar open status
  Future<void> updateOpenStatus(String bazaarId, bool isOpen) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: bazaarId,
      data: {'isOpen': isOpen},
    );
  }

  /// Add product to bazaar
  Future<void> addProductToBazaar(String bazaarId, String productId) async {
    final bazaar = await getBazaar(bazaarId);
    if (bazaar != null) {
      final updatedProductIds = [...bazaar.productIds, productId];
      await _firestoreService.updateDocument(
        collection: _collection,
        docId: bazaarId,
        data: {'productIds': updatedProductIds},
      );
    }
  }

  /// Remove product from bazaar
  Future<void> removeProductFromBazaar(
      String bazaarId, String productId) async {
    final bazaar = await getBazaar(bazaarId);
    if (bazaar != null) {
      final updatedProductIds =
          bazaar.productIds.where((id) => id != productId).toList();
      await _firestoreService.updateDocument(
        collection: _collection,
        docId: bazaarId,
        data: {'productIds': updatedProductIds},
      );
    }
  }

  /// Generate unique bazaar ID
  String generateBazaarId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'BAZ-$timestamp';
  }
}
