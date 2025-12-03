# UserDataManager.swift 修复进度

**文件大小**：约2133行  
**总print语句**：127个  
**已修复**：约47个（37%）  
**剩余**：约80个（63%）

---

## ✅ 已修复的部分

1. **数据清理相关**（6个print）
   - clearAllUserData()
   - clearUserProfile()
   - clearCustomCharacters()
   - clearChatHistory()
   - clearUserPreferences()

2. **数据导出相关**（约25个print）
   - exportUserData() 主要部分
   - 帖子图片备份相关
   - 角色头像备份相关
   - 点赞记录备份相关
   - 关注角色备份相关

3. **图片加载相关**（约10个print）
   - loadPostImage()
   - loadImageFromURL()
   - loadCharacterAvatar()

4. **数据备份相关**（约6个print）
   - getConversationsData()
   - getMultiPersonChatData()

---

## ⏳ 待修复的部分

### 数据恢复相关（约60个print）

- restoreUserData() 函数中的print语句
- 恢复用户资料相关print
- 恢复成就系统相关print
- 恢复自定义角色相关print
- 恢复私聊对话相关print
- 恢复多人对话相关print
- 恢复点赞记录相关print
- 恢复关注角色相关print

### 其他辅助函数（约20个print）

- 各种辅助函数中的print语句

---

## 🔧 修复建议

由于文件很大，建议：

1. **批量修复策略**
   - 按功能模块分组修复
   - 先修复数据恢复相关（约60个）
   - 再修复其他辅助函数（约20个）

2. **使用脚本辅助**
   - 可以创建脚本批量添加#if DEBUG保护
   - 但需要仔细检查每个print的用途

3. **逐步修复**
   - 继续手动修复，确保每个print都被正确保护

---

## 📝 修复模板

```swift
// 修复前
print("✅ [恢复] 用户名: \(username)")

// 修复后
#if DEBUG
print("✅ [恢复] 用户名: \(username)")
#endif
```

---

**最后更新**：2025年1月4日

