#!/bin/bash

# 查看服务器 IAP 验证日志的脚本
# 使用方法：
#   chmod +x 查看服务器日志.sh
#   ./查看服务器日志.sh

SERVER_IP="121.40.184.29"
BACKEND_DIR="/var/www/chongyu-backend"

echo "=========================================="
echo "查看服务器 IAP 验证日志"
echo "=========================================="
echo "服务器: $SERVER_IP"
echo ""

# 方式1: 使用 PM2 查看日志
echo "=== 方式1: 使用 PM2 查看日志 ==="
echo "执行命令: ssh root@$SERVER_IP \"pm2 logs chongyu-backend --lines 100 --nostream | grep -E 'IAP|Verify'\""
echo ""
ssh root@$SERVER_IP "pm2 logs chongyu-backend --lines 100 --nostream 2>/dev/null | grep -E 'IAP|Verify|Config.*IAP' | tail -50" || {
    echo "PM2 日志查看失败，尝试其他方式..."
    echo ""
    
    # 方式2: 查看日志文件
    echo "=== 方式2: 查看日志文件 ==="
    echo "执行命令: ssh root@$SERVER_IP \"tail -200 /var/log/chongyu-backend.log | grep -E 'IAP|Verify'\""
    echo ""
    ssh root@$SERVER_IP "tail -200 /var/log/chongyu-backend.log 2>/dev/null | grep -E 'IAP|Verify|Config.*IAP' | tail -50" || {
        echo "日志文件查看失败，尝试查看进程输出..."
        echo ""
        
        # 方式3: 查看最近的交易记录
        echo "=== 方式3: 查看最近的交易记录 ==="
        echo "执行命令: ssh root@$SERVER_IP \"cd $BACKEND_DIR && tail -50 server-data.json | jq '.transactions[] | select(.meta.productId != null) | {id, type, amount, ref, meta, at}' 2>/dev/null | tail -20\""
        echo ""
        ssh root@$SERVER_IP "cd $BACKEND_DIR && tail -100 server-data.json 2>/dev/null | jq '.transactions[] | select(.meta.productId != null) | {id, type, amount, ref: .ref, productId: .meta.productId, verification: .meta.verification, at: .at}' 2>/dev/null | tail -20" || {
            echo "无法查看日志，请手动执行以下命令："
            echo ""
            echo "1. SSH 到服务器："
            echo "   ssh root@$SERVER_IP"
            echo ""
            echo "2. 查看 PM2 日志："
            echo "   pm2 logs chongyu-backend --lines 100 | grep -E 'IAP|Verify'"
            echo ""
            echo "3. 或查看日志文件："
            echo "   tail -200 /var/log/chongyu-backend.log | grep -E 'IAP|Verify'"
            echo ""
            echo "4. 或查看最近的交易："
            echo "   cd $BACKEND_DIR"
            echo "   cat server-data.json | jq '.transactions[] | select(.meta.productId != null) | {ref, meta}' | tail -20"
        }
    }
}

echo ""
echo "=========================================="
echo "查看完成"
echo "=========================================="

