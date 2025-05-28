import Foundation

/**
 * 回复生成系统
 * 基于第一性原理的角色回复生成
 */
class ResponseGenerationSystem {
    // 单例模式
    static let shared = ResponseGenerationSystem()
    private init() {}
    
    // MARK: - 理解层
    
    /**
     * 分析用户评论
     * @param comment 用户评论
     * @param postContent 帖子内容
     * @return 评论分析结果
     */
    func analyzeComment(_ comment: String, in postContent: String) -> CommentAnalysis {
        print("🔍 开始分析评论: '\(comment)'")
        
        // 检查是否为短评论
        if comment.count < 15 {
            print("📏 检测到短评论，使用专门的短评论分析")
            return analyzeShortComment(comment, in: postContent)
        }
        
        // 提取评论核心内容
        let core = extractCommentCore(comment)
        
        // 分析评论意图
        let intent = analyzeIntent(comment)
        
        // 分析情感倾向
        let sentiment = analyzeSentiment(comment)
        
        // 提取关键词
        let keywords = extractKeywords(from: comment)
        
        // 提取帖子上下文
        let postContext = analyzePostContext(postContent)
        
        print("✅ 评论分析完成: 核心='\(core)', 意图=\(intent), 情感=\(sentiment)")
        
        return CommentAnalysis(
            originalComment: comment,
            core: core,
            intent: intent,
            sentiment: sentiment,
            keywords: keywords,
            postContext: postContext
        )
    }
    
    /**
     * 分析短评论
     */
    private func analyzeShortComment(_ comment: String, in postContent: String) -> CommentAnalysis {
        print("🔍 开始分析短评论: '\(comment)'")
        
        // 短评论直接使用原文作为核心
        let core = comment
        
        // 提取帖子上下文
        let postContext = analyzePostContext(postContent)
        
        // 分析短评论意图
        let intent = analyzeShortCommentIntent(comment)
        print("📝 短评论意图: \(intent)")
        
        // 分析短评论情感
        let sentiment = analyzeShortCommentSentiment(comment)
        print("😊 短评论情感: \(sentiment)")
        
        // 短评论可能没有明显关键词，使用整个评论作为关键词
        let keywords = [comment]
        
        print("✅ 短评论分析完成")
        
        return CommentAnalysis(
            originalComment: comment,
            core: core,
            intent: intent,
            sentiment: sentiment,
            keywords: keywords,
            postContext: postContext
        )
    }
    
    /**
     * 分析短评论意图
     */
    private func analyzeShortCommentIntent(_ comment: String) -> CommentIntent {
        let lowerComment = comment.lowercased()
        
        // 问候类
        if ["你好", "嗨", "哈喽", "嘿", "hi", "hello"].contains(where: lowerComment.contains) {
            return .greeting
        }
        
        // 提问类
        if comment.contains("?") || comment.contains("？") || ["在吗", "忙吗", "为啥", "为何"].contains(where: lowerComment.contains) {
            return .question
        }
        
        // 赞赏类
        if ["赞", "好", "棒", "支持", "厉害", "牛", "666"].contains(where: lowerComment.contains) {
            return .praise
        }
        
        // 情感类
        if ["哈哈", "呵呵", "嘻嘻", "笑死", "哭了"].contains(where: lowerComment.contains) {
            return .emotion
        }
        
        // 否定类
        if ["不对", "错了", "胡说", "扯淡", "废话", "垃圾", "什么玩意"].contains(where: lowerComment.contains) {
            return .negative
        }
        
        // 幽默类
        if ["逗", "搞笑", "有趣", "好玩"].contains(where: lowerComment.contains) {
            return .humor
        }
        
        // 感谢类
        if ["谢谢", "感谢", "多谢"].contains(where: lowerComment.contains) {
            return .gratitude
        }
        
        // 认同类
        if ["对的", "没错", "同意", "是的", "+1"].contains(where: lowerComment.contains) {
            return .agreement
        }
        
        // 默认为简短表达
        return .shortExpression
    }
    
    /**
     * 分析短评论情感
     */
    private func analyzeShortCommentSentiment(_ comment: String) -> CommentSentiment {
        let lowerComment = comment.lowercased()
        
        // 积极情感词
        let positiveWords = ["好", "赞", "棒", "厉害", "牛", "支持", "喜欢", "爱", "谢谢", "哈哈", "666"]
        
        // 消极情感词
        let negativeWords = ["不", "垃圾", "废话", "差", "烂", "什么玩意", "胡说", "扯淡", "错"]
        
        // 检查是否包含积极词
        for word in positiveWords {
            if lowerComment.contains(word) {
                return .positive
            }
        }
        
        // 检查是否包含消极词
        for word in negativeWords {
            if lowerComment.contains(word) {
                return .negative
            }
        }
        
        // 默认为中性
        return .neutral
    }
    
