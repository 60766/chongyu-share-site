#!/bin/bash

# 查看服务器 IAP 验证日志（自动输入密码版本）

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

echo "=========================================="
echo "查看服务器 IAP 验证日志"
echo "=========================================="
echo ""

expect << EOF
set timeout 30

puts "查看最近的 IAP 验证日志（最近50行）..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 50 --nostream | grep -E 'IAP|Verify'"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看配置日志..."
spawn ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'Config.*IAP|IAP_VERIFY_STRICT'"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最近的交易记录（包含验证信息）..."
spawn ssh root@$SERVER_IP "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.meta.productId != null) | {ref: .ref, productId: .meta.productId, verification: .meta.verification, at: .at}' 2>/dev/null | tail -10"
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
echo "日志查看完成"
echo "=========================================="

