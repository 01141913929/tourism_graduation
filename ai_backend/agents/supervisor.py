"""
🎯 Supervisor Agent — المنسق الرئيسي (محسّن)
بيحلل رسالة المستخدم ويوجهها للوكيل المناسب.

التحسينات:
1. Follow-up Detection — لو المستخدم بيتابع نفس الموضوع، يرجع لنفس الوكيل
2. Conversation Context — بيراعي سياق المحادثة مش بس آخر رسالة
3. Expanded Keywords — تغطية أوسع بكتير للكلمات المفتاحية
4. Sentiment-aware Routing — لو المستخدم محبط بيوجهه للتخصيص
5. Multi-signal Scoring — بيجمع إشارات من مصادر متعددة
"""
import re
import asyncio
from graph.state import AgentState
from services.gemini_service import get_llm
from prompts.agent_prompts import SUPERVISOR_PROMPT
from memory.working_memory import get_session, get_conversation_context


# ============================================================
# خريطة الكلمات المفتاحية المتقدمة (موسّعة بشكل كبير)
# ============================================================

AGENT_KEYWORDS: dict[str, list[str]] = {
    "commerce_agent": [
        # منتجات وسلع
        "منتج", "منتجات", "سلعة", "سلع", "هدية", "تذكار", "بردي", "تمثال", "خاتم", "فضة",
        # أفعال شراء وسعر
        "شراء", "اشتري", "عاوز", "محتاج", "سعر", "أسعار", "بكام", "تكلفة",
        "توصية", "اقتراح", "خصم", "تخفيض", "كوبون",
        # سلة وعمليات
        "سلة", "عربة", "أضف", "حط", "شيل", "احذف", "الإجمالي", "الحساب", "فضي",
        "product", "buy", "shop", "price", "cart", "add", "remove", "checkout",
    ],

    "explorer_agent": [
        # تاريخ وحضارة
        "فرعون", "ملك", "توت عنخ", "رمسيس", "هرم", "آثار", "متحف", "معبد",
        "تاريخ", "حضارة", "فراعنة", "مومياء", "هيروغليفي",
        # سياحة وجولات
        "سياحة", "رحلة", "زيارة", "أروح", "أين", "مرشد", "جولة",
        "بازار", "سوق", "خان الخليلي", "قريب", "القاهرة", "الأقصر", "أسوان",
        "history", "pharaoh", "museum", "tour", "visit", "bazaar", "nearby",
        "guide", "pyramid", "temple",
    ],

    "assistant_agent": [
        # بحث واستفسار عام
        "ابحث", "بحث", "معلومات", "احكيلي", "تفاصيل", "قصة",
        "مرحبا", "أهلا", "سلام", "شكرا", "باي", "ازيك", "كيفك",
        "search", "find", "tell me", "hello", "hi", "thanks", "bye",
    ],

    "personalization_agent": [
        "اقتراح شخصي", "حسب ذوقي", "يناسبني", "على ذوقي",
        "مفضلاتي", "أحب", "بحب", "اهتماماتي",
        "recommend", "personalized", "for me",
    ],
}

# كلمات المتابعة — تشير إن المستخدم بيكمل نفس الموضوع
FOLLOWUP_INDICATORS = [
    "كمان", "وكمان", "تاني", "برضه", "برضو",
    "أيوه", "ايوا", "اه", "نعم", "صح",
    "وايه كمان", "وإيه تاني", "غير كده",
    "المزيد", "زيادة", "أكتر", "أكثر",
    "الأول", "التاني", "الثالث", "الرابع",
    "ده", "دي", "دول", "هو ده", "هي دي",
    "أصغر", "أكبر", "أرخص", "أغلى", "أحلى",
    "more", "also", "and", "another", "else",
    "yes", "yeah", "ok", "okay", "sure",
]

# أنماط الإحباط — تشير إن المستخدم مش مبسوط
FRUSTRATION_PATTERNS = [
    "مش فاهم", "مبفهمش", "غلط", "خطأ",
    "مش ده", "مش كده", "لا مش",
    "تاني", "مرة تانية", "كرر",
    "غيّر", "حاجة تانية",
    "بطيء", "طويل", "كتير",
    "مش عاجبني", "مش حلو",
    "ليه مش", "ازاي مش",
    "wrong", "no", "not this", "change",
]

