import SwiftUI

/**
 * 角色详情页
 * 显示历史人物的详细信息
 */
struct CharacterDetailView: View {
    /// 角色数据
    var character: Character
    /// 是否显示分享菜单
    @State private var showingShareSheet = false
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["介绍", "相关信息", "互动记录"]
    /// 模拟对话数据
    @State private var conversations: [Conversation] = []
    
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 添加状态变量以控制导航
    @State private var navigateToChatView = false
    @State private var selectedConversationId: String? = nil
    
    // 添加环境变量用于自定义返回按钮
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // 简化主视图结构
        ScrollView {
            VStack(spacing: 0) {
                // 抽取为独立组件
                CharacterHeaderView(
                    character: character,
                    showShareSheet: $showingShareSheet,
                    selectedConversationId: $selectedConversationId,
                    navigateToChatView: $navigateToChatView
                )
                
                // 抽取为独立组件
                CharacterTabBarView(
                    tabOptions: tabOptions,
                    selectedTabIndex: $selectedTabIndex
                )
                
                // 标签页内容 - 保持不变
                TabView(selection: $selectedTabIndex) {
                    // 介绍标签页
                    CharacterIntroductionView(character: character)
                        .tag(0)
                    
                    // 相关信息标签页
                    CharacterRelatedInfoView(character: character)
                        .tag(1)
                    
                    // 互动记录标签页
                    CharacterInteractionView(
                        character: character, 
                        conversations: conversations,
                        onChatSelected: { conversationId in
                            print("对话记录点击: \(conversationId)")
                            selectedConversationId = conversationId
                            navigateToChatView = true
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(minHeight: 500)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 手动返回
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 17, weight: .regular))
                    }
                    .foregroundColor(.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            Text("分享 \(character.name) 的信息")
        }
        // 使用新的导航API
        .navigationDestination(isPresented: $navigateToChatView) {
            ChatView(
                character: CYChatCharacter(
                    id: character.id,
                    name: character.name,
                    introduction: character.introduction,
                    field: character.field,
                    birthYear: character.birthYear,
                    deathYear: character.deathYear ?? "",
                    avatarUrl: character.avatarUrl,
                    eraTag: character.eraTag ?? "",
                    achievements: character.achievements,
                    mainWorks: character.mainWorks,
                    keyThoughts: character.keyThoughts
                ),
                conversationId: selectedConversationId ?? UUID().uuidString
            )
        }
        .onAppear {
            // 在视图出现时隐藏TabBar
            tabBarManager.pushHideState()
            print("CharacterDetailView出现：TabBar已隐藏")
            
            // 加载模拟对话数据
            loadMockConversations()
        }
        .onDisappear {
            // 在视图消失时重置状态以确保清晰的导航体验
            tabBarManager.popHideState()
            print("CharacterDetailView消失：TabBar状态已恢复")
        }
    }
    
    /**
     * 加载模拟对话数据
     */
    private func loadMockConversations() {
        // 模拟数据
        conversations = [
            Conversation(id: "1", characterId: character.id, userId: "currentUser", lastMessageContent: "上次我们讨论到了关于您那个时代的生活方式，能继续聊聊吗？", lastMessageTime: Date().addingTimeInterval(-3600 * 24), messageCount: 0),
            Conversation(id: "2", characterId: character.id, userId: "currentUser", lastMessageContent: "您认为历史和现代的最大区别是什么？", lastMessageTime: Date().addingTimeInterval(-3600 * 24 * 3), messageCount: 1)
        ]
    }
}

/**
 * 角色头部信息视图
 * 抽取出来减少主视图的复杂度
 */
struct CharacterHeaderView: View {
    let character: Character
    @Binding var showShareSheet: Bool
    @Binding var selectedConversationId: String?
    @Binding var navigateToChatView: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 角色头像
            AsyncImage(url: URL(string: character.avatarUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray.opacity(0.3))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // 角色名称和领域
            VStack(spacing: 4) {
                Text(character.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("\(character.field) | \(character.birthYear)-\(character.deathYear ?? "现在")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // 角色数据
            CharacterStatsView()
            
            // 主要标签
            CharacterTagsView(keyThoughts: character.keyThoughts)
            
            // 操作按钮
            CharacterActionButtonsView(
                onFollowTapped: {
                    print("关注按钮点击")
                },
                onChatTapped: {
                    print("对话按钮点击")
                    selectedConversationId = UUID().uuidString
                    navigateToChatView = true
                },
                onShareTapped: {
                    print("分享按钮点击")
                    showShareSheet = true
                }
            )
        }
        .padding(16)
        .background(Color.white)
    }
}

/**
 * 角色统计信息视图
 */
struct CharacterStatsView: View {
    var body: some View {
        HStack(spacing: 40) {
            StatItem(value: "3,542", label: "粉丝")
            StatItem(value: "14.2K", label: "互动量")
            StatItem(value: "4.9", label: "评分")
        }
    }
    
    struct StatItem: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/**
 * 角色标签视图
 */
struct CharacterTagsView: View {
    let keyThoughts: [String]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(keyThoughts.prefix(3), id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
            }
        }
    }
}

/**
 * 角色操作按钮视图
 */
struct CharacterActionButtonsView: View {
    let onFollowTapped: () -> Void
    let onChatTapped: () -> Void
    let onShareTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // 关注按钮
            ActionButton(
                iconName: "plus.circle", 
                label: "关注", 
                action: onFollowTapped
            )
            
