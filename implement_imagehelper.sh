#!/bin/bash

# 实现ImageHelper并应用到项目中
echo "开始实现ImageHelper并应用到项目中..."

# 1. 确保ImageHelper.swift文件存在
if [ ! -f "虫遇/Utils/ImageHelper.swift" ]; then
  echo "创建ImageHelper.swift文件..."
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
  echo "已创建ImageHelper.swift文件"
fi

# 2. 查找需要修改的文件
echo "查找需要修改的文件..."
find 虫遇/Views -type f -name "*.swift" -exec grep -l "Image(" {} \; > files_to_check.txt
find 虫遇/Views -type f -name "*.swift" -exec grep -l "UIImage(named:" {} \; >> files_to_check.txt

# 3. 修改CharacterAvatarView.swift文件
avatar_view_file="虫遇/Views/Components/CharacterAvatarView.swift"
if [ -f "$avatar_view_file" ]; then
  echo "修改 $avatar_view_file..."
  # 备份原文件
  cp "$avatar_view_file" "${avatar_view_file}.bak"
  
  # 查找并替换图片加载代码
  sed -i '' '/if let _ = UIImage(named: character.avatar)/,/Circle()/c\
                        CharacterAvatarSimple(character.avatar, size: size)' "$avatar_view_file"
  
  # 添加import语句
  if ! grep -q "import SwiftUI" "$avatar_view_file"; then
    sed -i '' '1s/^/import SwiftUI\n/' "$avatar_view_file"
  fi
  
  echo "已修改 CharacterAvatarView.swift"
fi

# 4. 修改PostCardView.swift文件
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  echo "修改 $post_card_file..."
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.bak"
  
  # 查找并替换图片加载代码
  sed -i '' '/} else {/,/\.overlay(/c\
                    } else {\
                        // 使用ImageHelper加载图片\
                        if ImageHelper.isCharacterAvatarAvailable(imageName) {\
                            ImageHelper.loadCharacterAvatar(imageName, size: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85))\
                                .frame(maxWidth: geometry.size.width * 0.85)\
                                .cornerRadius(3)\
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)\
                                .overlay(' "$post_card_file"
  
  echo "已修改 PostCardView.swift"
fi

# 5. 修改FullscreenPostDetailView.swift文件
detail_view_file="虫遇/Views/Components/FullscreenPostDetailView.swift"
if [ -f "$detail_view_file" ]; then
  echo "修改 $detail_view_file..."
  # 备份原文件
  cp "$detail_view_file" "${detail_view_file}.bak"
  
  # 查找并替换头像加载代码
  sed -i '' 's/Image(nextPost.userAvatar)/CharacterAvatarSimple(nextPost.userAvatar, size: 40)/g' "$detail_view_file"
  
  echo "已修改 FullscreenPostDetailView.swift"
fi

# 6. 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "实现完成！请重启Xcode并清除项目缓存。"
