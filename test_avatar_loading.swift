import SwiftUI

/**
 * 头像加载测试视图
 * 用于测试各种角色的头像是否正确加载
 */
struct AvatarLoadingTestView: View {
    @State private var testResults: [String: String] = [:]
    private let avatarService = CharacterAvatarService.shared
    
    // 测试角色列表
    private let testCharacters = [
        "daenerys", "hermione", "don_quixote", "hamlet", 
        "jean_valjean", "anna_karenina", "gatsby", "macbeth"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("头像加载测试")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(testCharacters, id: \.self) { characterId in
                        VStack {
                            // 使用 CharacterAvatarService 获取头像
                            avatarService.getAvatarView(for: characterId, size: 60)
                            
                            Text(characterId)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(testResults[characterId] ?? "测试中...")
                                .font(.caption2)
                                .foregroundColor(testResults[characterId]?.contains("✅") == true ? .green : .orange)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                Button("重新测试") {
                    testAllAvatars()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            testAllAvatars()
        }
    }
    
    private func testAllAvatars() {
        for characterId in testCharacters {
            testAvatar(for: characterId)
        }
    }
    
    private func testAvatar(for characterId: String) {
        // 检查是否为已知角色
        let isKnown = avatarService.isKnownCharacter(id: characterId)
        
        // 检查是否有自定义头像
        let hasCustomAvatar = avatarService.hasCustomAvatar(for: characterId)
        
        // 检查图片是否存在
        let imageExists = UIImage(named: characterId) != nil || 
                         UIImage(named: "HistoricalFigures/\(characterId)") != nil
        
        let result: String
        if imageExists {
            result = "✅ 图片文件存在"
        } else if isKnown {
            result = "✅ 使用系统图标"
        } else {
            result = "⚠️ 未知角色"
        }
        
        DispatchQueue.main.async {
            testResults[characterId] = result
        }
        
        print("🔍 测试角色 \(characterId):")
        print("  - 已知角色: \(isKnown)")
        print("  - 自定义头像: \(hasCustomAvatar)")
        print("  - 图片存在: \(imageExists)")
        print("  - 结果: \(result)")
    }
}

// MARK: - 预览
struct AvatarLoadingTestView_Previews: PreviewProvider {
    static var previews: some View {
        AvatarLoadingTestView()
    }
} 