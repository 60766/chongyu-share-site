#!/bin/bash

# 最终集成脚本
echo "执行最终集成..."

# 创建一个README文件，说明如何使用ImageHelper
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

echo "已创建使用指南: 虫遇/Utils/README_ImageHelper使用指南.md"

# 创建一个更简洁的ImageHelper版本
cat > "虫遇/Utils/ImageHelper_简洁版.swift" << EOSIMPLE
import SwiftUI

/**
 * 图片加载辅助类（简洁版）
 * 提供统一的图片加载方法，解决不同路径的问题
 */
struct ImageHelper {
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
 * 角色头像视图
 */
struct CharacterAvatarSimple: View {
    let characterId: String
    let size: CGFloat
    
    init(_ characterId: String, size: CGFloat = 40) {
        self.characterId = characterId
        self.size = size
    }
    
    var body: some View {
        ImageHelper.loadCharacterAvatar(characterId, size: size)
    }
}
EOSIMPLE

echo "已创建简洁版ImageHelper: 虫遇/Utils/ImageHelper_简洁版.swift"

# 创建一个集成测试视图
cat > "虫遇/Views/Debug/IntegrationTestView.swift" << EOTEST
import SwiftUI

/**
 * 集成测试视图
 * 用于测试ImageHelper在实际场景中的效果
 */
struct IntegrationTestView: View {
    // 模拟帖子数据
    let posts = [
        MockPost(id: "1", userAvatar: "einstein", userName: "爱因斯坦", content: "相对论是我的重要发现"),
        MockPost(id: "2", userAvatar: "shakespeare", userName: "莎士比亚", content: "生存还是毁灭，这是个问题"),
        MockPost(id: "3", userAvatar: "davinci", userName: "达芬奇", content: "蒙娜丽莎的微笑是我的杰作"),
        MockPost(id: "4", userAvatar: "kongzi", userName: "孔子", content: "学而不思则罔，思而不学则殆"),
        MockPost(id: "5", userAvatar: "newton", userName: "牛顿", content: "我站在巨人的肩膀上")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(posts) { post in
                    PostRow(post: post)
                }
            }
            .navigationTitle("集成测试")
        }
    }
    
    // 帖子行视图
    struct PostRow: View {
        let post: MockPost
        
        var body: some View {
            HStack(spacing: 12) {
                // 使用CharacterAvatarSimple显示头像
                CharacterAvatarSimple(post.userAvatar, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userName)
                        .font(.headline)
                    
                    Text(post.content)
                        .font(.body)
                        .lineLimit(3)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // 模拟帖子模型
    struct MockPost: Identifiable {
        let id: String
        let userAvatar: String
        let userName: String
        let content: String
    }
}

struct IntegrationTestView_Previews: PreviewProvider {
    static var previews: some View {
        IntegrationTestView()
    }
}
EOTEST

echo "已创建集成测试视图: 虫遇/Views/Debug/IntegrationTestView.swift"

# 创建一个启动器视图，方便在ContentView中使用
cat > "虫遇/Views/Debug/AvatarFixLauncher.swift" << EOLAUNCHER
import SwiftUI

/**
 * 头像修复启动器
 * 在ContentView中添加此视图可快速访问测试工具
 */
struct AvatarFixLauncher: View {
    @State private var showTestView = false
    
    var body: some View {
        VStack {
            Button(action: {
                showTestView = true
            }) {
                Text("测试头像修复")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showTestView) {
                AvatarFixTestView()
            }
        }
    }
}

struct AvatarFixLauncher_Previews: PreviewProvider {
    static var previews: some View {
        AvatarFixLauncher()
    }
}
EOLAUNCHER

echo "已创建启动器视图: 虫遇/Views/Debug/AvatarFixLauncher.swift"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "集成完成！请重启Xcode并清除项目缓存。"
echo "提示: 可以在ContentView中添加AvatarFixLauncher()来快速访问测试工具"
