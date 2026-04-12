"""
🛡️ Middleware — برمجيات وسيطة
Rate Limiting + Request Logging + Error Handling
"""
import time
import asyncio
from collections import defaultdict
from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from config import RATE_LIMIT_RPM


# ============================================================
# Rate Limiting — حد معدل الطلبات
# ============================================================

class RateLimitMiddleware(BaseHTTPMiddleware):
    """حد معدل الطلبات — Token Bucket algorithm."""

    def __init__(self, app, requests_per_minute: int = RATE_LIMIT_RPM):
        super().__init__(app)
        self.rpm = requests_per_minute
        self._buckets: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next):
        # تجاوز الـ rate limiting للـ health check و الـ docs
        if request.url.path in ["/", "/health", "/docs", "/openapi.json"]:
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.time()

        # تنظيف الطلبات القديمة (أكثر من دقيقة)
        self._buckets[client_ip] = [
            t for t in self._buckets[client_ip]
            if now - t < 60
        ]

        # فحص الحد
        if len(self._buckets[client_ip]) >= self.rpm:
            return JSONResponse(
                status_code=429,
                content={
                    "error": "تم تجاوز حد الطلبات",
                    "detail": f"الحد الأقصى: {self.rpm} طلب/دقيقة",
                    "retry_after": 60,
                }
            )

        # تسجيل الطلب
        self._buckets[client_ip].append(now)

        return await call_next(request)


# ============================================================
# Request Logging — تسجيل الطلبات
# ============================================================

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """تسجيل تفاصيل كل طلب."""

    async def dispatch(self, request: Request, call_next):
        start = time.time()

        response = await call_next(request)

        duration = round((time.time() - start) * 1000, 2)
        method = request.method
        path = request.url.path
        status = response.status_code

        # تلوين حسب الحالة
        emoji = "✅" if status < 400 else "⚠️" if status < 500 else "❌"
        print(f"{emoji} {method} {path} → {status} ({duration}ms)")

        # إضافة headers مفيدة
        response.headers["X-Response-Time"] = f"{duration}ms"
        response.headers["X-Powered-By"] = "Egyptian Tourism AI"

        return response


# ============================================================
# Error Handling — معالجة الأخطاء
# ============================================================

class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """معالجة الأخطاء غير المتوقعة."""

    async def dispatch(self, request: Request, call_next):
        try:
            return await call_next(request)
        except Exception as e:
            print(f"❌ خطأ غير متوقع: {e}")
            return JSONResponse(
                status_code=500,
                content={
                    "error": "خطأ في السيرفر",
                    "detail": "حدث خطأ غير متوقع. حاول ثانية.",
                }
            )
