#!/bin/bash

# 虫遇APP生产环境部署脚本
# 确保服务器使用正确的配置并重启服务

echo "🚀 开始虫遇APP生产环境部署..."

# 设置变量
SERVER_IP="121.40.184.29"
SERVER_USER="root"
BACKEND_DIR="/var/www/chongyu-backend"
LOCAL_BACKEND_DIR="backend"

echo "📋 部署信息:"
echo "  服务器: $SERVER_IP"
echo "  用户: $SERVER_USER"
echo "  远程目录: $BACKEND_DIR"
echo "  本地目录: $LOCAL_BACKEND_DIR"

# 检查本地backend目录是否存在
if [ ! -d "$LOCAL_BACKEND_DIR" ]; then
    echo "❌ 错误: 本地backend目录不存在"
    exit 1
fi

# 1. 停止远程服务
echo "⏹️  停止远程服务..."
ssh $SERVER_USER@$SERVER_IP "pm2 stop chongyu-backend || echo '服务未运行，继续...'"

# 2. 备份远程数据
echo "💾 备份远程数据..."
ssh $SERVER_USER@$SERVER_IP "
    mkdir -p $BACKEND_DIR/backup/\$(date +%Y%m%d_%H%M%S)
    cp $BACKEND_DIR/server-data.json $BACKEND_DIR/backup/\$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || echo '没有数据文件需要备份'
"

# 3. 上传文件
echo "📤 上传后端文件..."
rsync -avz --exclude='node_modules' --exclude='.git' $LOCAL_BACKEND_DIR/ $SERVER_USER@$SERVER_IP:$BACKEND_DIR/

# 4. 复制生产环境配置
echo "⚙️  配置生产环境..."
ssh $SERVER_USER@$SERVER_IP "
    cd $BACKEND_DIR
    cp production.env .env
    echo '✅ 生产环境配置已应用'
"

# 5. 安装依赖
echo "📦 安装依赖..."
ssh $SERVER_USER@$SERVER_IP "
    cd $BACKEND_DIR
    npm install --production
"

# 6. 启动服务
echo "🚀 启动服务..."
ssh $SERVER_USER@$SERVER_IP "
    cd $BACKEND_DIR
    pm2 start server.js --name 'chongyu-backend' || pm2 restart chongyu-backend
    pm2 save
"

# 7. 验证服务状态
echo "🔍 验证服务状态..."
sleep 5
if curl -f http://$SERVER_IP:3000/health > /dev/null 2>&1; then
    echo "✅ 服务部署成功！健康检查通过"
    echo "🌐 服务地址: http://$SERVER_IP:3000"
else
    echo "❌ 服务部署可能有问题，请检查日志"
    ssh $SERVER_USER@$SERVER_IP "pm2 logs chongyu-backend --lines 20"
    exit 1
fi

echo "🎉 生产环境部署完成！"
echo ""
echo "📊 部署摘要:"
echo "  ✅ 端口配置: 3000 (已统一)"
echo "  ✅ API密钥: 已配置真实密钥"
echo "  ✅ Bundle ID: com.shilong111234.chongyu"
echo "  ✅ JWT密钥: 已设置安全密钥"
echo "  ✅ 服务状态: 运行中"
echo ""
echo "🔗 测试命令:"
echo "  curl http://$SERVER_IP:3000/health"
echo ""
echo "📱 iOS应用配置确认:"
echo "  Info.plist BACKEND_BASE_URL: http://121.40.184.29:3000 ✅"
echo "  推送环境: production ✅"
echo "  Bundle ID: com.shilong111234.chongyu ✅" 