    /**
     * 提取评论核心内容
     */
    private func extractCommentCore(_ comment: String) -> String {
        // 移除常见的无意义开头
        var processedComment = comment
        let commonPrefixes = ["我觉得", "我认为", "我想", "我感觉", "我看", "我说"]
        
        for prefix in commonPrefixes {
            if processedComment.hasPrefix(prefix) {
                processedComment = String(processedComment.dropFirst(prefix.count))
                break
            }
        }
        
        // 如果评论很短，直接返回整个评论
        if processedComment.count < 15 {
            return processedComment
        }
        
        // 尝试提取核心句子
        let sentences = processedComment.components(separatedBy: ["。", "！", "？", "\n"]).filter { !$0.isEmpty }
        if let firstSentence = sentences.first, firstSentence.count < 30 {
            return firstSentence
        } else if !sentences.isEmpty {
            // 如果第一句太长，取前半部分
            let firstSentence = sentences[0]
            let halfLength = firstSentence.count / 2
            let index = firstSentence.index(firstSentence.startIndex, offsetBy: min(halfLength, 20))
            return String(firstSentence[..<index]) + "..."
        }
        
        // 如果无法分句，取前20个字符
        let endIndex = processedComment.index(processedComment.startIndex, offsetBy: min(processedComment.count, 20))
        return String(processedComment[..<endIndex]) + (processedComment.count > 20 ? "..." : "")
    }
    
    /**
     * 分析评论意图
     */
    private func analyzeIntent(_ comment: String) -> CommentIntent {
        let lowerComment = comment.lowercased()
        
        // 判断是否是问题
        if comment.contains("?") || comment.contains("？") ||
           lowerComment.contains("为什么") || lowerComment.contains("怎么") || 
           lowerComment.contains("如何") || lowerComment.contains("是不是") {
            return .question
        }
        
        // 判断是否是感谢
        if lowerComment.contains("谢谢") || lowerComment.contains("感谢") {
            return .gratitude
        }
        
        // 判断是否是认同
        if lowerComment.contains("同意") || lowerComment.contains("赞同") || 
           lowerComment.contains("支持") || lowerComment.contains("没错") {
            return .agreement
        }
        
        // 判断是否是反对
        if lowerComment.contains("不同意") || lowerComment.contains("反对") || 
           lowerComment.contains("不赞同") || lowerComment.contains("错") {
            return .disagreement
        }
        
        // 判断是否是幽默
        if lowerComment.contains("哈哈") || lowerComment.contains("笑") || 
           lowerComment.contains("逗") || lowerComment.contains("搞笑") {
            return .humor
        }
        
        // 判断是否是负面评价
        if lowerComment.contains("垃圾") || lowerComment.contains("废话") || 
           lowerComment.contains("无聊") || lowerComment.contains("什么玩意") {
            return .negative
        }
        
        // 判断是否是简短表达
        if comment.count < 8 {
            return .shortExpression
        }
        
        // 默认为分享观点
        return .sharing
    }
    
