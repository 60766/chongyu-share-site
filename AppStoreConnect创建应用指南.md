# App Store Connect 创建应用指南

## 📱 步骤 1：填写基本信息

### 1.1 平台（Platform）
- ✅ **勾选 `iOS 系统`**
- ❌ 不需要勾选其他平台（macOS、Apple TV、visionOS）

### 1.2 名称（Name）
- 输入应用名称，例如：**虫遇**
- 注意：最多 30 个字符
- 这个名称会显示在 App Store 中

### 1.3 主要语言（Primary Language）
- 点击下拉菜单
- 选择：**简体中文**（或 **Chinese (Simplified)**）

### 1.4 套装 ID（Bundle ID）⚠️ **重要**
- 点击下拉菜单
- **必须选择：`com.lishilong.chongyu`**

**如果下拉菜单中没有这个 Bundle ID：**
1. 点击提示文字："请前往证书、标识符和描述文件注册一个新的套装ID"
2. 或者直接访问：https://developer.apple.com/account/resources/identifiers/list
3. 点击左上角 **+** 按钮
4. 选择 **App IDs** → **继续**
5. 填写：
   - **描述**：虫遇 App
   - **Bundle ID**：选择 **Explicit**，输入 `com.lishilong.chongyu`
   - **功能**：勾选 **App 内购买项目**（In-App Purchase）
6. 点击 **继续** → **注册**
7. 返回 App Store Connect，刷新页面，应该能看到这个 Bundle ID 了

### 1.5 SKU
- 输入一个唯一的标识符，例如：`chongyu-ios-2025`
- SKU 是内部使用的，不会显示给用户
- 格式建议：`应用名-平台-年份`

### 1.6 用户访问权限（User Access Permissions）
- ✅ 选择 **`有限访问权限`**（Limited Access Permissions）
- 这个选项适合大多数情况

---

## 📝 步骤 2：提交表单

填写完所有信息后：
1. 点击页面底部的 **创建** 按钮
2. 等待应用创建完成

---

## ✅ 步骤 3：创建完成后

创建完成后，你会进入应用的详情页面。接下来需要：

### 3.1 创建 App 内购买项目

1. 在应用详情页面，找到 **App 内购买项目** 标签
2. 点击 **+** 按钮创建新产品
3. 需要创建 4 个产品：

#### 产品 1：100能量
- **类型**：消耗型（Consumable）
- **产品 ID**：`com.lishilong.chongyu.100energy`
- **参考名称**：100能量（1800虫洞币）
- **价格**：¥6
- **描述**：适合轻度使用

#### 产品 2：300能量
- **类型**：消耗型（Consumable）
- **产品 ID**：`com.lishilong.chongyu.300energy`
- **参考名称**：300能量（6000虫洞币）
- **价格**：¥18
- **描述**：性价比之选

#### 产品 3：700能量
- **类型**：消耗型（Consumable）
- **产品 ID**：`com.lishilong.chongyu.700energy`
- **参考名称**：700能量（13800虫洞币）
- **价格**：¥38
- **描述**：深度体验

#### 产品 4：1400能量
- **类型**：消耗型（Consumable）
- **产品 ID**：`com.lishilong.chongyu.1400energy`
- **参考名称**：1400能量（24000虫洞币）
- **价格**：¥68
- **描述**：无限探索

### 3.2 产品状态

创建产品后，确保产品状态是：
- ✅ **准备提交**（Ready to Submit）
- ✅ 或 **等待审核**（Waiting for Review）

**重要**：产品状态必须是 **"准备提交"** 或更高，才能在真机上测试！

---

## 🔍 检查清单

创建应用前，确保：
- ✅ 开发者账号已激活
- ✅ Bundle ID `com.lishilong.chongyu` 已注册
- ✅ Bundle ID 已启用 **App 内购买项目** 功能

创建应用后，确保：
- ✅ 应用已创建成功
- ✅ 4 个 App 内购买产品已创建
- ✅ 所有产品的状态是 **"准备提交"** 或更高
- ✅ 产品 ID 完全匹配代码中的 ID

---

## ⚠️ 常见问题

### Q1: Bundle ID 下拉菜单中没有 `com.lishilong.chongyu`？
**A:** 需要先在 Apple Developer 中注册这个 Bundle ID。按照上面的步骤 1.4 操作。

### Q2: 创建产品时提示 Bundle ID 不匹配？
**A:** 确保应用的 Bundle ID 是 `com.lishilong.chongyu`，并且已启用 App 内购买功能。

### Q3: 产品创建后状态是"缺失元数据"？
**A:** 需要填写产品的显示名称和描述（至少一种语言）。

### Q4: 产品状态一直是"准备提交"，无法测试？
**A:** 产品状态是"准备提交"就可以测试了。如果还是不行，等待几分钟让 Apple 服务器同步。

---

## 🎯 完成后的验证

创建完成后，回到 Xcode：
1. 重新运行应用
2. 应该能够加载产品列表了
3. 如果还是不行，等待 5-10 分钟让 Apple 服务器同步

---

## 📞 需要帮助？

如果遇到问题，告诉我具体的错误信息，我会帮你解决！

