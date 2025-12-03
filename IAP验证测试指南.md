# IAP 验证功能测试指南

## 📋 测试前准备

### 1. 确认配置

检查 `backend/production.env` 中的配置：

```bash
# 查看当前配置
cat backend/production.env | grep IAP_VERIFY_STRICT

# 应该看到：
# IAP_VERIFY_STRICT=0  # 非严格模式（开发/测试）
# 或
# IAP_VERIFY_STRICT=1  # 严格模式（生产环境）
```

### 2. 重启后端服务

```bash
# 如果使用 PM2
pm2 restart chongyu-backend

# 如果使用 systemd
sudo systemctl restart chongyu-backend

# 如果直接运行
# 停止当前进程，然后重新启动
node backend/server.js
```

### 3. 确认服务运行

```bash
# 检查服务状态
curl http://localhost:3000/health
# 或
curl https://api.chongyuai.com/health

# 应该返回：{"ok":true}
```

## 🧪 测试方法

### 方法1：通过 iOS 应用测试（推荐）

#### 测试步骤

1. **打开 iOS 应用**
   - 进入充值页面
   - 选择一个充值包（如 100能量 = ¥6）

2. **执行购买**
   - 点击购买按钮
   - 完成 Apple 支付流程

3. **查看日志**
   ```bash
   # 实时查看后端日志
   tail -f /var/log/chongyu-backend.log
   # 或
   pm2 logs chongyu-backend
   ```

4. **预期日志输出**

   **验证成功时：**
   ```
   [IAP] confirm payload { appAccountToken: 'xxx', productId: 'com.lishilong.chongyu.100energy', transactionId: '2000000123456789', hasReceipt: true }
   [IAP Verify] ✅ 交易验证成功 { productId: 'com.lishilong.chongyu.100energy', transactionId: '2000000123456789', purchaseDate: 1234567890 }
   ```

   **验证失败时（非严格模式）：**
   ```
   [IAP Verify] ⚠️ 交易验证失败: product_id_mismatch
   [IAP Verify] ⚠️ 验证失败但继续处理（非严格模式）
   ```

   **验证失败时（严格模式）：**
   ```
   [IAP Verify] ⚠️ 交易验证失败: product_id_mismatch
   # 然后返回 400 错误，拒绝交易
   ```

### 方法2：使用 curl 手动测试 API

#### 测试1：正常交易（有 receipt）

```bash
# 设置变量
SERVER="http://localhost:3000"  # 或你的服务器地址
TOKEN="your_app_account_token"
PRODUCT_ID="com.lishilong.chongyu.100energy"
TRANSACTION_ID="2000000123456789"
RECEIPT="eyJhbGciOiJSUzI1NiIsIng1YyI6WyJNSUlCUERDQ..."  # 真实的 JWT receipt

# 发送请求
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TRANSACTION_ID\",
    \"receipt\": \"$RECEIPT\"
  }"
```

**预期响应（验证成功）：**
```json
{
  "balance": 1800,
  "currency": "CREDITS"
}
```

**预期响应（验证失败，非严格模式）：**
```json
{
  "balance": 1800,
  "currency": "CREDITS",
  "warning": {
    "error": "product_id_mismatch",
    "strictMode": false
  }
}
```

**预期响应（验证失败，严格模式）：**
```json
{
  "error": "iap_verification_failed",
  "reason": "product_id_mismatch",
  "details": {
    "error": "product_id_mismatch",
    "strictMode": true
  }
}
```

#### 测试2：未提供 receipt

```bash
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TRANSACTION_ID\"
  }"
```

**预期日志：**
```
[IAP Verify] ⚠️ 未提供 receipt，无法验证交易真实性
```

**预期响应：**
```json
{
  "balance": 1800,
  "currency": "CREDITS",
  "warning": {
    "error": "no_receipt_provided",
    "message": "iOS端未提供交易凭证，无法验证交易真实性"
  }
}
```

#### 测试3：无效的 receipt（伪造的 JWT）

```bash
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"$PRODUCT_ID\",
    \"transactionId\": \"$TRANSACTION_ID\",
    \"receipt\": \"invalid.jwt.token\"
  }"
```

**预期日志（非严格模式）：**
```
[IAP Verify] ❌ JWT verification failed: invalid JWT
[IAP Verify] ⚠️ 验证出错但继续处理（非严格模式）
```

**预期日志（严格模式）：**
```
[IAP Verify] ❌ JWT verification failed: invalid JWT
# 返回 500 错误
```

#### 测试4：产品 ID 不匹配

```bash
# 使用真实 receipt，但 productId 不匹配
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"com.lishilong.chongyu.300energy\",  # 错误的 productId
    \"transactionId\": \"$TRANSACTION_ID\",
    \"receipt\": \"$RECEIPT\"
  }"
```

**预期日志：**
```
[IAP Verify] Product ID mismatch: expected com.lishilong.chongyu.300energy, got com.lishilong.chongyu.100energy
```

### 方法3：使用测试脚本

创建一个测试脚本 `test_iap_verification.sh`：

