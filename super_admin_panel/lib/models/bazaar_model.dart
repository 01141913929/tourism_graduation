/// Bazaar/Shop model for e-commerce locations
class Bazaar {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String imageUrl;
  final List<String> galleryImages;
  final String address;
  final String governorate; // المحافظة
  final double latitude;
  final double longitude;
  final String phone;
  final String? email;
  final String ownerUserId;
  final List<String> productIds;
  final bool isOpen;
  final String workingHours;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final bool isVerified;

  // getter for alternative name
  int get reviewsCount => reviewCount;

  const Bazaar({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    required this.descriptionAr,
    this.descriptionEn = '',
    required this.imageUrl,
    this.galleryImages = const [],
    required this.address,
    this.governorate = '',
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.email,
    required this.ownerUserId,
    this.productIds = const [],
    this.isOpen = true,
    this.workingHours = '9:00 - 21:00',
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.isVerified = false,
  });

  factory Bazaar.fromJson(Map<String, dynamic> json) {
    return Bazaar(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      descriptionAr: json['descriptionAr'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      galleryImages:
          (json['galleryImages'] as List<dynamic>?)?.cast<String>() ?? [],
      address: json['address'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      ownerUserId: json['ownerUserId'] as String? ?? '',
      productIds: (json['productIds'] as List<dynamic>?)?.cast<String>() ?? [],
      isOpen: json['isOpen'] as bool? ?? true,
      workingHours: json['workingHours'] as String? ?? '9:00 - 21:00',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'address': address,
      'governorate': governorate,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'ownerUserId': ownerUserId,
      'productIds': productIds,
      'isOpen': isOpen,
      'workingHours': workingHours,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  Bazaar copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? imageUrl,
    List<String>? galleryImages,
    String? address,
    String? governorate,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? ownerUserId,
    List<String>? productIds,
    bool? isOpen,
    String? workingHours,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    bool? isVerified,
  }) {
    return Bazaar(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      productIds: productIds ?? this.productIds,
      isOpen: isOpen ?? this.isOpen,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Get display name based on locale preference
  String getDisplayName({bool preferArabic = true}) {
    if (preferArabic || nameEn.isEmpty) {
      return nameAr;
    }
    return nameEn;
  }

  /// Get display description based on locale preference
  String getDisplayDescription({bool preferArabic = true}) {
    if (preferArabic || descriptionEn.isEmpty) {
      return descriptionAr;
    }
    return descriptionEn;
  }
}
