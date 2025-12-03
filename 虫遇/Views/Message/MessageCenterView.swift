import SwiftUI
import SwiftData

/**
 * 消息中心视图
 * 显示用户与角色的对话列表
 */
struct MessageCenterView: View {
    /// SwiftData ModelContext
    @Environment(\.modelContext) private var modelContext
    
    /// 搜索文本
    @State private var searchText = ""
    /// 选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["全部对话", "未读消息", "收藏对话"]
    /// 对话数据（从SwiftData加载）
    @State private var conversations: [SDConversation] = []
    /// 模拟角色数据 - 修改为CYChatCharacter类型
    @State private var characters: [String: CYChatCharacter] = [:]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("消息中心")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // 设置按钮
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // 搜索栏
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("搜索对话", text: $searchText)
                        .foregroundColor(.primary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // 标签栏
            HStack(spacing: 20) {
                ForEach(0..<tabOptions.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedTabIndex = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tabOptions[index])
                                .font(.system(size: 16, weight: selectedTabIndex == index ? .bold : .regular))
                                .foregroundColor(selectedTabIndex == index ? .primary : .secondary)
                            
                            // 选中指示器
                            Rectangle()
                                .fill(selectedTabIndex == index ? Color.primaryColor : Color.clear)
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.top, 4)
            
            // 对话列表
            if filteredConversations.isEmpty {
                EmptyMessageView()
            } else {
                List {
                    ForEach(filteredConversations) { conversation in
                        ConversationRow(
                            conversation: conversation,
                            character: characters[conversation.characterId]
                        )
                        .swipeActions(edge: .trailing) {
                            // 删除操作
                            Button(role: .destructive) {
                                deleteConversation(conversation)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                            
                            // 标为已读/未读
                            Button {
                                toggleReadStatus(conversation)
                            } label: {
                                Label(
                                    conversation.messageCount > 0 ? "已读" : "未读",
                                    systemImage: conversation.messageCount > 0 ? "envelope.open" : "envelope.badge"
                                )
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading) {
                            // 收藏操作
                            Button {
                                toggleFavorite(conversation)
                            } label: {
                                Label("收藏", systemImage: "star")
                            }
                            .tint(.yellow)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .onAppear {
            loadConversations()
            loadMockCharacters()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ConversationsRestored"))) { _ in
            // 当对话恢复后，重新加载对话列表
            loadConversations()
        }
    }
    
    /// 过滤后的对话列表（按时间排序，最新的在前）
    private var filteredConversations: [SDConversation] {
        var result = conversations
        
        // 根据标签过滤
        switch selectedTabIndex {
        case 1: // 未读消息
            result = result.filter { $0.messageCount > 0 }
        case 2: // 收藏对话
            result = result.filter { _ in false } // 模拟数据没有收藏功能
        default:
            break
        }
        
        // 根据搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter {
                if let character = characters[$0.characterId] {
                    return character.name.lowercased().contains(searchText.lowercased()) ||
                           $0.lastMessageContent.lowercased().contains(searchText.lowercased())
                }
                return false
            }
        }
        
        // 按最后消息时间排序（最新的在前）
        return result.sorted { $0.lastMessageTime > $1.lastMessageTime }
    }
    
    /// 删除对话
    private func deleteConversation(_ conversation: SDConversation) {
        // 从SwiftData删除对话及其所有消息
        do {
            let conversationId = conversation.id
            // 删除所有相关消息
            let messagesDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.conversationId == conversationId
                }
            )
            let messages = try modelContext.fetch(messagesDescriptor)
            for message in messages {
                modelContext.delete(message)
            }
            
            // 删除对话
            modelContext.delete(conversation)
            try modelContext.save()
            
            // 从本地数组移除
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations.remove(at: index)
            }
            
            #if DEBUG
            print("✅ 已删除对话: \(conversation.id)")
            #endif
        } catch {
            #if DEBUG
            print("❌ 删除对话失败: \(error)")
            #endif
        }
    }
    
    /// 切换已读/未读状态
    private func toggleReadStatus(_ conversation: SDConversation) {
        // 更新SwiftData中的对话
        do {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].messageCount = conversations[index].messageCount > 0 ? 0 : 1
                try modelContext.save()
            }
        } catch {
            #if DEBUG
            print("❌ 更新对话状态失败: \(error)")
            #endif
        }
    }
    
    /// 切换收藏状态
    private func toggleFavorite(_ conversation: SDConversation) {
        // 实际项目中应该实现收藏功能
    }
    
    /**
     * 从SwiftData加载真实对话数据
     */
    private func loadConversations() {
        do {
            let currentUserId = AppAccountManager.shared.appAccountToken
            let fetchDescriptor = FetchDescriptor<SDConversation>(
                predicate: #Predicate { $0.userId == currentUserId },
                sortBy: [SortDescriptor(\.lastMessageTime, order: .reverse)] // 按最后消息时间倒序排列
            )
            conversations = try modelContext.fetch(fetchDescriptor)
            #if DEBUG
            print("✅ MessageCenterView: 加载了 \(conversations.count) 个对话（已按时间排序）")
            #endif
        } catch {
            #if DEBUG
            print("❌ MessageCenterView: 加载对话失败: \(error)")
            #endif
            conversations = []
        }
    }
    
    /**
     * 加载角色数据（用于显示角色信息）
     */
    private func loadMockCharacters() {
        // 模拟角色数据 - 使用CYChatCharacter替代Character
        let einstein = CYChatCharacter(
            id: "1",
            name: "阿尔伯特·爱因斯坦",
            introduction: "现代物理学最重要的科学家之一，相对论的创立者",
            field: "物理学家",
            birthYear: "1879",
            deathYear: "1955",
            avatarUrl: "https://example.com/einstein.jpg",
            eraTag: "1900s",
            achievements: ["相对论", "光电效应", "质能方程"],
            mainWorks: ["相对论：广义和狭义"],
            keyThoughts: ["时间和空间是相对的", "质量可以转化为能量"]
        )
        
        let socrates = CYChatCharacter(
            id: "2",
            name: "苏格拉底",
            introduction: "古希腊哲学家，西方哲学的奠基人之一",
            field: "哲学家",
            birthYear: "公元前469年",
            deathYear: "公元前399年",
            avatarUrl: "https://example.com/socrates.jpg",
            eraTag: "古希腊",
            achievements: ["苏格拉底方法", "道德哲学"],
            mainWorks: ["柏拉图对话录中记载"],
            keyThoughts: ["未经审视的生活不值得过", "认识你自己"]
        )
        
        let davinci = CYChatCharacter(
            id: "3",
            name: "伦纳德·达·芬奇",
            introduction: "意大利文艺复兴时期的多才多艺的人，艺术家、发明家、工程师",
            field: "艺术家",
            birthYear: "1452",
            deathYear: "1519",
            avatarUrl: "https://example.com/davinci.jpg",
            eraTag: "文艺复兴",
            achievements: ["蒙娜丽莎", "最后的晚餐", "解剖学研究"],
            mainWorks: ["蒙娜丽莎", "最后的晚餐"],
            keyThoughts: ["简单是终极的复杂", "人类的智慧在于观察"]
        )
        
        // 存储角色数据，方便通过ID查询
        characters = [
            einstein.id: einstein,
            socrates.id: socrates,
            davinci.id: davinci
        ]
        
        // 模拟对话数据
        conversations = [
            SDConversation(
                id: "1",
                characterId: einstein.id,
                userId: "currentUser",
                lastMessageContent: "我很好奇，您在研究相对论时，最初的灵感是从哪里来的？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 2),
                messageCount: 3
            ),
            SDConversation(
                id: "2",
                characterId: socrates.id,
                userId: "currentUser",
                lastMessageContent: "您认为什么是真正的智慧？如何分辨真理和谬误？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 24),
                messageCount: 0
            ),
            SDConversation(
                id: "3",
                characterId: davinci.id,
                userId: "currentUser",
                lastMessageContent: "我很欣赏您的蒙娜丽莎，能告诉我创作这幅作品的灵感来源吗？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 24 * 3),
                messageCount: 1
            )
        ]
    }
}

/**
 * 对话行项目
 */
struct ConversationRow: View {
    var conversation: SDConversation
    var character: CYChatCharacter?
    
    var body: some View {
        NavigationLink(destination: ChatView(character: character ?? CYChatCharacter(
            id: conversation.characterId,
            name: "未知角色",
            introduction: "",
            field: "",
            birthYear: "",
            deathYear: "",
            avatarUrl: "",
            eraTag: "",
            achievements: [],
            mainWorks: [],
            keyThoughts: []
        ))) {
            HStack(spacing: 12) {
                // 角色头像
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: character?.avatarUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    // 未读消息标记
                    if conversation.messageCount > 0 {
                        Text("\(conversation.messageCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 4, y: 4)
                    }
                }
                
                // 对话信息
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(character?.name ?? "未知角色")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(timeAgoString(from: conversation.lastMessageTime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(conversation.lastMessageContent)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 8)
        }
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
 * 空消息视图
 */
struct EmptyMessageView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("暂无消息")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("开始与历史人物对话，探索古今智慧")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            NavigationLink(destination: ExploreView()) {
                Text("去探索")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primaryColor)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/**
 * 消息中心预览
 */
struct MessageCenterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MessageCenterView()
        }
    }
} 