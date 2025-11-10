#!/bin/bash

PASSWORD="3Qq123456."
SERVER="root@47.94.254.130"

echo "=== 步骤1: 检查服务器当前配置 ==="
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $SERVER << 'REMOTE'
cd /var/www/chongyu-backend
echo "当前配置:"
cat production.env | grep CREDITS || echo "未找到CREDITS配置"
echo ""
REMOTE

echo ""
echo "=== 步骤2: 上传新的server.js ==="
sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no server.js $SERVER:/var/www/chongyu-backend/
echo "✓ server.js 已上传"

echo ""
echo "=== 步骤3: 更新配置并重启服务 ==="
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $SERVER << 'REMOTE'
cd /var/www/chongyu-backend

# 备份配置
cp production.env production.env.backup_$(date +%Y%m%d_%H%M%S)

# 更新费率配置
if grep -q '^CREDITS_PER_1K_TOKENS=' production.env; then
    sed -i 's/^CREDITS_PER_1K_TOKENS=.*/CREDITS_PER_1K_TOKENS=11/' production.env
else
    echo 'CREDITS_PER_1K_TOKENS=11' >> production.env
fi

# 删除旧的视觉API固定积分配置（如果存在）
sed -i '/^CREDITS_PER_DOUBAO_SEED_VISION=/d' production.env
sed -i '/^CREDITS_PER_DOUBAO_VISION_PRO=/d' production.env

echo ""
echo "新配置内容:"
cat production.env

echo ""
echo "重启服务..."
pm2 restart chongyu-backend --update-env

sleep 3

echo ""
echo "服务状态:"
pm2 list | grep chongyu-backend

echo ""
echo "验证日志（最新20行）:"
pm2 logs chongyu-backend --lines 20 --nostream | tail -20
REMOTE

echo ""
echo "✅ 部署完成！"
