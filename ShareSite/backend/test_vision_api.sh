#!/bin/bash

# 视觉API积分扣除测试脚本
# 使用expect自动化SSH登录并测试

expect <<'EOF'
set timeout 30
log_user 1

spawn ssh root@172.24.42.243
expect {
    "password:" {
        send "3Qq123456.\r"
    }
    timeout {
        puts "连接超时"
        exit 1
    }
}

expect "*]#"
send "cd /var/www/chongyu-backend\r"

expect "*]#"
send "echo '========================================'\r"

expect "*]#"
send "echo '视觉API积分扣除测试'\r"

expect "*]#"
send "echo '========================================'\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '1. 检查环境配置:'\r"

expect "*]#"
send "grep 'CREDITS_PER_.*_VISION' production.env\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '2. 创建测试账户:'\r"

expect "*]#"
send "curl -s -X POST http://localhost:3000/api/wallet/init -H 'Content-Type: application/json' -d '{\"appAccountToken\":\"vision-test-002\"}'\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '3. 充值5000积分:'\r"

expect "*]#"
send "curl -s -X POST http://localhost:3000/api/wallet/balance -H 'Content-Type: application/json' -d '{\"appAccountToken\":\"vision-test-002\",\"amount\":5000}'\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '4. 调用视觉API (doubao-seed):'\r"

expect "*]#"
send "curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vision-test-002' -d '{\"model\":\"doubao-seed-1-6-vision-250815\",\"messages\":\[\{\"role\":\"user\",\"content\":\"描述一下这是什么\"\}\],\"max_tokens\":50}'\r"

expect "*]#" {
    sleep 2
}

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '5. 查看剩余积分 (应该扣除了10积分):'\r"

expect "*]#"
send "curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-002\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '6. 调用视觉API (doubao-vision-pro):'\r"

expect "*]#"
send "curl -s -X POST http://localhost:3000/api/vision -H 'Content-Type: application/json' -H 'X-App-Account-Token: vision-test-002' -d '{\"model\":\"doubao-vision-pro-32k\",\"messages\":\[\{\"role\":\"user\",\"content\":\"你好\"\}\],\"max_tokens\":20}'\r"

expect "*]#" {
    sleep 2
}

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '7. 查看最终积分 (应该再扣除了20积分):'\r"

expect "*]#"
send "curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-002\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo ''\r"

expect "*]#"
send "echo '========================================'\r"

expect "*]#"
send "echo '测试完成！'\r"

expect "*]#"
send "echo '预期结果: 5000 -> 4990 -> 4970'\r"

expect "*]#"
send "echo '========================================'\r"

expect "*]#"
send "exit\r"

expect eof
EOF

