"""
🔌 WebSocket Handler — معالج اتصالات WebSocket
بيدعم streaming حقيقي مع حالة الكتابة
✅ يدعم ذاكرة ثلاثية الطبقات كاملة
✅ معماري معالج لمشاكل التكرار في الـ DynamoDB والـ astream_events الحقيقي
"""
import asyncio
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from langchain_core.messages import HumanMessage

from graph.workflow import get_workflow
from memory.working_memory import (
    is_memory_loaded, mark_memory_loaded,
    set_long_term_context, commit_session
)
from services.language_service import detect_language
import json

router = APIRouter(tags=["WebSocket"])


# ============================================================
# تحميل الذاكرة طويلة المدى
# ============================================================

async def _load_long_term_memory_ws(session_id: str, user_id: str):
    """تحميل episodic + semantic memory — مرة واحدة لكل جلسة."""
    if is_memory_loaded(session_id) or not user_id:
        return

    try:
        from memory.episodic_memory import get_episode_context
        from memory.semantic_memory import load_preferences, get_preferences_context

        episode_ctx, prefs = await asyncio.gather(
            get_episode_context(user_id),
            load_preferences(user_id),
            return_exceptions=True,
        )

        ep_text = episode_ctx if isinstance(episode_ctx, str) else ""
        prefs_text = ""
        if not isinstance(prefs, Exception):
            prefs_text = get_preferences_context(prefs)

        set_long_term_context(session_id, ep_text, prefs_text)
        mark_memory_loaded(session_id)

        if ep_text or prefs_text:
            print(f"🧠 [WS] ذاكرة طويلة المدى — {user_id[:8]}...")

    except Exception as e:
        print(f"⚠️ [WS] خطأ في تحميل الذاكرة: {e}")
        mark_memory_loaded(session_id)


@router.websocket("/ws/chat/{session_id}")
async def websocket_chat(websocket: WebSocket, session_id: str):
    """🔌 WebSocket endpoint — streaming responses مع ذاكرة ثلاثية."""
    await websocket.accept()
    print(f"🔌 اتصال جديد: {session_id}")

    graph = get_workflow()

    try:
        while True:
            data = await websocket.receive_json()
            message = data.get("message", "")
            user_id = data.get("user_id", "")

            if not message:
                await websocket.send_json({"type": "error", "text": "الرسالة فارغة"})
                continue

            # === تحميل ذاكرة طويلة المدى (مرة واحدة) ===
            await _load_long_term_memory_ws(session_id, user_id)

            # === كشف اللغة ===
            user_language = detect_language(message)

            # حالة الكتابة والتفكير
            await websocket.send_json({"type": "typing", "agent": "supervisor"})

            # إعداد الحالة المبدئية للجراف
            initial_state = {
                "messages": [HumanMessage(content=message)],
                "session_id": session_id,
                "user_id": user_id,
                "current_agent": "",
                "agent_output": "",
                "final_response": "",
                "cards": [],
                "quick_actions": [],
                "sources": [],
                "memory_context": "",
                "conversation_summary": "",
                "sentiment": "neutral",
                "proactive_suggestions": [],
                "user_preferences": {},
                "user_language": user_language,
                "current_viewed_items": [],
                "last_search_query": "",
                "last_tool_results": [],
                "start_time": 0.0,
                "error_count": 0,
                "last_agent_used": "",
            }

            try:
                # 🌟 Real Streaming using `astream_events` 🌟
                # بنستهلك الأحداث فور توليدها من الـ Agent المختار
                final_result = None
                
                async for event in graph.astream_events(initial_state, version="v2"):
                    # استقبال تدفق النصوص من الموديل الحي (LLM)
                    if event["event"] == "on_chat_model_stream":
                        chunk = event["data"]["chunk"].content
                        if isinstance(chunk, str) and chunk:
                            await websocket.send_json({
                                "type": "chunk",
                                "content": chunk
                            })
                            # ننتظر قليلاً جداً لضمان عدم اختناق السوكيت
                            await asyncio.sleep(0.01)

                    # استقبال استدعاءات الأدوات (Tool Calling)
                    elif event["event"] == "on_tool_start":
                        tool_name = event["name"]
                        await websocket.send_json({
                            "type": "tool_status",
                            "status": f"جاري البحث في ({tool_name})..."
                        })
                        
                    # عند نهاية الجراف للوصول للمخرجات النهائية
                    elif event["event"] == "on_chain_end" and event["name"] == "LangGraph":
                        final_result = event["data"].get("output")
                        
                # بعد انتهاء الـ Streaming، نرسل الإشارة النهائية (كروت المنتجات والإجراءات وحالة المشاعر)
                if final_result:
                    agent_used = final_result.get("current_agent", "")
                    
                    await websocket.send_json({
                        "type": "done",
                        "agent": agent_used,
                        "quick_actions": final_result.get("quick_actions", []),
                        "cards": final_result.get("cards", []),
                        "sources": final_result.get("sources", []),
                        "sentiment": final_result.get("sentiment", "neutral"),
                    })
                    
                    # نلتزم بحفظ الذاكرة (Session Commit) في قاعدة البيانات الموزعة
                    commit_session(session_id)
                else:
                    raise ValueError("Graph did not return a final explicit output.")

            except Exception as e:
                print(f"❌ خطأ في معالجة الرسالة للـ WebSocket: {e}")
                await websocket.send_json({
                    "type": "error",
                    "text": "عذراً، حدث خطأ أثناء معالجة طلبك. حاول مرة تانية.",
                })

    except WebSocketDisconnect:
        print(f"🔌 تم قطع الاتصال: {session_id}")
    except Exception as e:
        print(f"❌ خطأ WebSocket غريب: {e}")
