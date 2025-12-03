#!/bin/bash

# 新费率测试脚本 - 验证视觉API使用11币/1000tokens的费率
# 测试目标: 确认视觉API使用与文本API相同的费率

echo "========================================"
echo "视觉API新费率测试 (11币/1000tokens)"
echo "========================================"
echo ""

# 服务器信息
SERVER="47.94.254.130"
BASE_URL="http://${SERVER}:3000"
TEST_TOKEN="rate-test-$(date +%s)"

echo "📋 测试配置:"
echo "  - 服务器: ${SERVER}"
echo "  - 测试Token: ${TEST_TOKEN}"
echo "  - 预期费率: 11币/1000tokens"
echo ""

# 1. 创建测试账户
echo "1️⃣  创建测试账户..."
INIT_RESULT=$(curl -s -X POST "${BASE_URL}/api/wallet/init" \
  -H 'Content-Type: application/json' \
  -d "{\"appAccountToken\":\"${TEST_TOKEN}\"}")
echo "   结果: ${INIT_RESULT}"
echo ""

# 2. 充值10000积分
echo "2️⃣  充值10000积分..."
RECHARGE_RESULT=$(curl -s -X POST "${BASE_URL}/api/wallet/balance" \
  -H 'Content-Type: application/json' \
  -d "{\"appAccountToken\":\"${TEST_TOKEN}\",\"amount\":10000}")
echo "   结果: ${RECHARGE_RESULT}"
BALANCE_BEFORE=$(echo $RECHARGE_RESULT | grep -o '"balance":[0-9]*' | cut -d: -f2)
echo "   余额: ${BALANCE_BEFORE}币"
echo ""

# 3. 调用视觉API（模拟调用，无图片）
echo "3️⃣  调用视觉API..."
echo "   模型: doubao-seed-1-6-vision-250815"
VISION_RESULT=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/api/vision" \
  -H 'Content-Type: application/json' \
  -H "X-App-Account-Token: ${TEST_TOKEN}" \
  -d '{
    "model": "doubao-seed-1-6-vision-250815",
    "messages": [
      {
        "role": "user",
        "content": "你好"
      }
    ],
    "max_tokens": 50
  }')

HTTP_CODE=$(echo "$VISION_RESULT" | tail -n 1)
RESPONSE=$(echo "$VISION_RESULT" | head -n -1)

echo "   HTTP状态码: ${HTTP_CODE}"

if [ "$HTTP_CODE" = "200" ]; then
  echo "   ✅ API调用成功"
  
  # 提取响应头中的token使用量和费用
  TOKENS=$(echo "$RESPONSE" | grep -o '"total_tokens":[0-9]*' | head -1 | cut -d: -f2)
  
  echo "   Token消耗: ${TOKENS:-未知}"
  
  # 4. 查询剩余积分
  echo ""
  echo "4️⃣  查询剩余积分..."
  BALANCE_RESULT=$(curl -s "${BASE_URL}/api/wallet/balance?appAccountToken=${TEST_TOKEN}")
  BALANCE_AFTER=$(echo $BALANCE_RESULT | grep -o '"balance":[0-9]*' | cut -d: -f2)
  echo "   结果: ${BALANCE_RESULT}"
  echo "   余额: ${BALANCE_AFTER}币"
  
  # 5. 计算实际费用
  echo ""
  echo "5️⃣  费率验证..."
  COST=$((BALANCE_BEFORE - BALANCE_AFTER))
  echo "   实际扣费: ${COST}币"
  
  if [ ! -z "$TOKENS" ] && [ "$TOKENS" -gt 0 ]; then
    # 计算期望费用 (使用11币/1000tokens)
    EXPECTED_COST=$(echo "scale=2; ($TOKENS / 1000) * 11" | bc)
    EXPECTED_COST_CEIL=$(printf "%.0f" $(echo "$EXPECTED_COST + 0.999" | bc))
    
    echo "   Token消耗: ${TOKENS}"
    echo "   期望扣费: ${EXPECTED_COST_CEIL}币 (${TOKENS}tokens * 11币/1000tokens)"
    echo "   实际扣费: ${COST}币"
    
    if [ "$COST" -eq "$EXPECTED_COST_CEIL" ]; then
      echo "   ✅ 费率正确！"
    else
      echo "   ❌ 费率异常！期望${EXPECTED_COST_CEIL}币，实际${COST}币"
    fi
  else
    echo "   ⚠️  无法获取token数量，仅显示扣费: ${COST}币"
  fi
else
  echo "   ❌ API调用失败"
  echo "   响应: ${RESPONSE}"
fi

echo ""
echo "========================================"
echo "测试完成！"
echo "========================================"

