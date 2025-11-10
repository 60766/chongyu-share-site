#!/bin/bash

echo "=== 虫遇后端费率更新脚本 ==="
echo "目标: 将费率从65%(13币/1K tokens)降到55%(11币/1K tokens)"
echo ""

read -p "请输入SSH密码: " -s PASSWORD
echo ""

echo "=== 步骤1: 检查当前配置 ==="
ssh root@47.94.254.130 << REMOTE
cd /var/www/chongyu-backend
echo "当前production.env中的CREDITS配置:"
cat production.env | grep CREDITS
echo ""
REMOTE

echo ""
echo "=== 步骤2: 上传server.js ==="
scp server.js root@47.94.254.130:/var/www/chongyu-backend/
echo "✓ 上传完成"

echo ""
echo "=== 步骤3: 更新配置并重启 ==="
ssh root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend

# 备份
cp production.env production.env.backup_$(date +%Y%m%d_%H%M%S)

# 更新费率为11
if grep -q '^CREDITS_PER_1K_TOKENS=' production.env; then
    sed -i 's/^CREDITS_PER_1K_TOKENS=.*/CREDITS_PER_1K_TOKENS=11/' production.env
else
    echo 'CREDITS_PER_1K_TOKENS=11' >> production.env
fi

# 删除旧的视觉API固定配置
sed -i '/^CREDITS_PER_DOUBAO_SEED_VISION=/d' production.env 2>/dev/null
sed -i '/^CREDITS_PER_DOUBAO_VISION_PRO=/d' production.env 2>/dev/null

echo ""
echo "✓ 配置已更新，新配置:"
cat production.env | grep CREDITS

echo ""
echo "重启服务..."
pm2 restart chongyu-backend --update-env

sleep 3

echo ""
echo "服务状态:"
pm2 list | grep chongyu

echo ""
echo "最新日志:"
pm2 logs chongyu-backend --lines 10 --nostream
REMOTE

echo ""
echo "✅ 部署完成！费率已更新为11币/1000 tokens (55%)"
