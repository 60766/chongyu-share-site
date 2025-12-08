import SwiftUI

/**
 * PostAvatar测试视图
 * 专门用于测试PostAvatar组件的头像显示效果
 * 对比PostAvatar和Avatar组件的区别
 */
struct PostAvatarTestView: View {
    private let avatarService = CharacterAvatarService.shared
    
    // 测试角色列表
    private let testCharacters = [
        ("hermione", "赫敏", "fiction"),
        ("macbeth", "麦克白", "literature"),
        ("ayuwang", "阿育王", "historical"),
        ("daenerys", "丹妮莉丝", "fiction"),
        ("kongzi", "孔子", "philosopher")  // 添加孔子作为对比
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("PostAvatar vs Avatar测试")
                    .font(.title)
                    .padding()
                
                Text("对比PostAvatar和Avatar组件的头像显示效果")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                // 显示所有测试角色
                ForEach(testCharacters, id: \.0) { character in
                    characterComparisonSection(
                        id: character.0,
                        name: character.1,
                        category: character.2
                    )
                }
            }
            .padding()
        }
    }
    
    // 单个角色的对比部分
    private func characterComparisonSection(id: String, name: String, category: String) -> some View {
        VStack(spacing: 20) {
            Text("\(name) (ID: \(id))")
                .font(.headline)
            
            HStack(spacing: 30) {
                // 测试1: 使用PostAvatar组件
                VStack(spacing: 10) {
                    // 使用PostAvatar组件 - 直接使用ID
                    PostAvatar(url: id, size: 80)
                    
                    Text("PostAvatar")
                        .font(.caption)
                    Text("url: \(id)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // 测试2: 使用PostAvatar组件 - 使用HistoricalFigures路径
                VStack(spacing: 10) {
                    PostAvatar(url: "HistoricalFigures/\(id)", size: 80)
                    
                    Text("PostAvatar")
                        .font(.caption)
                    Text("url: HistoricalFigures/\(id)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // 测试3: 使用Avatar组件
                VStack(spacing: 10) {
                    Avatar(url: id, name: name, category: category, size: 80)
                    
                    Text("Avatar")
                        .font(.caption)
                    Text("url: \(id), name: \(name)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
                .padding(.vertical)
        }
    }
}

// 从PostCardView.swift中复制的PostAvatar组件
fileprivate struct PostAvatar: View {
    var url: String
    var size: CGFloat = 40
    var borderColor: Color = Color.gray.opacity(0.2)
    var borderWidth: CGFloat = 1
    
    var body: some View {
        Group {
            if url.contains("HistoricalFigures/") {
                // 历史人物头像
                if let characterID = url.components(separatedBy: "/").last,
                   let image = UIImage(named: "HistoricalFigures/\(characterID)") ?? UIImage(named: characterID) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                } else {
                    placeholderImage
                }
            } else if let image = UIImage(named: url) {
                // 本地图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
            } else {
                // 系统图标或占位符
                placeholderImage
            }
        }
    }
    
    // 占位图像
    private var placeholderImage: some View {
        // 使用字母头像作为占位图像
        let initialLetter = CharacterAvatarService.shared.getInitialLetter(from: url.isEmpty ? "?" : url)
        let color = CharacterAvatarService.shared.generateConsistentColor(for: url)
        
        return ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            
            Text(initialLetter)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(color)
            
            Circle()
                .stroke(color.opacity(0.7), lineWidth: 1.5)
                .frame(width: size, height: size)
        }
        .onAppear {
            #if DEBUG
            debugLog("⚠️ PostAvatar - 使用字母头像: \(initialLetter) (来自: \(url))")
            #endif
        }
    }
}

// MARK: - 预览
struct PostAvatarTestView_Previews: PreviewProvider {
    static var previews: some View {
        PostAvatarTestView()
    }
} 