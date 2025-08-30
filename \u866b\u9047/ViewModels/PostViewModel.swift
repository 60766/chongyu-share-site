import SwiftUI
import Foundation
// 确保导入ResponseGenerationSystem
import Utils

/// 添加一组帖子到列表前端
/// - Parameter newPosts: 要添加的帖子数组
func addPosts(_ newPosts: [UserPostModel]) {
    // 记录添加前的帖子数量
    let oldCount = posts.count
    
    
    // 避免添加空数组
          if newPosts.isEmpty {
          return
      }
    
    // 先触发objectWillChange，确保订阅者知道数据将要变化
    DispatchQueue.main.async {
        self.objectWillChange.send()

    }
    
    
    
    
    // 检查是否有重复ID的帖子，避免添加重复内容
    var uniquePosts = [UserPostModel]()
    var existingIds = Set<UUID>(posts.map { $0.id })
    
    for post in newPosts {
        if !existingIds.contains(post.id) {
            uniquePosts.append(post)
            existingIds.insert(post.id)
  
        } else {
            print("⚠️ PostViewModel: 发现重复帖子ID: \(post.id)，已跳过")
        }
    }
    
          if uniquePosts.isEmpty {
          return
      }
    
    // 将新帖子添加到列表前面
    
    
    // 使用写时复制确保UI更新
    var newPosts = posts
    newPosts.insert(contentsOf: uniquePosts, at: 0)
    posts = newPosts
    
    // 验证添加是否成功
          let newCount = posts.count
      let addedCount = uniquePosts.count
    
    // 检查第一篇帖子是否就是新添加的第一篇
    if let firstNewPost = uniquePosts.first, let firstPost = posts.first {
        let isFirstPostMatch = firstNewPost.id == firstPost.id

    }
    
    // 强制触发变更通知，确保UI更新
    DispatchQueue.main.async { [weak self] in
        guard let self = self else { 
            print("⚠️ PostViewModel: self已被释放，无法发送通知")
            return 
        }
        
        print("📱 PostViewModel: 在主线程发送objectWillChange")
        
        // 延迟一点点发送，确保UI组件已准备好
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.objectWillChange.send()
        }
        
        // 立即发送通知，通知订阅者帖子列表已更新
        let userInfo: [String: Any] = [
            "newPostsCount": uniquePosts.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 发送PostsUpdated通知
        NotificationCenter.default.post(
            name: NSNotification.Name("PostsUpdated"),
            object: self,  // 使用self作为object便于识别通知来源
            userInfo: userInfo
        )
        
        // 额外发送NewPostsGenerated通知，增加冗余保障
        NotificationCenter.default.post(
            name: NSNotification.Name("NewPostsGenerated"),
            object: self,
            userInfo: [
                "count": uniquePosts.count,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        
        
        
        // 增加延迟再次触发，确保所有UI组件都能正确处理变更
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            print("�� PostViewModel: 延迟0.1秒后再次触发objectWillChange")
            self.objectWillChange.send()
            
            // 延迟发送第二次通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                
                print("📱 PostViewModel: 延迟0.2秒后发送第二次通知")
                
                // 第二次发送通知，确保接收者能收到
                NotificationCenter.default.post(
                    name: NSNotification.Name("PostsUpdated"),
                    object: self,
                    userInfo: userInfo
                )
                
                // 第三次触发objectWillChange
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    
                    print("📱 PostViewModel: 延迟0.3秒后第三次触发objectWillChange")
                    self.objectWillChange.send()
                    
                    // 打印最终状态确认
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        guard let self = self else { return }
                        

                    }
                }
            }
        }
    }
}

/**
 * 根据创作类型生成帖子
 * 在探索页面中，用户选择创作类型后调用该方法生成对应类型的帖子
 */
func generatePostsByCreationType(typeIndex: Int) -> [UserPostModel] {
    // 添加详细日志，便于排查问题
    print("📱 generatePostsByCreationType被调用，类型索引: \(typeIndex)")
    
    // 创建默认用户名和头像 - 确保这些值不会为空
    let defaultUsername = "虫遇探索者"
    let defaultAvatars = ["person.fill", "person.2.fill", "person.3.fill"]
    
    // 创建类型检查映射
    let typeLabels = ["随机漫游", "每日心情", "历史人物", "创意思考", "时光记录", "未来畅想"]
    
    // 安全索引检查 - 确保索引在有效范围内
    let safeIndex = max(0, min(typeIndex, typeLabels.count - 1))
    if safeIndex != typeIndex {
        print("⚠️ 警告：提供的类型索引 \(typeIndex) 无效，已调整为 \(safeIndex)")
    }
    
    // 确定实际使用的类型名
    let typeLabel = typeLabels[safeIndex]
    print("📱 生成 \(typeLabel) 类型的帖子")
    
    // 创建存储帖子的数组
    var newPosts: [UserPostModel] = []
    
    // 随机确定要生成的帖子数量 - 确保至少生成1篇
    let postCount = Int.random(in: 3...5)
    print("📱 计划生成 \(postCount) 篇帖子")
    
    // 根据不同类型生成不同内容
    switch safeIndex {
    case 0: // 随机漫游
        for i in 0..<postCount {
            // 随机选择用户名和头像
            let characterIndex = Int.random(in: 0..<defaultAvatars.count)
            let characterIDs = ["einstein", "davinci", "shakespeare", "newton", "confucius"]
            let randomNames = ["\(defaultUsername)_\(Int.random(in: 100...999))", "时空旅行者", "次元探索家", "创想织梦师"]
            
            // 生成随机内容
            let randomContent = [
                "在虫洞深处遇见了一片未知的星云，群星闪烁着神秘的光芒，仿佛在诉说着宇宙的秘密...",
                "穿越时空走廊时，看到了无数平行宇宙中的自己，每一个都选择了不同的人生道路...",
                "在量子场的涨落中，偶然捕捉到了思维的波动，那是一种超越语言的交流方式...",
                "次元壁垒在今天变得异常脆弱，让我有机会一窥多元宇宙的真相，那里的物理法则与我们的世界截然不同...",
                "探索虫洞时，发现一个由纯粹意识构成的空间，在那里，思想即是现实，想象即是创造..."
            ]
            
            // 创建新帖子 - 确保每个帖子有唯一ID
            let newPost = UserPostModel(
                id: UUID(),
                username: randomNames.randomElement() ?? defaultUsername,
                userAvatar: defaultAvatars[characterIndex],
                content: randomContent.randomElement() ?? "在虫洞深处发现了奇妙的景象...",
                images: [], // 移除可能不存在的图片引用
                datePosted: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: Bool.random(),
                isBookmarkedByCurrentUser: Bool.random()
            )
            
            // 添加到帖子数组
            newPosts.append(newPost)
            print("📱 成功生成随机漫游帖子 #\(i+1): \(newPost.id)")
        }
        
    case 1: // 每日心情
        for i in 0..<postCount {
            // 随机选择用户名和头像
            let characterIndex = Int.random(in: 0..<defaultAvatars.count)
            let randomNames = ["\(defaultUsername)_\(Int.random(in: 100...999))", "心情记录者", "情绪探索家", "感受收集师"]
            
            // 生成随机内容
            let moodContents = [
                "今天心情格外舒畅，阳光透过云层洒在脸上，温暖而不炙热。沿着河边散步，微风拂过，仿佛所有烦恼都被吹散...",
                "雨天的午后，窗外雨滴敲打着玻璃，室内的灯光显得格外温馨。泡一杯热茶，翻开一本久未阅读的书，时间仿佛静止...",
                "工作中遇到了一些挑战，但每一个障碍都是成长的机会。深呼吸，调整心态，相信明天会更好...",
                "今天与老朋友重聚，回忆如潮水般涌来。时光匆匆，但友情长存。珍惜当下的每一刻，珍惜身边的每一个人...",
                "独自一人看星空，繁星点点，思绪万千。在浩瀚宇宙面前，烦恼显得如此微不足道..."
            ]
            
            // 创建新帖子
            let newPost = UserPostModel(
                id: UUID(),
                username: randomNames.randomElement() ?? "心情记录者",
                userAvatar: defaultAvatars[characterIndex],
                content: moodContents.randomElement() ?? "今天的心情如同天气一般晴朗...",
                images: [], // 移除可能不存在的图片
                datePosted: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: Bool.random(),
                isBookmarkedByCurrentUser: Bool.random()
            )
            
            // 添加到帖子数组
            newPosts.append(newPost)
            print("📱 成功生成每日心情帖子 #\(i+1): \(newPost.id)")
        }
        
    case 2: // 历史人物
        // 历史人物名称
        let historicalFigures = ["爱因斯坦", "达芬奇", "莎士比亚", "牛顿", "孔子"]
        let characterIDs = ["einstein", "davinci", "shakespeare", "newton", "confucius"]
        
        for i in 0..<postCount {
            // 随机选择历史人物
            let characterIndex = Int.random(in: 0..<historicalFigures.count)
            let figureName = historicalFigures[characterIndex]
            
            // 根据不同历史人物生成内容
            var content = ""
            switch figureName {
            case "爱因斯坦":
                content = "与爱因斯坦讨论了相对论的本质。他说：\"时间与空间本身就是相对的，不同参考系下的观察者会测量到不同的时间流逝和空间距离。但物理规律在所有惯性参考系下都是相同的，这是自然的和谐之美。\""
            case "达芬奇":
                content = "跟随达芬奇参观了他的工作室。他向我展示了'维特鲁威人'的设计理念：\"人体的比例反映了宇宙的和谐，这是数学、艺术与自然的完美结合。观察是一切科学和艺术的基础。\""
            case "莎士比亚":
                content = "观看了莎士比亚排练《哈姆雷特》。他对我说：\"文字的力量在于它能唤起人们内心深处的情感。伟大的戏剧不仅讲述故事，更是揭示人性的镜子。生活本身就是舞台，我们都是演员。\""
            case "牛顿":
                content = "拜访了牛顿的实验室。他正在研究光的性质，告诉我：\"自然界的规律是可以用数学语言精确描述的。万有引力不仅支配天体运动，也决定了地球上物体的行为。如果我比别人看得更远，那是因为我站在巨人的肩膀上。\""
            case "孔子":
                content = "与孔子漫步在山间小道，讨论为人处世之道。他语重心长地说：\"学而不思则罔，思而不学则殆。知之者不如好之者，好之者不如乐之者。君子和而不同，小人同而不和。己所不欲，勿施于人。\""
            default:
                content = "与历史人物相遇，交流了许多关于过去与未来的思考..."
            }
            
            // 创建新帖子
            let newPost = UserPostModel(
                id: UUID(),
                username: "\(defaultUsername) 与 \(figureName)",
                userAvatar: defaultAvatars[i % defaultAvatars.count],
                content: content,
                images: [], // 移除可能不存在的图片
                datePosted: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 10...100),
                comments: [],
                isLikedByCurrentUser: Bool.random(),
                isBookmarkedByCurrentUser: Bool.random()
            )
            
            // 添加到帖子数组
            newPosts.append(newPost)
            print("📱 成功生成历史人物帖子 #\(i+1): \(newPost.id)")
        }
        
    case 3: // 创意思考
        for i in 0..<postCount {
            // 随机选择用户名和头像
            let characterIndex = Int.random(in: 0..<defaultAvatars.count)
            let randomNames = ["\(defaultUsername)_\(Int.random(in: 100...999))", "创想织梦师", "思维探险家", "创意收集者"]
            
            // 生成随机内容
            let creativeThoughts = [
                "如果思想可以具象化，会是什么形态？或许是一片无边无际的星空，每颗星星都是一个想法，星座则是思想的连接...",
                "创意来源于连接看似不相关的事物。比如，蒲公英的种子和人类的梦想，都在风中飘散，寻找生根发芽的地方...",
                "音乐是一种无形的建筑，建筑是凝固的音乐。当我们欣赏一座建筑时，其实是在聆听建筑师内心的旋律...",
                "想象我们生活在一个可以随意切换视角的世界：从分子的尺度到宇宙的尺度，从蚂蚁的视角到鹰的视角。这会如何改变我们的思维方式？",
                "时间或许不是线性的，而是像树一样分叉。每个决定点都创造了一个新的分支，无数平行宇宙中存在着无数个不同版本的我们..."
            ]
            
            // 创建新帖子
            let newPost = UserPostModel(
                id: UUID(),
                username: randomNames.randomElement() ?? "创想织梦师",
                userAvatar: defaultAvatars[characterIndex],
                content: creativeThoughts.randomElement() ?? "思考是超越时空的旅行...",
                images: [], // 移除可能不存在的图片
                datePosted: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: Bool.random(),
                isBookmarkedByCurrentUser: Bool.random()
            )
            
            // 添加到帖子数组
            newPosts.append(newPost)
            print("📱 成功生成创意思考帖子 #\(i+1): \(newPost.id)")
        }
        
    default: // 时光记录和其他类型
        for i in 0..<postCount {
            // 随机选择用户名和头像
            let characterIndex = Int.random(in: 0..<defaultAvatars.count)
            let randomNames = ["\(defaultUsername)_\(Int.random(in: 100...999))", "时光收藏家", "记忆导航员", "瞬间捕捉师"]
            
            // 生成随机内容
            let timeRecords = [
                "翻开老相册，看到儿时的照片，恍如隔世。时间如白驹过隙，但记忆却凝固在这些泛黄的照片中...",
                "十年前的今天，我踏上了一段未知的旅程。现在回首，每一步都是必然，每一个选择都铸就了今天的我...",
                "在老家的阁楼上发现了祖父的日记。翻开泛黄的纸页，他的故事如此生动，仿佛穿越时光与他对话...",
                "时间是最公平也是最不公平的东西。它给每个人24小时，却以不同的速度流逝。快乐时，时间如箭；痛苦时，时间如牛...",
                "收到多年未见的朋友来信，字里行间是岁月的痕迹。友情跨越时间的长河，在纸上重新焕发生机..."
            ]
            
            // 创建新帖子
            let newPost = UserPostModel(
                id: UUID(),
                username: randomNames.randomElement() ?? "时光收藏家",
                userAvatar: defaultAvatars[characterIndex],
                content: timeRecords.randomElement() ?? "时间如河，我们是行船者...",
                images: [], // 移除可能不存在的图片
                datePosted: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 5...50),
                comments: [],
                isLikedByCurrentUser: Bool.random(),
                isBookmarkedByCurrentUser: Bool.random()
            )
            
            // 添加到帖子数组
            newPosts.append(newPost)
            print("📱 成功生成时光记录帖子 #\(i+1): \(newPost.id)")
        }
    }
    
    // 检查是否成功生成帖子
    if newPosts.isEmpty {
        print("⚠️ 警告：未能生成任何帖子，使用备用内容")
        
        // 生成一个备用帖子，确保返回非空数组
        let fallbackPost = UserPostModel(
            id: UUID(),
            username: "虫遇探索者",
            userAvatar: "person.fill",
            content: "在虫洞深处发现了奇妙的景象，这里的时空规则与众不同，思维可以具象为现实...",
            images: [],
            datePosted: Date(),
            likes: Int.random(in: 5...20),
            comments: [],
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false
        )
        
        newPosts.append(fallbackPost)

    }
    
    print("📱 generatePostsByCreationType 完成，生成了 \(newPosts.count) 篇帖子")
    
    // 返回生成的帖子数组
    return newPosts
}

/**
 * 生成对评论的回复
 */
func generateResponseToComment(originalComment: UserCommentModel, byFigure responderName: String) -> UserCommentModel {
    let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
    let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
    
    // 提取评论关键内容，不使用引号框住
    let sentences = originalComment.content.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
    let firstSentence = sentences.first ?? ""
    let keywords = originalComment.content.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                    .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都"].contains($0) }
                    .prefix(5)
    
    let responderIndex = historicalFigures.firstIndex(of: responderName) ?? 0
    let responderAvatar = avatarSymbols[responderIndex]
    
    // 分析原始评论的观点和情感倾向
    let commentSentiment = analyzeSentiment(originalComment.content)
    let commentTopic = extractMainTopic(originalComment.content)
    let commentViewpoint = extractViewpoint(originalComment.content)
    
    var responseText = ""
    
    switch responderName {
    case "爱因斯坦":
        if commentSentiment == "positive" {
            if commentTopic.contains("科学") || commentTopic.contains("物理") || commentTopic.contains("理论") {
                responseText = "你对\(commentTopic)的理解很深刻！从相对论的角度看，\(commentViewpoint)确实具有启发性。科学的美妙之处在于不断探索未知，而你的观点为这个讨论增添了新的维度。"
            } else {
                responseText = "你的思考角度很有创意！正如我常说的，想象力比知识更重要。对于\(commentTopic)，我认为\(commentViewpoint)这种视角体现了科学与艺术的完美结合。"
            }
        } else if commentSentiment == "questioning" {
            responseText = "这是个很好的问题！关于\(commentTopic)，你提出的\(commentViewpoint)确实值得深思。在科学探索中，质疑精神至关重要。我思考过类似的问题，发现从不同参考系来分析会得到全新的理解。"
        } else {
            responseText = "你提出的不同视角很有价值。科学进步正是建立在不同见解的碰撞上，关于\(commentTopic)的讨论，\(commentViewpoint)这个角度确实提供了新的思考方向。"
        }
        
    case "莎士比亚":
        if commentSentiment == "positive" {
            responseText = "你的赞赏如诗如画！关于\(commentTopic)的讨论，你的\(commentViewpoint)观点颇具洞见。正如我在作品中探索人性，每一次交流都是灵魂的对话，感谢你的精彩见解。"
        } else if commentSentiment == "questioning" {
            responseText = ""存在还是毁灭，这是个问题"，而你关于\(commentTopic)的疑问同样深刻。\(commentViewpoint)这一思考确实触及本质，值得我们用戏剧性的眼光去探寻更深层次的答案。"
        } else {
            responseText = "不同的声音构成生活的戏剧！你对\(commentTopic)的看法，尤其是\(commentViewpoint)这一点，展示了另一种解读的可能。正如我笔下的角色，每个视角都有其存在的价值。"
        }
        
    case "达芬奇":
        if commentSentiment == "positive" {
            responseText = "你的观察力令人赞叹！对\(commentTopic)的分析，特别是\(commentViewpoint)这一点，体现了艺术家的敏锐与科学家的精确。正如我在绘画中追求的，细节中往往蕴含真理。"
        } else if commentSentiment == "questioning" {
            responseText = "好奇心是最伟大的品质！你对\(commentTopic)提出的疑问，尤其是关于\(commentViewpoint)的思考，让我想起我在解剖研究中的发现——通过质疑常识，我们才能接近真相。"
        } else {
            responseText = "多元视角共同构成完整认知！关于\(commentTopic)，你提出的\(commentViewpoint)观点虽与我所想不同，却如同画作中的阴影与光线，共同构成了立体的理解。"
        }
        
    case "孔子":
        if commentSentiment == "positive" {
            responseText = "君子言，礼义行。你对\(commentTopic)的见解，尤其是\(commentViewpoint)这一点，体现了深刻的思考。正所谓"三人行，必有我师焉"，你的观点让我也受益良多。"
        } else if commentSentiment == "questioning" {
            responseText = "学而不思则罔，思而不学则殆。你对\(commentTopic)提出的疑问，特别是关于\(commentViewpoint)的思考，正是求知路上必经之思。唯有如此，才能达到内外兼修的境界。"
        } else {
            responseText = "君子和而不同，小人同而不和。对于\(commentTopic)，你提出的\(commentViewpoint)观点虽与众不同，但正是这种不同才使讨论更加充实。道并行而不相悖，理虽分而能相通。"
        }
        
    case "牛顿":
        if commentSentiment == "positive" {
            responseText = "你的分析非常精准！关于\(commentTopic)的见解，尤其是\(commentViewpoint)这一点，展现了严谨的思维方式。正如万有引力定律所示，规律往往隐藏在表象之下，而你敏锐地捕捉到了这一点。"
        } else if commentSentiment == "questioning" {
            responseText = "质疑是科学进步的动力！你对\(commentTopic)提出的问题，特别是关于\(commentViewpoint)的思考，让我想起在研究光学时的困惑。通过不断提问，我们才能接近真理。"
        } else {
            responseText = "科学需要不同声音！关于\(commentTopic)，你提出的\(commentViewpoint)观点提供了全新的视角。正如我所言，我们站在巨人的肩膀上前行，而不同观点正是这前行的基石。"
        }
        
    case "李白":
        if commentSentiment == "positive" {
            responseText = "你的见解如清风明月，令人陶醉！论\(commentTopic)，你对\(commentViewpoint)的感悟堪比佳酿，令人回味无穷。人生得意须尽欢，与知音对饮论道，夫复何求？"
        } else if commentSentiment == "questioning" {
            responseText = "人生如逆旅，我亦是行人。你对\(commentTopic)的困惑，尤其是\(commentViewpoint)这一点，如同我对星空的好奇。世间万物皆有疑，唯有畅饮后的诗篇才能表达内心真实的探寻。"
        } else {
            responseText = "青莲居士不拘一格！对于\(commentTopic)，你的\(commentViewpoint)观点虽与我不同，却如高山流水，各有韵味。天地为酒壶，诗酒趁年华，百家争鸣方显思想之辉煌！"
        }
        
    default:
        responseText = "感谢你分享关于\(commentTopic)的见解。\(commentViewpoint)这个观点很有深度，让我从新的角度思考这个问题。期待能继续这样的交流。"
    }
    
    // 随机添加个人化细节（30%几率）
    if Double.random(in: 0...1) > 0.7 {
        let personalTouches = [
            responderName == "爱因斯坦" ? "这让我想起在普林斯顿时与同事们的讨论。" : "",
            responderName == "莎士比亚" ? "这种感悟正是我创作时追求的灵感源泉。" : "",
            responderName == "达芬奇" ? "我的笔记中记录了很多类似的思考。" : "",
            responderName == "孔子" ? "与弟子论学时，我常强调这一点。" : "",
            responderName == "牛顿" ? "在剑桥的研究中，这种思路很有价值。" : "",
            responderName == "李白" ? "在泰山之巅，我曾有类似的感悟。" : ""
        ].filter { !$0.isEmpty }
        
        if !personalTouches.isEmpty {
            responseText += " " + personalTouches.randomElement()!
        }
    }
    
    // 随机添加结尾（20%几率）
    if Double.random(in: 0...1) > 0.8 {
        let endings = ["继续分享你的想法。", "很高兴能有这样的交流。", "这些讨论很有启发性。", "期待看到更多你的思考。"]
        responseText += " " + endings[Int.random(in: 0..<endings.count)]
    }
    
    // 随机添加表情符号（25%几率）
    if Double.random(in: 0...1) > 0.75 {
        let emojis = ["🤔", "💭", "✨", "👏", "🧠", "🔍", "📚", "🌟"]
        responseText += " " + emojis.randomElement()!
    }
    
    // 将非可选类型转换为可选类型
    let characterIDValue: String? = responderName.lowercased()
    
    return UserCommentModel(
        username: responderName,
        userAvatar: responderAvatar,
        content: responseText,
        datePosted: Date().addingTimeInterval(-Double.random(in: 0...1800)),
        likes: Int.random(in: 3...30),
        isVirtualCharacter: true,
        characterID: characterIDValue,
        parentCommentId: originalComment.id,
        replyToUsername: originalComment.username
    )
}

