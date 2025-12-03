#!/bin/bash

# 更新关键视图文件，使用ImageHelper加载头像
echo "更新关键视图文件，使用ImageHelper加载头像..."

# 修改HomeView.swift
home_view_file="虫遇/Views/Home/HomeView.swift"
if [ -f "$home_view_file" ]; then
  # 备份原文件
  cp "$home_view_file" "${home_view_file}.bak"
  
  # 添加import语句（如果没有）
  if ! grep -q "import SwiftUI" "$home_view_file"; then
    sed -i '' '1i\
import SwiftUI
' "$home_view_file"
  fi
  
  echo "已备份 HomeView.swift"
fi

# 修改PostCardView.swift
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.bak"
  
  # 修改头像加载代码
  sed -i '' 's|Image(post.userAvatar)|CharacterAvatarSimple(post.userAvatar)|g' "$post_card_file"
  
  echo "已修改 PostCardView.swift"
fi

# 修改FullscreenPostDetailView.swift
detail_view_file="虫遇/Views/Components/FullscreenPostDetailView.swift"
if [ -f "$detail_view_file" ]; then
  # 备份原文件
  cp "$detail_view_file" "${detail_view_file}.bak"
  
  # 修改头像加载代码
  sed -i '' 's|Image(nextPost.userAvatar)|CharacterAvatarSimple(nextPost.userAvatar)|g' "$detail_view_file"
  
  echo "已修改 FullscreenPostDetailView.swift"
fi

# 创建一个示例视图来展示修复效果
cat > "虫遇/Views/Debug/FixedAvatarDemoView.swift" << EODEMO
import SwiftUI

/**
 * 修复后的头像演示视图
 * 展示使用ImageHelper加载头像的效果
 */
struct FixedAvatarDemoView: View {
    let characters = ["einstein", "shakespeare", "davinci", "kongzi", "newton"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("头像修复演示").font(.title)
                    
                    // 展示修复后的头像
                    ForEach(characters, id: \.self) { id in
                        HStack(spacing: 20) {
                            // 使用CharacterAvatarSimple
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text("CharacterAvatarSimple")
                                    .font(.caption)
                            }
                            
                            // 使用ImageHelper
                            VStack {
                                ImageHelper.loadCharacterAvatar(id, size: 60)
                                Text("ImageHelper")
                                    .font(.caption)
                            }
                            
                            // 显示角色ID
                            Text(id)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("头像修复演示")
        }
    }
}

struct FixedAvatarDemoView_Previews: PreviewProvider {
    static var previews: some View {
        FixedAvatarDemoView()
    }
}
EODEMO

echo "已创建演示视图: 虫遇/Views/Debug/FixedAvatarDemoView.swift"

# 创建一个主入口点，方便测试
cat > "虫遇/Views/Debug/AvatarFixTestView.swift" << EOMAIN
import SwiftUI

/**
 * 头像修复测试入口
 * 提供多种测试视图的入口
 */
struct AvatarFixTestView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("修复演示", destination: FixedAvatarDemoView())
                NavigationLink("ImageHelper测试", destination: ImageHelperTestView())
                
                Section(header: Text("测试特定角色")) {
                    ForEach(["einstein", "shakespeare", "davinci", "kongzi", "newton"], id: \.self) { id in
                        NavigationLink(id, destination: SingleAvatarTestView(characterId: id))
                    }
                }
            }
            .navigationTitle("头像修复测试")
        }
    }
}

/**
 * 单个角色头像测试视图
 */
struct SingleAvatarTestView: View {
    let characterId: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("角色ID: \(characterId)")
                .font(.headline)
            
            VStack(spacing: 10) {
                Text("CharacterAvatarSimple").font(.caption)
                CharacterAvatarSimple(characterId, size: 100)
            }
            
            VStack(spacing: 10) {
                Text("ImageHelper").font(.caption)
                ImageHelper.loadCharacterAvatar(characterId, size: 100)
            }
            
            // 显示路径信息
            VStack(alignment: .leading, spacing: 5) {
                Text("路径信息:").font(.headline)
                Text("直接路径: \(UIImage(named: characterId) != nil ? "可用" : "不可用")")
                Text("历史人物路径: \(UIImage(named: "HistoricalFigures/\(characterId)") != nil ? "可用" : "不可用")")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
        .navigationTitle(characterId)
    }
}
EOMAIN

echo "已创建测试入口: 虫遇/Views/Debug/AvatarFixTestView.swift"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修改完成！请重启Xcode并清除项目缓存。"
echo "提示: 可以使用 AvatarFixTestView() 来测试修复效果"
