import SwiftUI

/**
 * 历史人物头像视图
 * 专门用于显示历史人物的头像，使用统一的Avatar组件
 * 确保即使没有头像资源也能正确显示字母头像
 */
struct HistoricalFigureAvatarView: View {
    // 角色ID
    let characterId: String
    // 角色名称
    let name: String
    // 头像尺寸
    var size: CGFloat = 60
    
    // 头像服务
    private let avatarService = CharacterAvatarService.shared
    
    var body: some View {
        // 使用统一的Avatar组件
        Avatar(
            url: characterId,
            name: name,
            category: avatarService.getCharacterCategoryTag(for: characterId),
            size: size
        )
        .onAppear {
            print("🔍 HistoricalFigureAvatarView - 显示历史人物头像: \(characterId), 名称: \(name)")
            
            // 检查图片是否存在
            let exists = avatarService.checkImageExistence(imageName: characterId)
            print("🔍 HistoricalFigureAvatarView - 角色头像检查 - \(characterId): \(exists ? "存在" : "不存在")")
        }
    }
}

#Preview("历史人物头像预览") {
    VStack(spacing: 20) {
        // 有图片资源的角色
        HistoricalFigureAvatarView(characterId: "einstein", name: "爱因斯坦")
        
        // 没有图片资源的角色
        HistoricalFigureAvatarView(characterId: "ayuwang", name: "阿育王")
        
        // 不同尺寸和样式
        HistoricalFigureAvatarView(characterId: "kongzi", name: "孔子", size: 40)
    }
    .padding()
} 