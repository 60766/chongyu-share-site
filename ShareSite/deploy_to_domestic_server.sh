#!/bin/bash

# 网站部署到国内服务器脚本

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."
WEBSITE_DIR="/var/www/share-site"
LOCAL_DIR="/Users/lishilong/IOS开发/虫遇/虫遇/ShareSite/ShareSite"

echo "🚀 开始部署网站到国内服务器..."
echo "================================"
echo ""

# 创建临时expect脚本用于上传文件
cat > /tmp/upload_website.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 300
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]
set local_dir [lindex $argv 3]
set remote_dir [lindex $argv 4]

spawn rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no" $local_dir/ $server_user@$server_ip:$remote_dir/
expect {
    "*password:" {
        send "$server_password\r"
        expect eof
    }
    eof
}
EOF

# 创建临时expect脚本用于SSH配置
cat > /tmp/configure_server.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 60
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]
set website_dir [lindex $argv 3]

spawn ssh -o StrictHostKeyChecking=no $server_user@$server_ip
expect {
    "*password:" {
        send "$server_password\r"
        expect "#"
        
        send "echo '=== 1. 创建网站目录 ==='\r"
        expect "#"
        send "mkdir -p $website_dir\r"
        expect "#"
        
        send "echo '=== 2. 备份当前Caddy配置 ==='\r"
        expect "#"
        send "cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%Y%m%d_%H%M%S)\r"
        expect "#"
        
        send "echo '=== 3. 更新Caddy配置 ==='\r"
        expect "#"
        send "cat > /tmp/caddy_config.txt << 'CADDYEOF'\r"
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
        
        send "cat /tmp/caddy_config.txt > /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "echo '=== 4. 验证Caddy配置 ==='\r"
        expect "#"
        send "cat /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 5. 设置文件权限 ==='\r"
        expect "#"
        send "chown -R root:root $website_dir\r"
        expect "#"
        send "chmod -R 755 $website_dir\r"
        expect "#"
        
        send "echo '=== 6. 验证文件 ==='\r"
        expect "#"
        send "ls -la $website_dir/ | head -10\r"
        expect "#"
        
        send "echo '=== 7. 重新加载Caddy配置 ==='\r"
        expect "#"
        send "caddy validate --config /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "systemctl reload caddy\r"
        expect "#"
        
        send "sleep 2\r"
        expect "#"
        
        send "echo '=== 8. 检查Caddy状态 ==='\r"
        expect "#"
        send "systemctl status caddy --no-pager | head -5\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EOF

chmod +x /tmp/upload_website.exp
chmod +x /tmp/configure_server.exp

echo "📤 步骤1: 上传网站文件到服务器..."
/tmp/upload_website.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD" "$LOCAL_DIR" "$WEBSITE_DIR"

if [ $? -eq 0 ]; then
    echo "✅ 文件上传成功"
else
    echo "❌ 文件上传失败"
    rm /tmp/upload_website.exp /tmp/configure_server.exp
    exit 1
fi

echo ""
echo "⚙️  步骤2: 配置Caddy和服务器..."
/tmp/configure_server.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD" "$WEBSITE_DIR"

# 清理临时文件
rm /tmp/upload_website.exp /tmp/configure_server.exp

echo ""
echo "✅ 部署完成！"
echo ""
echo "📋 下一步："
echo "  1. 在阿里云DNS中，将 share.chongyuai.com 的CNAME记录改为A记录，指向 121.40.184.29"
echo "  2. 等待DNS解析生效（通常几分钟）"
echo "  3. 访问 https://share.chongyuai.com 验证"
echo ""

