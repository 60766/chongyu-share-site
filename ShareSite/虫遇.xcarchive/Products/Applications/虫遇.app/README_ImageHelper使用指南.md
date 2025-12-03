# ImageHelper 使用指南

## 简介

ImageHelper是一个专门用于处理角色头像加载的辅助类，解决了不同路径、格式和缺失图片的问题。

## 主要功能

1. **统一加载接口**：提供一致的头像加载方法，自动处理路径问题
2. **多路径尝试**：尝试多种路径加载图片，提高成功率
3. **优雅降级**：当图片不存在时，显示占位图
4. **简化组件**：提供CharacterAvatarSimple组件，方便直接使用

## 使用方法

### 1. 使用CharacterAvatarSimple组件（推荐）

最简单的使用方式，直接替换原来的Image：

```swift
// 旧代码
Image(characterId)
    .resizable()
    .aspectRatio(contentMode: .fill)
    .frame(width: 40, height: 40)
    .clipShape(Circle())

// 新代码
CharacterAvatarSimple(characterId, size: 40)
```

### 2. 使用ImageHelper.loadCharacterAvatar方法

如果需要更多自定义：

```swift
ImageHelper.loadCharacterAvatar(characterId, size: 40)
    .overlay(
        Circle()
            .stroke(Color.blue, lineWidth: 2)
    )
```

### 3. 检查头像是否可用

```swift
if ImageHelper.isCharacterAvatarAvailable(characterId) {
    // 头像可用
} else {
    // 头像不可用
}
```

## 注意事项

1. 确保已导入SwiftUI
2. 如果需要自定义样式，建议使用CharacterAvatarSimple组件
3. 如果遇到头像不显示问题，可以使用AvatarFixTestView进行测试

## 测试工具

项目中包含以下测试工具：

- **AvatarFixTestView**：综合测试入口
- **FixedAvatarDemoView**：展示修复效果
- **ImageHelperTestView**：测试ImageHelper功能
- **SingleAvatarTestView**：测试单个角色头像
