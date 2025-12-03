#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看最新的 IAP 验证日志..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'IAP|Verify' | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的购买请求详情..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 150 --nostream | grep -B 2 -A 20 'confirm payload' | tail -50"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的交易记录（查找最新的 transactionId）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && tail -500 server-data.json | grep -B 5 -A 30 'productId.*100energy' | tail -40"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

