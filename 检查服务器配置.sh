#!/bin/bash
# 检查服务器上实际运行的配置

echo "=== 1. 检查服务器上的 production.env 文件 ==="
ssh root@121.40.184.29 "cd /root/chongyu-backend && cat production.env | grep INITIAL_WELCOME_CREDITS"

echo ""
echo "=== 2. 检查服务器上的代码（server.js） ==="
ssh root@121.40.184.29 "cd /root/chongyu-backend && grep -n 'INITIAL_WELCOME_CREDITS' server.js | head -3"

echo ""
echo "=== 3. 检查PM2进程的环境变量 ==="
ssh root@121.40.184.29 "pm2 show chongyu-backend | grep -A 20 'env:'"

echo ""
echo "=== 4. 检查最近的启动日志（完整） ==="
ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 100 --nostream | grep -E '\[Config\]|INITIAL|启动|listening' | tail -20"

echo ""
echo "=== 5. 检查最近的赠送记录 ==="
ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 500 --nostream | grep '获得.*虫洞币' | tail -10"

echo ""
echo "=== 6. 检查 server-data.json 中的赠送金额 ==="
ssh root@121.40.184.29 "cd /root/chongyu-backend && cat server-data.json | grep -A 3 'new_user_welcome' | grep 'amount' | head -5"

