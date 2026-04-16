"""
🔴 Admin AI Service — Main Application
FastAPI application containing the 7 admin endpoints.
Directly invokes LangGraph ReAct and generators.
"""
import json
import asyncio
import logging
from fastapi import FastAPI, APIRouter, HTTPException, Request
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware

from core.config import validate_config
from services.admin.models.schemas import (
    AdminChatRequest, BusinessReportRequest,
    GenerateMessageRequest, AdminChatResponse,
    ModerationResponse, ApplicationAnalysisResponse,
    BusinessReportResponse, PlatformInsightsResponse,
    GenerateMessageResponse, PromotionSuggestionsResponse
)
from services.admin.agents.admin_assistant import (
    admin_chat, generate_business_report,
    get_platform_insights, generate_admin_message, suggest_promotions
)
from services.admin.agents.moderation import (
    moderate_product, analyze_application
)

# Setup logging
logger = logging.getLogger("Admin_AI_API")

# Initialize and validate
validate_config(service_name="AdminService")
app = FastAPI(title="Egyptian Tourism Admin AI", version="1.0.0", root_path="/prod")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

router = APIRouter(prefix="/api/admin/ai", tags=["Admin AI"])


# ============================================================
# 1. Admin AI Chatbot (REST & Stream)
# ============================================================

@router.post("/chat", response_model=AdminChatResponse)
async def api_admin_chat(request: AdminChatRequest):
    """🤖 Admin Chatbot — Answers questions in natural language."""
    try:
        result = await admin_chat(
            question=request.message,
            context=request.context or "",
        )
        return result
    except Exception as e:
        logger.error(f"Admin chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/chat/stream")
async def api_admin_chat_stream(request: AdminChatRequest):
    """📡 Admin Chatbot with SSE Streaming (Direct from LangGraph)."""
    async def generate_events():
        try:
            yield f"data: {json.dumps({'type': 'status', 'status': 'thinking'}, ensure_ascii=False)}\n\n"

            # Execute ReAct agent directly as event stream
            from services.admin.agents.admin_assistant import ADMIN_TOOLS, ADMIN_SYSTEM_MSG
            from langgraph.prebuilt import create_react_agent
            from langchain_core.messages import HumanMessage
            from core.llm_service import get_llm
            
            llm = get_llm(temperature=0.3, app_id="admin")
            agent = create_react_agent(llm, ADMIN_TOOLS, state_modifier=ADMIN_SYSTEM_MSG)
            prompt_str = f"سياق إضافي: {request.context}\n\nسؤال المدير: {request.message}"
            
            yield f"data: {json.dumps({'type': 'status', 'status': 'generating'}, ensure_ascii=False)}\n\n"

            final_text = ""
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
                    
            from core.json_utils import parse_json_response
            parsed = parse_json_response(final_text)
            quick_actions = parsed.get("quick_actions", ["تحديث البيانات"]) if parsed else ["تحديث البيانات"]
                
            yield f"data: {json.dumps({'type': 'done', 'quick_actions': quick_actions, 'charts_data': None, 'data_tables': None}, ensure_ascii=False)}\n\n"

        except Exception as e:
            logger.error(f"Stream Admin Chat Error: {e}")
            yield f"data: {json.dumps({'type': 'error', 'content': 'حدثت مشكلة مفاجئة! برجاء المحاولة لاحقاً.'}, ensure_ascii=False)}\n\n"

    return StreamingResponse(
        generate_events(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "Connection": "keep-alive"}
    )


# ============================================================
# 2. Moderate Product
# ============================================================

@router.get("/moderate-product/{product_id}", response_model=ModerationResponse)
async def api_moderate_product(product_id: str):
    """🛡️ AI Product Moderation — Returns score and recommendations."""
    try:
        return await moderate_product(product_id)
    except Exception as e:
        logger.error(f"Moderation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 3. Analyze Bazaar Application
# ============================================================

@router.get("/analyze-application/{application_id}", response_model=ApplicationAnalysisResponse)
async def api_analyze_application(application_id: str):
    """📋 Analyze new bazaar joining application."""
    try:
        return await analyze_application(application_id)
    except Exception as e:
        logger.error(f"Application analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 4. Business Report
# ============================================================

@router.post("/business-report", response_model=BusinessReportResponse)
async def api_business_report(request: BusinessReportRequest):
    """📊 Generate comprehensive BI report."""
    try:
        return await generate_business_report(period=request.period.value, focus=request.focus.value if request.focus else None)
    except Exception as e:
        logger.error(f"Business report error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 5. Platform Insights
# ============================================================

@router.get("/platform-insights", response_model=PlatformInsightsResponse)
async def api_platform_insights():
    """🔍 Quick real-time platform system health & insights."""
    try:
        return await get_platform_insights()
    except Exception as e:
        logger.error(f"Platform insights error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 6. Generate Admin Message
# ============================================================

@router.post("/generate-message", response_model=GenerateMessageResponse)
async def api_generate_message(request: GenerateMessageRequest):
    """✉️ Generate professional admin/owner communication message."""
    try:
        return await generate_admin_message(
            message_type=request.message_type.value,
            bazaar_name=request.bazaar_name,
            context=request.context or "",
            custom_notes=request.custom_notes or "",
        )
    except Exception as e:
        logger.error(f"Generate message error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# 7. Promotion Suggestions
# ============================================================

@router.get("/promotion-suggestions", response_model=PromotionSuggestionsResponse)
async def api_promotion_suggestions():
    """🏷️ AI smart promotion and discounting suggestions."""
    try:
        return await suggest_promotions()
    except Exception as e:
        logger.error(f"Promotion suggestions error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Include the router
app.include_router(router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "admin-ai"}
