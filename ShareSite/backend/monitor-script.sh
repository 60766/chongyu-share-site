#!/bin/bash

# 虫遇后端监控脚本
echo "🔍 虫遇后端服务监控报告 - $(date)"
echo "=================================="

# 1. 检查服务状态
echo "📊 PM2服务状态："
pm2 list | grep chongyu-backend

# 2. 检查端口占用
echo ""
echo "🔌 端口3000状态："
netstat -tlnp | grep :3000

# 3. 测试API健康检查
echo ""
echo "🏥 API健康检查："
curl -s http://localhost:3000/health | jq '.' 2>/dev/null || curl -s http://localhost:3000/health

# 4. 检查最近的错误日志
echo ""
echo "🚨 最近10条错误日志："
pm2 logs chongyu-backend --err --lines 10

# 5. 内存和CPU使用情况
echo ""
echo "💻 系统资源使用："
pm2 monit --no-colors | head -20

echo ""
echo "✅ 监控完成" 