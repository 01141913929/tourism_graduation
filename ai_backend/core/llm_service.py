"""
🤖 Core LLM Service — Shared LLM access for all microservices.
Supports: Groq (primary) + Gemini (fallback) with per-app API key routing.
"""
import asyncio
import logging
from core.config import (
    GEMINI_API_KEY, GEMINI_MODEL, GEMINI_EMBEDDING_MODEL,
    GROQ_API_KEY, GROQ_API_KEY_OWNER, GROQ_API_KEY_ADMIN,
    GROQ_MODEL, GROQ_FAST_MODEL, LLM_PROVIDER,
)

logger = logging.getLogger(__name__)

# ============================================================
# Emergency Responses — Last line of defense
# ============================================================
EMERGENCY_RESPONSES = {
    "admin": "عذراً، النظام مشغول. جرّب تاني بعد لحظات.",
    "owner": "عذراً، مش قادر أوصل للبيانات دلوقتي. جرّب تاني.",
    "default": "عذراً، حدث خطأ مؤقت. جرّب تاني بعد شوية! 🙏",
}

# ============================================================
# LLM Instance Cache
# ============================================================
_llm_cache: dict[str, object] = {}


def _get_groq_key_for_app(app_id: str) -> str:
    """Route to the correct Groq API key based on the app."""
    if app_id == "admin":
        return GROQ_API_KEY_ADMIN or GROQ_API_KEY
    if app_id == "owner":
        return GROQ_API_KEY_OWNER or GROQ_API_KEY
    return GROQ_API_KEY


def get_llm(temperature: float = 0.7, app_id: str = "tourist"):
    """Get LLM instance — Groq or Gemini based on config (cached)."""
    cache_key = f"{LLM_PROVIDER}_{temperature}_{app_id}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    if LLM_PROVIDER == "groq":
        from langchain_groq import ChatGroq
        instance = ChatGroq(
            model=GROQ_MODEL,
            api_key=_get_groq_key_for_app(app_id),
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


def get_fast_llm(temperature: float = 0.7, app_id: str = "tourist"):
    """Get fast LLM — smaller model for routing/evaluation tasks."""
    cache_key = f"fast_{LLM_PROVIDER}_{temperature}_{app_id}"
    if cache_key in _llm_cache:
        return _llm_cache[cache_key]

    if LLM_PROVIDER != "groq":
        instance = get_llm(temperature=temperature, app_id=app_id)
        _llm_cache[cache_key] = instance
        return instance

    from langchain_groq import ChatGroq
    instance = ChatGroq(
        model=GROQ_FAST_MODEL,
        temperature=temperature,
        api_key=_get_groq_key_for_app(app_id),
        max_retries=2,
        timeout=15.0,
    )
    _llm_cache[cache_key] = instance
    return instance


def _get_gemini_fallback(temperature: float = 0.7):
    """Get Gemini as fallback — regardless of primary provider."""
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
# Fallback Chain — async + supports messages list
# ============================================================

async def invoke_with_fallback(prompt, agent: str = "default",
                                temperature: float = 0.7,
                                timeout: float = 30.0) -> str:
    """Invoke LLM with Fallback Chain: Primary → Gemini → Emergency response."""
    # Attempt 1: Primary provider
    try:
        llm = get_llm(temperature=temperature, app_id="admin")
        result = await asyncio.wait_for(llm.ainvoke(prompt), timeout=timeout)
        return result.content
    except Exception as e:
        logger.warning(f"Primary LLM failed: {e}")

    # Attempt 2: Gemini fallback
    if GEMINI_API_KEY and LLM_PROVIDER != "gemini":
        try:
            gemini = _get_gemini_fallback(temperature)
            result = await asyncio.wait_for(gemini.ainvoke(prompt), timeout=timeout)
            logger.info("Gemini fallback succeeded")
            return result.content
        except Exception as e:
            logger.warning(f"Gemini fallback failed: {e}")

    # Attempt 3: Emergency response
    logger.warning("Using emergency response")
    return EMERGENCY_RESPONSES.get(agent, EMERGENCY_RESPONSES["default"])


# ============================================================
# Embeddings
# ============================================================

def get_embeddings():
    """Get Gemini embeddings instance (always Gemini)."""
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
    """Get Gemini embeddings for queries."""
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
