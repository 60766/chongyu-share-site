# 🔐 API安全配置指南

## 📋 概述

本项目采用**安全的代理架构**，所有外部API调用都通过后端服务代理，确保API密钥不会暴露在客户端。

## 🏗️ 安全架构

```
iOS应用 → 后端服务 → 外部API提供商
       ↑         ↑
  应用Token   API密钥(服务端安全存储)
```

## ⚙️ 配置步骤

### 1. 后端配置 (backend/.env)

```bash
# API提供商配置
PROVIDER_ENDPOINT=https://ark.cn-beijing.volces.com/api/v3/chat/completions
PROVIDER_MODEL=deepseek-r1-250120

# 🔑 将此处替换为您的真实API密钥
PROVIDER_API_KEY=your_actual_api_key_here

# 其他配置
MOCK_PROVIDER=0
CREDITS_PER_1K_TOKENS=100
PORT=8787
```

### 2. iOS应用配置 (虫遇/Info.plist)

```xml
<!-- 后端服务地址 -->
<key>BACKEND_BASE_URL</key>
<string>http://127.0.0.1:8787</string>

<!-- ⚠️ 客户端不需要真实API密钥，已设置为占位符 -->
<key>DEEPSEEK_API_KEY</key>
<string>PLACEHOLDER_API_KEY</string>
```

## ✅ 安全特性

### 1. **API密钥保护**
- ✅ API密钥只存储在服务端
- ✅ 客户端从不直接调用外部API
- ✅ 所有AI请求通过 `/api/proxy` 代理

### 2. **用户认证**
- ✅ 使用应用Token (`X-App-Account-Token`)
- ✅ 服务端验证用户积分余额
- ✅ 防止未授权使用

### 3. **使用监控**
- ✅ 服务端记录所有API调用
- ✅ 积分消耗跟踪
- ✅ 用户使用统计

## 🚫 已禁用的不安全功能

以下测试文件已被安全化处理，不再直接调用外部API：
- `DirectAPITest.swift`
- `DeepSeekTest.swift` 
- `ARKAPITest.swift`
- `TestDeepSeekAPI.swift`

## 📱 正确的API调用方式

### ✅ 推荐方式 - 通过后端代理

```swift
// 使用 AINetworkService (已实现)
let service = AINetworkService()
service.sendRequest(prompt: "你好")
    .sink(
        receiveCompletion: { completion in
            // 处理完成
        },
        receiveValue: { response in
            // 处理响应
        }
    )
```

### ❌ 错误方式 - 直接调用外部API

```swift
// ❌ 不要这样做！
let request = URLRequest(url: URL(string: "https://api.deepseek.com/...")!)
request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
```

## 🔧 开发环境设置

1. **启动后端服务**
```bash
cd backend
node server.js
```

2. **验证后端健康状态**
```bash
curl http://127.0.0.1:8787/health
# 应返回: {"ok":true}
```

3. **测试API代理**
```bash
curl -X POST http://127.0.0.1:8787/api/proxy \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: test-token" \
  -d '{"messages":[{"role":"user","content":"测试"}]}'
```

## 🛡️ 安全检查清单

- [ ] 后端 `.env` 文件包含真实API密钥
- [ ] 后端服务正常运行
- [ ] iOS应用使用占位符API密钥
- [ ] 所有AI功能通过 `/api/proxy` 调用
- [ ] 测试文件不包含真实API密钥
- [ ] `.env` 文件已添加到 `.gitignore`

## 📞 技术支持

如有API配置问题，请检查：
1. 后端服务是否运行
2. 网络连接是否正常
3. API密钥是否有效
4. 用户积分是否充足

---

**重要提醒**: 永远不要在客户端代码或版本控制中存储真实的API密钥！ 