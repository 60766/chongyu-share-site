# 快速测试真实 IAP 购买

## ✅ 应用未上架也可以测试！

---

## 🚀 快速开始（3步）

### 步骤1：创建 Sandbox 测试账号（5分钟）

1. 登录 [App Store Connect](https://appstoreconnect.apple.com)
2. 进入 **用户和访问** → **沙盒技术测试员**
3. 点击 **+** 添加测试账号
4. 填写信息：
   - 邮箱：`test@example.com`（任意邮箱，不需要真实存在）
   - 密码：`Test123456`
   - 国家：中国
   - 姓名：测试用户

### 步骤2：在真机上测试购买（2分钟）

1. **使用真机**（不是模拟器）
2. 通过 Xcode 安装应用
3. **不要**在设置中登录 Apple ID
4. 打开应用 → 充值页面 → 点击购买
5. 弹出登录时，**输入 Sandbox 测试账号**
6. 完成购买

### 步骤3：查看验证结果（1分钟）

```bash
ssh root@121.40.184.29
pm2 logs chongyu-backend --lines 50 | grep -E "IAP|Verify"
```

**预期看到：**
```
[IAP Verify] ✅ 交易验证成功 { productId: 'xxx', transactionId: 'xxx' }
```

---

## 📱 重要提示

### ✅ 必须使用真机
- 模拟器可能无法生成真实的 receipt
- 真机 + Sandbox = 最接近真实环境

### ✅ 不要在设置中登录 Apple ID
- 如果已登录，先退出
- 或在购买时选择"使用其他账号"

### ✅ Sandbox 不会扣费
- 这是测试环境
- 不会产生真实费用

---

## 🔍 如何确认 receipt 是真实的？

### 检查服务器日志

如果看到以下日志，说明 receipt 是真实的：

```
✅ 验证成功：
[IAP Verify] ✅ 交易验证成功 { productId: 'xxx', transactionId: 'xxx' }

❌ 验证失败（receipt 格式问题）：
[IAP Verify] JWT verification failed: Invalid Compact JWS
```

### 检查 receipt 格式

真实的 receipt（JWT）特征：
- 很长的字符串（几百到几千字符）
- 格式：`eyJhbGciOiJSUzI1NiIsIng1YyI6WyJ...`
- 三部分用 `.` 分隔

---

## 🐛 常见问题

### Q: 购买时没有弹出登录？

**解决：**
1. 设置 → Apple ID → 退出登录
2. 或在购买时选择"使用其他账号"

### Q: receipt 验证失败？

**可能原因：**
- 使用了模拟器（不是真机）
- receipt 格式不正确

**解决：**
- 使用真机 + Sandbox 账号测试

### Q: 如何确认测试成功？

**检查点：**
1. ✅ 服务器收到购买请求
2. ✅ receipt 是有效的 JWT 格式
3. ✅ 验证成功（看到 `✅ 交易验证成功`）
4. ✅ 余额正确增加

---

## 📋 测试清单

- [ ] 创建 Sandbox 测试账号
- [ ] 在真机上安装应用
- [ ] 退出设备上的 Apple ID（或在购买时选择其他账号）
- [ ] 执行购买流程
- [ ] 使用 Sandbox 账号登录
- [ ] 完成购买
- [ ] 查看服务器日志确认验证成功

---

## 💡 提示

你的 iOS 代码已经正确配置了：
- ✅ `StoreKitManager.swift` 中已发送 `transaction.jsonRepresentation`（真实的 receipt）
- ✅ `WalletService.swift` 中已发送 receipt 到后端
- ✅ 后端已部署验证功能

**只需要：**
1. 创建 Sandbox 账号
2. 在真机上测试购买
3. 查看日志确认验证结果

---

## 🎯 总结

**应用未上架也可以测试真实 receipt！**

**推荐方式：**
1. ✅ Sandbox 测试账号（App Store Connect）
2. ✅ 真机测试（不是模拟器）
3. ✅ 查看服务器日志（确认验证结果）

这样就能完整测试 IAP 购买和验证流程了！

