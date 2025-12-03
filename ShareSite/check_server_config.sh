#!/bin/bash

# 检查服务器配置脚本

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

echo "🔍 开始检查服务器配置..."
echo "================================"
echo ""

# 创建临时expect脚本
cat > /tmp/check_config.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 30
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]

spawn ssh -o StrictHostKeyChecking=no $server_user@$server_ip
expect {
    "*password:" {
        send "$server_password\r"
        expect "#"
        
        send "echo '=== 1. 检查Caddy配置 ==='\r"
        expect "#"
        send "cat /etc/caddy/Caddyfile 2>/dev/null || echo 'Caddyfile不存在'\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 2. 检查Caddy服务状态 ==='\r"
        expect "#"
        send "systemctl status caddy --no-pager | head -10\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 3. 检查可能的网站目录 ==='\r"
        expect "#"
        send "ls -la /var/www/ 2>/dev/null || echo '/var/www/ 不存在'\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 4. 查找HTML文件 ==='\r"
        expect "#"
        send "find /var/www -name '*.html' -type f 2>/dev/null | head -10\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 5. 检查Nginx配置（如果存在）==='\r"
        expect "#"
        send "ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo 'Nginx未安装或未配置'\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 6. 检查端口监听 ==='\r"
        expect "#"
        send "netstat -tlnp | grep -E ':80|:443' | head -5\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EOF

chmod +x /tmp/check_config.exp
/tmp/check_config.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"

# 清理临时文件
rm /tmp/check_config.exp

echo ""
echo "✅ 检查完成！"