# ضمائر الإشارة (تحتاج سياق)
REFERENCE_WORDS = [
    "ده", "دي", "دول", "هو", "هي", "هم",
    "اللي قولتلك", "اللي قلته", "اللي فات",
    "نفسه", "نفسها", "زيه", "زيها",
    "this", "that", "these", "those", "it", "them",
]


# ============================================================
# تحليل متعدد الإشارات (Multi-signal Analysis)
# ============================================================

def _keyword_routing(message: str) -> str | None:
    """توجيه بالكلمات المفتاحية — أسرع (0ms) ولكن أقل دقة."""
    message_lower = message.lower().strip()

    # حساب نقاط لكل وكيل
    scores: dict[str, int] = {}
    for agent, keywords in AGENT_KEYWORDS.items():
        score = 0
        for kw in keywords:
            if kw in message_lower:
                # كلمات أطول تحصل على نقاط أعلى (أكثر تحديداً)
                score += len(kw.split())
        if score > 0:
            scores[agent] = score

    if not scores:
        return None

    # أعلى وكيل نقاطاً
    best_agent = max(scores, key=scores.get)
    best_score = scores[best_agent]

    # لازم يكون فيه فرق واضح أو نقاط عالية
    if best_score >= 2:
        return best_agent

    # لو النقاط متقاربة → خلي الـ LLM يقرر
    sorted_scores = sorted(scores.values(), reverse=True)
    if len(sorted_scores) >= 2 and sorted_scores[0] - sorted_scores[1] <= 1:
        return None  # متقاربة → LLM fallback

    return best_agent if best_score >= 1 else None


def _detect_followup(message: str) -> bool:
    """كشف إذا الرسالة متابعة لسؤال سابق."""
    message_lower = message.lower().strip()

    # رسائل قصيرة جداً غالباً متابعة
    if len(message_lower) < 15:
        return True

    # كلمات متابعة صريحة
    for indicator in FOLLOWUP_INDICATORS:
        if indicator in message_lower:
            return True

    # ضمائر إشارة بدون سياق واضح
    for ref in REFERENCE_WORDS:
        if ref in message_lower:
            # تأكد إن مفيش كلمة مفتاحية واضحة
            has_keyword = any(
                kw in message_lower
                for keywords in AGENT_KEYWORDS.values()
                for kw in keywords
                if len(kw) > 3  # كلمات مفتاحية طويلة فقط
            )
            if not has_keyword:
                return True

    return False


def _detect_frustration(message: str) -> bool:
    """كشف إحباط المستخدم."""
    message_lower = message.lower().strip()
    count = sum(1 for p in FRUSTRATION_PATTERNS if p in message_lower)
    return count >= 1


def _get_conversation_topic(session_id: str) -> str:
    """استخراج الموضوع السائد من سياق المحادثة."""
    try:
        session = get_session(session_id)
        last_agent = session.get("last_agent", "")
        topics = session.get("topics", [])

        if last_agent:
            return last_agent

        # تحليل المواضيع المذكورة
        if topics:
            return topics[-1] if topics else ""
    except Exception:
        pass

    return ""


# ============================================================
# الدالة الرئيسية — التوجيه الذكي
# ============================================================

