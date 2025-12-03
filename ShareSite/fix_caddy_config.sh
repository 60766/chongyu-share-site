#!/bin/bash

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

# 直接在服务器上创建配置
cat > /tmp/fix_caddy.exp << 'EXPEOF'
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
        send "    root * /var/www/share-site\r"
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
        
        send "cat /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EXPEOF

chmod +x /tmp/fix_caddy.exp
/tmp/fix_caddy.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"
rm /tmp/fix_caddy.exp

echo ""
echo "✅ 配置完成！"

