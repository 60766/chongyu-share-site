#!/bin/bash

# 虫遇后端服务器快速更新脚本
# 用于更新云服务器（121.40.184.29）上的配置

echo "🚀 虫遇后端服务器更新脚本"
echo "================================"
echo ""

# 云服务器信息
SERVER_IP="121.40.184.29"
SERVER_USER="root"  # 根据实际情况修改
BACKEND_PATH="/root/chongyu-backend"  # 根据实际情况修改

echo "📡 目标服务器: ${SERVER_USER}@${SERVER_IP}"
echo "📂 后端路径: ${BACKEND_PATH}"
echo ""

# 确认是否继续
read -p "是否继续更新服务器配置？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 取消更新"
    exit 0
fi

echo "📤 上传server.js文件..."
scp backend/server.js ${SERVER_USER}@${SERVER_IP}:${BACKEND_PATH}/

if [ $? -ne 0 ]; then
    echo "❌ 文件上传失败"
    exit 1
fi

echo "✅ 文件上传成功"
echo ""

echo "🔄 重启后端服务..."
ssh ${SERVER_USER}@${SERVER_IP} << 'EOF'
cd /root/chongyu-backend
pm2 restart chongyu-backend
pm2 logs chongyu-backend --lines 20
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 服务器更新完成！"
    echo "🌐 测试地址: http://121.40.184.29:3000/health"
else
    echo ""
    echo "❌ 服务重启失败，请手动检查服务器"
    exit 1
fi 