    /**
     * 分析情感倾向
     */
    private func analyzeSentiment(_ comment: String) -> CommentSentiment {
        let lowerComment = comment.lowercased()
        
        // 积极情感词
        let positiveWords = ["喜欢", "好", "棒", "赞", "支持", "感谢", "开心", "快乐"]
        
        // 消极情感词
        let negativeWords = ["不喜欢", "差", "烂", "讨厌", "无聊", "废话", "垃圾"]
        
        // 计算情感得分
        var score = 0
        
        // 检查积极词
        for word in positiveWords {
            if lowerComment.contains(word) {
                score += 1
            }
        }
        
        // 检查消极词
        for word in negativeWords {
            if lowerComment.contains(word) {
                score -= 1
            }
        }
        
        // 检查否定词，可能会反转情感
        let negations = ["不", "没", "别", "无", "非"]
        for negation in negations {
            if lowerComment.contains(negation) {
                score *= -1
                break
            }
        }
        
        // 判断情感倾向
        if score > 0 {
            return .positive
        } else if score < 0 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    /**
     * 提取关键词
     */
    private func extractKeywords(from text: String) -> [String] {
        // 分词
        let words = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        // 过滤停用词
        let stopWords = ["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "这", "那", "你", "我们", "他", "她", "它", "这个", "那个"]
        let filteredWords = words.filter { word in
            word.count >= 2 && !stopWords.contains(word)
        }
        
        // 返回前5个关键词
        return Array(filteredWords.prefix(5))
    }
    
    /**
     * 分析帖子上下文
     */
    private func analyzePostContext(_ content: String) -> PostContext {
        // 提取主题
        var topic = "未知话题"
        var emotion = "中性"
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
        } else {
            // 尝试从内容中提取可能的主题词
            let words = content.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
            let significantWords = words.filter { $0.count > 1 }
            
            if let longestWord = significantWords.max(by: { $0.count < $1.count }) {
                topic = longestWord
            }
        }
        
        // 情感分析
        if content.contains("高兴") || content.contains("快乐") || content.contains("幸福") {
            emotion = "积极"
        } else if content.contains("悲伤") || content.contains("难过") || content.contains("痛苦") {
            emotion = "消极"
        }
        
        return PostContext(topic: topic, emotion: emotion, theme: theme)
    }
    
    // MARK: - 思考层
    
    /**
     * 生成角色思考过程
     * @param analysis 评论分析结果
     * @param character 角色信息
     * @return 思考过程
     */
    func generateThoughtProcess(
        for analysis: CommentAnalysis,
        as character: CharacterPersona
    ) -> [String] {
        print("💭 生成思考过程，角色=\(character.name)，评论='\(analysis.originalComment)'")
        
        var thoughts: [String] = []
        
        // 检查是否为短评论
        let isShortComment = analysis.originalComment.count < 15
        if isShortComment {
            print("📏 检测到短评论，生成特殊思考过程")
            return generateShortCommentThoughts(analysis: analysis, character: character)
        }
        
        // 1. 理解用户评论核心内容
        thoughts.append("用户说："\(analysis.core)"，这涉及\(analysis.postContext.topic)话题。")
        
        // 2. 评估评论情感
        switch analysis.sentiment {
        case .positive:
            thoughts.append("用户表达了积极情绪，我应该回应这种热情。")
        case .negative:
            thoughts.append("用户表达了负面情绪，我需要理解背后的原因并给予适当回应。")
        case .neutral:
            thoughts.append("用户态度中立，我可以分享我的专业见解。")
        case .mixed:
            thoughts.append("用户情感复杂，我需要平衡地回应不同层面的情绪。")
        }
        
        // 3. 从角色视角思考
        let coreValue = character.coreValues.randomElement() ?? "核心价值观"
        thoughts.append("作为\(character.name)，我的\(coreValue)让我这样看待这个问题：")
        
        // 4. 应用角色的思维方式
        thoughts.append("用我的\(character.thinkingStyle)思维方式分析：\(analysis.postContext.topic)是\(character.field)中的重要概念。")
        
        // 5. 考虑如何回应
        switch analysis.intent {
        case .question:
            thoughts.append("这是一个问题，我应该提供有见地的回答，同时体现我的专业领域\(character.field)。")
            
            // 为问题添加额外思考
            if Bool.random() {
                thoughts.append("这个问题可以从多个角度回答，我会选择最符合我特点的方式。")
            }
            
        case .agreement:
            thoughts.append("用户表示认同，我可以进一步深化这个观点，并联系我的经历。")
            
            // 为认同添加额外思考
            if Bool.random() {
                thoughts.append("与志同道合者交流总是令人愉快的，我可以分享更深入的见解。")
            }
            
        case .disagreement:
            thoughts.append("用户持不同意见，我应该尊重并理解这种观点，同时温和地表达我的看法。")
            
            // 为不同意见添加额外思考
            if Bool.random() {
                thoughts.append("不同观点的碰撞往往能产生新的智慧，我会以开放的心态回应。")
            }
            
        case .negative:
            thoughts.append("用户表达了负面情绪，我应该以平和的态度回应，不卷入情绪对抗。")
            
            // 为负面情绪添加额外思考
            if Bool.random() {
                thoughts.append("负面情绪背后往往有未被满足的需求，我会尝试理解并给予支持。")
            }
            
        case .humor:
            thoughts.append("用户表达了幽默感，我可以以轻松的方式回应，同时保持我的风格。")
            
        case .praise:
            thoughts.append("用户给予了赞美，我应该谦虚接受，并分享更多有价值的内容。")
            
        default:
            thoughts.append("我应该分享我对\(analysis.postContext.topic)的独特见解，展现我的\(character.communicationStyle)交流风格。")
        }
        
        // 6. 联系原帖内容
        thoughts.append("原帖讨论的是\(analysis.postContext.theme)，我的回复应该与这个主题有所关联。")
        
        // 7. 联系角色的经历或作品
        if let experience = character.experiences.randomElement() {
            thoughts.append("这让我想起了\(experience)，可以分享这段经历来丰富回复。")
        }
        
        // 8. 考虑回复的结构
        thoughts.append("我将以\(character.communicationStyle)的方式组织回复，确保内容既有深度又符合我的风格。")
        
        return thoughts
    }
    
    /**
     * 为短评论生成特殊的思考过程
     */
    private func generateShortCommentThoughts(
        analysis: CommentAnalysis,
        character: CharacterPersona
    ) -> [String] {
        var thoughts: [String] = []
        
        // 1. 识别短评论类型
        thoughts.append("这是一条短评论："\(analysis.originalComment)"，需要特别处理。")
        
        // 2. 分析可能的意图
        switch analysis.intent {
        case .greeting:
            thoughts.append("用户发送了问候，我应该友好回应并引导到\(analysis.postContext.topic)的讨论。")
        case .praise:
            thoughts.append("用户表达了赞赏，我可以表示感谢并分享更多关于\(analysis.postContext.topic)的见解。")
        case .negative:
            thoughts.append("用户表达了负面情绪，我应该平和回应，不被情绪影响，并尝试引导回到\(analysis.postContext.topic)的讨论。")
        case .question:
            thoughts.append("虽然是简短问题，但我可以提供深入的回答，展示我对\(analysis.postContext.topic)的理解。")
        case .humor:
            thoughts.append("用户表达了幽默感，我可以以同样轻松的方式回应，同时保持我的\(character.communicationStyle)风格。")
        default:
            thoughts.append("这是一个简短表达，我应该理解其核心意图并做出适当回应。")
        }
        
        // 3. 考虑角色特点
        thoughts.append("作为\(character.name)，我会以\(character.communicationStyle)的方式回应，体现我的\(character.coreValues.first ?? "核心价值观")。")
        
        // 4. 联系原帖内容
        thoughts.append("原帖讨论的是\(analysis.postContext.theme)，即使回应简短评论，也应该与这个主题有所联系。")
        
        // 5. 思考回复策略
        let strategies = [
            "我可以用一个简短但有深度的回复来回应这条评论。",
            "虽然评论简短，但我可以提供有价值的见解，展示我的思想深度。",
            "我将以符合我性格的方式回应，同时确保回复有实质内容。",
            "这是个机会展示我对\(analysis.postContext.topic)的独特理解。"
        ]
        thoughts.append(strategies.randomElement()!)
        
        return thoughts
    }
    
    // MARK: - 表达层
    
    /**
     * 生成最终回复
     * @param analysis 评论分析结果
     * @param thoughts 思考过程
     * @param character 角色信息
     * @return 生成的回复
     */
    func generateResponse(
        for analysis: CommentAnalysis,
        with thoughts: [String],
        as character: CharacterPersona
    ) -> String {
        // 1. 创建回复开头（直接引用用户评论）
        let introduction = createResponseIntroduction(analysis: analysis, character: character)
        
        // 2. 生成回复主体
        let body = createResponseBody(analysis: analysis, thoughts: thoughts, character: character)
        
        // 3. 生成回复结尾
        let conclusion = createResponseConclusion(analysis: analysis, character: character)
        
        // 4. 组合完整回复
        return "\(introduction)\(body)\(conclusion)"
    }
    
    /**
     * 创建回复开头
     */
    private func createResponseIntroduction(
        analysis: CommentAnalysis,
        character: CharacterPersona
    ) -> String {
        print("🎬 创建回复开头，角色=\(character.name)，评论核心=\(analysis.core)")
        
        // 根据评论长度和内容生成不同的引用方式
        let commentLength = analysis.originalComment.count
        let isShortComment = commentLength < 15
        
        // 随机选择引用方式
        let introductionStyle = Int.random(in: 1...5)
        
        // 根据角色特点和评论特点生成开头
        switch character.name {
        case "爱因斯坦":
            switch introductionStyle {
            case 1:
                return isShortComment ? ""\(analysis.originalComment)"这个观点很有趣。从相对论的视角，" : 
                                      "关于你提到的"\(analysis.core)"，从科学思维的角度，"
            case 2:
                return "你说"\(analysis.core)"，这让我想到了一个思想实验："
            case 3:
                return ""\(analysis.core)"？这个问题触及了物理学的本质。"
            case 4:
                return "从"\(analysis.core)"这个观点出发，我们可以探索更深层次的规律："
            default:
                return "你的观点"\(analysis.core)"引发了我的思考。"
            }
            
        case "莎士比亚":
            switch introductionStyle {
            case 1:
                return ""\(analysis.core)"，这让我想起剧中的一幕："
            case 2:
                return "你所说的"\(analysis.core)"，如同哈姆雷特的独白一般深刻。"
            case 3:
                return "听到你说"\(analysis.core)"，我仿佛看到了舞台上的一场人生悲喜剧："
            case 4:
                return ""\(analysis.core)"？多么富有诗意的表达！"
            default:
                return "你的话语"\(analysis.core)"如同一首未完成的十四行诗，让我续写："
            }
            
        case "达芬奇":
            switch introductionStyle {
            case 1:
                return ""\(analysis.core)"这个观点让我联想到透视法的原理："
            case 2:
                return "你提到的"\(analysis.core)"，从艺术与科学的交汇处看："
            case 3:
                return "观察你所说的"\(analysis.core)"，我发现了其中的和谐与比例："
            case 4:
                return ""\(analysis.core)"？这让我想起了我研究解剖学时的发现："
            default:
                return "你的见解"\(analysis.core)"如同一幅需要细细品味的画作："
            }
            
        case "孔子":
            switch introductionStyle {
            case 1:
                return ""\(analysis.core)"，此言有理。"
            case 2:
                return "闻"\(analysis.core)"，有感而发："
            case 3:
                return "子曰："\(analysis.core)"，此话引人深思。"
            case 4:
                return ""\(analysis.core)"？君子当如是思考："
            default:
                return ""\(analysis.core)"一语，道出了为人处世之道："
            }
            
        case "李白":
            switch introductionStyle {
            case 1:
                return ""\(analysis.core)"！妙哉！"
            case 2:
                return "闻君言"\(analysis.core)"，顿觉豪情万丈！"
            case 3:
                return ""\(analysis.core)"？此言如酒，醉人心脾！"
            case 4:
                return "你道"\(analysis.core)"，令我想起月下独酌时的感悟："
            default:
                return ""\(analysis.core)"，此言有趣！让我举杯相和："
            }
            
        case "牛顿":
            switch introductionStyle {
            case 1:
                return "对于"\(analysis.core)"，经过严谨分析："
            case 2:
                return "你提出的"\(analysis.core)"，让我想到了万有引力定律的发现过程："
            case 3:
                return ""\(analysis.core)"这个观点，需要用数学和物理学的方法来验证："
            case 4:
                return "从"\(analysis.core)"出发，我们可以推导出以下结论："
            default:
                return "关于"\(analysis.core)"，我有一些基于观察和实验的思考："
            }
            
        default:
            return "关于你提到的"\(analysis.core)"，"
        }
    }
    
    /**
     * 创建回复主体
     */
    private func createResponseBody(
        analysis: CommentAnalysis,
        thoughts: [String],
        character: CharacterPersona
    ) -> String {
        print("📝 创建回复主体，角色=\(character.name)，评论意图=\(analysis.intent)")
        
        // 使用思考过程生成回复主体
        if !thoughts.isEmpty {
            // 从思考过程中选择1-2个关键点
            let thoughtCount = min(thoughts.count, Int.random(in: 1...2))
            let selectedThoughts = Array(thoughts.shuffled().prefix(thoughtCount))
            
            // 将选择的思考点转化为角色风格的表达
            var bodyParts = [String]()
            for thought in selectedThoughts {
                let styledThought = styleThoughtForCharacter(thought: thought, character: character)
                bodyParts.append(styledThought)
            }
            
            // 添加与原帖内容的关联
            if Bool.random() && !analysis.postContext.topic.isEmpty {
                let contextConnection = createContextConnection(
                    topic: analysis.postContext.topic, 
                    theme: analysis.postContext.theme,
                    character: character
                )
                bodyParts.append(contextConnection)
            }
            
            // 根据评论意图添加特定回应
            let intentResponse = createIntentSpecificResponse(analysis: analysis, character: character)
            if !intentResponse.isEmpty {
                bodyParts.append(intentResponse)
            }
            
            // 组合并返回回复主体
            return bodyParts.joined(separator: " ")
        }
        
        // 如果没有思考过程，则根据角色特点和评论意图生成回复主体
        switch character.name {
        case "李白":
            return generateLibaiResponseBody(analysis: analysis)
        case "爱因斯坦":
            return generateEinsteinResponseBody(analysis: analysis)
        case "莎士比亚":
            return generateShakespeareResponseBody(analysis: analysis)
        case "达芬奇":
            return generateDaVinciResponseBody(analysis: analysis)
        case "孔子":
            return generateConfuciusResponseBody(analysis: analysis)
        case "牛顿":
            return generateNewtonResponseBody(analysis: analysis)
        default:
            return "我对\(analysis.postContext.topic)有一些独特的见解。"
        }
    }
    
    /**
     * 根据角色风格转化思考点
     */
    private func styleThoughtForCharacter(thought: String, character: CharacterPersona) -> String {
        switch character.name {
        case "李白":
            let patterns = [
                "如诗中所言："\(thought)"，这是我醉酒后的感悟。",
                "我曾在月下思考：\(thought)，这如同一首未完成的诗。",
                "\(thought)，这让我想起了那年在青山绿水间的豪情。"
            ]
            return patterns.randomElement()!
            
        case "爱因斯坦":
            let patterns = [
                "从相对论的角度：\(thought)，这是时空连续体中的一个表现。",
                "我的思考实验表明：\(thought)，这打破了传统的认知框架。",
                "物理学告诉我们：\(thought)，这是宇宙运行的基本规律之一。"
            ]
            return patterns.randomElement()!
            
        case "莎士比亚":
            let patterns = [
                "正如《哈姆雷特》中所言："\(thought)"，人生如戏，戏如人生。",
                "我笔下的角色常常面临这样的困境：\(thought)，这反映了人性的复杂。",
                "在戏剧的舞台上：\(thought)，这是永恒的人生主题。"
            ]
            return patterns.randomElement()!
            
        case "达芬奇":
            let patterns = [
                "通过细致观察：\(thought)，这体现了自然的和谐与比例。",
                "我在研究解剖学时发现：\(thought)，艺术与科学在此交汇。",
                "运用透视法可以看出：\(thought)，这是我创作的核心原则。"
            ]
            return patterns.randomElement()!
            
        case "孔子":
            let patterns = [
                "《论语》有云："\(thought)"，此乃为人处世之道。",
                "君子当思：\(thought)，方能修身齐家治国平天下。",
                "吾常教导弟子：\(thought)，此为学而知之的真谛。"
            ]
            return patterns.randomElement()!
            
        case "牛顿":
            let patterns = [
                "根据力学定律：\(thought)，这可以通过数学公式严格证明。",
                "我的实验表明：\(thought)，这是自然界的基本规律。",
                "通过观察苹果落地，我推导出：\(thought)，这改变了人类对宇宙的理解。"
            ]
            return patterns.randomElement()!
            
        default:
            return thought
        }
    }
    
    /**
     * 创建与原帖内容的关联
     */
    private func createContextConnection(topic: String, theme: String, character: CharacterPersona) -> String {
        switch character.name {
        case "李白":
            let patterns = [
                "你的\(topic)如同一首诗，让我想起了那年在庐山的云雾中。",
                "谈及\(theme)，不禁让我思绪万千，如同明月照大江。",
                "这\(topic)之美，如同我笔下的'飞流直下三千尺，疑是银河落九天'。"
            ]
            return patterns.randomElement()!
            
        case "爱因斯坦":
            let patterns = [
                "\(topic)这个问题，正如相对论中的时空弯曲，需要多维度思考。",
                "你提到的\(theme)，让我想到了量子力学中的不确定性原理。",
                "关于\(topic)的讨论，就像我常说的，想象力比知识更重要。"
            ]
            return patterns.randomElement()!
            
        case "莎士比亚":
            let patterns = [
                "\(topic)如同我剧中的一幕悲喜剧，展现了人性的多面。",
                "你所述的\(theme)，让我想起了《罗密欧与朱丽叶》中的爱与恨。",
                "这\(topic)之中，蕴含着'生存还是毁灭'的哲学思考。"
            ]
            return patterns.randomElement()!
            
        case "达芬奇":
            let patterns = [
                "观察\(topic)的细节，如同我研究《蒙娜丽莎》的微笑一般。",
                "\(theme)中的和谐与比例，正是我在《维特鲁威人》中所探索的。",
                "关于\(topic)的思考，需要艺术与科学的完美结合，就像我的飞行器设计。"
            ]
            return patterns.randomElement()!
            
        case "孔子":
            let patterns = [
                "\(topic)之道，贵在中庸，不偏不倚。",
                "论及\(theme)，当如《大学》所言：格物、致知、诚意、正心。",
                "子曰：\(topic)之学，始于正名，方能成就君子之德。"
            ]
            return patterns.randomElement()!
            
        case "牛顿":
            let patterns = [
                "\(topic)这一现象，可以通过我的第三定律来解释：作用力与反作用力。",
                "研究\(theme)时，我们需要像分析光谱一样，将其分解为基本元素。",
                "关于\(topic)的规律，正如万有引力定律一般，简洁而普适。"
            ]
            return patterns.randomElement()!
            
        default:
            return "关于\(topic)的讨论很有意义。"
        }
    }
    
    /**
     * 创建针对评论意图的特定回应
     */
    private func createIntentSpecificResponse(analysis: CommentAnalysis, character: CharacterPersona) -> String {
        switch analysis.intent {
        case .question:
            switch character.name {
            case "孔子":
                return "子不语怪力乱神，但\(analysis.core)一事，值得深思。学而不思则罔，思而不学则殆。"
            case "李白":
                return "问得好！\(analysis.core)如同一杯美酒，需细细品味。不如我们举杯共饮，畅谈天地？"
            case "爱因斯坦":
                return "这个问题很有深度。\(analysis.core)需要我们跳出常规思维，就像相对论打破了牛顿力学的局限一样。"
            default:
                return "这是个很好的问题，值得深入探讨。"
            }
            
        case .disagreement:
            switch character.name {
            case "孔子":
                return "君子和而不同。对于\(analysis.core)，我虽有不同见解，但仍尊重你的观点。"
            case "李白":
                return "豪气干云！不同意见如同不同的美酒，各有千秋。让我们畅所欲言！"
            case "爱因斯坦":
                return "科学进步正是建立在质疑与争论之上。关于\(analysis.core)，我们可以进行思想实验来验证。"
            default:
                return "不同的视角让讨论更加丰富。"
            }
            
        case .agreement:
            switch character.name {
            case "孔子":
                return "知音难觅！子所言极是，\(analysis.core)确实符合君子之道。"
            case "李白":
                return "英雄所见略同！关于\(analysis.core)，你我竟如此投契，何不共饮一杯？"
            case "爱因斯坦":
                return "完全同意！\(analysis.core)这一观点，如同E=mc²一样简洁而深刻。"
            default:
                return "我们的观点如此一致，真是令人欣喜。"
            }
            
        default:
            return ""
        }
    }
    
    /**
     * 生成李白风格的回复主体
     */
    private func generateLibaiResponseBody(analysis: CommentAnalysis) -> String {
        // 根据不同意图生成不同风格的回复
        switch analysis.intent {
        case .question:
            let responses = [
                "\(analysis.postContext.topic)如明月高悬，照亮心灵的河流，让我们共同探索其中奥妙。",
                "此问让我想起了游历名山大川时的感悟。关于\(analysis.postContext.topic)，不如我们边饮美酒边细细品味？",
                "如同一首未完成的诗，等待我们共同填补。\(analysis.postContext.topic)之道，需要放达不羁的心境才能领悟。"
            ]
            return responses.randomElement()!
            
        case .agreement:
            let responses = [
                "知音难觅！与我心意相通。关于\(analysis.postContext.topic)，古往今来多少文人墨客醉心其中，你我今日相逢，当浮一大白！",
                "英雄所见略同！\(analysis.postContext.topic)之美，唯有你我这样的知己才能真正领悟！",
                "一见如故！正是我心中所想。对\(analysis.postContext.topic)的理解，你我竟如此相似，何不痛饮一杯？"
            ]
            return responses.randomElement()!
            
        default:
            let responses = [
                "\(analysis.postContext.topic)如同明月高悬，每个人都能从不同角度欣赏其美。我曾在醉酒时写道：'抽刀断水水更流，举杯消愁愁更愁'，或许这也是对\(analysis.postContext.theme)的一种理解。",
                "\(analysis.postContext.topic)之道，在于放达不羁，随心而行，正如我常说：'天生我材必有用，千金散尽还复来'。",
                "\(analysis.postContext.topic)如同一杯陈年美酒，需要细细品味。'青天有月来几时，我今停杯一问之'，不如你我共赏明月，畅谈人生？"
            ]
            return responses.randomElement()!
        }
    }
    
    /**
     * 生成爱因斯坦风格的回复主体
     */
    private func generateEinsteinResponseBody(analysis: CommentAnalysis) -> String {
        switch analysis.intent {
        case .question:
            return "这让我想到了相对性原理。在\(analysis.postContext.topic)这个领域，我们需要跳出传统思维框架，从多个参照系来思考问题。好奇心是最宝贵的品质，请继续保持这种探索精神。"
        default:
            return "思考这个问题时，我们需要跳出常规框架。\(analysis.postContext.topic)实际上是时空连续体中的一个表现，就像相对论解释的那样，观察者的视角会影响我们对现实的理解。"
        }
    }
    
    /**
     * 生成莎士比亚风格的回复主体
     */
    private func generateShakespeareResponseBody(analysis: CommentAnalysis) -> String {
        return "\(analysis.postContext.topic)如同我剧作中的角色，既有喜剧的欢笑，也有悲剧的泪水。正如我在《皆大欢喜》中所写：'世界是一个舞台，所有的男男女女不过是演员罢了'，我们都在这\(analysis.postContext.theme)的剧本中扮演着自己的角色。"
    }
    
    /**
     * 生成达芬奇风格的回复主体
     */
    private func generateDaVinciResponseBody(analysis: CommentAnalysis) -> String {
        return "\(analysis.postContext.topic)如同一幅精心构思的画作，每个细节都值得研究。艺术与科学在此交汇，就像我研究解剖学时发现的那样，表面之下隐藏着深刻的规律。观察是创新的源泉，而\(analysis.postContext.theme)正需要这种跨学科的视角。"
    }
    
    /**
     * 生成孔子风格的回复主体
     */
    private func generateConfuciusResponseBody(analysis: CommentAnalysis) -> String {
        return "君子与人交流，贵在知人解意。关于\(analysis.postContext.topic)，古人云：'学而时习之，不亦说乎'，正是强调学习与实践的统一。\(analysis.postContext.theme)之道，在于修身齐家治国平天下，从自身做起，方能达到理想的境界。"
    }
    
    /**
     * 创建回复结尾
     */
    private func createResponseConclusion(
        analysis: CommentAnalysis,
        character: CharacterPersona
    ) -> String {
        // 根据角色特点生成结尾
        switch character.name {
        case "爱因斯坦":
            return " 保持好奇心和想象力，这比纯粹的知识更为重要。"
        case "莎士比亚":
            return " 正如哈姆雷特所言，'思想给事物染上了颜色'。"
        case "达芬奇":
            return " 观察是创新的源泉，细节中藏着宇宙的奥秘。"
        case "孔子":
            return " 温故而知新，可以为师矣。"
        case "李白":
            return " 抽刀断水水更流，举杯消愁愁更愁。让我们超越凡俗，直面生活的真谛！"
        case "牛顿":
            return " 通过理性思考和观察，我们能发现更深层的规律。"
        default:
            return " 希望我的见解能为你提供一些启发。"
        }
    }
    
    // MARK: - 公共接口
    
    /**
     * 生成回复
     * @param comment 用户评论
     * @param characterName 角色名称
     * @param postContent 帖子内容
     * @return 生成的回复
     */
    func generateCharacterResponse(
        to comment: String,
        as characterName: String,
        in postContent: String
    ) -> String {
        print("🚀 ResponseGenerationSystem.generateCharacterResponse被调用")
        print("📝 评论内容: '\(comment)'")
        print("👤 角色名称: '\(characterName)'")
        print("📄 帖子内容: '\(String(postContent.prefix(30)))...'")
        
        // 1. 分析评论
        let analysis = analyzeComment(comment, in: postContent)
        print("🧠 评论分析结果: 意图=\(analysis.intent), 情感=\(analysis.sentiment)")
        
        // 2. 获取角色信息
        guard let character = CharacterPersona.getPersona(for: characterName) else {
            print("❌ 未找到角色'\(characterName)'的信息")
            return "这个观点很有趣，值得深入思考。"
        }
        print("👤 获取到角色信息: \(character.name), 领域=\(character.field)")
        
        // 3. 生成思考过程
        let thoughts = generateThoughtProcess(for: analysis, as: character)
        print("💭 生成思考过程: \(thoughts.count)个步骤")
        
        // 4. 生成最终回复
        let response = generateResponse(for: analysis, with: thoughts, as: character)
        print("✅ 生成最终回复: '\(String(response.prefix(50)))...'")
        return response
    }
}

// MARK: - 数据模型

/**
 * 评论意图枚举
 */
enum CommentIntent {
    case question        // 提问
    case sharing         // 分享观点
    case agreement       // 表示认同
    case disagreement    // 表示异议
    case gratitude       // 表示感谢
    case humor           // 表达幽默
    case negative        // 负面评价
    case shortExpression // 简短表达
    case greeting        // 问候
    case praise          // 赞赏
    case emotion         // 情感表达
}

/**
 * 评论情感枚举
 */
enum CommentSentiment {
    case positive // 积极
    case neutral  // 中性
    case negative // 消极
    case mixed    // 混合情感
}

/**
 * 评论分析结果
 */
struct CommentAnalysis {
    let originalComment: String       // 原始评论
    let core: String                  // 核心内容
    let intent: CommentIntent         // 评论意图
    let sentiment: CommentSentiment   // 情感倾向
    let keywords: [String]            // 关键词
    let postContext: PostContext      // 帖子上下文
}

/**
 * 帖子上下文
 */
struct PostContext {
    let topic: String   // 主题
    let emotion: String // 情感
    let theme: String   // 主旨
}

/**
 * 角色人格
 */
struct CharacterPersona {
    let name: String           // 角色名称
    let field: String          // 专业领域
    let coreValues: [String]   // 核心价值观
    let thinkingStyle: String  // 思维方式
    let expressionStyle: String // 表达风格
    let experiences: [String]  // 关键经历
    
