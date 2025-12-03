# AI生成帖子显示修复说明

## 🐛 问题描述

用户反馈主页面AI生成的帖子右边显示了"· AI生成 · 文字"，希望去掉"· 文字"这部分，只保留"AI生成"。

## 📋 问题分析

在`PostCardView.swift`中，帖子的元数据显示逻辑为：
- **修改前**：时间 • AI生成 • 文字
- **修改后**：时间 • AI生成

对于用户发布的帖子，仍然显示完整信息：
- **用户发布**：时间 • 自己发布 • 文字

## 🔧 修复内容

### 修改文件
- `虫遇/Views/Components/PostCardView.swift` (主要文件)
- `\u866b\u9047/Views/Components/PostCardView.swift` (代码片段文件)

### 修改逻辑
```swift
// 修改前
Text(postSource == .userGenerated ? "自己发布" : "AI生成")
Text("•")
Text(post.images.isEmpty ? "文字" : "图文")

// 修改后
if postSource == .userGenerated {
    // 用户发布的帖子显示完整信息
    Text("自己发布")
    Text("•")
    Text(post.images.isEmpty ? "文字" : "图文")
} else {
    // AI生成的帖子只显示"AI生成"
    Text("AI生成")
}
```

## ✅ 修复效果

### AI生成的帖子
- **修改前**：`刚刚 • AI生成 • 文字`
- **修改后**：`刚刚 • AI生成`

### 用户发布的帖子
- **保持不变**：`刚刚 • 自己发布 • 文字`

## 🎯 优势

1. **界面更简洁** - AI生成帖子的元数据更简洁
2. **突出重点** - 重点突出AI生成这个特征
3. **保持一致性** - 用户发布的帖子仍然显示完整信息
4. **用户体验** - 减少冗余信息，提升阅读体验

## 📝 编译验证

修改后代码编译成功，无错误和警告。

## 🔍 相关文件

- `虫遇/Views/Components/PostCardView.swift` - 主要的帖子卡片组件
- `虫遇/Views/Home/HomeView.swift` - 主页面，使用PostCardView
- `\u866b\u9047/Views/Components/PostCardView.swift` - 代码片段文件（已同步修改）

---

✅ **修复完成**：AI生成帖子现在只显示"AI生成"，不再显示"· 文字"。 