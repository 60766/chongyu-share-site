Last login: Sun Sep 21 06:24:49 on ttys001
lishilong@lishilongdeMacBook-Air ~ % ssh root@121.40.184.29
root@121.40.184.29's password: 
Last login: Sun Sep 21 06:25:06 2025 from 36.24.59.215

Welcome to Alibaba Cloud Elastic Compute Service !

[root@iZbp13q0phv2mgyqtz083lZ ~]# # 测试本地连接
[root@iZbp13q0phv2mgyqtz083lZ ~]# curl http://localhost:3000
{"message":"🐛 虫遇APP后端服务正在运行","version":"1.0.0","status":"running","timestamp":"2025-09-20T22:27:06.107Z","node_version":"v14.21.3"}[root@iZbp13q0phv2mgyqtz083lZ ~]# 
[root@iZbp13q0phv2mgyqtz083lZ ~]# # 查看服务日志
[root@iZbp13q0phv2mgyqtz083lZ ~]# pm2 logs chongyu-backend --lines 10
[TAILING] Tailing last 10 lines for [chongyu-backend] process (change the value with --lines option)
/root/.pm2/logs/chongyu-backend-error.log last 10 lines:
/root/.pm2/logs/chongyu-backend-out.log last 10 lines:
0|chongyu- | 🚀 虫遇APP后端服务已启动
0|chongyu- | 📡 服务地址: http://0.0.0.0:3000
0|chongyu- | 🌍 公网访问: http://121.40.184.29:3000




#!/bin/bash

# 虫遇APP后端一键部署脚本
# 使用方法: chmod +x deploy.sh && ./deploy.sh

echo "🚀 开始部署虫遇APP后端..."

# 1. 更新系统
echo "📦 更新系统软件包..."
sudo yum update -y

# 2. 安装Node.js 18
echo "📦 安装Node.js 18..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 3. 安装PM2进程管理器
echo "📦 安装PM2进程管理器..."
sudo npm install -g pm2

# 4. 创建应用目录
echo "📁 创建应用目录..."
sudo mkdir -p /var/www/chongyu-backend
sudo chown $(whoami):$(whoami) /var/www/chongyu-backend

# 5. 进入应用目录
cd /var/www/chongyu-backend

# 6. 复制文件（如果是本地部署）
if [ -f "./package.json" ]; then
    echo "📋 检测到本地文件，直接使用..."
else
    echo "❌ 请先将backend文件夹上传到服务器"
    exit 1
fi

# 7. 安装依赖
echo "📦 安装Node.js依赖..."
npm install --production

# 8. 复制环境配置
if [ -f "./production.env" ]; then
    cp ./production.env ./.env
    echo "✅ 环境配置已复制"
else
    echo "⚠️  请手动配置.env文件"
fi

# 9. 启动应用
echo "🚀 启动应用..."
pm2 start server.js --name "chongyu-backend"
pm2 save
pm2 startup

# 10. 配置防火墙
echo "🔒 配置防火墙..."
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

# 11. 显示状态
echo "✅ 部署完成！"
echo "📊 应用状态："
pm2 status
echo ""
echo "🌐 服务器地址：http://$(curl -s ifconfig.me):3000"
echo "🔍 健康检查：http://$(curl -s ifconfig.me):3000/health"
echo ""
echo "📝 常用命令："
echo "  查看日志: pm2 logs chongyu-backend"
echo "  重启应用: pm2 restart chongyu-backend"
echo "  停止应用: pm2 stop chongyu-backend" 