#!/bin/bash

# 添加网站配置到国内服务器（修复版）

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."
WEBSITE_DIR="/var/www/share-site"

echo "🚀 开始添加网站配置..."
echo "================================"
echo ""

# 创建临时expect脚本
cat > /tmp/add_config.exp << 'EXPEOF'
#!/usr/bin/expect -f
set timeout 300
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]
set website_dir [lindex $argv 3]

spawn ssh -o StrictHostKeyChecking=no $server_user@$server_ip
expect {
    "*password:" {
        send "$server_password\r"
        expect "#"
        
        send "mkdir -p $website_dir\r"
        expect "#"
        
        send "cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup\r"
        expect "#"
        
        send "cat > /etc/caddy/Caddyfile << 'CADDYEOF'\r"
        expect "#"
        send "api.chongyuai.com {\r"
        expect "#"
        send "    log {\r"
        expect "#"
        send "        output file /var/log/caddy/access.log {\r"
        expect "#"
        send "            roll_size 10mb\r"
        expect "#"
        send "            roll_keep 5\r"
        expect "#"
        send "        }\r"
        expect "#"
        send "        format json\r"
        expect "#"
        send "    }\r"
        expect "#"
        send "  encode zstd gzip\r"
        expect "#"
        send "  reverse_proxy 127.0.0.1:3000\r"
        expect "#"
        send "  tls qiurao5@gmail.com {\r"
        expect "#"
        send "    protocols tls1.2 tls1.3\r"
        expect "#"
        send "  }\r"
        expect "#"
        send "}\r"
        expect "#"
        send "\r"
        expect "#"
        send "share.chongyuai.com {\r"
        expect "#"
        send "    log {\r"
        expect "#"
        send "        output file /var/log/caddy/share-access.log {\r"
        expect "#"
        send "            roll_size 10mb\r"
        expect "#"
        send "            roll_keep 5\r"
        expect "#"
        send "        }\r"
        expect "#"
        send "        format json\r"
        expect "#"
        send "    }\r"
        expect "#"
        send "    root * $website_dir\r"
        expect "#"
        send "    encode zstd gzip\r"
        expect "#"
        send "    file_server\r"
        expect "#"
        send "    try_files {path} /index.html\r"
        expect "#"
        send "    header Cache-Control \"no-cache, no-store, must-revalidate\"\r"
        expect "#"
        send "    header Pragma \"no-cache\"\r"
        expect "#"
        send "    header Expires \"0\"\r"
        expect "#"
        send "}\r"
        expect "#"
        send "CADDYEOF\r"
        expect "#"
        
        send "caddy validate --config /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "systemctl reload caddy\r"
        expect "#"
        
        send "sleep 2\r"
        expect "#"
        
        send "systemctl status caddy --no-pager | head -5\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EXPEOF

chmod +x /tmp/add_config.exp

echo "⚙️  正在配置Caddy..."
/tmp/add_config.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD" "$WEBSITE_DIR"

# 清理临时文件
rm /tmp/add_config.exp

echo ""
echo "✅ Caddy配置已添加！"
echo ""
echo "📋 下一步："
echo "  1. 上传网站文件到服务器"
echo "  2. 更新域名解析"
echo ""

