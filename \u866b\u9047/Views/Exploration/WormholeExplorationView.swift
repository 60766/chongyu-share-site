                    // 如果黑洞中心位置可用，则使用它作为特效中心
                    TimeSpaceEffectView(
                        isActive: $isShowingSpaceEffect,
                        centerPosition: centerPosition
                    ) {
                        // 特效完成后的回调
                        withAnimation {
                            isTransitioning = false
                            showGeneratedPostsMessage = true
                        }
                        
                        // 添加打印信息，跟踪执行情况
                        print("🚀 时空效果完成，准备生成帖子，当前选择的创作类型索引: \(typeManager.selectedIndex)")
                        print("🔍 调用栈检查：TimeSpaceEffectView回调正在被执行")
                        
                        // 确保创作类型管理器是有效的
                        guard let typeIndex = typeManager.selectedIndex else {
                            print("⚠️ 严重错误：创作类型索引不可用！使用默认值0")
                            generateAndAddPosts(typeIndex: 0)
                            return
                        }
                        
                        // 生成基于当前所选创作类型的帖子
                        generateAndAddPosts(typeIndex: typeIndex)
                    }
                    
    // 提取帖子生成和添加逻辑为独立函数，方便在不同位置调用
    private func generateAndAddPosts(typeIndex: Int) {
        print("🚀 generateAndAddPosts被调用，创作类型索引: \(typeIndex)")
        
        // 生成基于当前所选创作类型的5个帖子
        var posts = postViewModel.generatePostsByCreationType(typeIndex: typeIndex)
        
        // 检查帖子是否生成成功 - 增加保障措施，确保生成的帖子有效
        if posts.isEmpty {
            print("⚠️ 严重错误：第一次尝试未生成任何帖子！重试...")
            // 重试一次
            posts = postViewModel.generatePostsByCreationType(typeIndex: typeIndex)
            
            if posts.isEmpty {
                print("⚠️⚠️ 严重错误：第二次尝试仍未生成任何帖子！")
                // 最后尝试通过强制索引生成
                posts = postViewModel.generatePostsByCreationType(typeIndex: 0)
                
                if posts.isEmpty {
                    print("⚠️⚠️⚠️ 致命错误：无法生成任何帖子，可能是PostViewModel出现问题")
                    // 显示错误信息后立即关闭，避免错误状态持续
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            showGeneratedPostsMessage = false
                        }
                    }
                    return
                }
            }
        }
        
        // 更新生成成功的帖子数量
        generatedPostsCount = posts.count
        print("✅ 成功生成 \(posts.count) 个帖子，创作类型: \(typeManager.types[typeIndex])")
        
        // 检查帖子内容有效性
        for (index, post) in posts.enumerated() {
            print("📝 帖子 #\(index+1): ID=\(post.id), 内容=\(post.content.prefix(30))...")
        }
        
        // 在主线程处理UI更新
        DispatchQueue.main.async {
            print("🔄 主线程开始添加帖子")
            
            // 先触发 objectWillChange，确保 UI 知道数据将要变化
            postViewModel.objectWillChange.send()
            
            // 捕获当前帖子数量，用于后续验证
            let beforeCount = postViewModel.posts.count
            print("📊 添加前帖子总数: \(beforeCount)")
            
            // 手动验证帖子 ID 是否重复
            var postIds = Set<UUID>()
            var hasDuplicates = false
            for post in posts {
                if postIds.contains(post.id) {
                    hasDuplicates = true
                    print("⚠️ 发现重复帖子ID: \(post.id)")
                } else {
                    postIds.insert(post.id)
                }
            }
            
            if hasDuplicates {
                print("⚠️ 生成的帖子中存在ID重复，这可能导致添加问题")
            }
            
            // 添加到现有帖子列表的前面
            postViewModel.addPosts(posts)
            
            // 额外发送系统通知
            NotificationCenter.default.post(
                name: NSNotification.Name("PostsUpdated"),
                object: nil,
                userInfo: [
                    "newPostsCount": posts.count,
                    "timestamp": Date().timeIntervalSince1970,
                    "source": "WormholeExplorationView"
                ]
            )
            
            // 验证添加成功
            let afterCount = postViewModel.posts.count
            let expectedCount = beforeCount + posts.count
            print("📊 添加后帖子总数: \(afterCount)，预期总数: \(expectedCount)")
            
            if afterCount != expectedCount {
                print("⚠️ 错误：帖子添加异常！预期添加后总数\(expectedCount)，实际\(afterCount)")
                
                // 如果 PostViewModel 没有正确添加帖子，尝试直接添加
                if afterCount == beforeCount {
                    print("🔄 尝试强制添加帖子...")
                    var updatedPosts = postViewModel.posts
                    updatedPosts.insert(contentsOf: posts, at: 0)
                    postViewModel.posts = updatedPosts
                    
                    // 再次验证
                    let newCount = postViewModel.posts.count
                    print("📊 强制添加后总数: \(newCount)")
                    
                    // 强制触发刷新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        postViewModel.objectWillChange.send()
                        
                        // 发送通知
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PostsUpdated"),
                            object: postViewModel,
                            userInfo: [
                                "newPostsCount": posts.count,
                                "timestamp": Date().timeIntervalSince1970,
                                "source": "WormholeExplorationView-ForcedUpdate"
                            ]
                        )
                    }
                }
            } else {
                print("✅ 帖子添加成功，从索引0开始新增了\(posts.count)个帖子")
                
                // 确认首篇帖子内容
                if !postViewModel.posts.isEmpty {
                    let firstPost = postViewModel.posts[0]
                    print("📝 当前首篇帖子: ID=\(firstPost.id), 内容=\(firstPost.content.prefix(30))...")
                }
            }
            
            // 额外触发两次刷新，确保UI更新
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔄 延迟0.3秒后触发额外刷新")
                postViewModel.objectWillChange.send()
                
                // 再次发送通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("NewPostsGenerated"),
                    object: postViewModel,
                    userInfo: [
                        "count": posts.count,
                        "typeIndex": typeIndex,
                        "timestamp": Date().timeIntervalSince1970 + 0.3
                    ]
                )
                
                // 连续触发第二次刷新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("🔄 延迟0.5秒后触发第二次额外刷新")
                    postViewModel.objectWillChange.send()
                }
            }
        }
        
        // 显示成功信息一段时间后关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showGeneratedPostsMessage = false
            }
            
            // 提供额外的视觉和触觉反馈
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            print("✨ 所有生成和通知步骤已完成，即将返回主界面")
            
            // 返回主界面前，再次触发objectWillChange，确保UI刷新
            DispatchQueue.main.async {
                postViewModel.objectWillChange.send()
                
                // 最后一次发送通知，确保首页能接收到
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostsUpdated"),
                    object: postViewModel,
                    userInfo: [
                        "newPostsCount": posts.count,
                        "timestamp": Date().timeIntervalSince1970 + 1.5,
                        "source": "WormholeExplorationView-Final"
                    ]
                )
            }
        }
    } 