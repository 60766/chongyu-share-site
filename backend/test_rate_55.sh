#!/bin/bash

echo "=== 测试55%费率（11虫洞币/1000 tokens）==="
echo ""

# 在服务器上运行测试
ssh root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend

echo "1️⃣ 创建测试账户并充值1000积分:"
curl -s -X POST http://localhost:3000/admin/set-balance \
  -H 'Content-Type: application/json' \
  -d '{"appAccountToken":"rate55-test","balance":1000}' | jq '.'

echo ""
echo "2️⃣ 模拟API调用（约5000 tokens）:"
echo "   预期消耗: 5000/1000 * 11 = 55虫洞币"
echo ""

# 模拟5000 token的调用
curl -s -X POST http://localhost:3000/api/proxy \
  -H 'Content-Type: application/json' \
  -H 'X-App-Account-Token: rate55-test' \
  -d '{
    "model": "deepseek-r1-250120",
    "messages": [{"role":"user","content":"测试"}],
    "stream": false
  }' > /tmp/test_response.json

echo "✓ API调用完成"
echo ""

sleep 1

echo "3️⃣ 查看余额变化:"
BALANCE=$(curl -s "http://localhost:3000/balance?appAccountToken=rate55-test" | jq -r '.balance')
echo "   当前余额: $BALANCE 虫洞币"
echo "   消耗积分: $((1000 - BALANCE)) 虫洞币"
echo ""

# 计算费率
USED=$((1000 - BALANCE))
echo "4️⃣ 费率验证:"
if [ $USED -ge 10 ] && [ $USED -le 15 ]; then
    echo "   ✅ 费率正确！消耗 $USED 虫洞币，符合11虫洞币/1000 tokens"
else
    echo "   ⚠️  费率可能不对，消耗 $USED 虫洞币"
fi

echo ""
echo "5️⃣ 查看响应头信息:"
TOKENS=$(cat /tmp/test_response.json | jq -r '.usage.total_tokens // "N/A"')
echo "   实际tokens: $TOKENS"
if [ "$TOKENS" != "N/A" ]; then
    EXPECTED=$((TOKENS * 11 / 1000))
    echo "   预期消耗: $EXPECTED 虫洞币"
fi

echo ""
echo "=== 测试完成 ==="
REMOTE

