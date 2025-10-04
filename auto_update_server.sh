#!/bin/bash

# 虫遇后端服务器自动更新脚本
# 自动更新云服务器（121.40.184.29）上的配置

echo "🚀 开始自动更新云服务器配置..."
echo "================================"

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

# 检查是否安装了sshpass
if ! command -v sshpass &> /dev/null; then
    echo "📦 安装sshpass工具..."
    brew install hudochenkov/sshpass/sshpass
fi

echo ""
echo "📤 步骤1: 上传最新的server.js文件..."
sshpass -p "${SERVER_PASSWORD}" scp -o StrictHostKeyChecking=no \
    /Users/lishilong/IOS开发/虫遇/虫遇/backend/server.js \
    ${SERVER_USER}@${SERVER_IP}:/root/chongyu-backend/

if [ $? -ne 0 ]; then
    echo "❌ 文件上传失败，尝试其他路径..."
    # 尝试其他可能的路径
    sshpass -p "${SERVER_PASSWORD}" scp -o StrictHostKeyChecking=no \
        /Users/lishilong/IOS开发/虫遇/虫遇/backend/server.js \
        ${SERVER_USER}@${SERVER_IP}:/home/chongyu/backend/
fi

echo "✅ 文件上传成功"
echo ""

echo "🔄 步骤2: 重启后端服务..."
sshpass -p "${SERVER_PASSWORD}" ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
# 查找server.js文件位置
if [ -f "/root/chongyu-backend/server.js" ]; then
    cd /root/chongyu-backend
elif [ -f "/home/chongyu/backend/server.js" ]; then
    cd /home/chongyu/backend
else
    echo "❌ 找不到server.js文件"
    exit 1
fi

echo "📂 当前目录: $(pwd)"
echo "📄 验证server.js已更新..."
grep -n "limit: '50mb'" server.js | head -5

echo ""
echo "🔄 重启PM2服务..."
pm2 restart all || pm2 restart chongyu-backend

echo ""
echo "📊 查看服务状态..."
pm2 status

echo ""
echo "📝 最新日志（最后20行）..."
pm2 logs --lines 20 --nostream
ENDSSH

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 服务器更新完成！"
    echo ""
    echo "🧪 测试端点："
    echo "  - 健康检查: http://121.40.184.29:3000/health"
    echo "  - 视觉API: http://121.40.184.29:3000/api/vision"
    echo ""
    echo "💡 提示: 现在可以在iOS应用中测试发布9张图片了！"
else
    echo ""
    echo "❌ 服务更新失败，请检查错误信息"
    exit 1
fi 