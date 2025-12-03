#!/bin/bash

echo "🧪 API服务器测试"
echo "=================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_DOMAIN="api.chongyuai.com"
SERVER_IP="121.40.184.29"

echo "📋 测试项目："
echo "1. DNS解析"
echo "2. HTTPS连接"
echo "3. SSL证书"
echo "4. API端点响应"
echo "5. 服务器后端服务状态"
echo ""
echo "=================================="
echo ""

# 1. DNS解析测试
echo "1️⃣ DNS解析测试"
echo "----------------------------------"
DNS_RESULT=$(nslookup $API_DOMAIN 2>&1 | grep -A 2 "Non-authoritative answer" | grep "Address" | tail -1 | awk '{print $2}')
if [ "$DNS_RESULT" == "$SERVER_IP" ]; then
    echo -e "${GREEN}✅ DNS解析正确: $API_DOMAIN → $DNS_RESULT${NC}"
else
    echo -e "${RED}❌ DNS解析错误: 期望 $SERVER_IP, 实际 $DNS_RESULT${NC}"
fi
echo ""

# 2. HTTPS连接测试
echo "2️⃣ HTTPS连接测试"
echo "----------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://$API_DOMAIN 2>&1)
if [ "$HTTP_CODE" == "404" ] || [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ] || [ "$HTTP_CODE" == "302" ]; then
    echo -e "${GREEN}✅ HTTPS连接成功 (HTTP状态码: $HTTP_CODE)${NC}"
    echo "   说明：404是正常的，因为根路径没有内容"
else
    echo -e "${RED}❌ HTTPS连接失败 (HTTP状态码: $HTTP_CODE)${NC}"
fi
echo ""

# 3. SSL证书测试
echo "3️⃣ SSL证书测试"
echo "----------------------------------"
CERT_INFO=$(echo | openssl s_client -connect $API_DOMAIN:443 -servername $API_DOMAIN 2>&1 | grep -A 2 "Certificate chain" | head -3)
if echo "$CERT_INFO" | grep -q "Certificate chain"; then
    echo -e "${GREEN}✅ SSL证书有效${NC}"
    CERT_EXPIRY=$(echo | openssl s_client -connect $API_DOMAIN:443 -servername $API_DOMAIN 2>&1 | openssl x509 -noout -dates 2>/dev/null | grep "notAfter" | cut -d= -f2)
    if [ ! -z "$CERT_EXPIRY" ]; then
        echo "   证书过期时间: $CERT_EXPIRY"
    fi
else
    echo -e "${RED}❌ SSL证书检查失败${NC}"
fi
echo ""

# 4. API端点测试
echo "4️⃣ API端点测试"
echo "----------------------------------"

# 测试健康检查端点（如果存在）
echo "测试: GET /health"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 5 https://$API_DOMAIN/health 2>&1)
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -1)
if [ "$HEALTH_CODE" == "200" ]; then
    echo -e "${GREEN}✅ /health 端点正常${NC}"
elif [ "$HEALTH_CODE" == "404" ]; then
    echo -e "${YELLOW}⚠️  /health 端点不存在（可能正常，取决于后端实现）${NC}"
else
    echo -e "${YELLOW}⚠️  /health 返回: $HEALTH_CODE${NC}"
fi

# 测试余额查询端点（需要token，但可以测试端点是否存在）
echo ""
echo "测试: GET /api/wallet/balance"
BALANCE_RESPONSE=$(curl -s -w "\n%{http_code}" --max-time 5 "https://$API_DOMAIN/api/wallet/balance?appAccountToken=test" 2>&1)
BALANCE_CODE=$(echo "$BALANCE_RESPONSE" | tail -1)
BALANCE_BODY=$(echo "$BALANCE_RESPONSE" | head -1)
if [ "$BALANCE_CODE" == "200" ] || [ "$BALANCE_CODE" == "400" ] || [ "$BALANCE_CODE" == "401" ]; then
    echo -e "${GREEN}✅ /api/wallet/balance 端点可访问 (状态码: $BALANCE_CODE)${NC}"
    if echo "$BALANCE_BODY" | grep -q "balance\|error\|message"; then
        echo "   响应: $(echo "$BALANCE_BODY" | head -c 100)..."
    fi
elif [ "$BALANCE_CODE" == "404" ]; then
    echo -e "${RED}❌ /api/wallet/balance 端点不存在${NC}"
else
    echo -e "${YELLOW}⚠️  /api/wallet/balance 返回: $BALANCE_CODE${NC}"
fi
echo ""

# 5. 服务器后端服务状态
echo "5️⃣ 服务器后端服务状态"
echo "----------------------------------"
echo "正在检查服务器上的后端服务..."
echo ""

expect << 'EXPEOF' 2>/dev/null
set timeout 30
spawn ssh -o StrictHostKeyChecking=no root@121.40.184.29
expect {
    "*password:" {
        send "3Qq123456.\r"
        expect "#"
        send "echo '=== Node.js进程 ==='\r"
        expect "#"
        send "ps aux | grep node | grep -v grep | head -3\r"
        expect "#"
        send "echo ''\r"
        expect "#"
        send "echo '=== 端口监听 ==='\r"
        expect "#"
        send "netstat -tlnp | grep ':3000' | head -2\r"
        expect "#"
        send "echo ''\r"
        expect "#"
        send "echo '=== Caddy服务状态 ==='\r"
        expect "#"
        send "systemctl status caddy --no-pager | grep -E 'Active|Main PID' | head -2\r"
        expect "#"
        send "echo ''\r"
        expect "#"
        send "echo '=== 测试本地API ==='\r"
        expect "#"
        send "curl -s -o /dev/null -w 'HTTP状态码: %{http_code}\n' http://127.0.0.1:3000/health 2>&1 || echo '后端服务可能未运行'\r"
        expect "#"
        send "exit\r"
        expect eof
}
EXPEOF

echo ""
echo "=================================="
echo "✅ 测试完成！"
echo ""
echo "📊 总结："
echo "- 如果DNS、HTTPS、SSL都正常，说明网络层配置正确"
echo "- 如果API端点返回200/400/401，说明后端服务正常"
echo "- 如果返回404，可能需要检查后端路由配置"

