#!/bin/bash
set -e

echo "=== 检查阿里云后端配置 ==="
echo ""

# 检查当前配置
echo "1️⃣ 查看当前费率配置:"
ssh -o StrictHostKeyChecking=no root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend
if [ -f production.env ]; then
    echo "production.env 内容:"
    cat production.env | grep -E "CREDITS|PORT|NODE_ENV" || echo "未找到相关配置"
else
    echo "⚠️  production.env 文件不存在"
fi
echo ""
echo "2️⃣ 查看当前运行的进程:"
pm2 list
echo ""
echo "3️⃣ 查看最近日志（检查费率配置）:"
pm2 logs chongyu-backend --lines 30 --nostream | grep -E "CREDITS|Config|token" || pm2 logs chongyu-backend --lines 30 --nostream
REMOTE

echo ""
echo "=== 检查完成 ==="
