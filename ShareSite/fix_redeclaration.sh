#!/bin/bash

# 修复重复声明问题
echo "修复重复声明问题..."

# 重命名简洁版ImageHelper
mv "虫遇/Utils/ImageHelper_简洁版.swift" "虫遇/Utils/ImageHelperSimple.swift"

# 修改文件内容，更改类名
cat > "虫遇/Utils/ImageHelperSimple.swift" << EOHELPER
import SwiftUI

/**
 * 图片加载辅助类（简洁版）
 * 提供统一的图片加载方法，解决不同路径的问题
 */
struct ImageHelperSimple {
    /**
     * 加载角色头像
     */
    static func loadCharacterAvatar(_ id: String, size: CGFloat = 40) -> some View {
        // 尝试多种路径加载图片
        if let image = UIImage(named: id) ?? UIImage(named: "HistoricalFigures/\(id)") {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            )
        } else {
            // 使用占位图
            return AnyView(
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(String(id.prefix(1)).uppercased())
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.gray)
                    )
            )
        }
    }
    
    /**
     * 检查角色头像是否可用
     */
    static func isCharacterAvatarAvailable(_ id: String) -> Bool {
        return UIImage(named: id) != nil || UIImage(named: "HistoricalFigures/\(id)") != nil
    }
}

/**
 * 角色头像视图（简洁版）
 */
struct CharacterAvatarMini: View {
    let characterId: String
    let size: CGFloat
    
    init(_ characterId: String, size: CGFloat = 40) {
        self.characterId = characterId
        self.size = size
    }
    
    var body: some View {
        ImageHelperSimple.loadCharacterAvatar(characterId, size: size)
    }
}
EOHELPER

echo "已重命名并修改简洁版ImageHelper"

# 更新使用指南
cat > "虫遇/Utils/README_ImageHelper使用指南.md" << EOREADME
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

## 简洁版（可选）

如果需要更简洁的实现，可以使用ImageHelperSimple和CharacterAvatarMini：

```swift
// 使用简洁版组件
CharacterAvatarMini(characterId, size: 40)

// 使用简洁版方法
ImageHelperSimple.loadCharacterAvatar(characterId, size: 40)
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
EOREADME

echo "已更新使用指南"

# 更新集成测试视图
sed -i '' 's/CharacterAvatarSimple/CharacterAvatarMini/g' "虫遇/Views/Debug/IntegrationTestView.swift"
echo "已更新集成测试视图"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修复完成！请重新编译项目。"
