import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/bazaar_model.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';
import '../services/notification_service.dart';

/// نموذج طلب بازار جديد
class BazaarApplication {
  final String id;
  final String userId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String bazaarName;
  final String description;
  final String address;
  final String governorate;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final String? rejectionReason;

  const BazaarApplication({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.bazaarName,
    required this.description,
    required this.address,
    required this.governorate,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  factory BazaarApplication.fromJson(Map<String, dynamic> json) {
    try {
      return BazaarApplication(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? 'غير محدد',
        ownerEmail: json['ownerEmail'] as String? ?? '',
        ownerPhone: json['ownerPhone'] as String? ?? '',
        bazaarName: json['bazaarName'] as String? ?? 'بازار غير مسمى',
        description: json['description'] as String? ?? '',
        address: json['address'] as String? ?? '',
        governorate: json['governorate'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        rejectionReason: json['rejectionReason'] as String?,
      );
    } catch (e) {
      debugPrint('❌ Error parsing BazaarApplication: $e');
      debugPrint('📄 JSON data: $json');
      rethrow;
    }
  }
}

/// Provider لإدارة البيانات في لوحة Super Admin
class AdminDataProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  List<BazaarApplication> _pendingApplications = [];
  List<Bazaar> _allBazaars = [];
  List<UserModel> _allUsers = [];
  List<Product> _allProducts = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // إحصائيات
  int _totalUsers = 0;
  int _totalBazaars = 0;
  int _pendingApprovals = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0;
  int _totalProducts = 0;
  int _activeProducts = 0;

  List<BazaarApplication> get pendingApplications => _pendingApplications;
  List<Bazaar> get allBazaars => _allBazaars;
  List<UserModel> get allUsers => _allUsers;
  List<Product> get allProducts => _allProducts;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalUsers => _totalUsers;
  int get totalBazaars => _totalBazaars;
  int get pendingApprovals => _pendingApprovals;
  int get totalOrders => _totalOrders;
  double get totalRevenue => _totalRevenue;
  int get totalProducts => _totalProducts;
  int get activeProducts => _activeProducts;

  /// تحميل كل البيانات
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadPendingApplications(),
        _loadAllBazaars(),
        _loadAllUsers(),
        _loadStatistics(),
        _loadAllProducts(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading admin data: $e');
      _error = 'خطأ في تحميل البيانات: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPendingApplications() async {
    try {
      debugPrint('📋 Loading pending applications...');

      // استعلام بسيط بدون orderBy لتجنب مشكلة composite index
      final snapshot = await _firestore
          .collection('bazaarApplications')
          .where('status', isEqualTo: 'pending')
          .get();

      debugPrint('📋 Found ${snapshot.docs.length} pending applications');

      _pendingApplications = snapshot.docs
          .map((doc) =>
              BazaarApplication.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // ترتيب محلياً بدل Firestore
      _pendingApplications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _pendingApprovals = _pendingApplications.length;
    } catch (e) {
      debugPrint('❌ Error loading pending applications: $e');
      _pendingApplications = [];
      _pendingApprovals = 0;
      rethrow;
    }
  }

  Future<void> _loadAllBazaars() async {
    try {
      debugPrint('🏪 Loading bazaars...');

      final snapshot = await _firestore.collection('bazaars').get();

      debugPrint('🏪 Found ${snapshot.docs.length} bazaars');

      _allBazaars = snapshot.docs
          .map((doc) => Bazaar.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      // ترتيب محلياً
      _allBazaars.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _totalBazaars = _allBazaars.length;
    } catch (e) {
      debugPrint('❌ Error loading bazaars: $e');
      _allBazaars = [];
      _totalBazaars = 0;
      rethrow;
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      debugPrint('👥 Loading users...');

      final snapshot = await _firestore.collection('users').limit(100).get();

      debugPrint('👥 Found ${snapshot.docs.length} users');

      _allUsers = snapshot.docs
          .map((doc) => UserModel.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();

      // ترتيب محلياً
      _allUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _totalUsers = _allUsers.length;
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      _allUsers = [];
      _totalUsers = 0;
      rethrow;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      debugPrint('📊 Loading statistics...');

      // عدد الطلبات الإجمالي
      final ordersSnapshot =
          await _firestore.collection('orders').count().get();
      _totalOrders = ordersSnapshot.count ?? 0;

      debugPrint('📊 Total orders: $_totalOrders');

      // حساب الإيرادات من الطلبات المكتملة
      final completedSubOrders = await _firestore
          .collection('subOrders')
          .where('status', isEqualTo: 'delivered')
          .get();

      _totalRevenue = 0;
      for (final doc in completedSubOrders.docs) {
        _totalRevenue += (doc.data()['subtotal'] as num?)?.toDouble() ?? 0;
      }

      debugPrint('📊 Total revenue: $_totalRevenue');
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
      _totalOrders = 0;
      _totalRevenue = 0;
      // لا نعيد الخطأ هنا لأن الإحصائيات ليست حرجة
    }
  }

  /// الموافقة على طلب بازار
  Future<bool> approveApplication(BazaarApplication application) async {
    try {
      // 1. إنشاء البازار في Firestore
      final bazaarDoc = _firestore.collection('bazaars').doc();
      await bazaarDoc.set({
        'id': bazaarDoc.id,
        'nameAr': application.bazaarName,
        'nameEn': application.bazaarName, // يمكن تعديله لاحقاً
        'descriptionAr': application.description,
        'descriptionEn': application.description,
        'ownerUserId': application.userId,
        'address': application.address,
        'governorate': application.governorate,
        'phone': application.ownerPhone,
        'email': application.ownerEmail,
        'isOpen': true,
        'isVerified': true,
        'rating': 0.0,
        'reviewsCount': 0,
        'productIds': [],
        'createdAt': DateTime.now().toIso8601String(),
      });

      // 2. تحديث حالة المستخدم
      await _firestore.collection('users').doc(application.userId).update({
        'role': 'bazaarOwner',
        'bazaarId': bazaarDoc.id,
        'applicationStatus': 'approved',
      });

      // 3. تحديث حالة الطلب
      await _firestore
          .collection('bazaarApplications')
          .doc(application.id)
          .update({'status': 'approved'});

      // Notify Bazaar Owner
      NotificationService().sendNotification(
        targetUserId: application.userId,
        title: 'تهانينا! تمت الموافقة على البازار',
        body:
            'تمت الموافقة على طلبك لفتح ${application.bazaarName}. يمكنك الآن الدخول وإضافة منتجاتك.',
        data: {'type': 'bazaar_approval', 'bazaarId': bazaarDoc.id},
      );

      await loadAllData();
      return true;
    } catch (e) {
      debugPrint('Error approving application: $e');
      return false;
    }
  }

  /// رفض طلب بازار
  Future<bool> rejectApplication(
    BazaarApplication application,
    String reason,
  ) async {
    try {
      // 1. تحديث حالة المستخدم
      await _firestore.collection('users').doc(application.userId).update({
        'applicationStatus': 'rejected',
        'applicationRejectionReason': reason,
      });

      // 2. تحديث حالة الطلب
      await _firestore
          .collection('bazaarApplications')
          .doc(application.id)
          .update({'status': 'rejected', 'rejectionReason': reason});

      // Notify Bazaar Owner
      NotificationService().sendNotification(
        targetUserId: application.userId,
        title: 'عذراً، تم رفض طلب البازار',
        body: 'تم رفض طلبك لفتح ${application.bazaarName}. السبب: $reason',
        data: {'type': 'bazaar_rejection'},
      );

      await loadAllData();
      return true;
    } catch (e) {
      debugPrint('Error rejecting application: $e');
      return false;
    }
  }

  /// إلغاء تفعيل / تفعيل بازار
  Future<bool> toggleBazaarVerification(
    String bazaarId,
    bool isVerified,
  ) async {
    try {
      await _firestore.collection('bazaars').doc(bazaarId).update({
        'isVerified': isVerified,
      });
      await _loadAllBazaars();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error toggling bazaar verification: $e');
      return false;
    }
  }

  /// تغيير دور المستخدم
  Future<bool> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
      });
      await _loadAllUsers();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }

  // ============ Products Management ============

  /// تحميل جميع المنتجات
  Future<void> _loadAllProducts() async {
    try {
      debugPrint('📦 Loading products...');
      _allProducts = await _productService.getAllProducts();
      _totalProducts = _allProducts.length;
      _activeProducts = _allProducts.where((p) => p.isActive).length;
      debugPrint('📦 Loaded ${_allProducts.length} products');
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      _allProducts = [];
      _totalProducts = 0;
      _activeProducts = 0;
    }
  }

  /// تحميل المنتجات (public method)
  Future<void> loadAllProducts() async {
    _isLoading = true;
    notifyListeners();

    await _loadAllProducts();

    _isLoading = false;
    notifyListeners();
  }

  /// إنشاء منتج جديد
  Future<bool> createProduct(Product product) async {
    try {
      final productId = await _productService.createProduct(product);
      if (productId != null) {
        await _loadAllProducts();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error creating product: $e');
      return false;
    }
  }

  /// تحديث منتج
  Future<bool> updateProduct(
      String productId, Map<String, dynamic> data) async {
    try {
      final success = await _productService.updateProduct(productId, data);
      if (success) {
        await _loadAllProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(String productId) async {
    try {
      final success = await _productService.deleteProduct(productId);
      if (success) {
        await _loadAllProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      return false;
    }
  }

  /// تفعيل/إيقاف منتج
  Future<bool> toggleProductStatus(String productId, bool isActive) async {
    try {
      final success =
          await _productService.toggleProductStatus(productId, isActive);
      if (success) {
        await _loadAllProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error toggling product status: $e');
      return false;
    }
  }

  /// تحديث منتجات متعددة
  Future<bool> bulkUpdateProducts(
    List<String> productIds,
    Map<String, dynamic> data,
  ) async {
    try {
      final success =
          await _productService.bulkUpdateProducts(productIds, data);
      if (success) {
        await _loadAllProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error in bulk update: $e');
      return false;
    }
  }

  /// حذف منتجات متعددة
  Future<bool> bulkDeleteProducts(List<String> productIds) async {
    try {
      final success = await _productService.bulkDeleteProducts(productIds);
      if (success) {
        await _loadAllProducts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error in bulk delete: $e');
      return false;
    }
  }

  /// تحميل الفئات
  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getAllCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
    }
  }
}
