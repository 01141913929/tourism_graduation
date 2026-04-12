"""
🔧 Shared JSON Parser — استخراج JSON من ردود الـ LLM
يُستخدم من: owner_assistant_agent, admin_assistant_agent, moderation_agent
"""
import json
import re


def parse_json_response(text: str) -> dict:
    """استخراج JSON من رد LLM — يتعامل مع code blocks ونص مختلط.

    يدعم:
    - JSON نظيف مباشر
    - JSON داخل ```json ... ``` code blocks
    - JSON مدفون داخل نص عادي
    - حالات الفشل (يرجع dict فاضي)
    """
    if not text or not text.strip():
        return {}

    text = text.strip()

    # === المحاولة 1: JSON مباشر ===
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # === المحاولة 2: استخراج من code block ===
    code_block_patterns = [
        r'```json\s*([\s\S]*?)\s*```',
        r'```\s*([\s\S]*?)\s*```',
    ]
    for pattern in code_block_patterns:
        match = re.search(pattern, text)
        if match:
            try:
                return json.loads(match.group(1).strip())
            except json.JSONDecodeError:
                continue

    # === المحاولة 3: أول { ... } أو [ ... ] في النص ===
    # نبحث عن أول كائن JSON كامل
    brace_match = _extract_balanced_json(text, '{', '}')
    if brace_match:
        try:
            return json.loads(brace_match)
        except json.JSONDecodeError:
            pass

    bracket_match = _extract_balanced_json(text, '[', ']')
    if bracket_match:
        try:
            return {"items": json.loads(bracket_match)}
        except json.JSONDecodeError:
            pass

    # === المحاولة 4: محاولة إصلاح JSON شائع الأخطاء ===
    cleaned = _fix_common_json_errors(text)
    if cleaned:
        try:
            return json.loads(cleaned)
        except json.JSONDecodeError:
            pass

    return {}


def _extract_balanced_json(text: str, open_char: str, close_char: str) -> str | None:
    """استخراج أول JSON متوازن الأقواس من النص."""
    start = text.find(open_char)
    if start == -1:
        return None

    depth = 0
    in_string = False
    escape_next = False

    for i in range(start, len(text)):
        char = text[i]

        if escape_next:
            escape_next = False
            continue

        if char == '\\':
            escape_next = True
            continue

        if char == '"' and not escape_next:
            in_string = not in_string
            continue

        if in_string:
            continue

        if char == open_char:
            depth += 1
        elif char == close_char:
            depth -= 1
            if depth == 0:
                return text[start:i + 1]

    return None


def _fix_common_json_errors(text: str) -> str | None:
    """محاولة إصلاح أخطاء JSON الشائعة في ردود LLM."""
    # إزالة trailing commas
    fixed = re.sub(r',\s*([\}\]])', r'\1', text)

    # إزالة نص قبل أول { أو [
    first_brace = fixed.find('{')
    first_bracket = fixed.find('[')

    if first_brace == -1 and first_bracket == -1:
        return None

    if first_brace >= 0 and (first_bracket == -1 or first_brace < first_bracket):
        fixed = fixed[first_brace:]
    elif first_bracket >= 0:
        fixed = fixed[first_bracket:]

    # إزالة نص بعد آخر } أو ]
    last_brace = fixed.rfind('}')
    last_bracket = fixed.rfind(']')
    last_pos = max(last_brace, last_bracket)

    if last_pos >= 0:
        fixed = fixed[:last_pos + 1]

    return fixed if fixed.strip() else None
