#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << EOF
set timeout 30

puts "查看最近的完整日志（包含购买和验证）..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 200 --nostream | grep -B 2 -A 10 'E46BACD2-9BF6-44A0-8D48-E4976965B291' | tail -40"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看所有包含 transactionId '3' 或 '4' 的日志..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 300 --nostream | grep -B 3 -A 10 'transactionId.*[34]' | tail -50"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的交易记录（所有字段）..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.ref == \"3\" or .ref == \"4\")' 2>/dev/null"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

EOF

