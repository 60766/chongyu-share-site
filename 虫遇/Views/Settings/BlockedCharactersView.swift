import SwiftUI

/**
 * 已屏蔽角色管理视图
 * 用于查看和管理被用户屏蔽的角色
 */
struct BlockedCharactersView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 获取所有被屏蔽的角色ID
    @State private var blockedCharacters: [String] = []
    @State private var showUnblockAlert = false
    @State private var selectedCharacter: String = ""
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    var body: some View {
        List {
            if blockedCharacters.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "hand.thumbsup")
                                .font(.system(size: 36))
                                .foregroundColor(.gray)
                            Text("没有已屏蔽的角色")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("当你屏蔽某个角色后，他们将不会出现在你的推荐中")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 40)
                }
            } else {
                Section(header: Text("已屏蔽角色列表")) {
                    ForEach(blockedCharacters, id: \.self) { characterId in
                        HStack {
                            Image(systemName: getCharacterAvatar(for: characterId))
                                .font(.system(size: 20))
                                .foregroundColor(getCharacterColor(for: characterId))
                                .frame(width: 32, height: 32)
                                .background(getCharacterColor(for: characterId).opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(getCharacterName(for: characterId))
                                    .font(.system(size: 16, weight: .medium))
                                Text(getCharacterDescription(for: characterId))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedCharacter = characterId
                                showUnblockAlert = true
                            }) {
                                Text("取消屏蔽")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(footer: Text("取消屏蔽后，角色将可能再次出现在你的推荐内容中")) {
                    Button(action: {
                        showUnblockAlert = true
                        selectedCharacter = "all"
                    }) {
                        HStack {
                            Spacer()
                            Text("取消所有屏蔽")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("已屏蔽角色")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("设置")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryAccentColor)
            }
        )
        .onAppear {
            loadBlockedCharacters()
        }
        .alert(isPresented: $showUnblockAlert) {
            if selectedCharacter == "all" {
                return Alert(
                    title: Text("取消所有屏蔽"),
                    message: Text("确定要取消所有角色的屏蔽吗？"),
                    primaryButton: .destructive(Text("确定")) {
                        unblockAllCharacters()
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            } else {
                return Alert(
                    title: Text("取消屏蔽"),
                    message: Text("确定要取消对\"\(getCharacterName(for: selectedCharacter))\"的屏蔽吗？"),
                    primaryButton: .default(Text("确定")) {
                        unblockCharacter(selectedCharacter)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
        }
    }
    
    /**
     * 加载所有被屏蔽的角色
     */
    private func loadBlockedCharacters() {
        blockedCharacters = CharacterRotationSystem.shared.getAllDislikedCharacters()
    }
    
    /**
     * 取消屏蔽特定角色
     */
    private func unblockCharacter(_ characterId: String) {
        CharacterRotationSystem.shared.toggleDislike(characterId: characterId)
        loadBlockedCharacters()
        
        // 触觉反馈和提示
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Toast提示
        ToastManager.shared.showToast(message: "已取消屏蔽\"\(getCharacterName(for: characterId))\"")
    }
    
    /**
     * 取消屏蔽所有角色
     */
    private func unblockAllCharacters() {
        for characterId in blockedCharacters {
            CharacterRotationSystem.shared.toggleDislike(characterId: characterId)
        }
        loadBlockedCharacters()
        
        // 触觉反馈和提示
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Toast提示
        ToastManager.shared.showToast(message: "已取消所有屏蔽")
    }
    
    /**
     * 获取角色头像图标
     */
    private func getCharacterAvatar(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein":
            return "atom"
        case "shakespeare":
            return "book.fill"
        case "davinci":
            return "paintpalette.fill"
        case "kongzi":
            return "scroll.fill"
        case "libai":
            return "text.book.closed.fill"
        case "curie":
            return "sparkles"
        default:
            return "person.circle.fill"
        }
    }
    
    /**
     * 获取角色名称
     */
    private func getCharacterName(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein":
            return "爱因斯坦"
        case "shakespeare":
            return "莎士比亚"
        case "davinci":
            return "达芬奇"
        case "kongzi":
            return "孔子"
        case "libai":
            return "李白"
        case "curie":
            return "居里夫人"
        default:
            return characterID
        }
    }
    
    /**
     * 获取角色简介
     */
    private func getCharacterDescription(for characterID: String) -> String {
        switch characterID.lowercased() {
        case "einstein":
            return "物理学家，相对论创始人"
        case "shakespeare":
            return "英国剧作家、诗人"
        case "davinci":
            return "意大利艺术家、发明家"
        case "kongzi":
            return "中国思想家、教育家"
        case "libai":
            return "唐代诗人，浪漫主义代表"
        case "curie":
            return "物理学家，化学家"
        default:
            return "虚拟角色"
        }
    }
    
    /**
     * 获取角色对应的颜色
     */
    private func getCharacterColor(for characterID: String) -> Color {
        switch characterID.lowercased() {
        case "einstein":
            return Color.blue
        case "shakespeare":
            return Color(hex: "9A8BB0")
        case "davinci":
            return Color.orange
        case "kongzi":
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        case "libai":
            return Color(red: 0.8, green: 0.4, blue: 0.2)
        case "curie":
            return Color.pink
        default:
            return Color.gray
        }
    }
}

struct BlockedCharactersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BlockedCharactersView()
        }
    }
} 