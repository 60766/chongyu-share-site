#!/bin/bash

# HTTPS 设置脚本 - Caddy 自动证书方案
# 域名: api.chongyuai.com
# 服务器: 121.40.184.29
# 后端端口: 3000

set -e  # 遇到错误立即退出

echo "🚀 开始设置 HTTPS (Caddy 自动证书方案)"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ 请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 步骤 1: 检查后端服务
echo "📋 步骤 1: 检查后端服务..."
if curl -I http://127.0.0.1:3000 >/dev/null 2>&1; then
    echo -e "${GREEN}✅ 后端服务在 127.0.0.1:3000 正常运行${NC}"
else
    echo -e "${YELLOW}⚠️  后端服务未响应，请确认后端是否在运行${NC}"
    echo "   继续执行脚本，但请确保后端服务正常后再测试 HTTPS"
fi
echo ""

# 步骤 2: 检查系统时间
echo "📋 步骤 2: 检查系统时间..."
if timedatectl status | grep -q "synchronized: yes"; then
    echo -e "${GREEN}✅ 系统时间已同步${NC}"
else
    echo -e "${YELLOW}⚠️  系统时间可能不同步，正在同步...${NC}"
    timedatectl set-ntp true
    sleep 2
fi
echo ""

# 步骤 3: 检查端口占用
echo "📋 步骤 3: 检查端口占用..."
if lsof -i:80 >/dev/null 2>&1 || lsof -i:443 >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  检测到 80/443 端口被占用:${NC}"
    lsof -i:80 -i:443 || true
    echo ""
    echo "请手动停止占用端口的服务，然后重新运行此脚本"
    echo "常见命令: sudo systemctl stop nginx"
    exit 1
else
    echo -e "${GREEN}✅ 80/443 端口未被占用${NC}"
fi
echo ""

# 步骤 4: 检测系统类型并安装 Caddy
echo "📋 步骤 4: 安装 Caddy..."
if [ -f /etc/debian_version ]; then
    echo "检测到 Debian/Ubuntu 系统"
    apt update
    apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
    
    curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg >/dev/null
    curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
    
    apt update && apt install -y caddy
    echo -e "${GREEN}✅ Caddy 安装完成${NC}"
elif [ -f /etc/redhat-release ]; then
    echo "检测到 CentOS/Rocky/RHEL 系统"
    dnf install -y 'dnf-command(copr)' curl
    dnf copr enable @caddy/caddy -y
    dnf install -y caddy
    echo -e "${GREEN}✅ Caddy 安装完成${NC}"
else
    echo -e "${RED}❌ 不支持的系统类型，请手动安装 Caddy${NC}"
    exit 1
fi
echo ""

# 步骤 5: 配置 Caddyfile
echo "📋 步骤 5: 配置 Caddyfile..."
cat > /etc/caddy/Caddyfile <<'EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
}
EOF

echo -e "${GREEN}✅ Caddyfile 配置完成${NC}"
echo "配置内容:"
cat /etc/caddy/Caddyfile
echo ""

# 步骤 6: 验证配置
echo "📋 步骤 6: 验证 Caddyfile 配置..."
if caddy validate --config /etc/caddy/Caddyfile 2>&1; then
    echo -e "${GREEN}✅ Caddyfile 配置有效${NC}"
else
    echo -e "${RED}❌ Caddyfile 配置有误${NC}"
    exit 1
fi
echo ""

# 步骤 7: 启动 Caddy
echo "📋 步骤 7: 启动 Caddy 服务..."
systemctl enable --now caddy
systemctl restart caddy
sleep 3

if systemctl is-active --quiet caddy; then
    echo -e "${GREEN}✅ Caddy 服务已启动${NC}"
else
    echo -e "${RED}❌ Caddy 服务启动失败${NC}"
    echo "查看日志: sudo journalctl -u caddy -n 50"
    exit 1
fi
echo ""

# 步骤 8: 查看日志
echo "📋 步骤 8: 查看 Caddy 日志（证书申请状态）..."
echo "最近 30 行日志:"
journalctl -u caddy -n 30 --no-pager | tail -20
echo ""

# 步骤 9: 等待证书申请
echo "📋 步骤 9: 等待证书申请（最多 30 秒）..."
for i in {1..30}; do
    if curl -I https://api.chongyuai.com >/dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTPS 已可用！${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""
echo ""

# 步骤 10: 最终验证
echo "📋 步骤 10: 最终验证..."
echo ""
echo "测试 HTTPS 连接:"
if curl -I https://api.chongyuai.com 2>&1 | head -5; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "✅ HTTPS 设置成功！"
    echo "==========================================${NC}"
    echo ""
    echo "📝 下一步操作:"
    echo "1. 在浏览器中访问 https://api.chongyuai.com 确认证书有效"
    echo "2. 运行测试: curl -I https://api.chongyuai.com"
    echo "3. 告诉开发者更新 iOS 配置"
    echo ""
    echo "📊 查看实时日志: sudo journalctl -u caddy -f"
    echo "🔄 重启服务: sudo systemctl restart caddy"
    echo "📋 查看状态: sudo systemctl status caddy"
else
    echo ""
    echo -e "${YELLOW}⚠️  HTTPS 可能还在申请证书中，请稍等片刻后重试${NC}"
    echo "查看日志: sudo journalctl -u caddy -n 100"
fi

