# 禁用 StoreKit Configuration - 使用真实 Sandbox 环境

## 🔍 问题原因

你的 Xcode Scheme 中启用了 `StoreKit.storekit` 配置文件。即使是在真机上运行，也会使用 Xcode 测试环境，receipt 会是 JSON 对象格式而不是 JWT 格式。

## ✅ 解决方法：在 Xcode 中禁用 StoreKit Configuration

### 方法 1：通过 Xcode UI 禁用（推荐）

1. **打开 Xcode**
2. **选择 Scheme**：
   - 点击顶部工具栏中的 Scheme 选择器（显示 "虫遇" 的地方）
   - 选择 **Edit Scheme...**

3. **禁用 StoreKit Configuration**：
   - 在左侧选择 **Run**（运行）
   - 在右侧找到 **StoreKit Configuration** 部分
   - 取消勾选 **StoreKit Configuration File** 或选择 **None**
   - 点击 **Close** 保存

4. **重新运行应用**：
   - 在真机上重新运行应用
   - 现在应该会使用真实的 Sandbox 环境

### 方法 2：直接修改 Scheme 文件（如果方法 1 不行）

如果通过 UI 无法禁用，可以直接修改 scheme 文件：

1. **关闭 Xcode**
2. **编辑 scheme 文件**：
   - 文件位置：`虫遇.xcodeproj/xcshareddata/xcschemes/虫遇.xcscheme`
   - 找到第 77-79 行：
     ```xml
     <StoreKitConfigurationFileReference
        identifier = "../../虫遇/StoreKit.storekit">
     </StoreKitConfigurationFileReference>
     ```
   - **删除这 3 行**

3. **重新打开 Xcode 并运行**

---

## 🧪 验证是否成功

禁用 StoreKit Configuration 后：

1. **在真机上运行应用**
2. **退出 Apple ID**（设置 → Apple ID → 退出登录）
3. **使用 Sandbox 账号购买**
4. **检查服务器日志**：
   ```bash
   ./check_latest_iap.sh
   ```

应该看到：
- ✅ `environment: 'Sandbox'`（不是 'Xcode'）
- ✅ JWT 格式的 receipt 验证
- ✅ `[IAP Verify] ✅ 交易验证成功`（JWT 格式）

---

## 📝 注意事项

- **禁用后**：应用会使用真实的 Sandbox 环境，需要真实的 Sandbox 账号
- **重新启用**：如果需要测试，可以重新勾选 StoreKit Configuration
- **生产环境**：上线时不需要 StoreKit Configuration，会自动使用生产环境

---

## 🎯 完整测试流程（禁用后）

1. ✅ 在 Xcode 中禁用 StoreKit Configuration
2. ✅ 在真机上运行应用
3. ✅ 退出设备上的 Apple ID
4. ✅ 在应用中输入 Sandbox 账号
5. ✅ 开启 "使用 Sandbox 账号购买" 开关
6. ✅ 执行购买，使用 Sandbox 账号登录
7. ✅ 检查服务器日志，确认是 Sandbox 环境