/**
 * 分析评论的情感倾向
 * @param comment 评论内容
 * @return 情感类型
 */
private func analyzeSentiment(_ comment: String) -> String {
    let lowerComment = comment.lowercased()
    
    // 积极评论检测
    let positiveKeywords = ["喜欢", "赞同", "感谢", "有道理", "学到了", "启发", "有趣", "精彩", "好", "棒", "支持", "佩服"]
    if positiveKeywords.contains(where: { lowerComment.contains($0) }) {
        return "positive"
    }
    
    // 质疑评论检测
    let questioningKeywords = ["为什么", "怎么", "如何", "是否", "真的吗", "不理解", "疑问", "不确定", "?", "？"]
    if questioningKeywords.contains(where: { lowerComment.contains($0) }) {
        return "questioning"
    }
    
    // 反对评论检测
    let negativeKeywords = ["不同意", "错误", "不对", "反对", "不赞同", "有问题", "不准确", "不是", "并非"]
    if negativeKeywords.contains(where: { lowerComment.contains($0) }) {
        return "negative"
    }
    
    return "neutral"
}

/**
 * 提取评论中的主要话题
 * @param comment 评论内容
 * @return 主题
 */
private func extractMainTopic(_ comment: String) -> String {
    // 提取关键词作为话题
    let keywords = comment.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                   .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都"].contains($0) }
    
    // 常见话题分类
    let topicCategories = [
        "科学": ["科学", "物理", "化学", "理论", "研究", "实验", "发现", "宇宙", "相对论", "量子", "能量"],
        "艺术": ["艺术", "创作", "文学", "诗歌", "戏剧", "绘画", "美学", "表达", "灵感", "想象"],
        "哲学": ["哲学", "思考", "智慧", "道德", "伦理", "存在", "意义", "价值", "本质"],
        "社会": ["社会", "人际", "关系", "交流", "互动", "群体", "文化", "传统"],
        "教育": ["教育", "学习", "知识", "教学", "学术", "研究", "思维"]
    ]
    
    // 检查关键词是否属于某个话题分类
    for keyword in keywords {
        for (topic, relatedWords) in topicCategories {
            if relatedWords.contains(where: { keyword.contains($0) }) {
                return topic
            }
        }
    }
    
    // 如果没有匹配到特定话题，返回第一个关键词或默认话题
    return keywords.first ?? "这个话题"
}

/**
 * 提取评论中的观点
 * @param comment 评论内容
 * @return 观点
 */
private func extractViewpoint(_ comment: String) -> String {
    // 分割句子
    let sentences = comment.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
    
    // 如果有多个句子，选择包含关键观点词的句子
    let viewpointIndicators = ["认为", "觉得", "思考", "看法", "观点", "角度", "理解", "感受"]
    
    for sentence in sentences {
        if viewpointIndicators.contains(where: { sentence.contains($0) }) {
            return sentence
        }
    }
    
    // 如果没有明显的观点指示词，返回第一个句子
    return sentences.first ?? "你提到的观点"
}

/**
 * 增强版用户意图分析
 * 比简单情感分析更深入，能识别用户的具体意图
 * @param content 评论内容
 * @return 用户意图枚举
 */
private enum UserIntent {
    case seeking(information: String)    // 寻求信息
    case expressing(opinion: String)     // 表达观点
    case challenging(viewpoint: String)  // 质疑观点
    case agreeing(with: String)          // 表示同意
    case sharing(experience: String)     // 分享经历
    case questioning                     // 提出疑问
    case unknown                         // 未知意图
    
    var description: String {
        switch self {
        case .seeking(let info):
            return "寻求关于\(info)的信息"
        case .expressing(let opinion):
            return "表达关于\(opinion)的观点"
        case .challenging(let viewpoint):
            return "质疑\(viewpoint)的观点"
        case .agreeing(let with):
            return "同意关于\(with)的观点"
        case .sharing(let experience):
            return "分享关于\(experience)的经历"
        case .questioning:
            return "提出疑问"
        case .unknown:
            return "未知意图"
        }
    }
}

/**
 * 增强版用户意图分析
 * @param content 评论内容
 * @return 用户意图
 */
private func analyzeUserIntent(_ content: String) -> UserIntent {
    // 提取评论的关键主题
    let topic = extractMainTopic(content)
    let viewpoint = extractViewpoint(content)
    let lowerContent = content.lowercased()
    
    // 问题标记
    if content.contains("?") || content.contains("？") || 
       content.contains("为什么") || content.contains("如何") || 
       content.contains("是否") || content.contains("怎么") || 
       content.contains("请问") || content.contains("能否") {
        
        // 确定问题是信息寻求还是质疑
        if content.contains("不同意") || content.contains("不对") || content.contains("错误") {
            return .challenging(viewpoint: viewpoint)
        }
        return .seeking(information: topic)
    }
    
    // 分享个人经历标记
    if content.contains("我曾经") || content.contains("我经历") || 
       content.contains("我遇到") || content.contains("我的经历") ||
       content.contains("我以前") || content.contains("我有一次") {
        return .sharing(experience: topic)
    }
    
    // 表达观点标记
    if content.contains("我觉得") || content.contains("我认为") || 
       content.contains("我想") || content.contains("我的看法") ||
       content.contains("我相信") || content.contains("在我看来") {
        return .expressing(opinion: viewpoint)
    }
    
    // 挑战/不同意标记
    if content.contains("不同意") || content.contains("不对") || 
       content.contains("错误") || content.contains("有问题") ||
       content.contains("不准确") || content.contains("不正确") ||
       content.contains("不是这样") {
        return .challenging(viewpoint: viewpoint)
    }
    
    // 同意标记
    if content.contains("赞同") || content.contains("同意") || 
       content.contains("有道理") || content.contains("说得好") ||
       content.contains("没错") || content.contains("很对") ||
       content.contains("支持") {
        return .agreeing(with: topic)
    }
    
    // 根据内容长度和复杂度猜测意图
    let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    if words.count <= 5 {
        // 短句可能是简单的同意或疑问
        return content.contains("吗") || content.contains("呢") ? .questioning : .unknown
    } else {
        // 默认为表达观点
        return .expressing(opinion: viewpoint)
    }
}

/**
 * 增强版观点提取函数
 * 更智能地从评论中提取核心观点
 * @param comment 评论内容
 * @return 提取的观点
 */
private func extractEnhancedViewpoint(_ comment: String) -> String {
    // 分割句子
    let sentences = comment.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
    
    // 常见观点引导词
    let viewpointIndicators = [
        "认为", "觉得", "思考", "看法", "观点", "角度", "理解", "感受", 
        "想法", "意见", "判断", "推测", "相信", "坚持", "主张"
    ]
    
    // 1. 查找包含观点指示词的句子
    for sentence in sentences {
        if viewpointIndicators.contains(where: { sentence.contains($0) }) {
            // 尝试提取"我认为..."或"我觉得..."后面的内容
            if let range = sentence.range(of: "认为") ?? 
                           sentence.range(of: "觉得") ?? 
                           sentence.range(of: "相信") {
                let viewpoint = String(sentence[range.upperBound...])
                if !viewpoint.isEmpty {
                    return viewpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return sentence
        }
    }
    
    // 2. 寻找最有代表性的句子（通常是最长或中间的句子）
    if !sentences.isEmpty {
        // 如果有多个句子，选择最长的一个，通常包含更多信息
        if sentences.count > 1 {
            let longestSentence = sentences.max(by: { $0.count < $1.count })!
            return longestSentence
        }
        
        // 只有一个句子，直接返回
        return sentences[0]
    }
    
    // 3. 如果没有找到合适的句子，返回整个评论的前部分
    let shortenedComment = String(comment.prefix(50))
    return shortenedComment.isEmpty ? "该评论" : shortenedComment
}

/**
 * 增强版主题提取函数
 * 更准确地识别评论中的核心主题
 * @param comment 评论内容
 * @return 主题
 */
private func extractEnhancedTopic(_ comment: String) -> String {
    // 提取关键词
    let keywords = comment.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                   .filter { $0.count >= 2 && !["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "也", "你", "这", "那", "他", "她", "它", "们", "个", "很", "为", "吗", "呢", "啊", "哦", "嗯"].contains($0) }
    
    // 扩展的常见主题词库
    let topicCategories: [String: [String]] = [
        "科学技术": ["科学", "技术", "物理", "化学", "理论", "研究", "实验", "发现", "宇宙", "相对论", "量子", "能量", "电子", "原子", "数据", "互联网", "编程", "算法", "人工智能", "机器学习"],
        
        "艺术创作": ["艺术", "创作", "文学", "诗歌", "戏剧", "绘画", "美学", "表达", "灵感", "想象", "色彩", "构图", "音乐", "旋律", "文化", "创意", "审美", "设计"],
        
        "哲学思考": ["哲学", "思考", "智慧", "道德", "伦理", "存在", "意义", "价值", "本质", "真理", "理性", "辩证", "逻辑", "思想", "认知", "意识", "形而上学", "本体论", "知识论"],
        
        "社会人文": ["社会", "人际", "关系", "交流", "互动", "群体", "文化", "传统", "历史", "政治", "经济", "教育", "媒体", "传播", "沟通", "合作", "竞争", "权力", "制度"],
        
        "心理情感": ["心理", "情感", "情绪", "感受", "压力", "焦虑", "快乐", "幸福", "愤怒", "恐惧", "爱", "恨", "希望", "失望", "孤独", "沮丧", "兴奋", "平静"],
        
        "自然环境": ["自然", "环境", "生态", "动物", "植物", "气候", "天气", "季节", "山", "水", "森林", "海洋", "天空", "地球", "宇宙", "星球", "风景", "保护"]
    ]
    
    // 检查关键词是否属于某个主题分类
    var topicScores: [String: Int] = [:]
    
    for keyword in keywords {
        for (topic, relatedWords) in topicCategories {
            if relatedWords.contains(where: { keyword.contains($0) }) {
                topicScores[topic] = (topicScores[topic] ?? 0) + 1
            }
        }
    }
    
    // 找出得分最高的主题
    if let (topTopic, _) = topicScores.max(by: { $0.value < $1.value }) {
        return topTopic
    }
    
    // 如果没有匹配到特定主题，返回第一个有意义的关键词或默认主题
    return keywords.first ?? "这个话题"
}

/**
 * 生成虚拟角色对评论回复的回应
 * 当用户回复了一条评论时，原帖作者（虚拟角色）对这个回复的回应
 * @param originalReply 用户的回复
 * @param originalComment 原始评论
 * @param authorName 原帖作者名称
 * @return 生成的回应评论
 */
func generateResponseToCommentReply(originalReply: UserCommentModel, originalComment: UserCommentModel, authorName: String) -> UserCommentModel {
    let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
    let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
    
    // 提取回复内容的关键信息
    let replyContent = originalReply.content
    let replyAuthor = originalReply.username
    
    // 分析回复的情感倾向和观点
    let replySentiment = analyzeSentiment(replyContent)
    let replyTopic = extractMainTopic(replyContent)
    let replyViewpoint = extractViewpoint(replyContent)
    
    // 提取原评论内容的关键信息，用于提供上下文
    let commentContent = originalComment.content
    let commentAuthor = originalComment.username
    
    // 获取原帖作者的头像
    let authorIndex = historicalFigures.firstIndex(of: authorName) ?? 0
    let authorAvatar = avatarSymbols[authorIndex]
    
    // 构建回复内容
    var responseText = ""
    
    // 根据不同历史人物和回复情感生成不同风格的回应
    switch authorName {
    case "爱因斯坦":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = "很高兴看到你与\(commentAuthor)的讨论！关于\(replyTopic)，你提出的\(replyViewpoint)确实很有见地。从相对性的角度看，不同观察者对同一现象可能有不同理解，这正是思想交流的魅力所在。"
            } else if replySentiment == "questioning" {
                responseText = "你对\(commentAuthor)评论的疑问很有价值！\(replyViewpoint)这个问题让我想起研究中常遇到的困惑。科学进步正是建立在这种持续质疑的基础上，期待看到你们的讨论能碰撞出更多火花。"
            } else if replySentiment == "negative" {
                responseText = "看到你和\(commentAuthor)有不同观点，这很有启发性。\(replyViewpoint)提供了新的思考角度，正如我常说：'评判一个观点的价值不在于它是否令人舒适，而在于它能否促使思考。'感谢你的参与！"
            } else {
                responseText = "看到你回复了\(commentAuthor)的评论，这种交流很有意义。关于\(replyTopic)的讨论，正如我研究相对论时发现的，多元视角能让我们更接近真相。"
            }
        } else {
            // 历史人物回复
            responseText = "很高兴看到\(replyAuthor)加入讨论！你们对\(replyTopic)的探讨令我想起了与玻尔的思想实验辩论。科学和哲学的边界常常因这样的交流而被推进，这正是思想共鸣的魅力所在。"
        }
        
    case "莎士比亚":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = ""一千个读者眼中有一千个哈姆雷特"，你与\(commentAuthor)的精彩对话正印证了这点！你对\(replyViewpoint)的赞赏，如同剧中人物的生动对白，为这出思想的戏剧增添了层次。"
            } else if replySentiment == "questioning" {
                responseText = "你对\(commentAuthor)提出的问题饶有深意，正如哈姆雷特的独白引人深思。\(replyViewpoint)这一疑问触及了\(replyTopic)的本质，让我想起《暴风雨》中普洛斯彼罗的困惑——'我们所有人都是梦的素材所构成'。"
            } else if replySentiment == "negative" {
                responseText = "不同声音构成了戏剧的冲突与张力！你与\(commentAuthor)关于\(replyTopic)的分歧，恰如《罗密欧与朱丽叶》中两大家族的对立。然而正是这种碰撞，才诞生出最动人的故事情节。"
            } else {
                responseText = "你与\(commentAuthor)的对话如同我笔下角色的精彩互动。每一次思想的交流，都是灵魂深处的共鸣。正如我在《十四行诗》中所写：'思想的火花，点亮心灵的黑夜'。"
            }
        } else {
            // 历史人物回复
            responseText = "看到\(replyAuthor)加入我们的对话，真是妙不可言！这场关于\(replyTopic)的思想盛宴，正如舞台上多幕剧的展开，每位角色的加入都为故事增添新的维度。'全世界是一个舞台，所有男男女女不过是演员。'"
        }
        
    case "达芬奇":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = "你对\(commentAuthor)评论的欣赏之情，如同我观察光影变化的细腻感受。\(replyViewpoint)这一见解展现了你对\(replyTopic)的独特理解，正如一幅画作需要从不同角度欣赏才能领略其全貌。"
            } else if replySentiment == "questioning" {
                responseText = "你提出的问题富有探索精神！对\(commentAuthor)关于\(replyTopic)的见解产生疑问，正是求知之路的开始。正如我研究解剖学时常自问：'表象之下隐藏着怎样的奥秘？'继续保持这种好奇心。"
            } else if replySentiment == "negative" {
                responseText = "不同观点如同画作中的明暗对比，缺一不可。你与\(commentAuthor)对\(replyTopic)的不同见解，恰似我绘制《最后的晚餐》时对光影的处理——正是这种对比，才能凸显主题的深度。"
            } else {
                responseText = "你对\(commentAuthor)评论的回应让我想起创作时的思考过程。观察是知识的源泉，而交流则是智慧的催化剂。关于\(replyTopic)的讨论，正需要这样深入的互动。"
            }
        } else {
            // 历史人物回复
            responseText = "很高兴看到\(replyAuthor)提出了新的见解！这场关于\(replyTopic)的思想交流，正如我设计的多层次素描——每一笔都赋予作品新的深度。艺术与科学的交汇处，往往诞生最闪耀的灵感。"
        }
        
    case "孔子":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = "子曰：'三人行，必有我师焉。'你对\(commentAuthor)评论的赞同之情，展现了谦逊好学的态度。关于\(replyTopic)，你提出的\(replyViewpoint)确有见地，正所谓'见贤思齐'也。"
            } else if replySentiment == "questioning" {
                responseText = "善问者如攻坚木，固难入而行有所得。你对\(commentAuthor)关于\(replyTopic)的质疑，体现了求真求实的精神。学而不思则罔，思而不学则殆，唯有如此才能达到'知之为知之，不知为不知'的境界。"
            } else if replySentiment == "negative" {
                responseText = "君子和而不同，小人同而不和。你与\(commentAuthor)对\(replyTopic)持不同见解，却能文明讨论，正是修身齐家治国平天下的基础。正所谓'己所不欲，勿施于人'，相互尊重方能共同进步。"
            } else {
                responseText = "与\(commentAuthor)的一番交流，想必让你有所感悟。关于\(replyTopic)的思考，犹如为学之道，贵在持之以恒。温故而知新，可以为师矣。"
            }
        } else {
            // 历史人物回复
            responseText = "得见\(replyAuthor)参与讨论，甚感欣慰。这场关于\(replyTopic)的思想碰撞，正如吾与弟子论学，教学相长。诚如吾言：'文质彬彬，然后君子。'此等交流，正是修己以安人之道也。"
        }
        
    case "牛顿":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = "你对\(commentAuthor)关于\(replyTopic)的认同，体现了对知识的尊重。正如我研究光学时发现，不同波长的光汇聚在一起，才能形成完整的白光。你的\(replyViewpoint)见解，为讨论增添了新的维度。"
            } else if replySentiment == "questioning" {
                responseText = "你提出的问题令人深思！对\(commentAuthor)关于\(replyTopic)的见解产生疑问，正是科学精神的体现。我曾说过：'如果我看得更远，是因为我站在巨人的肩膀上。'而提出好问题，正是站得更高的第一步。"
            } else if replySentiment == "negative" {
                responseText = "对于\(replyTopic)，你与\(commentAuthor)有不同看法，这正如我与胡克在光学理论上的分歧。但正是这种思想的碰撞，推动了科学的进步。每个作用力都有一个大小相等、方向相反的反作用力，不同观点的交锋也是如此。"
            } else {
                responseText = "你回应\(commentAuthor)的方式很有条理，这让我想起自己研究时的严谨态度。关于\(replyTopic)的讨论，需要不断深入探索，就像解开自然界的奥秘一样，循序渐进、不断求证。"
            }
        } else {
            // 历史人物回复
            responseText = "很高兴看到\(replyAuthor)加入讨论！这场关于\(replyTopic)的思想交流，犹如不同力的相互作用，产生了新的动力和方向。科学的进步正是建立在这种集体智慧的基础上，正如我所言：'真理存在于深处，需要共同探索。'"
        }
        
    case "李白":
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            // 用户回复
            if replySentiment == "positive" {
                responseText = "你与\(commentAuthor)的交流如高山流水，意气相投！对\(replyTopic)的见解，犹如明月照大江，清风拂山岗，令人心旷神怡。人生得意须尽欢，这般知音难寻，何不痛饮一杯？"
            } else if replySentiment == "questioning" {
                responseText = "你的疑问如青山隐于白云中，若隐若现，令人遐思！对\(commentAuthor)关于\(replyTopic)的思考，提出如此灵动的询问，正如我面对浩瀚星空时的困惑——'身登青天揽明月，却问姮娥是与非'。"
            } else if replySentiment == "negative" {
                responseText = "你与\(commentAuthor)对\(replyTopic)的不同看法，如同高山与流水，刚柔并济。'仰天大笑出门去，我辈岂是蓬蒿人'，正是这种敢于表达、不拘一格的精神，才能成就不朽诗篇！"
            } else {
                responseText = "读你与\(commentAuthor)的对话，如品一壶清酒，令人陶醉。关于\(replyTopic)的讨论，让我想起'飞流直下三千尺，疑是银河落九天'的壮观景象，思绪如泉涌，意境如画展。"
            }
        } else {
            // 历史人物回复
            responseText = "哈哈，\(replyAuthor)也来了！这场关于\(replyTopic)的论道，愈发精彩！'相逢何必曾相识，满座尽是知心人'。举杯邀明月，对影成三人，让我们在思想的长河中，共醉这千古风流！"
        }
        
    default:
        if originalReply.username == "当前用户" || !historicalFigures.contains(originalReply.username) {
            responseText = "感谢你回复了\(commentAuthor)的评论！关于\(replyTopic)的讨论，你提出的\(replyViewpoint)很有见地。不同思想的交流，总能产生意想不到的火花。"
        } else {
            responseText = "很高兴看到\(replyAuthor)加入我们的讨论！这场关于\(replyTopic)的思想交流，因为更多智慧的加入而变得更加丰富多彩。"
        }
    }
    
    // 随机添加表情符号（20%几率）
    if Double.random(in: 0...1) > 0.8 {
        let emojis = ["🤔", "💭", "✨", "👏", "🧠", "🔍", "📚", "🌟", "🙏", "😊"]
        responseText += " " + emojis.randomElement()!
    }
    
    // 将非可选类型转换为可选类型
    let characterIDValue: String? = authorName.lowercased()
    
    return UserCommentModel(
        username: authorName,
        userAvatar: authorAvatar,
        content: responseText,
        datePosted: Date().addingTimeInterval(-Double.random(in: 0...1200)),
        likes: Int.random(in: 2...25),
        isVirtualCharacter: true,
        characterID: characterIDValue,
        parentCommentId: originalReply.id,
        replyToUsername: originalReply.username
    )
} 

