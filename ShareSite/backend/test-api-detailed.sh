#!/bin/bash

API_URL="http://localhost:3000"
TEST_USER_ID="test-debug-$(date +%s)"

echo "================================"
echo "    API详细调试测试"
echo "================================"
echo "用户ID: $TEST_USER_ID"
echo ""

# 初始化账户余额
echo "1. 初始化账户余额..."
INIT_RESPONSE=$(curl -s "$API_URL/balance?appAccountToken=$TEST_USER_ID")
echo "初始化响应: $INIT_RESPONSE"
INITIAL_BALANCE=$(echo "$INIT_RESPONSE" | grep -o '"balance":[0-9]*' | cut -d':' -f2)
echo "初始余额: $INITIAL_BALANCE 积分"
echo ""

# 调用纯文本API，显示完整的响应头
echo "2. 调用纯文本API..."
echo "请求体:"
cat << EOF
{
  "appAccountToken": "$TEST_USER_ID",
  "messages": [
    {"role": "user", "content": "请用中文写一个简短的自我介绍，大约50字左右。"}
  ],
  "conversationId": "test-conv-$(date +%s)"
}
EOF
echo ""

# 保存响应到文件并显示响应头
TEMP_HEADERS="/tmp/api_headers_$$.txt"
TEMP_BODY="/tmp/api_body_$$.txt"

curl -v "$API_URL/api/proxy" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TEST_USER_ID" \
  -d "{
    \"messages\": [
      {\"role\": \"user\", \"content\": \"请用中文写一个简短的自我介绍，大约50字左右。\"}
    ]
  }" \
  -D "$TEMP_HEADERS" \
  -o "$TEMP_BODY" \
  2>&1 | grep -E "^[<>]"

echo ""
echo "响应头信息:"
cat "$TEMP_HEADERS"
echo ""

# 提取关键信息
USAGE_TOKENS=$(grep -i "X-Usage-Tokens:" "$TEMP_HEADERS" | cut -d' ' -f2 | tr -d '\r')
COST_CREDITS=$(grep -i "X-Cost-Credits:" "$TEMP_HEADERS" | cut -d' ' -f2 | tr -d '\r')
BALANCE_AFTER=$(grep -i "X-Balance-After:" "$TEMP_HEADERS" | cut -d' ' -f2 | tr -d '\r')

echo "从响应头提取的信息:"
echo "  Token使用量: $USAGE_TOKENS"
echo "  扣除积分: $COST_CREDITS"
echo "  剩余余额: $BALANCE_AFTER"
echo ""

# 再次查询余额确认
echo "3. 查询最终余额..."
FINAL_RESPONSE=$(curl -s "$API_URL/balance?appAccountToken=$TEST_USER_ID")
echo "最终余额响应: $FINAL_RESPONSE"
FINAL_BALANCE=$(echo "$FINAL_RESPONSE" | grep -o '"balance":[0-9]*' | cut -d':' -f2)
echo "最终余额: $FINAL_BALANCE 积分"
echo ""

# 计算实际扣除
ACTUAL_DEDUCTED=$((INITIAL_BALANCE - FINAL_BALANCE))
echo "4. 费率分析:"
echo "  初始余额: $INITIAL_BALANCE 积分"
echo "  最终余额: $FINAL_BALANCE 积分"
echo "  实际扣除: $ACTUAL_DEDUCTED 积分"
echo "  响应头显示扣除: $COST_CREDITS 积分"

if [ -n "$USAGE_TOKENS" ] && [ "$USAGE_TOKENS" -gt 0 ]; then
  ACTUAL_RATE=$(echo "scale=2; $ACTUAL_DEDUCTED * 1000 / $USAGE_TOKENS" | bc)
  echo "  实际费率: $ACTUAL_RATE 积分/1k tokens"
  echo ""
  
  EXPECTED_COST=$(echo "scale=0; $USAGE_TOKENS * 16.3 / 1000" | bc)
  echo "  预期扣除(16.3费率): $EXPECTED_COST 积分"
  
  if [ "$ACTUAL_DEDUCTED" -le "$((EXPECTED_COST + 1))" ] && [ "$ACTUAL_DEDUCTED" -ge "$((EXPECTED_COST - 1))" ]; then
    echo "  ✅ 费率正确 (误差在±1积分内)"
  else
    echo "  ❌ 费率异常！实际扣除 $ACTUAL_DEDUCTED 积分，预期 $EXPECTED_COST 积分"
  fi
fi

# 清理临时文件
rm -f "$TEMP_HEADERS" "$TEMP_BODY"

echo ""
echo "================================"

