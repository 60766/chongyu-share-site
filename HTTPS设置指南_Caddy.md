# HTTPS 设置指南 - Caddy 自动证书方案

## 📋 前置检查清单

在开始之前，请确认：
- [ ] 域名 `api.chongyuai.com` 已解析到 `121.40.184.29`
- [ ] 后端服务在 `127.0.0.1:3000` 正常运行
- [ ] 你有服务器的 root 或 sudo 权限

---

## 🚀 快速开始（推荐）

### 方法一：使用自动化脚本

1. **上传脚本到服务器**
   ```bash
   # 在本机执行（将脚本上传到服务器）
   scp setup_https_caddy.sh root@121.40.184.29:/root/
   ```

2. **登录服务器并运行脚本**
   ```bash
   ssh root@121.40.184.29
   chmod +x /root/setup_https_caddy.sh
   /root/setup_https_caddy.sh
   ```

3. **等待脚本完成**，它会自动：
   - 检查后端服务
   - 安装 Caddy
   - 配置反向代理
   - 申请 SSL 证书
   - 启动服务

---

## 📝 手动步骤（如果脚本失败）

### 步骤 1: 登录服务器

```bash
ssh root@121.40.184.29
# 或者：ssh ubuntu@121.40.184.29
```

### 步骤 2: 检查后端服务

```bash
# 检查后端是否在 3000 端口运行
curl -I http://127.0.0.1:3000

# 或者
curl http://127.0.0.1:3000/health

# 如果有响应（200 OK），继续下一步
```

### 步骤 3: 放通 80/443 端口

#### 3.1 阿里云控制台设置
1. 登录 [阿里云控制台](https://ecs.console.aliyun.com/)
2. 进入 **ECS** → **实例** → 选择你的服务器
3. 点击 **安全组** → **配置规则**
4. **入方向规则** → **添加安全组规则**：
   - **规则方向**: 入方向
   - **授权策略**: 允许
   - **协议类型**: 自定义 TCP
   - **端口范围**: `80/80`
   - **授权对象**: `0.0.0.0/0`
   - **描述**: HTTP
5. 再添加一条规则（端口 `443/443`，其他相同）

#### 3.2 服务器防火墙设置（如果启用）

```bash
# Ubuntu/Debian
sudo ufw allow 80,443/tcp

# CentOS/Rocky
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 步骤 4: 检查端口占用

```bash
sudo lsof -i:80
sudo lsof -i:443

# 如果有占用，停止相关服务
# 例如：sudo systemctl stop nginx
```

### 步骤 5: 检查系统时间（重要！）

证书申请需要准确的时间：

```bash
timedatectl status

# 如果时间不准，同步时间：
sudo timedatectl set-ntp true
```

### 步骤 6: 安装 Caddy

#### Ubuntu/Debian 系统：

```bash
sudo apt update
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https

curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg >/dev/null
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update && sudo apt install -y caddy
```

#### CentOS/Rocky/RHEL 系统：

```bash
sudo dnf install -y 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy -y
sudo dnf install -y caddy
```

### 步骤 7: 配置 Caddyfile

```bash
sudo tee /etc/caddy/Caddyfile >/dev/null <<'EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
}
EOF

# 验证配置
cat /etc/caddy/Caddyfile
```

### 步骤 8: 启动 Caddy

```bash
# 启用开机自启
sudo systemctl enable --now caddy

# 启动服务
sudo systemctl restart caddy

# 检查状态
sudo systemctl status caddy
```

### 步骤 9: 查看日志（确认证书申请）

```bash
# 查看最近 100 行日志
sudo journalctl -u caddy -n 100 --no-pager

# 应该看到类似这样的内容：
# "obtaining certificate" 或 "certificate obtained"
```

### 步骤 10: 验证 HTTPS

```bash
# 等待几秒让证书申请完成
sleep 5

# 测试 HTTPS
curl -I https://api.chongyuai.com

# 期望看到：
# HTTP/1.1 200 OK
# 或
# HTTP/1.1 301 Moved Permanently
```

**浏览器测试**：
- 打开 `https://api.chongyuai.com`
- 应该看到小锁图标 🔒
- 点击锁图标查看证书信息

---

## 🔍 故障排查

### 问题 1: 80/443 端口被占用

```bash
# 查看占用进程
sudo lsof -i:80
sudo lsof -i:443

# 停止占用服务（例如 nginx）
sudo systemctl stop nginx
sudo systemctl disable nginx  # 如果不需要

# 重启 Caddy
sudo systemctl restart caddy
```

### 问题 2: 证书申请失败

**可能原因**：
- DNS 未生效（等待几分钟）
- 80 端口被占用
- 系统时间不准

**解决方法**：
```bash
# 检查 DNS
nslookup api.chongyuai.com

# 检查时间
timedatectl status

# 查看详细日志
sudo journalctl -u caddy -f
```

### 问题 3: Caddy 启动失败

```bash
# 检查配置语法
sudo caddy validate --config /etc/caddy/Caddyfile

# 查看详细错误
sudo journalctl -u caddy -n 50 --no-pager
```

### 问题 4: 后端服务无响应

```bash
# 检查后端是否运行
curl http://127.0.0.1:3000

# 如果后端在其他端口，修改 Caddyfile 中的端口号
```

---

## ✅ 完成检查清单

设置完成后，请确认：

- [ ] `curl -I https://api.chongyuai.com` 返回 200 或 301
- [ ] 浏览器访问 `https://api.chongyuai.com` 显示小锁图标
- [ ] 证书有效期显示正确（通常 90 天，自动续期）
- [ ] 后端 API 通过 HTTPS 可正常访问

---

## 📱 下一步：更新 iOS 配置

HTTPS 设置成功后，告诉我，我会：

1. ✅ 更新 `Info.plist` 中的 `BACKEND_BASE_URL` 为 `https://api.chongyuai.com`
2. ✅ 移除 `NSAppTransportSecurity` 中的 HTTP 例外
3. ✅ 验证代码中的 HTTPS 检查逻辑
4. ✅ 重新构建项目确保一切正常

---

## 📞 需要帮助？

如果遇到问题，请提供：
1. 错误信息（完整日志）
2. `sudo systemctl status caddy` 的输出
3. `sudo journalctl -u caddy -n 50` 的输出


















































































