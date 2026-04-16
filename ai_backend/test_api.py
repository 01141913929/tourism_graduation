import urllib.request, json
try:
    req = urllib.request.Request('https://al5bhgldsf.execute-api.us-east-1.amazonaws.com/prod/api/admin/ai/chat', data=json.dumps({'message': 'ما هي المنتجات الأكثر مبيعا؟'}).encode('utf-8'), headers={'Content-Type': 'application/json'})
    res = urllib.request.urlopen(req)
    with open('res.json', 'w', encoding='utf-8') as f:
        f.write(res.read().decode('utf-8'))
except Exception as e:
    with open('res.json', 'w', encoding='utf-8') as f:
        f.write(str(e))
        if hasattr(e, 'read'):
            f.write(e.read().decode('utf-8'))
