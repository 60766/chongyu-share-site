#!/bin/bash

# 虫遇后端服务器自动更新脚本（使用expect）

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."
LOCAL_FILE="/Users/lishilong/IOS开发/虫遇/虫遇/backend/server.js"

echo "🚀 开始自动更新云服务器配置..."
echo "================================"
echo ""

# 创建临时expect脚本用于SCP上传
cat > /tmp/scp_upload.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 30
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]
set local_file [lindex $argv 3]

spawn scp -o StrictHostKeyChecking=no $local_file $server_user@$server_ip:/var/www/chongyu-backend/
expect {
    "*password:" {
        send "$server_password\r"
        expect eof
    }
    eof
}
EOF

# 创建临时expect脚本用于SSH执行
cat > /tmp/ssh_restart.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]

spawn ssh -o StrictHostKeyChecking=no $server_user@$server_ip
expect {
    "*password:" {
        send "$server_password\r"
        expect "#"
        
        send "cd /var/www/chongyu-backend\r"
        expect "#"
        
        send "echo '📄 验证server.js已更新...'\r"
        expect "#"
        
        send "grep -n \"limit: '50mb'\" server.js | head -3\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        
        send "echo '🔄 重启PM2服务...'\r"
        expect "#"
        
        send "pm2 restart all\r"
        expect "#"
        
        send "sleep 2\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        
        send "echo '📊 查看服务状态...'\r"
        expect "#"
        
        send "pm2 status\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        
        send "echo '📝 最新日志...'\r"
        expect "#"
        
        send "pm2 logs --lines 20 --nostream\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EOF

chmod +x /tmp/scp_upload.exp
chmod +x /tmp/ssh_restart.exp

echo "📤 步骤1: 上传最新的server.js文件到 /var/www/chongyu-backend/ ..."
/tmp/scp_upload.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD" "$LOCAL_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 文件上传成功"
else
    echo "❌ 文件上传失败"
    rm /tmp/scp_upload.exp /tmp/ssh_restart.exp
    exit 1
fi

echo ""
echo "🔄 步骤2: 重启后端服务..."
/tmp/ssh_restart.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"

# 清理临时文件
rm /tmp/scp_upload.exp /tmp/ssh_restart.exp

echo ""
echo "✅ 服务器更新完成！"
echo ""
echo "🧪 测试端点："
echo "  - 健康检查: http://121.40.184.29:3000/health"
echo "  - 视觉API: http://121.40.184.29:3000/api/vision"
echo ""
echo "💡 提示: 现在可以在iOS应用中测试发布9张图片了！" 