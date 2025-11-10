#!/bin/bash
# 同步计费修复到远程生产服务器
# 核心目标：替换远程的 server.js，让它使用正确的 Math.floor() 算法

set -e

SERVER="121.40.184.29"
REMOTE_DIR="/var/www/chongyu-backend"
LOCAL_FILE="./server.js"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 使用expect脚本处理SSH密码
SSH_EXPECT="$SCRIPT_DIR/ssh_with_pass.exp"
SCP_EXPECT="$SCRIPT_DIR/scp_with_pass.exp"

echo "🎯 目标：同步计费算法修复到生产服务器"
echo "📡 服务器：$SERVER"
echo ""

# 检查本地文件
if [ ! -f "$LOCAL_FILE" ]; then
    echo "❌ 本地 server.js 文件不存在"
    exit 1
fi

echo "1️⃣ 备份远程服务器上的旧文件..."
$SSH_EXPECT "$SERVER" "cd $REMOTE_DIR && if [ -f server.js ]; then cp server.js \"server.js.backup.\$(date +%Y%m%d_%H%M%S)\" && echo '✅ 已备份'; else echo '⚠️  server.js 不存在，无需备份'; fi"

echo ""
echo "2️⃣ 上传修复后的 server.js..."
$SCP_EXPECT "$SCRIPT_DIR/server.js" "root@$SERVER:$REMOTE_DIR/server.js"
echo "✅ 文件已上传"

echo ""
echo "3️⃣ 重启服务..."
$SSH_EXPECT "$SERVER" "cd $REMOTE_DIR && pm2 restart chongyu-backend && sleep 2 && pm2 logs chongyu-backend --lines 10 --nostream"

echo ""
echo "4️⃣ 验证计费算法..."
$SSH_EXPECT "$SERVER" "cd $REMOTE_DIR && if grep -q 'Math.floor.*totalTokens.*CREDITS_TEXT_PER_1K_TOKENS' server.js && grep -q 'Math.floor.*totalTokens.*CREDITS_VISION_PER_1K_TOKENS' server.js; then echo '✅ 确认：文本和视觉API都使用 Math.floor() 算法'; elif grep -q 'Math.round.*totalTokens.*CREDITS' server.js; then echo '❌ 警告：仍在使用 Math.round() 算法！'; elif grep -q 'Math.ceil.*totalTokens.*CREDITS' server.js; then echo '❌ 警告：仍在使用 Math.ceil() 算法！'; else echo '⚠️  未找到标准计费代码'; fi"

echo ""
echo "✅ 部署完成！"
echo ""
echo "📊 下一步测试："
echo "  1. 在APP里发送一条消息"
echo "  2. 查看扣费是否正确（应该是 Math.floor 算法）"
echo ""
echo "🔍 查看远程日志："
echo "  ssh root@$SERVER"
echo "  cd /var/www/chongyu-backend && pm2 logs chongyu-backend"

