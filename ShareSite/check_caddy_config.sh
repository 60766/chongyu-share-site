#!/bin/bash

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

cat > /tmp/check_caddy.exp << 'EOF'
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
        
        send "echo '=== 检查Caddy配置 ==='\r"
        expect "#"
        send "cat /etc/caddy/Caddyfile\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 检查Caddy状态 ==='\r"
        expect "#"
        send "systemctl status caddy --no-pager | head -10\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 检查网站目录 ==='\r"
        expect "#"
        send "ls -la /var/www/share-site/ 2>/dev/null || echo '目录不存在或为空'\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EOF

chmod +x /tmp/check_caddy.exp
/tmp/check_caddy.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"
rm /tmp/check_caddy.exp

