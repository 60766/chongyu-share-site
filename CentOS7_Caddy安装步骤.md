# CentOS 7 安装 Caddy 步骤

## 当前状态
- ✅ 后端服务在运行（127.0.0.1:3000）
- ✅ 系统：CentOS 7
- ⚠️  需要先完成 Caddyfile 输入

## 步骤 1: 完成 Caddyfile 输入

你现在还在输入 Caddyfile，需要先完成它：

```bash
# 在终端中继续输入（你现在应该看到 > 提示符）
> }
> EOF
```

输入 `}` 然后回车，再输入 `EOF` 然后回车，就会完成配置。

## 步骤 2: CentOS 7 安装 Caddy

CentOS 7 使用 `yum` 而不是 `dnf`。执行以下命令：

```bash
# 方法 1: 使用官方二进制安装（推荐）
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sSf https://dl.cloudsmith.io/public/caddy/stable/rpm/caddy-stable.repo | tee /etc/yum.repos.d/caddy-stable.repo
yum install -y caddy

# 或者方法 2: 直接下载二进制（如果方法1失败）
# wget https://caddyserver.com/api/download?os=linux&arch=amd64 -O /usr/local/bin/caddy
# chmod +x /usr/local/bin/caddy
```

## 步骤 3: 配置 systemd 服务（如果使用方法2）

如果使用方法2安装，需要创建 systemd 服务文件：

```bash
cat > /etc/systemd/system/caddy.service <<'EOF'
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

# 创建 caddy 用户
useradd -r -s /sbin/nologin caddy
mkdir -p /etc/caddy
chown -R caddy:caddy /etc/caddy
```

## 步骤 4: 启动 Caddy

```bash
systemctl daemon-reload
systemctl enable caddy
systemctl start caddy
systemctl status caddy
```

## 步骤 5: 查看日志

```bash
journalctl -u caddy -n 50 --no-pager
```

## 步骤 6: 测试 HTTPS

```bash
sleep 5
curl -I https://api.chongyuai.com
```













































