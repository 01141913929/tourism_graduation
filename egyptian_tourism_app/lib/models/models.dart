import 'sub_order_model.dart';

/// Product model for shop items
class Product {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final List<String> galleryImages;
  final List<String> sizes;
  final String? weight;
  final String? dimensions;
  final String? material;
  final String category;
  final String bazaarId;
  final String bazaarName;
  final bool isNew;
  final bool isFeatured;
  final double rating;
  final int reviewCount;
  final int stockQuantity; // كمية المخزون
  final bool isInStock; // هل متوفر في المخزون
  final bool isActive;

  const Product({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    required this.descriptionAr,
    this.descriptionEn = '',
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    this.galleryImages = const [],
    this.sizes = const [],
    this.weight,
    this.dimensions,
    this.material,
    required this.category,
    this.bazaarId = '',
    this.bazaarName = '',
    this.isNew = false,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stockQuantity = 100,
    this.isInStock = true,
    this.isActive = true,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((oldPrice! - price) / oldPrice! * 100).roundToDouble();
  }

  String getName(bool isArabic) {
    if (isArabic) return nameAr;
    return nameEn.isNotEmpty ? nameEn : nameAr;
  }

  String getDescription(bool isArabic) {
    if (isArabic) return descriptionAr;
    return descriptionEn.isNotEmpty ? descriptionEn : descriptionAr;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: json['oldPrice'] != null
          ? (json['oldPrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'] as String? ?? '',
      galleryImages:
          (json['galleryImages'] as List<dynamic>?)?.cast<String>() ?? [],
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      weight: json['weight'] as String?,
      dimensions: json['dimensions'] as String?,
      material: json['material'] as String?,
      category: json['category'] as String? ?? 'أخرى',
      bazaarId: json['bazaarId'] as String? ?? '',
      bazaarName: json['bazaarName'] as String? ?? '',
      isNew: json['isNew'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      stockQuantity: json['stockQuantity'] as int? ?? 100,
      isInStock: json['isInStock'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'sizes': sizes,
      'weight': weight,
      'dimensions': dimensions,
      'material': material,
      'category': category,
      'bazaarId': bazaarId,
      'bazaarName': bazaarName,
      'isNew': isNew,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'stockQuantity': stockQuantity,
      'isInStock': isInStock,
      'isActive': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    double? price,
    double? oldPrice,
    String? imageUrl,
    List<String>? galleryImages,
    List<String>? sizes,
    String? weight,
    String? dimensions,
    String? material,
    String? category,
    String? bazaarId,
    String? bazaarName,
    bool? isNew,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    int? stockQuantity,
    bool? isInStock,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      sizes: sizes ?? this.sizes,
      weight: weight ?? this.weight,
      dimensions: dimensions ?? this.dimensions,
      material: material ?? this.material,
      category: category ?? this.category,
      bazaarId: bazaarId ?? this.bazaarId,
      bazaarName: bazaarName ?? this.bazaarName,
      isNew: isNew ?? this.isNew,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isInStock: isInStock ?? this.isInStock,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Artifact model for museum items
class Artifact {
  final String id;
  final String nameAr;
  final String descriptionAr;
  final String imageUrl;
  final String era;
  final String location;
  final bool isFeatured;

  const Artifact({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.imageUrl,
    required this.era,
    required this.location,
    this.isFeatured = false,
  });

  String getName(bool isArabic) => nameAr;
  String getDescription(bool isArabic) => descriptionAr;

  factory Artifact.fromJson(Map<String, dynamic> json) {
    return Artifact(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      era: json['era'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'descriptionAr': descriptionAr,
      'imageUrl': imageUrl,
      'era': era,
      'location': location,
      'isFeatured': isFeatured,
    };
  }
}

/// Cart item model for Firebase
class CartItemModel {
  final String id;
  final String productId;
  final String selectedSize;
  final int quantity;

  const CartItemModel({
    required this.id,
    required this.productId,
    required this.selectedSize,
    this.quantity = 1,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      selectedSize: json['selectedSize'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'selectedSize': selectedSize,
      'quantity': quantity,
    };
  }
}

/// Cart item model (in-memory with full product)
class CartItem {
  final Product product;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItemModel toCartItemModel() {
    return CartItemModel(
      id: '${product.id}_$selectedSize',
      productId: product.id,
      selectedSize: selectedSize,
      quantity: quantity,
    );
  }
}

/// Order model - الطلب الأب (من وجهة نظر العميل)
class Order {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final List<String> subOrderIds; // معرفات الطلبات الفرعية
  final double totalAmount;
  final double taxes;
  final double shipping;
  final double discount;
  final String address;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  // حقول إضافية للتتبع
  final int totalItemCount;
  final int bazaarCount; // عدد البازارات

  const Order({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhone = '',
    required this.subOrderIds,
    required this.totalAmount,
    required this.taxes,
    required this.shipping,
    this.discount = 0,
    required this.address,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.totalItemCount = 0,
    this.bazaarCount = 1,
  });

  double get total => totalAmount + taxes + shipping - discount;

  /// هل الطلب مدفوع
  bool get isPaid => paymentStatus == PaymentStatus.paid;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      subOrderIds:
          (json['subOrderIds'] as List<dynamic>?)?.cast<String>() ?? [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['subtotal'] as num?)?.toDouble() ??
          0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      shipping: (json['shipping'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalItemCount: json['totalItemCount'] as int? ?? 0,
      bazaarCount: json['bazaarCount'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'subOrderIds': subOrderIds,
      'totalAmount': totalAmount,
      'taxes': taxes,
      'shipping': shipping,
      'discount': discount,
      'address': address,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'totalItemCount': totalItemCount,
      'bazaarCount': bazaarCount,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? userPhone,
    List<String>? subOrderIds,
    double? totalAmount,
    double? taxes,
    double? shipping,
    double? discount,
    String? address,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    int? totalItemCount,
    int? bazaarCount,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      subOrderIds: subOrderIds ?? this.subOrderIds,
      totalAmount: totalAmount ?? this.totalAmount,
      taxes: taxes ?? this.taxes,
      shipping: shipping ?? this.shipping,
      discount: discount ?? this.discount,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      totalItemCount: totalItemCount ?? this.totalItemCount,
      bazaarCount: bazaarCount ?? this.bazaarCount,
    );
  }
}

/// OrderStatus القديم - للتوافق العكسي
enum OrderStatus {
  submitted,
  preparing,
  shipping,
  delivered,
}

/// Exhibition hall model
class ExhibitionHall {
  final String id;
  final String nameAr;
  final String imageUrl;

  const ExhibitionHall({
    required this.id,
    required this.nameAr,
    required this.imageUrl,
  });

  factory ExhibitionHall.fromJson(Map<String, dynamic> json) {
    return ExhibitionHall(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'imageUrl': imageUrl,
    };
  }
}
