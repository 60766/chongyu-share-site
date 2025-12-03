#!/bin/bash

# 检查服务器上的 IAP 验证代码是否已部署

echo "=========================================="
echo "检查服务器上的 IAP 验证代码"
echo "=========================================="

# 检查验证函数是否存在
echo "1. 检查 verifyIAPTransaction 函数："
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -n 'verifyIAPTransaction' server.js | head -5"

echo ""
echo "2. 检查 /purchase/confirm 端点是否包含验证逻辑："
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 10 'app.post.*purchase/confirm' server.js | grep -E 'verifyIAPTransaction|IAP Verify' | head -5"

echo ""
echo "3. 检查配置："
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep IAP_VERIFY_STRICT production.env 2>/dev/null || echo '未找到 IAP_VERIFY_STRICT 配置'"

echo ""
echo "4. 检查 App Store JWKS 配置："
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -n 'APP_STORE_JWKS' server.js | head -3"

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

