import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_model.dart';

/// Service for logging and retrieving audit trail
class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'auditLogs';

  /// Log an action
  Future<void> log({
    required AuditActionType actionType,
    required String description,
    required String performedBy,
    required String performedByName,
    String? targetId,
    String? targetType,
    String? targetName,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    final docRef = _firestore.collection(_collection).doc();

    final log = AuditLog(
      id: docRef.id,
      actionType: actionType,
      actionDescription: description,
      performedBy: performedBy,
      performedByName: performedByName,
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
      previousData: previousData,
      newData: newData,
      createdAt: DateTime.now(),
    );

    await docRef.set(log.toJson());
  }

  /// Log user action helper
  Future<void> logUserAction({
    required AuditActionType actionType,
    required String userId,
    required String userName,
    required String adminId,
    required String adminName,
    String? description,
  }) async {
    await log(
      actionType: actionType,
      description: description ?? '${actionType.name} for user: $userName',
      performedBy: adminId,
      performedByName: adminName,
      targetId: userId,
      targetType: 'user',
      targetName: userName,
    );
  }

  /// Log bazaar action helper
  Future<void> logBazaarAction({
    required AuditActionType actionType,
    required String bazaarId,
    required String bazaarName,
    required String adminId,
    required String adminName,
    String? description,
    Map<String, dynamic>? previousData,
    Map<String, dynamic>? newData,
  }) async {
    await log(
      actionType: actionType,
      description: description ?? '${actionType.name} for bazaar: $bazaarName',
      performedBy: adminId,
      performedByName: adminName,
      targetId: bazaarId,
      targetType: 'bazaar',
      targetName: bazaarName,
      previousData: previousData,
      newData: newData,
    );
  }

  /// Log application action helper
  Future<void> logApplicationAction({
    required AuditActionType actionType,
    required String applicationId,
    required String bazaarName,
    required String adminId,
    required String adminName,
    String? reason,
  }) async {
    await log(
      actionType: actionType,
      description: actionType == AuditActionType.applicationApproved
          ? 'تمت الموافقة على طلب بازار: $bazaarName'
          : 'تم رفض طلب بازار: $bazaarName${reason != null ? ' - السبب: $reason' : ''}',
      performedBy: adminId,
      performedByName: adminName,
      targetId: applicationId,
      targetType: 'application',
      targetName: bazaarName,
    );
  }

  /// Log admin login
  Future<void> logLogin(String adminId, String adminName) async {
    await log(
      actionType: AuditActionType.adminLogin,
      description: 'تسجيل دخول المسؤول: $adminName',
      performedBy: adminId,
      performedByName: adminName,
    );
  }

  /// Log admin logout
  Future<void> logLogout(String adminId, String adminName) async {
    await log(
      actionType: AuditActionType.adminLogout,
      description: 'تسجيل خروج المسؤول: $adminName',
      performedBy: adminId,
      performedByName: adminName,
    );
  }

  /// Get all audit logs with pagination
  Future<List<AuditLog>> getAuditLogs({
    int limit = 50,
    DocumentSnapshot? lastDocument,
    AuditActionType? filterByType,
    String? filterByAdmin,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);

    if (filterByType != null) {
      query = query.where('actionType', isEqualTo: filterByType.name);
    }

    if (filterByAdmin != null) {
      query = query.where('performedBy', isEqualTo: filterByAdmin);
    }

    if (startDate != null) {
      query = query.where('createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String());
    }

    if (endDate != null) {
      query = query.where('createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String());
    }

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => AuditLog.fromJson(
            {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
        .toList();
  }

  /// Stream recent audit logs
  Stream<List<AuditLog>> streamRecentAuditLogs({int limit = 20}) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditLog.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