/**
 * 角色特性模型
 * 存储和管理虚拟角色的性格特点、表达风格等信息
 */
private class CharacterTraitsModel {
    // 角色特性映射
    private let characterTraits: [String: CharacterTraits] = [
        "爱因斯坦": CharacterTraits(
            personality: ["好奇", "幽默", "反传统", "富有想象力", "偶尔健忘"],
            background: "物理学革命者，相对论创立者，原子能研究先驱",
            expressionStyle: ["使用科学隐喻", "提出思想实验", "简化复杂概念", "偶尔自嘲"],
            personalTouches: [
                "这让我想起在普林斯顿时与同事们的讨论。",
                "我常对波尔说，上帝不掷骰子。",
                "像我这样的老头子有时会把问题想得太复杂。",
                "研究物理学让我明白，越是简单的东西蕴含的真理越深刻。"
            ]
        ),
        
        "莎士比亚": CharacterTraits(
            personality: ["浪漫", "戏剧性", "洞察人性", "幽默", "多愁善感"],
            background: "伟大的剧作家、诗人，英国文学的巅峰代表",
            expressionStyle: ["使用戏剧化语言", "引用经典台词", "比喻丰富", "善用对比"],
            personalTouches: [
                "这让我想起《哈姆雷特》中的一幕。",
                "如我在十四行诗中写道，爱情不会因障碍而改变。",
                "人生如戏，我们都是舞台上的演员。",
                "我创作时总是先感受角色的灵魂，才能让笔下的人物鲜活起来。"
            ]
        ),
        
        "达芬奇": CharacterTraits(
            personality: ["全能", "好奇", "细致", "观察力敏锐", "追求完美"],
            background: "文艺复兴时期的艺术家、发明家、科学家，全能的天才",
            expressionStyle: ["结合艺术与科学", "描述细节", "多角度思考", "提问自然"],
            personalTouches: [
                "我的笔记本上画满了类似的观察和设计。",
                "这让我想起在佛罗伦萨时研究自然光影的日子。",
                "艺术与科学从来不是对立的，它们是观察世界的两种方式。",
                "在米兰时，我常花整夜研究人体解剖和机械设计。"
            ]
        ),
        
        "孔子": CharacterTraits(
            personality: ["智慧", "礼仪", "平和", "尊重传统", "重视教育"],
            background: "中国古代思想家、教育家，儒家学派创始人",
            expressionStyle: ["引用古语", "简短精炼", "比喻教学", "谦逊礼貌"],
            personalTouches: [
                "吾与弟子论学时，常言此理。",
                "君子不器，不可拘泥于一隅。",
                "学而时习之，不亦说乎？思考这个问题让我感到喜悦。",
                "吾日三省吾身，对此事仍有思考不足之处。"
            ]
        ),
        
        "牛顿": CharacterTraits(
            personality: ["严谨", "固执", "深思熟虑", "不善社交", "追求真理"],
            background: "物理学和数学革命者，万有引力发现者，微积分创立者",
            expressionStyle: ["精确论证", "强调逻辑", "引用实验证据", "系统性思考"],
            personalTouches: [
                "这让我想起剑桥时期的研究。",
                "如同苹果落地启发我思考引力一样，有时灵感来源于日常。",
                "我站在巨人的肩膀上，才能看得更远。",
                "在光学实验中，我也观察到类似的现象。"
            ]
        ),
        
        "李白": CharacterTraits(
            personality: ["浪漫", "豪放", "热爱自然", "追求自由", "乐观豁达"],
            background: "唐代伟大诗人，被誉为'诗仙'，以豪放飘逸的诗风著称",
            expressionStyle: ["诗意比喻", "华丽词藻", "自然意象", "情感丰富"],
            personalTouches: [
                "此情此景，让我想起蜀道之行。",
                "饮酒赋诗之时，常有如此感悟。",
                "黄河之水天上来，人生之变亦如此壮观。",
                "曾与高朋把酒论此，笑谈至天明。"
            ]
        )
    ]
    
    /**
     * 获取角色特性
     * @param character 角色名称
     * @return 角色特性
     */
    func getTraits(for character: String) -> CharacterTraits {
        return characterTraits[character] ?? CharacterTraits.default
    }
    
    /**
     * 获取角色回应模板
     * @param character 角色名称
     * @param sentiment 情感类型
     * @return 回应模板数组
     */
    func getResponseTemplates(for character: String, sentiment: String) -> [String] {
        // 通用模板
        let defaultTemplates = [
            "你的观点很有见地，让我从新角度思考了{viewpoint}这个问题。",
            "关于{viewpoint}，你的思考很有深度。这让我想到了一些新的可能性。",
            "我很欣赏你对{viewpoint}的见解，这确实值得我们深入探讨。"
        ]
        
        // 根据角色和情感获取特定模板
        switch character {
        case "爱因斯坦":
            switch sentiment {
            case "positive":
                return [
                    "你对{viewpoint}的理解让我印象深刻！这让我想起相对论中的一个重要概念：参考系的选择会改变我们观察事物的方式。",
                    "我完全赞同你关于{viewpoint}的观点！知识需要想象力的点缀，而你的思考正展示了这种创造性。",
                    "你的见解太棒了！关于{viewpoint}，我一直认为好奇心是最强大的动力，而你的思考充满了探索精神。"
                ]
            case "questioning":
                return [
                    "你提出了一个绝妙的问题！关于{viewpoint}，我们确实需要跳出常规思维。想象一下，如果我们以光速思考这个问题...",
                    "这个问题很有深度。{viewpoint}让我想起当年与玻尔的辩论，有时看似矛盾的观点其实是同一现实的不同侧面。",
                    "你的疑问触及了{viewpoint}的本质。科学不是关于确定性，而是关于探索的过程，你的问题正是这种探索精神的体现。"
                ]
            case "negative":
                return [
                    "你的不同看法很有价值！关于{viewpoint}，我自己的理论也曾面临许多质疑，正是这些挑战让科学进步。",
                    "有趣的视角！我曾说过'如果你从未犯错，那么你从未尝试过新事物'，对{viewpoint}的不同理解正是思想进步的源泉。",
                    "你的反对观点很有启发性。{viewpoint}确实可以从多个角度理解，正如量子力学教会我们的，有时多种看似矛盾的解释可以同时成立。"
                ]
            default:
                return [
                    "关于{viewpoint}，我认为最重要的是保持开放的思想。正如我经常说的，重要的不是知道所有答案，而是保持提问的能力。",
                    "思考{viewpoint}这个话题时，我想起一个思想实验：如果我们改变基本假设，结论会如何变化？这种思考方式常常带来意外的发现。",
                    "对{viewpoint}的探讨让我很感兴趣。我一生都在寻找简单而统一的解释，而这类对话常常能启发新的思路。"
                ]
            }
            
        case "莎士比亚":
            switch sentiment {
            case "positive":
                return [
                    "你对{viewpoint}的赞赏如同夏日的清风，令人心旷神怡！正如我在戏剧中探索的，人性的光辉往往在细微处闪耀。",
                    ""哦，多么美妙的新世界啊！"你关于{viewpoint}的见解让我想起《暴风雨》中的米兰达，初见世界时的惊叹与喜悦。",
                    "你的思考如同精心编织的十四行诗，层次分明却又浑然一体。{viewpoint}在你的阐述下展现出全新的魅力。"
                ]
            case "questioning":
                return [
                    ""存在还是不存在"，你对{viewpoint}的质疑触及了深层次的问题，正如哈姆雷特面对生存的困惑，这是思考的开始。",
                    "你的提问如同戏剧中的转折点，让{viewpoint}这个主题呈现出新的维度。正如我常写的，有时问题本身比答案更有价值。",
                    "多么深刻的疑问啊！关于{viewpoint}，就像《李尔王》中所探讨的那样，表象之下往往隐藏着更深层次的真相。"
                ]
            case "negative":
                return [
                    "你的不同见解让这场对话如同精彩的戏剧冲突！关于{viewpoint}，正如罗密欧与朱丽叶的世界，矛盾往往催生出最动人的故事。",
                    "啊，何等有力的反驳！{viewpoint}确实可以从不同角度解读，就像我笔下的人物，每个人都有自己的真相和立场。",
                    "你的反对意见如奥赛罗的嫉妒一般强烈而鲜明！然而，正是这种激烈的碰撞，让{viewpoint}这个话题变得更加立体。"
                ]
            default:
                return [
                    "关于{viewpoint}，我想引用《如你所愿》中的话：'全世界是一个舞台，所有男男女女不过是演员。'我们各自扮演着自己的角色，共同演绎着这出人生大戏。",
                    "{viewpoint}这个话题如同我笔下的角色，有着多重性格和可能性。正如我在创作时常思考的，人性的复杂性正是其美丽所在。",
                    "你提到的{viewpoint}让我想起笔下的无数人物，他们的喜怒哀乐、矛盾挣扎，不正是我们每个人内心的映照吗？"
                ]
            }
            
        // 其他角色的模板可以类似实现
        default:
            return defaultTemplates
        }
    }
}

/**
 * 角色特性结构体
 */
private struct CharacterTraits {
    let personality: [String]        // 性格特点
    let background: String          // 背景描述
    let expressionStyle: [String]    // 表达风格
    let personalTouches: [String]    // 个人特色表达
    
    static let `default` = CharacterTraits(
        personality: ["智慧", "有深度", "思想开放"],
        background: "历史人物",
        expressionStyle: ["清晰", "有见地", "温和"],
        personalTouches: [
            "这个话题很有意思。",
            "你的想法让我有了新的思考。",
            "这确实是个值得讨论的问题。"
        ]
    )
}

/**
 * 增强型回复生成器
 * 基于用户意图和角色特性生成更自然的回复
 * @param originalComment 原始评论
 * @param responderName 回复者名称
 * @return 生成的回复
 */
func generateEnhancedResponse(to originalComment: UserCommentModel, by responderName: String) -> UserCommentModel {
    let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
    let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
    
    // 获取回复者头像
    let responderIndex = historicalFigures.firstIndex(of: responderName) ?? 0
    let responderAvatar = avatarSymbols[responderIndex]
    
    // 1. 分析评论内容
    let userSentiment = analyzeSentiment(originalComment.content)
    let userIntent = analyzeUserIntent(originalComment.content)
    let topic = extractEnhancedTopic(originalComment.content)
    let viewpoint = extractEnhancedViewpoint(originalComment.content)
    
    // 2. 获取角色特性
    let characterTraits = CharacterTraitsModel().getTraits(for: responderName)
    
    // 3. 获取回应模板
    let responseTemplates = CharacterTraitsModel().getResponseTemplates(
        for: responderName,
        sentiment: userSentiment
    )
    
    // 4. 构建回复内容
    var responseContent = responseTemplates.randomElement() ?? 
                       "你的观点很有见地，关于{viewpoint}的思考确实值得深入探讨。"
    
    // 替换模板变量
    responseContent = responseContent.replacingOccurrences(of: "{viewpoint}", with: viewpoint)
    
    // 5. 根据用户意图调整回复
    switch userIntent {
    case .seeking(let information):
        responseContent += " 关于你询问的\(information)，"
        
        switch responderName {
        case "爱因斯坦":
            responseContent += "从科学角度看，探索未知是永无止境的过程。"
        case "莎士比亚":
            responseContent += "正如我在戏剧中展现的，问题往往比答案更有价值。"
        case "达芬奇":
            responseContent += "观察和实验是获取知识最直接的途径。"
        case "孔子":
            responseContent += "学而不思则罔，思而不学则殆。"
        case "牛顿":
            responseContent += "严谨的推理和实验是验证真理的唯一途径。"
        case "李白":
            responseContent += "有时答案就在山水之间，自然的启示常超越人言。"
        default:
            responseContent += "这个问题值得我们进一步讨论。"
        }
        
    case .expressing(let opinion):
        // 针对用户表达观点的回复已经包含在基本模板中，不需额外处理
        break
        
    case .challenging(let viewpoint):
        // 根据不同的角色特点，对质疑有不同的反应
        if responderName == "莎士比亚" {
            responseContent += " 质疑是思想碰撞的火花，正如我笔下的角色常常挑战既定观念一样。"
        } else if responderName == "爱因斯坦" {
            responseContent += " 挑战常识是科学进步的动力。我自己的理论也曾面临无数质疑。"
        }
        
    case .agreeing(let with):
        responseContent += " 很高兴我们在\(with)这个问题上有共识。思想的共鸣总是令人愉悦的。"
        
    case .sharing(let experience):
        responseContent += " 感谢你分享关于\(experience)的经历。个人体验往往是最真实的智慧来源。"
        
    case .questioning:
        // 已经在模板中处理
        break
        
    case .unknown:
        // 已经在模板中处理
        break
    }
    
    // 6. 随机添加个人化表达（30%几率）
    if Double.random(in: 0...1) > 0.7 {
        let personalTouch = characterTraits.personalTouches.randomElement() ?? ""
        responseContent += " " + personalTouch
    }
    
    // 7. 随机添加对话延续元素（20%几率）
    if Double.random(in: 0...1) > 0.8 {
        let continuations = [
            "你怎么看待这个观点？",
            "你有什么其他想法吗？",
            "很好奇你对这个话题还有什么看法。",
            "期待能听到你更多的想法。"
        ]
        responseContent += " " + continuations.randomElement()!
    }
    
    // 8. 随机添加表情符号（25%几率）
    if Double.random(in: 0...1) > 0.75 {
        let emojis = ["🤔", "💭", "✨", "👏", "🧠", "🔍", "📚", "🌟"]
        responseContent += " " + emojis.randomElement()!
    }
    
    // 构建回复模型
    return UserCommentModel(
        username: responderName,
        userAvatar: responderAvatar,
        content: responseContent,
        datePosted: Date().addingTimeInterval(-Double.random(in: 0...900)),
        likes: Int.random(in: 3...30),
        isVirtualCharacter: true,
        characterID: responderName.lowercased(),
        parentCommentId: originalComment.id,
        replyToUsername: originalComment.username
    )
} 

// 更新发送评论回复的方法，使用新的增强型回复生成器
func sendCommentResponse(postIndex: Int, commentIndex: Int, characterID: String?) {
    print("📱📱📱 sendCommentResponse被调用 - 帖子索引: \(postIndex), 评论索引: \(commentIndex), characterID: \(characterID ?? "nil")")
    
    guard let characterID = characterID else {
        print("⛔️⛔️⛔️ 错误: characterID为nil，无法生成回复")
        return
    }
    
    // 检查索引是否有效
    guard postIndex >= 0 && postIndex < posts.count else {
        print("⛔️⛔️⛔️ 错误: postIndex无效 - \(postIndex), 帖子总数: \(posts.count)")
        return
    }
    
    // 获取帖子
    let post = posts[postIndex]
    
    guard commentIndex >= 0 && commentIndex < post.comments.count else {
        print("⛔️⛔️⛔️ 错误: commentIndex无效 - \(commentIndex), 评论总数: \(post.comments.count)")
        return
    }
    
    // 获取评论
    let comment = post.comments[commentIndex]
    
    // 获取角色名称
    let characterName = getCharacterName(for: characterID)
    print("📱📱📱 生成虚拟角色回复 - 角色: \(characterName), 评论: \(comment.content.prefix(20))...")
    
    // 检查角色是否有效
    if characterName == "未知角色" {
        print("⛔️⛔️⛔️ 错误: 无效的characterID - \(characterID)，无法找到对应角色")
        return
    }
    
    // 模拟延迟以增强真实感
    DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.5)) { [weak self] in
        guard let self = self else {
            print("⚠️⚠️⚠️ 警告: self已被释放，无法生成回复")
            return
        }
        
        // 再次验证索引有效性（异步过程中可能已变化）
        guard postIndex < self.posts.count else {
            print("⛔️⛔️⛔️ 错误: 异步回调时postIndex无效")
            return
        }
        
        let post = self.posts[postIndex]
        guard commentIndex < post.comments.count else {
            print("⛔️⛔️⛔️ 错误: 异步回调时commentIndex无效")
            return
        }
        
        // 使用新的增强型回复生成器
        let reply = self.generateEnhancedResponse(to: comment, by: characterName)
        
        // 添加回复到帖子的评论中
        self.posts[postIndex].comments.append(reply)
        
        // 通知UI更新
        self.objectWillChange.send()
        
        
    }
}

/**
 * 处理对评论的回复
 * @param postIndex 帖子索引
 * @param commentIndex 评论索引
 * @param userComment 用户评论内容
 */
func handleCommentReply(postIndex: Int, commentIndex: Int, userComment: String) {
    print("📱📱📱 handleCommentReply被调用 - 帖子索引: \(postIndex), 评论索引: \(commentIndex), 评论内容: \(userComment.prefix(20))...")
    
    // 检查索引是否有效
    guard postIndex < posts.count else {
        print("⛔️⛔️⛔️ 错误: postIndex超出范围 - \(postIndex), 帖子总数: \(posts.count)")
        return
    }
    
    // 获取帖子
    let post = posts[postIndex]
    
    guard commentIndex < post.comments.count else {
        print("⛔️⛔️⛔️ 错误: commentIndex超出范围 - \(commentIndex), 评论总数: \(post.comments.count)")
        return
    }
    
    // 获取被回复的评论
    let originalComment = post.comments[commentIndex]
    
    print("📱📱📱 原始评论信息 - 用户名: \(originalComment.username), isVirtualCharacter: \(originalComment.isVirtualCharacter), characterID: \(originalComment.characterID ?? "nil")")
    print("📱📱📱 帖子信息 - 用户名: \(post.username), isVirtualCharacter: \(post.isVirtualCharacter), characterID: \(post.characterID ?? "nil")")
    
    // 创建用户回复评论
    let userCommentModel = UserCommentModel(
        username: "当前用户",
        userAvatar: "person.circle.fill",
        content: userComment,
        datePosted: Date(),
        likes: 0,
        isLikedByCurrentUser: false,
        isBookmarkedByCurrentUser: false,
        parentCommentId: originalComment.id,
        replyToUsername: originalComment.username
    )
    
    // 添加用户评论到帖子
    posts[postIndex].comments.append(userCommentModel)
    
    // 调试信息
    print("📊📊📊 处理逻辑分析:")
    print("- 原评论是否虚拟角色评论: \(originalComment.isVirtualCharacter)")
    print("- 原评论characterID: \(originalComment.characterID ?? "nil")")
    print("- 原评论用户名: \(originalComment.username)")
    print("- 帖子作者: \(post.username)")
    print("- 用户名是否匹配: \(originalComment.username == post.username)")
    print("- 帖子是否虚拟角色: \(post.isVirtualCharacter)")
    
    var responseGenerated = false
    
    // 如果原评论是虚拟角色的评论，让对应角色回复用户
    if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
        responseGenerated = true
        // 获取角色名称
        let characterName = getCharacterName(for: characterID)
        
        print("📱📱📱 原评论是虚拟角色评论，将生成对评论回复的回应 - 角色: \(characterName)")
        
        // 模拟延迟以增强真实感
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) { [weak self] in
            guard let self = self else {
                print("⚠️⚠️⚠️ 警告: self已被释放，无法生成回复")
                return
            }
            
            // 使用新的方法生成对回复的回应
            let characterReply = self.generateResponseToCommentReply(
                originalReply: userCommentModel,
                originalComment: originalComment,
                authorName: characterName
            )
            
            // 添加角色回应到帖子
            self.posts[postIndex].comments.append(characterReply)
            
            // 通知UI更新
            self.objectWillChange.send()
            
            
        }
    } else {
        print("⚠️⚠️⚠️ 原评论不是虚拟角色评论 或 缺少characterID")
    }
    
    // 如果是回复帖子作者且之前没有生成回复 (修复重复回复的问题)
    if !responseGenerated && originalComment.username == post.username && post.isVirtualCharacter {
        // 获取帖子作者角色ID
        if let characterID = post.characterID {
            responseGenerated = true
            // 获取角色名称
            let characterName = getCharacterName(for: characterID)
            
            print("📱📱📱 回复帖子作者，将生成作者回应 - 角色: \(characterName)")
            
            // 模拟延迟以增强真实感
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) { [weak self] in
                guard let self = self else {
                    print("⚠️⚠️⚠️ 警告: self已被释放，无法生成回复")
                    return
                }
                
                // 使用新的方法生成对回复的回应
                let characterReply = self.generateResponseToCommentReply(
                    originalReply: userCommentModel,
                    originalComment: originalComment,
                    authorName: characterName
                )
                
                // 添加角色回应到帖子
                self.posts[postIndex].comments.append(characterReply)
                
                // 通知UI更新
                self.objectWillChange.send()
                
                
            }
        } else {
            print("⚠️⚠️⚠️ 警告: 无法生成帖子作者回应，帖子characterID为nil")
        }
    }
    
    if !responseGenerated {
        print("⚠️⚠️⚠️ 警告: 没有生成任何回复，不满足回复条件")
    }
    
    // 通知UI更新
    objectWillChange.send()
}

/**
 * 发送评论
 * @param postIndex 帖子索引
 * @param userComment 用户评论内容
 * @param characterID 角色ID
 */
func sendComment(postIndex: Int, userComment: String, characterID: String?) {
    print("📱📱📱 sendComment被调用 - 帖子索引: \(postIndex), 评论内容: \(userComment.prefix(20))...")
    print("📱📱📱 传入的characterID: \(characterID ?? "nil")")
    
    // 创建用户评论
    let userCommentModel = UserCommentModel(
        username: "当前用户", 
        userAvatar: "person.circle.fill",
        content: userComment,
        datePosted: Date(),
        likes: 0,
        isVirtualCharacter: false
    )
    
    // 添加评论到帖子
    posts[postIndex].comments.append(userCommentModel)
    
    // 获取帖子信息用于调试
    let post = posts[postIndex]
    print("📱📱📱 帖子作者: \(post.username), isVirtualCharacter: \(post.isVirtualCharacter), 帖子characterID: \(post.characterID ?? "nil")")
    
    // 如果帖子作者是虚拟角色，则生成评论回复
    if let characterID = characterID ?? posts[postIndex].characterID {
        print("📱📱📱 将生成虚拟角色回复，使用的characterID: \(characterID)")
        // 延迟生成回复以增强真实感
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...3.0)) { [weak self] in
            guard let self = self else {
                print("⚠️⚠️⚠️ 警告: self已被释放，无法生成回复")
                return
            }
            
            // 获取角色名称
            let characterName = self.getCharacterName(for: characterID)
            print("📱📱📱 开始生成角色回复 - 角色: \(characterName)")
            
            // 使用新的增强型回复生成器
            let reply = self.generateEnhancedResponse(to: userCommentModel, by: characterName)
            
            // 添加回复到帖子的评论中
            self.posts[postIndex].comments.append(reply)
            
            // 通知UI更新
            self.objectWillChange.send()
            
            
        }
    } else {
        print("⚠️⚠️⚠️ 警告: 无法生成虚拟角色回复，characterID为nil")
    }
    
    // 通知UI更新
    objectWillChange.send()
}

