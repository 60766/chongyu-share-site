import SwiftUI

/**
 * 角色头像测试视图
 * 专门用于测试没有图片资源的角色头像显示效果
 */
struct HermioneAvatarTestView: View {
    private let avatarService = CharacterAvatarService.shared
    
    // 测试角色列表
    private let testCharacters = [
        ("hermione", "赫敏", "fiction"),
        ("macbeth", "麦克白", "literature"),
        ("ayuwang", "阿育王", "historical")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("角色头像测试")
                    .font(.title)
                    .padding()
                
                Text("测试没有图片资源的角色是否正确显示文字头像")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                // 显示所有测试角色
                ForEach(testCharacters, id: \.0) { character in
                    characterTestSection(
                        id: character.0,
                        name: character.1,
                        category: character.2
                    )
                }
            }
            .padding()
        }
    }
    
    // 单个角色的测试部分
    private func characterTestSection(id: String, name: String, category: String) -> some View {
        VStack(spacing: 20) {
            Text("\(name) (ID: \(id))")
                .font(.headline)
            
            // 测试1: 直接使用 CharacterAvatarService
            VStack(spacing: 10) {
                Text("测试1: 直接使用 CharacterAvatarService")
                    .font(.subheadline)
                
                avatarService.getAvatarView(for: id, name: name, category: category, size: 100)
                
                Text("ID: \(id), 名称: \(name)")
                    .font(.caption)
            }
            .padding()
            
            // 测试2: 使用 Avatar 组件
            VStack(spacing: 10) {
                Text("测试2: 使用 Avatar 组件")
                    .font(.subheadline)
                
                Avatar(url: id, name: name, category: category, size: 100)
                
                Text("URL: \(id), 名称: \(name)")
                    .font(.caption)
            }
            .padding()
            
            // 测试3: 强制使用字母头像
            VStack(spacing: 10) {
                Text("测试4: 强制使用字母头像")
                    .font(.subheadline)
                
                let initialLetter = avatarService.getInitialLetter(from: name)
                let color = avatarService.generateConsistentColor(for: id)
                
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Text(initialLetter)
                        .font(.system(size: 45, weight: .medium))
                        .foregroundColor(color)
                    
                    Circle()
                        .stroke(color.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 100, height: 100)
                }
                
                Text("首字母: \(initialLetter), 来自: \(name)")
                    .font(.caption)
            }
            .padding()
            
            Divider()
                .padding(.vertical)
        }
    }
}

// MARK: - 预览
struct HermioneAvatarTestView_Previews: PreviewProvider {
    static var previews: some View {
        HermioneAvatarTestView()
    }
} 