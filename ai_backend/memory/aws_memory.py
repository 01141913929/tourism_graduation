"""
🧠 Memory Proxy — Redirects all calls to the centralized core/aws_memory module.
Ensures consistency in vector dimensions, database pools, and schema initialization.
✅ Consolidated Source of Truth in core/aws_memory.py
"""
import logging
from core.aws_memory import (
    get_aurora_connection,
    release_aurora_connection,
    initialize_db_schema,
    search_knowledge_pgvector,
    get_session_data,
    save_session_data,
    get_user_memory,
    save_user_memory,
    get_user_preferences,
    save_user_preferences,
    get_preferences,
    save_connection,
    remove_connection,
    get_dynamo_table,
    # Old/Internal Aliases for compatibility
    _initialize_db_schema,
    init_aurora_schema,
)

logger = logging.getLogger(__name__)

# Re-export everything for agents/services that import from memory.aws_memory
__all__ = [
    'get_aurora_connection',
    'release_aurora_connection',
    'initialize_db_schema',
    'search_knowledge_pgvector',
    'get_session_data',
    'save_session_data',
    'get_user_memory',
    'save_user_memory',
    'get_user_preferences',
    'save_user_preferences',
    'get_preferences',
    'save_connection',
    'remove_connection',
    'get_dynamo_table',
    '_initialize_db_schema',
    'init_aurora_schema',
]
