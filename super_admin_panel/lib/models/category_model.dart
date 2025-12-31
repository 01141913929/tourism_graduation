/// Category model for products classification
class Category {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    this.icon = '📦',
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      icon: json['icon'] as String? ?? '📦',
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'icon': icon,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Category copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? icon,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, nameAr: $nameAr, order: $order)';
  }
}

/// Default categories for the platform
class DefaultCategories {
  static const List<Map<String, dynamic>> categories = [
    {'nameAr': 'تماثيل', 'nameEn': 'Statues', 'icon': '🗿', 'order': 1},
    {'nameAr': 'مجوهرات', 'nameEn': 'Jewelry', 'icon': '💍', 'order': 2},
    {
      'nameAr': 'ملابس تقليدية',
      'nameEn': 'Traditional Clothes',
      'icon': '👘',
      'order': 3
    },
    {'nameAr': 'أواني', 'nameEn': 'Pottery', 'icon': '🏺', 'order': 4},
    {'nameAr': 'لوحات', 'nameEn': 'Paintings', 'icon': '🖼️', 'order': 5},
    {
      'nameAr': 'هدايا تذكارية',
      'nameEn': 'Souvenirs',
      'icon': '🎁',
      'order': 6
    },
    {'nameAr': 'بردي', 'nameEn': 'Papyrus', 'icon': '📜', 'order': 7},
    {'nameAr': 'أخرى', 'nameEn': 'Others', 'icon': '📦', 'order': 99},
  ];
}
