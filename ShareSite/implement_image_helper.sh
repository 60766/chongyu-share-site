#!/bin/bash

# 实现ImageHelper类并集成到项目中
echo "正在实现ImageHelper类并集成到项目中..."

# 确保ImageHelper.swift文件存在
if [ ! -f "虫遇/Utils/ImageHelper.swift" ]; then
  echo "创建ImageHelper.swift文件..."
  
  # 创建ImageHelper类
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
fi

# 查找并修改CharacterAvatarView.swift
echo "修改CharacterAvatarView.swift..."
character_avatar_file="虫遇/Views/Components/CharacterAvatarView.swift"

if [ -f "$character_avatar_file" ]; then
  # 备份原文件
  cp "$character_avatar_file" "${character_avatar_file}.bak"
  
  # 查找文件内容
  if grep -q "UIImage(named: character.avatar)" "$character_avatar_file"; then
    # 修改文件内容
    sed -i '' '/if UIImage(named: character.avatar)/,/Circle()/c\
                    // 使用ImageHelper加载头像\
                    ImageHelper.loadCharacterAvatar(character.avatar, size: size)\
                        .overlay(\
                            Circle()\
                                .stroke(\
                                    characterColor.opacity(0.5),\
                                    lineWidth: 1.5\
                                )\
                        )' "$character_avatar_file"
    
    # 添加import语句
    if ! grep -q "import SwiftUI" "$character_avatar_file"; then
      sed -i '' '1i\
import SwiftUI
' "$character_avatar_file"
    fi
    
    echo "已修改 CharacterAvatarView.swift"
  else
    echo "CharacterAvatarView.swift 中没有找到需要替换的代码"
  fi
else
  echo "未找到 CharacterAvatarView.swift 文件"
fi

# 查找并修改其他使用头像的视图
echo "查找其他使用头像的视图文件..."
avatar_files=$(grep -l "Image(" --include="*.swift" -r 虫遇/Views)

for file in $avatar_files; do
  echo "检查文件: $file"
  
  # 如果文件包含直接使用Image(characterId)或Image(uiImage: UIImage(named: characterId))的代码
  if grep -q "Image(.*avatar" "$file" || grep -q "Image(uiImage: UIImage(named:" "$file"; then
    echo "  - 找到可能需要修改的文件: $file"
    
    # 备份文件
    cp "$file" "${file}.bak"
    
    # 添加import语句
    if ! grep -q "import SwiftUI" "$file"; then
      sed -i '' '1i\
import SwiftUI
' "$file"
    fi
  fi
done

# 创建测试视图
echo "创建测试视图..."
cat > "虫遇/Views/Debug/ImageHelperTestView.swift" << EOTESTVIEW
import SwiftUI

/**
 * ImageHelper测试视图
 * 用于测试ImageHelper类的效果
 */
struct ImageHelperTestView: View {
    let characterIds = [
        "einstein", "shakespeare", "davinci", "kongzi", "newton",
        "libai", "holmes", "curie", "socrates", "plato"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("ImageHelper测试").font(.title)
                    
                    // 测试CharacterAvatarSimple
                    Group {
                        Text("使用CharacterAvatarSimple").font(.headline)
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
                    
                    // 测试ImageHelper.loadCharacterAvatar
                    Group {
                        Text("使用ImageHelper.loadCharacterAvatar").font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                            ForEach(characterIds, id: \.self) { id in
                                VStack {
                                    ImageHelper.loadCharacterAvatar(id, size: 60)
                                    Text(id).font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("头像测试")
        }
    }
}

struct ImageHelperTestView_Previews: PreviewProvider {
    static var previews: some View {
        ImageHelperTestView()
    }
}
EOTESTVIEW

echo "已创建测试视图: 虫遇/Views/Debug/ImageHelperTestView.swift"

# 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修改完成！请重启Xcode并清除项目缓存。"
echo "提示: 可以使用 ImageHelperTestView() 来测试ImageHelper的效果"
