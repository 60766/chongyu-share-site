#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

echo "=========================================="
echo "检查真实 IAP 购买验证结果"
echo "=========================================="
echo ""

expect << EOF
set timeout 30

puts "查看最近的 IAP 验证日志（最近100行）..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'IAP|Verify' | tail -30"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的交易记录（包含验证信息）..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.meta.productId != null) | {id: .id, ref: .ref, productId: .meta.productId, amount: .amount, verification: .meta.verification, at: .at}' 2>/dev/null | tail -5"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的购买请求详情..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 200 --nostream | grep -A 5 'IAP.*confirm payload' | tail -20"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

EOF

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

