#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "检查服务状态..."
spawn ssh root@121.40.184.29 "pm2 status chongyu-backend"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的错误日志..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'error|Error|ERROR|502|崩溃|crash' | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的购买和验证日志..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 200 --nostream | grep -E 'IAP|Verify|purchase/confirm' | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看服务器错误日志..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 200 --nostream | tail -50"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

