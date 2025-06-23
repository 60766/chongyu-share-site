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
    
    // 帖子操作相关
    @State private var editingPost: UserPostModel? = nil
    @State private var showEditPostView: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var postToDelete: UserPostModel? = nil
    
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
                
                // 帖子列表 - 拆分为更小的表达式，避免编译器超时
                ForEach(Array(posts.enumerated()), id: \.element.id) { indexedPost in
                    let index = indexedPost.offset
                    let post = indexedPost.element
                    
                    // 拆分创建PostCardView的过程
                    createPostCardView(post: post, index: index)
                }
                
                // 空状态提示
                if posts.isEmpty {
                    emptyStateView()
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
        // 添加编辑帖子视图的sheet
        .sheet(item: $editingPost) { post in
            EditPostView(
                post: post,
                onClose: {
                    print("关闭编辑视图")
                    editingPost = nil
                },
                onUpdate: { newContent, newImages in
                    print("更新帖子内容，新内容长度: \(newContent.count), 图片数: \(newImages.count)")
                    updatePost(post, content: newContent, images: newImages)
                }
            )
            .presentationDetents([.height(550), .large])
            .onAppear {
                // 添加延迟，确保视图完全加载
                print("EditPostView 开始加载，帖子ID: \(post.id)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("EditPostView 已完全加载")
                }
            }
        }
        // 添加删除确认对话框
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {
                postToDelete = nil
            }
            Button("删除", role: .destructive) {
                if let post = postToDelete {
                    deletePost(post)
                    postToDelete = nil
                }
            }
        } message: {
            Text("确认删除这条帖子吗？此操作不可撤销。")
        }
    }
    
    // 提取出创建PostCardView的方法
    @ViewBuilder
    private func createPostCardView(post: UserPostModel, index: Int) -> some View {
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
            },
            onShare: {
                let content = "\(post.username)的虫遇动态: \(post.content)"
                shareContent(content)
                HapticFeedbackManager.shared.selectionChanged()
            },
            isOwnPost: post.source == "user",
            onEdit: {
                handleEditPost(post)
            },
            onDelete: {
                handleDeletePost(post)
            },
            onPin: { isPinned in
                handlePinPost(post, isPinned: isPinned)
            },
            postSource: post.source == "user" ? .userGenerated : .aiGenerated
        )
    }
    
    // 提取出空状态视图
    @ViewBuilder
    private func emptyStateView() -> some View {
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
    private func handleLikeComment(post: UserPostModel, comment: DetailedCommentModel) {
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
                func findComment(in comments: [DetailedCommentModel], id: UUID) -> DetailedCommentModel? {
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
    
    // MARK: - 帖子操作方法
    
    // 处理编辑帖子
    private func handleEditPost(_ post: UserPostModel) {
        print("开始编辑帖子: \(post.id), 内容: \(post.content.prefix(20))...")
        
        // 直接设置要编辑的帖子，不再需要标志变量
        editingPost = post
        print("✅ 设置editingPost成功: \(post.id)")
        
        // 触发触觉反馈
        HapticFeedbackManager.shared.selectionChanged()
    }
    
    // 处理删除帖子
    private func handleDeletePost(_ post: UserPostModel) {
        postToDelete = post
        showDeleteConfirmation = true
        HapticFeedbackManager.shared.notifyWarning()
    }
    
    // 处理置顶帖子
    private func handlePinPost(_ post: UserPostModel, isPinned: Bool) {
        var pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        
        if isPinned {
            // 确保不重复添加
            if !pinnedPosts.contains(post.id.uuidString) {
                pinnedPosts.append(post.id.uuidString)
            }
        } else {
            // 移除置顶
            pinnedPosts.removeAll { $0 == post.id.uuidString }
        }
        
        // 保存更新后的置顶帖子列表
        UserDefaults.standard.set(pinnedPosts, forKey: "PinnedPosts")
        
        // 为了在UI上立即反映变化，可以重新排序或强制刷新UI
        reorderPostsBasedOnPin()
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
    }
    
    // 更新帖子内容
    private func updatePost(_ post: UserPostModel, content: String, images: [UIImage]) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else {
            return
        }
        
        // 保存新图片并获取图片ID
        var imageIdentifiers: [String] = []
        for (i, image) in images.enumerated() {
            // 生成唯一图片标识符
            let imageId = "\(post.id)_updated_image_\(i)"
            
            // 保存图片到本地存储或云存储
            if ImageManager.shared.saveImage(image, withId: imageId) {
                imageIdentifiers.append(imageId)
            }
        }
        
        // 创建更新后的帖子对象
        let updatedPost = UserPostModel(
            id: post.id,
            username: post.username,
            userAvatar: post.userAvatar,
            content: content,
            images: imageIdentifiers,
            datePosted: post.datePosted,
            likes: post.likes,
            comments: post.comments,
            isLikedByCurrentUser: post.isLikedByCurrentUser,
            isBookmarkedByCurrentUser: post.isBookmarkedByCurrentUser,
            contentType: post.contentType,
            characterID: post.characterID,
            source: post.source
        )
        
        // 更新模型
        posts[index] = updatedPost
        
        // 如果正在查看的是同一帖子，也更新selectedPost
        if selectedPost?.id == post.id {
            selectedPost = updatedPost
        }
        
        // 显示成功提示
        ToastManager.shared.showToast(message: "帖子已更新")
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
    }
    
    // 删除帖子
    private func deletePost(_ post: UserPostModel) {
        // 从模型中删除帖子
        posts.removeAll { $0.id == post.id }
        
        // 如果正在查看的是被删除的帖子，关闭详情视图
        if selectedPost?.id == post.id {
            selectedPost = nil
        }
        
        // 显示成功提示
        ToastManager.shared.showToast(message: "帖子已删除")
        
        // 震动反馈
        HapticFeedbackManager.shared.notifySuccess()
        
        // 如果帖子是置顶的，也从置顶列表中移除
        var pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        pinnedPosts.removeAll { $0 == post.id.uuidString }
        UserDefaults.standard.set(pinnedPosts, forKey: "PinnedPosts")
    }
    
    // 根据置顶状态重新排序帖子
    private func reorderPostsBasedOnPin() {
        let pinnedPosts = UserDefaults.standard.stringArray(forKey: "PinnedPosts") ?? []
        
        // 将帖子分为置顶和非置顶两组
        var pinnedItems: [UserPostModel] = []
        var unpinnedItems: [UserPostModel] = []
        
        for post in posts {
            if pinnedPosts.contains(post.id.uuidString) {
                pinnedItems.append(post)
            } else {
                unpinnedItems.append(post)
            }
        }
        
        // 将置顶帖子按时间排序
        pinnedItems.sort { $0.datePosted > $1.datePosted }
        
        // 将非置顶帖子按时间排序
        unpinnedItems.sort { $0.datePosted > $1.datePosted }
        
        // 合并两组帖子
        posts = pinnedItems + unpinnedItems
    }

    // 分享内容
    private func shareContent(_ content: String) {
        // 创建分享项
        let items: [Any] = [content]
        
        // 创建活动视图控制器
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // 获取当前窗口场景和根视图控制器
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // 在iPad上设置popover源视图
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            // 显示分享菜单
            rootViewController.present(activityVC, animated: true)
        }
    }
}

// 预览
#Preview("有内容") {
    UserPostListView(posts: ModelData.samplePosts)
}

#Preview("空状态") {
    UserPostListView(posts: [])
} 