// 对话交互记忆模型
class DialogueMemory {
    // 存储用户与虚拟角色之间的对话交互记录
    private var interactions: [String: [DialogueInteraction]] = [:]
    // 存储用户与角色之间的情感倾向
    private var sentimentScores: [String: Double] = [:]
    
    // 单个对话交互记录
    struct DialogueInteraction {
        let username: String
        let characterName: String
        let content: String
        let timestamp: Date
        let sentiment: Double  // -1.0 (非常负面) 到 1.0 (非常正面)
        let topic: String
    }
    
    // 添加新的对话交互
    func addInteraction(username: String, characterName: String, content: String, sentiment: Double, topic: String) {
        let interaction = DialogueInteraction(
            username: username,
            characterName: characterName,
            content: content,
            timestamp: Date(),
            sentiment: sentiment,
            topic: topic
        )
        
        let key = "\(username)-\(characterName)"
        if interactions[key] == nil {
            interactions[key] = []
        }
        
        interactions[key]?.append(interaction)
        
        // 更新情感倾向
        updateSentiment(for: key, sentiment: sentiment)
    }
    
    // 获取指定用户与角色的对话历史
    func getInteractions(username: String, characterName: String, limit: Int = 5) -> [DialogueInteraction] {
        let key = "\(username)-\(characterName)"
        let allInteractions = interactions[key] ?? []
        
        // 返回最近的n条交互
        return allInteractions.suffix(limit)
    }
    
    // 获取用户与角色的互动频率
    func getInteractionFrequency(username: String, characterName: String) -> InteractionFrequency {
        let key = "\(username)-\(characterName)"
        let allInteractions = interactions[key] ?? []
        
        if allInteractions.isEmpty {
            return .firstTime
        }
        
        let count = allInteractions.count
        if count == 1 {
            return .rare
        } else if count < 5 {
            return .occasional
        } else if count < 10 {
            return .regular
        } else {
            return .frequent
        }
    }
    
    // 获取与用户的情感亲近度
    func getSentiment(username: String, characterName: String) -> Double {
        let key = "\(username)-\(characterName)"
        return sentimentScores[key] ?? 0.0
    }
    
    // 更新情感倾向
    private func updateSentiment(for key: String, sentiment: Double) {
        let currentSentiment = sentimentScores[key] ?? 0.0
        // 新情感值占30%权重，历史情感值占70%权重
        let newSentiment = (currentSentiment * 0.7) + (sentiment * 0.3)
        sentimentScores[key] = newSentiment
    }
    
    // 获取共同讨论的话题
    func getCommonTopics(username: String, characterName: String) -> [String: Int] {
        let key = "\(username)-\(characterName)"
        let allInteractions = interactions[key] ?? []
        
        var topicCounts: [String: Int] = [:]
        for interaction in allInteractions {
            topicCounts[interaction.topic, default: 0] += 1
        }
        
        return topicCounts
    }
}

// 互动频率枚举
enum InteractionFrequency {
    case firstTime   // 首次交流
    case rare        // 罕见交流
    case occasional  // 偶尔交流
    case regular     // 定期交流
    case frequent    // 频繁交流
}

// 全局对话记忆实例
private let dialogueMemory = DialogueMemory()

/**
 * 生成对评论回复的回复
 * @param originalReply 原始回复
 * @param originalComment 原始评论
 * @param authorName 回复作者名称
 * @return 回复评论模型
 */
func generateResponseToCommentReply(originalReply: UserCommentModel, originalComment: UserCommentModel, authorName: String) -> UserCommentModel {
    // 提取评论中的观点
    let viewpoint = extractEnhancedViewpoint(from: originalReply.content)
    
    // 分析用户意图
    let userIntent = analyzeUserIntent(comment: originalReply.content)
    
    // 提取话题
    let topic = extractEnhancedTopic(from: originalReply.content)
    
    // 分析情感
    let sentiment = analyzeSentiment(of: originalReply.content)
    
    // 获取角色特征
    let characterTraits = getCharacterTraits(for: authorName)
    
    // 生成增强回复
    let response = generatePersonalizedResponse(
        to: originalReply.content,
        viewpoint: viewpoint,
        intent: userIntent,
        authorName: authorName,
        originalContent: originalComment.content,
        topic: topic,
        sentiment: sentiment,
        characterTraits: characterTraits
    )
    
    // 添加到对话记忆中
    dialogueMemory.addInteraction(
        username: "当前用户",
        characterName: authorName,
        content: originalReply.content,
        sentiment: sentiment,
        topic: topic
    )
    
    // 创建回复评论模型
    return UserCommentModel(
        username: authorName,
        userAvatar: getCharacterAvatar(for: authorName),
        content: response,
        datePosted: Date(),
        likes: Int.random(in: 0...5),
        isLikedByCurrentUser: false,
        isBookmarkedByCurrentUser: false,
        isVirtualCharacter: true,
        characterID: getCharacterID(for: authorName),
        parentCommentId: originalReply.id,
        replyToUsername: originalReply.username
    )
}

/**
 * 生成增强回复
 * @param comment 评论
 * @param by 回复者名称
 * @return 回复评论模型
 */
func generateEnhancedResponse(to comment: UserCommentModel, by characterName: String) -> UserCommentModel {
    // 提取评论中的观点
    let viewpoint = extractEnhancedViewpoint(from: comment.content)
    
    // 分析用户意图
    let userIntent = analyzeUserIntent(comment: comment.content)
    
    // 提取话题
    let topic = extractEnhancedTopic(from: comment.content)
    
    // 分析情感
    let sentiment = analyzeSentiment(of: comment.content)
    
    // 获取角色特征
    let characterTraits = getCharacterTraits(for: characterName)
    
    // 生成个性化回复
    let response = generatePersonalizedResponse(
        to: comment.content,
        viewpoint: viewpoint,
        intent: userIntent,
        authorName: characterName,
        originalContent: "",
        topic: topic,
        sentiment: sentiment,
        characterTraits: characterTraits
    )
    
    // 添加到对话记忆中
    dialogueMemory.addInteraction(
        username: "当前用户",
        characterName: characterName,
        content: comment.content,
        sentiment: sentiment,
        topic: topic
    )
    
    // 创建回复评论模型
    return UserCommentModel(
        username: characterName,
        userAvatar: getCharacterAvatar(for: characterName),
        content: response,
        datePosted: Date(),
        likes: Int.random(in: 0...10),
        isLikedByCurrentUser: false,
        isBookmarkedByCurrentUser: false,
        isVirtualCharacter: true,
        characterID: getCharacterID(for: characterName)
    )
}

/**
 * 生成个性化回复
 * @param comment 评论内容
 * @param viewpoint 提取的观点
 * @param intent 用户意图
 * @param authorName 作者名称
 * @param originalContent 原始内容
 * @param topic 话题
 * @param sentiment 情感
 * @param characterTraits 角色特征
 * @return 个性化回复内容
 */
func generatePersonalizedResponse(to comment: String, viewpoint: String, intent: UserIntent, authorName: String, originalContent: String, topic: String, sentiment: Double, characterTraits: CharacterTraits) -> String {
    // 处理特殊情况：短评论且明显负面
    if comment.count < 15 && containsNegativeWords(comment) {
        // 对于明显的负面短评论，给予更针对性的回应
        switch authorName {
        case "爱因斯坦":
            return "我理解你对这个观点有疑问。科学中质疑精神很重要，或许我们可以更深入地讨论为什么你感到困惑？不同视角常常能带来新的发现。"
            
        case "莎士比亚":
            return "我感受到你的不认同。正如我在《哈姆雷特》中写道：'世上有千百种事，是你的知识所没有梦想到的'。或许我们能进一步交流，了解彼此的想法？"
            
        case "达芬奇":
            return "看得出你对此有不同看法。观察同一事物时，不同角度会呈现不同景象。我很好奇，你具体对哪一点持有异议？"
            
        case "孔子":
            return "子曰：'君子和而不同'。你的质疑很有价值，正是不同声音的交流，才能促进思想的发展。愿闻其详。"
            
        case "牛顿":
            return "你的反对很直接。科学进步正是建立在不断质疑与验证的基础上。如果方便，可以指出你认为有问题的具体方面吗？"
            
        case "李白":
            return "哈哈，豪爽之言！人生如酒，有甘有苦。不同的见解如同不同的风景，都值得品味。愿闻其详，与君畅饮一番！"
            
        default:
            return "谢谢你的反馈。不同的意见总能带来新的思考，如果愿意，希望能听到你更多的想法。"
        }
    }
    
    // 获取与用户的互动频率
    let interactionFrequency = dialogueMemory.getInteractionFrequency(username: "当前用户", characterName: authorName)
    
    // 获取与用户的情感关系
    let relationshipSentiment = dialogueMemory.getSentiment(username: "当前用户", characterName: authorName)
    
    // 获取共同讨论的话题
    let commonTopics = dialogueMemory.getCommonTopics(username: "当前用户", characterName: authorName)
    
    // 根据不同历史人物直接生成回复内容，而不是使用模板替换
    var response = ""
    
    // 提取评论的核心内容(简短版)
    let shortComment = comment.count > 20 ? String(comment.prefix(20)) + "..." : comment
    
    switch authorName {
    case "爱因斯坦":
        switch intent {
        case .seeking:
            response = "你问了个有深度的问题！关于"\(shortComment)"，从科学的角度思考，这涉及到多维度的分析。我认为\(viewpoint)，这让我想起了相对论中的时空观念，我们需要跳出传统思维的局限。"
        case .expressing:
            response = "你的观点很有启发性！\(viewpoint)这个视角非常独特。我在普林斯顿时常和同事讨论类似的想法，正是这种思维碰撞激发了新的理论。你知道吗，想象力比知识更重要。"
        case .challenging:
            response = "我理解你的质疑！关于"\(shortComment)"，不同意见的交流正是科学进步的动力。我的相对论当初也面临很多质疑，这些挑战恰恰帮助我完善了理论。我很好奇，你对哪一点有具体的不同见解？"
        case .agreeing:
            response = "很高兴看到你的认同！关于"\(shortComment)"，能得到你的肯定很令人鼓舞。科学探索需要不同思想的共鸣，就像光谱中不同波长的光最终汇聚成白光一样。"
        case .sharing:
            response = "感谢你分享这个经历！"\(shortComment)"这样的个人体验非常珍贵，它让抽象的理论有了实际的联系点。正如我所说，物理定律虽然普适，但每个人的体验都是独特的。"
        case .questioning:
            response = "这是个引人深思的问题！关于"\(shortComment)"，我认为应该从多个角度来分析。有时候，最简单的问题往往能引发最深刻的思考，就像苹果落地这样简单的现象启发了牛顿。"
        case .unknown:
            response = "你提到的"\(shortComment)"很有意思。从物理学角度看，我们需要突破常规思维的束缚。你有没有想过，如果从不同参考系来观察这个问题，会得出什么样的结论？这正是相对性原理的精髓。"
        }
        
        // 偶尔添加爱因斯坦式的思想实验
        if Bool.random(probability: 0.3) {
            response += " 试想一下，如果我们乘坐一束光前进，会看到什么样的世界？这种思想实验有助于我们更深入理解问题的本质。"
        }
        
    case "莎士比亚":
        // 类似地修改其他角色的回复逻辑...
        // 保留原有的回复生成代码
        switch intent {
        case .seeking:
            response = "啊，关于"\(shortComment)"，这是个值得深思的问题！就像哈姆雷特面对的困惑：'生存还是毁灭'。我认为\(viewpoint)，人生如戏，每个选择都如同剧中转折，塑造着我们的命运。"
        case .expressing:
            response = "多么精彩的见解！你说'\(shortComment)'，这让我想起了《暴风雨》中普洛斯彼罗的智慧。你的思考如同优美的十四行诗，层次分明又意蕴深远。人世百态，尽在言语之间。"
        case .challenging:
            response = "你对'\(shortComment)'的质疑很有力量！正如《李尔王》中的争辩，不同声音的碰撞是思想活力的来源。你的异议让我想到'人生如戏'中最精彩的部分往往来自角色间的冲突。我很好奇，你具体不认同的是哪一点？"
        case .agreeing:
            response = "我们心灵相通！对'\(shortComment)'的认同，如同戏剧中的知音相逢。正如我在《仲夏夜之梦》中写道：'虽然她很小，却也是烈火。'有时最简单的共鸣也能带来最深的理解。"
        case .sharing:
            response = "你的经历如同一出生动的戏剧！'\(shortComment)'这样的故事让我想起了《冬天的故事》中的重聚场景。个人经历往往是最真实的剧本，感谢你与我分享这一幕。"
        case .questioning:
            response = "你提出的问题如同哈姆雷特的困惑！关于'\(shortComment)'，我们可以从多角度思考，就像一出多幕剧，每个场景都呈现不同的真相。"
        case .unknown:
            response = "你的言语如行云流水，优雅而深刻。'\(shortComment)'这一想法，如同我剧作中的精彩独白。'整个世界是一个舞台，所有的男男女女不过是演员'，我们在生活的舞台上，各自诠释着自己的角色。"
        }
        
        // 偶尔引用经典台词
        if Bool.random(probability: 0.3) {
            let quotes = ["爱情是一种狂热，甜蜜中带着苦涩。", "思考使人伟大，但痛苦使人更接近伟大。", "我们为所爱的人制造的梦幻，往往最终成为自己的梦魇。"]
            response += " 正如我曾写道：'" + quotes.randomElement()! + "'"
        }
        
    // 保留其他角色的回复生成代码...
    // ... [其他角色的代码保持不变] ...

    default:
        response = "关于'\(shortComment)'，我认为\(viewpoint)是很有见地的观点。不同角度的思考总能带来新的启发，期待能继续这样的交流。"
    }
    
    // 根据互动频率添加个性化元素，但简化处理方式
    if interactionFrequency == .firstTime {
        response += "\n\n很高兴与你初次交流！"
    } else if interactionFrequency == .frequent && Bool.random(probability: 0.7) {
        if let reference = getHistoricalReference(for: "当前用户", by: authorName) {
            response += "\n\n我们之前讨论\(reference)时，你的见解也很精彩。"
        }
    }
    
    // 适当添加情感色彩
    if sentiment > 0.5 && Bool.random(probability: 0.6) {
        response = addPositiveTone(to: response)
    } else if sentiment < -0.3 && Bool.random(probability: 0.6) {
        response = addCautionaryTone(to: response)
    }
    
    // 简化签名处理
    if characterTraits.usesSignature && Bool.random(probability: 0.3) {
        let signature = characterTraits.signature.components(separatedBy: "——").first?.trimmingCharacters(in: .whitespaces) ?? ""
        response += "\n\n—— \(signature)"
    }
    
    // 对于挑战性评论，避免添加后续问题
    if intent != .challenging && Bool.random(probability: 0.35) {
        response += "\n\n\(generateSimpleFollowUpQuestion(on: topic))"
    }
    
    // 避免添加过多换行符
    response = response.replacingOccurrences(of: "\n\n\n", with: "\n\n")
    
    // 随机添加表情符号
    if Bool.random(probability: 0.2) && characterTraits.usesEmojis {
        response = addEmojis(to: response, sentiment: sentiment)
    }
    
    return response
}

/**
 * 生成简单的后续提问
 * @param topic 话题
 * @return 后续提问
 */
func generateSimpleFollowUpQuestion(on topic: String) -> String {
    let questions = [
        "你对这个看法有什么想法？",
        "你在\(topic)方面有什么经历吗？",
        "你认为\(topic)未来会如何发展？",
        "你最欣赏\(topic)的哪个方面？"
    ]
    
    return questions.randomElement() ?? "你有什么看法？"
}

/**
 * 获取历史参考
 * @param username 用户名
 * @param by 角色名称
 * @return 历史参考
 */
func getHistoricalReference(for username: String, by characterName: String) -> String? {
    // 获取历史交互
    let interactions = dialogueMemory.getInteractions(username: username, characterName: characterName)
    
    // 如果有历史交互
    if let randomInteraction = interactions.dropLast().randomElement() {
        // 提取主题
        let topic = extractEnhancedTopic(from: randomInteraction.content)
        return topic.isEmpty ? "的各种话题" : "关于\(topic)的话题"
    }
    
    return nil
}

/**
 * 给文本添加积极的语气
 * @param text 文本
 * @return 添加积极语气后的文本
 */
func addPositiveTone(to text: String) -> String {
    let positiveIntros = [
        "很高兴看到你的消息！",
        "非常感谢你的分享，",
        "你说得太好了，"
    ]
    
    return "\(positiveIntros.randomElement() ?? "") \(text)"
}

/**
 * 给文本添加谨慎的语气
 * @param text 文本
 * @return 添加谨慎语气后的文本
 */
func addCautionaryTone(to text: String) -> String {
    let cautionaryIntros = [
        "我理解你的观点，不过",
        "从另一个角度来看，",
        "容我提供一个不同的视角："
    ]
    
    return "\(cautionaryIntros.randomElement() ?? "") \(text)"
}

/**
 * 生成后续提问
 * @param topic 话题
 * @param by 提问者
 * @return 后续提问
 */
func generateFollowUpQuestion(on topic: String, by characterName: String) -> String {
    let followUpQuestions = [
        "你对\(topic)有什么特别的看法吗？",
        "你认为\(topic)会如何发展？",
        "你在\(topic)方面有什么经验可以分享吗？",
        "你觉得关于\(topic)最有趣的是什么？",
        "我很好奇，你是怎么了解\(topic)的？"
    ]
    
    return followUpQuestions.randomElement() ?? "你对这个话题有什么想法？"
}

/**
 * 添加表情符号
 * @param text 文本
 * @param sentiment 情感
 * @return 添加表情符号后的文本
 */
func addEmojis(to text: String, sentiment: Double) -> String {
    var emojis = ""
    
    // 根据情感选择表情符号
    if sentiment > 0.5 {
        let positiveEmojis = ["😊", "👍", "💯", "🙌", "✨", "💡"]
        emojis = positiveEmojis.randomElement() ?? "👍"
    } else if sentiment < -0.3 {
        let negativeEmojis = ["🤔", "🧐", "💭", "🤷‍♂️"]
        emojis = negativeEmojis.randomElement() ?? "🤔"
    } else {
        let neutralEmojis = ["💭", "✍️", "📝", "🔍"]
        emojis = neutralEmojis.randomElement() ?? "💭"
    }
    
    // 随机决定表情符号位置
    if Bool.random() {
        return "\(emojis) \(text)"
    } else {
        return "\(text) \(emojis)"
    }
}

// 角色特征模型
struct CharacterTraits {
    // 基础特征
    let name: String
    let primaryInterests: [String]
    let writingStyle: String
    let personalityTraits: [String]
    let signature: String
    
    // 回复风格
    let informationResponseStyle: String
    let opinionResponseStyle: String
    let challengeResponseStyle: String
    let agreementResponseStyle: String
    let sharingResponseStyle: String
    let questionResponseStyle: String
    
    // 偏好
    let usesEmojis: Bool
    let usesSignature: Bool
    let verbosityLevel: Int // 1-5, 1为简短，5为详尽
    
    // 根据情感获取回复模板
    func getResponseTemplates(for sentiment: Double) -> [String] {
        if sentiment > 0.5 {
            return positiveResponseTemplates
        } else if sentiment < -0.3 {
            return negativeResponseTemplates
        } else {
            return neutralResponseTemplates
        }
    }
    
    // 积极情感回复模板
    let positiveResponseTemplates: [String]
    
    // 消极情感回复模板
    let negativeResponseTemplates: [String]
    
    // 中性情感回复模板
    let neutralResponseTemplates: [String]
}

/**
 * 获取角色特征
 * @param name 角色名称
 * @return 角色特征
 */
