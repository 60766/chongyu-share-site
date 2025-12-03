#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看交易记录中的验证信息（transactionId 2, 3, 4）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && cat server-data.json | jq '.transactions[] | select(.ref == \"2\" or .ref == \"3\" or .ref == \"4\") | {ref: .ref, productId: .meta.productId, verification: .meta.verification, amount: .amount}'"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看所有包含 productId 的交易（最后5条）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && cat server-data.json | jq '[.transactions[] | select(.meta.productId != null)] | .[-5:] | .[] | {ref: .ref, productId: .meta.productId, verification: .meta.verification}'"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

