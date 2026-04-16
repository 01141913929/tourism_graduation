"""
Langfuse Tracing Configuration
Provides dynamic callback handler for deep tracing of Langchain & Langgraph executions.
"""
from langfuse.langchain import CallbackHandler
from config import LANGFUSE_SECRET_KEY, LANGFUSE_PUBLIC_KEY, LANGFUSE_BASE_URL

def get_langfuse_handler():
    """عزل إعدادات مراقبة Langfuse لتسجيل تفاصيل التنفيذ بدقة"""
    if not LANGFUSE_SECRET_KEY or not LANGFUSE_PUBLIC_KEY:
        return None
    
    import os
    os.environ["LANGFUSE_SECRET_KEY"] = LANGFUSE_SECRET_KEY
    os.environ["LANGFUSE_PUBLIC_KEY"] = LANGFUSE_PUBLIC_KEY
    os.environ["LANGFUSE_HOST"] = LANGFUSE_BASE_URL
    
    return CallbackHandler()
