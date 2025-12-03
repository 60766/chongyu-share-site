#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << EOF
set timeout 30

puts "查看最近的 IAP 交易记录（包含验证信息）..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.meta.productId != null) | {id: .id, ref: .ref, productId: .meta.productId, amount: .amount, verification: .meta.verification, at: .at}' 2>/dev/null | tail -20"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看所有 IAP 相关日志（最近100行）..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'IAP|Verify' | tail -30"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

EOF

