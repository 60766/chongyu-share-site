#!/bin/bash

# 上传网站文件到服务器

SERVER_IP="121.40.184.29"
SERVER_USER="root"
SERVER_PASSWORD="3Qq123456."
WEBSITE_DIR="/var/www/share-site"
LOCAL_DIR="/Users/lishilong/IOS开发/虫遇/虫遇/ShareSite/ShareSite"

echo "🚀 开始上传网站文件..."
echo "================================"
echo ""

# 检查本地文件
if [ ! -d "$LOCAL_DIR" ]; then
    echo "❌ 本地目录不存在: $LOCAL_DIR"
    exit 1
fi

echo "📁 本地目录: $LOCAL_DIR"
echo "📁 服务器目录: $WEBSITE_DIR"
echo ""

# 使用rsync上传文件
expect << 'EXPEOF'
set timeout 300
set server_ip "121.40.184.29"
set server_user "root"
set server_password "3Qq123456."
set local_dir "/Users/lishilong/IOS开发/虫遇/虫遇/ShareSite/ShareSite"
set remote_dir "/var/www/share-site"

spawn rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no" $local_dir/ $server_user@$server_ip:$remote_dir/
expect {
    "*password:" {
        send "$server_password\r"
        expect eof
    }
    eof
}
EXPEOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 文件上传成功！"
    echo ""
    
    # 验证文件
    expect << 'EXPEOF'
    set timeout 30
    spawn ssh -o StrictHostKeyChecking=no root@121.40.184.29
    expect {
        "*password:" {
            send "3Qq123456.\r"
            expect "#"
            send "echo '=== 验证上传的文件 ==='\r"
            expect "#"
            send "ls -lh /var/www/share-site/*.html\r"
            expect "#"
            send "echo ''\r"
            expect "#"
            send "echo '=== 设置文件权限 ==='\r"
            expect "#"
            send "chown -R root:root /var/www/share-site\r"
            expect "#"
            send "chmod -R 755 /var/www/share-site\r"
            expect "#"
            send "exit\r"
            expect eof
        }
    }
EXPEOF
    
    echo ""
    echo "✅ 部署完成！"
    echo ""
    echo "📋 下一步："
    echo "  1. 在阿里云DNS中，将 share.chongyuai.com 的CNAME记录改为A记录"
    echo "  2. 指向：121.40.184.29"
    echo "  3. 等待DNS解析生效（通常几分钟）"
    echo "  4. 访问 https://share.chongyuai.com 验证"
else
    echo ""
    echo "❌ 文件上传失败"
    exit 1
fi

