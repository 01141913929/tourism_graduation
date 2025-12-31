import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/notification_service.dart';

/// Provider للمصادقة في تطبيق صاحب البازار
class BazaarAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Completer للانتظار حتى يتم التحقق من حالة Auth
  final Completer<void> _authStateCompleter = Completer<void>();
  bool _isAuthStateChecked = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get userId => _firebaseUser?.uid;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null && _user != null;
  bool get isApprovedBazaarOwner => _user?.isApprovedBazaarOwner ?? false;
  bool get isPendingApproval =>
      _user?.applicationStatus == BazaarApplicationStatus.pending;
  bool get isRejected =>
      _user?.applicationStatus == BazaarApplicationStatus.rejected;

  BazaarAuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// انتظار حتى يتم التحقق من حالة Auth
  Future<void> waitForAuthReady() async {
    if (_isAuthStateChecked) return;
    return _authStateCompleter.future;
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      await _loadUserData();
    } else {
      _user = null;
    }

    // إكمال الـ Completer في أول مرة
    if (!_isAuthStateChecked) {
      _isAuthStateChecked = true;
      if (!_authStateCompleter.isCompleted) {
        _authStateCompleter.complete();
      }
    }

    notifyListeners();
  }

  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(_firebaseUser!.uid).get();

      if (doc.exists) {
        _user = UserModel.fromJson({...doc.data()!, 'uid': doc.id});

        // Initialize Notifications
        await NotificationService().initialize(_user!.uid);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// تسجيل الدخول
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _loadUserData();

      // التحقق من أن المستخدم صاحب بازار
      if (_user?.role != UserRole.bazaarOwner) {
        await _auth.signOut();
        _error = 'هذا الحساب ليس حساب صاحب بازار';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تسجيل صاحب بازار جديد
  Future<bool> registerBazaarOwner({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String bazaarName,
    required String bazaarDescription,
    required String bazaarAddress,
    required String governorate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // إنشاء حساب Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('فشل إنشاء الحساب');
      }

      final uid = credential.user!.uid;
      final now = DateTime.now();

      // إنشاء بيانات المستخدم
      final userData = UserModel(
        uid: uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: now,
        role: UserRole.bazaarOwner,
        applicationStatus: BazaarApplicationStatus.pending,
      );

      // حفظ بيانات المستخدم
      await _firestore.collection('users').doc(uid).set(userData.toJson());

      // إنشاء طلب البازار
      final bazaarApplicationDoc =
          _firestore.collection('bazaarApplications').doc();
      await bazaarApplicationDoc.set({
        'id': bazaarApplicationDoc.id,
        'userId': uid,
        'ownerName': name,
        'ownerEmail': email,
        'ownerPhone': phone,
        'bazaarName': bazaarName,
        'description': bazaarDescription,
        'address': bazaarAddress,
        'governorate': governorate,
        'status': 'pending',
        'createdAt': now.toIso8601String(),
      });

      await _loadUserData();

      // Notify Super Admin
      try {
        final adminsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'superAdmin')
            .get();

        for (final doc in adminsSnapshot.docs) {
          NotificationService().sendNotification(
            targetUserId: doc.id,
            title: 'طلب انضمام بازار جديد',
            body: 'قام $name بتقديم طلب لفتح بازار "$bazaarName".',
            data: {
              'type': 'new_bazaar_application',
              'applicationId': bazaarApplicationDoc.id
            },
          );
        }
      } catch (e) {
        debugPrint('Error sending admin notification: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'حدث خطأ غير متوقع: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  /// تحديث بيانات المستخدم
  Future<void> refreshUserData() async {
    await _loadUserData();
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'حدث خطأ: $code';
    }
  }
}
