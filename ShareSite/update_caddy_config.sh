#!/bin/bash

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."
WEBSITE_DIR="/var/www/share-site"

echo "🚀 更新Caddy配置..."
echo "================================"
echo ""

# 创建新的Caddy配置文件内容
cat > /tmp/caddyfile_new << 'EOF'
api.chongyuai.com {
    log {
        output file /var/log/caddy/access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
  tls qiurao5@gmail.com {
    protocols tls1.2 tls1.3
  }
}

share.chongyuai.com {
    log {
        output file /var/log/caddy/share-access.log {
            roll_size 10mb
            roll_keep 5
        }
        format json
    }
    root * /var/www/share-site
    encode zstd gzip
    file_server
    try_files {path} /index.html
    header Cache-Control "no-cache, no-store, must-revalidate"
    header Pragma "no-cache"
    header Expires "0"
}
EOF

# 创建expect脚本
cat > /tmp/update_caddy.exp << 'EXPEOF'
#!/usr/bin/expect -f
set timeout 60
set server_ip [lindex $argv 0]
set server_user [lindex $argv 1]
set server_password [lindex $argv 2]

spawn scp -o StrictHostKeyChecking=no /tmp/caddyfile_new $server_user@$server_ip:/tmp/caddyfile_new
expect {
    "*password:" {
        send "$server_password\r"
        expect eof
    }
    eof
}
EXPEOF

chmod +x /tmp/update_caddy.exp

echo "📤 上传新配置到服务器..."
/tmp/update_caddy.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"

# 创建SSH执行脚本
cat > /tmp/apply_config.exp << 'EXPEOF'
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
        
        send "cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup\r"
        expect "#"
        
        send "cp /tmp/caddyfile_new /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "caddy validate --config /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "systemctl reload caddy\r"
        expect "#"
        
        send "sleep 2\r"
        expect "#"
        
        send "echo '=== 新配置内容 ==='\r"
        expect "#"
        send "cat /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EXPEOF

chmod +x /tmp/apply_config.exp

echo "⚙️  应用新配置..."
/tmp/apply_config.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"

# 清理临时文件
rm /tmp/update_caddy.exp /tmp/apply_config.exp /tmp/caddyfile_new

echo ""
echo "✅ Caddy配置已更新！"

