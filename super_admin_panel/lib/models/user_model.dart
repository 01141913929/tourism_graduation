/// أدوار المستخدمين في النظام
enum UserRole {
  customer, // عميل عادي (افتراضي)
  bazaarOwner, // صاحب بازار
  superAdmin, // مدير النظام
}

/// حالة طلب إنشاء البازار
enum BazaarApplicationStatus {
  none, // لم يقدم طلب
  pending, // قيد المراجعة
  approved, // موافق عليه
  rejected, // مرفوض
}

/// User model for Firebase integration
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final List<Address> addresses;
  final List<String> favoriteProductIds;
  final List<String> favoriteArtifactIds;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // حقول جديدة للأدوار والبازارات
  final UserRole role;
  final String? bazaarId; // معرف البازار (فقط لـ bazaarOwner)
  final BazaarApplicationStatus applicationStatus;
  final String? applicationRejectionReason;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.addresses = const [],
    this.favoriteProductIds = const [],
    this.favoriteArtifactIds = const [],
    required this.createdAt,
    this.lastLoginAt,
    this.role = UserRole.customer,
    this.bazaarId,
    this.applicationStatus = BazaarApplicationStatus.none,
    this.applicationRejectionReason,
  });

  /// هل المستخدم صاحب بازار موافق عليه
  bool get isApprovedBazaarOwner =>
      role == UserRole.bazaarOwner &&
      applicationStatus == BazaarApplicationStatus.approved &&
      bazaarId != null;

  /// هل المستخدم مدير النظام
  bool get isSuperAdmin => role == UserRole.superAdmin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteProductIds:
          (json['favoriteProductIds'] as List<dynamic>?)?.cast<String>() ?? [],
      favoriteArtifactIds:
          (json['favoriteArtifactIds'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.customer,
      ),
      bazaarId: json['bazaarId'] as String?,
      applicationStatus: BazaarApplicationStatus.values.firstWhere(
        (e) => e.name == json['applicationStatus'],
        orElse: () => BazaarApplicationStatus.none,
      ),
      applicationRejectionReason: json['applicationRejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'favoriteProductIds': favoriteProductIds,
      'favoriteArtifactIds': favoriteArtifactIds,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'role': role.name,
      'bazaarId': bazaarId,
      'applicationStatus': applicationStatus.name,
      'applicationRejectionReason': applicationRejectionReason,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    List<Address>? addresses,
    List<String>? favoriteProductIds,
    List<String>? favoriteArtifactIds,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserRole? role,
    String? bazaarId,
    BazaarApplicationStatus? applicationStatus,
    String? applicationRejectionReason,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      addresses: addresses ?? this.addresses,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      favoriteArtifactIds: favoriteArtifactIds ?? this.favoriteArtifactIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      role: role ?? this.role,
      bazaarId: bazaarId ?? this.bazaarId,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      applicationRejectionReason:
          applicationRejectionReason ?? this.applicationRejectionReason,
    );
  }
}

/// Address model for user addresses
class Address {
  final String id;
  final String label; // منزل، عمل، إلخ
  final String addressLine;
  final String city;
  final String country;
  final String? postalCode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.addressLine,
    required this.city,
    this.country = 'مصر',
    this.postalCode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      addressLine: json['addressLine'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? 'مصر',
      postalCode: json['postalCode'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'addressLine': addressLine,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }

  Address copyWith({
    String? id,
    String? label,
    String? addressLine,
    String? city,
    String? country,
    String? postalCode,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Payment method model for user payment cards
class PaymentMethod {
  final String id;
  final String type; // visa, mastercard, etc.
  final String last4;
  final String expiry;
  final String holderName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.expiry,
    required this.holderName,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      last4: json['last4'] as String? ?? '',
      expiry: json['expiry'] as String? ?? '',
      holderName: json['holderName'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'expiry': expiry,
      'holderName': holderName,
      'isDefault': isDefault,
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? last4,
    String? expiry,
    String? holderName,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      expiry: expiry ?? this.expiry,
      holderName: holderName ?? this.holderName,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
