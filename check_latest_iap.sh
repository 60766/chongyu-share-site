#!/bin/bash

expect << 'EOF'
set timeout 10
spawn ssh root@121.40.184.29
expect {
    "password:" {
        send "3Qq123456.\r"
        expect "# "
        send "pm2 logs chongyu-backend --lines 50 --nostream | grep -E 'IAP Verify|confirm payload|transactionId|productId' | tail -20\r"
        expect "# "
        send "exit\r"
        expect eof
    }
}
EOF

