            // 自定义时空特效覆盖层
            if showCustomTimeSpaceEffect {
                GeometryReader { geometry in
                    // 计算黑洞中心位置 - 位于屏幕中央偏上的位置
                    let centerX = geometry.size.width / 2
                    // 向上调整Y轴位置，使特效从随机漫游按钮位置开始
                    let centerY = geometry.size.height / 2 + geometry.size.height * 0.25 - 290 // 修改为与其他文件一致
                    let blackHoleCenterPosition = CGPoint(x: centerX, y: centerY)
                    
                    // 使用自定义位置的TimeSpaceEffectView
                    TimeSpaceEffectView(
                        isActive: $showCustomTimeSpaceEffect, 
                        centerPosition: blackHoleCenterPosition
                    ) {
                        // 特效完成后的回调
                        print("⭐️ 时空特效完成，准备返回主页面")
                        
                        
                        // 在返回前生成帖子
                        let postVM = PostViewModel.shared
                        
                        // 获取当前选中的创作类型索引
                        let typeIndex = CreationTypeManager.shared.selectedIndex ?? 0
                        print("🚀 从FullscreenPostDetailView生成帖子，创作类型索引: \(typeIndex)")
                        
                        // 生成帖子
                        DispatchQueue.global(qos: .userInitiated).async {
                            // 在后台线程生成帖子，避免阻塞UI
                            let posts = postVM.generatePostsByCreationType(typeIndex: typeIndex)
                
                            
                            // 在主线程添加帖子
                            DispatchQueue.main.async {
                                if !posts.isEmpty {
                                    // 打印帖子信息
                                    for (index, post) in posts.enumerated() {
      
                                    }
                                    
                                    // 添加到帖子列表
                                    postVM.addPosts(posts)
                                    
                                    // 立即发送通知，确保 HomeView 能接收到
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PostsUpdated"),
                                        object: postVM,
                                        userInfo: [
                                            "newPostsCount": posts.count,
                                            "timestamp": Date().timeIntervalSince1970,
                                            "source": "FullscreenPostDetailView"
                                        ]
                                    )
                                    
                                    // 额外发送生成新帖子的通知
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("NewPostsGenerated"),
                                        object: postVM,
                                        userInfo: [
                                            "count": posts.count,
                                            "typeIndex": typeIndex,
                                            "timestamp": Date().timeIntervalSince1970
                                        ]
                                    )
                                    
                                    // 强制触发 ViewModel 的更新
                                    postVM.objectWillChange.send()
                                    
                                    // 确认帖子添加成功
                                    print("✅ 帖子添加完成，当前帖子总数: \(postVM.posts.count)")
                                } else {
                                    print("⚠️ 无法生成任何帖子，可能是 PostViewModel 出现问题")
                                }
                            }
                        }
                        
                        // 关闭虫洞探索页面
                        showAddContentView = false
                        
                        // 重置状态
                        dragOffset = 0
                        swipeDirection = .none
                        isTransitioning = false
                        
                        // 延迟一点调用onDismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onDismiss?()
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .zIndex(1000) // 确保特效显示在最上层
            } 