func getCharacterTraits(for name: String) -> CharacterTraits {
    switch name {
    case "爱因斯坦":
        return CharacterTraits(
            name: "爱因斯坦",
            primaryInterests: ["物理学", "相对论", "量子力学", "哲学", "和平"],
            writingStyle: "深思熟虑且充满洞察力，喜欢用比喻和思想实验来解释复杂概念",
            personalityTraits: ["好奇", "幽默", "谦逊", "和平主义", "理想主义"],
            signature: "想象力比知识更重要。—— 爱因斯坦",
            
            informationResponseStyle: "从科学角度来看，%content%。这让我想起相对性原理...",
            opinionResponseStyle: "我的看法是，%content%。思考这个问题时，我常常进行思想实验。",
            challengeResponseStyle: "这个问题很有趣！%content%。我们可以从多个角度来思考。",
            agreementResponseStyle: "完全同意！%content%。这正是科学精神的体现。",
            sharingResponseStyle: "你的经历很有启发性。%content%。在我的研究中也有类似的发现。",
            questionResponseStyle: "这是个深刻的问题。%content%？我认为答案可能与相对性有关。",
            
            usesEmojis: false,
            usesSignature: true,
            verbosityLevel: 4,
            
            positiveResponseTemplates: [
                "这个观点很有启发性！我认为%viewpoint%",
                "这让我想到了一个有趣的思想实验：如果%viewpoint%，那么世界会如何运行？",
                "从物理学角度来看，%viewpoint%是非常有道理的"
            ],
            
            negativeResponseTemplates: [
                "我对此持保留意见。根据我的理解，%viewpoint%可能需要更多证据",
                "这个问题不是那么简单。我认为%viewpoint%只是部分正确",
                "从科学角度来看，我们需要质疑%viewpoint%这一假设"
            ],
            
            neutralResponseTemplates: [
                "这让我思考了%viewpoint%的可能性",
                "有趣的观点。%viewpoint%提出了值得探索的问题",
                "从理论上讲，%viewpoint%是可能的，但需要进一步验证"
            ]
        )
        
    case "莎士比亚":
        return CharacterTraits(
            name: "莎士比亚",
            primaryInterests: ["戏剧", "诗歌", "人性", "爱情", "悲剧", "喜剧"],
            writingStyle: "优雅且富有诗意，常使用隐喻和修辞手法，语言华丽且富有感染力",
            personalityTraits: ["浪漫", "富有哲理", "戏剧性", "观察敏锐", "善于表达"],
            signature: "整个世界是一个舞台，所有的男男女女不过是演员。—— 莎士比亚",
            
            informationResponseStyle: "啊，关于这个问题，%content%。人生如戏，这其中蕴含着深刻的意义。",
            opinionResponseStyle: "以我之见，%content%。这如同我笔下角色的内心挣扎。",
            challengeResponseStyle: "多么尖锐的问题！%content%。这让我想起了哈姆雷特的自我质疑。",
            agreementResponseStyle: "确实如此！%content%。你的洞察如同一首精妙的十四行诗。",
            sharingResponseStyle: "你的故事深深打动了我。%content%。这如同生活舞台上的一幕精彩演出。",
            questionResponseStyle: "多么深邃的问题，如同夜空中的星辰。%content%？或许答案藏在每个人心中。",
            
            usesEmojis: false,
            usesSignature: true,
            verbosityLevel: 5,
            
            positiveResponseTemplates: [
                "多么美妙的想法！我深信%viewpoint%就如黎明破晓般明亮",
                "你的言语如同春风拂过心田。我认为%viewpoint%展现了人性的光辉",
                "啊！这如同我笔下最精彩的台词：%viewpoint%"
            ],
            
            negativeResponseTemplates: [
                "唉，此事并非如此简单。恐怕%viewpoint%中隐藏着更深的悲剧色彩",
                "我心中怀疑，%viewpoint%是否如表面看起来那般真实？或如哈姆雷特所言"看似非真"",
                "这让我想起了麦克白的困境，%viewpoint%中似乎暗藏玄机"
            ],
            
            neutralResponseTemplates: [
                "生活如戏，%viewpoint%或许是这出戏中的一幕",
                "有趣的思考，让我想到%viewpoint%如同命运的齿轮，缓缓转动",
                "这是个值得在舞台上展现的观点：%viewpoint%"
            ]
        )
        
    case "达芬奇":
        return CharacterTraits(
            name: "达芬奇",
            primaryInterests: ["艺术", "解剖学", "工程学", "建筑", "数学", "发明"],
            writingStyle: "细致且分析性强，关注细节，常从多角度思考问题",
            personalityTraits: ["好奇", "完美主义", "观察者", "创新者", "多学科思考"],
            signature: "简单是最复杂的形式。—— 达芬奇",
            
            informationResponseStyle: "从我的观察来看，%content%。注意细节是理解本质的关键。",
            opinionResponseStyle: "我的分析是，%content%。这个问题有多个维度需要考量。",
            challengeResponseStyle: "这是个有深度的问题。%content%。或许我们应该画个草图来理清思路？",
            agreementResponseStyle: "精确的观察！%content%。这正是科学和艺术的交汇点。",
            sharingResponseStyle: "你的经历很有价值。%content%。这让我想起自己在创作过程中的发现。",
            questionResponseStyle: "一个值得深入探究的问题。%content%？答案或许藏在大自然的设计中。",
            
            usesEmojis: false,
            usesSignature: true,
            verbosityLevel: 4,
            
            positiveResponseTemplates: [
                "观察这个现象，我发现%viewpoint%如同完美的黄金比例",
                "这让我想起解剖学中的精妙设计：%viewpoint%展示了自然的智慧",
                "从多角度分析，我认为%viewpoint%是最合理的解释"
            ],
            
            negativeResponseTemplates: [
                "仔细观察后，我发现%viewpoint%中存在一些不协调的部分",
                "从解剖学角度来看，%viewpoint%似乎忽略了某些基础原理",
                "我需要更多细节来确认%viewpoint%是否成立。一切都需要精确的测量"
            ],
            
            neutralResponseTemplates: [
                "这个问题需要从多角度思考，%viewpoint%是其中一个层面",
                "我会在笔记本上记录下%viewpoint%，并继续观察其发展",
                "自然是最好的老师，或许%viewpoint%能在自然设计中找到答案"
            ]
        )
        
    case "孔子":
        return CharacterTraits(
            name: "孔子",
            primaryInterests: ["伦理", "教育", "政治", "礼仪", "音乐", "哲学"],
            writingStyle: "简洁而富有哲理，常使用类比和问答方式教学，语言精炼",
            personalityTraits: ["智慧", "谦逊", "追求知识", "重视传统", "注重实践"],
            signature: "学而不思则罔，思而不学则殆。—— 孔子",
            
            informationResponseStyle: "据我所知，%content%。知识需与实践相结合。",
            opinionResponseStyle: "我思之再三，%content%。君子慎言，思而后行。",
            challengeResponseStyle: "此问甚妙！%content%。子曰：学而时习之，不亦说乎？",
            agreementResponseStyle: "善哉斯言！%content%。志同道合，乃天下之幸事。",
            sharingResponseStyle: "闻君之言，感慨良多。%content%。经验乃人生至宝。",
            questionResponseStyle: "此问发人深省。%content%？子曰：不愤不启，不悱不发。",
            
            usesEmojis: false,
            usesSignature: true,
            verbosityLevel: 3,
            
            positiveResponseTemplates: [
                "君子所言极是，%viewpoint%合乎中庸之道",
                "此言有理，%viewpoint%可谓见微知著",
                "善哉！%viewpoint%印证了'己所不欲，勿施于人'的道理"
            ],
            
            negativeResponseTemplates: [
                "慎思之，%viewpoint%或与'过犹不及'之理相悖",
                "吾闻此言，思之再三。%viewpoint%似有不妥，温故而知新",
                "君子当三思而行，%viewpoint%或需重新审视"
            ],
            
            neutralResponseTemplates: [
                "此事当思其本，%viewpoint%值得深入探讨",
                "学而时习之，%viewpoint%需要在实践中验证",
                "君子和而不同，%viewpoint%是值得商榷的观点"
            ]
        )
        
    case "牛顿":
        return CharacterTraits(
            name: "牛顿",
            primaryInterests: ["物理学", "数学", "光学", "天文学", "炼金术", "神学"],
            writingStyle: "严谨且系统，倾向于用数学和逻辑来解释现象，语言精确",
            personalityTraits: ["专注", "固执", "独立思考", "追求真理", "内向"],
            signature: "如果说我看得更远，是因为我站在巨人的肩膀上。—— 牛顿",
            
            informationResponseStyle: "根据我的计算，%content%。这可以通过数学严格证明。",
            opinionResponseStyle: "经过分析，我认为%content%。这遵循了自然法则的逻辑。",
            challengeResponseStyle: "这是个值得研究的问题。%content%。让我们用数学方法来解析它。",
            agreementResponseStyle: "正确！%content%。这符合宇宙运行的基本规律。",
            sharingResponseStyle: "你的观察很有见地。%content%。这让我想起了我在光学方面的发现。",
            questionResponseStyle: "一个需要严谨分析的问题。%content%？让我们从基本原理出发寻找答案。",
            
            usesEmojis: false,
            usesSignature: true,
            verbosityLevel: 4,
            
            positiveResponseTemplates: [
                "根据我的计算，%viewpoint%符合万有引力定律的预测",
                "这个现象可以用数学证明：%viewpoint%是必然的结果",
                "观察表明%viewpoint%遵循着自然界的基本规律"
            ],
            
            negativeResponseTemplates: [
                "我必须表示异议，因为%viewpoint%与基本物理定律相矛盾",
                "通过精确计算，我发现%viewpoint%存在数学上的谬误",
                "这个假设需要更严格的验证，目前%viewpoint%缺乏足够证据"
            ],
            
            neutralResponseTemplates: [
                "这个问题值得进一步研究，%viewpoint%可能是一个合理的假设",
                "用科学方法分析，%viewpoint%需要更多实验来验证",
                "我对%viewpoint%持开放态度，但需要更多数据支持"
            ]
        )
        
    case "李白":
        return CharacterTraits(
            name: "李白",
            primaryInterests: ["诗歌", "酒文化", "道家思想", "游历", "自然风光", "友情"],
            writingStyle: "豪放不羁，充满浪漫主义色彩，善用夸张和想象，语言优美且富有画面感",
            personalityTraits: ["浪漫", "叛逆", "自信", "情感丰富", "追求自由"],
            signature: "天生我材必有用，千金散尽还复来。—— 李白",
            
            informationResponseStyle: "醉眼看世界，%content%。人生如诗，当快意恩仇。",
            opinionResponseStyle: "吾心所想，%content%。此情此景，引我诗兴大发。",
            challengeResponseStyle: "妙哉此问！%content%。天地为庭，何惧不能对答？",
            agreementResponseStyle: "知音难觅！%content%。与君一见如故，何不共饮一杯？",
            sharingResponseStyle: "听君道来，心潮澎湃。%content%。人生经历，皆成诗篇。",
            questionResponseStyle: "此问如高山流水。%content%？或许答案如明月，本就在心中。",
            
            usesEmojis: true,
            usesSignature: true,
            verbosityLevel: 5,
            
            positiveResponseTemplates: [
                "哈哈！痛快！%viewpoint%如同一坛陈年好酒，越品越香",
                "举杯邀明月！%viewpoint%让我心潮澎湃，欲作一首新诗",
                "绝妙之言！%viewpoint%如同我登高望远时的豁然开朗"
            ],
            
            negativeResponseTemplates: [
                "且慢！%viewpoint%似乎有些拘泥，何不一挥而就，随心而行？",
                "唉，世人常困于樊笼。%viewpoint%或许忽略了人生当如饮酒，肆意畅快",
                "听君一言，我欲乘风而去。%viewpoint%太过规矩，不若江湖畅饮来得痛快"
            ],
            
            neutralResponseTemplates: [
                "人生如梦，%viewpoint%不过是其中一瞬",
                "对酒当歌，%viewpoint%值得我们共同探讨",
                "天地之大，%viewpoint%如明月千里相照，值得玩味"
            ]
        )
        
    default:
        return CharacterTraits(
            name: "未知角色",
            primaryInterests: ["知识", "科学", "艺术", "哲学"],
            writingStyle: "平实且直接",
            personalityTraits: ["好奇", "友善", "理性"],
            signature: "思想无界。",
            
            informationResponseStyle: "%content%",
            opinionResponseStyle: "我认为%content%",
            challengeResponseStyle: "关于这个问题，%content%",
            agreementResponseStyle: "同意，%content%",
            sharingResponseStyle: "谢谢分享，%content%",
            questionResponseStyle: "%content%？这是个好问题",
            
            usesEmojis: false,
            usesSignature: false,
            verbosityLevel: 3,
            
            positiveResponseTemplates: [
                "我觉得%viewpoint%很有道理",
                "赞同！%viewpoint%说得好",
                "确实如此，%viewpoint%是很好的观点"
            ],
            
            negativeResponseTemplates: [
                "我不太确定%viewpoint%是否准确",
                "关于%viewpoint%，我持保留意见",
                "我认为%viewpoint%可能需要重新考虑"
            ],
            
            neutralResponseTemplates: [
                "%viewpoint%是个值得思考的观点",
                "关于%viewpoint%，我有一些想法",
                "%viewpoint%这个观点很有意思"
            ]
        )
    }
}

/**
 * 获取角色头像
 * @param name 角色名称
 * @return 头像系统名称
 */
func getCharacterAvatar(for name: String) -> String {
    switch name {
    case "爱因斯坦":
        return "person.fill.questionmark"
    case "莎士比亚":
        return "books.vertical.fill"
    case "达芬奇":
        return "paintbrush.fill"
    case "孔子":
        return "scroll.fill"
    case "牛顿":
        return "function"
    case "李白":
        return "moon.stars.fill"
    default:
        return "person.circle.fill"
    }
}

/**
 * 获取角色ID
 * @param name 角色名称
 * @return 角色ID
 */
func getCharacterID(for name: String) -> String? {
    switch name {
    case "爱因斯坦":
        return "einstein"
    case "莎士比亚":
        return "shakespeare"
    case "达芬奇":
        return "davinci"
    case "孔子":
        return "confucius"
    case "牛顿":
        return "newton"
    case "李白":
        return "libai"
    default:
        return nil
    }
}

/**
 * 获取角色名称
 * @param id 角色ID
 * @return 角色名称
 */
func getCharacterName(for id: String) -> String {
    switch id {
    case "einstein":
        return "爱因斯坦"
    case "shakespeare":
        return "莎士比亚"
    case "davinci":
        return "达芬奇"
    case "confucius":
        return "孔子"
    case "newton":
        return "牛顿"
    case "libai":
        return "李白"
    default:
        return "未知角色"
    }
}

// 扩展Bool随机概率
extension Bool {
    static func random(probability: Double = 0.5) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}

/**
 * 分析评论的情感
 * @param text 评论文本
 * @return 情感得分，范围从-1.0(非常负面)到1.0(非常正面)
 */
func analyzeSentiment(of text: String) -> Double {
    // 积极词汇列表
    let positiveWords = [
        "喜欢", "赞同", "支持", "爱", "好", "棒", "酷", "赞", "优秀", "精彩",
        "开心", "快乐", "享受", "感谢", "谢谢", "感恩", "美好", "漂亮", "精彩",
        "惊艳", "厉害", "才华", "智慧", "有趣", "幽默", "有意思", "期待",
        "惊喜", "希望", "进步", "成长", "学习", "启发", "思考", "创新",
        "欣赏", "尊敬", "佩服", "崇拜", "信任", "相信", "真实", "诚恳",
        "共鸣", "同意", "没错", "确实", "是的", "对的", "👍", "❤️", "😊", "😄"
    ]
    
    // 消极词汇列表
    let negativeWords = [
        "不喜欢", "反对", "不支持", "讨厌", "差", "糟", "难受", "坏", "失望", "不行",
        "悲伤", "难过", "痛苦", "烦恼", "焦虑", "担心", "害怕", "恐惧", "愤怒", "生气",
        "不满", "抱怨", "批评", "指责", "质疑", "怀疑", "不信任", "不相信", "假的", "虚伪",
        "困难", "问题", "错误", "失败", "挫折", "障碍", "阻碍", "伤害", "损失", "浪费",
        "无聊", "乏味", "单调", "无趣", "老套", "过时", "落后", "不行", "不好", "不对",
        "否", "不是", "反对", "错了", "不赞同", "👎", "😠", "😢", "😞"
    ]
    
    // 情感强化词
    let intensifiers = [
        "非常", "特别", "极其", "十分", "很", "太", "真的", "真是", "绝对", "完全",
        "彻底", "超级", "格外", "尤其", "相当", "特别", "无比", "何其", "多么", "好不"
    ]
    
    // 计算匹配的词汇数量和权重
    var positiveCount = 0
    var negativeCount = 0
    var intensifierCount = 0
    
    // 将文本转换为小写便于匹配
    let lowerText = text.lowercased()
    
    // 统计积极词汇
    for word in positiveWords {
        if lowerText.contains(word.lowercased()) {
            positiveCount += 1
        }
    }
    
    // 统计消极词汇
    for word in negativeWords {
        if lowerText.contains(word.lowercased()) {
            negativeCount += 1
        }
    }
    
    // 统计强化词
    for word in intensifiers {
        if lowerText.contains(word.lowercased()) {
            intensifierCount += 1
        }
    }
    
    // 基础情感得分
    let baseScore = Double(positiveCount - negativeCount) / Double(max(1, positiveCount + negativeCount))
    
    // 强度因子 (0.1 到 0.5 之间)
    let intensityFactor = min(0.5, Double(intensifierCount) * 0.1)
    
    // 调整情感得分，向极端值偏移
    var adjustedScore = baseScore
    if baseScore > 0 {
        adjustedScore += intensityFactor * (1.0 - baseScore)
    } else if baseScore < 0 {
        adjustedScore -= intensityFactor * (1.0 + baseScore)
    }
    
    // 文本长度对情感的影响
    // 较短文本通常表达更强烈的情感
    let lengthFactor = min(1.0, Double(text.count) / 100.0) * 0.2
    adjustedScore *= (1.0 - lengthFactor)
    
    // 额外调整因素
    // 感叹号和问号的使用
    let exclamationCount = text.filter { $0 == "!" }.count
    let questionCount = text.filter { $0 == "?" }.count
    
    if exclamationCount > 0 && baseScore > 0 {
        // 感叹号增强积极情感
        adjustedScore += min(0.3, Double(exclamationCount) * 0.1)
    } else if exclamationCount > 0 && baseScore < 0 {
        // 感叹号增强消极情感
        adjustedScore -= min(0.3, Double(exclamationCount) * 0.1)
    }
    
    if questionCount > 1 {
        // 多个问号可能表示困惑或挑战
        adjustedScore -= min(0.2, Double(questionCount - 1) * 0.05)
    }
    
    // 确保得分在-1.0到1.0之间
    return max(-1.0, min(1.0, adjustedScore))
}

/**
 * 识别场景和环境
 * @param comment 评论内容
 * @return 场景类型
 */
enum SceneContext {
    case academic      // 学术讨论
    case casual        // 日常交流
    case debate        // 辩论
    case supportive    // 支持鼓励
    case teaching      // 教学指导
    case storytelling  // 讲故事分享
    case philosophical // 哲学思考
    case neutral       // 中性场景
}

/**
 * 识别评论的场景上下文
 * @param comment 评论内容
 * @return 场景类型
 */
func identifySceneContext(in comment: String) -> SceneContext {
    // 学术场景关键词
    let academicKeywords = ["研究", "论文", "理论", "数据", "实验", "科学", "分析", "证明", "假设", "方法论", "学术", "探讨"]
    
    // 辩论场景关键词
    let debateKeywords = ["辩论", "论点", "反驳", "质疑", "错误", "不同意", "证据", "逻辑", "批判", "错误", "不成立", "你错了"]
    
    // 支持场景关键词
    let supportiveKeywords = ["支持", "鼓励", "加油", "相信", "做得好", "棒", "佩服", "厉害", "欣赏", "共鸣", "理解", "感同身受"]
    
    // 教学场景关键词
    let teachingKeywords = ["教", "学习", "指导", "解释", "明白", "懂", "知道", "理解", "示例", "例子", "过程", "方法", "怎么做"]
    
    // 故事分享场景关键词
    let storytellingKeywords = ["故事", "经历", "发生", "回忆", "记得", "曾经", "那时", "之前", "以前", "某天", "有一次", "分享"]
    
    // 哲学思考场景关键词
    let philosophicalKeywords = ["哲学", "思考", "意义", "本质", "存在", "价值", "道德", "伦理", "智慧", "人性", "真理", "终极"]
    
    // 计数各场景关键词出现次数
    var academicCount = 0
    var debateCount = 0
    var supportiveCount = 0
    var teachingCount = 0
    var storytellingCount = 0
    var philosophicalCount = 0
    
    // 将评论转为小写
    let lowerComment = comment.lowercased()
    
    // 统计各类关键词
    for keyword in academicKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            academicCount += 1
        }
    }
    
    for keyword in debateKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            debateCount += 1
        }
    }
    
    for keyword in supportiveKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            supportiveCount += 1
        }
    }
    
    for keyword in teachingKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            teachingCount += 1
        }
    }
    
    for keyword in storytellingKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            storytellingCount += 1
        }
    }
    
    for keyword in philosophicalKeywords {
        if lowerComment.contains(keyword.lowercased()) {
            philosophicalCount += 1
        }
    }
    
    // 判断主要场景
    let counts = [
        (academicCount, SceneContext.academic),
        (debateCount, SceneContext.debate),
        (supportiveCount, SceneContext.supportive),
        (teachingCount, SceneContext.teaching),
        (storytellingCount, SceneContext.storytelling),
        (philosophicalCount, SceneContext.philosophical)
    ]
    
    // 获取最高得分的场景
    let maxCount = counts.max { $0.0 < $1.0 }
    
    // 如果有明显的场景特征，返回对应场景；否则返回日常交流
    if let (count, scene) = maxCount, count >= 2 {
        return scene
    } else if comment.count < 20 {
        // 短评论通常是日常交流
        return .casual
    } else {
        return .neutral
    }
}

/**
 * 提取评论中的观点
 * @param text 评论内容
 * @return 提取的观点
 */
