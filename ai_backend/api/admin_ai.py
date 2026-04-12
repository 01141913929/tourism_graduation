"""
🔴 Admin AI API Routes — 7 endpoints للوحة تحكم الأدمن
"""
import json
import asyncio
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from models.ai_models import (
    AdminChatRequest,
    BusinessReportRequest, BusinessReportResponse,
    GenerateMessageRequest, GenerateMessageResponse,
)
from agents.admin_assistant_agent import (
    admin_chat, generate_business_report,
    generate_admin_message, suggest_promotions,
    get_platform_insights,
)
from agents.moderation_agent import (
    moderate_product, analyze_application,
)


router = APIRouter(prefix="/api/admin/ai", tags=["Admin AI"])


# ============================================================
# 1. Admin AI Chatbot
# ============================================================

@router.post("/chat")
async def api_admin_chat(request: AdminChatRequest):
    """🤖 شات بوت الأدمن — يجاوب على أسئلة الإدارة بلغة طبيعية."""
    try:
        result = await admin_chat(
            question=request.message,
            context=request.context or "",
        )
        return result

    except Exception as e:
        print(f"⚠️ Admin chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chat/stream")
async def api_admin_chat_stream(request: AdminChatRequest):
    """📡 شات بوت الأدمن بالـ SSE Streaming الحقيقي باستخدام LangGraph."""

    async def generate_events():
        try:
            # Status: Thinking
            yield f"data: {json.dumps({'type': 'status', 'status': 'thinking'}, ensure_ascii=False)}\n\n"

            # Execute ReAct agent directly as event stream
            from agents.admin_assistant_agent import ADMIN_TOOLS, ADMIN_SYSTEM_MSG
            from langgraph.prebuilt import create_react_agent
            from langchain_core.messages import HumanMessage
            from services.gemini_service import get_llm
            
            llm = get_llm(temperature=0.3)
            agent = create_react_agent(llm, ADMIN_TOOLS, state_modifier=ADMIN_SYSTEM_MSG)
            prompt_str = f"سياق إضافي: {request.context}\n\nسؤال المدير: {request.message}"
            
            # Start generating
            yield f"data: {json.dumps({'type': 'status', 'status': 'generating'}, ensure_ascii=False)}\n\n"

            final_text = ""
            # Stream events natively from LangGraph
            async for event in agent.astream_events({"messages": [HumanMessage(content=prompt_str)]}, version="v2"):
                if event["event"] == "on_chat_model_stream":
                    chunk_text = event["data"]["chunk"].content
                    if isinstance(chunk_text, str) and chunk_text:
                        final_text += chunk_text
                        yield f"data: {json.dumps({'type': 'chunk', 'content': chunk_text}, ensure_ascii=False)}\n\n"
                        await asyncio.sleep(0.01)
                
                elif event["event"] == "on_tool_start":
                    tool_name = event["name"]
                    yield f"data: {json.dumps({'type': 'status', 'status': f'جاري جلب إحصائيات: {tool_name}...'}, ensure_ascii=False)}\n\n"
                    
            # After full generation, we must extract JSON if it exists embedded in final_text, or just serve final_text.
            # Usually ReAct outputs plain markdown due to custom prompt, but we requested JSON.
            # Let's cleanly parse it
            from utils.json_parser import parse_json_response
            parsed = parse_json_response(final_text)
            
            if parsed and isinstance(parsed, dict):
                quick_actions = parsed.get("quick_actions", [])
            else:
                quick_actions = ["تحديث البيانات", "أفضل البازارات أداءً"]
                
            yield f"data: {json.dumps({'type': 'done', 'quick_actions': quick_actions, 'charts_data': None, 'data_tables': None}, ensure_ascii=False)}\n\n"

        except Exception as e:
            print(f"⚠️ Stream Admin Chat Error: {e}")
            yield f"data: {json.dumps({'type': 'error', 'content': 'حدثت مشكلة مفاجئة! برجاء المحاولة لاحقاً.'}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        generate_events(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ============================================================
# 2. Moderate Product
# ============================================================

@router.get("/moderate-product/{product_id}")
async def api_moderate_product(product_id: str):
    """🛡️ فحص منتج بالذكاء الاصطناعي — يعطي score وتوصيات."""
    try:
        result = await moderate_product(product_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 3. Analyze Bazaar Application
# ============================================================

@router.get("/analyze-application/{application_id}")
async def api_analyze_application(application_id: str):
    """📋 تحليل طلب بازار جديد بالذكاء الاصطناعي."""
    try:
        result = await analyze_application(application_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 4. Business Report
# ============================================================

@router.post("/business-report")
async def api_business_report(request: BusinessReportRequest):
    """📊 تقرير BI ذكي شامل."""
    try:
        result = await generate_business_report(
            period=request.period,
            focus=request.focus,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 5. Platform Insights
# ============================================================

@router.get("/platform-insights")
async def api_platform_insights():
    """🔍 استخراج insights فورية عن المنصة."""
    try:
        result = await get_platform_insights()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 6. Generate Admin Message
# ============================================================

@router.post("/generate-message")
async def api_generate_message(request: GenerateMessageRequest):
    """✉️ توليد رسالة إدارية احترافية."""
    try:
        result = await generate_admin_message(
            message_type=request.message_type,
            bazaar_name=request.bazaar_name,
            context=request.context or "",
            custom_notes=request.custom_notes or "",
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 7. Promotion Suggestions
# ============================================================

@router.get("/promotion-suggestions")
async def api_promotion_suggestions():
    """🏷️ اقتراحات عروض وتخفيضات ذكية."""
    try:
        result = await suggest_promotions()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
