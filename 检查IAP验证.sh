#!/bin/bash

# 检查 IAP 验证日志
echo "正在连接服务器检查 IAP 验证日志..."
echo ""

expect << 'EOF'
set timeout 10
spawn ssh root@121.40.184.29
expect {
    "password:" {
        send "3Qq123456.\r"
        expect "# "
        send "pm2 logs chongyu-backend --lines 200 --nostream | grep -E 'IAP|Verify|purchase/confirm' | tail -50\r"
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

