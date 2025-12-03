#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << EOF
set timeout 30

puts "查看所有 IAP Verify 相关日志（最近500行）..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 500 --nostream | grep 'IAP Verify' | tail -20"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看 transactionId 2, 3, 4 的完整日志..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 500 --nostream | grep -A 15 'transactionId.*\"2\"' | tail -20"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看交易记录中的验证信息..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.ref == \"2\" or .ref == \"3\" or .ref == \"4\") | {ref: .ref, productId: .meta.productId, verification: .meta.verification}' 2>/dev/null"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的完整购买流程日志..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 500 --nostream | grep -B 5 -A 15 'E46BACD2.*100energy' | grep -E 'IAP|Verify|transactionId|hasReceipt' | tail -30"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

EOF

