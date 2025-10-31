#!/bin/bash

# 生产环境API测试脚本
# 用于快速验证所有Product ID和API端点

SERVER="http://121.40.184.29:3000"
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 虫遇生产环境API测试${NC}\n"

# 1. 健康检查
echo -e "${BLUE}1. 健康检查${NC}"
HEALTH=$(curl -s "$SERVER/health")
if [[ $HEALTH == *"ok"* ]]; then
    echo -e "${GREEN}✅ 服务器正常运行${NC}"
else
    echo -e "${RED}❌ 服务器异常${NC}"
    exit 1
fi
echo ""

# 2. 测试新格式Product ID
echo -e "${BLUE}2. 测试生产环境Product ID（新格式）${NC}"

test_product() {
    local product_id=$1
    local expected=$2
    local name=$3
    
    local result=$(curl -s -X POST "$SERVER/purchase/confirm" \
        -H "Content-Type: application/json" \
        -d "{\"appAccountToken\":\"test-$product_id\",\"productId\":\"$product_id\",\"transactionId\":\"test-$(date +%s)-$product_id\"}")
    
    if [[ $result == *"\"balance\":$expected"* ]]; then
        echo -e "${GREEN}✅ $name: $product_id → $expected能量${NC}"
    else
        echo -e "${RED}❌ $name失败: $result${NC}"
    fi
}

test_product "com.lishilong.chongyu.100energy" "1800" "100能量包(¥6)"
test_product "com.lishilong.chongyu.300energy" "6000" "300能量包(¥18)"
test_product "com.lishilong.chongyu.700energy" "13800" "700能量包(¥38)"
test_product "com.lishilong.chongyu.1400energy" "26800" "1400能量包(¥68)"
echo ""

# 3. 测试向后兼容性
echo -e "${BLUE}3. 测试向后兼容性（旧格式）${NC}"
test_product "credits.small" "1800" "旧格式-小包"
test_product "credits.medium" "6000" "旧格式-中包"
echo ""

# 4. 测试余额查询
echo -e "${BLUE}4. 测试余额查询${NC}"
BALANCE=$(curl -s "$SERVER/balance?appAccountToken=test-balance-query")
if [[ $BALANCE == *"balance"* ]]; then
    echo -e "${GREEN}✅ 余额查询正常: $BALANCE${NC}"
else
    echo -e "${RED}❌ 余额查询失败${NC}"
fi
echo ""

# 5. 测试错误处理
echo -e "${BLUE}5. 测试错误处理${NC}"
ERROR_TEST=$(curl -s -X POST "$SERVER/purchase/confirm" \
    -H "Content-Type: application/json" \
    -d '{"appAccountToken":"test","productId":"invalid.product","transactionId":"test"}')
if [[ $ERROR_TEST == *"unknown productId"* ]]; then
    echo -e "${GREEN}✅ 错误处理正常（未知Product ID被正确拒绝）${NC}"
else
    echo -e "${RED}❌ 错误处理异常${NC}"
fi
echo ""

echo -e "${GREEN}🎉 所有测试完成！${NC}"
echo -e "${BLUE}📊 服务器地址: $SERVER${NC}"
echo -e "${BLUE}📝 查看详细日志: ./check_server_status.exp${NC}"

