# 🔒 HTTPS 设置手把手指南 - Caddy 自动证书

## 📋 准备工作

在开始之前，请确认：
- ✅ 域名 `api.chongyuai.com` 已解析到 `121.40.184.29`
- ✅ 你有服务器的 root 或 sudo 权限
- ✅ 后端服务在 `127.0.0.1:3000` 正常运行

---

## 🎯 方法一：自动化脚本（推荐，最简单）

### 步骤 1: 上传脚本到服务器

在你的**本地电脑**上执行：

```bash
cd "/Users/lishilong/IOS开发/虫遇/虫遇"
scp setup_https_caddy.sh root@121.40.184.29:/root/
```

**如果提示输入密码**，输入你的服务器 root 密码。

### 步骤 2: 登录服务器

```bash
ssh root@121.40.184.29
```

### 步骤 3: 运行脚本

```bash
chmod +x /root/setup_https_caddy.sh
/root/setup_https_caddy.sh
```

脚本会自动完成所有步骤，包括：
- ✅ 检查后端服务
- ✅ 检查系统时间
- ✅ 检查端口占用
- ✅ 安装 Caddy
- ✅ 配置反向代理
- ✅ 申请 SSL 证书
- ✅ 启动服务

### 步骤 4: 等待完成

脚本运行完成后，你会看到：
- ✅ 成功提示
- 📝 下一步操作说明

**如果看到错误**，请把错误信息发给我，我会帮你解决。

---

## 🛠️ 方法二：手动执行（如果脚本失败）

如果自动化脚本遇到问题，可以手动执行以下步骤：

### 步骤 1: 登录服务器

```bash
ssh root@121.40.184.29
```

### 步骤 2: 检查后端服务

```bash
curl -I http://127.0.0.1:3000
```

**期望看到**: `HTTP/1.1 200 OK` 或类似响应

**如果没有响应**，请先启动后端服务。

### 步骤 3: 放通 80/443 端口（重要！）

#### 3.1 阿里云控制台设置（必须）

1. 打开浏览器，登录 [阿里云控制台](https://ecs.console.aliyun.com/)
2. 进入 **ECS** → **实例** → 找到你的服务器（IP: 121.40.184.29）
3. 点击 **安全组** → **配置规则**
4. 点击 **添加安全组规则**，添加两条规则：

   **规则 1 - HTTP (80端口)**:
   - 规则方向: 入方向
   - 授权策略: 允许
   - 协议类型: 自定义 TCP
   - 端口范围: `80/80`
   - 授权对象: `0.0.0.0/0`
   - 描述: HTTP

   **规则 2 - HTTPS (443端口)**:
   - 规则方向: 入方向
   - 授权策略: 允许
   - 协议类型: 自定义 TCP
   - 端口范围: `443/443`
   - 授权对象: `0.0.0.0/0`
   - 描述: HTTPS

5. 点击 **保存**

#### 3.2 服务器防火墙设置（如果启用了防火墙）

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
sudo lsof -i:80 -i:443
```

**如果有输出**，说明端口被占用，需要先停止占用端口的服务：

```bash
# 例如，如果 nginx 占用了端口
sudo systemctl stop nginx
sudo systemctl disable nginx  # 如果不需要 nginx
```

**如果没有输出**，说明端口空闲，可以继续。

### 步骤 5: 检查系统时间（重要！）

证书申请需要准确的时间：

```bash
timedatectl status
```

**如果显示 `synchronized: yes`**，说明时间已同步，继续下一步。

**如果时间不准**，执行：

```bash
sudo timedatectl set-ntp true
```

等待几秒后再次检查。

### 步骤 6: 安装 Caddy

#### 如果是 Ubuntu/Debian 系统：

```bash
sudo apt update
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https

curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | sudo tee /usr/share/keyrings/caddy-stable-archive-keyring.gpg >/dev/null
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update && sudo apt install -y caddy
```

#### 如果是 CentOS/Rocky/RHEL 系统：

```bash
sudo dnf install -y 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy -y
sudo dnf install -y caddy
```

**安装完成后**，验证安装：

```bash
caddy version
```

应该看到版本号。

### 步骤 7: 配置 Caddyfile

```bash
sudo tee /etc/caddy/Caddyfile >/dev/null <<'EOF'
api.chongyuai.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3000
}
EOF
```

**验证配置**：

```bash
cat /etc/caddy/Caddyfile
```

应该看到刚才写入的内容。

**验证配置语法**：

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
```

