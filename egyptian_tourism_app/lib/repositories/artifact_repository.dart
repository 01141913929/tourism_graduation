import '../models/models.dart';
import '../services/firestore_service.dart';

/// Repository for artifact data operations
class ArtifactRepository {
  final FirestoreService _firestoreService;
  static const String _collection = 'artifacts';

  ArtifactRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  /// Get all artifacts
  Future<List<Artifact>> getArtifacts() async {
    final data = await _firestoreService.getCollection(collection: _collection);
    return data.map((e) => Artifact.fromJson(e)).toList();
  }

  /// Stream all artifacts
  Stream<List<Artifact>> streamArtifacts() {
    return _firestoreService
        .streamCollection(collection: _collection)
        .map((data) => data.map((e) => Artifact.fromJson(e)).toList());
  }

  /// Get artifact by ID
  Future<Artifact?> getArtifact(String artifactId) async {
    final data = await _firestoreService.getDocument(
      collection: _collection,
      docId: artifactId,
    );
    if (data == null) return null;
    return Artifact.fromJson({...data, 'id': artifactId});
  }

  /// Stream single artifact
  Stream<Artifact?> streamArtifact(String artifactId) {
    return _firestoreService
        .streamDocument(collection: _collection, docId: artifactId)
        .map((data) {
      if (data == null) return null;
      return Artifact.fromJson({...data, 'id': artifactId});
    });
  }

  /// Get artifacts by era
  Future<List<Artifact>> getArtifactsByEra(String era) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('era', isEqualTo: era),
    );
    return data.map((e) => Artifact.fromJson(e)).toList();
  }

  /// Stream artifacts by era
  Stream<List<Artifact>> streamArtifactsByEra(String era) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('era', isEqualTo: era),
        )
        .map((data) => data.map((e) => Artifact.fromJson(e)).toList());
  }

  /// Get featured artifacts
  Future<List<Artifact>> getFeaturedArtifacts() async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('isFeatured', isEqualTo: true),
    );
    return data.map((e) => Artifact.fromJson(e)).toList();
  }

  /// Stream featured artifacts
  Stream<List<Artifact>> streamFeaturedArtifacts() {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('isFeatured', isEqualTo: true),
        )
        .map((data) => data.map((e) => Artifact.fromJson(e)).toList());
  }

  /// Get artifacts by location
  Future<List<Artifact>> getArtifactsByLocation(String location) async {
    final data = await _firestoreService.getCollection(
      collection: _collection,
      queryBuilder: (ref) => ref.where('location', isEqualTo: location),
    );
    return data.map((e) => Artifact.fromJson(e)).toList();
  }

  /// Stream artifacts by location
  Stream<List<Artifact>> streamArtifactsByLocation(String location) {
    return _firestoreService
        .streamCollection(
          collection: _collection,
          queryBuilder: (ref) => ref.where('location', isEqualTo: location),
        )
        .map((data) => data.map((e) => Artifact.fromJson(e)).toList());
  }

  /// Search artifacts
  Future<List<Artifact>> searchArtifacts(String query) async {
    final data = await _firestoreService.getCollection(collection: _collection);
    final artifacts = data.map((e) => Artifact.fromJson(e)).toList();

    final lowerQuery = query.toLowerCase();
    return artifacts.where((a) {
      return a.nameAr.toLowerCase().contains(lowerQuery) ||
          a.descriptionAr.toLowerCase().contains(lowerQuery) ||
          a.era.toLowerCase().contains(lowerQuery) ||
          a.location.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get artifacts by IDs
  Future<List<Artifact>> getArtifactsByIds(List<String> artifactIds) async {
    if (artifactIds.isEmpty) return [];

    final artifacts = <Artifact>[];
    for (final id in artifactIds) {
      final artifact = await getArtifact(id);
      if (artifact != null) {
        artifacts.add(artifact);
      }
    }
    return artifacts;
  }

  // Admin operations

  /// Create artifact
  Future<void> createArtifact(Artifact artifact) async {
    await _firestoreService.setDocument(
      collection: _collection,
      docId: artifact.id,
      data: artifact.toJson(),
    );
  }

  /// Update artifact
  Future<void> updateArtifact(Artifact artifact) async {
    await _firestoreService.updateDocument(
      collection: _collection,
      docId: artifact.id,
      data: artifact.toJson(),
    );
  }

  /// Delete artifact
  Future<void> deleteArtifact(String artifactId) async {
    await _firestoreService.deleteDocument(
      collection: _collection,
      docId: artifactId,
    );
  }

  /// Seed artifacts from mock data
  Future<void> seedArtifacts(List<Artifact> artifacts) async {
    for (final artifact in artifacts) {
      await createArtifact(artifact);
    }
  }
}
