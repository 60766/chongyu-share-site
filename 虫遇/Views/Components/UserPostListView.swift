import SwiftUI

/**
 * 用户帖子列表视图
 * 显示用户发布的多条动态
 */
struct UserPostListView: View {
    // 帖子数据
    @State private var posts: [UserPostModel]
    
    // 其他状态
    @State private var isRefreshing: Bool = false
    @State private var selectedPost: UserPostModel? = nil
    @State private var showPostDetail: Bool = false
    @State private var selectedPostIndex: Int = 0
    // TabBar管理器
    @ObservedObject private var tabBarManager = TabBarManager.shared
    
    // 初始化
    init(posts: [UserPostModel]) {
        self._posts = State(initialValue: posts)
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 下拉刷新指示器
                if isRefreshing {
                    ProgressView()
                        .padding(.vertical, 8)
                }
                
                // 帖子列表
                ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                    PostCardView(
                        post: post,
                        onPostTap: {
                            selectedPost = post
                            selectedPostIndex = index
                            showPostDetail = true
                        },
                        onLikeToggle: { isLiked in
                            handleLike(at: index, isLiked: isLiked)
                        },
                        onBookmarkToggle: { isBookmarked in
                            handleBookmark(at: index, isBookmarked: isBookmarked)
                        }
                    )
                }
                
                // 空状态提示
                if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("还没有发布动态")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text("您的发布的动态将会显示在这里")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                }
                
                // 调整TabBar的底部填充，确保不会有额外空白
                Color.clear
                    .frame(height: tabBarManager.fullBottomAreaHeight - (tabBarManager.bottomSafeAreaHeight * 0.8))
                    .id("bottomSpacer")
            }
            .padding(16)
        }
        // 使用透明背景，而不是白色背景
        .background(Color.clear)
        .refreshable {
            await refreshData()
        }
        .ignoresSafeArea(.all, edges: .bottom) // 使内容可以延伸到底部安全区域
        .edgesIgnoringSafeArea(.bottom) // 确保完全延伸到屏幕底部
        .horizontalModal(
            item: $selectedPost, 
            direction: .fromRight,
            onDismiss: {
                showPostDetail = false
                selectedPost = nil
            }
        ) { post in
            FullscreenPostDetailView(
                post: post,
                onDismiss: {
                    showPostDetail = false
                    selectedPost = nil
                },
                onLike: { comment in
                    handleLikeComment(post: post, comment: comment)
                }
            )
        }
    }
    
    // 导航到下一个帖子
    private func navigateToNextPost() {
        guard !posts.isEmpty else { return }
        
        let newIndex = (selectedPostIndex + 1) % posts.count
        selectedPostIndex = newIndex
        selectedPost = posts[newIndex]
    }
    
    // 导航到上一个帖子
    private func navigateToPreviousPost() {
        guard !posts.isEmpty else { return }
        
        let newIndex = (selectedPostIndex - 1 + posts.count) % posts.count
        selectedPostIndex = newIndex
        selectedPost = posts[newIndex]
    }
    
    // 处理点赞
    private func handleLike(at index: Int, isLiked: Bool) {
        guard index < posts.count else { return }
        let updatedPost = posts[index].toggleLike(isLiked: isLiked)
        posts[index] = updatedPost
        
        // 这里可以添加网络请求，将点赞状态同步到服务器
    }
    
    // 处理收藏
    private func handleBookmark(at index: Int, isBookmarked: Bool) {
        guard index < posts.count else { return }
        let updatedPost = posts[index].toggleBookmark(isBookmarked: isBookmarked)
        posts[index] = updatedPost
        
        // 这里可以添加网络请求，将收藏状态同步到服务器
    }
    
    // 刷新数据
    private func refreshData() async {
        isRefreshing = true
        
        // 模拟网络请求延迟
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 在实际应用中，这里将是从API获取最新数据的代码
        // posts = await fetchPostsFromAPI()
        
        isRefreshing = false
    }
    
    // 处理评论点赞
    private func handleLikeComment(post: UserPostModel, comment: UserCommentModel) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        
        // 调用模型的likeComment方法，添加commentId:参数标签
        posts[index].likeComment(commentId: comment.id)
        
        // 更新当前选中的帖子
        if selectedPost?.id == post.id {
            selectedPost = posts[index]
        }
        
        // 这里可以添加网络请求，将点赞状态同步到服务器
    }
    
    // 处理添加评论
    private func handleAddComment(post: UserPostModel, content: String, replyToID: UUID?) {
        // 如果帖子模型有addComment方法
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            if let replyToID = replyToID {
                // 如果是回复，查找被回复的评论，设置回复的用户名
                func findComment(in comments: [UserCommentModel], id: UUID) -> UserCommentModel? {
                    for comment in comments {
                        if comment.id == id {
                            return comment
                        }
                        // 检查这个评论的回复
                        if let found = findComment(in: comment.replies, id: id) {
                            return found
                        }
                    }
                    return nil
                }
                
                // 查找回复的评论
                if let replyToComment = findComment(in: posts[index].comments, id: replyToID) {
                    // 添加带有回复信息的评论
                    posts[index].addComment(
                        username: "当前用户",  // 应替换为实际用户名
                        userAvatar: "person.circle.fill",  // 应替换为实际用户头像
                        content: content,
                        parentCommentId: replyToID,
                        replyToUsername: replyToComment.username
                    )
                }
            } else {
                // 直接添加评论
                posts[index].addComment(
                    username: "当前用户",  // 应替换为实际用户名
                    userAvatar: "person.circle.fill",  // 应替换为实际用户头像
                    content: content
                )
            }
        }
        
        // 这里可以添加网络请求，将评论同步到服务器
    }
}

// 预览
struct UserPostListView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserPostListView(posts: ModelData.samplePosts)
                .previewDisplayName("有内容")
            
            UserPostListView(posts: [])
                .previewDisplayName("空状态")
        }
    }
} 