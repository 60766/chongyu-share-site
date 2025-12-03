#!/bin/bash

# 设置测试余额脚本
# 用于快速为 TEST_TOKEN 设置测试余额

TOKEN="TEST_TOKEN"
BALANCE=10000

echo "🔧 设置测试余额..."
echo "Token: $TOKEN"
echo "余额: $BALANCE 虫洞币"
echo ""

# 在服务器上执行
ssh root@121.40.184.29 << EOF
curl -X POST https://api.chongyuai.com/admin/set-balance \\
  -H "Content-Type: application/json" \\
  -d '{"appAccountToken":"$TOKEN","balance":$BALANCE}'

echo ""
echo "✅ 余额设置完成！"
echo ""
echo "验证余额："
curl -s "https://api.chongyuai.com/balance?appAccountToken=$TOKEN" | python3 -m json.tool 2>/dev/null || curl -s "https://api.chongyuai.com/balance?appAccountToken=$TOKEN"
EOF

echo ""
echo "📱 请在应用中点击刷新按钮查看新余额"

