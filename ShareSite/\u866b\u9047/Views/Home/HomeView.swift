    // 提取帖子列表为独立的计算属性
    private var postsListView: some View {
        VStack {
            // 显示帖子总数，便于调试
            if !postViewModel.posts.isEmpty {
                Text("当前帖子数量: \(postViewModel.posts.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .id("postsCounter_\(postViewModel.posts.count)") // 只依赖帖子数量，不依赖forceRefreshID
                    .onAppear {
                        print("🏠 帖子计数器已显示: \(postViewModel.posts.count) 篇帖子")
                    }
            }
            
            // 无帖子时显示提示信息
            if postViewModel.posts.isEmpty {
                Text("暂无帖子内容")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
                    .id("emptyPostsMessage")
                    .onAppear {
                        print("🏠 显示空帖子提示信息")
                    }
            } else {
                // 帖子列表 - 只依赖帖子数量变化，不依赖forceRefreshID
                ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
                    postCardView(for: post, at: index)
                        .onAppear {
                            // 在视图出现时打印日志，帮助调试
                            if index == 0 {
                                print("🏠 首篇帖子已显示: \(post.id) - \(post.content.prefix(50))...")
                            }
                        }
                }
                .id("postsForEach_\(postViewModel.posts.count)") // 只依赖帖子数量变化
            }
        }
        .onReceive(postViewModel.objectWillChange) { _ in
            // 接收到模型变更信号时，只记录日志，不强制刷新
            print("🏠 postsListView: 接收到postViewModel的objectWillChange信号")
            print("🏠 postsListView: 当前帖子数量: \(postViewModel.posts.count)")
            if !postViewModel.posts.isEmpty {
                print("🏠 postsListView: 首篇帖子: \(postViewModel.posts[0].content.prefix(50))...")
            }
            // 不再触发forceRefreshID，让SwiftUI自然更新
        }
        // 处理增量更新通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostsIncrementallyUpdated"))) { notification in
            if let count = notification.userInfo?["newPostsCount"] as? Int,
               let postIds = notification.userInfo?["newPostIds"] as? [String] {
                print("🏠 postsListView: 收到增量更新通知，\(count)个新帖子")
                print("🏠 postsListView: 新帖子IDs: \(postIds)")
                // 不需要强制刷新，SwiftUI会自动处理数据变化
            }
        }
        // 处理单帖子添加通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SinglePostAdded"))) { notification in
            if let postId = notification.userInfo?["newPostId"] as? String,
               let content = notification.userInfo?["newPostContent"] as? String {
                print("🏠 postsListView: 收到单帖子添加通知")
                print("🏠 postsListView: 新帖子ID: \(postId), 内容: \(content)")
                // 不需要强制刷新，SwiftUI会自动处理数据变化
            }
        }
        // 每当视图出现时，只记录状态，不主动刷新
        .onAppear {
            print("🏠 postsListView: 视图已出现，当前帖子数量: \(postViewModel.posts.count)")
            // 不再主动触发刷新，让SwiftUI自然管理
        }
    } 