应该显示 `Valid configuration`。

### 步骤 8: 启动 Caddy

```bash
# 启用开机自启
sudo systemctl enable --now caddy

# 启动服务
sudo systemctl restart caddy

# 检查状态
sudo systemctl status caddy
```

**期望看到**: `Active: active (running)`

### 步骤 9: 查看日志（确认证书申请）

```bash
sudo journalctl -u caddy -n 100 --no-pager
```

**查找关键信息**：
- `obtaining certificate` - 正在申请证书
- `certificate obtained` - 证书已获得
- `serving initial configuration` - 配置已加载

**如果看到错误**，请把错误信息发给我。

### 步骤 10: 验证 HTTPS

等待 10-30 秒让证书申请完成，然后测试：

```bash
curl -I https://api.chongyuai.com
```

**期望看到**:
```
HTTP/1.1 200 OK
或
HTTP/1.1 301 Moved Permanently
```

**浏览器测试**：
1. 打开浏览器
2. 访问 `https://api.chongyuai.com`
3. 应该看到小锁图标 🔒
4. 点击锁图标可以查看证书信息

---

## 🔍 常见问题排查

### 问题 1: 80/443 端口被占用

**症状**: Caddy 启动失败，日志显示端口被占用

**解决**:
```bash
# 查看占用进程
sudo lsof -i:80 -i:443

# 停止占用服务（例如 nginx）
sudo systemctl stop nginx
sudo systemctl disable nginx

# 重启 Caddy
sudo systemctl restart caddy
```

### 问题 2: 证书申请失败

**症状**: 日志显示 `certificate obtain error`

**可能原因**:
1. DNS 未生效（等待几分钟）
2. 80 端口被占用
3. 系统时间不准
4. 域名解析错误

**解决**:
```bash
# 检查 DNS
nslookup api.chongyuai.com
# 应该显示 121.40.184.29

# 检查时间
timedatectl status

# 查看详细日志
sudo journalctl -u caddy -f
```

### 问题 3: Caddy 启动失败

**症状**: `systemctl status caddy` 显示 failed

**解决**:
```bash
# 检查配置语法
sudo caddy validate --config /etc/caddy/Caddyfile

# 查看详细错误
sudo journalctl -u caddy -n 50 --no-pager
```

### 问题 4: 后端服务无响应

**症状**: HTTPS 可以访问，但返回 502 Bad Gateway

**解决**:
```bash
# 检查后端是否运行
curl http://127.0.0.1:3000

# 如果后端在其他端口，修改 Caddyfile
sudo nano /etc/caddy/Caddyfile
# 把 3000 改成实际端口
# 然后重启: sudo systemctl restart caddy
```

### 问题 5: 安全组未放通

**症状**: 本地无法访问，但服务器上可以

**解决**:
1. 检查阿里云控制台安全组规则
2. 确认 80/443 端口已添加
3. 确认授权对象是 `0.0.0.0/0`

---

## ✅ 完成检查清单

设置完成后，请确认：

- [ ] `curl -I https://api.chongyuai.com` 返回 200 或 301
- [ ] 浏览器访问 `https://api.chongyuai.com` 显示小锁图标 🔒
- [ ] 证书有效期显示正确（通常 90 天，自动续期）
- [ ] 后端 API 通过 HTTPS 可正常访问
- [ ] 阿里云安全组已放通 80/443 端口

---

## 📱 下一步：更新 iOS 配置

**HTTPS 设置成功后，请回复 "HTTPS 已通"**，我会立即：

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
4. `curl -I https://api.chongyuai.com` 的输出

我会帮你快速解决问题！

