#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

echo "=========================================="
echo "检查 Sandbox 环境测试结果"
echo "=========================================="
echo ""

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看最新的 IAP 验证日志（查找 JWT 格式的验证）..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 200 --nostream | grep -E 'IAP|Verify' | tail -40"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的购买请求（检查 receipt 格式）..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 200 --nostream | grep -B 2 -A 15 'confirm payload' | grep -A 15 'receiptPreview' | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查找 JWT 格式的 receipt（eyJ 开头）..."
spawn ssh root@121.40.184.29 "pm2 logs chongyu-backend --lines 500 --nostream | grep -B 5 -A 20 'eyJ' | tail -40"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看最新的交易记录（查找 format: jwt）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && tail -1000 server-data.json | grep -B 10 -A 10 '\"format\": \"jwt\"' | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看所有包含 verification 的交易（最后5条）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && tail -2000 server-data.json | grep -B 5 -A 15 'verification' | tail -50"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
echo ""
echo "关键检查点："
echo "1. Receipt 格式：应该是 'eyJ...' 开头（JWT 格式）"
echo "2. 验证日志：应该看到 '✅ 交易验证成功'（不是'对象格式'）"
echo "3. 交易记录：format 应该是 'jwt'（不是 'object'）"

