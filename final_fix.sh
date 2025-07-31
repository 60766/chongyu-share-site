#!/bin/bash

# 最终修复脚本
echo "执行最终修复..."

# 创建一个统一的图片加载辅助类
cat > "虫遇/Utils/ImageHelper.swift" << EOHELPER
import SwiftUI

/**
 * 图片加载辅助类
 * 提供统一的图片加载方法，解决不同路径的问题
 */
struct ImageHelper {
    /**
     * 加载角色头像
     * @param id 角色ID
     * @return 图片视图
     */
    static func loadCharacterAvatar(_ id: String, size: CGFloat = 40) -> some View {
        // 尝试多种路径加载图片
        if let image = UIImage(named: id) {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            )
        } else if let image = UIImage(named: "HistoricalFigures/\(id)") {
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
     * @param id 角色ID
     * @return 是否可用
     */
    static func isCharacterAvatarAvailable(_ id: String) -> Bool {
        return UIImage(named: id) != nil || UIImage(named: "HistoricalFigures/\(id)") != nil
    }
}

/**
 * 角色头像视图
 * 简化版的角色头像显示组件
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
EOHELPER

echo "已创建图片加载辅助类: 虫遇/Utils/ImageHelper.swift"

# 创建测试视图
cat > "虫遇/Utils/AvatarTestView.swift" << EOTESTVIEW
import SwiftUI

/**
 * 头像测试视图
 * 用于测试不同角色头像的加载效果
 */
struct AvatarTestView: View {
    let characterIds = [
        "einstein", "shakespeare", "davinci", "kongzi", "newton",
        "libai", "holmes", "curie", "socrates", "plato"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("角色头像测试").font(.title)
                
                // 测试直接使用Image
                Group {
                    Text("方法1: 直接使用Image").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                Image(id)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 测试使用ImageHelper
                Group {
                    Text("方法2: 使用ImageHelper").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
                
                Divider()
                
                // 测试使用完整路径
                Group {
                    Text("方法3: 使用完整路径").font(.headline)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                        ForEach(characterIds, id: \.self) { id in
                            VStack {
                                if let image = UIImage(named: "HistoricalFigures/\(id)") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                } else {
                                    Circle()
                                        .fill(Color.red.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                }
                                Text(id).font(.caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}
EOTESTVIEW

echo "已创建头像测试视图: 虫遇/Utils/AvatarTestView.swift"

echo "修复完成！请重启Xcode并清除项目缓存。"
echo "提示: 可以使用 AvatarTestView() 来测试不同方式加载头像的效果"
