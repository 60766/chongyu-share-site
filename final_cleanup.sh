#!/bin/bash

# 最终清理脚本
echo "执行最终清理..."

# 1. 修复PostCardView.swift
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  echo "完全重写PostCardView.swift文件..."
  
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.final_bak"
  
  # 检查文件大小
  file_size=$(wc -l < "$post_card_file")
  echo "PostCardView.swift文件行数: $file_size"
  
  # 创建一个临时文件
  touch "${post_card_file}.new"
  
  # 提取文件前半部分
  head -1150 "$post_card_file" > "${post_card_file}.new"
  
  # 添加修复后的代码片段
  cat >> "${post_card_file}.new" << EOFIX
                    } else {
                        // 使用ImageHelper加载图片
                        if ImageHelper.isCharacterAvatarAvailable(imageName) {
                            ImageHelper.loadCharacterAvatar(imageName, size: calculateSingleImageHeight(for: imageName, width: geometry.size.width * 0.85))
                                .frame(maxWidth: geometry.size.width * 0.85)
                                .cornerRadius(3)
                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color(.systemGray5), lineWidth: 0.5)
                                )
                        }
                    }
EOFIX
  
  # 提取文件后半部分
  tail -n +1190 "$post_card_file" >> "${post_card_file}.new"
  
  # 替换原文件
  mv "${post_card_file}.new" "$post_card_file"
  
  echo "已修复PostCardView.swift"
fi

# 2. 创建一个简单的ImageHelper
echo "创建简洁版的ImageHelper..."
cat > "虫遇/Utils/ImageHelper.swift" << EOHELPER
import SwiftUI

struct ImageHelper {
    // 加载角色头像
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
    
    // 检查角色头像是否可用
    static func isCharacterAvatarAvailable(_ id: String) -> Bool {
        return UIImage(named: id) != nil || UIImage(named: "HistoricalFigures/\(id)") != nil
    }
}

// 角色头像简单视图
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

echo "已创建简洁版的ImageHelper.swift"

# 3. 删除可能存在的简洁版重复文件
if [ -f "虫遇/Utils/ImageHelper_简洁版.swift" ]; then
  echo "删除ImageHelper_简洁版.swift..."
  rm "虫遇/Utils/ImageHelper_简洁版.swift"
fi

# 4. 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "最终清理完成！请重启Xcode并清除项目缓存。"
