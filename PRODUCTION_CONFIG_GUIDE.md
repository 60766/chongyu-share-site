# 🚀 虫遇应用生产环境配置指南

## 📋 配置概述

虫遇应用采用了安全的架构设计，将敏感的API密钥存储在后端服务器中，客户端通过代理方式访问AI服务。发布到生产环境时需要调整以下配置：

## 🔧 需要修改的配置

### 1. 后端服务部署 ✅ 已完成
**当前状态**：✅ 配置正确，无需修改
- API密钥：已配置真实的DeepSeek密钥
- 端点配置：使用ARK端点（`https://ark.cn-beijing.volces.com/api/v3/chat/completions`）
- 模拟模式：已禁用（`MOCK_PROVIDER=0`）

### 2. iOS应用配置调整 ⚠️ 需要修改

#### 2.1 后端服务器地址
**文件**：`虫遇/Info.plist`
**当前配置**：
```xml
<key>BACKEND_BASE_URL</key>
<string>http://127.0.0.1:8787</string>
```

**生产环境配置选项**：

**选项A：云服务器部署**
```xml
<key>BACKEND_BASE_URL</key>
<string>https://your-domain.com</string>
```

**选项B：本地网络部署**
```xml
<key>BACKEND_BASE_URL</key>
<string>http://your-mac-ip:8787</string>  <!-- 如 http://192.168.1.100:8787 -->
```

#### 2.2 NASA API密钥（可选）
**当前配置**：
```xml
<key>NASA_API_KEY</key>
<string>DEMO_KEY</string>
```

**生产环境配置**：
```xml
<key>NASA_API_KEY</key>
<string>your-real-nasa-api-key</string>
```

**获取方式**：
1. 访问 https://api.nasa.gov/
2. 注册账号并申请API密钥
3. 免费密钥限制：每小时1000次请求

#### 2.3 Bundle ID配置
**文件**：`backend/.env`
**当前配置**：
```
APP_BUNDLE_ID=com.example.chongyu
```

**需要修改为**：
```
APP_BUNDLE_ID=com.shilong111234.chongyu
```

## 🏗️ 部署选项分析

### 选项1：云服务器部署（推荐）
**优点**：
- ✅ 稳定可靠，24/7在线
- ✅ 支持HTTPS安全连接
- ✅ 用户可以随时使用应用
- ✅ 符合App Store审核要求

**部署步骤**：
1. 选择云服务提供商（阿里云、腾讯云、AWS等）
2. 部署Node.js应用
3. 配置域名和SSL证书
4. 更新iOS应用中的`BACKEND_BASE_URL`

### 选项2：本地网络部署
**优点**：
- ✅ 成本低，无需购买服务器
- ✅ 数据完全在本地控制

**限制**：
- ⚠️ 只能在同一网络下使用
- ⚠️ Mac关机后服务停止
- ⚠️ 不适合App Store发布

## 📱 代码中的配置管理

### 智能配置优先级
应用使用了智能的配置优先级系统：

```swift
// AppAccountManager.swift
private func backendBaseURL() -> URL? {
    let candidates: [String?] = [
        ProcessInfo.processInfo.environment["BACKEND_BASE_URL"],  // 1. 环境变量
        Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,  // 2. Info.plist
        UserDefaults.standard.string(forKey: "BackendBaseURL")  // 3. 用户设置
    ]
    // 选择第一个有效的配置
}
```

### 开发/生产环境自动切换
```swift
#if DEBUG
return URL(string: "http://127.0.0.1:8787")  // 开发环境
#else
return nil  // 生产环境必须配置
#endif
```

## 🔒 安全架构说明

### 为什么这样设计？
1. **API密钥保护**：敏感密钥只存储在后端，客户端无法访问
2. **代理访问**：所有AI请求通过后端代理，统一管理
3. **积分控制**：后端控制用户积分，防止滥用
4. **审核友好**：符合App Store审核要求

### 数据流向
```
iOS App → 后端代理 → DeepSeek API
     ↑                    ↓
  用户界面            AI响应内容
```

## 🚀 发布前检查清单

### 必须完成项
- [ ] **确定部署方案**（云服务器 vs 本地网络）
- [ ] **更新BACKEND_BASE_URL**（指向生产服务器）
- [ ] **配置Bundle ID**（后端.env文件）
- [ ] **测试网络连接**（确保iOS能访问后端）

### 可选优化项
- [ ] **申请NASA API密钥**（提升天文功能体验）
- [ ] **配置HTTPS**（提高安全性）
- [ ] **设置域名**（更专业的访问地址）

## 💡 推荐配置

### 快速发布配置（本地网络）
如果想快速发布测试，可以使用本地网络部署：

1. **获取Mac的IP地址**：
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

2. **更新Info.plist**：
```xml
<key>BACKEND_BASE_URL</key>
<string>http://192.168.1.100:8787</string>  <!-- 替换为实际IP -->
```

3. **启动后端服务**：
```bash
cd backend && npm start
```

### 正式发布配置（云服务器）
用于App Store正式发布的配置：

1. **部署到云服务器**
2. **配置HTTPS域名**
3. **更新配置**：
```xml
<key>BACKEND_BASE_URL</key>
<string>https://api.chongyu.com</string>
```

## ❓ 常见问题

**Q：为什么不直接在iOS中调用DeepSeek API？**
A：出于安全考虑，API密钥不应暴露在客户端代码中。后端代理模式更安全。

**Q：本地部署适合App Store发布吗？**
A：不适合。App Store要求应用能够独立运行，不依赖用户的特定网络环境。

**Q：NASA API密钥是必需的吗？**
A：不是必需的。应用可以使用DEMO_KEY，但会有请求限制。真实密钥可以提供更好的体验。 