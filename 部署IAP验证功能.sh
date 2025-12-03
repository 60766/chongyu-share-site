#!/bin/bash

# 部署 IAP 验证功能到服务器
# 使用方法：./部署IAP验证功能.sh

set -e

SERVER_IP="121.40.184.29"
BACKEND_DIR="/var/www/chongyu-backend"
LOCAL_BACKEND_DIR="backend"

echo "=========================================="
echo "部署 IAP 验证功能到服务器"
echo "=========================================="
echo "服务器: $SERVER_IP"
echo "后端目录: $BACKEND_DIR"
echo ""

# 检查本地文件是否存在
if [ ! -f "$LOCAL_BACKEND_DIR/server.js" ]; then
    echo "❌ 错误: 找不到 $LOCAL_BACKEND_DIR/server.js"
    exit 1
fi

if [ ! -f "$LOCAL_BACKEND_DIR/production.env" ]; then
    echo "❌ 错误: 找不到 $LOCAL_BACKEND_DIR/production.env"
    exit 1
fi

echo "✅ 本地文件检查通过"
echo ""

# 备份服务器上的文件
echo "步骤1: 备份服务器上的现有文件..."
ssh root@$SERVER_IP "cd $BACKEND_DIR && cp server.js server.js.backup.\$(date +%Y%m%d_%H%M%S) && cp production.env production.env.backup.\$(date +%Y%m%d_%H%M%S) && echo '备份完成'"

echo ""
echo "步骤2: 上传新的 server.js..."
scp $LOCAL_BACKEND_DIR/server.js root@$SERVER_IP:$BACKEND_DIR/server.js

echo ""
echo "步骤3: 上传新的 production.env..."
scp $LOCAL_BACKEND_DIR/production.env root@$SERVER_IP:$BACKEND_DIR/production.env

echo ""
echo "步骤4: 验证文件是否上传成功..."
ssh root@$SERVER_IP "cd $BACKEND_DIR && grep -n 'verifyIAPTransaction' server.js | head -3 && echo '' && grep IAP_VERIFY_STRICT production.env"

echo ""
echo "步骤5: 重启服务..."
ssh root@$SERVER_IP "cd $BACKEND_DIR && pm2 restart chongyu-backend && sleep 2 && pm2 status chongyu-backend | grep chongyu-backend"

echo ""
echo "步骤6: 检查服务日志（验证功能是否加载）..."
sleep 3
ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 20 --nostream | grep -E 'IAP_VERIFY_STRICT|Config.*IAP' || echo '未找到配置日志，可能需要等待几秒'"

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 查看服务日志: ssh root@$SERVER_IP 'pm2 logs chongyu-backend --lines 50 | grep -E \"IAP|Verify\"'"
echo "2. 运行测试: SERVER=https://api.chongyuai.com ./test_iap_verification.sh"
echo "3. 在 iOS 应用中测试真实购买"

