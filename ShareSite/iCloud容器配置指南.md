# iCloud 容器配置指南

## 🔍 问题诊断

从日志看：
- ✅ `ubiquityIdentityToken` 存在（已登录iCloud）
- ✅ 在真机上运行
- ✅ Bundle ID: `com.lishilong.chongyu`
- ❌ **无法获取iCloud容器URL**

**根本原因**：Xcode中虽然勾选了"iCloud Documents"，但**没有添加iCloud容器标识符**。

## 🔧 解决方案

### 步骤1：在Xcode中添加iCloud容器

1. 打开Xcode项目
2. 选择 **"虫遇"** Target（不是Project）
3. 点击 **"Signing & Capabilities"** 标签
4. 找到 **"iCloud"** 部分
5. 在 **"Containers"** 下，点击 **"+"** 按钮
6. 在弹出的对话框中，输入容器标识符：
   ```
   iCloud.com.lishilong.chongyu
   ```
7. 点击 **"OK"** 或 **"Add"**

### 步骤2：验证配置

配置完成后，你应该看到：
- ✅ "iCloud" 能力已添加
- ✅ "iCloud Documents" 已勾选
- ✅ "Containers" 下显示：`iCloud.com.lishilong.chongyu`

### 步骤3：重新构建和测试

1. 在Xcode中按 `Cmd + Shift + K` 清理构建
2. 按 `Cmd + B` 重新构建
3. 在真机上运行应用
4. 再次测试iCloud备份功能

## 📝 容器标识符格式

容器标识符的格式通常是：
```
iCloud.<Bundle ID>
```

对于你的项目：
- Bundle ID: `com.lishilong.chongyu`
- 容器标识符: `iCloud.com.lishilong.chongyu`

## ⚠️ 注意事项

1. **容器标识符必须唯一**
   - 如果该容器已被其他应用使用，需要选择不同的标识符
   - 或者使用Xcode自动生成的标识符

2. **Apple Developer后台**
   - 首次添加容器时，Xcode会自动在Apple Developer后台创建
   - 需要有效的Apple Developer账号

3. **重新签名**
   - 添加容器后，应用需要重新签名
   - Xcode会自动处理

## 🧪 测试验证

配置完成后，运行应用，查看控制台日志：

**成功标志：**
```
✅ [iCloud] 使用默认容器成功
或
✅ [iCloud] 使用容器ID成功: iCloud.com.lishilong.chongyu
✅ [iCloud] 成功获取容器URL: /private/var/mobile/Library/Mobile Documents/iCloud.com.lishilong.chongyu
```

**如果仍然失败：**
- 检查容器标识符是否正确
- 检查Apple Developer账号权限
- 尝试删除并重新添加容器

## 🔄 替代方案（如果仍然无法工作）

如果配置容器后仍然无法工作，可以考虑：

1. **使用本地文件系统作为fallback**
   - 保存到应用的Documents目录
   - 用户可以通过iTunes文件共享访问

2. **使用CloudKit（更复杂）**
   - 需要更多配置
   - 但功能更强大

3. **使用第三方云存储**
   - 如Dropbox、Google Drive等
   - 需要集成SDK

## 📞 需要帮助？

如果按照上述步骤操作后仍然无法工作，请提供：
1. Xcode中iCloud配置的截图
2. 控制台的完整错误日志
3. Apple Developer账号状态

