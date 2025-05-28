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
                    .id("postsCounter_\(forceRefreshID)")
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
                    .id("emptyPostsMessage_\(forceRefreshID)")
                    .onAppear {
                        print("🏠 显示空帖子提示信息")
                    }
            } else {
                // 添加一个隐藏的Text来强制刷新
                Text("")
                    .frame(width: 0, height: 0)
                    .id("forceRefreshTrigger_\(forceRefreshID)_\(postViewModel.posts.count)")
                    .onAppear {
                        print("🏠 强制刷新触发器已加载: \(forceRefreshID)")
                    }
                
                // 帖子列表 - 使用ID确保在帖子数量变化时重新渲染
                ForEach(Array(postViewModel.posts.enumerated()), id: \.element.id) { index, post in
                    postCardView(for: post, at: index)
                        .id("\(post.id)_\(forceRefreshID)") // 在强制刷新时更新视图ID
                        .onAppear {
                            // 在视图出现时打印日志，帮助调试
                            if index == 0 {
                                print("🏠 首篇帖子已显示: \(post.id) - \(post.content.prefix(50))...")
                            }
                        }
                }
                .id("postsForEach_\(postViewModel.posts.count)_\(forceRefreshID)") // 当帖子数量变化或forceRefreshID变化时，整个ForEach会重新创建
            }
        }
        .onReceive(postViewModel.objectWillChange) { _ in
            // 接收到模型变更信号时添加额外日志
            print("🏠 postsListView: 接收到postViewModel的objectWillChange信号")
            print("🏠 postsListView: 当前帖子数量: \(postViewModel.posts.count)")
            if !postViewModel.posts.isEmpty {
                print("🏠 postsListView: 首篇帖子: \(postViewModel.posts[0].content.prefix(50))...")
            }
            
            // 强制刷新 - 使用主线程异步调用来确保安全访问UI
            DispatchQueue.main.async {
                self.forceRefreshID = UUID()
                print("🔄 postsListView: 已触发强制刷新，新ID: \(self.forceRefreshID)")
                
                // 延迟0.1秒后再次触发刷新，确保UI更新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.forceRefreshID = UUID()
                    print("🔄 postsListView: 延迟0.1秒后再次触发刷新，新ID: \(self.forceRefreshID)")
                    
                    // 如果仍然没有显示更新，尝试第三次刷新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.forceRefreshID = UUID()
                        print("🔄 postsListView: 延迟0.3秒后第三次触发刷新，新ID: \(self.forceRefreshID)")
                        
                        // 添加第四次延迟刷新，以防前面三次都没有成功
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.forceRefreshID = UUID()
                            print("🔄 postsListView: 延迟0.6秒后第四次触发刷新，新ID: \(self.forceRefreshID)")
                        }
                    }
                }
            }
        }
        // 添加接收通知中心的通知，确保响应通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostsUpdated"))) { notification in
            if let count = notification.userInfo?["newPostsCount"] as? Int {
                print("🏠 postsListView: 收到PostsUpdated通知，\(count)个新帖子")
                if let source = notification.userInfo?["source"] as? String {
                    print("🏠 postsListView: 通知来源: \(source)")
                }
                
                // 强制刷新
                DispatchQueue.main.async {
                    self.forceRefreshID = UUID()
                    print("🔄 postsListView(通知): 已触发强制刷新，新ID: \(self.forceRefreshID)")
                    
                    // 延迟再次刷新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.forceRefreshID = UUID()
                        print("🔄 postsListView(通知): 延迟0.2秒后再次触发刷新，新ID: \(self.forceRefreshID)")
                    }
                }
            }
        }
        // 添加接收NewPostsGenerated通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewPostsGenerated"))) { notification in
            if let count = notification.userInfo?["count"] as? Int {
                print("🏠 postsListView: 收到NewPostsGenerated通知，\(count)个新帖子")
                
                // 强制刷新
                DispatchQueue.main.async {
                    self.forceRefreshID = UUID()
                    print("🔄 postsListView(生成通知): 已触发强制刷新，新ID: \(self.forceRefreshID)")
                    
                    // 延迟再次刷新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.forceRefreshID = UUID()
                        print("🔄 postsListView(生成通知): 延迟0.25秒后再次触发刷新，新ID: \(self.forceRefreshID)")
                    }
                }
            }
        }
        // 每当视图出现时，主动刷新一次
        .onAppear {
            print("🏠 postsListView: 视图已出现，当前帖子数量: \(postViewModel.posts.count)")
            // 短延迟后触发刷新，确保所有UI组件已准备好
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forceRefreshID = UUID()
                print("🔄 postsListView(onAppear): 已触发强制刷新，新ID: \(self.forceRefreshID)")
            }
        }
    } 