/// Product model for Super Admin Panel
/// Matches the structure used in egyptian_tourism_app and bazaar_owner_app
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
  final int stockQuantity;
  final bool isInStock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    required this.bazaarId,
    required this.bazaarName,
    this.isNew = false,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.stockQuantity = 100,
    this.isInStock = true,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((oldPrice! - price) / oldPrice! * 100).roundToDouble();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (json['oldPrice'] as num?)?.toDouble(),
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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, nameAr: $nameAr, price: $price, bazaarId: $bazaarId)';
  }
}
