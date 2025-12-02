#!/bin/bash
# 检查服务器上的代码版本

echo "=== 检查服务器上的启动日志代码 ==="
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && tail -15 server.js | grep -A 10 'app.listen'"

echo ""
echo "=== 检查是否有 [Config] 日志输出 ==="
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -n '\[Config\]' server.js"

echo ""
echo "=== 检查实际的赠送记录（查看所有交易） ==="
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.ref == \"new_user_welcome\") | {amount, at, meta}' 2>/dev/null | head -30"

echo ""
echo "=== 如果没有jq，用grep查看 ==="
ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -B 2 -A 5 'new_user_welcome' server-data.json | grep -E 'amount|reason' | head -20"

