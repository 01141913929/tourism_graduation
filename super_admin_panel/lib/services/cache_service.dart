import 'dart:async';

/// خدمة التخزين المؤقت في الذاكرة مع TTL
/// تُستخدم لتحسين أداء التطبيق بتقليل طلبات Firestore
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};

  /// الحصول على قيمة من الـ cache
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // التحقق من انتهاء الصلاحية
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.value as T?;
  }

  /// حفظ قيمة في الـ cache
  void set<T>(String key, T value,
      {Duration ttl = const Duration(minutes: 5)}) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  /// إبطال قيمة محددة
  void invalidate(String key) {
    _cache.remove(key);
  }

  /// إبطال قيم بنمط معين
  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.startsWith(pattern));
  }

  /// مسح كل الـ cache
  void clear() {
    _cache.clear();
  }

  /// تنظيف القيم المنتهية الصلاحية
  void cleanup() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// الحصول على قيمة أو تحميلها
  Future<T> getOrLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final cached = get<T>(key);
    if (cached != null) return cached;

    final value = await loader();
    set(key, value, ttl: ttl);
    return value;
  }
}

/// إدخال في الـ cache مع وقت انتهاء الصلاحية
class _CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
