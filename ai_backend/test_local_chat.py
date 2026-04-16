import asyncio
import json
from agents.admin_assistant_agent import admin_chat

async def main():
    try:
        response = await admin_chat("ما هي بيانات المنصة المتاحة وهل يوجد أي بازارات نشطة؟", "")
        print(json.dumps(response, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(main())
