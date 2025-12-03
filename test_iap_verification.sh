#!/bin/bash

# IAP 验证功能测试脚本
# 使用方法：
#   chmod +x test_iap_verification.sh
#   ./test_iap_verification.sh
#   或指定服务器地址：
#   SERVER=https://api.chongyuai.com ./test_iap_verification.sh

set -e

# 配置
SERVER="${SERVER:-http://localhost:3000}"
TOKEN="${TOKEN:-test_token_$(date +%s)}"
PRODUCT_ID="${PRODUCT_ID:-com.lishilong.chongyu.100energy}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "IAP 验证功能测试"
echo "=========================================="
echo "服务器: $SERVER"
echo "Token: $TOKEN"
echo "产品 ID: $PRODUCT_ID"
echo ""

# 检查服务器是否可用
echo -e "${YELLOW}检查服务器连接...${NC}"
if ! curl -s -f "$SERVER/health" > /dev/null; then
  echo -e "${RED}❌ 无法连接到服务器: $SERVER${NC}"
  exit 1
fi
echo -e "${GREEN}✅ 服务器连接正常${NC}\n"

# 测试1: 正常交易（无 receipt）
echo -e "${YELLOW}测试1: 正常交易（无 receipt）${NC}"
TX_ID_1="test_$(date +%s)_1"
RESPONSE=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TX_ID_1\"
  }")

echo "$RESPONSE" | jq '.' || echo "$RESPONSE"

if echo "$RESPONSE" | jq -e '.balance' > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 测试1通过：充值成功${NC}\n"
else
  echo -e "${RED}❌ 测试1失败：充值失败${NC}\n"
fi

# 测试2: 无效 receipt
echo -e "${YELLOW}测试2: 无效 receipt（伪造的 JWT）${NC}"
TX_ID_2="test_$(date +%s)_2"
RESPONSE=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TX_ID_2\",
    \"receipt\": \"invalid.jwt.token.here\"
  }")

echo "$RESPONSE" | jq '.' || echo "$RESPONSE"

if echo "$RESPONSE" | jq -e '.warning' > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 测试2通过：检测到警告（非严格模式）${NC}\n"
elif echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 测试2通过：拒绝交易（严格模式）${NC}\n"
else
  echo -e "${YELLOW}⚠️  测试2：未检测到警告或错误${NC}\n"
fi

# 测试3: 重复交易
echo -e "${YELLOW}测试3: 重复交易（防重复机制）${NC}"
TX_ID_3="test_$(date +%s)_3"

# 第一次请求
RESPONSE1=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TX_ID_3\"
  }")

BALANCE1=$(echo "$RESPONSE1" | jq -r '.balance // 0')

# 第二次请求（相同 transactionId）
sleep 1
RESPONSE2=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TX_ID_3\"
  }")

BALANCE2=$(echo "$RESPONSE2" | jq -r '.balance // 0')

echo "第一次余额: $BALANCE1"
echo "第二次余额: $BALANCE2"

if [ "$BALANCE1" = "$BALANCE2" ]; then
  echo -e "${GREEN}✅ 测试3通过：防重复机制正常工作${NC}\n"
else
  echo -e "${RED}❌ 测试3失败：余额发生变化，可能重复充值了${NC}\n"
fi

# 测试4: 产品 ID 不匹配（如果有 receipt）
echo -e "${YELLOW}测试4: 产品 ID 不匹配${NC}"
TX_ID_4="test_$(date +%s)_4"
WRONG_PRODUCT_ID="com.lishilong.chongyu.300energy"

RESPONSE=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$WRONG_PRODUCT_ID\",
    \"transactionId\": \"$TX_ID_4\",
    \"receipt\": \"invalid.jwt.token\"
  }")

echo "$RESPONSE" | jq '.' || echo "$RESPONSE"

if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error')
  if [ "$ERROR" = "unknown productId" ]; then
    echo -e "${GREEN}✅ 测试4通过：检测到未知产品 ID${NC}\n"
  else
    echo -e "${YELLOW}⚠️  测试4：返回错误但不是预期的错误类型${NC}\n"
  fi
else
  echo -e "${YELLOW}⚠️  测试4：未返回错误${NC}\n"
fi

# 测试5: 缺少参数
echo -e "${YELLOW}测试5: 缺少必要参数${NC}"
RESPONSE=$(curl -s -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\"
  }")

echo "$RESPONSE" | jq '.' || echo "$RESPONSE"

if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo -e "${GREEN}✅ 测试5通过：正确检测到缺少参数${NC}\n"
else
  echo -e "${RED}❌ 测试5失败：未检测到缺少参数${NC}\n"
fi

# 总结
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "提示："
echo "1. 查看后端日志以获取详细的验证信息："
echo "   tail -f /var/log/chongyu-backend.log | grep -E 'IAP|Verify'"
echo ""
echo "2. 检查配置："
echo "   grep IAP_VERIFY_STRICT backend/production.env"
echo ""
echo "3. 如需测试真实 receipt，请在 iOS 应用中执行实际购买"