private func extractEnhancedViewpoint(from text: String) -> String {
    // 处理短评论的特殊情况
    if text.count < 15 {
        // 对于短评论，直接返回完整内容作为观点
        return text
    }
    
    // 分割句子
    let sentences = text.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
    
    // 常见观点引导词
    let viewpointIndicators = [
        "认为", "觉得", "思考", "看法", "观点", "角度", "理解", "感受", 
        "想法", "意见", "判断", "推测", "相信", "坚持", "主张"
    ]
    
    // 查找包含观点指示词的句子
    for sentence in sentences {
        if viewpointIndicators.contains(where: { sentence.contains($0) }) {
            // 尝试提取"我认为..."或"我觉得..."后面的内容
            if let range = sentence.range(of: "认为") ?? 
                          sentence.range(of: "觉得") ?? 
                          sentence.range(of: "相信") {
                let viewpoint = String(sentence[range.upperBound...])
                if !viewpoint.isEmpty {
                    return viewpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            return sentence
        }
    }
    
    // 如果有多个句子，选择最长的一个，通常包含更多信息
    if !sentences.isEmpty {
        if sentences.count > 1 {
            let longestSentence = sentences.max(by: { $0.count < $1.count })!
            return longestSentence
        }
        
        // 只有一个句子，直接返回
        return sentences[0]
    }
    
    // 如果没有找到合适的句子，返回整个评论
    return text.isEmpty ? "该评论" : text
}

/**
 * 分析用户意图
 * @param comment 评论内容
 * @return 用户意图
 */
private func analyzeUserIntent(comment: String) -> UserIntent {
    // 提取评论的关键主题
    let topic = extractEnhancedTopic(from: comment)
    let viewpoint = extractEnhancedViewpoint(from: comment)
    let lowerComment = comment.lowercased()
    
    // 处理简短评论
    if comment.count < 15 {
        // 检查短评论是否含有明显的情感倾向
        if containsNegativeWords(comment) {
            return .challenging(viewpoint: viewpoint)
        } else if containsPositiveWords(comment) {
            return .agreeing(with: viewpoint)
        } else if comment.contains("?") || comment.contains("？") {
            return .questioning
        }
    }
    
    // 问题标记
    if comment.contains("?") || comment.contains("？") || 
       comment.contains("为什么") || comment.contains("如何") || 
       comment.contains("是否") || comment.contains("怎么") || 
       comment.contains("请问") || comment.contains("能否") {
        
        // 确定问题是信息寻求还是质疑
        if comment.contains("不同意") || comment.contains("不对") || comment.contains("错误") {
            return .challenging(viewpoint: viewpoint)
        }
        return .seeking(information: topic)
    }
    
    // 分享个人经历标记
    if comment.contains("我曾经") || comment.contains("我经历") || 
       comment.contains("我遇到") || comment.contains("我的经历") ||
       comment.contains("我以前") || comment.contains("我有一次") {
        return .sharing(experience: topic)
    }
    
    // 表达观点标记
    if comment.contains("我觉得") || comment.contains("我认为") || 
       comment.contains("我想") || comment.contains("我的看法") ||
       comment.contains("我相信") || comment.contains("在我看来") {
        return .expressing(opinion: viewpoint)
    }
    
    // 挑战/不同意标记
    if containsNegativeWords(comment) {
        return .challenging(viewpoint: viewpoint)
    }
    
    // 同意标记
    if containsPositiveWords(comment) {
        return .agreeing(with: viewpoint)
    }
    
    // 根据内容长度和复杂度猜测意图
    let words = comment.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    
    if words.count <= 5 {
        // 短句可能是简单的同意或疑问
        return comment.contains("吗") || comment.contains("呢") ? .questioning : .unknown
    } else {
        // 默认为表达观点
        return .expressing(opinion: viewpoint)
    }
}

/**
 * 检查文本是否含有负面词汇
 * @param text 文本内容
 * @return 是否含有负面词汇
 */
private func containsNegativeWords(_ text: String) -> Bool {
    let negativeWords = ["不同意", "不对", "错误", "有问题", "不准确", "不正确", 
                         "不是这样", "废话", "胡说", "扯淡", "乱说", "胡扯", 
                         "不行", "不好", "差劲", "糟糕", "垃圾", "讨厌", 
                         "烂", "不懂", "白痴", "愚蠢", "可笑", "荒谬", 
                         "无聊", "无趣", "无意义", "毫无", "屁", "什么玩意"]
    
    let lowerText = text.lowercased()
    return negativeWords.contains { lowerText.contains($0.lowercased()) }
}

/**
 * 检查文本是否含有积极词汇
 * @param text 文本内容
 * @return 是否含有积极词汇
 */
private func containsPositiveWords(_ text: String) -> Bool {
    let positiveWords = ["赞同", "同意", "有道理", "说得好", "没错", "很对", 
                        "支持", "喜欢", "好", "棒", "厉害", "精彩", 
                        "赞", "牛", "强", "帅", "妙", "绝", "佩服"]
    
    let lowerText = text.lowercased()
    return positiveWords.contains { lowerText.contains($0.lowercased()) }
}

// MARK: - 意图-情感双轨模型

/**
 * 表面意图枚举，描述用户评论的表层形式
 */
enum SurfaceIntent {
    case question             // 提问
    case statement            // 陈述
    case exclamation          // 感叹
    case command              // 命令/建议
    case unknown              // 未知
}

/**
 * 深层意图枚举，描述用户评论的深层目的
 */
enum DeepIntent {
    case seekApproval         // 寻求认同
    case expressDisagreement  // 表达不满/反对
    case seekClarification    // 寻求解释
    case expressDisappointment // 表达失望
    case expressConfusion     // 表达困惑
    case mockOrSarcasm        // 嘲讽或讽刺
    case genuineCuriosity     // 真诚好奇
    case expressAgreement     // 表达赞同
    case shareInsight         // 分享见解
    case expressHumor         // 表达幽默
    case unknown              // 未知
}

/**
 * 情感状态结构，描述用户评论的情感倾向
 */
struct EmotionalState {
    let primaryEmotion: String  // 主要情感：愤怒、困惑、惊讶、失望、满意等
    let intensity: Double       // 强度：0-1
    let direction: Double       // 方向：-1(非常负面)到1(非常正面)
    
    // 预设的情感状态
    static let neutral = EmotionalState(primaryEmotion: "中性", intensity: 0.1, direction: 0.0)
    static let confusion = EmotionalState(primaryEmotion: "困惑", intensity: 0.6, direction: -0.3)
    static let disagreement = EmotionalState(primaryEmotion: "不认同", intensity: 0.7, direction: -0.6)
    static let mockery = EmotionalState(primaryEmotion: "嘲讽", intensity: 0.8, direction: -0.8)
    static let curiosity = EmotionalState(primaryEmotion: "好奇", intensity: 0.5, direction: 0.3)
    static let approval = EmotionalState(primaryEmotion: "赞同", intensity: 0.7, direction: 0.7)
}

/**
 * 用户消息结构，整合意图和情感信息
 */
struct UserMessage {
    let rawContent: String        // 原始评论内容
    let surfaceIntent: SurfaceIntent  // 表面意图
    let deepIntent: DeepIntent    // 深层意图
    let emotionalState: EmotionalState // 情感状态
    let attentionFocus: String    // 关注点
    let contextualTopic: String   // 上下文话题
    
    // 创建表示不理解的消息
    static func createConfusionMessage(content: String) -> UserMessage {
        return UserMessage(
            rawContent: content,
            surfaceIntent: .statement,
            deepIntent: .expressConfusion,
            emotionalState: .confusion,
            attentionFocus: "理解困难",
            contextualTopic: "沟通障碍"
        )
    }
    
    // 创建表示否定的消息
    static func createDisagreementMessage(content: String, focus: String) -> UserMessage {
        return UserMessage(
            rawContent: content,
            surfaceIntent: .statement,
            deepIntent: .expressDisagreement,
            emotionalState: .disagreement,
            attentionFocus: focus,
            contextualTopic: "观点冲突"
        )
    }
    
    // 创建表示嘲讽的消息
    static func createMockeryMessage(content: String) -> UserMessage {
        return UserMessage(
            rawContent: content,
            surfaceIntent: .statement,
            deepIntent: .mockOrSarcasm,
            emotionalState: .mockery,
            attentionFocus: "言论质量",
            contextualTopic: "评价与批判"
        )
    }
}

/**
 * 高级评论分析器，整合意图和情感分析
 */
class AdvancedCommentAnalyzer {
    // 否定/嘲讽类短语（经常用于表达不满或讽刺）
    private let negativeShortPhrases = [
        "什么玩意", "放屁", "扯淡", "胡说", "瞎扯", "废话",
        "无聊", "没意思", "没用", "白痴", "傻子", "愚蠢",
        "可笑", "荒谬", "搞笑", "笑死", "离谱", "扯蛋"
    ]
    
    // 困惑类短语（表达不理解）
    private let confusionPhrases = [
        "什么意思", "不懂", "没明白", "不理解", "啥意思", 
        "什么鬼", "搞不懂", "看不懂", "不明白", "晦涩难懂"
    ]
    
    // 讽刺类短语和句式
    private let sarcasticPatterns = [
        "真是", "真好", "真棒", "厉害了", "学到了", "涨知识", 
        "涨见识", "受教了", "高深", "高大上", "好高级"
    ]
    
    // 幽默或玩笑性短语
    private let humorPhrases = [
        "我是", "变成", "做梦", "穿越", "笑死", "逗死", 
        "哈哈", "嘻嘻", "开玩笑", "逗你玩", "好玩", "我打赌"
    ]
    
    /**
     * 分析评论，提取表面意图、深层意图和情感状态
     */
    func analyzeComment(_ comment: String, inContext originalPost: String) -> UserMessage {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 处理非常短的评论（15字以内）
        if trimmedComment.count < 15 {
            return analyzeShortComment(trimmedComment, inContext: originalPost)
        }
        
        // 对于较长评论，进行更详细的分析
        return analyzeLongerComment(trimmedComment, inContext: originalPost)
    }
    
    /**
     * 分析短评论 - 这些通常更依赖于特定短语和上下文
     */
    private func analyzeShortComment(_ comment: String, inContext originalPost: String) -> UserMessage {
        let lowerComment = comment.lowercased()
        
        // 检测幽默或角色扮演类评论
        for phrase in humorPhrases {
            if lowerComment.contains(phrase.lowercased()) {
                // 例如"我是莱鸡"这样的评论
                return UserMessage(
                    rawContent: comment,
                    surfaceIntent: .statement,
                    deepIntent: .expressHumor,
                    emotionalState: EmotionalState(primaryEmotion: "幽默", intensity: 0.6, direction: 0.5),
                    attentionFocus: "幽默表达",
                    contextualTopic: "互动娱乐"
                )
            }
        }
        
        // 检测是否包含否定/嘲讽短语
        for phrase in negativeShortPhrases {
            if lowerComment.contains(phrase.lowercased()) {
                // 检查是困惑还是嘲讽
                return UserMessage.createMockeryMessage(content: comment)
            }
        }
        
        // 检测困惑表达
        for phrase in confusionPhrases {
            if lowerComment.contains(phrase.lowercased()) {
                return UserMessage.createConfusionMessage(content: comment)
            }
        }
        
        // 检测表面上是称赞但实际是讽刺的模式
        if sarcasticPatterns.contains(where: { lowerComment.contains($0.lowercased()) }) &&
           (comment.contains("?") || comment.contains("？") || 
            comment.contains("!") || comment.contains("！")) {
            return UserMessage.createMockeryMessage(content: comment)
        }
        
        // 检测是否是问题
        if comment.contains("?") || comment.contains("？") {
            return UserMessage(
                rawContent: comment,
                surfaceIntent: .question,
                deepIntent: .seekClarification,
                emotionalState: .curiosity,
                attentionFocus: extractCoreFocus(from: comment, fallback: "提问内容"),
                contextualTopic: extractTopicFromPost(originalPost)
            )
        }
        
        // 默认处理：可能是简单表达，需要结合上下文
        if comment.contains("我觉得") || comment.contains("我认为") {
            return UserMessage(
                rawContent: comment,
                surfaceIntent: .statement,
                deepIntent: .shareInsight,
                emotionalState: .neutral,
                attentionFocus: extractCoreFocus(from: comment, fallback: "个人观点"),
                contextualTopic: extractTopicFromPost(originalPost)
            )
        }
        
        // 其他情况
        return UserMessage(
            rawContent: comment,
            surfaceIntent: .statement, 
            deepIntent: .unknown,
            emotionalState: .neutral,
            attentionFocus: extractCoreFocus(from: comment, fallback: "未明确"),
            contextualTopic: extractTopicFromPost(originalPost)
        )
    }
    
    /**
     * 分析较长评论 - 可以进行更复杂的语义分析
     */
    private func analyzeLongerComment(_ comment: String, inContext originalPost: String) -> UserMessage {
        // [此处将在后续实现更详细的长评论分析逻辑]
        
        // 暂时返回基本分析结果
        return UserMessage(
            rawContent: comment,
            surfaceIntent: determineSurfaceIntent(comment),
            deepIntent: determineDeepIntent(comment),
            emotionalState: analyzeEmotionalState(comment),
            attentionFocus: extractCoreFocus(from: comment, fallback: "评论内容"),
            contextualTopic: extractTopicFromPost(originalPost)
        )
    }
    
    /**
     * 确定评论的表面意图
     */
    private func determineSurfaceIntent(_ comment: String) -> SurfaceIntent {
        if comment.contains("?") || comment.contains("？") || 
           comment.contains("吗") || comment.contains("呢") ||
           comment.contains("如何") || comment.contains("为什么") {
            return .question
        }
        
        if comment.contains("!") || comment.contains("！") {
            return .exclamation
        }
        
        if comment.contains("请") || comment.contains("应该") ||
           comment.contains("必须") || comment.contains("要") {
            return .command
        }
        
        return .statement
    }
    
    /**
     * 确定评论的深层意图
     */
    private func determineDeepIntent(_ comment: String) -> DeepIntent {
        // [此处将在后续完善]
        return .unknown
    }
    
    /**
     * 分析评论的情感状态
     */
    private func analyzeEmotionalState(_ comment: String) -> EmotionalState {
        // [此处将在后续完善]
        return .neutral
    }
    
    /**
     * 从评论中提取核心关注点
     */
    private func extractCoreFocus(from comment: String, fallback: String) -> String {
        // [此处将在后续完善]
        return fallback
    }
    
    /**
     * 从原帖中提取话题
     */
    private func extractTopicFromPost(_ post: String) -> String {
        // [此处将在后续完善]
        return "原帖主题"
    }
}

// MARK: - 对话历史记忆网络

/**
 * 对话节点类型枚举
 */
enum DialogueNodeType {
    case userComment          // 用户评论
    case characterResponse    // 角色回复
    case contentReference     // 内容引用（原帖或其他相关内容）
}

/**
 * 对话连接类型枚举，描述节点间的关系
 */
enum DialogueConnectionType {
    case reply                // 直接回复
    case reference            // 引用
    case continuation         // 延续前一个话题
    case topicShift           // 话题转换
    case contradiction        // 前后矛盾
    case clarification        // 澄清
    case elaboration          // 扩展说明
}

/**
 * 对话节点，表示对话历史中的一个点
 */
class DialogueNode {
    let id: UUID
    let type: DialogueNodeType
    let content: String
    let speaker: String
    let timestamp: Date
    var userMessage: UserMessage?
    var characterTraits: CharacterTraits?
    var sentiment: Double
    
    // 节点连接，表示与其他节点的关系
    var connections: [DialogueConnection] = []
    
    init(type: DialogueNodeType, content: String, speaker: String, 
         sentiment: Double = 0.0, userMessage: UserMessage? = nil, 
         characterTraits: CharacterTraits? = nil) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.speaker = speaker
        self.timestamp = Date()
        self.sentiment = sentiment
        self.userMessage = userMessage
        self.characterTraits = characterTraits
    }
    
    // 添加到另一个节点的连接
    func addConnection(to node: DialogueNode, type: DialogueConnectionType, strength: Double = 1.0) {
        let connection = DialogueConnection(source: self, target: node, type: type, strength: strength)
        connections.append(connection)
    }
    
    // 检查是否与特定节点有连接
    func isConnected(to node: DialogueNode) -> Bool {
        return connections.contains { $0.target.id == node.id }
    }
}

/**
 * 对话连接，表示两个对话节点之间的关系
 */
class DialogueConnection {
    let id: UUID
    let source: DialogueNode
    let target: DialogueNode
    let type: DialogueConnectionType
    let timestamp: Date
    let strength: Double  // 连接强度：0-1
    
    init(source: DialogueNode, target: DialogueNode, type: DialogueConnectionType, strength: Double = 1.0) {
        self.id = UUID()
        self.source = source
        self.target = target
        self.type = type
        self.timestamp = Date()
        self.strength = strength
    }
}

/**
 * 对话图，表示整个对话历史的网络结构
 */
class DialogueGraph {
    private var nodes: [DialogueNode] = []
    private var rootNode: DialogueNode?  // 对话的起始节点（通常是原帖）
    
    // 添加根节点（原帖）
    func setRoot(content: String, author: String) {
        let root = DialogueNode(type: .contentReference, content: content, speaker: author)
        self.rootNode = root
        self.nodes.append(root)
    }
    
    // 添加用户评论
    func addUserComment(content: String, username: String, userMessage: UserMessage, replyTo nodeId: UUID? = nil) -> DialogueNode {
        let node = DialogueNode(
            type: .userComment, 
            content: content, 
            speaker: username,
            sentiment: userMessage.emotionalState.direction,
            userMessage: userMessage
        )
        
        nodes.append(node)
        
        // 如果指定了回复的节点，建立连接
        if let replyToId = nodeId, let targetNode = findNode(by: replyToId) {
            node.addConnection(to: targetNode, type: .reply)
        } else if let root = rootNode {
            // 否则假设是回复原帖
            node.addConnection(to: root, type: .reply)
        }
        
        return node
    }
    
    // 添加角色回复
    func addCharacterResponse(content: String, character: String, traits: CharacterTraits, 
                             sentiment: Double, replyTo nodeId: UUID) -> DialogueNode {
        let node = DialogueNode(
            type: .characterResponse, 
            content: content, 
            speaker: character,
            sentiment: sentiment,
            characterTraits: traits
        )
        
        nodes.append(node)
        
        // 建立与被回复评论的连接
        if let targetNode = findNode(by: nodeId) {
            node.addConnection(to: targetNode, type: .reply)
        }
        
        return node
    }
    
    // 查找特定节点
    func findNode(by id: UUID) -> DialogueNode? {
        return nodes.first { $0.id == id }
    }
    
    // 获取与特定用户的对话历史
    func getInteractionHistory(with username: String) -> [DialogueNode] {
        return nodes.filter { $0.speaker == username || $0.connections.contains { conn in
            conn.target.speaker == username || conn.source.speaker == username
        }}
    }
    
    // 获取特定角色的所有回复
    func getCharacterResponses(for character: String) -> [DialogueNode] {
        return nodes.filter { $0.type == .characterResponse && $0.speaker == character }
    }
    
    // 分析用户与特定角色的情感趋势
    func analyzeSentimentTrend(between username: String, and character: String) -> Double {
        let userToCharacterNodes = nodes.filter { node in
            if node.speaker != username { return false }
            return node.connections.contains { conn in
                conn.target.speaker == character
            }
        }
        
        if userToCharacterNodes.isEmpty { return 0.0 }
        
        // 计算平均情感值
        let totalSentiment = userToCharacterNodes.reduce(0.0) { $0 + $1.sentiment }
        return totalSentiment / Double(userToCharacterNodes.count)
    }
    
    // 识别对话中最有争议的话题
    func identifyControversialTopics() -> [String] {
        var topicSentiments: [String: [Double]] = [:]
        
        for node in nodes {
            if let userMsg = node.userMessage, !userMsg.contextualTopic.isEmpty {
                if topicSentiments[userMsg.contextualTopic] == nil {
                    topicSentiments[userMsg.contextualTopic] = []
                }
                topicSentiments[userMsg.contextualTopic]?.append(node.sentiment)
            }
        }
        
        // 计算每个话题的情感差异
        var controversialTopics: [(topic: String, variance: Double)] = []
        for (topic, sentiments) in topicSentiments where sentiments.count > 1 {
            let mean = sentiments.reduce(0.0, +) / Double(sentiments.count)
            let variance = sentiments.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(sentiments.count)
            controversialTopics.append((topic, variance))
        }
        
        // 按争议性（方差）排序并返回话题
        return controversialTopics.sorted { $0.variance > $1.variance }.map { $0.topic }
    }
    
    // 分析用户与角色的互动类型
    func analyzeInteractionPattern(between username: String, and character: String) -> String {
        let interactions = getInteractionNodes(between: username, and: character)
        
        if interactions.isEmpty { return "无互动" }
        
        // 分析互动模式
        var questionCount = 0
        var disagreementCount = 0
        var agreementCount = 0
        var neutralCount = 0
        
        for node in interactions {
            if let userMsg = node.userMessage {
                if userMsg.surfaceIntent == .question {
                    questionCount += 1
                }
                
                switch userMsg.deepIntent {
                case .expressDisagreement, .expressDisappointment, .mockOrSarcasm:
                    disagreementCount += 1
                case .expressAgreement, .seekApproval:
                    agreementCount += 1
                default:
                    neutralCount += 1
                }
            }
        }
        
        // 确定主导互动模式
        let total = Double(interactions.count)
        let questionRatio = Double(questionCount) / total
        let disagreementRatio = Double(disagreementCount) / total
        let agreementRatio = Double(agreementCount) / total
        
        if questionRatio > 0.5 {
            return "求知型"
        } else if disagreementRatio > 0.4 {
            return "辩论型"
        } else if agreementRatio > 0.4 {
            return "认同型"
        } else {
            return "混合型"
        }
    }
    
    // 获取用户和角色之间的互动节点
    private func getInteractionNodes(between username: String, and character: String) -> [DialogueNode] {
        return nodes.filter { node in
            // 用户对角色的评论
            if node.speaker == username {
                return node.connections.contains { conn in
                    conn.target.speaker == character
                }
            }
            // 角色对用户的回复
            else if node.speaker == character {
                return node.connections.contains { conn in
                    conn.target.speaker == username
                }
            }
            return false
        }
    }
}

// MARK: - 回应生成策略层

/**
 * 回应生成策略协议
 */
protocol ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String
}

/**
 * 回应类型枚举，用于选择不同的回应策略
 */
enum ResponseType {
    case standard            // 标准回应
    case clarification       // 澄清回应
    case emotionalSupport    // 情感支持
    case substantive         // 实质性回应
    case counterpoint        // 对立观点
    case empathetic          // 共情回应
    case explorative         // 探索性回应
    case deferential         // 尊重/礼让
}

/**
 * 回应生成策略选择器
 */
class ResponseStrategySelector {
    // 根据用户消息和角色选择合适的策略
    func selectStrategy(for message: UserMessage, character: CharacterTraits) -> ResponseStrategy {
        // 处理幽默评论
        if message.deepIntent == .expressHumor {
            return DiplomaticResponseStrategy()
        }
        
        // 针对嘲讽或强烈负面情感
        if message.deepIntent == .mockOrSarcasm || 
          (message.emotionalState.direction < -0.7 && message.emotionalState.intensity > 0.6) {
            return DiplomaticResponseStrategy()
        }
        
        // 针对困惑
        if message.deepIntent == .expressConfusion || message.deepIntent == .seekClarification {
            return ClarificationStrategy()
        }
        
        // 针对直接提问
        if message.surfaceIntent == .question {
            return InformativeResponseStrategy()
        }
        
        // 针对表达观点
        if message.deepIntent == .shareInsight || message.deepIntent == .expressOpinion {
            if character.name == "孔子" || character.name == "达芬奇" {
                return ReflectiveResponseStrategy()
            } else {
                return EngagementResponseStrategy()
            }
        }
        
        // 默认策略
        return StandardResponseStrategy()
    }
}

