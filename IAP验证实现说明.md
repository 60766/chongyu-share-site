# IAP 验证实现说明

## 📋 概述

已实现 App Store Server API 验证功能，用于验证应用内购买（IAP）交易的真实性。

## ✅ 实现内容

### 1. JWT 验证函数

在 `backend/server.js` 中添加了 `verifyIAPTransaction()` 函数：

- **功能**：验证 StoreKit 2 交易 JWT（`transaction.jsonRepresentation`）
- **验证项**：
  - JWT 签名验证（使用 App Store JWKS）
  - 产品 ID 匹配
  - 交易 ID 匹配
  - 交易状态检查（是否已退款）
  - 过期时间检查

### 2. `/purchase/confirm` 端点增强

- **验证流程**：
  1. 如果提供了 `receipt`（JWT），先验证交易真实性
  2. 验证失败时，根据 `IAP_VERIFY_STRICT` 配置决定是否拒绝
  3. 验证通过后，继续充值流程

### 3. 配置选项

在 `backend/production.env` 中添加了配置：

```bash
# IAP验证配置
# IAP_VERIFY_STRICT: 是否启用严格模式（1=启用，0=禁用）
# - 严格模式：验证失败直接拒绝交易
# - 非严格模式：验证失败记录警告但继续处理（向后兼容）
# 建议：生产环境设为1（严格模式），开发/测试环境设为0（非严格模式）
IAP_VERIFY_STRICT=0
```

## 🔧 使用方法

### 开发/测试环境（非严格模式）

```bash
# 在 production.env 中设置
IAP_VERIFY_STRICT=0
```

**特点**：
- 验证失败时记录警告，但继续处理交易
- 向后兼容，不影响现有功能
- 适合开发和测试阶段

### 生产环境（严格模式）

```bash
# 在 production.env 中设置
IAP_VERIFY_STRICT=1
```

**特点**：
- 验证失败时直接拒绝交易
- 提高安全性，防止伪造交易
- 符合 Apple 要求

## 📊 验证结果

### 验证成功

```
[IAP Verify] ✅ 交易验证成功
{
  productId: 'com.lishilong.chongyu.100energy',
  transactionId: '2000000123456789',
  purchaseDate: 1234567890
}
```

### 验证失败（非严格模式）

```
[IAP Verify] ⚠️ 交易验证失败: product_id_mismatch
[IAP Verify] ⚠️ 验证失败但继续处理（非严格模式）
```

**响应**：
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

### 验证失败（严格模式）

**响应**：
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

## 🔍 验证错误类型

| 错误代码 | 说明 | 处理方式 |
|---------|------|---------|
| `missing_or_invalid_jwt` | 未提供或无效的 JWT | 严格模式：拒绝；非严格模式：警告 |
| `invalid_transaction_type` | 无效的交易类型 | 严格模式：拒绝；非严格模式：警告 |
| `product_id_mismatch` | 产品 ID 不匹配 | 严格模式：拒绝；非严格模式：警告 |
| `transaction_id_mismatch` | 交易 ID 不匹配 | 严格模式：拒绝；非严格模式：警告 |
| `transaction_revoked` | 交易已退款 | 严格模式：拒绝；非严格模式：警告 |
| `transaction_expired` | 交易已过期 | 严格模式：拒绝；非严格模式：警告 |
| `jwt_verification_failed` | JWT 验证失败 | 严格模式：拒绝；非严格模式：警告 |

## 🚀 部署步骤

### 1. 更新代码

确保 `backend/server.js` 包含最新的验证代码。

### 2. 配置环境变量

在 `backend/production.env` 中设置：

```bash
IAP_VERIFY_STRICT=0  # 开发/测试环境
# 或
IAP_VERIFY_STRICT=1  # 生产环境
```

### 3. 重启服务

```bash
# 重启后端服务
pm2 restart chongyu-backend
# 或
systemctl restart chongyu-backend
```

### 4. 验证功能

查看日志确认验证功能正常工作：

```bash
# 查看日志
tail -f /var/log/chongyu-backend.log
# 或
pm2 logs chongyu-backend
```

## 📝 注意事项

### 1. iOS 端要求

iOS 端需要发送 `transaction.jsonRepresentation`（JWT 格式）作为 `receipt`：

```swift
let receiptJSON: String? = String(data: transaction.jsonRepresentation, encoding: .utf8)
```

### 2. 向后兼容

- 如果 iOS 端未提供 `receipt`，系统会记录警告但继续处理（非严格模式）
- 如果验证失败，非严格模式下会继续处理，但会在响应中包含警告信息

### 3. 生产环境建议

- **启用严格模式**：`IAP_VERIFY_STRICT=1`
- **监控验证失败**：定期检查日志，关注验证失败的交易
- **及时处理问题**：如果发现大量验证失败，及时排查原因

## 🔒 安全性提升

### 之前（未验证）

- ❌ 无法验证交易真实性
- ❌ 可能被伪造交易 ID
- ❌ 退款后仍可使用

### 现在（已验证）

- ✅ 验证交易 JWT 签名
- ✅ 检查产品 ID 和交易 ID 匹配
- ✅ 检测退款交易
- ✅ 符合 Apple 要求

## 📚 参考文档

- [Apple StoreKit 2 文档](https://developer.apple.com/documentation/storekit)
- [App Store Server API 文档](https://developer.apple.com/documentation/appstoreserverapi)
- [JWT 验证文档](https://developer.apple.com/documentation/appstoreserverapi/verifying_transaction_signatures)

## 🐛 故障排查

### 问题：验证总是失败

**可能原因**：
1. iOS 端未发送 `receipt`（JWT）
2. JWT 格式不正确
3. Bundle ID 不匹配
4. 网络问题（无法访问 App Store JWKS）

**解决方案**：
1. 检查 iOS 端是否正确发送 `receipt`
2. 查看日志中的详细错误信息
3. 确认 `APP_BUNDLE_ID` 配置正确
4. 检查服务器网络连接

### 问题：验证成功但充值失败

**可能原因**：
1. 产品 ID 不在白名单中
2. 交易 ID 已处理过（防重复机制）

**解决方案**：
1. 检查 `skuToCredits` 映射表
2. 检查 `processedIapTransactions` 集合

## ✅ 测试清单

- [ ] 验证正常交易（应该成功）
- [ ] 验证已退款交易（应该检测到退款）
- [ ] 验证产品 ID 不匹配（应该失败）
- [ ] 验证交易 ID 不匹配（应该失败）
- [ ] 验证未提供 receipt（应该警告但继续）
- [ ] 验证严格模式（验证失败应该拒绝）
- [ ] 验证非严格模式（验证失败应该警告但继续）

## 📞 支持

如有问题，请查看日志或联系开发团队。

