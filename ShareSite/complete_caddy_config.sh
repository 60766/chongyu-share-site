#!/bin/bash

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

echo "🚀 完成Caddy配置..."
echo "================================"
echo ""

# 创建完整的Caddy配置文件
cat > /tmp/complete_caddyfile.txt << 'EOF'
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

# 上传配置文件
expect << 'EXPEOF'
set timeout 30
spawn scp -o StrictHostKeyChecking=no /tmp/complete_caddyfile.txt root@121.40.184.29:/tmp/complete_caddyfile.txt
expect {
    "*password:" {
        send "3Qq123456.\r"
        expect eof
    }
    eof
}
EXPEOF

# 应用配置
expect << 'EXPEOF'
set timeout 60
spawn ssh -o StrictHostKeyChecking=no root@121.40.184.29
expect {
    "*password:" {
        send "3Qq123456.\r"
        expect "#"
        
        send "cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup\r"
        expect "#"
        
        send "cp /tmp/complete_caddyfile.txt /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "caddy validate --config /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "systemctl reload caddy\r"
        expect "#"
        
        send "sleep 2\r"
        expect "#"
        
        send "echo '=== 验证配置 ==='\r"
        expect "#"
        send "grep -A 5 'share.chongyuai.com' /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EXPEOF

rm /tmp/complete_caddyfile.txt

echo ""
echo "✅ 配置完成！"

