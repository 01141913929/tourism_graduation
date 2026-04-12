"""
Egyptian Tourism AI Backend - LLM & Embeddings Service
يدعم Groq و Gemini — مع Fallback Chain ذكي + Singleton Caching + Async Fallback
"""
import asyncio
from functools import lru_cache
from config import (
    GEMINI_API_KEY, GEMINI_MODEL, GEMINI_EMBEDDING_MODEL,
    GROQ_API_KEY, GROQ_MODEL, LLM_PROVIDER,
)

# ============================================================
# ردود مخزنة للطوارئ — آخر خط دفاع
# ============================================================
EMERGENCY_RESPONSES = {
    "history_agent": "عذراً، النظام مشغول حالياً. لكن أقدر أقولك إن مصر فيها أكتر من 7000 سنة تاريخ مذهل! جرّب تاني بعد شوية وهحكيلك كل حاجة 😊",
    "product_agent": "عذراً، مش قادر أوصل للمنتجات دلوقتي. بس تقدر تتصفح المنتجات في الابليكيشن مباشرة! جرّب تاني بعد شوية 🛍️",
    "tour_guide_agent": "عذراً، النظام مشغول. بس نصيحتي: ابدأ بأهرامات الجيزة والمتحف المصري الكبير — دول لازم يتزاروا! 🏛️",
    "cart_agent": "عذراً، مش قادر أعالج طلب السلة دلوقتي. جرّب تاني بعد شوية! 🛒",
    "general_agent": "عذراً، النظام مشغول شوية. جرّب تاني بعد دقيقة وهكون جاهز أساعدك! 😊",
    "default": "عذراً، حدث خطأ مؤقت. جرّب تاني بعد شوية! 🙏",
}

# ============================================================
# LLM Instance Cache — بدل ما ننشئ instance جديد كل مرة
# ============================================================
_llm_cache: dict[str, object] = {}


def get_llm(temperature: float = 0.7):
    """Get LLM instance — Groq أو Gemini حسب الإعدادات (مع caching)."""
    cache_key = f"{LLM_PROVIDER}_{temperature}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    if LLM_PROVIDER == "groq":
        from langchain_groq import ChatGroq
        instance = ChatGroq(
            model=GROQ_MODEL,
            api_key=GROQ_API_KEY,
            temperature=temperature,
        )
    else:
        from langchain_google_genai import ChatGoogleGenerativeAI
        instance = ChatGoogleGenerativeAI(
            model=GEMINI_MODEL,
            google_api_key=GEMINI_API_KEY,
            temperature=temperature,
            convert_system_message_to_human=False,
        )

    _llm_cache[cache_key] = instance
    return instance


def get_fast_llm(temperature: float = 0.0):
    """Get fast LLM — نموذج أصغر وأسرع للمهام البسيطة (routing, evaluation)."""
    cache_key = f"fast_{LLM_PROVIDER}_{temperature}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    if LLM_PROVIDER == "groq":
        from langchain_groq import ChatGroq
        from config import GROQ_FAST_MODEL
        instance = ChatGroq(
            model=GROQ_FAST_MODEL,
            api_key=GROQ_API_KEY,
            temperature=temperature,
        )
    else:
        instance = get_llm(temperature=temperature)

    _llm_cache[cache_key] = instance
    return instance


def get_streaming_llm(temperature: float = 0.7):
    """Get streaming LLM — للردود المتدفقة chunk by chunk."""
    cache_key = f"stream_{LLM_PROVIDER}_{temperature}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    if LLM_PROVIDER == "groq":
        from langchain_groq import ChatGroq
        instance = ChatGroq(
            model=GROQ_MODEL,
            api_key=GROQ_API_KEY,
            temperature=temperature,
            streaming=True,
        )
    else:
        from langchain_google_genai import ChatGoogleGenerativeAI
        instance = ChatGoogleGenerativeAI(
            model=GEMINI_MODEL,
            google_api_key=GEMINI_API_KEY,
            temperature=temperature,
            convert_system_message_to_human=False,
            streaming=True,
        )

    _llm_cache[cache_key] = instance
    return instance