```bash
#!/bin/bash

SERVER="${SERVER:-http://localhost:3000}"
TOKEN="${TOKEN:-test_token_123}"

echo "=== 测试1: 正常交易（无 receipt）==="
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"com.lishilong.chongyu.100energy\",
    \"transactionId\": \"test_$(date +%s)\"
  }" | jq '.'

echo -e "\n=== 测试2: 无效 receipt ==="
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"com.lishilong.chongyu.100energy\",
    \"transactionId\": \"test_$(date +%s)\",
    \"receipt\": \"invalid.jwt.token\"
  }" | jq '.'

echo -e "\n=== 测试3: 重复交易（应该返回现有余额）==="
TX_ID="duplicate_test_$(date +%s)"
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"com.lishilong.chongyu.100energy\",
    \"transactionId\": \"$TX_ID\"
  }" | jq '.'

# 再次发送相同交易
curl -X POST "$SERVER/purchase/confirm" \
  -H "Content-Type: application/json" \
  -H "X-App-Account-Token: $TOKEN" \
  -d "{
    \"appAccountToken\": \"$TOKEN\",
    \"productId\": \"com.lishilong.chongyu.100energy\",
    \"transactionId\": \"$TX_ID\"
  }" | jq '.'
```

运行测试脚本：

```bash
chmod +x test_iap_verification.sh
./test_iap_verification.sh
```

## 🔍 验证测试结果

### 1. 检查日志输出

```bash
# 实时查看日志
tail -f /var/log/chongyu-backend.log | grep -E "IAP|Verify"

# 或使用 PM2
pm2 logs chongyu-backend --lines 100 | grep -E "IAP|Verify"
```

### 2. 检查配置日志

启动服务时应该看到：

```
[Config] IAP_VERIFY_STRICT: disabled (compatibility mode)
# 或
[Config] IAP_VERIFY_STRICT: enabled (strict mode)
```

### 3. 检查数据库/文件

```bash
# 检查交易记录
cat backend/server-data.json | jq '.transactions[] | select(.ref | contains("test"))'

# 检查已处理的交易
cat backend/server-data.json | jq '.processedIapTransactions'
```

## 📊 测试场景清单

### ✅ 基本功能测试

- [ ] **正常交易（有 receipt）**
  - 验证成功
  - 充值成功
  - 余额正确

- [ ] **正常交易（无 receipt）**
  - 记录警告
  - 充值成功（非严格模式）
  - 或拒绝交易（严格模式）

- [ ] **重复交易**
  - 返回现有余额
  - 不重复充值

### ✅ 验证失败测试

- [ ] **无效 JWT**
  - 记录错误
  - 根据模式决定是否拒绝

- [ ] **产品 ID 不匹配**
  - 检测到不匹配
  - 根据模式决定是否拒绝

- [ ] **交易 ID 不匹配**
  - 检测到不匹配
  - 根据模式决定是否拒绝

- [ ] **已退款交易**
  - 检测到 `revocationDate`
  - 拒绝交易

### ✅ 模式切换测试

- [ ] **非严格模式（IAP_VERIFY_STRICT=0）**
  - 验证失败时记录警告
  - 继续处理交易
  - 响应中包含警告信息

- [ ] **严格模式（IAP_VERIFY_STRICT=1）**
  - 验证失败时拒绝交易
  - 返回错误响应
  - 不进行充值

## 🐛 常见问题排查

### 问题1：验证总是失败

**可能原因：**
1. Bundle ID 不匹配
2. JWT 格式不正确
3. 网络问题（无法访问 App Store JWKS）

**排查步骤：**
```bash
# 1. 检查 Bundle ID 配置
grep APP_BUNDLE_ID backend/production.env

# 2. 检查网络连接
curl -I https://api.storekit.itunes.apple.com/in-app-purchase/publicKeys

# 3. 查看详细错误日志
tail -f /var/log/chongyu-backend.log | grep -A 10 "IAP Verify"
```

### 问题2：验证成功但充值失败

**可能原因：**
1. 产品 ID 不在白名单中
2. 交易 ID 已处理过

**排查步骤：**
```bash
# 1. 检查产品 ID 映射
grep -A 10 "skuToCredits" backend/server.js

# 2. 检查已处理的交易
cat backend/server-data.json | jq '.processedIapTransactions | length'
```

### 问题3：日志中没有验证信息

**可能原因：**
1. iOS 端未发送 receipt
2. 代码未正确部署

**排查步骤：**
```bash
# 1. 检查 iOS 端代码
grep -r "jsonRepresentation" 虫遇/Services/

# 2. 检查后端代码
grep -A 5 "verifyIAPTransaction" backend/server.js
```

## 📝 测试报告模板

```
测试日期：2025-XX-XX
测试人员：XXX
测试环境：开发/测试/生产

测试结果：
✅ 正常交易（有 receipt）：通过/失败
✅ 正常交易（无 receipt）：通过/失败
✅ 重复交易：通过/失败
✅ 无效 JWT：通过/失败
✅ 产品 ID 不匹配：通过/失败
✅ 严格模式：通过/失败
✅ 非严格模式：通过/失败

问题记录：
1. [问题描述]
2. [问题描述]

建议：
1. [建议内容]
2. [建议内容]
```

## 🚀 生产环境部署前检查

- [ ] 所有测试场景通过
- [ ] 日志输出正常
- [ ] 配置正确（IAP_VERIFY_STRICT=1）
- [ ] 监控告警设置完成
- [ ] 回滚方案准备就绪

## 📞 需要帮助？

如果遇到问题，请：
1. 查看日志：`tail -f /var/log/chongyu-backend.log`
2. 检查配置：`cat backend/production.env | grep IAP`
3. 查看文档：`IAP验证实现说明.md`
4. 联系开发团队

