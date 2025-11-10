#!/bin/bash
# 图片API费率验证脚本
# 用途：验证图片API的费率设置是否为10.4积分/1k tokens

USER_ID="verify-img-$(date +%s)"
echo "================================"
echo "   图片API费率验证测试"
echo "================================"
echo "用户ID: $USER_ID"
echo

# 1. 检查初始余额
BALANCE1=$(curl -s "http://localhost:3000/balance?appAccountToken=$USER_ID" | python3 -c "import sys, json; print(json.load(sys.stdin)['balance'])" 2>/dev/null)

if [ -z "$BALANCE1" ]; then
    echo "✗ 无法连接到服务器"
    exit 1
fi

echo "初始余额: $BALANCE1 积分"

# 2. 调用图片API（使用一个简单的测试图片URL）
echo "调用图片API..."
curl -s http://localhost:3000/api/image-proxy \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $USER_ID" \
  -d '{
    "model":"doubao-vision-pro-32k",
    "messages":[{
      "role":"user",
      "content":[
        {"type":"text","text":"描述这张图片"},
        {"type":"image_url","image_url":{"url":"https://example.com/test.jpg"}}
      ]
    }],
    "stream":false
  }' \
  --max-time 30 > /tmp/verify-image-response.json 2>/dev/null

# 3. 检查响应
if [ ! -s /tmp/verify-image-response.json ]; then
    echo "✗ API请求失败"
    exit 1
fi

# 4. 检查是否有错误
if grep -q '"error"' /tmp/verify-image-response.json; then
    echo "✗ API返回错误:"
    cat /tmp/verify-image-response.json | python3 -m json.tool 2>/dev/null | head -10
    exit 1
fi

# 5. 获取最终余额
sleep 1
BALANCE2=$(curl -s "http://localhost:3000/balance?appAccountToken=$USER_ID" | python3 -c "import sys, json; print(json.load(sys.stdin)['balance'])" 2>/dev/null)
echo "最终余额: $BALANCE2 积分"

COST=$((BALANCE1 - BALANCE2))
echo "扣除积分: $COST 积分"
echo

# 6. 验证费率
python3 - "$COST" << 'EOF'
import json
import math
import sys

try:
    with open('/tmp/verify-image-response.json', 'r') as f:
        data = json.load(f)
    
    if 'usage' not in data:
        print("✗ 响应中没有usage信息")
        sys.exit(1)
    
    total_tokens = data['usage']['total_tokens']
    expected_rate = 10.4
    cost = int(sys.argv[1])
    
    expected_cost = math.ceil((total_tokens / 1000) * expected_rate)
    actual_rate = (cost * 1000) / total_tokens if total_tokens > 0 else 0
    
    print(f"Token使用: {total_tokens}")
    print(f"预期扣除: {expected_cost} 积分 (按 {expected_rate} 积分/1k tokens)")
    print(f"实际扣除: {cost} 积分")
    print(f"实际费率: {actual_rate:.2f} 积分/1k tokens")
    print()
    
    if cost == expected_cost:
        print("✅ 图片API费率验证通过！")
        print(f"   费率已正确设置为 {expected_rate} 积分/1k tokens")
        sys.exit(0)
    else:
        print(f"⚠ 扣费不一致，差异: {abs(cost - expected_cost)} 积分")
        sys.exit(1)
        
except Exception as e:
    print(f"✗ 验证失败: {e}")
    sys.exit(1)
EOF

EXIT_CODE=$?
echo
echo "================================"
exit $EXIT_CODE

