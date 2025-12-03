#!/usr/bin/expect -f
set timeout 30

puts "=== 步骤1: 检查服务器当前配置 ==="
spawn ssh root@47.94.254.130 "cd /var/www/chongyu-backend && echo '当前配置:' && cat production.env | grep CREDITS || echo '未找到CREDITS配置'"
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n=== 步骤2: 上传新的server.js ==="
spawn scp server.js root@47.94.254.130:/var/www/chongyu-backend/
expect {
    "password:" {
        send "3Qq123456.\r"
        exp_continue
    }
    eof
}

puts "\n=== 步骤3: 更新配置并重启服务 ==="
spawn ssh root@47.94.254.130
expect {
    "password:" {
        send "3Qq123456.\r"
        expect "#"
        
        send "cd /var/www/chongyu-backend\r"
        expect "#"
        
        send "cp production.env production.env.backup_\$(date +%Y%m%d_%H%M%S)\r"
        expect "#"
        
        send "if grep -q '^CREDITS_PER_1K_TOKENS=' production.env; then sed -i 's/^CREDITS_PER_1K_TOKENS=.*/CREDITS_PER_1K_TOKENS=11/' production.env; else echo 'CREDITS_PER_1K_TOKENS=11' >> production.env; fi\r"
        expect "#"
        
        send "echo '\n新配置内容:'\r"
        expect "#"
        send "cat production.env\r"
        expect "#"
        
        send "pm2 restart chongyu-backend --update-env\r"
        expect "#"
        
        send "sleep 3\r"
        expect "#"
        
        send "echo '\n验证日志:'\r"
        expect "#"
        send "pm2 logs chongyu-backend --lines 20 --nostream | grep -E 'CREDITS_PER_1K_TOKENS|Config' || echo '检查完成'\r"
        expect "#"
        
        send "exit\r"
    }
}
expect eof

puts "\n✅ 部署完成！"
