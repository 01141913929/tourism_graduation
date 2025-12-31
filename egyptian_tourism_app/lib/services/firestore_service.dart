import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic Firestore service for CRUD operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Set a document (create or update)
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    await _firestore
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  /// Get a single document
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    final doc = await _firestore.collection(collection).doc(docId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Stream a single document
  Stream<Map<String, dynamic>?> streamDocument({
    required String collection,
    required String docId,
  }) {
    return _firestore.collection(collection).doc(docId).snapshots().map(
          (doc) => doc.exists ? doc.data() : null,
        );
  }

  /// Get all documents in a collection
  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    Query<Map<String, dynamic>> Function(
            CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Stream a collection
  Stream<List<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query<Map<String, dynamic>> Function(
            CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  /// Add a document with auto-generated ID
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final docRef = await _firestore.collection(collection).add(data);
    return docRef.id;
  }

  /// Batch write operations
  Future<void> batchWrite(
    void Function(WriteBatch batch) operations,
  ) async {
    final batch = _firestore.batch();
    operations(batch);
    await batch.commit();
  }

  /// Run a transaction
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    return _firestore.runTransaction(transactionHandler);
  }

  // Subcollection helpers

  /// Set a document in a subcollection
  Future<void> setSubDocument({
    required String parentCollection,
    required String parentDocId,
    required String subCollection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    await _firestore
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subCollection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
  }

  /// Get documents from a subcollection
  Future<List<Map<String, dynamic>>> getSubCollection({
    required String parentCollection,
    required String parentDocId,
    required String subCollection,
  }) async {
    final snapshot = await _firestore
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subCollection)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  /// Stream a subcollection
  Stream<List<Map<String, dynamic>>> streamSubCollection({
    required String parentCollection,
    required String parentDocId,
    required String subCollection,
  }) {
    return _firestore
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  /// Delete a document from a subcollection
  Future<void> deleteSubDocument({
    required String parentCollection,
    required String parentDocId,
    required String subCollection,
    required String docId,
  }) async {
    await _firestore
        .collection(parentCollection)
        .doc(parentDocId)
        .collection(subCollection)
        .doc(docId)
        .delete();
  }

  /// Get paginated documents from a collection
  /// Returns a tuple of (documents, lastDocument) for cursor-based pagination
  Future<PaginatedResult> getPaginatedCollection({
    required String collection,
    required int limit,
    DocumentSnapshot? startAfter,
    Query<Map<String, dynamic>> Function(
            CollectionReference<Map<String, dynamic>>)?
        queryBuilder,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collection);
    if (queryBuilder != null) {
      query = queryBuilder(_firestore.collection(collection));
    }

    query = query.limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final documents =
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    final hasMore = snapshot.docs.length == limit;

    return PaginatedResult(
      documents: documents,
      lastDocument: lastDoc,
      hasMore: hasMore,
    );
  }
}

/// Result class for paginated queries
class PaginatedResult {
  final List<Map<String, dynamic>> documents;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedResult({
    required this.documents,
    this.lastDocument,
    required this.hasMore,
  });
}
