#!/bin/bash

# 纯文本API费率验证脚本
# 预期费率: 16.3 积分/1k tokens

API_URL="http://localhost:3000"
TEST_USER_ID="verify-$(date +%s)"

echo "================================"
echo "      纯文本API费率验证"
echo "================================"
echo "用户ID: $TEST_USER_ID"
echo ""

# 获取初始余额
INITIAL_BALANCE=$(curl -s "$API_URL/balance?appAccountToken=$TEST_USER_ID" | grep -o '"balance":[0-9]*' | cut -d':' -f2)
echo "初始余额: $INITIAL_BALANCE 积分"

# 调用纯文本API
echo "调用纯文本API..."
RESPONSE=$(curl -s "$API_URL/api/proxy" \
  -H "Content-Type: application/json" \
  -d "{
    \"appAccountToken\": \"$TEST_USER_ID\",
    \"messages\": [
      {\"role\": \"user\", \"content\": \"请用中文写一个简短的自我介绍，大约50字左右。\"}
    ],
    \"conversationId\": \"test-conv-$(date +%s)\"
  }")

# 提取token使用信息
TOKEN_USAGE=$(echo "$RESPONSE" | grep -o '"usage":{[^}]*}' | grep -o '"total_tokens":[0-9]*' | cut -d':' -f2)

# 获取最终余额
sleep 1
FINAL_BALANCE=$(curl -s "$API_URL/balance?appAccountToken=$TEST_USER_ID" | grep -o '"balance":[0-9]*' | cut -d':' -f2)
echo "最终余额: $FINAL_BALANCE 积分"

# 计算扣除积分
DEDUCTED=$((INITIAL_BALANCE - FINAL_BALANCE))
echo "扣除积分: $DEDUCTED 积分"
echo ""

# 验证费率
echo "Token使用: $TOKEN_USAGE"
EXPECTED=$((TOKEN_USAGE * 163 / 10000))
echo "预期扣除: $EXPECTED 积分 (按 16.3 积分/1k tokens)"
echo "实际扣除: $DEDUCTED 积分"

# 计算实际费率
if [ $TOKEN_USAGE -gt 0 ]; then
  ACTUAL_RATE=$(awk "BEGIN {printf \"%.2f\", $DEDUCTED * 1000.0 / $TOKEN_USAGE}")
  echo "实际费率: $ACTUAL_RATE 积分/1k tokens"
fi

# 检查是否在合理范围内 (允许±1积分误差)
DIFF=$((DEDUCTED - EXPECTED))
ABS_DIFF=${DIFF#-}

if [ $ABS_DIFF -le 1 ]; then
  echo ""
  echo "✅ 纯文本API费率验证通过！"
  echo "   费率已正确设置为 16.3 积分/1k tokens"
else
  echo ""
  echo "❌ 费率验证失败！"
  echo "   误差: $DIFF 积分"
fi

echo ""
echo "================================"
echo ""
