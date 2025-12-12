# HTTPS 设置 - 快速命令参考

## 🚀 一键执行（推荐）

```bash
# 1. 上传脚本到服务器
scp setup_https_caddy.sh root@121.40.184.29:/root/

# 2. 登录服务器
ssh root@121.40.184.29

# 3. 运行脚本
chmod +x /root/setup_https_caddy.sh
/root/setup_https_caddy.sh
```

---

## 📋 手动执行命令（逐行复制）

### 1. 登录服务器
```bash
ssh root@121.40.184.29
```

### 2. 检查后端
```bash
curl -I http://127.0.0.1:3000
```

### 3. 检查端口占用
```bash
sudo lsof -i:80 -i:443
```

### 4. 同步时间
```bash
sudo timedatectl set-ntp true
```

### 5. 安装 Caddy (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg >/dev/null
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
```

### 6. 配置 Caddyfile
```bash
sudo tee /etc/caddy/Caddyfile >/dev/null <<'EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
}
EOF
```

### 7. 启动 Caddy
```bash
sudo systemctl enable --now caddy
sudo systemctl restart caddy
```

### 8. 查看日志
```bash
sudo journalctl -u caddy -n 100 --no-pager
```

### 9. 测试 HTTPS
```bash
curl -I https://api.chongyuai.com
```

---

## ⚠️ 重要提醒

1. **阿里云安全组**：必须在控制台放通 80/443 端口
2. **DNS 解析**：确保 `api.chongyuai.com` 指向 `121.40.184.29`
3. **后端服务**：确保后端在 `127.0.0.1:3000` 运行

---

## ✅ 完成后告诉我

执行完成后，回复 **"HTTPS 已通"**，我会立即更新 iOS 配置！






















































































