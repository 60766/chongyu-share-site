#!/bin/bash
set -e

echo "=== 更新费率从65%到55% ==="
echo ""
echo "📊 费率对比："
echo "   65%费率: 1000 tokens = 13虫洞币"
echo "   55%费率: 1000 tokens = 11虫洞币 ⬅️ 新费率"
echo ""
echo "💡 节省效果："
echo "   12篇帖子从110虫洞币降至93虫洞币（节省15%）"
echo ""

read -p "确认更新费率到55%？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "取消操作"
    exit 1
fi

echo ""
echo "步骤1: 上传新的server.js"
scp server.js root@47.94.254.130:/var/www/chongyu-backend/

echo ""
echo "步骤2: 更新production.env中的费率"
ssh root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend

# 备份当前配置
cp production.env production.env.backup_$(date +%Y%m%d_%H%M%S)

# 更新费率
if grep -q "^CREDITS_PER_1K_TOKENS=" production.env; then
    sed -i 's/^CREDITS_PER_1K_TOKENS=.*/CREDITS_PER_1K_TOKENS=11/' production.env
    echo "✓ 已更新现有配置"
else
    echo "CREDITS_PER_1K_TOKENS=11" >> production.env
    echo "✓ 已添加新配置"
fi

echo ""
echo "=== 新配置内容 ==="
cat production.env
REMOTE

echo ""
echo "步骤3: 重启PM2服务"
ssh root@47.94.254.130 << 'REMOTE'
cd /var/www/chongyu-backend
pm2 restart chongyu-backend --update-env
sleep 3
echo ""
echo "=== 验证配置 ==="
pm2 logs chongyu-backend --lines 20 --nostream | grep -E "CREDITS_PER_1K_TOKENS|Config"
REMOTE

echo ""
echo "=== 部署完成 ==="
echo "✓ 费率已更新到55% (11虫洞币/1000 tokens)"
echo "✓ 视觉API已恢复使用token计费"
echo ""
echo "💰 现在测试12篇帖子应该消耗约93虫洞币（之前110）"

