"""
Egyptian Tourism AI Backend - Configuration
✅ Fixed: Removed stale Firebase config, added logging setup, removed unused CHROMA_DIR
"""
import os
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# --- Logging Setup ---
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

# --- Paths ---
BASE_DIR = Path(__file__).parent
KNOWLEDGE_DIR = BASE_DIR / "knowledge"

# --- API Keys ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")

# --- Model Config ---
LLM_PROVIDER = os.getenv("LLM_PROVIDER", "groq")  # "groq" or "gemini"
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-pro")
GROQ_MODEL = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")
GROQ_FAST_MODEL = os.getenv("GROQ_FAST_MODEL", "openai/gpt-oss-20b")  # Fast model for routing/evaluation
GEMINI_EMBEDDING_MODEL = os.getenv("GEMINI_EMBEDDING_MODEL", "models/gemini-embedding-001")

# --- Server Config ---
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))
DEBUG = os.getenv("DEBUG", "true").lower() == "true"

# --- RAG Config ---
CHUNK_SIZE = 1000
CHUNK_OVERLAP = 200
TOP_K_RESULTS = 5
RELEVANCE_THRESHOLD = 0.7  # Below this → query rewrite or web search

# --- Memory Config ---
MAX_CONVERSATION_HISTORY = 20  # Messages in working memory
SUMMARY_AFTER_MESSAGES = 15   # Summarize after this many (was 3 — too costly)

# --- Agent Config ---
MAX_TOOL_CALLS = 3             # Max tool calls per agent turn
ENABLE_REFLECTION = True       # Enable for quality improvement

# --- Rate Limiting ---
MAX_REQUESTS_PER_MINUTE = 15
RATE_LIMIT_RPM = MAX_REQUESTS_PER_MINUTE  # Alias for middleware


def validate_config():
    """Validate all required config values are present."""
    logger = logging.getLogger(__name__)
    errors = []
    if LLM_PROVIDER == "gemini" and not GEMINI_API_KEY:
        errors.append("GEMINI_API_KEY is not set")
    if LLM_PROVIDER == "groq" and not GROQ_API_KEY:
        errors.append("GROQ_API_KEY is not set")
    if not TAVILY_API_KEY:
        logger.warning("TAVILY_API_KEY is not set — web search will be unavailable")
    if errors:
        raise ValueError(f"Configuration errors:\n" + "\n".join(f"  - {e}" for e in errors))
    logger.info("✅ Configuration validated successfully")
