#!/bin/bash

# 视觉API积分扣除测试脚本
# 请在服务器上运行: cd /var/www/chongyu-backend && bash test_vision_credits.sh

echo "========================================"
echo "视觉API积分扣除测试"
echo "========================================"
echo ""

echo "1. 检查环境配置:"
grep 'CREDITS_PER_.*_VISION' production.env
echo ""

echo "2. 创建测试账户:"
curl -s -X POST http://localhost:3000/api/wallet/init \
  -H 'Content-Type: application/json' \
  -d '{"appAccountToken":"vision-test-003"}'
echo ""
echo ""

echo "3. 充值5000积分:"
curl -s -X POST http://localhost:3000/api/wallet/balance \
  -H 'Content-Type: application/json' \
  -d '{"appAccountToken":"vision-test-003","amount":5000}'
echo ""
echo ""

echo "4. 调用视觉API (doubao-seed, 应扣10积分):"
curl -s -X POST http://localhost:3000/api/vision \
  -H 'Content-Type: application/json' \
  -H 'X-App-Account-Token: vision-test-003' \
  -d '{"model":"doubao-seed-1-6-vision-250815","messages":[{"role":"user","content":"你好"}],"max_tokens":50}'
echo ""
echo ""

sleep 1

echo "5. 查看剩余积分 (应该是4990):"
curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-003
echo ""
echo ""

echo "6. 调用视觉API (doubao-vision-pro, 应扣20积分):"
curl -s -X POST http://localhost:3000/api/vision \
  -H 'Content-Type: application/json' \
  -H 'X-App-Account-Token: vision-test-003' \
  -d '{"model":"doubao-vision-pro-32k","messages":[{"role":"user","content":"你好"}],"max_tokens":20}'
echo ""
echo ""

sleep 1

echo "7. 查看最终积分 (应该是4970):"
curl -s http://localhost:3000/api/wallet/balance?appAccountToken=vision-test-003
echo ""
echo ""

echo "========================================"
echo "测试完成！"
echo "预期积分变化: 5000 -> 4990 -> 4970"
echo "========================================"