def _get_gemini_fallback(temperature: float = 0.7):
    """الحصول على Gemini كـ fallback — بغض النظر عن الـ provider الأساسي."""
    cache_key = f"gemini_fallback_{temperature}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    from langchain_google_genai import ChatGoogleGenerativeAI
    instance = ChatGoogleGenerativeAI(
        model=GEMINI_MODEL,
        google_api_key=GEMINI_API_KEY,
        temperature=temperature,
        convert_system_message_to_human=False,
    )
    _llm_cache[cache_key] = instance
    return instance


# ============================================================
# Fallback Chain — الآن async + يدعم messages list
# ============================================================

async def invoke_with_fallback(prompt, agent: str = "default",
                                temperature: float = 0.7,
                                timeout: float = 30.0) -> str:
    """استدعاء LLM مع Fallback Chain: Primary → Gemini → رد مخزن.

    يقبل:
    - str: prompt نصي
    - list: قائمة LangChain messages
    """
    # === المحاولة 1: المزود الأساسي ===
    try:
        llm = get_llm(temperature=temperature)
        result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=timeout)
        return result.content
    except Exception as e:
        print(f"⚠️ Primary LLM failed: {e}")

    # === المحاولة 2: Gemini كـ fallback ===
    if GEMINI_API_KEY and LLM_PROVIDER != "gemini":
        try:
            gemini = _get_gemini_fallback(temperature)
            result = await asyncio.wait_for(gemini.ainvoke(prompt), timeout=timeout)
            print("✅ Gemini fallback succeeded")
            return result.content
        except Exception as e:
            print(f"⚠️ Gemini fallback failed: {e}")

    # === المحاولة 3: رد مخزن (آخر خط دفاع) ===
    print("🆘 Using emergency response")
    return EMERGENCY_RESPONSES.get(agent, EMERGENCY_RESPONSES["default"])


async def invoke_llm_with_retry(prompt, temperature: float = 0.7,
                                 max_retries: int = 3,
                                 agent: str = "default") -> str:
    """استدعاء LLM مع retry + exponential backoff + fallback.

    أفضل من invoke_with_fallback لأنه يحاول نفس المزود أكثر من مرة قبل الـ fallback.
    """
    last_error = None

    for attempt in range(max_retries):
        try:
            llm = get_llm(temperature=temperature)
            timeout = 30.0 + (attempt * 10)  # timeout يزيد مع كل محاولة
            result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=timeout)
            return result.content
        except asyncio.TimeoutError:
            last_error = "timeout"
            print(f"⏰ LLM timeout (attempt {attempt + 1}/{max_retries})")
        except Exception as e:
            last_error = str(e)
            error_msg = str(e).lower()

            # Rate limit → انتظار أطول
            if "429" in error_msg or "rate" in error_msg or "quota" in error_msg:
                wait_time = 5 * (attempt + 1)
                print(f"⚠️ Rate limited (attempt {attempt + 1}). Waiting {wait_time}s...")
                await asyncio.sleep(wait_time)
            else:
                # خطأ آخر → انتظار قصير
                await asyncio.sleep(1 * (attempt + 1))

    # كل المحاولات فشلت → fallback
    print(f"❌ All {max_retries} retries failed. Last error: {last_error}")
    return await invoke_with_fallback(prompt, agent=agent, temperature=temperature)


# ============================================================
# Embeddings
# ============================================================

def get_embeddings():
    """Get Gemini embeddings instance (دايماً Gemini)."""
    cache_key = "embeddings_doc"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    from langchain_google_genai import GoogleGenerativeAIEmbeddings
    instance = GoogleGenerativeAIEmbeddings(
        model=GEMINI_EMBEDDING_MODEL,
        google_api_key=GEMINI_API_KEY,
        task_type="retrieval_document",
    )
    _llm_cache[cache_key] = instance
    return instance


def get_query_embeddings():
    """Get Gemini embeddings for queries (دايماً Gemini)."""
    cache_key = "embeddings_query"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    from langchain_google_genai import GoogleGenerativeAIEmbeddings
    instance = GoogleGenerativeAIEmbeddings(
        model=GEMINI_EMBEDDING_MODEL,
        google_api_key=GEMINI_API_KEY,
        task_type="retrieval_query",
    )
    _llm_cache[cache_key] = instance
    return instance
