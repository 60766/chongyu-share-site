#!/bin/bash

# 验证ImageHelper实现
echo "验证ImageHelper实现..."

# 1. 检查ImageHelper.swift文件
echo "检查ImageHelper.swift文件..."
if [ -f "虫遇/Utils/ImageHelper.swift" ]; then
  echo "✅ ImageHelper.swift文件存在"
else
  echo "❌ ImageHelper.swift文件不存在"
fi

# 2. 检查修改后的文件
echo "检查修改后的文件..."

# CharacterAvatarView.swift
avatar_view_file="虫遇/Views/Components/CharacterAvatarView.swift"
if [ -f "$avatar_view_file" ]; then
  if grep -q "CharacterAvatarSimple" "$avatar_view_file"; then
    echo "✅ CharacterAvatarView.swift已正确修改"
  else
    echo "❌ CharacterAvatarView.swift未正确修改"
  fi
fi

# PostCardView.swift
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  if grep -q "ImageHelper" "$post_card_file"; then
    echo "✅ PostCardView.swift已正确修改"
  else
    echo "❌ PostCardView.swift未正确修改"
  fi
fi

# FullscreenPostDetailView.swift
detail_view_file="虫遇/Views/Components/FullscreenPostDetailView.swift"
if [ -f "$detail_view_file" ]; then
  if grep -q "CharacterAvatarSimple" "$detail_view_file"; then
    echo "✅ FullscreenPostDetailView.swift已正确修改"
  else
    echo "❌ FullscreenPostDetailView.swift未正确修改"
  fi
fi

# 3. 创建一个简单的测试视图
cat > "虫遇/Utils/AvatarQuickTest.swift" << EOTEST
import SwiftUI

/**
 * 头像快速测试视图
 * 用于验证ImageHelper是否正常工作
 */
struct AvatarQuickTest: View {
    // 测试角色列表
    let testCharacters = [
        "einstein",    // 爱因斯坦
        "shakespeare", // 莎士比亚
        "davinci",     // 达芬奇
        "kongzi",      // 孔子
        "newton",      // 牛顿
        "socrates",    // 苏格拉底
        "plato",       // 柏拉图
        "mozart",      // 莫扎特
        "beethoven",   // 贝多芬
        "tesla"        // 特斯拉
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("头像加载测试").font(.title)
                    
                    // 使用CharacterAvatarSimple加载头像
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                        ForEach(testCharacters, id: \.self) { id in
                            VStack {
                                CharacterAvatarSimple(id, size: 60)
                                Text(id)
                                    .font(.caption)
                            }
                            .padding(5)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    // 显示路径可用性信息
                    VStack(alignment: .leading, spacing: 10) {
                        Text("路径可用性检查:").font(.headline)
                        
                        ForEach(testCharacters, id: \.self) { id in
                            HStack {
                                Text(id)
                                    .frame(width: 100, alignment: .leading)
                                
                                if UIImage(named: id) != nil {
                                    Text("直接路径 ✅")
                                        .foregroundColor(.green)
                                } else {
                                    Text("直接路径 ❌")
                                        .foregroundColor(.red)
                                }
                                
                                if UIImage(named: "HistoricalFigures/\(id)") != nil {
                                    Text("历史路径 ✅")
                                        .foregroundColor(.green)
                                } else {
                                    Text("历史路径 ❌")
                                        .foregroundColor(.red)
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("头像测试")
        }
    }
}
EOTEST

echo "已创建测试视图: 虫遇/Utils/AvatarQuickTest.swift"

# 4. 添加测试入口
entry_file="虫遇/Views/Debug/DebugMenuView.swift"
if [ -f "$entry_file" ]; then
  echo "添加测试入口到DebugMenuView.swift..."
  # 备份原文件
  cp "$entry_file" "${entry_file}.bak"
  
  # 查找合适位置添加测试入口
  if grep -q "NavigationLink" "$entry_file"; then
    # 在最后一个NavigationLink后添加
    sed -i '' '/NavigationLink/a\\
        NavigationLink(destination: AvatarQuickTest()) {\
            Text("头像加载测试")\
        }' "$entry_file"
    
    echo "✅ 已添加测试入口到DebugMenuView.swift"
  else
    echo "❌ 无法找到合适位置添加测试入口"
  fi
fi

echo "验证完成！请重启Xcode并测试头像加载功能。"
echo "提示: 可以在调试菜单中找到'头像加载测试'选项来验证修改效果。"
