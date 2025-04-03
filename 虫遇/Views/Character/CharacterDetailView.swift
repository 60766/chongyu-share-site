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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部信息卡
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
                    HStack(spacing: 40) {
                        VStack {
                            Text("3,542")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("粉丝")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("14.2K")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("互动量")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("4.9")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("评分")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 主要标签
                    HStack(spacing: 8) {
                        ForEach(character.keyThoughts.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(16)
                        }
                    }
                    
                    // 操作按钮
                    HStack(spacing: 20) {
                        Button(action: {
                            // 关注操作
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primaryColor)
                                
                                Text("关注")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)
                        }
                        
                        NavigationLink(destination: ChatView(character: character, conversationId: UUID().uuidString)) {
                            VStack(spacing: 4) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primaryColor)
                                
                                Text("对话")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)
                        }
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primaryColor)
                                
                                Text("分享")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60)
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                
                // 内容标签页
                HStack(spacing: 0) {
                    ForEach(0..<tabOptions.count, id: \.self) { index in
                        Button(action: {
                            withAnimation {
                                selectedTabIndex = index
                            }
                        }) {
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
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 标签页内容
                TabView(selection: $selectedTabIndex) {
                    // 介绍标签页
                    CharacterIntroductionView(character: character)
                        .tag(0)
                    
                    // 相关信息标签页
                    CharacterRelatedInfoView(character: character)
                        .tag(1)
                    
                    // 互动记录标签页
                    CharacterInteractionView(character: character, conversations: conversations)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.6)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            // 分享界面
            Text("分享 \(character.name) 的信息")
        }
        .onAppear {
            loadMockData()
        }
    }
    
    /**
     * 加载模拟数据
     */
    private func loadMockData() {
        // 加载模拟对话记录
        conversations = [
            Conversation(
                id: UUID().uuidString,
                characterId: character.id,
                userId: "currentUser",
                lastMessageContent: "我很好奇，您在研究相对论时，最初的灵感是从哪里来的？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 24 * 2),
                messageCount: 12
            ),
            Conversation(
                id: UUID().uuidString,
                characterId: character.id,
                userId: "currentUser",
                lastMessageContent: "您认为人工智能会在未来取代人类的创造力吗？",
                lastMessageTime: Date().addingTimeInterval(-3600 * 24 * 5),
                messageCount: 8
            )
        ]
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
 * 角色互动记录视图
 */
struct CharacterInteractionView: View {
    var character: Character
    var conversations: [Conversation]
    
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
                    
                    // 开始对话按钮
                    NavigationLink(destination: ChatView(character: character, conversationId: UUID().uuidString)) {
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(conversations) { conversation in
                    NavigationLink(destination: ChatView(character: character, conversationId: conversation.id)) {
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