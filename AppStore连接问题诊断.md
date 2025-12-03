# App Store 连接问题诊断指南

## 🔍 问题现象

应用显示"正在连接 App Store..."，但一直无法加载产品列表。

## 📋 可能原因和解决方案

### 1. App Store Connect 产品配置问题 ⚠️（最常见）

**检查步骤：**
1. 访问 https://appstoreconnect.apple.com
2. 进入 **我的 App** → 选择你的应用
3. 进入 **App 内购买项目**
4. 检查以下产品是否存在：
   - `com.lishilong.chongyu.100energy`
   - `com.lishilong.chongyu.300energy`
   - `com.lishilong.chongyu.700energy`
   - `com.lishilong.chongyu.1400energy`

**必须满足的条件：**
- ✅ 产品状态必须是 **"准备提交"** 或 **"等待审核"** 或 **"已批准"**
- ✅ Bundle ID 必须匹配：`com.lishilong.chongyu`
- ✅ 产品类型必须是 **"消耗型"**（Consumable）
- ✅ 价格必须已设置

**如果产品不存在或状态不对：**
- 创建缺失的产品
- 确保产品状态正确
- 等待几分钟让 Apple 服务器同步

---

### 2. 网络连接问题

**检查步骤：**
1. 确保 iPad 已连接到互联网
2. 尝试打开 Safari，访问任意网站
3. 检查是否使用了 VPN（某些 VPN 可能阻止 App Store 连接）

**解决方案：**
- 切换到 Wi-Fi 网络
- 关闭 VPN（如果开启）
- 重启 iPad 的网络设置

---

### 3. Apple ID 登录状态问题

**检查步骤：**
1. 在 iPad 上：**设置 → App Store**
2. 检查是否已登录 Apple ID

**重要：**
- 如果**已登录**：可能无法使用 Sandbox 环境
- 如果**未登录**：可能无法连接到 App Store

**解决方案：**
- **测试 Sandbox 购买**：需要退出 Apple ID（设置 → Apple ID → 退出登录）
- **但退出后可能无法加载产品列表**
- **建议**：先登录 Apple ID 加载产品，然后退出进行 Sandbox 测试

---

### 4. 开发者账号配置问题

**检查步骤：**
1. 在 Xcode 中：**项目 → TARGETS → 虫遇 → Signing & Capabilities**
2. 确认 **Team** 选择正确
3. 确认 **Bundle Identifier** 是 `com.lishilong.chongyu`

**解决方案：**
- 确保使用正确的开发者账号
- 确保账号有 App Store Connect 访问权限
- 重新选择 Team 并清理构建

---

### 5. 产品 ID 不匹配

**检查步骤：**
1. 在 App Store Connect 中查看产品 ID
2. 与代码中的产品 ID 对比（`StoreKitManager.swift` 第 24-29 行）

**必须完全匹配：**
```swift
"com.lishilong.chongyu.100energy"
"com.lishilong.chongyu.300energy"
"com.lishilong.chongyu.700energy"
"com.lishilong.chongyu.1400energy"
```

---

### 6. 应用未提交审核（首次测试）

**重要提示：**
- 如果应用**从未提交过审核**，产品可能无法在真机上加载
- 需要先在 App Store Connect 中创建应用和产品
- 产品状态至少需要是 **"准备提交"**

---

## 🔧 快速诊断步骤

### 步骤 1：检查 Xcode 控制台日志

在 Xcode 中运行应用，查看控制台输出，寻找：
- `[IAP] 🔄 开始请求产品信息...`
- `[IAP] ❌ 加载商品失败: ...`
- `[IAP] ⚠️ 没有找到任何商品`

这些日志会告诉你具体的问题。

### 步骤 2：检查 App Store Connect

1. 登录 https://appstoreconnect.apple.com
2. 确认应用已创建
3. 确认所有 4 个产品已创建且状态正确

### 步骤 3：检查网络和登录状态

1. 确保网络正常
2. 尝试登录 Apple ID（如果未登录）
3. 等待几分钟后重试

### 步骤 4：重新安装应用

1. 删除应用
2. 清理构建（Cmd + Shift + K）
3. 重新运行

---

## 💡 推荐的测试流程

### 方案 A：使用 Sandbox 环境（推荐）

1. **先登录 Apple ID**（用于加载产品列表）
2. **打开应用，等待产品加载完成**
3. **退出 Apple ID**（设置 → Apple ID → 退出登录）
4. **执行购买**（系统会提示登录，使用 Sandbox 账号）

### 方案 B：使用 StoreKit Configuration（仅开发测试）

1. **重新启用 StoreKit Configuration**（在 Scheme 中）
2. **在模拟器或真机上测试**
3. **注意**：这种方式 receipt 是 JSON 格式，不是真实的 JWT

---

## 🎯 最可能的原因

根据你的情况，最可能的原因是：

1. **App Store Connect 中产品未创建或状态不对**（80% 可能性）
2. **网络连接问题**（15% 可能性）
3. **Apple ID 登录状态问题**（5% 可能性）

---

## 📝 下一步操作

1. **检查 App Store Connect**：确认所有产品已创建且状态正确
2. **查看 Xcode 控制台**：查看具体的错误信息
3. **尝试登录 Apple ID**：先登录加载产品，再退出进行 Sandbox 测试

告诉我你检查的结果，我会帮你进一步诊断！

