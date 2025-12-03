#!/bin/bash

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."

cat > /tmp/check_files.exp << 'EOF'
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
        
        send "echo '=== 检查 /var/www/chongyu 目录 ==='\r"
        expect "#"
        send "ls -la /var/www/chongyu/\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 查找所有HTML文件 ==='\r"
        expect "#"
        send "find /var/www -name '*.html' -type f 2>/dev/null\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 检查是否有index.html ==='\r"
        expect "#"
        send "find /var/www -name 'index.html' -type f 2>/dev/null\r"
        expect "#"
        
        send "echo ''\r"
        expect "#"
        send "echo '=== 检查chongyu目录内容 ==='\r"
        expect "#"
        send "find /var/www/chongyu -type f 2>/dev/null | head -20\r"
        expect "#"
        
        send "exit\r"
        expect eof
    }
}
EOF

chmod +x /tmp/check_files.exp
/tmp/check_files.exp "$SERVER_IP" "$SERVER_USER" "$SERVER_PASSWORD"
rm /tmp/check_files.exp

