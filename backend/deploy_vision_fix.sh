#!/bin/bash
set -e

echo "=== 部署视觉API固定积分扣除功能 ==="
echo ""
echo "步骤1: 上传新的server.js"
scp server.js root@47.94.254.130:/var/www/chongyu-backend/

echo ""
echo "步骤2: 重启PM2服务（加载新环境变量）"
ssh root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend
pm2 restart chongyu-backend --update-env
sleep 3
echo ""
echo "=== 验证配置 ==="
pm2 logs chongyu-backend --lines 10 --nostream | grep -E "CREDITS_PER_DOUBAO|Config"
REMOTE

echo ""
echo "=== 部署完成 ==="
echo "✓ server.js已更新"
echo "✓ PM2服务已重启"
echo ""
echo "现在可以运行测试脚本验证功能..."