            // 对话按钮
            ActionButton(
                iconName: "bubble.left.fill", 
                label: "对话", 
                action: onChatTapped
            )
            
            // 分享按钮
            ActionButton(
                iconName: "square.and.arrow.up", 
                label: "分享", 
                action: onShareTapped
            )
        }
    }
    
    struct ActionButton: View {
        let iconName: String
        let label: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.primaryColor)
                    
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(width: 60, height: 60)
            }
            .contentShape(Rectangle())
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

/**
 * 角色标签栏视图
 */
struct CharacterTabBarView: View {
    let tabOptions: [String]
    @Binding var selectedTabIndex: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabOptions.count, id: \.self) { index in
                Button {
                    print("标签选择: \(tabOptions[index])")
                    withAnimation {
                        selectedTabIndex = index
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tabOptions[index])
                            .font(.system(size: 16, weight: selectedTabIndex == index ? .semibold : .regular))
                            .foregroundColor(selectedTabIndex == index ? .primaryColor : .secondary)
                        
                        // 选中指示条
                        Rectangle()
                            .fill(selectedTabIndex == index ? Color.primaryColor : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ScaleButtonStyle(scaleAmount: 0.97))
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

/**
 * 角色介绍视图
 */
struct CharacterIntroductionView: View {
    var character: Character
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 个人介绍
            VStack(alignment: .leading, spacing: 8) {
                Text("个人简介")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(character.introduction)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            Divider()
            
            // 主要成就
            VStack(alignment: .leading, spacing: 8) {
                Text("主要成就")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                ForEach(character.achievements, id: \.self) { achievement in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.primaryColor)
                        
                        Text(achievement)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // 主要作品
            VStack(alignment: .leading, spacing: 8) {
                Text("主要作品")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                ForEach(character.mainWorks, id: \.self) { work in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.primaryColor)
                        
                        Text(work)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // 核心思想
            VStack(alignment: .leading, spacing: 8) {
                Text("核心思想")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                ForEach(character.keyThoughts, id: \.self) { thought in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.primaryColor)
                        
                        Text(thought)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

/**
 * 角色相关信息视图
 */
struct CharacterRelatedInfoView: View {
    var character: Character
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 历史背景
            VStack(alignment: .leading, spacing: 8) {
                Text("历史背景")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("这部分将展示 \(character.name) 所处的历史时期背景和重要事件。")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            Divider()
            
            // 相关人物
            VStack(alignment: .leading, spacing: 8) {
                Text("相关人物")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("这部分将展示与 \(character.name) 相关的历史人物和他们之间的关系。")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            Divider()
            
            // 影响与评价
            VStack(alignment: .leading, spacing: 8) {
                Text("影响与评价")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("这部分将展示 \(character.name) 的历史影响和后世评价。")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

/**
 * 角色互动记录视图 - 重构为使用回调而非内部导航
 */
struct CharacterInteractionView: View {
    var character: Character
    var conversations: [Conversation]
    var onChatSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("还没有与\(character.name)的互动记录")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    // 开始对话按钮 - 使用回调而非内部导航
                    Button {
                        onChatSelected(UUID().uuidString)
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 16))
                            
                            Text("开始对话")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.primaryColor)
                        .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(conversations) { conversation in
                    Button {
                        onChatSelected(conversation.id)
                    } label: {
                        HStack(spacing: 12) {
                            // 角色头像
                            AsyncImage(url: URL(string: character.avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            
                            // 对话信息
                            VStack(alignment: .leading, spacing: 4) {
                                Text(character.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(conversation.lastMessageContent)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // 时间和消息数
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(timeAgoString(from: conversation.lastMessageTime))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                
                                Text("\(conversation.messageCount)条消息")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
    }
    
    /**
     * 将时间转换为"几分钟前"、"几小时前"等格式
     */
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes) 分钟前"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours) 小时前"
        } else if let days = components.day {
            return "\(days) 天前"
        } else {
            return "刚刚"
        }
    }
}

/**
 * 角色详情页预览
 */
struct CharacterDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CharacterDetailView(
                character: Character(
                    name: "阿尔伯特·爱因斯坦",
                    introduction: "现代物理学最重要的科学家之一，相对论的创立者。他的质能方程E=mc²彻底改变了人类对能量与物质关系的认识，而他的相对论则彻底改变了物理学的发展方向。",
                    field: "物理学家",
                    birthYear: "1879",
                    deathYear: "1955",
                    avatarUrl: "https://example.com/einstein.jpg",
                    eraTag: "1900s",
                    achievements: ["相对论", "光电效应", "质能方程"],
                    mainWorks: ["相对论：广义和狭义", "光电效应研究", "布朗运动研究"],
                    keyThoughts: ["时间和空间是相对的", "质量可以转化为能量", "自然界的规律是简单而统一的"]
                )
            )
        }
    }
} 