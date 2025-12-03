#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << EOF
set timeout 30

puts "查看最近的交易记录（所有字段）..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[-10:]' 2>/dev/null"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查找包含 productId 的交易..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.meta.productId != null)' 2>/dev/null | tail -5"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

EOF

