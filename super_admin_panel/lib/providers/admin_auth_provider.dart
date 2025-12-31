import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

/// Provider للمصادقة في لوحة Super Admin
class AdminAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get userId => _firebaseUser?.uid;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null && _user != null;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;

  AdminAuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      await _loadUserData();
    } else {
      _user = null;
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

      // التحقق من أن المستخدم مدير النظام
      if (!isSuperAdmin) {
        await _auth.signOut();
        _error = 'هذا الحساب ليس حساب مدير النظام';
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

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
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
