import SwiftUI

/**
 * 推荐角色展示视图
 * 使用优化后的卡片组件展示推荐角色 - 纵向网格布局
 */
struct RecommendedCharactersView: View {
    // 推荐角色列表
    var characters: [CharacterModel]
    // 标题文本
    var titleText: String = "推荐角色"
    // 点击角色事件 - 进入角色详情
    var onCharacterTap: (CharacterModel) -> Void = { _ in }
    // 点击聊天按钮事件 - 进入聊天
    var onCharacterChatTap: (CharacterModel) -> Void = { _ in }
    // 查看全部事件
    var onViewAllTap: () -> Void = {}
    // 创建角色事件
    var onCreateTap: () -> Void = {}
    
    // 使用三列布局，调整间距
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 标题栏
            HStack(alignment: .center) {
                Text(titleText)
                    .font(.system(size: 15, weight: .medium)) // 字体保持小一点
                    .foregroundColor(Color(.label)) // 恢复原来的颜色
                
                Spacer()
                
                // 创建角色按钮
                Button(action: onCreateTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.primaryColor)
                        Text("创建")
                            .font(.system(size: 13))
                            .foregroundColor(.primaryColor)
                    }
                }
                .padding(.trailing, 12)
                
                // 查看全部按钮
                Button(action: onViewAllTap) {
                    HStack(spacing: 3) {
                        Text("全部")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(.systemGray))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // 角色卡片网格布局 - 改为三列网格
            LazyVGrid(columns: columns, spacing: 12) { // 增加垂直间距
                ForEach(characters) { character in
                    ImprovedCharacterCardView(
                        character: character,
                        onTap: { onCharacterTap(character) },
                        onChatTap: { onCharacterChatTap(character) }
                    )
                }
            }
            .padding(.horizontal, 16) // 与标题栏使用相同的水平内边距
            .padding(.top, 2)
            .padding(.bottom, 2)
        }
    }
}

// 预览
struct RecommendedCharactersView_Previews: PreviewProvider {
    static var previews: some View {
        RecommendedCharactersView(
            characters: CharacterModel.sampleCharacters.prefix(6).map { $0 },
            titleText: "推荐角色"
        )
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
} 