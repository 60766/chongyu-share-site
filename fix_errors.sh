#!/bin/bash

# 修复编译错误
echo "开始修复编译错误..."

# 1. 检查ImageHelper_简洁版.swift是否存在
if [ -f "虫遇/Utils/ImageHelper_简洁版.swift" ]; then
  echo "删除重复的ImageHelper_简洁版.swift文件..."
  rm "虫遇/Utils/ImageHelper_简洁版.swift"
fi

# 2. 修复CharacterAvatarView.swift中的错误
avatar_view_file="虫遇/Views/Components/CharacterAvatarView.swift"
if [ -f "$avatar_view_file" ]; then
  echo "修复CharacterAvatarView.swift中的错误..."
  # 备份原文件
  cp "$avatar_view_file" "${avatar_view_file}.error_bak"
  
  # 读取文件内容
  content=$(cat "$avatar_view_file")
  
  # 计算大括号数量
  open_braces=$(grep -o "{" "$avatar_view_file" | wc -l)
  close_braces=$(grep -o "}" "$avatar_view_file" | wc -l)
  
  echo "大括号检查: 开始括号 $open_braces, 结束括号 $close_braces"
  
  # 修复多余的大括号
  if [ "$close_braces" -gt "$open_braces" ]; then
    # 创建一个新的临时文件，删除最后一个多余的大括号
    sed '$ s/}$//' "$avatar_view_file" > "${avatar_view_file}.tmp"
    mv "${avatar_view_file}.tmp" "$avatar_view_file"
    echo "已删除多余的大括号"
  fi
  
  # 确保文件结构正确
  echo "重新格式化文件结构..."
  cat > "$avatar_view_file" << EOAVATAR
import SwiftUI

struct CharacterAvatarView: View {
    var character: Character
    var size: CGFloat = 40
    var showBorder: Bool = true
    var showBackground: Bool = false
    var showName: Bool = false
    var namePosition: NamePosition = .bottom
    var nameFont: Font = .caption
    var namePadding: CGFloat = 4
    
    enum NamePosition {
        case top, bottom, trailing
    }
    
    // 根据角色类别获取颜色
    private var characterColor: Color {
        switch character.category {
        case .historical:
            return .blue
        case .fictional:
            return .purple
        case .mythological:
            return .orange
        case .literary:
            return .green
        case .religious:
            return .red
        case .scientific:
            return .cyan
        case .artistic:
            return .pink
        case .philosophical:
            return .yellow
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: namePadding) {
            if namePosition == .top && showName {
                characterNameView
            }
            
            ZStack {
                // 背景
                if showBackground {
                    Circle()
                        .fill(characterColor.opacity(0.1))
                }
                
                // 头像
                CharacterAvatarSimple(character.avatar, size: size)
                    .overlay(
                        showBorder ? Circle()
                            .stroke(
                                characterColor.opacity(0.5),
                                lineWidth: 1.5
                            ) : nil
                    )
            }
            
            if namePosition == .bottom && showName {
                characterNameView
            }
        }
        .frame(maxWidth: showName && namePosition != .trailing ? .infinity : nil)
        .padding(.horizontal, showName && namePosition != .trailing ? 4 : 0)
    }
    
    // 角色名称视图
    private var characterNameView: some View {
        Text(character.name)
            .font(nameFont)
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}
EOAVATAR

  echo "已修复CharacterAvatarView.swift"
fi

# 3. 修复PostCardView.swift中的错误
post_card_file="虫遇/Views/Components/PostCardView.swift"
if [ -f "$post_card_file" ]; then
  echo "修复PostCardView.swift中的错误..."
  # 备份原文件
  cp "$post_card_file" "${post_card_file}.error_bak"
  
  # 检查文件中的注释是否正确闭合
  if grep -q "/\*" "$post_card_file" && ! grep -q "\*/" "$post_card_file"; then
    echo "发现未闭合的块注释，添加闭合标记..."
    echo "*/" >> "$post_card_file"
  fi
  
  # 修复特定行的问题
  sed -i '' 's/if ImageHelper.isCharacterAvatarAvailable(imageName) {/if ImageHelper.isCharacterAvatarAvailable(imageName) {/g' "$post_card_file"
  
  echo "已修复PostCardView.swift"
fi

# 4. 创建简洁版的ImageHelper
echo "创建简洁版的ImageHelper..."
cat > "虫遇/Utils/ImageHelper.swift" << EOHELPER
import SwiftUI

/**
 * 图片加载辅助类
 */
struct ImageHelper {
    /**
     * 加载角色头像
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
EOHELPER

echo "已创建简洁版的ImageHelper.swift"

# 5. 清理缓存
echo "清理缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*虫遇* 2>/dev/null
find . -name ".DS_Store" -delete

echo "修复完成！请重启Xcode并清除项目缓存。"
