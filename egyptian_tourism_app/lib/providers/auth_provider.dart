import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

/// Provider for authentication state management
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  AuthProvider({
    AuthService? authService,
    UserRepository? userRepository,
  })  : _authService = authService ?? AuthService(),
        _userRepository = userRepository ?? UserRepository() {
    _init();
  }

  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _firebaseUser != null;
  String? get error => _error;
  String? get userId => _firebaseUser?.uid;

  // Initialize auth state listener
  void _init() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _firebaseUser = user;
      _isInitialized = true;

      if (user != null) {
        _subscribeToUser(user.uid);
      } else {
        _userSubscription?.cancel();
        _user = null;
      }

      notifyListeners();
    });
  }

  void _subscribeToUser(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _userRepository.streamUser(uid).listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.signInWithFacebook();
      return credential != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.signInWithGoogle();
      return credential != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } finally {
      _setLoading(false);
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updatedUser = _user!.copyWith(
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        photoUrl: photoUrl ?? _user!.photoUrl,
      );

      await _userRepository.updateUser(updatedUser);

      if (name != null) {
        await _authService.updateProfile(displayName: name);
      }
      if (photoUrl != null) {
        await _authService.updateProfile(photoURL: photoUrl);
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle product favorite
  Future<bool> toggleFavorite(String productId) async {
    if (_user == null) return false;

    try {
      return await _userRepository.toggleFavorite(_user!.uid, productId);
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Check if product is favorite
  bool isFavorite(String productId) {
    return _user?.favoriteProductIds.contains(productId) ?? false;
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}
