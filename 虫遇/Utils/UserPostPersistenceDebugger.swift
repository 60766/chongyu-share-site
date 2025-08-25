import Foundation
import SwiftUI

/**
 * 用户动态持久化调试工具
 * 用于验证用户动态的保存和恢复功能
 */
class UserPostPersistenceDebugger: ObservableObject {
    
    static let shared = UserPostPersistenceDebugger()
    
    private let userPostsKey = "UserPosts_v1"
    private let aiPostsKey = "AIPosts_v1"
    
    private init() {}
    
    /**
     * 检查当前UserDefaults中是否有用户帖子数据
     */
    func checkUserPostsInStorage() -> String {
        var debugInfo = "🔍 动态持久化检查报告\n"
        debugInfo += "==============================\n\n"
        
        // 检查用户帖子数据
        debugInfo += "📱 用户动态检查:\n"
        debugInfo += "-------------------\n"
        if let data = UserDefaults.standard.data(forKey: userPostsKey) {
            debugInfo += "✅ 在UserDefaults中找到用户帖子数据\n"
            debugInfo += "📦 数据大小: \(data.count) bytes\n"
            
            // 尝试解码数据
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let userPosts = try decoder.decode([UserPostModel].self, from: data)
                
                debugInfo += "✅ 成功解码用户帖子\n"
                debugInfo += "📊 帖子数量: \(userPosts.count)\n\n"
                
                // 显示每个帖子的详细信息
                for (index, post) in userPosts.enumerated() {
                    debugInfo += "📝 帖子 #\(index + 1):\n"
                    debugInfo += "   ID: \(post.id)\n"
                    debugInfo += "   内容: \(String(post.content.prefix(50)))\(post.content.count > 50 ? "..." : "")\n"
                    debugInfo += "   作者: \(post.username)\n"
                    debugInfo += "   来源: \(post.source ?? "未知")\n"
                    debugInfo += "   发布时间: \(formatDate(post.datePosted))\n"
                    debugInfo += "   点赞数: \(post.likes)\n"
                    debugInfo += "   评论数: \(post.comments.count)\n\n"
                }
            } catch {
                debugInfo += "❌ 解码用户帖子失败: \(error.localizedDescription)\n"
            }
        } else {
            debugInfo += "⚠️ 在UserDefaults中没有找到用户帖子数据\n"
            debugInfo += "   可能的原因:\n"
            debugInfo += "   1. 用户还没有发布过动态\n"
            debugInfo += "   2. 数据保存失败\n"
            debugInfo += "   3. 数据被清除或损坏\n\n"
        }
        
