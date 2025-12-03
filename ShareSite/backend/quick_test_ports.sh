#!/bin/bash
echo "正在测试不同的SSH端口..."
echo ""

for port in 22 2022 2222 8022 8888 10022; do
  echo "测试端口 $port..."
  nc -z -w 3 47.236.112.139 $port 2>&1
  if [ $? -eq 0 ]; then
    echo "✅ 端口 $port 开放！尝试SSH连接..."
    ssh -p $port -o ConnectTimeout=5 root@47.236.112.139 "echo '连接成功'" && echo "🎉 SSH端口是 $port" && break
  else
    echo "❌ 端口 $port 关闭或无响应"
  fi
  echo ""
done
