# API安全配置指南

## 概述
本文档说明虫遇app中所有API调用的正确配置方式，确保没有硬编码的API密钥和端点。

## API配置架构

### 1. 配置优先级
所有API服务都遵循以下配置优先级（从高到低）：
1. 环境变量 (ProcessInfo.processInfo.environment)
2. Info.plist配置
3. UserDefaults
4. 默认值/备用配置

### 2. 支持的API服务

#### AI网络服务 (AINetworkService)
- **用途**: DeepSeek AI API调用
- **配置项**:
  - `BACKEND_BASE_URL`: 后端代理服务地址
  - `DEEPSEEK_PRIMARY_ENDPOINT`: 主要API端点
  - `DEEPSEEK_FALLBACK_ENDPOINT`: 备用API端点
- **认证**: 通过AppAccountManager的X-App-Account-Token

#### 钱包服务 (WalletService)
- **用途**: 余额查询和购买确认
- **配置项**:
  - `BACKEND_BASE_URL`: 后端服务地址
- **认证**: 通过AppAccountManager的X-App-Account-Token

#### 天文API服务 (AstronomyAPIService)
- **用途**: NASA天文数据获取
- **配置项**:
  - `NASA_API_BASE_URL`: NASA API基础地址
  - `NASA_API_KEY`: NASA API密钥
- **认证**: API密钥认证

#### StoreKit内购服务
- **用途**: 应用内购买
- **配置**: StoreKit.storekit配置文件
- **认证**: App Store Connect配置

## 安全最佳实践

### 1. 密钥管理
- ✅ 所有敏感密钥存储在iOS Keychain中
- ✅ 测试环境使用固定测试令牌
- ✅ 生产环境密钥通过安全渠道分发

### 2. 配置管理
- ✅ 支持多环境配置切换
- ✅ Info.plist作为默认配置来源
- ✅ 支持运行时配置覆盖

### 3. 错误处理
- ✅ API调用失败时自动切换端点
- ✅ 详细的错误日志记录
- ✅ 用户友好的错误提示

## 部署检查清单

### 生产环境部署前
- [ ] 确认所有API密钥已从代码中移除
- [ ] 验证Info.plist中的配置是否正确
- [ ] 测试API端点切换功能
- [ ] 确认NASA API密钥为真实有效密钥

### 安全审计
- [ ] 检查是否有硬编码的URL或密钥
- [ ] 验证Keychain存储是否正常工作
- [ ] 测试网络请求的错误处理
- [ ] 确认日志中不包含敏感信息

## 配置示例

### Info.plist配置
```xml
<key>BACKEND_BASE_URL</key>
<string>https://your-backend.com</string>
<key>DEEPSEEK_PRIMARY_ENDPOINT</key>
<string>https://api.deepseek.com/v1/chat/completions</string>
<key>NASA_API_KEY</key>
<string>YOUR_REAL_NASA_API_KEY</string>
```

### 环境变量覆盖
```bash
export BACKEND_BASE_URL="http://localhost:8787"
export NASA_API_KEY="DEMO_KEY"
```

## 问题排查

### 常见问题
1. **API调用失败**: 检查网络连接和API密钥有效性
2. **端点切换不生效**: 验证APIConfigManager配置
3. **认证失败**: 检查AppAccountManager的token生成

### 调试工具
- 使用控制台日志查看API调用详情
- 通过设置页面验证API密钥状态
- 使用网络调试工具检查请求内容

## 联系方式
如有API配置相关问题，请联系开发团队。 