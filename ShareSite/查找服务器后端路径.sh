#!/bin/bash
# 查找服务器上后端代码的实际位置

echo "=== 查找后端目录 ==="
ssh root@121.40.184.29 "find /root -name 'server.js' -type f 2>/dev/null | head -5"

echo ""
echo "=== 查找 production.env 文件 ==="
ssh root@121.40.184.29 "find /root -name 'production.env' -type f 2>/dev/null | head -5"

echo ""
echo "=== 检查PM2进程的工作目录 ==="
ssh root@121.40.184.29 "pm2 show chongyu-backend | grep -E 'cwd|script path'"

echo ""
echo "=== 列出 /root 目录 ==="
ssh root@121.40.184.29 "ls -la /root | grep -E 'chongyu|backend|server'"

