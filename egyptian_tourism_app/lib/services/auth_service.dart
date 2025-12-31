import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for handling Firebase Authentication
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FacebookAuth _facebookAuth = FacebookAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login
      if (credential.user != null) {
        await _updateLastLogin(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user document in Firestore
      if (credential.user != null) {
        await _createUserDocument(
          uid: credential.user!.uid,
          email: email.trim(),
          name: name,
          phone: phone,
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create or update user document
      if (userCredential.user != null) {
        await _createOrUpdateSocialUser(userCredential.user!, 'Google');
      }

      return userCredential;
    } catch (e) {
      throw Exception('فشل تسجيل الدخول بـ Google: $e');
    }
  }

  /// Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Trigger the sign-in flow
      final LoginResult result = await _facebookAuth.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;

        // Create a credential from the access token
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.tokenString);

        // Sign in to Firebase with the credential
        final userCredential = await _auth.signInWithCredential(credential);

        // Create or update user document
        if (userCredential.user != null) {
          await _createOrUpdateSocialUser(userCredential.user!, 'Facebook');
        }

        return userCredential;
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else {
        throw Exception('فشل تسجيل الدخول: ${result.message}');
      }
    } catch (e) {
      throw Exception('فشل تسجيل الدخول بـ Facebook: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      // Delete Firebase Auth account
      await user.delete();
    }
  }

  // Private helper methods

  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String name,
    String? phone,
  }) async {
    final user = UserModel(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(user.toJson());
  }

  Future<void> _createOrUpdateSocialUser(
      User firebaseUser, String provider) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // Create new user document
      final user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'مستخدم',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(user.toJson());
    } else {
      // Update last login
      await _updateLastLogin(firebaseUser.uid);
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً، حاول لاحقاً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت';
      default:
        return 'حدث خطأ: ${e.message}';
    }
  }
}
