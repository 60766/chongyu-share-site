#!/bin/bash
# 虫遇后端生产环境重启脚本
# 用于应用新的 production.env 配置

echo "🔄 准备重启虫遇生产环境后端..."
echo ""

# 检查是否在backend目录
if [ ! -f "production.env" ]; then
    echo "❌ 错误: 请在backend目录下运行此脚本"
    exit 1
fi

# 检查现有进程
echo "1. 检查现有进程..."
OLD_PID=$(ps aux | grep "node.*server.js" | grep -v grep | awk '{print $2}')
if [ -n "$OLD_PID" ]; then
    echo "   发现运行中的进程: PID=$OLD_PID"
    OLD_PORT=$(lsof -p $OLD_PID -iTCP -sTCP:LISTEN | grep -o ':\d*' | grep -o '\d*' | head -1)
    if [ -n "$OLD_PORT" ]; then
        echo "   监听端口: $OLD_PORT"
    fi
fi

# 检查PM2是否安装
if ! command -v pm2 &> /dev/null; then
    echo ""
    echo "⚠️  PM2未安装，将使用手动重启方式"
    echo ""
    
    # 手动重启
    echo "2. 停止旧进程..."
    if [ -n "$OLD_PID" ]; then
        kill $OLD_PID
        echo "   已发送停止信号到进程 $OLD_PID"
        sleep 2
        
        # 确认进程已停止
        if ps -p $OLD_PID > /dev/null 2>&1; then
            echo "   进程未响应，强制停止..."
            kill -9 $OLD_PID
        fi
    fi
    
    echo ""
    echo "3. 启动新进程（使用production.env）..."
    # 确保使用production.env
    if [ ! -f "production.env" ]; then
        echo "   ❌ production.env 不存在！"
        exit 1
    fi
    
    # 后台启动，重定向日志
    nohup node server.js > server.log 2>&1 &
    NEW_PID=$!
    echo "   ✅ 服务器已后台启动，PID=$NEW_PID"
    
    sleep 3
    echo ""
    echo "4. 验证服务状态..."
    if ps -p $NEW_PID > /dev/null 2>&1; then
        echo "   ✅ 进程运行正常"
        NEW_PORT=$(lsof -p $NEW_PID -iTCP -sTCP:LISTEN 2>/dev/null | grep -o ':\d*' | grep -o '\d*' | head -1)
        if [ -n "$NEW_PORT" ]; then
            echo "   监听端口: $NEW_PORT"
        fi
    else
        echo "   ❌ 进程启动失败！"
    fi
    
    echo ""
    echo "📋 最新日志:"
    tail -n 20 server.log
else
    # 使用PM2重启
    echo ""
    echo "2. 使用PM2重启..."
    pm2 restart chongyu-production
    
    sleep 2
    echo ""
    echo "3. 验证服务状态..."
    pm2 list | grep chongyu
    
    echo ""
    echo "4. 检查最新日志..."
    pm2 logs chongyu-production --lines 20 --nostream
fi

echo ""
echo "🎉 重启完成！"
echo ""
echo "📊 验证新配置:"
echo "  - 查看日志: pm2 logs chongyu-production"
echo "  - 预期看到: CREDITS_PER_1K_TOKENS = 13"
echo ""
echo "🧪 测试建议:"
echo "  1. 生成1篇帖子（约2000 tokens）"
echo "  2. 预期消耗: 26虫洞币（旧版是200）"
echo "  3. 648币可生成约25篇（理论69篇）"
echo ""

