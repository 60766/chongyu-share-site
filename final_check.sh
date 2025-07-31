#!/bin/bash

# 最终检查脚本
echo "执行最终检查..."

# 检查ImageHelper.swift是否存在
if [ -f "虫遇/Utils/ImageHelper.swift" ]; then
  echo "✅ ImageHelper.swift文件存在"
else
  echo "❌ ImageHelper.swift文件不存在"
fi

# 检查ImageHelperSimple.swift是否已删除
if [ -f "虫遇/Utils/ImageHelperSimple.swift" ]; then
  echo "❌ ImageHelperSimple.swift文件仍然存在"
else
  echo "✅ ImageHelperSimple.swift文件已删除"
fi

# 检查测试视图文件
test_files=(
  "虫遇/Views/Debug/ImageHelperTestView.swift"
  "虫遇/Views/Debug/FixedAvatarDemoView.swift"
  "虫遇/Views/Debug/AvatarFixTestView.swift"
  "虫遇/Views/Debug/IntegrationTestView.swift"
)

echo "检查测试视图文件:"
for file in "${test_files[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file 存在"
  else
    echo "❌ $file 不存在"
  fi
done

# 检查使用指南
if [ -f "虫遇/Utils/README_ImageHelper使用指南.md" ]; then
  echo "✅ README_ImageHelper使用指南.md 存在"
else
  echo "❌ README_ImageHelper使用指南.md 不存在"
fi

# 创建一个简单的测试视图
cat > "虫遇/Views/Debug/SimpleAvatarTest.swift" << EOTEST
import SwiftUI

/**
 * 简单头像测试视图
 * 用于快速测试头像加载效果
 */
struct SimpleAvatarTest: View {
    let avatars = ["einstein", "shakespeare", "davinci", "kongzi", "newton"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("头像测试").font(.title)
            
            ForEach(avatars, id: \.self) { id in
                HStack(spacing: 20) {
                    // 使用CharacterAvatarSimple
                    CharacterAvatarSimple(id, size: 60)
                    
                    // 显示ID
                    Text(id).font(.headline)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SimpleAvatarTest_Previews: PreviewProvider {
    static var previews: some View {
        SimpleAvatarTest()
    }
}
EOTEST

echo "已创建简单测试视图: 虫遇/Views/Debug/SimpleAvatarTest.swift"

# 创建一个ContentView修改示例
cat > "虫遇/Views/Debug/ContentViewExample.txt" << EOEXAMPLE
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 原有内容
            // ...
            
            // 添加头像测试入口
            VStack {
                // 原有内容
                // ...
                
                // 添加测试按钮
                Button(action: {
                    // 显示测试视图
                    // 这里根据您的导航方式进行调整
                }) {
                    Text("测试头像")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .sheet(isPresented: $showTestView) {
                    SimpleAvatarTest()
                }
            }
            .tabItem {
                Image(systemName: "person")
                Text("我的")
            }
        }
    }
    
    @State private var showTestView = false
}
EOEXAMPLE

echo "已创建ContentView修改示例: 虫遇/Views/Debug/ContentViewExample.txt"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "检查完成！"
echo "提示: 您可以使用SimpleAvatarTest()来快速测试头像加载效果"