async def run_supervisor(state: AgentState) -> dict:
    """
    🎯 توجيه ذكي متعدد الإشارات:
    1. Follow-up Detection — لو المستخدم بيتابع → نفس الوكيل
    2. Frustration Detection → personalization_agent
    3. Keyword Routing (سريع) — فحص الكلمات المفتاحية
    4. LLM Fallback (ذكي) — لو الكلمات المفتاحية مش كافية
    """
    messages = state.get("messages", [])
    session_id = state.get("session_id", "")

    if not messages:
        return {"current_agent": "assistant_agent"}

    last_message = messages[-1].content if messages else ""

    # === الخطوة 0: استرجاع سياق الجلسة ===
    session = get_session(session_id)
    last_agent = session.get("last_agent", "")
    message_count = session.get("message_count", 0)

    # === الخطوة 1: كشف المتابعة (Follow-up Detection) ===
    if last_agent and last_agent != "assistant_agent" and message_count > 1:
        is_followup = _detect_followup(last_message)

        if is_followup:
            # تأكد إن مفيش intent واضح مختلف
            keyword_agent = _keyword_routing(last_message)

            if keyword_agent is None or keyword_agent == last_agent:
                # متابعة مؤكدة → نفس الوكيل
                print(f"🔁 متابعة → {last_agent} (follow-up detected)")
                return {"current_agent": last_agent, "last_agent_used": last_agent}

            # لو فيه keyword مختلف واضح → تغيير الوكيل
            if keyword_agent and keyword_agent != last_agent:
                print(f"↪️ تغيير من {last_agent} → {keyword_agent} (new intent)")
                return {"current_agent": keyword_agent, "last_agent_used": keyword_agent}

    # === الخطوة 2: كشف الإحباط ===
    if _detect_frustration(last_message):
        # لو محبط + موجود في وكيل → يفضل في نفس الوكيل مع ملاحظة
        if last_agent and last_agent != "assistant_agent":
            print(f"😤 إحباط مكتشف — يبقى في {last_agent} مع تحسين الرد")
            return {"current_agent": last_agent, "sentiment": "negative", "last_agent_used": last_agent}
        # لو مفيش وكيل سابق → personalization
        print("😤 إحباط مكتشف → personalization_agent")
        return {"current_agent": "personalization_agent", "sentiment": "negative", "last_agent_used": "personalization_agent"}

    # === الخطوة 3: توجيه بالكلمات المفتاحية (سريع) ===
    keyword_agent = _keyword_routing(last_message)
    if keyword_agent:
        print(f"⚡ توجيه سريع → {keyword_agent}")
        return {"current_agent": keyword_agent, "last_agent_used": keyword_agent}

    # === الخطوة 4: توجيه بالـ LLM (ذكي — آخر خيار) ===
    try:
        llm = get_llm(temperature=0.0)

        # بناء سياق إضافي للـ LLM
        context_info = ""
        if last_agent:
            context_info += f"\nالوكيل السابق: {last_agent}"
        if session.get("topics"):
            context_info += f"\nالمواضيع السابقة: {', '.join(session['topics'][-3:])}"

        conversation_ctx = get_conversation_context(session_id)
        if conversation_ctx:
            # آخر 3 رسائل كسياق
            ctx_lines = conversation_ctx.split('\n')[-3:]
            context_info += f"\nسياق المحادثة الأخيرة:\n" + '\n'.join(ctx_lines)

        prompt = (
            f"{SUPERVISOR_PROMPT}\n\n"
            f"الرسالة: {last_message}"
            f"{context_info}"
        )

        response = await asyncio.wait_for(
            llm.ainvoke(prompt),
            timeout=8.0,
        )
        text = response.content.strip()

        # استخراج اسم الوكيل
        agent = _extract_agent_name(text)
        if agent:
            print(f"🤖 توجيه LLM → {agent}")
            return {"current_agent": agent, "last_agent_used": agent}

    except asyncio.TimeoutError:
        print("⏰ Supervisor LLM timeout — fallback")
    except Exception as e:
        print(f"⚠️ Supervisor error: {e}")

    # === Fallback النهائي ===
    # لو فيه وكيل سابق وبقاله أقل من 5 رسائل → يرجعله
    if last_agent and last_agent != "assistant_agent" and message_count < 5:
        print(f"🔄 Fallback → {last_agent} (recent agent)")
        return {"current_agent": last_agent, "last_agent_used": last_agent}

    print("💬 Fallback → assistant_agent")
    return {"current_agent": "assistant_agent", "last_agent_used": "assistant_agent"}


def _extract_agent_name(text: str) -> str | None:
    """استخراج اسم الوكيل من رد الـ LLM."""
    valid_agents = [
        "commerce_agent", "explorer_agent",
        "assistant_agent", "personalization_agent",
    ]

    # محاولة 1: JSON
    try:
        import json
        # البحث عن JSON في النص
        for pattern in [r'\{[^}]+\}', r'"agent"\s*:\s*"([^"]+)"']:
            import re
            match = re.search(pattern, text)
            if match:
                try:
                    data = json.loads(match.group(0))
                    agent = data.get("agent", "")
                    if agent in valid_agents:
                        return agent
                except (json.JSONDecodeError, AttributeError):
                    # محاولة regex مباشرة
                    agent_match = re.search(r'"agent"\s*:\s*"([^"]+)"', text)
                    if agent_match and agent_match.group(1) in valid_agents:
                        return agent_match.group(1)
    except Exception:
        pass

    # محاولة 2: البحث عن اسم وكيل في النص
    text_lower = text.lower()
    for agent in valid_agents:
        if agent in text_lower:
            return agent

    return None