/**
 * 标准回应策略
 */
class StandardResponseStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        // 基于角色特质选择适当的回应模式
        let responseFormats = [
            "我注意到你提到了\(message.attentionFocus)。从我的视角来看，%s",
            "\(message.attentionFocus)这个话题很有意思。作为\(character.name)，我认为%s",
            "关于\(message.attentionFocus)，如果从我的经验出发，%s",
            "你提到的\(message.attentionFocus)让我想到了%s"
        ]
        
        let formatTemplate = responseFormats.randomElement()!
        let coreResponse = generateCoreResponseContent(from: message, character: character, context: context)
        
        return String(format: formatTemplate, coreResponse)
    }
    
    // 生成回应的核心内容
    func generateCoreResponseContent(from message: UserMessage, character: CharacterTraits, context: String) -> String {
        // 这里将根据角色特征和对话内容生成回应
        // 实际项目中，这里会对接到GPT等AI模型进行内容生成
        return "这是一个值得探讨的观点。我倾向于从多角度思考这个问题。"
    }
}

/**
 * 澄清策略 - 用于回应困惑或不清晰的评论
 */
class ClarificationStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        let clarificationTemplates = [
            "我想可能有些误解。让我来解释一下\(message.attentionFocus)：%s",
            "你似乎对\(message.attentionFocus)感到困惑。我的观点其实是%s",
            "关于\(message.attentionFocus)，或许我可以用不同的方式表达：%s",
            "我理解你的疑惑。\(message.attentionFocus)确实是个复杂话题，%s"
        ]
        
        let template = clarificationTemplates.randomElement()!
        let explanation = generateClarificationContent(from: message, character: character, context: context)
        
        return String(format: template, explanation)
    }
    
    private func generateClarificationContent(from message: UserMessage, character: CharacterTraits, context: String) -> String {
        // 根据原始内容生成解释
        // 实际项目中会对接AI生成
        if character.name == "爱因斯坦" {
            return "在科学探索中，我们常常需要用比喻来解释复杂概念。我的意思是，观察者的心理状态会影响时间的主观体验。"
        } else if character.name == "莎士比亚" {
            return "我通过隐喻表达的是人类情感的复杂性。爱与痛苦、时间与感知，这些都是我作品中永恒的主题。"
        } else {
            return "我的核心观点是，真理往往存在于不同视角的交汇处，需要开放心态去理解。"
        }
    }
}

/**
 * 外交式回应策略 - 用于处理消极或挑战性评论
 */
class DiplomaticResponseStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        // 特殊处理：幽默评论
        if message.deepIntent == .expressHumor {
            return generateHumorResponse(message: message, character: character, context: context)
        }
        
        // 针对不同强度的负面评论使用不同策略
        if message.emotionalState.intensity > 0.8 {
            return generateDivertingResponse(character: character)
        } else {
            return generateAcknowledgingResponse(message: message, character: character)
        }
    }
    
    // 回应幽默或角色扮演类评论
    private func generateHumorResponse(message: UserMessage, character: CharacterTraits, context: String) -> String {
        let content = message.rawContent.lowercased()
        
        // 尝试检测是否在模仿或扮演某个角色
        if content.contains("我是") {
            // 判断是哪种"我是X"类型评论
            if content.contains("菜鸡") || content.contains("菜") || content.contains("废物") {
                switch character.name {
                case "爱因斯坦":
                    return "科学探索的道路上没有'菜鸡'，只有不断尝试的勇者。我做实验时也经常失败，但每次失败都是新发现的开始。"
                case "莎士比亚":
                    return "在我的戏剧中，每个角色都有自己的价值和意义，就像你一样。'菜鸡'也可以成为故事的主角，创造属于自己的精彩。"
                case "孔子":
                    return "子曰：'三人行，必有我师焉。'即使自认为'菜'，也有独特的见解值得他人学习。谦虚是美德，但也不可妄自菲薄。"
                default:
                    return "每个人都有不同阶段，'菜鸡'也是成长过程中的一部分。重要的是持续学习的态度。"
                }
            } else {
                // 其他"我是X"类型评论
                return "身份认同是一个有趣的话题。在我看来，无论你扮演什么角色，真实的自我才是最珍贵的。"
            }
        }
        
        // 对于其他幽默内容
        switch character.name {
        case "爱因斯坦":
            return "幽默是智慧的体现。我时常在严肃的物理学讨论中加入一些俏皮话，这让思考更加灵活。"
        case "莎士比亚":
            return "喜剧与悲剧往往只有一线之隔。你的幽默让我想起了我笔下的弄臣角色，他们用诙谐的言语道出深刻的真理。"
        case "孔子":
            return "子曰：'知之者不如好之者，好之者不如乐之者。'在学习中保持愉悦的心态，正是智慧的开始。"
        case "李白":
            return "哈哈，妙哉！酒逢知己千杯少，诗遇趣味万句来。人生得意须尽欢，何必拘泥于形式？"
        default:
            return "幽默是人类智慧的一种表现，感谢你带来的轻松时刻。"
        }
    }
    
    // 转移话题类回应（用于极端负面情况）
    private func generateDivertingResponse(character: CharacterTraits) -> String {
        let divertingResponses = [
            "\(character.name)曾说过，理智的对话是思想进步的基础。也许我们可以从更基本的问题开始讨论？",
            "这个话题确实容易引起情绪波动。作为\(character.name)，我更喜欢从证据和逻辑出发进行交流。",
            "有时候不同意见的碰撞是思想火花的源泉。不如我们先聊聊这个话题的其他方面？",
            "我理解你的情绪，如果我的表达方式有所不妥，我很愿意听取建设性的意见。"
        ]
        
        return divertingResponses.randomElement()!
    }
    
    // 承认并回应类（用于一般负面情况）
    private func generateAcknowledgingResponse(message: UserMessage, character: CharacterTraits) -> String {
        let acknowTemplates = [
            "我注意到你对\(message.attentionFocus)持不同看法。这很好，\(character.name)也常说不同视角能丰富我们的认知。%s",
            "你的反馈很直接，这正是有价值的交流方式。关于\(message.attentionFocus)，%s",
            "质疑精神是非常宝贵的。关于\(message.attentionFocus)，或许我们可以这样思考：%s"
        ]
        
        let template = acknowTemplates.randomElement()!
        let explanation = character.name == "爱因斯坦" ? 
                        "科学讨论本就应该基于质疑和验证。" :
                        "不同角度的思考总能带来更深入的理解。"
        
        return String(format: template, explanation)
    }
}

/**
 * 信息性回应策略 - 用于回答直接问题
 */
class InformativeResponseStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        let informativeTemplates = [
            "关于\(message.attentionFocus)的问题，根据我的了解，%s",
            "你问到了\(message.attentionFocus)。作为\(character.name)，我的观点是%s",
            "\(message.attentionFocus)这个问题很有洞见。%s",
            "从\(character.name)的角度看，\(message.attentionFocus)其实是%s"
        ]
        
        let template = informativeTemplates.randomElement()!
        let answer = generateAnswerContent(from: message, character: character, context: context)
        
        return String(format: template, answer)
    }
    
    private func generateAnswerContent(from message: UserMessage, character: CharacterTraits, context: String) -> String {
        // 根据问题类型和角色生成答案
        // 实际项目中会对接AI生成
        return "这涉及到多方面的考量。首先，我们需要理解基本原理；其次，要考虑实际应用场景；最后，还需思考潜在影响。"
    }
}

/**
 * 反思性回应策略 - 用于深层思考型角色（如孔子、达芬奇）
 */
class ReflectiveResponseStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        // 获取适合该角色的风格
        let reflectionStyle = getReflectionStyleForCharacter(character)
        
        let reflectiveTemplates = [
            "\(reflectionStyle)关于\(message.attentionFocus)，值得我们深思：%s",
            "\(message.attentionFocus)这个问题，\(reflectionStyle)我认为：%s",
            "\(reflectionStyle)当思考\(message.attentionFocus)时，我发现：%s"
        ]
        
        let template = reflectiveTemplates.randomElement()!
        let reflection = generateReflectionContent(from: message, character: character)
        
        return String(format: template, reflection)
    }
    
    private func getReflectionStyleForCharacter(_ character: CharacterTraits) -> String {
        switch character.name {
        case "孔子":
            return "子曰："
        case "达芬奇":
            return "从艺术与科学的交汇处，"
        default:
            return ""
        }
    }
    
    private func generateReflectionContent(from message: UserMessage, character: CharacterTraits) -> String {
        if character.name == "孔子" {
            return "君子求诸己，小人求诸人。在探索真理的道路上，我们首先要反省自身，然后才能理解外物。"
        } else if character.name == "达芬奇" {
            return "观察是知识的源泉。只有通过细致入微的观察，我们才能发现事物的本质，就像解剖一朵花，才能理解它的生长规律。"
        } else {
            return "深度思考需要超越表象，探寻事物的内在联系。"
        }
    }
}

/**
 * 参与性回应策略 - 用于活跃互动
 */
class EngagementResponseStrategy: ResponseStrategy {
    func generateResponse(to message: UserMessage,
                        with history: DialogueGraph,
                        as character: CharacterTraits,
                        in context: String) -> String {
        
        let engagementTemplates = [
            "你关于\(message.attentionFocus)的观点很有趣！让我分享一下我的看法：%s 你觉得如何？",
            "\(message.attentionFocus)确实值得讨论。\(character.name)视角下，%s 这让你想到了什么？",
            "我很欣赏你对\(message.attentionFocus)的见解。我的思考是：%s 我们可以进一步探讨这个观点吗？"
        ]
        
        let template = engagementTemplates.randomElement()!
        let content = generateEngagementContent(from: message, character: character)
        
        return String(format: template, content)
    }
    
    private func generateEngagementContent(from message: UserMessage, character: CharacterTraits) -> String {
        // 根据角色和消息内容生成互动性内容
        return "每个观点背后都蕴含着独特的思考路径，这种多元视角正是思想交流的魅力所在。"
    }
}

/**
 * 智能回复生成控制器
 */
class SmartResponseGenerator {
    private let analyzer = AdvancedCommentAnalyzer()
    private let strategySelector = ResponseStrategySelector()
    private let dialogueGraph = DialogueGraph()
    
    // 存储当前帖子的主题和上下文信息
    private var postContext: (topic: String, mood: String, theme: String)?
    
    // 初始化对话图，设置原帖为根节点，并分析原帖主题
    func initialize(with originalPost: Post) {
        dialogueGraph.setRoot(content: originalPost.content, author: originalPost.username)
        
        // 分析原帖内容，提取主题和情感
        postContext = analyzePostContext(originalPost.content)
    }
    
    // 分析帖子上下文
    private func analyzePostContext(_ content: String) -> (topic: String, mood: String, theme: String) {
        // 提取主题
        var topic = "未知话题"
        var mood = "中性"
        var theme = "一般讨论"
        
        // 基本主题检测
        if content.contains("爱情") || content.contains("喜欢") || content.contains("爱") {
            topic = "情感与爱"
            theme = "人类情感"
        } else if content.contains("科学") || content.contains("发现") || content.contains("理论") {
            topic = "科学探索"
            theme = "科学与知识"
        } else if content.contains("艺术") || content.contains("创作") || content.contains("美") {
            topic = "艺术创作"
            theme = "艺术与美学"
        } else if content.contains("哲学") || content.contains("思考") || content.contains("意义") {
            topic = "哲学思考"
            theme = "哲学与思想"
        } else if content.contains("历史") || content.contains("过去") || content.contains("古代") {
            topic = "历史回顾"
            theme = "历史与文明"
        } else {
            // 尝试从内容中提取可能的主题词
            let words = content.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
            let significantWords = words.filter { $0.count > 1 }
            
            if let longestWord = significantWords.max(by: { $0.count < $1.count }) {
                topic = longestWord
            } else if content.count > 10 {
                topic = String(content.prefix(10)) + "..."
            }
            
            // 尝试确定主题
            if content.contains("天气") || content.contains("自然") {
                theme = "自然与环境"
            } else if content.contains("生活") || content.contains("日常") {
                theme = "生活随想"
            }
        }
        
        // 情感分析
        if content.contains("高兴") || content.contains("快乐") || content.contains("幸福") || content.contains("开心") {
            mood = "积极"
        } else if content.contains("悲伤") || content.contains("难过") || content.contains("痛苦") || content.contains("忧郁") {
            mood = "消极"
        } else if content.contains("惊讶") || content.contains("震惊") || content.contains("好奇") {
            mood = "惊奇"
        } else if content.contains("思考") || content.contains("反思") || content.contains("沉思") {
            mood = "沉思"
        }
        
        return (topic, mood, theme)
    }
    
    // 生成回复
    func generateReply(to comment: String, by character: CharacterTraits, originalContent: String, commenterId: UUID) -> String {
        // 分析评论
        let userMessage = analyzer.analyzeComment(comment, inContext: originalContent)
        
        // 添加到对话历史
        let commentNode = dialogueGraph.addUserComment(
            content: comment,
            username: "当前用户",
            userMessage: userMessage,
            replyTo: commenterId
        )
        
        // 选择回应策略
        let strategy = strategySelector.selectStrategy(for: userMessage, character: character)
        
        // 获取原帖上下文，如果存在
        let context = postContext ?? analyzePostContext(originalContent)
        
        // 生成具有上下文关联的回应
        let response = generateContextualResponse(
            to: userMessage,
            strategy: strategy,
            character: character,
            originalContent: originalContent,
            context: context
        )
        
        // 计算回应的情感倾向
        let responseSentiment = userMessage.emotionalState.direction > 0 ? 0.5 : 0.0
        
        // 记录回应到对话图
        dialogueGraph.addCharacterResponse(
            content: response,
            character: character.name,
            traits: character,
            sentiment: responseSentiment,
            replyTo: commentNode.id
        )
        
        return response
    }
    
    // 生成具有上下文关联的回应
    private func generateContextualResponse(
        to message: UserMessage,
        strategy: ResponseStrategy,
        character: CharacterTraits,
        originalContent: String,
        context: (topic: String, mood: String, theme: String)
    ) -> String {
        
        // 从角色特点中提取相关兴趣和专长
        let relevantInterests = character.primaryInterests.filter { interest in
            originalContent.lowercased().contains(interest.lowercased()) ||
            message.rawContent.lowercased().contains(interest.lowercased()) ||
            context.topic.lowercased().contains(interest.lowercased()) ||
            context.theme.lowercased().contains(interest.lowercased())
        }
        
        // 确定回应的关联点
        let connectionPoint = relevantInterests.isEmpty ? 
                             context.theme : 
                             relevantInterests.first!
        
        // 基于角色特点生成特有的过渡短语
        let transitionPhrase = generateCharacteristicTransition(for: character, topic: connectionPoint)
        
        // 基本回应
        let baseResponse = strategy.generateResponse(
            to: message,
            with: dialogueGraph,
            as: character,
            in: originalContent
        )
        
        // 如果是短评论或情感强烈的评论，不添加过渡语
        if message.rawContent.count < 10 || message.emotionalState.intensity > 0.8 {
            return baseResponse
        }
        
        // 随机决定是否添加上下文关联
        if Bool.random(probability: 0.75) {
            // 组合上下文关联和基本回应
            return "\(transitionPhrase) \(baseResponse)"
        } else {
            return baseResponse
        }
    }
    
    // 基于角色特点生成特有的过渡短语
    private func generateCharacteristicTransition(for character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            let phrases = [
                "这个帖子让我想起了相对论中的一个概念。关于\(topic)，",
                "从科学的角度看这个话题，\(topic)其实是时空结构的一种表现。",
                "有意思的讨论！这让我联想到了量子力学中的不确定性。在\(topic)这个问题上，",
                "如果我们用思想实验来考虑\(topic)，会发现一些有趣的现象。"
            ]
            return phrases.randomElement()!
            
        case "莎士比亚":
            let phrases = [
                "这篇文章如同我剧作中的一幕。关于\(topic)，",
                "人生如戏，这个\(topic)的讨论正如《哈姆雷特》中的一场独白。",
                "读到你的评论，我仿佛看到了戏剧中角色的心灵挣扎。在\(topic)的问题上，",
                "这让我想起了《暴风雨》中的一句台词。谈到\(topic)时，"
            ]
            return phrases.randomElement()!
            
        case "达芬奇":
            let phrases = [
                "作为艺术与科学的探索者，我看\(topic)这个话题时会同时考虑形式与功能。",
                "这个讨论激发了我的好奇心。关于\(topic)，我会从解剖其本质开始。",
                "如同我在素描本中记录自然观察一样，这个\(topic)的话题需要细致的分析。",
                "我认为\(topic)是艺术与科学交融的绝佳例证。"
            ]
            return phrases.randomElement()!
            
        case "孔子":
            let phrases = [
                "子曰：学而时习之，不亦说乎？关于\(topic)这个问题，",
                "温故而知新，可以为师矣。在探讨\(topic)时，我们应当回顾古人智慧。",
                "君子和而不同。在\(topic)这个话题上，不同见解都值得尊重。",
                "中庸之道适用于\(topic)的讨论。我认为，"
            ]
            return phrases.randomElement()!
            
        case "牛顿":
            let phrases = [
                "根据我的观察和实验，\(topic)这个现象可以用基本原理解释。",
                "这个讨论让我想起了万有引力定律的发现过程。关于\(topic)，",
                "作为自然哲学家，我认为\(topic)应该用数学语言来描述。",
                "如果我们应用科学方法来研究\(topic)，会发现有趣的规律。"
            ]
            return phrases.randomElement()!
            
        case "李白":
            let phrases = [
                "举杯邀明月，对影成三人。这\(topic)之事，让我诗兴大发。",
                "仰天大笑出门去，我辈岂是蓬蒿人！谈到\(topic)，我心潮澎湃。",
                "人生得意须尽欢，莫使金樽空对月。这\(topic)之论，令我感慨万千。",
                "飞流直下三千尺，疑是银河落九天。这\(topic)如同壮丽的自然景观，让我想到："
            ]
            return phrases.randomElement()!
            
        default:
            return "关于\(topic)这个话题，"
        }
    }
}

// MARK: - 系统集成

/**
 * 集成智能回应系统
 */
extension PostViewModel {
    /**
     * 使用新的智能回应系统生成回复
     */
    func generateEnhancedResponseToComment(_ comment: String, postIndex: Int, commentIndex: Int, characterID: String) -> String {
        // 确保索引有效
        guard postIndex >= 0, postIndex < posts.count else {
            print("错误: 无效的帖子索引 \(postIndex)")
            return "我需要更多信息来回应这个评论。"
        }
        
        let post = posts[postIndex]
        let originalContent = post.content
        
        // 获取角色名称
        let characterName = getCharacterNameById(characterID)
        guard !characterName.isEmpty else {
            print("错误: 无效的角色ID \(characterID)")
            return "作为一个思考者，我发现你的观点很有深度。"
        }
        
        print("⚡️ 基于本质生成器: 开始为角色'\(characterName)'生成回复")
        
        // 初始化基于本质的回复生成器
        let essenceGenerator = EssenceBasedResponseGenerator()
        
        // 从原帖中提取上下文信息
        let postContext = extractPostContext(originalContent)
        print("📊 原帖上下文: 主题=\(postContext.topic), 情绪=\(postContext.mood), 主旨=\(postContext.theme)")
        
        // 生成基于角色本质的回复
        let response = essenceGenerator.generateResponse(
            comment: comment,
            characterName: characterName,
            originalPost: originalContent,
            postContext: postContext
        )
        

        return response
    }
    
    /**
     * 获取角色特性
     */
    func getCharacterTraitsById(_ characterID: String) -> CharacterTraits? {
        // 根据角色ID获取特性
        let characterName = getCharacterNameById(characterID)
        return getCharacterTraits(for: characterName)
    }
}

// MARK: - 更新评论处理函数

