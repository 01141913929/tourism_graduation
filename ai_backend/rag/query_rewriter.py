"""
✍️ Query Rewriter — إعادة صياغة الاستعلامات بالذكاء الاصطناعي
بيحسن سؤال المستخدم قبل البحث للحصول على نتائج أفضل
"""
from services.gemini_service import get_llm


async def rewrite_query(query: str, context: str = "") -> str:
    """إعادة صياغة الاستعلام ليكون أوضح وأدق للبحث."""
    llm = get_llm(temperature=0.3)

    prompt = f"""أعد صياغة هذا السؤال بشكل أوضح وأدق للبحث في قاعدة معرفة عن السياحة المصرية والآثار.

السؤال الأصلي: {query}
{"سياق المحادثة: " + context if context else ""}

قواعد:
1. استبدل الضمائر بأسماء واضحة
2. أضف كلمات مفتاحية مفيدة
3. حافظ على المعنى الأصلي
4. لو السؤال واضح أصلاً، حسّنه بإضافة سياق مصري

أعد الاستعلام المحسّن فقط بدون شرح."""

    response = await llm.ainvoke(prompt)
    rewritten = response.content.strip()

    # لو الـ LLM رجع حاجة طويلة جداً أو فاضية، نرجع الأصلي
    if not rewritten or len(rewritten) > len(query) * 3:
        return query

    return rewritten


async def decompose_query(query: str) -> list[str]:
    """تقسيم استعلام معقد لأجزاء أبسط."""
    llm = get_llm(temperature=0.1)

    prompt = f"""لو هذا السؤال يحتوي على أكثر من طلب، قسّمه لأجزاء مستقلة.
لو السؤال بسيط، أعده كما هو.

السؤال: {query}

أعد كل جزء في سطر مستقل بدون ترقيم."""

    response = await llm.ainvoke(prompt)
    parts = [p.strip() for p in response.content.strip().split("\n") if p.strip()]

    # لو رجع أكثر من 3 أجزاء أو أقل من واحد، نرجع الأصلي
    if len(parts) > 3 or len(parts) == 0:
        return [query]

    return parts


async def expand_arabic_query(query: str) -> str:
    """توسيع الاستعلام العربي بمرادفات ومصطلحات بديلة."""
    llm = get_llm(temperature=0.2)

    prompt = f"""أضف مرادفات ومصطلحات بديلة لهذا الاستعلام للبحث بشكل أوسع.
أعد استعلام واحد موسّع يجمع المصطلحات.

الاستعلام: {query}

الاستعلام الموسّع:"""

    response = await llm.ainvoke(prompt)
    return response.content.strip() or query
