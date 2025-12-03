# 🚀 虫遇APP生产环境部署检查清单

## 📋 部署前检查

### 1. 服务器环境准备

#### **阿里云服务器 (121.40.184.29)**
- [ ] **服务器状态检查**
  ```bash
  # 检查服务器是否可访问
  ping 121.40.184.29
  ssh root@121.40.184.29
  ```

- [ ] **端口配置**
  ```bash
  # 确保3000端口开放
  firewall-cmd --list-ports
  firewall-cmd --permanent --add-port=3000/tcp
  firewall-cmd --reload
  ```

- [ ] **Node.js环境**
  ```bash
  node --version  # 应该 >= 14.x
  npm --version
  pm2 --version
  ```

### 2. 后端服务配置

#### **环境变量配置** (`backend/.env`)
- [ ] **API密钥配置**
  ```bash
  DEEPSEEK_API_KEY=sk-xxx...  # 替换为真实API密钥
  FALLBACK_API_KEY=xxx...     # 备用API密钥
  ```

- [ ] **端口统一**
  ```bash
  PORT=3000  # 与iOS应用配置保持一致
  ```

- [ ] **积分配置**
  ```bash
  CREDITS_PER_1K_TOKENS=100  # 每1K tokens消耗100积分
  ```

- [ ] **安全配置**
  ```bash
  JWT_SECRET=生产环境强密码  # 更换为安全的密钥
  MOCK_PROVIDER=0           # 生产环境禁用模拟
  ```

#### **部署脚本**
- [ ] **上传文件**
  ```bash
  # 将backend目录上传到服务器
  scp -r backend/ root@121.40.184.29:/var/www/chongyu-backend/
  ```

- [ ] **安装依赖**
  ```bash
  cd /var/www/chongyu-backend
  npm install --production
  ```

- [ ] **启动服务**
  ```bash
  pm2 start server.js --name "chongyu-backend"
  pm2 save
  pm2 startup
  ```

### 3. iOS应用配置

#### **Info.plist配置**
- [x] **后端地址**
  ```xml
  <key>BACKEND_BASE_URL</key>
  <string>http://121.40.184.29:3000</string>
  ```

- [ ] **Bundle ID确认**
  ```xml
  确保与StoreKit配置一致: com.shilong111234.chongyu
  ```

#### **StoreKit配置**
- [x] **产品配置完整**
  - credits.small (¥6.00 - 1800积分)
  - credits.medium (¥18.00 - 6000积分)  
  - credits.large (¥38.00 - 13800积分)
  - credits.xlarge (¥68.00 - 26800积分)

### 4. App Store Connect配置

#### **应用信息**
- [ ] **Bundle ID**: `com.shilong111234.chongyu`
- [ ] **版本号**: 确保与Xcode项目一致
- [ ] **内购产品**: 创建并配置所有4个产品

#### **内购产品配置**
```
Product ID: credits.small
Reference Name: 虫币入门包
Price: ¥6.00
Type: Consumable

Product ID: credits.medium  
Reference Name: 虫币标准包
Price: ¥18.00
Type: Consumable

Product ID: credits.large
Reference Name: 虫币豪华包  
Price: ¥38.00
Type: Consumable

Product ID: credits.xlarge
Reference Name: 虫币至尊包
Price: ¥68.00  
Type: Consumable
```

### 5. 安全检查

#### **API密钥安全**
- [x] **客户端无硬编码密钥**
- [x] **代理架构正确实现**
- [ ] **生产密钥已配置**

#### **网络安全**
- [x] **HTTPS配置** (外部API调用)
- [x] **HTTP异常域名配置** (生产服务器)

### 6. 功能测试

#### **核心功能测试**
- [ ] **用户注册/登录**
- [ ] **Apple ID登录**
- [ ] **AI对话功能**
- [ ] **内购充值流程**
- [ ] **积分消耗机制**

#### **错误处理测试**
- [ ] **网络连接失败**
- [ ] **API调用失败**
- [ ] **内购失败处理**
- [ ] **积分不足提示**

### 7. 监控配置

#### **服务器监控**
```bash
# 查看服务状态
pm2 status

# 查看日志
pm2 logs chongyu-backend

# 监控资源使用
pm2 monit
```

#### **健康检查**
```bash
# 服务健康检查
curl http://121.40.184.29:3000/health

# API代理测试
curl -X POST http://121.40.184.29:3000/api/proxy \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: test-token" \
  -d '{"messages":[{"role":"user","content":"测试"}]}'
```

## ⚠️ **当前已知问题**

### **紧急修复项**
1. **生产服务器无法访问** - 需要重启服务器或检查网络配置
2. **API密钥未配置** - 需要获取并配置真实的DeepSeek API密钥
3. **端口配置已统一** - ✅ 已修正为3000端口

### **优化建议**
1. **添加HTTPS支持** - 为生产服务器配置SSL证书
2. **数据库持久化** - 考虑使用Redis或数据库替代JSON文件存储
3. **日志系统** - 配置结构化日志和日志轮转
4. **备份策略** - 定期备份用户数据和交易记录

## 🎯 **部署优先级**

### **P0 (立即修复)**
- [ ] 修复生产服务器连接问题
- [ ] 配置真实API密钥
- [ ] 验证内购功能

### **P1 (上线前完成)**
- [ ] 完整功能测试
- [ ] App Store Connect配置
- [ ] 监控和日志配置

### **P2 (上线后优化)**
- [ ] HTTPS配置
- [ ] 数据库迁移
- [ ] 性能优化

---

**最后更新**: 2025年9月21日
**状态**: 🔄 配置修正中，等待服务器修复 