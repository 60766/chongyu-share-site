#!/bin/bash

# 修复 SSL 证书链问题
# 在服务器上执行此脚本

echo "🔧 检查并修复 SSL 证书链..."

# 检查证书链
echo "📋 检查证书链："
echo | openssl s_client -connect api.chongyuai.com:443 -servername api.chongyuai.com 2>&1 | grep -A 5 "Certificate chain"

# 检查 Caddy 配置
echo ""
echo "📋 当前 Caddyfile 配置："
cat /etc/caddy/Caddyfile

# 更新 Caddyfile，确保提供完整证书链
echo ""
echo "📋 更新 Caddyfile 配置..."
cat > /etc/caddy/Caddyfile <<'EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
  tls {
    protocols tls1.2 tls1.3
  }
}
EOF

# 验证配置
echo ""
echo "📋 验证 Caddyfile："
caddy validate --config /etc/caddy/Caddyfile

# 重启 Caddy
echo ""
echo "📋 重启 Caddy..."
systemctl restart caddy
sleep 3

# 检查状态
echo ""
echo "📋 Caddy 状态："
systemctl status caddy --no-pager -l | head -20

# 再次检查证书链
echo ""
echo "📋 重新检查证书链："
echo | openssl s_client -connect api.chongyuai.com:443 -servername api.chongyuai.com 2>&1 | grep -A 5 "Certificate chain"

echo ""
echo "✅ 完成！"

