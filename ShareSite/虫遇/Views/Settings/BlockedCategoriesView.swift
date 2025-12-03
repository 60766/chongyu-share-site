import SwiftUI

/**
 * 屏蔽角色分类视图
 * 用于管理被屏蔽的角色分类
 */
struct BlockedCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedCategories: Set<CharacterCategory> = []
    @State private var showWarningAlert = false
    @State private var warningMessage = ""
    
    // 主题颜色
    private var primaryAccentColor: Color {
        Color(hex: "9A8BB0")
    }
    
    // 所有可用分类（排除"全部"）
    private var availableCategories: [CharacterCategory] {
        CharacterCategory.allCases.filter { $0 != .all }
    }
    
    var body: some View {
        List {
            // 说明信息
            Section {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("屏蔽的分类将不会出现在AI生成的帖子中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // 分类列表
            Section(header: Text("角色分类")) {
                ForEach(availableCategories, id: \.self) { category in
                    HStack {
                        // 分类图标
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(blockedCategories.contains(category) ? 0.2 : 0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: category.icon)
                                .font(.system(size: 18))
                                .foregroundColor(blockedCategories.contains(category) ? .gray : category.color)
                        }
                        
                        // 分类信息
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(category.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(blockedCategories.contains(category) ? .gray : .primary)
                                
                                // 被屏蔽时显示小图标
                                if blockedCategories.contains(category) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // 显示角色数量
                            let count = getCharacterCount(for: category)
                            Text("\(count)个角色")
                                .font(.system(size: 13))
                                .foregroundColor(blockedCategories.contains(category) ? .gray.opacity(0.7) : .secondary)
                        }
                        
                        Spacer()
                        
                        // 开关 - 开启=可用，关闭=已屏蔽
                        Toggle("", isOn: Binding(
                            get: { !blockedCategories.contains(category) },
                            set: { isEnabled in
                                if !isEnabled {
                                    // 尝试屏蔽
                                    if BlockedCategoriesManager.shared.toggleCategory(category) {
                                        blockedCategories.insert(category)
                                        
                                        // Toast提示
                                        ToastManager.shared.showToast(message: "已屏蔽「\(category.displayName)」分类")
                                    } else {
                                        // 不能屏蔽最后一个分类
                                        warningMessage = "至少需要保留一个分类，无法屏蔽所有分类"
                                        showWarningAlert = true
                                    }
                                } else {
                                    // 取消屏蔽
                                    BlockedCategoriesManager.shared.toggleCategory(category)
                                    blockedCategories.remove(category)
                                    
                                    // Toast提示
                                    ToastManager.shared.showToast(message: "已取消屏蔽「\(category.displayName)」分类")
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: primaryAccentColor))
                    }
                    .padding(.vertical, 4)
                    .opacity(blockedCategories.contains(category) ? 0.7 : 1.0)
                }
            }
            
            // 重置按钮
            if !blockedCategories.isEmpty {
                Section {
                    Button(action: {
                        BlockedCategoriesManager.shared.unblockAllCategories()
                        blockedCategories.removeAll()
                        
                        // Toast提示
                        ToastManager.shared.showToast(message: "已取消所有分类屏蔽")
                    }) {
                        HStack {
                            Spacer()
                            Text("取消所有屏蔽")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(primaryAccentColor)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("取消屏蔽后，所有分类的角色将重新出现在帖子生成中")
                        .font(.caption)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
        .navigationTitle("屏蔽角色分类")
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
            loadBlockedCategories()
        }
        .alert("提示", isPresented: $showWarningAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(warningMessage)
        }
    }
    
    /**
     * 加载被屏蔽的分类
     */
    private func loadBlockedCategories() {
        blockedCategories = Set(BlockedCategoriesManager.shared.getBlockedCategories())
    }
    
    /**
     * 获取分类的角色数量
     */
    private func getCharacterCount(for category: CharacterCategory) -> Int {
        // 显示所有角色数量，不受分类屏蔽影响
        let allCharacters = CharacterModel.loadAllCharactersWithoutFilter()
        return allCharacters.filter { $0.category == category }.count
    }
}

