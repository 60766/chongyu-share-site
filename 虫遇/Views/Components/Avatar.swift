import SwiftUI

/**
 * 通用头像组件
 * 支持多种头像来源：URL、系统图标、本地图片
 * 自动识别角色ID并使用CharacterAvatarService获取头像
 */
struct Avatar: View {
    // 头像URL、系统图标名称或角色ID
    var url: String
    // 角色名称（用于生成字母头像）
    var name: String = ""
    // 角色类别
    var category: String = ""
    // 头像大小
    var size: CGFloat = 40
    // 边框颜色
    var borderColor: Color = Color.gray.opacity(0.2)
    // 边框宽度
    var borderWidth: CGFloat = 1
    
    // 自定义头像
    @State private var customImage: UIImage? = nil
    
    // 头像服务
    private let avatarService = CharacterAvatarService.shared
    
    // 从url中提取干净的角色ID (例如 "HistoricalFigures/hermione" -> "hermione")
    private var cleanCharacterId: String {
        if let lastComponent = url.split(separator: "/").last {
            let cleaned = String(lastComponent)
            print("🔍 Avatar - cleanCharacterId: 原始URL: \(url), 提取ID: \(cleaned)")
            return cleaned
        }
        print("🔍 Avatar - cleanCharacterId: 原始URL: \(url), 提取ID: \(url) (无路径)")
        return url
    }
    
    // 判断是否为已知角色
    private var isKnownCharacter: Bool {
        guard !cleanCharacterId.isEmpty else { 
            print("🔍 Avatar - isKnownCharacter: cleanCharacterId为空，返回false")
            return false 
        }
        let result = avatarService.isKnownCharacter(id: cleanCharacterId)
        print("🔍 Avatar - 检查是否为已知角色: \(cleanCharacterId), 结果: \(result)")
        return result
    }
    
    // 判断是否为自定义角色
    private var isCustomCharacter: Bool {
        return cleanCharacterId.hasPrefix("custom_")
    }
    
    var body: some View {
        Group {
            if let customImage = customImage {
                // 显示从文档目录加载的自定义头像
                Image(uiImage: customImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            } else if isKnownCharacter {
                // 已知角色交由服务处理
                avatarService.getAvatarView(for: cleanCharacterId, name: name, category: category, size: size)
                    .onAppear {
                        print("✅ Avatar - 已知角色 \(cleanCharacterId)，交由CharacterAvatarService处理")
                    }
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            } else if url.starts(with: "http") {
                // 远程URL图片
                remoteImage
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            } else if url.contains(".") {
                // 本地图片 (通常是文件名带后缀)
                localImage
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            } else {
                // 对于未知ID或带有路径的已知ID，尝试直接加载图片
                characterImage
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            }
        }
        .onAppear {
            print("🔄 Avatar - 组件加载: URL=\(url), name=\(name), isKnownCharacter=\(isKnownCharacter)")
            
            // 尝试加载自定义头像
            if isCustomCharacter || url == "default_avatar" {
                loadCustomAvatar()
            }
        }
    }
    
    // 角色图片视图 - 尝试多种路径加载
    private var characterImage: some View {
        Group {
            // 尝试直接加载 (适用于 "HistoricalFigures/laozi" 这样的情况)
            if let image = UIImage(named: url), image.size.width > 0 {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .onAppear {
                        print("✅ Avatar - 直接加载图片成功: \(url), 尺寸: \(image.size)")
                    }
            } else {
                // 如果直接加载失败，则使用占位符
                placeholderImage
                    .onAppear {
                        print("⚠️ Avatar - 直接加载图片失败 \(url)，使用占位符")
                    }
            }
        }
    }
    
    // 远程图片视图
    private var remoteImage: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: size, height: size)
                    .onAppear {
                        print("🔄 Avatar - 远程图片加载中: \(url)")
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        print("✅ Avatar - 远程图片加载成功: \(url)")
                    }
            case .failure:
                placeholderImage
                    .onAppear {
                        print("❌ Avatar - 远程图片加载失败: \(url)")
                    }
            @unknown default:
                placeholderImage
                    .onAppear {
                        print("⚠️ Avatar - 远程图片未知状态: \(url)")
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
    
    // 本地图片视图
    private var localImage: some View {
        Group {
            if let image = UIImage(named: url) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .onAppear {
                    print("✅ Avatar - 本地图片加载成功: \(url)")
                }
            } else {
                // 图片加载失败，显示占位符
                placeholderImage
                    .onAppear {
                        print("❌ Avatar - 本地图片加载失败: \(url)")
                    }
            }
        }
    }
    
    // 系统图标视图
    private var systemIcon: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: size, height: size)
                    
            Image(systemName: "person.circle.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(.gray)
        }
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .onAppear {
            print("ℹ️ Avatar - 使用系统图标: person.circle.fill")
        }
    }
    
    // 占位图像
    private var placeholderImage: some View {
        // 使用字母头像作为占位图像
        let initialLetter = avatarService.getInitialLetter(from: name.isEmpty ? (url.isEmpty ? "?" : url) : name)
        let color = avatarService.generateConsistentColor(for: url)
        
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
            print("⚠️ Avatar - 使用占位字母头像: \(initialLetter) (来自: \(name.isEmpty ? url : name)), 颜色: \(color)")
        }
    }
    
    // 从文档目录加载自定义头像
    private func loadCustomAvatar() {
        // 对于自定义角色，尝试从文档目录加载头像
        let characterId = cleanCharacterId
        if let image = CustomAvatarLoader.shared.loadCustomAvatar(characterId: characterId, avatarName: url) {
            self.customImage = image
        }
    }
}

// MARK: - 预览
struct Avatar_Previews: PreviewProvider {
    static var previews: some View {
    VStack(spacing: 20) {
            HStack(spacing: 20) {
                // 角色ID头像 (自动识别)
                Avatar(url: "einstein", size: 50)
                
                // 系统图标头像
                Avatar(url: "person.circle.fill", size: 50)
                
                // 本地图片头像 - 使用爱因斯坦而不是孔子作为示例
                Avatar(url: "HistoricalFigures/einstein", size: 50)
            }
            
            HStack(spacing: 20) {
                // 远程URL头像（模拟）
                Avatar(url: "https://example.com/avatar.jpg", size: 50)
                
                // 带边框的头像
                Avatar(url: "person.circle.fill", size: 50, borderColor: .blue, borderWidth: 2)
                
                // 新角色
                Avatar(url: "frodo", size: 50)
            }
            
            HStack(spacing: 20) {
                // 字母头像 - 中文
                Avatar(url: "unknown_char1", name: "查尔斯·达尔文", category: "scientist", size: 50)
                
                // 字母头像 - 英文
                Avatar(url: "unknown_char2", name: "Einstein", category: "scientist", size: 50)
                
                // 字母头像 - 自定义颜色
                Avatar(url: "unknown_char3", name: "牛顿", category: "scientist", size: 50, borderColor: .purple, borderWidth: 2)
            }
    }
    .padding()
        .previewLayout(.sizeThatFits)
    }
} 