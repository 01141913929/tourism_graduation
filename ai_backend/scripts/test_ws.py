import asyncio
import websockets
import json

async def test_websocket():
    uri = "wss://zm6it1qy02.execute-api.us-east-1.amazonaws.com/deployment-test"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected successfully!")
            
            # Send a user request that triggers pgvector search (RAG)
            message = {
                "action": "sendMessage",
                "message": "can you tell me about the pyrimids of giza?"
            }
            print(f"Sending message: {json.dumps(message)}")
            await websocket.send(json.dumps(message))
            
            print("Waiting for response...")
            while True:
                response = await websocket.recv()
                data = json.loads(response)
                print("\n--- Response Received ---")
                print(json.dumps(data, indent=2))
                
                # Check if it's the final output
                if data.get("type") == "message" or data.get("sender") == "ai":
                    print("\nSuccess! AI responded.")
                    break
                
    except Exception as e:
        print(f"Connection failed or error occurred: {e}")

if __name__ == "__main__":
    asyncio.run(test_websocket())
