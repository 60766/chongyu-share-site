# 测试真实 IAP 购买指南

## 📱 应用未上架也可以测试！

即使应用还没有上架到 App Store，你也可以通过以下方式测试真实的 IAP 购买：

---

## 方法1：Sandbox 测试账号（推荐）✅

### 什么是 Sandbox？

Sandbox 是 Apple 提供的测试环境，可以模拟真实的购买流程，**不需要应用上架**。

### 设置步骤

#### 1. 创建 Sandbox 测试账号

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入 **用户和访问** → **沙盒技术测试员**
3. 点击 **+** 添加新的测试账号
4. 填写测试账号信息：
   - 邮箱（可以是任意邮箱，不需要真实存在）
   - 密码
   - 国家/地区
   - 姓名

#### 2. 在设备上登录 Sandbox 账号

**重要：** 不要在设置中登录，而是在购买时登录！

1. 在 iOS 设备上打开你的应用
2. 进入充值页面
3. 点击购买按钮
4. 系统会弹出登录提示
5. **在这里输入 Sandbox 测试账号**（不是你的 Apple ID）
6. 完成购买流程

#### 3. 验证购买

购买完成后：
- 查看服务器日志，应该能看到真实的 receipt
- receipt 是真实的 JWT，可以正常验证

---

## 方法2：StoreKit Configuration 文件（模拟器测试）

### 适用场景

- 在模拟器中测试
- 不需要真实设备
- 不需要 Sandbox 账号

### 设置步骤

#### 1. 检查是否已有 StoreKit 配置文件

你的项目中已经有 `StoreKit.storekit` 文件，检查一下：

```bash
ls -la 虫遇/StoreKit.storekit
```

#### 2. 在 Xcode 中配置

1. 打开 Xcode
2. 选择你的 Scheme（Product → Scheme → Edit Scheme）
3. 在 **Run** → **Options** 中
4. 找到 **StoreKit Configuration**
5. 选择 `StoreKit.storekit` 文件

#### 3. 运行应用

- 在模拟器中运行应用
- 购买时会使用配置文件中的测试数据
- **注意：** 这种方式生成的 receipt 可能不是真实的 JWT，验证可能会失败

---

## 方法3：TestFlight（如果应用在 TestFlight）

如果应用已经上传到 TestFlight：

1. 使用 TestFlight 安装应用
2. 使用 Sandbox 测试账号购买
3. 会生成真实的 receipt

---

## 🎯 推荐测试流程

### 步骤1：准备 Sandbox 测试账号

```bash
# 1. 登录 App Store Connect
# 2. 创建 Sandbox 测试账号
# 3. 记录账号信息（邮箱和密码）
```

### 步骤2：在真机上测试

1. **使用真机**（不是模拟器）
2. 安装应用（通过 Xcode 或 TestFlight）
3. **不要**在设置中登录 Apple ID
4. 打开应用，进入充值页面
5. 点击购买
6. 系统弹出登录提示时，**输入 Sandbox 测试账号**
7. 完成购买

### 步骤3：查看服务器日志

```bash
ssh root@121.40.184.29
pm2 logs chongyu-backend --lines 50 | grep -E "IAP|Verify"
```

**预期看到的日志：**
```
[IAP] confirm payload { appAccountToken: 'xxx', productId: 'xxx', transactionId: 'xxx', hasReceipt: true }
[IAP Verify] ✅ 交易验证成功 { productId: 'xxx', transactionId: 'xxx', purchaseDate: xxx }
```

---

## 🔍 验证真实 receipt 的特征

### 真实的 receipt（JWT）特征：

1. **格式**：`eyJhbGciOiJSUzI1NiIsIng1YyI6WyJ...`（很长的字符串）
2. **长度**：通常几百到几千字符
3. **结构**：三部分，用 `.` 分隔（header.payload.signature）

### 测试 receipt 的特征：

- 可能是简短的字符串
- 可能不是有效的 JWT 格式
- 验证时会失败

---

## 📋 测试清单

### 测试前准备

- [ ] 在 App Store Connect 中创建 Sandbox 测试账号
- [ ] 确保应用中的产品 ID 已配置
- [ ] 确保后端代码已部署（包含验证功能）
- [ ] 准备真机设备

### 测试步骤

- [ ] 在真机上安装应用
- [ ] 打开应用，进入充值页面
- [ ] 点击购买按钮
- [ ] 使用 Sandbox 账号登录
- [ ] 完成购买流程
- [ ] 查看服务器日志

### 验证结果

- [ ] 服务器收到购买请求
- [ ] receipt 格式正确（是有效的 JWT）
- [ ] 验证成功（看到 `✅ 交易验证成功`）
- [ ] 余额正确增加

---

## 🐛 常见问题

### Q1: 为什么购买时没有弹出登录提示？

**可能原因：**
- 设备上已经登录了 Apple ID
- 需要在设置中退出 Apple ID，或者在购买时选择"使用其他账号"

**解决方法：**
1. 设置 → Apple ID → 退出登录
2. 或者在购买时选择"使用其他账号"

### Q2: 为什么 receipt 验证失败？

**可能原因：**
- 使用的是 StoreKit Configuration（模拟器），不是真实的 receipt
- receipt 格式不正确

**解决方法：**
- 使用真机 + Sandbox 账号测试
- 确保 receipt 是有效的 JWT 格式

### Q3: 如何确认 receipt 是真实的？

**检查方法：**
```bash
# 查看服务器日志
pm2 logs chongyu-backend | grep -E "IAP|Verify"

# 如果看到：
# [IAP Verify] ✅ 交易验证成功
# 说明 receipt 是真实的，验证通过了
```

### Q4: Sandbox 购买会扣费吗？

**答案：** 不会！Sandbox 是测试环境，不会产生真实费用。

---

## 💡 最佳实践

### 1. 使用真机测试

- 模拟器可能无法生成真实的 receipt
- 真机 + Sandbox 账号是最接近生产环境的测试方式

### 2. 准备多个 Sandbox 账号

- 可以创建多个测试账号
- 测试不同的购买场景

### 3. 记录测试结果

- 记录每次购买的 transactionId
- 查看服务器日志确认验证结果
- 确认余额是否正确增加

---

## 📝 测试脚本

测试完成后，可以运行测试脚本验证：

```bash
# 查看服务器日志
ssh root@121.40.184.29
pm2 logs chongyu-backend --lines 100 | grep -E "IAP|Verify"

# 查看最近的交易记录
cd /var/www/chongyu-backend
cat server-data.json | jq '.transactions[] | select(.meta.productId != null) | {ref, productId, verification}' | tail -5
```

---

## ✅ 总结

**应用未上架也可以测试真实 receipt！**

推荐方式：
1. ✅ **使用 Sandbox 测试账号**（最接近真实环境）
2. ✅ **在真机上测试**（不是模拟器）
3. ✅ **查看服务器日志**（确认验证结果）

这样就能测试完整的 IAP 购买和验证流程了！

