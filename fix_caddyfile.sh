#!/bin/bash

# 修复 Caddyfile 配置
# 在服务器上执行

echo "🔧 修复 Caddyfile 配置..."

# 备份当前配置
cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup.$(date +%s) 2>/dev/null || true

# 写入正确的配置
cat > /etc/caddy/Caddyfile <<'CADDYFILE_EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
  tls {
    protocols tls1.2 tls1.3
  }
}
CADDYFILE_EOF

# 验证配置
echo "📋 验证 Caddyfile："
caddy validate --config /etc/caddy/Caddyfile

# 如果验证成功，重启 Caddy
if [ $? -eq 0 ]; then
    echo "✅ 配置验证成功，重启 Caddy..."
    systemctl restart caddy
    sleep 3
    systemctl status caddy --no-pager -l | head -15
else
    echo "❌ 配置验证失败，请检查错误信息"
    echo "当前 Caddyfile 内容："
    cat /etc/caddy/Caddyfile
fi

