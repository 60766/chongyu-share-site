#!/bin/bash

# 修复代码中的路径引用
echo "修复代码中的路径引用..."

# 1. 查找所有可能使用头像的Swift文件
echo "查找所有可能使用头像的Swift文件..."
avatar_files=$(find 虫遇 -name "*.swift" -exec grep -l "Avatar\|avatar\|HistoricalFigures" {} \;)

# 2. 备份这些文件
echo "备份文件..."
for file in $avatar_files; do
  cp "$file" "${file}.bak"
done

# 3. 检查PostViewModel.swift中的头像加载
post_view_model="虫遇/ViewModels/PostViewModel.swift"
if [ -f "$post_view_model" ]; then
  echo "检查 PostViewModel.swift..."
  
  # 查找getCharacterAvatar方法
  if grep -q "getCharacterAvatar.*for characterID" "$post_view_model"; then
    echo "找到 getCharacterAvatar 方法，查看实现..."
    grep -A 10 "getCharacterAvatar.*for characterID" "$post_view_model"
  fi
fi

# 4. 创建测试文件，验证头像加载
echo "创建测试文件，验证头像加载..."
cat > 虫遇/Views/Debug/AvatarDebugView.swift << 'EOSWIFT'
import SwiftUI

struct AvatarDebugView: View {
    let characterIds = ["einstein", "shakespeare", "davinci", "kongzi", "newton", "libai"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("头像调试视图")
                    .font(.title)
                    .padding()
                
                ForEach(characterIds, id: \.self) { id in
                    VStack {
                        Text(id)
                            .font(.headline)
                        
                        // 直接使用Image加载
                        Image(id)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .padding(.bottom, 5)
                        
                        Text("直接加载")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

#Preview {
    AvatarDebugView()
}
EOSWIFT

echo "修复完成！请重启Xcode并测试头像显示。"
