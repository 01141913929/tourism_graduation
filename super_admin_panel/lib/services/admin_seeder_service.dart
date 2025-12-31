import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// خدمة بذر البيانات للوحة الإدارة
class AdminSeederService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// بيانات حساب Super Admin التجريبي
  static const String adminEmail = 'admin@bazar.com';
  static const String adminPassword = 'Admin123!';
  static const String adminName = 'مدير النظام';

  /// التحقق من وجود حساب Super Admin
  Future<bool> superAdminExists() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'superAdmin')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking super admin: $e');
      return false;
    }
  }

  /// إنشاء حساب Super Admin تجريبي
  /// يُستخدم مرة واحدة فقط لإعداد النظام
  Future<bool> seedSuperAdmin() async {
    try {
      // التحقق من عدم وجود حساب admin مسبقاً
      if (await superAdminExists()) {
        debugPrint('Super Admin already exists');
        return true;
      }

      // إنشاء حساب Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (credential.user == null) {
        throw Exception('Failed to create admin account');
      }

      final uid = credential.user!.uid;

      // إنشاء وثيقة المستخدم مع دور superAdmin
      final userData = UserModel(
        uid: uid,
        email: adminEmail,
        name: adminName,
        phone: '+201000000000',
        createdAt: DateTime.now(),
        role: UserRole.superAdmin,
        applicationStatus: BazaarApplicationStatus.approved,
      );

      await _firestore.collection('users').doc(uid).set(userData.toJson());

      debugPrint('✅ Super Admin created successfully!');
      debugPrint('📧 Email: $adminEmail');
      debugPrint('🔑 Password: $adminPassword');

      // تسجيل الخروج حتى يتمكن المستخدم من تسجيل الدخول
      await _auth.signOut();

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // الحساب موجود في Auth، نتحقق من users collection
        debugPrint('Admin email exists in Auth, checking Firestore...');
        return await _ensureAdminUserDocument();
      }
      debugPrint('Error seeding super admin: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error seeding super admin: $e');
      return false;
    }
  }

  /// التأكد من وجود وثيقة المستخدم للـ admin
  Future<bool> _ensureAdminUserDocument() async {
    try {
      // تسجيل الدخول بحساب الأدمن
      final credential = await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      if (credential.user == null) return false;

      final uid = credential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        // إنشاء وثيقة المستخدم
        final userData = UserModel(
          uid: uid,
          email: adminEmail,
          name: adminName,
          createdAt: DateTime.now(),
          role: UserRole.superAdmin,
          applicationStatus: BazaarApplicationStatus.approved,
        );
        await _firestore.collection('users').doc(uid).set(userData.toJson());
      }

      await _auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Error ensuring admin document: $e');
      return false;
    }
  }

  /// بذر بيانات تجريبية للنظام (اختياري)
  Future<void> seedSampleData() async {
    try {
      // إنشاء بعض الفئات
      final categories = [
        'تماثيل',
        'مجوهرات',
        'ملابس تقليدية',
        'تحف',
        'هدايا تذكارية'
      ];

      for (final category in categories) {
        await _firestore.collection('categories').add({
          'nameAr': category,
          'nameEn': category,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('✅ Sample data seeded successfully!');
    } catch (e) {
      debugPrint('Error seeding sample data: $e');
    }
  }
}
