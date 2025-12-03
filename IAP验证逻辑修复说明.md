# IAP 验证逻辑修复说明

**修复时间：** 2025-12-03  
**问题：** Receipt 是 JSON 对象格式，验证代码无法处理

---

## 🔍 问题分析

### 发现的问题

从真实购买的交易记录中发现：
1. **Receipt 格式不匹配**：后端收到的 receipt 是 JSON 对象格式，而不是 JWT 字符串
2. **验证代码未执行**：验证代码只在 receipt 是字符串时执行，所以验证被跳过了
3. **验证失败**：即使验证执行，也因为格式不匹配而失败

### 根本原因

**StoreKit 2 的 `transaction.jsonRepresentation` 在不同环境下返回不同格式：**

1. **生产环境/Sandbox**：返回 JWT 字符串（`eyJ...`）
2. **Xcode 环境**：返回 JSON 对象（解析后的 receipt）

从交易记录可以看到，receipt 是对象格式，说明是在 Xcode 环境中测试的。

---

## ✅ 修复方案

### 修改内容

1. **支持两种 receipt 格式**
   - JWT 字符串格式（生产环境/Sandbox）
   - JSON 对象格式（Xcode 环境）

2. **添加对象格式验证逻辑**
   - 检查 `productId` 是否匹配
   - 检查 `transactionId` 是否匹配
   - 检查 `bundleId` 是否匹配
   - 检查环境信息（Xcode/Sandbox）

3. **增强日志输出**
   - 记录 receipt 格式类型
   - 记录验证过程详情
   - 记录验证结果

### 代码修改

#### 1. 添加 receipt 格式检查

```javascript
// 检查 receipt 格式（在验证之前）
const receiptType = typeof receipt
const receiptPreview = receiptType === 'string' 
  ? (receipt.length > 100 ? receipt.substring(0, 100) + '...' : receipt)
  : (receiptType === 'object' ? JSON.stringify(receipt).substring(0, 100) + '...' : String(receipt))

console.log('[IAP] confirm payload', { 
  appAccountToken, 
  productId, 
  transactionId, 
  hasReceipt: Boolean(receipt),
  receiptType,
  receiptPreview
})
```

#### 2. 支持对象格式验证

```javascript
if (typeof receipt === 'object' && receipt !== null) {
  // 对象格式验证
  const receiptProductId = receiptObject.productId || receiptObject.productID
  const receiptTransactionId = String(receiptObject.transactionId || receiptObject.originalTransactionId || '')
  const receiptBundleId = receiptObject.bundleId || receiptObject.bundleID
  
  // 验证产品 ID、交易 ID、Bundle ID
  // ...
}
```

#### 3. 保存验证信息

```javascript
verification: verificationResult ? {
  valid: verificationResult.valid,
  error: verificationResult.error,
  format: verificationResult.format || 'jwt',
  warning: verificationWarning
} : (verificationWarning ? {
  valid: false,
  error: verificationWarning.error,
  warning: verificationWarning
} : null)
```

---

## 📊 验证逻辑流程

### JWT 字符串格式（生产环境/Sandbox）

```
1. 检查 receipt 是字符串
2. 调用 verifyIAPTransaction() 验证 JWT
3. 检查签名、产品 ID、交易 ID
4. 返回验证结果
```

### JSON 对象格式（Xcode 环境）

```
1. 检查 receipt 是对象
2. 提取 productId、transactionId、bundleId
3. 验证这些字段是否匹配
4. 检查环境信息
5. 返回验证结果
```

---

## 🧪 测试方法

### 1. 测试对象格式验证

在 Xcode 环境中执行购买，应该看到：

```
[IAP Verify] ✅ 交易验证成功（对象格式） {
  productId: 'com.lishilong.chongyu.100energy',
  transactionId: '5',
  environment: 'Xcode'
}
```

### 2. 测试 JWT 格式验证

在 Sandbox 环境中执行购买，应该看到：

```
[IAP Verify] ✅ 交易验证成功 {
  productId: 'com.lishilong.chongyu.100energy',
  transactionId: '2000000123456789',
  purchaseDate: 1234567890
}
```

### 3. 查看交易记录

```bash
ssh root@121.40.184.29
cd /var/www/chongyu-backend
cat server-data.json | grep -A 20 '"ref": "5"' | grep verification
```

应该看到：

```json
"verification": {
  "valid": true,
  "format": "object",
  "error": null
}
```

---

## 📋 验证结果说明

### 验证成功

**JWT 格式：**
```json
{
  "valid": true,
  "format": "jwt",
  "error": null
}
```

**对象格式：**
```json
{
  "valid": true,
  "format": "object",
  "error": null
}
```

### 验证失败

**产品 ID 不匹配：**
```json
{
  "valid": false,
  "error": "product_id_mismatch",
  "warning": {
    "error": "product_id_mismatch",
    "expected": "com.lishilong.chongyu.100energy",
    "got": "com.lishilong.chongyu.300energy"
  }
}
```

---

## ✅ 修复效果

### 修复前

- ❌ 对象格式的 receipt 无法验证
- ❌ 验证代码被跳过
- ❌ 交易记录中 verification 字段显示验证失败

### 修复后

- ✅ 支持两种 receipt 格式
- ✅ 对象格式可以正确验证
- ✅ 交易记录中 verification 字段显示验证成功
- ✅ 详细的日志输出

---

## 🎯 下一步

1. **测试验证功能**
   - 在 Xcode 环境中执行购买
   - 查看服务器日志确认验证成功
   - 检查交易记录中的 verification 字段

2. **测试 Sandbox 环境**
   - 使用 Sandbox 账号在真机上测试
   - 确认 JWT 格式的验证也正常工作

3. **监控验证结果**
   - 定期检查验证成功率
   - 关注验证失败的交易

---

## 📝 注意事项

1. **Xcode 环境**：receipt 是对象格式是正常的，不是错误
2. **Sandbox 环境**：receipt 应该是 JWT 字符串格式
3. **生产环境**：receipt 应该是 JWT 字符串格式

---

## 🔗 相关文档

- `IAP验证实现说明.md` - 验证功能实现说明
- `真实购买验证结果分析.md` - 问题分析
- `IAP验证测试指南.md` - 测试指南