        // 检查AI生成的帖子数据
        debugInfo += "🤖 AI生成动态检查:\n"
        debugInfo += "-------------------\n"
        if let data = UserDefaults.standard.data(forKey: aiPostsKey) {
            debugInfo += "✅ 在UserDefaults中找到AI生成帖子数据\n"
            debugInfo += "📦 数据大小: \(data.count) bytes\n"
            
            // 尝试解码AI帖子数据
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let aiPosts = try decoder.decode([UserPostModel].self, from: data)
                
                debugInfo += "✅ 成功解码AI生成帖子\n"
                debugInfo += "📊 帖子数量: \(aiPosts.count)\n\n"
                
                // 按来源分组统计
                let sourceStats = Dictionary(grouping: aiPosts, by: { $0.source ?? "未知" })
                debugInfo += "📈 按来源分组:\n"
                for (source, posts) in sourceStats {
                    debugInfo += "   \(source): \(posts.count) 条\n"
                }
                debugInfo += "\n"
                
                // 显示最近5个AI帖子的详细信息
                let recentAIPosts = aiPosts.sorted { $0.datePosted > $1.datePosted }.prefix(5)
                if !recentAIPosts.isEmpty {
                    debugInfo += "🎯 最近的5个AI帖子:\n"
                    for (index, post) in recentAIPosts.enumerated() {
                        debugInfo += "   #\(index + 1): [\(post.source ?? "未知")] \(post.username)\n"
                        debugInfo += "      内容: \(String(post.content.prefix(30)))\(post.content.count > 30 ? "..." : "")\n"
                        debugInfo += "      时间: \(formatDate(post.datePosted))\n\n"
                    }
                }
            } catch {
                debugInfo += "❌ 解码AI生成帖子失败: \(error.localizedDescription)\n"
            }
        } else {
            debugInfo += "⚠️ 在UserDefaults中没有找到AI生成帖子数据\n\n"
        }
        
        // 检查PostViewModel中的数据
        let allPosts = PostViewModel.shared.posts
        let userPosts = allPosts.filter { $0.source == "user" }
        let aiPosts = allPosts.filter { post in
            guard let source = post.source else { return false }
            return source != "user" && source != "sample"
        }
        
        debugInfo += "📊 PostViewModel状态:\n"
        debugInfo += "   总帖子数: \(allPosts.count)\n"
        debugInfo += "   用户帖子数: \(userPosts.count)\n"
        debugInfo += "   AI生成帖子数: \(aiPosts.count)\n"
        debugInfo += "   示例帖子数: \(allPosts.filter { $0.source == "sample" }.count)\n\n"
        
        if !userPosts.isEmpty {
            debugInfo += "🎯 PostViewModel中的用户帖子:\n"
            for (index, post) in userPosts.enumerated() {
                debugInfo += "   #\(index + 1): \(String(post.content.prefix(30)))\(post.content.count > 30 ? "..." : "")\n"
            }
            debugInfo += "\n"
        }
        
        if !aiPosts.isEmpty {
            debugInfo += "🤖 PostViewModel中的AI帖子:\n"
            let sourceStats = Dictionary(grouping: aiPosts, by: { $0.source ?? "未知" })
            for (source, posts) in sourceStats {
                debugInfo += "   \(source): \(posts.count) 条\n"
            }
        }
        
        return debugInfo
    }
    
    /**
     * 创建一个测试用户帖子并保存
     */
    func createTestUserPost() -> String {
        var debugInfo = "🧪 创建测试用户帖子\n"
        debugInfo += "====================\n\n"
        
        let testPost = UserPostModel(
            id: UUID(),
            username: "测试用户",
            userAvatar: "person.circle.fill",
            content: "这是一个测试帖子，用于验证用户动态持久化功能。发布时间：\(Date())",
            images: [],
            datePosted: Date(),
            likes: 0,
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            contentType: "user_post",
            source: "user"
        )
        
        // 添加到PostViewModel
        PostViewModel.shared.addPosts([testPost])
        
        debugInfo += "✅ 测试帖子已创建并添加到PostViewModel\n"
        debugInfo += "📝 帖子内容: \(testPost.content)\n"
        debugInfo += "📅 发布时间: \(formatDate(testPost.datePosted))\n\n"
        
        return debugInfo
    }
    
    /**
     * 清除所有用户帖子数据（仅用于测试）
     */
    func clearUserPostsData() -> String {
        var debugInfo = "🧹 清除用户帖子数据\n"
        debugInfo += "====================\n\n"
        
        // 清除UserDefaults中的数据
        UserDefaults.standard.removeObject(forKey: userPostsKey)
        
        // 从PostViewModel中移除用户帖子
        let userPosts = PostViewModel.shared.posts.filter { $0.source == "user" }
        for post in userPosts {
            if let index = PostViewModel.shared.posts.firstIndex(where: { $0.id == post.id }) {
                PostViewModel.shared.posts.remove(at: index)
            }
        }
        
        debugInfo += "✅ 已清除UserDefaults中的用户帖子数据\n"
        debugInfo += "✅ 已从PostViewModel中移除 \(userPosts.count) 个用户帖子\n\n"
        
        return debugInfo
    }
    
    /**
     * 清除所有AI生成帖子数据（仅用于测试）
     */
    func clearAIPostsData() -> String {
        var debugInfo = "🧹 清除AI生成帖子数据\n"
        debugInfo += "========================\n\n"
        
        // 清除UserDefaults中的AI帖子数据
        UserDefaults.standard.removeObject(forKey: aiPostsKey)
        
        // 从PostViewModel中移除AI生成的帖子
        let aiPosts = PostViewModel.shared.posts.filter { post in
            guard let source = post.source else { return false }
            return source != "user" && source != "sample"
        }
        
        for post in aiPosts {
            if let index = PostViewModel.shared.posts.firstIndex(where: { $0.id == post.id }) {
                PostViewModel.shared.posts.remove(at: index)
            }
        }
        
        debugInfo += "✅ 已清除UserDefaults中的AI帖子数据\n"
        debugInfo += "✅ 已从PostViewModel中移除 \(aiPosts.count) 个AI帖子\n"
        
        // 按来源分组显示清除的帖子
        let sourceStats = Dictionary(grouping: aiPosts, by: { $0.source ?? "未知" })
        for (source, posts) in sourceStats {
            debugInfo += "   - \(source): \(posts.count) 条\n"
        }
        debugInfo += "\n"
        
        return debugInfo
    }
    
    /**
     * 清除所有帖子数据（用户+AI生成）
     */
    func clearAllPostsData() -> String {
        var debugInfo = "🧹 清除所有帖子数据\n"
        debugInfo += "====================\n\n"
        
        debugInfo += clearUserPostsData()
        debugInfo += clearAIPostsData()
        
        return debugInfo
    }
    
    /**
     * 测试持久化功能
     */
    func testPersistence() -> String {
        var debugInfo = "🔄 测试持久化功能\n"
        debugInfo += "==================\n\n"
        
        // 1. 清除现有数据
        debugInfo += "步骤1: 清除现有数据\n"
        debugInfo += clearUserPostsData()
        
        // 2. 创建测试帖子
        debugInfo += "步骤2: 创建测试帖子\n"
        debugInfo += createTestUserPost()
        
        // 3. 检查保存结果
        debugInfo += "步骤3: 检查保存结果\n"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let checkResult = self.checkUserPostsInStorage()
            print(checkResult)
        }
        
        debugInfo += "⏳ 保存检查将在0.5秒后显示...\n\n"
        
        return debugInfo
    }
    
    /**
     * 模拟应用重启后的数据恢复
     */
    func simulateAppRestart() -> String {
        var debugInfo = "🔄 模拟应用重启\n"
        debugInfo += "================\n\n"
        
        // 记录重启前的状态
        let postsBeforeRestart = PostViewModel.shared.posts.filter { $0.source == "user" }
        debugInfo += "重启前用户帖子数: \(postsBeforeRestart.count)\n\n"
        
        // 清除PostViewModel中的数据（模拟应用重启）
        PostViewModel.shared.posts.removeAll()
        debugInfo += "✅ 已清除PostViewModel中的所有帖子（模拟重启）\n"
        
        // 模拟PostViewModel的初始化流程
        // 1. 恢复用户帖子
        restoreUserPostsFromStorage()
        
        // 2. 加载示例帖子
        loadSamplePosts()
        
        let postsAfterRestart = PostViewModel.shared.posts.filter { $0.source == "user" }
        debugInfo += "✅ 模拟重启完成\n"
        debugInfo += "重启后用户帖子数: \(postsAfterRestart.count)\n"
        debugInfo += "总帖子数: \(PostViewModel.shared.posts.count)\n\n"
        
        if postsBeforeRestart.count == postsAfterRestart.count {
            debugInfo += "🎉 数据恢复成功！用户帖子完整保留\n"
        } else {
            debugInfo += "❌ 数据恢复失败！用户帖子丢失\n"
        }
        
        return debugInfo
    }
    
    // MARK: - Private Methods
    
    private func restoreUserPostsFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userPostsKey) else {
            print("🔍 没有找到持久化的用户帖子数据")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let userPosts = try decoder.decode([UserPostModel].self, from: data)
            
            // 将用户帖子按时间倒序添加到帖子列表的前面（最新的在最前面）
            let sortedUserPosts = userPosts.sorted { $0.datePosted > $1.datePosted }
            
            for post in sortedUserPosts {
                if !PostViewModel.shared.posts.contains(where: { $0.id == post.id }) {
                    PostViewModel.shared.posts.insert(post, at: 0)
                }
            }
            
            print("✅ 成功恢复 \(userPosts.count) 条用户帖子")
        } catch {
            print("❌ 恢复用户帖子失败: \(error.localizedDescription)")
        }
    }
    
    private func loadSamplePosts() {
        let samplePosts = ModelData.samplePosts
        
        // 添加示例帖子到现有帖子列表，避免重复
        for samplePost in samplePosts {
            if !PostViewModel.shared.posts.contains(where: { $0.id == samplePost.id }) {
                PostViewModel.shared.posts.append(samplePost)
            }
        }
        
        print("📦 加载了 \(samplePosts.count) 条示例帖子")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Debug View

struct UserPostPersistenceDebugView: View {
    @StateObject private var debugger = UserPostPersistenceDebugger.shared
    @State private var debugOutput = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("动态持久化调试工具")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    // 用户动态操作区
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📱 用户动态操作")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            
                            Button("检查存储状态") {
                                debugOutput = debugger.checkUserPostsInStorage()
                            }
                            .buttonStyle(DebugButtonStyle(color: .blue))
                            
                            Button("创建测试帖子") {
                                debugOutput = debugger.createTestUserPost()
                            }
                            .buttonStyle(DebugButtonStyle(color: .green))
                            
                            Button("清除用户帖子") {
                                debugOutput = debugger.clearUserPostsData()
                            }
                            .buttonStyle(DebugButtonStyle(color: .red))
                            
                            Button("测试持久化") {
                                debugOutput = debugger.testPersistence()
                            }
                            .buttonStyle(DebugButtonStyle(color: .orange))
                        }
                    }
                    
                    // AI生成动态操作区
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🤖 AI生成动态操作")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            
                            Button("清除AI帖子") {
                                debugOutput = debugger.clearAIPostsData()
                            }
                            .buttonStyle(DebugButtonStyle(color: .purple))
                            
                            Button("清除所有数据") {
                                debugOutput = debugger.clearAllPostsData()
                            }
                            .buttonStyle(DebugButtonStyle(color: .red))
                        }
                    }
                    
                    // 通用操作区
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚙️ 通用操作")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            
                            Button("模拟重启") {
                                debugOutput = debugger.simulateAppRestart()
                            }
                            .buttonStyle(DebugButtonStyle(color: .indigo))
                            
                            Button("清除输出") {
                                debugOutput = ""
                            }
                            .buttonStyle(DebugButtonStyle(color: .gray))
                        }
                    }
                    
                    if !debugOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("调试输出")
                                    .font(.headline)
                                Spacer()
                                Button("复制") {
                                    UIPasteboard.general.string = debugOutput
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            
                            Text(debugOutput)
                                .font(.system(.caption, design: .monospaced))
                                .padding(12)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DebugButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(color)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    UserPostPersistenceDebugView()
} 