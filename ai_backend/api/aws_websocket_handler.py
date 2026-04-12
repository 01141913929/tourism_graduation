"""
🚀 AWS Lambda WebSocket Handler
المدخل الرئيسي لـ AWS API Gateway WebSockets
"""
import json
import asyncio
import boto3
import os
from langchain_core.messages import HumanMessage
from graph.workflow import get_workflow
from memory.aws_memory import save_connection, remove_connection
from memory.working_memory import commit_session

# ============================================================
# AWS Global Scope (Cold Start Optimization)
# ============================================================
# بناء الجرّاف مرة واحدة وتهيئة المتغيرات على مستوى الحاوية.
# سيوفر هذا أكثر من ثانية إلى ثانيتين مع كل طلب في Lambda.
apigw_client = None
global_graph = get_workflow()

def get_apigw_client(event):
    global apigw_client
    if not apigw_client:
        domain = event.get('requestContext', {}).get('domainName')
        stage = event.get('requestContext', {}).get('stage')
        endpoint_url = f"https://{domain}/{stage}"
        apigw_client = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint_url)
    return apigw_client

def send_to_connection(connection_id, data, event):
    """إرسال رسالة باك عبر الـ WebSocket للمستخدم"""
    client = get_apigw_client(event)
    try:
        client.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(data, ensure_ascii=False).encode('utf-8')
        )
    except Exception as e:
        print(f"⚠️ Failed to send message to {connection_id}: {e}")

async def process_chat_message(connection_id: str, payload: dict, event: dict):
    """ربط الجراف وإرسال النتائج بشكل مباشر (أو Streaming)"""
    message = payload.get("message", "")
    session_id = payload.get("session_id", "default_session")
    user_id = payload.get("user_id", "")
    
    # 1. تحديث الاتصال في DynamoDB
    save_connection(connection_id, session_id, user_id)
    
    try:
        # 2. إشعار المستخدم بأن النظام "يفكر"
        send_to_connection(connection_id, {"type": "thinking"}, event)
        
        # 3. تنفيذ State Graph
        result = await asyncio.wait_for(
            global_graph.ainvoke({
                "messages": [HumanMessage(content=message)],
                "session_id": session_id,
                "user_id": user_id,
                "current_agent": "",
                "agent_output": "",
                "final_response": "",
                "cards": [],
                "quick_actions": [],
            }),
            timeout=40.0
        )
        
        # 5. إعداد وإرسال الرد النهائي
        response_data = {
            "type": "message",
            "text": result.get("final_response", "عذراً، حدث خطأ."),
            "agent": result.get("current_agent", ""),
            "quick_actions": result.get("quick_actions", []),
            "cards": result.get("cards", []),
        }
        
        send_to_connection(connection_id, response_data, event)
        
        # 5. حفظ הذاكرة في DynamoDB بشكل قطعي قبل نهاية الـ Lambda
        commit_session(session_id)
        
    except asyncio.TimeoutError:
        send_to_connection(connection_id, {"type": "error", "text": "استغرق التفكير وقتاً طويلاً."}, event)
    except Exception as e:
        print(f"❌ Error in graph execution: {e}")
        send_to_connection(connection_id, {"type": "error", "text": "حدث خطأ غير متوقع بالخادم."}, event)

def lambda_handler(event, context):
    """المعالج الرئيسي من AWS Lambda"""
    print(f"📥 Received event: {json.dumps(event)}")
    
    route_key = event.get('requestContext', {}).get('routeKey')
    connection_id = event.get('requestContext', {}).get('connectionId')
    
    if route_key == '$connect':
        print(f"🔗 New connection: {connection_id}")
        return {'statusCode': 200}
        
    elif route_key == '$disconnect':
        print(f"❌ Disconnected: {connection_id}")
        remove_connection(connection_id)
        return {'statusCode': 200}
        
    elif route_key == '$default':
        try:
            body = json.loads(event.get('body', '{}'))
            
            # الجرّاف LangGraph معرّف כـ Async فلازم نشغله داخل Event Loop
            asyncio.run(process_chat_message(connection_id, body, event))
            
            return {'statusCode': 200}
        except Exception as e:
            print(f"⚠️ Error processing message: {e}")
            return {'statusCode': 500}
            
    return {'statusCode': 200}
