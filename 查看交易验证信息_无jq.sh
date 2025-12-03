#!/bin/bash

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."

expect << 'EXPECT_SCRIPT'
set timeout 30

puts "查看交易记录（查找 transactionId 2, 3, 4）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 20 '\"ref\": \"2\"' server-data.json | head -25"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看交易记录（查找 transactionId 3）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 20 '\"ref\": \"3\"' server-data.json | head -25"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查看交易记录（查找 transactionId 4）..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -A 20 '\"ref\": \"4\"' server-data.json | head -25"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n\n查找所有包含 verification 的交易记录..."
spawn ssh root@121.40.184.29 "cd /var/www/chongyu-backend && grep -B 5 -A 10 'verification' server-data.json | tail -30"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

EXPECT_SCRIPT

