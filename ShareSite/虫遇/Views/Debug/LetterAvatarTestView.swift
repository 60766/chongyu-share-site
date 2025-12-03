import SwiftUI

/**
 * 字母头像测试视图
 * 用于测试没有图片资源的角色是否正确显示文字头像
 */
struct LetterAvatarTestView: View {
    private let avatarService = CharacterAvatarService.shared
    
    // 测试角色列表 - 包括有图片的和没有图片的
    private let testCharacters: [(id: String, name: String, category: String)] = [
        ("hermione", "赫敏", "fiction"),
        ("daenerys", "丹妮莉丝", "fiction"),
        ("don_quixote", "堂吉诃德", "literature"),
        ("hamlet", "哈姆雷特", "literature"),
        ("jean_valjean", "冉阿让", "literature"),
        ("anna_karenina", "安娜·卡列尼娜", "literature"),
        ("gatsby", "盖茨比", "literature"),
        ("raskolnikov", "拉斯科尔尼科夫", "literature"),
        ("joker", "小丑", "fiction"),
        ("doctor", "神秘博士", "fiction"),
        // 添加麦克白和阿育王
        ("macbeth", "麦克白", "literature"),
        ("ayuwang", "阿育王", "historical")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("字母头像测试")
                    .font(.title)
                    .padding()
                
                Text("测试没有图片资源的角色是否正确显示文字头像")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.bottom)
                
                // 显示所有测试角色
                ForEach(testCharacters, id: \.id) { character in
                    characterRow(id: character.id, name: character.name, category: character.category)
                }
            }
            .padding()
        }
    }
    
    // 单个角色测试行
    private func characterRow(id: String, name: String, category: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 20) {
                // 测试1: 直接使用Avatar组件
                VStack {
                    Avatar(url: id, name: name, category: category, size: 80)
                    Text("Avatar组件")
                        .font(.caption)
                }
                
                // 测试2: 使用CharacterAvatarService
                VStack {
                    avatarService.getAvatarView(for: id, name: name, category: category, size: 80)
                    Text("AvatarService")
                        .font(.caption)
                }
                
                // 测试3: 强制使用字母头像
                VStack {
                    let initialLetter = avatarService.getInitialLetter(from: name)
                    let color = avatarService.generateConsistentColor(for: id)
                    
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Text(initialLetter)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(color)
                        
                        Circle()
                            .stroke(color.opacity(0.7), lineWidth: 1.5)
                            .frame(width: 80, height: 80)
                    }
                    
                    Text("强制字母头像")
                        .font(.caption)
                }
            }
            
            // 角色信息
            HStack {
                Text("ID: \(id)")
                    .font(.caption)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text("名称: \(name)")
                    .font(.caption)
                
                Text("•")
                    .foregroundColor(.gray)
                
                Text("类别: \(category)")
                    .font(.caption)
            }
            .foregroundColor(.gray)
            
            Divider()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 预览
struct LetterAvatarTestView_Previews: PreviewProvider {
    static var previews: some View {
        LetterAvatarTestView()
    }
} 