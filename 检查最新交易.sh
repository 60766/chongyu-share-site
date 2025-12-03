#!/bin/bash

# 检查最新的 IAP 交易记录
echo "正在检查最新的 IAP 交易记录..."
echo ""

expect << 'EOF'
set timeout 10
spawn ssh root@121.40.184.29
expect {
    "password:" {
        send "3Qq123456.\r"
        expect "# "
        send "cd /var/www/chongyu-backend && tail -100 server.log 2>/dev/null | grep -A 5 -B 5 'IAP Verify' | tail -30\r"
        expect "# "
        send "exit\r"
        expect eof
    }
    timeout {
        puts "连接超时"
        exit 1
    }
}
EOF

