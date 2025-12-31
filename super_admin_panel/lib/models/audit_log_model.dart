import 'package:cloud_firestore/cloud_firestore.dart';

/// Action type for audit logging
enum AuditActionType {
  // User actions
  userCreated,
  userUpdated,
  userDeleted,
  userRoleChanged,

  // Bazaar actions
  bazaarCreated,
  bazaarUpdated,
  bazaarVerified,
  bazaarUnverified,
  bazaarDeleted,

  // Application actions
  applicationApproved,
  applicationRejected,

  // Order actions
  orderCreated,
  orderStatusChanged,
  orderCancelled,

  // Product actions
  productCreated,
  productUpdated,
  productDeleted,

  // Coupon actions
  couponCreated,
  couponUpdated,
  couponDeleted,

  // Login actions
  adminLogin,
  adminLogout,

  // Other
  other,
}

/// Audit log entry model
class AuditLog {
  final String id;
  final AuditActionType actionType;
  final String actionDescription;
  final String performedBy; // admin user ID
  final String performedByName;
  final String? targetId; // affected resource ID
  final String? targetType; // 'user', 'bazaar', 'order', etc.
  final String? targetName;
  final Map<String, dynamic>? previousData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;
  final String? ipAddress;

  const AuditLog({
    required this.id,
    required this.actionType,
    required this.actionDescription,
    required this.performedBy,
    required this.performedByName,
    this.targetId,
    this.targetType,
    this.targetName,
    this.previousData,
    this.newData,
    required this.createdAt,
    this.ipAddress,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String? ?? '',
      actionType: AuditActionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => AuditActionType.other,
      ),
      actionDescription: json['actionDescription'] as String? ?? '',
      performedBy: json['performedBy'] as String? ?? '',
      performedByName: json['performedByName'] as String? ?? 'مسؤول',
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      targetName: json['targetName'] as String?,
      previousData: json['previousData'] as Map<String, dynamic>?,
      newData: json['newData'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      ipAddress: json['ipAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actionType': actionType.name,
      'actionDescription': actionDescription,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'targetId': targetId,
      'targetType': targetType,
      'targetName': targetName,
      'previousData': previousData,
      'newData': newData,
      'createdAt': createdAt.toIso8601String(),
      'ipAddress': ipAddress,
    };
  }

  String get actionTypeArabic {
    switch (actionType) {
      case AuditActionType.userCreated:
        return 'إنشاء مستخدم';
      case AuditActionType.userUpdated:
        return 'تحديث مستخدم';
      case AuditActionType.userDeleted:
        return 'حذف مستخدم';
      case AuditActionType.userRoleChanged:
        return 'تغيير صلاحيات مستخدم';
      case AuditActionType.bazaarCreated:
        return 'إنشاء بازار';
      case AuditActionType.bazaarUpdated:
        return 'تحديث بازار';
      case AuditActionType.bazaarVerified:
        return 'تفعيل بازار';
      case AuditActionType.bazaarUnverified:
        return 'إلغاء تفعيل بازار';
      case AuditActionType.bazaarDeleted:
        return 'حذف بازار';
      case AuditActionType.applicationApproved:
        return 'قبول طلب بازار';
      case AuditActionType.applicationRejected:
        return 'رفض طلب بازار';
      case AuditActionType.orderCreated:
        return 'إنشاء طلب';
      case AuditActionType.orderStatusChanged:
        return 'تغيير حالة طلب';
      case AuditActionType.orderCancelled:
        return 'إلغاء طلب';
      case AuditActionType.productCreated:
        return 'إضافة منتج';
      case AuditActionType.productUpdated:
        return 'تحديث منتج';
      case AuditActionType.productDeleted:
        return 'حذف منتج';
      case AuditActionType.couponCreated:
        return 'إنشاء كوبون';
      case AuditActionType.couponUpdated:
        return 'تحديث كوبون';
      case AuditActionType.couponDeleted:
        return 'حذف كوبون';
      case AuditActionType.adminLogin:
        return 'تسجيل دخول';
      case AuditActionType.adminLogout:
        return 'تسجيل خروج';
      case AuditActionType.other:
        return 'إجراء آخر';
    }
  }
}
