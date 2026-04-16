"""Batch fix: Replace all print() with logging across the codebase."""
import re
import os

files_to_fix = [
    'services/gemini_service.py',
    'main.py',
    'graph/workflow.py',
    'memory/summarizer.py',
    'agents/tool_executor.py',
    'agents/commerce_agent.py',
    'agents/admin_assistant_agent.py',
    'api/websocket.py',
    'api/recommendations.py',
    'api/admin_ai.py',
    'rag/knowledge_loader.py',
    'rag/bm25_store.py',
]

for fpath in files_to_fix:
    if not os.path.exists(fpath):
        print(f"SKIP (not found): {fpath}")
        continue
        
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Add logging import if missing
    if 'import logging' not in content:
        if 'import asyncio' in content:
            content = content.replace('import asyncio', 'import asyncio\nimport logging', 1)
        elif 'import json' in content:
            content = content.replace('import json', 'import json\nimport logging', 1)
        else:
            content = 'import logging\n' + content
    
    # Add logger if missing
    if 'logger = logging.getLogger' not in content:
        lines = content.split('\n')
        last_import_idx = 0
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped.startswith('import ') or stripped.startswith('from '):
                last_import_idx = i
        lines.insert(last_import_idx + 1, '\nlogger = logging.getLogger(__name__)')
        content = '\n'.join(lines)
    
    # Replace print() with appropriate log levels
    # Error patterns
    content = content.replace('print(f"❌ ', 'logger.error(f"')
    content = content.replace('print(f"⚠️ ', 'logger.warning(f"')
    content = content.replace('print(f"⏰ ', 'logger.warning(f"')
    content = content.replace('print(f"🚫 ', 'logger.warning(f"')
    content = content.replace('print("🆘 ', 'logger.warning("')
    
    # Info patterns
    content = content.replace('print(f"✅ ', 'logger.info(f"')
    content = content.replace('print("✅ ', 'logger.info("')
    content = content.replace('print(f"🔌 ', 'logger.info(f"')
    content = content.replace('print(f"🧠 ', 'logger.info(f"')
    content = content.replace('print("🧠 ', 'logger.info("')
    content = content.replace('print("🔍 ', 'logger.info("')
    content = content.replace('print("⏭️ ', 'logger.info("')
    content = content.replace('print("👋 ', 'logger.info("')
    content = content.replace('print("🚀 ', 'logger.info("')
    content = content.replace('print(f"🌐 ', 'logger.info(f"')
    content = content.replace('print(f"📖 ', 'logger.info(f"')
    content = content.replace('print(f"📚 ', 'logger.info(f"')
    content = content.replace('print(f"🔤 ', 'logger.info(f"')
    
    # Separator lines
    content = content.replace('print("=" * 50)', 'logger.info("=" * 50)')
    
    # Remaining generic prints (catch-all)
    # These use regex to match any remaining print( patterns
    content = re.sub(r'(\s+)print\(f"', r'\1logger.info(f"', content)
    content = re.sub(r'(\s+)print\("', r'\1logger.info("', content)
    
    if content != original:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"FIXED: {fpath}")
    else:
        print(f"NO CHANGES: {fpath}")

print("\nDone! All print() replaced with logging.")
