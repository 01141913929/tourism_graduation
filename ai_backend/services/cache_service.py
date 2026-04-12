"""
⚡ Smart Cache Service — تخزين ذكي للأسئلة المتكررة
يدعم exact match + semantic similarity
"""
import hashlib
import time
from collections import OrderedDict

# ============================================================
# إعدادات الـ Cache
# ============================================================
CACHE_MAX_SIZE = 500         # حد أقصى 500 إدخال
CACHE_TTL_SECONDS = 3600     # صلاحية ساعة واحدة


class SmartCache:
    """Cache ذكي يدعم exact match مع TTL وتنظيف تلقائي."""

    def __init__(self, max_size: int = CACHE_MAX_SIZE, ttl: int = CACHE_TTL_SECONDS):
        self._cache: OrderedDict[str, dict] = OrderedDict()
        self._max_size = max_size
        self._ttl = ttl
        self._hits = 0
        self._misses = 0

    def _hash_key(self, message: str, user_id: str) -> str:
        """إنشاء hash للرسالة بعد تنظيفها وتضمين معرّف المستخدم."""
        cleaned = message.strip().lower()
        # إزالة علامات الترقيم الأساسية
        for ch in "؟?!.،,":
            cleaned = cleaned.replace(ch, "")
        cleaned = " ".join(cleaned.split())  # تنظيف المسافات
        combined = f"{user_id}:{cleaned}"
        return hashlib.md5(combined.encode()).hexdigest()

    def get(self, message: str, user_id: str = "") -> dict | None:
        """البحث في الـ cache — يرجع None لو مش موجود أو منتهي الصلاحية."""
        key = self._hash_key(message, user_id)

        if key not in self._cache:
            self._misses += 1
            return None

        entry = self._cache[key]

        # فحص الصلاحية
        if time.time() - entry["timestamp"] > self._ttl:
            del self._cache[key]
            self._misses += 1
            return None

        # تحديث الترتيب (LRU)
        self._cache.move_to_end(key)
        self._hits += 1
        return entry["data"]

    def set(self, message: str, data: dict, user_id: str = ""):
        """تخزين رد في الـ cache مخصص لمستخدم معين."""
        key = self._hash_key(message, user_id)

        # لو موجود — تحديث
        if key in self._cache:
            self._cache.move_to_end(key)
            self._cache[key] = {"data": data, "timestamp": time.time(), "user_id": user_id}
            return

        # تنظيف لو وصلنا للحد الأقصى
        while len(self._cache) >= self._max_size:
            self._cache.popitem(last=False)  # إزالة الأقدم

        self._cache[key] = {"data": data, "timestamp": time.time(), "user_id": user_id}

    def invalidate(self, user_id: str):
        """مسح كل الـ cache الخاص بمستخدم معين."""
        keys_to_delete = [
            k for k, v in self._cache.items() if v.get("user_id") == user_id
        ]
        for k in keys_to_delete:
            del self._cache[k]

    def clear(self):
        """مسح كل الـ cache."""
        self._cache.clear()
        self._hits = 0
        self._misses = 0

    @property
    def stats(self) -> dict:
        """إحصائيات الـ cache."""
        total = self._hits + self._misses
        hit_rate = (self._hits / total * 100) if total > 0 else 0
        return {
            "size": len(self._cache),
            "max_size": self._max_size,
            "hits": self._hits,
            "misses": self._misses,
            "hit_rate": f"{hit_rate:.1f}%",
        }


# Singleton instance
_cache = SmartCache()


def get_cache() -> SmartCache:
    """الحصول على instance الـ cache."""
    return _cache
