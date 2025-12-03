# 🚀 后端服务安全启动指南

## 📋 快速开始

### 1. 配置API密钥

在 `backend/.env` 文件中，将占位符替换为您的真实API密钥：

```bash
# 编辑后端环境变量文件
cd backend
nano .env

# 将 your_actual_api_key_here 替换为真实密钥
PROVIDER_API_KEY=your_actual_api_key_here
```

### 2. 启动后端服务

```bash
cd backend
node server.js
```

### 3. 验证服务状态

```bash
# 检查健康状态
curl http://127.0.0.1:8787/health

# 应返回: {"ok":true}
```

## 🔐 安全检查

启动前请确认：

- [ ] `backend/.env` 包含真实API密钥
- [ ] 客户端代码中没有硬编码密钥
- [ ] 所有测试文件使用占位符密钥
- [ ] `.env` 文件已被 `.gitignore` 忽略

## 🛠️ 故障排除

### 问题：API调用失败
- 检查 `PROVIDER_API_KEY` 是否为真实密钥
- 确认API密钥有效且有余额

### 问题：服务无法启动
- 检查端口8787是否被占用
- 确认 `backend/.env` 文件存在

### 问题：iOS应用连接失败
- 确认后端服务正在运行
- 检查网络配置和防火墙设置

## 📱 iOS应用配置

iOS应用会自动使用安全的代理模式：
- 通过 `/api/proxy` 调用AI服务
- 使用应用Token认证
- 不需要在客户端配置真实API密钥

---

**重要**: 请妥善保管您的API密钥，不要提交到版本控制系统！ 