"""
🧪 اختبارات Smart Cache Service
"""
import sys
import os
import time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.cache_service import SmartCache


class TestSmartCache:
    def _new_cache(self, **kwargs):
        return SmartCache(**kwargs)

    # --- Set/Get أساسي ---
    def test_set_and_get(self):
        cache = self._new_cache()
        cache.set("مرحبا", {"text": "أهلاً!"})
        result = cache.get("مرحبا")
        assert result is not None
        assert result["text"] == "أهلاً!"

    def test_cache_miss(self):
        cache = self._new_cache()
        assert cache.get("لا يوجد") is None

    # --- تنظيف النص ---
    def test_normalized_key(self):
        """نفس الرسالة مع علامات ترقيم مختلفة."""
        cache = self._new_cache()
        cache.set("مرحبا!", {"text": "رد 1"})
        result = cache.get("مرحبا")
        assert result is not None

    def test_case_insensitive(self):
        cache = self._new_cache()
        cache.set("Hello World", {"text": "hi"})
        assert cache.get("hello world") is not None

    # --- TTL ---
    def test_ttl_expired(self):
        cache = self._new_cache(ttl=1)  # صلاحية ثانية واحدة
        cache.set("test_ttl", {"text": "قديم"})
        time.sleep(1.5)
        assert cache.get("test_ttl") is None

    def test_ttl_valid(self):
        cache = self._new_cache(ttl=60)
        cache.set("test_ttl_ok", {"text": "جديد"})
        assert cache.get("test_ttl_ok") is not None

    # --- LRU ---
    def test_max_size(self):
        cache = self._new_cache(max_size=3)
        cache.set("a", {"v": 1})
        cache.set("b", {"v": 2})
        cache.set("c", {"v": 3})
        cache.set("d", {"v": 4})  # يحذف 'a'
        assert cache.get("a") is None
        assert cache.get("d") is not None

    def test_lru_access_updates_order(self):
        cache = self._new_cache(max_size=3)
        cache.set("x", {"v": 1})
        cache.set("y", {"v": 2})
        cache.set("z", {"v": 3})
        # الوصول لـ x يحدّثه في الترتيب
        cache.get("x")
        cache.set("w", {"v": 4})  # يحذف 'y' (الأقدم)
        assert cache.get("x") is not None
        assert cache.get("y") is None

    # --- Update ---
    def test_update_existing(self):
        cache = self._new_cache()
        cache.set("key", {"v": "old"})
        cache.set("key", {"v": "new"})
        assert cache.get("key")["v"] == "new"

    # --- Stats ---
    def test_stats(self):
        cache = self._new_cache()
        cache.set("s1", {"v": 1})
        cache.get("s1")  # hit
        cache.get("s2")  # miss
        stats = cache.stats
        assert stats["hits"] == 1
        assert stats["misses"] == 1
        assert stats["size"] == 1

    # --- Clear ---
    def test_clear(self):
        cache = self._new_cache()
        cache.set("a", {"v": 1})
        cache.set("b", {"v": 2})
        cache.clear()
        assert cache.get("a") is None
        stats = cache.stats
        assert stats["size"] == 0
        assert stats["hits"] == 0
