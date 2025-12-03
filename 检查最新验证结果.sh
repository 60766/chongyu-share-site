#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看最新的购买和验证日志..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'IAP|Verify' | tail -20"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的交易记录（transactionId 5）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 30 '\"ref\": \"5\"' server-data.json | grep -A 20 'verification'"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