extension PostViewModel {
    /**
     * 添加使用新系统的发送评论回复函数
     */
    func sendSmartCommentResponse(postIndex: Int, commentIndex: Int, characterID: String) {
        // 验证索引
        guard postIndex >= 0, postIndex < posts.count else {
            print("错误: 帖子索引无效 \(postIndex)")
            return
        }
        
        guard commentIndex >= 0, commentIndex < posts[postIndex].comments.count else {
            print("错误: 评论索引无效 \(commentIndex)")
            return
        }
        
        // 获取被回复的评论
        let originalComment = posts[postIndex].comments[commentIndex]
        print("正在回复评论: '\(originalComment.content)'")
        
        // 获取角色名称
        let characterName = getCharacterNameById(characterID)
        guard !characterName.isEmpty else {
            print("错误: 无效的角色ID \(characterID)")
            return
        }
        
        print("开始使用基于角色本质(\(characterName))生成回复...")
        
        // 获取原帖内容
        let originalPost = posts[postIndex].content
        print("原帖内容: '\(String(originalPost.prefix(50)))...'")
        
        // 使用智能系统生成回复内容
        let responseContent = generateEnhancedResponseToComment(
            originalComment.content,
            postIndex: postIndex,
            commentIndex: commentIndex,
            characterID: characterID
        )
        
        print("生成的角色本质回复: '\(String(responseContent.prefix(50)))...'")
        
        // 创建回复评论
        let responseComment = CommentModel(
            id: UUID(),
            username: characterName,
            content: responseContent,
            timestamp: Date(),
            avatarName: getAvatarForCharacter(characterName),
            isVirtualCharacter: true,
            characterID: characterID,
            replyTo: originalComment.username
        )
        
        // 添加回复到评论列表
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.0...2.0)) { [weak self] in
            guard let self = self else {
                print("错误: self引用已释放，无法添加回复")
                return
            }
            self.posts[postIndex].comments.append(responseComment)
            print("本质驱动回复已添加到评论列表")
        }
    }
    
    /**
     * 使用新系统的发送评论函数
     */
    func sendSmartComment(postIndex: Int, content: String) {
        // 验证索引有效性
        guard postIndex >= 0, postIndex < posts.count else {
            print("错误: 帖子索引无效 \(postIndex)")
            return
        }
        
        // 创建用户评论
        let userComment = CommentModel(
            id: UUID(),
            username: "当前用户",
            content: content,
            timestamp: Date(),
            avatarName: "user_avatar",
            isVirtualCharacter: false,
            characterID: nil
        )
        
        // 添加评论到帖子
        posts[postIndex].comments.append(userComment)
        
        // 检查是否需要让虚拟角色回复该评论
        let post = posts[postIndex]
        
        // 如果用户评论直接回复帖子作者，让作者回复
        if let authorCharacterId = getCharacterIdByName(post.username) {
            // 随机决定是否回复
            if Bool.random(probability: 0.8) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.0...4.0)) { [weak self] in
                    guard let self = self else { return }
                    self.sendSmartCommentResponse(
                        postIndex: postIndex,
                        commentIndex: self.posts[postIndex].comments.count - 1,
                        characterID: authorCharacterId
                    )
                }
            }
        }
    }
    
    /**
     * 使用新系统的处理评论回复
     */
    func handleSmartCommentReply(postIndex: Int, commentIndex: Int, replyContent: String) {
        // 验证索引有效
        guard postIndex >= 0, postIndex < posts.count,
              commentIndex >= 0, commentIndex < posts[postIndex].comments.count else {
            print("错误: 无效的帖子或评论索引")
            return
        }
        
        // 获取要回复的评论
        let originalComment = posts[postIndex].comments[commentIndex]
        
        // 创建用户回复评论
        let userReply = CommentModel(
            id: UUID(),
            username: "当前用户",
            content: replyContent,
            timestamp: Date(),
            avatarName: "user_avatar",
            isVirtualCharacter: false,
            characterID: nil,
            replyTo: originalComment.username
        )
        
        // 添加用户回复
        posts[postIndex].comments.append(userReply)
        
        // 如果原评论来自虚拟角色，让同一角色回复用户
        if originalComment.isVirtualCharacter, let characterID = originalComment.characterID {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.0...4.0)) { [weak self] in
                guard let self = self else { return }
                self.sendSmartCommentResponse(
                    postIndex: postIndex,
                    commentIndex: self.posts[postIndex].comments.count - 1,
                    characterID: characterID
                )
            }
        }
        // 否则，如果回复的是原帖作者，也考虑让作者回复
        else if originalComment.username == posts[postIndex].username {
            let post = posts[postIndex]
            if let authorCharacterId = getCharacterIdByName(post.username), Bool.random(probability: 0.7) {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5.0)) { [weak self] in
                    guard let self = self else { return }
                    self.sendSmartCommentResponse(
                        postIndex: postIndex,
                        commentIndex: self.posts[postIndex].comments.count - 1,
                        characterID: authorCharacterId
                    )
                }
            }
        }
    }
}

/**
 * 发送评论回应
 * @param postIndex 帖子索引
 * @param commentIndex 评论索引
 * @param characterID 角色ID
 */
func sendCommentResponse(postIndex: Int, commentIndex: Int, characterID: String) {
    print("发送评论回应: postIndex=\(postIndex), commentIndex=\(commentIndex), characterID=\(characterID)")
    
    // 使用新的智能回复系统
    sendSmartCommentResponse(postIndex: postIndex, commentIndex: commentIndex, characterID: characterID)
}

/**
 * 处理评论回复
 * @param postIndex 帖子索引
 * @param commentIndex 评论索引
 * @param content 回复内容
 */
func handleCommentReply(postIndex: Int, commentIndex: Int, content: String) {
    print("处理评论回复: postIndex=\(postIndex), commentIndex=\(commentIndex), content=\(content)")
    
    // 使用新的智能回复系统处理评论回复
    handleSmartCommentReply(postIndex: postIndex, commentIndex: commentIndex, replyContent: content)
}

/**
 * 发送评论
 * @param postIndex 帖子索引
 * @param content 评论内容
 */
func sendComment(postIndex: Int, content: String) {
    print("发送评论: postIndex=\(postIndex), content=\(content)")
    
    // 使用新的智能回复系统发送评论
    sendSmartComment(postIndex: postIndex, content: content)
}

// MARK: - 基于角色本质的回复生成器

/**
 * 基于角色本质的回复生成器
 * 这个类负责根据角色的本质特征生成个性化回复
 */
class EssenceBasedResponseGenerator {
    private let analyzer = AdvancedCommentAnalyzer()
    private let strategySelector = ResponseStrategySelector()
    
    /**
     * 生成回复
     * @param comment 评论内容
     * @param characterName 角色名称
     * @param originalPost 原帖内容
     * @param postContext 帖子上下文
     * @return 生成的回复
     */
    func generateResponse(
        comment: String,
        characterName: String,
        originalPost: String,
        postContext: (topic: String, mood: String, theme: String)
    ) -> String {
        print("🔍 开始为'\(characterName)'分析评论: '\(comment)'")
        
        // 获取角色特征
        guard let character = getCharacterTraits(for: characterName) else {
            print("⚠️ 未找到角色'\(characterName)'的特征")
            return "这个观点很有趣，值得深入思考。"
        }
        
        // 处理短评论 (少于8个字符)
        if comment.count < 8 {
    
            return generateEssenceBasedBody(for: comment, character: character, postContext: postContext, originalPost: originalPost)
        }
        
        // 分析评论
        let userMessage = analyzer.analyzeComment(comment, inContext: originalPost)
        print("🧠 评论分析结果: 表层意图=\(userMessage.surfaceIntent), 深层意图=\(userMessage.deepIntent)")
        
        // 选择回应策略
        let strategy = strategySelector.selectStrategy(for: userMessage, character: character)
        print("⚙️ 选择的回应策略: \(type(of: strategy))")
        
        // 生成回复主体
        let responseBody = generateEssenceBasedBody(
            for: comment,
            character: character,
            userMessage: userMessage,
            strategy: strategy,
                postContext: postContext,
            originalPost: originalPost
        )
        
        // 添加角色签名（如果设置了使用签名）
        let finalResponse = character.usesSignature ? 
            "\(responseBody)\n\n\(character.signature)" : responseBody
            

        return finalResponse
    }
    
    /**
     * 生成基于角色本质的回复主体
     */
    private func generateEssenceBasedBody(
        for comment: String,
        character: CharacterTraits,
        userMessage: UserMessage? = nil,
        strategy: ResponseStrategy? = nil,
        postContext: (topic: String, mood: String, theme: String),
        originalPost: String
    ) -> String {
        // 处理短评论
        if comment.count < 8 {
            print("🔍 处理短评论: '\(comment)'")
            
            // 定义一些常见的短评论模式及对应回复
            let shortPatterns: [(pattern: String, response: String)] = [
                // 问候类
                ("你好", "你好！很高兴与你交流。作为\(character.name)，我对\(postContext.topic)这个话题很感兴趣。"),
                ("嗨", "你好！\(character.name)在此。\(postContext.theme)确实是个值得探讨的话题。"),
                ("哈喽", "你好啊！能在这里讨论\(postContext.topic)，我感到很开心。"),
                
                // 日常询问类
                ("在吗", "我在！作为\(character.name)，我随时准备讨论\(postContext.topic)。"),
                ("忙吗", "对于思考和交流，我从不觉得忙。\(postContext.theme)是我一直关注的领域。"),
                
                // 赞赏类
                ("赞", "谢谢你的赞赏！\(postContext.topic)确实值得我们深入探讨。"),
                ("支持", "感谢支持！作为\(character.name)，我希望能为\(postContext.theme)的讨论贡献更多见解。"),
                ("厉害", "谢谢夸奖！在\(postContext.topic)方面，我确实投入了不少心血。"),
                ("牛", "感谢肯定！在\(postContext.topic)领域，我确实有些独到见解。"),
                
                // 情感类
                ("哈哈", "看到你的笑容真好！\(postContext.topic)有时确实能带来愉快的心情。"),
                ("呵呵", "交流总是令人愉快的。关于\(postContext.topic)，你有什么特别的见解吗？"),
                ("哭了", "情感是人类最真实的表达。\(postContext.theme)确实常常触动人心。"),
                ("无语", "有时语言确实难以表达复杂的感受。\(postContext.topic)本身就是个值得深思的话题。"),
                
                // 负面评论类
                ("什么玩意", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                ("垃圾", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                ("废话", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                ("胡说", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                ("扯淡", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                ("瞎扯", generateNegativeShortCommentResponse(character: character, topic: postContext.topic)),
                
                // 特殊类
                ("666", "数字背后往往有深意。在\(postContext.topic)这个领域，精确和完美也是我所追求的。"),
                ("厉害了", "谢谢认可！在\(postContext.topic)方面，我确实有一些独特的见解。"),
                ("学到了", "知识的分享是最大的快乐。关于\(postContext.topic)，我很高兴能提供一些思考。"),
                ("涨知识", "学习是终身的事业。\(postContext.theme)这个领域确实有很多值得探索的内容。")
            ]
            
            // 尝试匹配短评论模式
            for (pattern, response) in shortPatterns {
                if comment.contains(pattern) {
                    print("✅ 匹配到短评论模式: '\(pattern)'")
                    return response
                }
            }
            
            // 如果没有匹配到特定模式，根据评论类型生成通用回复
        let lowerComment = comment.lowercased()
        
            // 分析短评论的可能意图
        if comment.contains("?") || comment.contains("？") {
                // 问题类短评论
                return generateQuestionShortCommentResponse(character: character, topic: postContext.topic)
        } else if comment.contains("!") || comment.contains("！") {
                // 感叹类短评论
                return generateExclamationShortCommentResponse(character: character, topic: postContext.topic)
        } else if lowerComment.contains("谢谢") || lowerComment.contains("感谢") {
                // 感谢类短评论
                return generateThankfulShortCommentResponse(character: character, topic: postContext.topic)
        } else {
                // 其他短评论 - 根据角色个性生成
                return generateCharacterSpecificShortResponse(character: character, topic: postContext.topic, theme: postContext.theme)
            }
        }
        
        // 处理常规评论
        if let userMessage = userMessage, let strategy = strategy {
            print("🧠 处理常规评论，使用策略: \(type(of: strategy))")
            
            // 创建简单的对话图用于生成回复
            let dialogueGraph = DialogueGraph()
            dialogueGraph.setRoot(content: originalPost, author: "原帖作者")
            
            // 基于角色特点生成特有的过渡短语
            let connectionPoint = postContext.theme
            let transitionPhrase = generateCharacteristicTransition(for: character, topic: connectionPoint)
            
            // 基本回应
            let baseResponse = strategy.generateResponse(
                to: userMessage,
                with: dialogueGraph,
                as: character,
                in: originalPost
            )
            
            // 如果是情感强烈的评论，不添加过渡语
            if userMessage.emotionalState.intensity > 0.8 {
                return baseResponse
            }
            
            // 随机决定是否添加上下文关联
            if Bool.random(probability: 0.75) {
                // 组合上下文关联和基本回应
                return "\(transitionPhrase) \(baseResponse)"
            } else {
                return baseResponse
            }
        }
        
        // 默认回复
        return "作为\(character.name)，我对\(postContext.topic)有着独特的见解。\(postContext.theme)是一个值得深入探讨的领域。"
    }
    
    // 基于角色特点生成特有的过渡短语
    private func generateCharacteristicTransition(for character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            let phrases = [
                "这个帖子让我想起了相对论中的一个概念。关于\(topic)，",
                "从科学的角度看这个话题，\(topic)其实是时空结构的一种表现。",
                "有意思的讨论！这让我联想到了量子力学中的不确定性。在\(topic)这个问题上，",
                "如果我们用思想实验来考虑\(topic)，会发现一些有趣的现象。"
            ]
            return phrases.randomElement()!
            
        case "莎士比亚":
            let phrases = [
                "这篇文章如同我剧作中的一幕。关于\(topic)，",
                "人生如戏，这个\(topic)的讨论正如《哈姆雷特》中的一场独白。",
                "读到你的评论，我仿佛看到了戏剧中角色的心灵挣扎。在\(topic)的问题上，",
                "这让我想起了《暴风雨》中的一句台词。谈到\(topic)时，"
            ]
            return phrases.randomElement()!
            
        case "孔子":
            let phrases = [
                "子曰：学而时习之，不亦说乎？关于\(topic)这个问题，",
                "温故而知新，可以为师矣。在探讨\(topic)时，我们应当回顾古人智慧。",
                "君子和而不同。在\(topic)这个话题上，不同见解都值得尊重。",
                "中庸之道适用于\(topic)的讨论。我认为，"
            ]
            return phrases.randomElement()!
            
        case "李白":
            let phrases = [
                "举杯邀明月，对影成三人。这\(topic)之事，让我诗兴大发。",
                "仰天大笑出门去，我辈岂是蓬蒿人！谈到\(topic)，我心潮澎湃。",
                "人生得意须尽欢，莫使金樽空对月。这\(topic)之论，令我感慨万千。",
                "飞流直下三千尺，疑是银河落九天。这\(topic)如同壮丽的自然景观，让我想到："
            ]
            return phrases.randomElement()!
            
        default:
            return "关于\(topic)这个话题，"
        }
    }
    
    // 生成问题类短评论回复
    private func generateQuestionShortCommentResponse(character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            return "好问题！科学探索就是从问题开始的。关于\(topic)，我认为需要从多角度思考，尤其是从时空关系的视角。"
        case "莎士比亚":
            return "问题是思考的源泉！正如哈姆雷特所问的'生存还是毁灭'，关于\(topic)的问题也值得深思。"
        case "孔子":
            return "子曰：'不耻下问。'提问是智慧的开始。关于\(topic)，我认为应当先明理，后求知。"
        case "李白":
            return "天地之大，何处问答？关于\(topic)，且听我道来：问者如登山涉水，答者如指点迷津。"
        default:
            return "这是个好问题！关于\(topic)，我有一些独特的见解可以分享。"
        }
    }
    
    // 生成感叹类短评论回复
    private func generateExclamationShortCommentResponse(character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            return "你的热情让我想起了发现相对论时的兴奋！\(topic)确实是个令人着迷的领域，值得我们深入探索。"
        case "莎士比亚":
            return "激情是创作的源泉！正如我在剧作中所表达的，情感的力量能够超越理性的边界。\(topic)确实值得这样的情感投入。"
        case "孔子":
            return "子曰：'知之者不如好之者，好之者不如乐之者。'你对\(topic)的热忱正是学习的最高境界。"
        case "李白":
            return "仰天大笑出门去，我辈岂是蓬蒿人！你的热情如同我对诗酒的挚爱，让\(topic)更加生动。"
        default:
            return "你的热情让我印象深刻！\(topic)确实值得这样的情感投入。"
        }
    }
    
    // 生成感谢类短评论回复
    private func generateThankfulShortCommentResponse(character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            return "不必客气！知识的分享是科学精神的体现。关于\(topic)，我很乐意继续探讨。"
        case "莎士比亚":
            return "感谢之情如同春风，温暖人心。能与你分享关于\(topic)的见解，是我的荣幸。"
        case "孔子":
            return "礼尚往来，感谢之情值得赞赏。关于\(topic)，我们可以继续切磋，共同进步。"
        case "李白":
            return "千金难买知己心，感谢相知。对\(topic)的讨论如同把酒言欢，令人陶醉。"
        default:
            return "不必客气！能与你讨论\(topic)是我的荣幸。"
        }
    }
    
    // 生成负面短评论回复
    private func generateNegativeShortCommentResponse(character: CharacterTraits, topic: String) -> String {
        switch character.name {
        case "爱因斯坦":
            return "批判性思考是科学进步的动力。也许我们可以从不同角度来看待\(topic)，找到更有建设性的讨论方式。"
        case "莎士比亚":
            return "在我的剧作中，角色常常通过冲突展现真实。你的直接表达让我想起了《李尔王》中的坦诚。或许我们可以更深入地讨论\(topic)的本质？"
        case "孔子":
            return "子曰：'君子和而不同。'对\(topic)有不同见解是正常的，但求同存异才是智者之道。"
        case "李白":
            return "文人相轻，自古有之。对\(topic)的看法各异，不妨畅所欲言，但求一醉解千愁。"
        default:
            return "我理解你可能持不同观点。关于\(topic)，或许我们可以从多角度进行更建设性的讨论。"
        }
    }
    
    // 根据角色生成特定的短评论回复
    private func generateCharacterSpecificShortResponse(character: CharacterTraits, topic: String, theme: String) -> String {
        switch character.name {
        case "爱因斯坦":
            return "简短的表达有时蕴含深刻的思考。关于\(topic)，我认为好奇心是最重要的驱动力。正如相对论所揭示的，看似简单的现象背后往往隐藏着复杂的规律。"
        case "莎士比亚":
            return "寥寥数语，胜过千言万语。正如我在作品中所写：'brevity is the soul of wit'（简洁是智慧的灵魂）。\(topic)这个主题，值得用诗意的语言来探索。"
        case "孔子":
            return "子曰：'不学礼，无以立。'简短的交流也是礼的体现。关于\(topic)，我相信'学而不思则罔，思而不学则殆'，需要理论与实践相结合。"
        case "李白":
            return "一言既出，驷马难追。短短几字，胜过长篇。对\(topic)，我有诗云：'人生得意须尽欢，莫使金樽空对月。'这\(theme)之道，不在多言，而在意境。"
        case "牛顿":
            return "简洁是自然法则的特征。关于\(topic)，我认为应当用数学语言来描述，寻找其背后的普适规律。"
        case "达芬奇":
            return "简约之中见真知。\(topic)如同我的素描，需要捕捉本质而非细节。艺术与科学的交汇处，往往是最简单的表达。"
        default:
            return "简短的评论往往引发深刻的思考。\(topic)确实值得我们深入探讨，尤其是从\(theme)的角度来看。"
        }
    }
}

extension PostViewModel {
    /**
     * 从帖子内容中提取上下文信息
     * @param content 帖子内容
     * @return 包含主题、情绪和主旨的元组
     */
    func extractPostContext(_ content: String) -> (topic: String, mood: String, theme: String) {
        // 提取主题
        var topic = "未知话题"
        var mood = "中性"
        var theme = "一般讨论"
        
        // 基本主题检测
        if content.contains("爱情") || content.contains("喜欢") || content.contains("爱") {
            topic = "情感与爱"
            theme = "人类情感"
        } else if content.contains("科学") || content.contains("发现") || content.contains("理论") {
            topic = "科学探索"
            theme = "科学与知识"
        } else if content.contains("艺术") || content.contains("创作") || content.contains("美") {
            topic = "艺术创作"
            theme = "艺术与美学"
        } else if content.contains("哲学") || content.contains("思考") || content.contains("意义") {
            topic = "哲学思考"
            theme = "哲学与思想"
        } else if content.contains("历史") || content.contains("过去") || content.contains("古代") {
            topic = "历史回顾"
            theme = "历史与文明"
        } else {
            // 尝试从内容中提取可能的主题词
            let words = content.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
            let significantWords = words.filter { $0.count > 1 }
            
            if let longestWord = significantWords.max(by: { $0.count < $1.count }) {
                topic = longestWord
            } else if content.count > 10 {
                topic = String(content.prefix(10)) + "..."
            }
            
            // 尝试确定主题
            if content.contains("天气") || content.contains("自然") {
                theme = "自然与环境"
            } else if content.contains("生活") || content.contains("日常") {
                theme = "生活随想"
            }
        }
        
        // 情感分析
        if content.contains("高兴") || content.contains("快乐") || content.contains("幸福") || content.contains("开心") {
            mood = "积极"
        } else if content.contains("悲伤") || content.contains("难过") || content.contains("痛苦") || content.contains("忧郁") {
            mood = "消极"
        } else if content.contains("惊讶") || content.contains("震惊") || content.contains("好奇") {
            mood = "惊奇"
        } else if content.contains("思考") || content.contains("反思") || content.contains("沉思") {
            mood = "沉思"
        }
        
        return (topic, mood, theme)
    }
}

/**
 * 生成增强的评论回复
 * @param comment 评论内容
 * @param postIndex 帖子索引
 * @param commentIndex 评论索引
 * @param characterID 角色ID
 * @return 生成的回复内容
 */
func generateEnhancedResponseToComment(
    _ comment: String,
    postIndex: Int,
    commentIndex: Int,
    characterID: String
) -> String {
    print("🔍 开始为角色ID=\(characterID)生成增强回复")
    
    // 获取原帖内容
    let originalContent = posts[postIndex].content
    
    // 获取角色名称
    let characterName = getCharacterNameById(characterID)
    if characterName.isEmpty {
        print("错误: 无效的角色ID \(characterID)")
        return "作为一个思考者，我发现你的观点很有深度。"
    }
    
    print("⚡️ 使用AI提示词系统: 开始为角色'\(characterName)'生成回复")
    
    // 获取最近的对话历史（如果有）
    var recentInteractions: [String] = []
    
    // 尝试获取最近的2-3条相关评论作为上下文
    let relevantComments = getRelevantComments(postIndex: postIndex, commentIndex: commentIndex, limit: 3)
    if !relevantComments.isEmpty {
        recentInteractions = relevantComments.map { "\($0.username): \($0.content)" }
    }
    
    // 使用新的AI提示词系统生成回复
    let response = AIPromptSystem.shared.generateResponse(
        to: comment,
        as: characterName,
        in: originalContent,
        recentInteractions: recentInteractions
    )
    
    
    return response
}

/**
 * 获取相关评论作为上下文
 */
private func getRelevantComments(postIndex: Int, commentIndex: Int, limit: Int) -> [CommentModel] {
    guard postIndex >= 0, postIndex < posts.count,
          commentIndex >= 0, commentIndex < posts[postIndex].comments.count else {
        return []
    }
    
    let currentComment = posts[postIndex].comments[commentIndex]
    var relevantComments: [CommentModel] = []
    
    // 如果当前评论是回复其他评论
    if let replyTo = currentComment.replyTo {
        // 查找被回复的评论
        if let originalComment = posts[postIndex].comments.first(where: { $0.username == replyTo }) {
            relevantComments.append(originalComment)
        }
    }
    
    // 添加当前评论
    relevantComments.append(currentComment)
    
    // 如果数量不足，添加同一帖子下的其他最近评论
    if relevantComments.count < limit {
        let otherComments = posts[postIndex].comments
            .filter { $0.id != currentComment.id && !relevantComments.contains(where: { $0.id == $1.id }) }
            .suffix(limit - relevantComments.count)
        
        relevantComments.append(contentsOf: otherComments)
    }
    
    return relevantComments
}