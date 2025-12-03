import SwiftUI
import SwiftData

// MARK: - 集成示例 1: 在角色详情页添加入口

/**
 * 示例：在角色详情页添加"互动画像"入口
 */
struct CharacterDetailWithInsightExample: View {
    let character: CharacterModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 角色头像和基本信息
                VStack {
                    Image(character.avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    
                    Text(character.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(character.era)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // 互动画像入口 - 新增部分
                NavigationLink {
                    CharacterChatInsightView(
                        characterId: character.id,
                        characterName: character.name
                    )
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("查看互动画像")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("了解你和\(character.name)的聊天风格")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 其他功能按钮
                // ...
            }
        }
        .navigationTitle("角色详情")
    }
}

// MARK: - 集成示例 2: 在聊天界面顶部添加按钮

/**
 * 示例：在聊天界面添加"画像"按钮
 */
struct ChatViewWithInsightButtonExample: View {
    let character: CharacterModel
    @Environment(\.modelContext) private var modelContext
    @State private var showInsight = false
    
    var body: some View {
        VStack {
            // 聊天消息列表
            ScrollView {
                // 消息内容...
            }
            
            // 输入框
            // ...
        }
        .navigationTitle(character.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showInsight = true
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showInsight) {
            NavigationStack {
                CharacterChatInsightView(
                    characterId: character.id,
                    characterName: character.name
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            showInsight = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 集成示例 3: 个人中心的画像列表

/**
 * 示例：在个人中心展示所有角色的画像列表
 */
struct MyInsightsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var caches: [CharacterChatInsightCache]
    
    var body: some View {
        List {
            if caches.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("还没有互动画像")
                        .font(.headline)
                    
                    Text("和角色多聊聊，生成你的专属画像")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(caches) { cache in
                    NavigationLink {
                        CharacterChatInsightView(
                            characterId: cache.characterId,
                            characterName: cache.characterName
                        )
                    } label: {
                        insightListRow(cache)
                    }
                }
            }
        }
        .navigationTitle("我的互动画像")
    }
    
    @ViewBuilder
    private func insightListRow(_ cache: CharacterChatInsightCache) -> some View {
        HStack(spacing: 12) {
            // 角色头像（如果有）
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(cache.characterName)
                    .font(.headline)
                
                Text("生成于 \(formatDate(cache.generatedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(cache.messageCount) 条对话")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - 集成示例 4: 简化版卡片（预览）

/**
 * 示例：在角色列表中显示简化版画像卡片
 */
struct InsightPreviewCard: View {
    let characterId: String
    let characterName: String
    @Environment(\.modelContext) private var modelContext
    @State private var insight: CharacterChatInsight?
    
    var body: some View {
        if let insight = insight {
            NavigationLink {
                CharacterChatInsightView(
                    characterId: characterId,
                    characterName: characterName
                )
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.orange)
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(insight.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        ForEach(insight.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        } else {
            // 加载画像
            ProgressView()
                .onAppear {
                    loadInsight()
                }
        }
    }
    
    private func loadInsight() {
        // 尝试从缓存加载
        do {
            let predicate = #Predicate<CharacterChatInsightCache> { cache in
                cache.characterId == characterId
            }
            let descriptor = FetchDescriptor<CharacterChatInsightCache>(predicate: predicate)
            let caches = try modelContext.fetch(descriptor)
            
            if let cache = caches.first {
                let decoder = JSONDecoder()
                insight = try decoder.decode(CharacterChatInsight.self, from: cache.insightData)
            }
        } catch {
            print("加载画像失败: \(error)")
        }
    }
}

// MARK: - 集成示例 5: 快捷菜单

/**
 * 示例：长按角色头像显示快捷菜单
 */
struct CharacterAvatarWithContextMenu: View {
    let character: CharacterModel
    @Environment(\.modelContext) private var modelContext
    @State private var showInsight = false
    
    var body: some View {
        Image(character.avatarImage)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .contextMenu {
                Button {
                    showInsight = true
                } label: {
                    Label("查看互动画像", systemImage: "sparkles")
                }
                
                Button {
                    // 其他操作
                } label: {
                    Label("查看资料", systemImage: "info.circle")
                }
            }
            .sheet(isPresented: $showInsight) {
                NavigationStack {
                    CharacterChatInsightView(
                        characterId: character.id,
                        characterName: character.name
                    )
                }
            }
    }
}

// MARK: - 使用服务的底层示例

/**
 * 示例：直接使用服务生成画像
 */
class InsightViewModel: ObservableObject {
    @Published var insight: CharacterChatInsight?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func generateInsight(
        characterId: String,
        characterName: String,
        modelContext: ModelContext
    ) {
        isLoading = true
        errorMessage = nil
        
        CharacterChatInsightService.shared.generateInsight(
            characterId: characterId,
            characterName: characterName,
            modelContext: modelContext
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let generatedInsight):
                    self?.insight = generatedInsight
                    print("✅ 画像生成成功: \(generatedInsight.title)")
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("❌ 画像生成失败: \(error)")
                }
            }
        }
    }
    
    func clearCache(characterId: String, modelContext: ModelContext) {
        CharacterChatInsightService.shared.clearCache(
            characterId: characterId,
            modelContext: modelContext
        )
        insight = nil
    }
}

// MARK: - 预览

#Preview("角色详情页") {
    NavigationStack {
        CharacterDetailWithInsightExample(
            character: CharacterModel(
                id: "shakespeare",
                name: "莎士比亚",
                era: "文艺复兴",
                avatarImage: "shakespeare_avatar"
            )
        )
    }
}

#Preview("画像列表") {
    NavigationStack {
        MyInsightsListView()
    }
}