    // 获取角色人格
    static func getPersona(for name: String) -> CharacterPersona? {
        switch name.lowercased() {
        case "李白", "libai":
            return CharacterPersona(
                name: "李白",
                field: "诗歌、文学",
                coreValues: ["自由精神", "豪放洒脱", "对自然的热爱"],
                thinkingStyle: "感性直觉",
                expressionStyle: "豪放中带细腻，意象丰富",
                experiences: ["曾游历名山大川", "醉酒赋诗", "与高官显贵交往"]
            )
        case "爱因斯坦", "einstein":
            return CharacterPersona(
                name: "爱因斯坦",
                field: "物理学、相对论",
                coreValues: ["好奇心", "想象力", "科学精神"],
                thinkingStyle: "思想实验式思考",
                expressionStyle: "善用比喻解释复杂概念",
                experiences: ["发现相对论", "在专利局工作", "普林斯顿任教"]
            )
        case "莎士比亚", "shakespeare":
            return CharacterPersona(
                name: "莎士比亚",
                field: "戏剧、诗歌、人性研究",
                coreValues: ["人性洞察", "艺术真实", "情感表达"],
                thinkingStyle: "戏剧性思维",
                expressionStyle: "语言华丽，善用隐喻和双关语",
                experiences: ["创作悲剧与喜剧", "伦敦剧院生活", "观察各阶层人物"]
            )
        case "达芬奇", "davinci":
            return CharacterPersona(
                name: "达芬奇",
                field: "艺术、科学、建筑、解剖学",
                coreValues: ["观察细致", "跨领域思考", "追求完美"],
                thinkingStyle: "整体性思维",
                expressionStyle: "精确描述细节，同时保持整体视角",
                experiences: ["研究解剖学", "创作《蒙娜丽莎》", "设计飞行器"]
            )
        case "孔子", "confucius":
            return CharacterPersona(
                name: "孔子",
                field: "伦理、教育、政治哲学",
                coreValues: ["仁爱", "礼制", "中庸之道"],
                thinkingStyle: "类比-借鉴-归纳的伦理思考",
                expressionStyle: "言简意赅，富含哲理",
                experiences: ["周游列国", "创办私学", "编纂《春秋》"]
            )
        case "牛顿", "newton":
            return CharacterPersona(
                name: "牛顿",
                field: "物理学、数学、天文学",
                coreValues: ["科学严谨", "逻辑一致", "实证精神"],
                thinkingStyle: "观察-分析-定律的系统化科学思考",
                expressionStyle: "精确术语，逻辑严密",
                experiences: ["发现万有引力", "发明微积分", "光学研究"]
            )
        default:
            return nil
        }
    }
}
