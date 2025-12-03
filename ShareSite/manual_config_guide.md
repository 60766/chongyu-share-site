# 手动配置指南

## 📋 当前情况

配置脚本执行时遇到问题，可能需要手动配置。

## 🔧 手动配置步骤

### 方法1：SSH到服务器手动配置（推荐）

1. **SSH到服务器**
   ```bash
   ssh root@121.40.184.29
   # 密码：3Qq123456.
   ```

2. **备份当前配置**
   ```bash
   cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.backup
   ```

3. **编辑Caddy配置**
   ```bash
   nano /etc/caddy/Caddyfile
   # 或
   vi /etc/caddy/Caddyfile
   ```

4. **添加以下内容到文件末尾**
   ```
   share.chongyuai.com {
       log {
           output file /var/log/caddy/share-access.log {
               roll_size 10mb
               roll_keep 5
           }
           format json
       }
       root * /var/www/share-site
       encode zstd gzip
       file_server
       try_files {path} /index.html
       header Cache-Control "no-cache, no-store, must-revalidate"
       header Pragma "no-cache"
       header Expires "0"
   }
   ```

5. **验证配置**
   ```bash
   caddy validate --config /etc/caddy/Caddyfile
   ```

6. **重新加载Caddy**
   ```bash
   systemctl reload caddy
   ```

### 方法2：使用本地文件上传

1. **在本地创建完整配置文件**
   ```bash
   # 先获取当前配置
   scp root@121.40.184.29:/etc/caddy/Caddyfile ./Caddyfile.current
   
   # 编辑文件，添加share.chongyuai.com配置
   # 然后上传
   scp ./Caddyfile.current root@121.40.184.29:/etc/caddy/Caddyfile
   
   # SSH到服务器验证和重载
   ssh root@121.40.184.29
   caddy validate --config /etc/caddy/Caddyfile
   systemctl reload caddy
   ```

---

**最后更新**：2025年1月4日

