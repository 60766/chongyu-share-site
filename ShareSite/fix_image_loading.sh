#!/bin/bash

# 修复图片加载问题
echo "修复图片加载问题..."

# 修复CharacterAvatarView.swift中的图片加载
avatar_view_file="虫遇/Views/Components/CharacterAvatarView.swift"
if [ -f "$avatar_view_file" ]; then
  # 备份原文件
  cp "$avatar_view_file" "${avatar_view_file}.bak"
  
  # 修改图片加载代码
  sed -i '' 's|if UIImage(named: character.avatar) != nil {|if let _ = UIImage(named: character.avatar) {|g' "$avatar_view_file"
  
  echo "已修改 CharacterAvatarView.swift 中的图片加载代码"
fi

# 修复PostCardView.swift中的图片加载
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.bak"
  
  # 修改图片加载代码
  sed -i '' 's|} else if let uiImage = UIImage(named: imageName) {|} else {|g' "$post_card_file"
  sed -i '' 's|Image(uiImage: uiImage)|Image(imageName)|g' "$post_card_file"
  
  echo "已修改 PostCardView.swift 中的图片加载代码"
fi

# 创建一个测试文件来验证图片加载
cat > "虫遇/Utils/ImageLoadingTest.swift" << EOTEST
import SwiftUI

/**
 * 图片加载测试工具
 * 用于验证不同方式加载图片的效果
 */
struct ImageLoadingTest: View {
    let characterIds = ["einstein", "shakespeare", "davinci", "kongzi", "socrates"]
    
    var body: some View {
        VStack {
            Text("图片加载测试").font(.title)
            
            ForEach(characterIds, id: \.self) { id in
                HStack {
                    // 方式1: 直接使用Image(id)
                    Image(id)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(Text("方式1"))
                    
                    // 方式2: 使用Image(uiImage:)
                    if let uiImage = UIImage(named: id) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Text("方式2"))
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 50)
                            .overlay(Text("方式2失败"))
                    }
                    
                    Text(id)
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
    }
}
EOTEST

echo "已创建图片加载测试文件: 虫遇/Utils/ImageLoadingTest.swift"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修复完成！请重启Xcode并清除项目缓存。"
echo "提示: 可以创建一个临时视图来测试图片加载: ImageLoadingTest()"
