#!/bin/bash

# 部署 IAP 验证功能到服务器（自动输入密码版本）
# 使用方法：./部署IAP验证功能_自动.sh

set -e

SERVER_IP="121.40.184.29"
SSH_PASSWORD="3Qq123456."
BACKEND_DIR="/var/www/chongyu-backend"
LOCAL_BACKEND_DIR="backend"

echo "=========================================="
echo "部署 IAP 验证功能到服务器"
echo "=========================================="
echo "服务器: $SERVER_IP"
echo "后端目录: $BACKEND_DIR"
echo ""

# 检查本地文件是否存在
if [ ! -f "$LOCAL_BACKEND_DIR/server.js" ]; then
    echo "❌ 错误: 找不到 $LOCAL_BACKEND_DIR/server.js"
    exit 1
fi

if [ ! -f "$LOCAL_BACKEND_DIR/production.env" ]; then
    echo "❌ 错误: 找不到 $LOCAL_BACKEND_DIR/production.env"
    exit 1
fi

echo "✅ 本地文件检查通过"
echo ""

# 检查是否安装了 expect
if ! command -v expect &> /dev/null; then
    echo "❌ 错误: 需要安装 expect 工具"
    echo "安装方法: brew install expect"
    exit 1
fi

# 使用 expect 自动输入密码
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

expect << EOF
set timeout 30

# 备份服务器上的文件
spawn ssh root@$SERVER_IP "cd $BACKEND_DIR && cp server.js server.js.backup.$BACKUP_TIMESTAMP && cp production.env production.env.backup.$BACKUP_TIMESTAMP && echo '备份完成'"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    "Permission denied" {
        puts "❌ SSH 认证失败"
        exit 1
    }
    eof
}

# 上传 server.js
puts "\n步骤2: 上传新的 server.js..."
spawn scp $LOCAL_BACKEND_DIR/server.js root@$SERVER_IP:$BACKEND_DIR/server.js
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

# 上传 production.env
puts "\n步骤3: 上传新的 production.env..."
spawn scp $LOCAL_BACKEND_DIR/production.env root@$SERVER_IP:$BACKEND_DIR/production.env
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

# 验证文件并重启服务
puts "\n步骤4: 验证文件并重启服务..."
spawn ssh root@$SERVER_IP "cd $BACKEND_DIR && grep -n 'verifyIAPTransaction' server.js | head -3 && echo '' && grep IAP_VERIFY_STRICT production.env && echo '' && pm2 restart chongyu-backend && sleep 2 && pm2 status chongyu-backend | grep chongyu-backend"
expect {
    "password:" {
        send "$SSH_PASSWORD\r"
        exp_continue
    }
    eof
}

puts "\n步骤5: 检查服务日志..."
spawn ssh root@$SERVER_IP "sleep 3 && pm2 logs chongyu-backend --lines 20 --nostream | grep -E 'IAP_VERIFY_STRICT|Config.*IAP' || echo '未找到配置日志'"
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
echo "部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 查看服务日志: ssh root@$SERVER_IP 'pm2 logs chongyu-backend --lines 50 | grep -E \"IAP|Verify\"'"
echo "2. 运行测试: SERVER=https://api.chongyuai.com ./test_iap_verification.sh"
echo ""
echo "⚠️  安全提示：建议使用 SSH 密钥认证替代密码认证"

