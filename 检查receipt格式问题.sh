#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看最近的购买请求日志（查看 receipt 格式）..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 1000 --nostream | grep -B 2 -A 30 'E46BACD2.*100energy' | grep -A 30 'confirm payload' | head -40"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看后端代码中 receipt 的处理逻辑..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 10 'receipt.*JSON.parse' server.js | head -15"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

