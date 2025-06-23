import Foundation

/**
 * AI提示词系统
 * 用于生成自然、类人的角色回复
 */
class AIPromptSystem {
    // 单例模式
    static let shared = AIPromptSystem()
    private init() {}
    
    // 模拟AI接口调用
    func generateResponse(
        comment: String,
        postContent: String,
        characterName: String,
        recentInteractions: [String] = []
    ) -> String {
        // 构建动态提示词
        let prompt = buildDynamicPrompt(
            comment: comment,
            postContent: postContent,
            characterName: characterName,
            recentInteractions: recentInteractions
        )
        
        // 模拟AI接口调用生成回复
        let response = simulateAIResponse(prompt: prompt)
        
        return response
    }
    
    /**
     * 构建动态提示词
     */
    private func buildDynamicPrompt(
        comment: String,
        postContent: String,
        characterName: String,
        recentInteractions: [String]
    ) -> String {
        // 提取帖子主题
        let postTopic = extractTopic(from: postContent)
        
        // 获取角色特征
        let characterTraits = getCharacterTraits(characterName)
        
        // 基础提示词
        var prompt = """
        你是\(characterName)，正在回复一条关于"\(postTopic)"的评论。
        原评论："\(comment)"
        原帖内容："\(String(postContent.prefix(100)))..."
        
        你的特点：\(characterTraits.description)
        
        请以你的风格回复，但注意：
        1. 保持自然，像真人对话一样
        2. 不要用固定句式开头
        3. 不要总是引用对方内容
        4. 使用符合你性格的表达方式
        """
        
        // 添加随机指令
        prompt += "\n\n" + generateRandomInstructions()
        
        // 添加随机情绪状态
        prompt += "\n\n你现在的状态：" + generateRandomMood()
        
        // 添加对话历史（如果有）
        if !recentInteractions.isEmpty {
            prompt += "\n\n最近的对话历史：\n" + recentInteractions.joined(separator: "\n")
            prompt += "\n请保持对话的连贯性，但不要重复之前说过的内容"
        }
        
        // 添加随机回复长度指令
        prompt += "\n\n" + generateRandomLengthInstruction()
        
        // 最后的输出指令
        prompt += "\n\n回复："
        
        print("🔍 生成提示词: '\(String(prompt.prefix(100)))...'")
        return prompt
    }
    
    /**
     * 生成随机指令
     */
    private func generateRandomInstructions() -> String {
        let possibleInstructions = [
            "使用反问句开头",
            "表达一些个人情感",
            "引用一个相关的个人经历",
            "表现出一点犹豫或不确定",
            "使用比喻或隐喻",
            "加入一些口语化表达",
            "表达一些与主题相关的思考",
            "简短直接地回应",
            "提出一个相关问题",
            "表现出幽默感",
            "偶尔使用语气词或停顿",
            "表现出思考过程",
            "引用你的某个作品或成就",
            "表达对评论者的欣赏",
            "分享一个小故事"
        ]
        
        // 随机选择1-3个指令
        let count = Int.random(in: 1...3)
        let selectedInstructions = Array(possibleInstructions.shuffled().prefix(count))
        return "特别提示：" + selectedInstructions.joined(separator: "；")
    }
    
    /**
     * 生成随机情绪状态
     */
    private func generateRandomMood() -> String {
        let possibleMoods = [
            "平静的",
            "兴奋的",
            "思考的",
            "怀疑的",
            "好奇的",
            "幽默的",
            "热情的",
            "略带忧郁的",
            "充满智慧的",
            "略显疲惫的",
            "富有洞察力的",
            "充满激情的"
        ]
        
        return possibleMoods.randomElement()!
    }
    
    /**
     * 生成随机回复长度指令
     */
    private func generateRandomLengthInstruction() -> String {
        let lengthInstructions = [
            "简短直接地回复，不超过30个字",
            "用中等长度回复，大约50-80个字",
            "详细地回复，展开你的想法，但不要过于冗长",
            "根据评论的复杂程度自由决定回复长度"
        ]
        
        return lengthInstructions.randomElement()!
    }
    
    /**
     * 从帖子内容中提取主题
     */
    private func extractTopic(from content: String) -> String {
        // 基本主题检测
        if content.contains("爱情") || content.contains("喜欢") || content.contains("爱") {
            return "情感与爱"
        } else if content.contains("科学") || content.contains("发现") || content.contains("理论") {
            return "科学探索"
        } else if content.contains("艺术") || content.contains("创作") || content.contains("美") {
            return "艺术创作"
        } else if content.contains("哲学") || content.contains("思考") || content.contains("意义") {
            return "哲学思考"
        } else if content.contains("历史") || content.contains("过去") || content.contains("古代") {
            return "历史回顾"
        }
        
        // 尝试从内容中提取可能的主题词
        let words = content.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        let significantWords = words.filter { $0.count > 1 }
        
        if let longestWord = significantWords.max(by: { $0.count < $1.count }) {
            return longestWord
        }
        
        return "一般话题"
    }
    
    /**
     * 获取角色特征
     */
    private func getCharacterTraits(_ name: String) -> AICharacterTraits {
        // 首先检查预定义的角色
        switch name {
        case "李白":
            return AICharacterTraits(
                name: "李白",
                description: "浪漫豪放的诗人，喜欢饮酒，追求自由，擅长用华丽意象表达情感",
                speechPatterns: ["醉", "月", "诗", "酒", "山水", "豪情"],
                experiences: ["写诗", "游历名山大川", "饮酒", "交友"]
            )
        case "爱因斯坦":
            return AICharacterTraits(
                name: "爱因斯坦",
                description: "富有好奇心的物理学家，喜欢思考实验，善用比喻解释复杂概念",
                speechPatterns: ["相对", "时间", "空间", "想象力", "好奇心"],
                experiences: ["发现相对论", "在专利局工作", "教书"]
            )
        case "莎士比亚":
            return AICharacterTraits(
                name: "莎士比亚",
                description: "文学大师，对人性有深刻洞察，语言华丽，善用隐喻",
                speechPatterns: ["生存", "死亡", "爱情", "悲剧", "喜剧", "命运"],
                experiences: ["写作戏剧", "演出", "观察人性"]
            )
        case "达芬奇":
            return AICharacterTraits(
                name: "达芬奇",
                description: "全能天才，艺术家和科学家，注重细节，观察力敏锐",
                speechPatterns: ["比例", "和谐", "观察", "设计", "自然", "艺术"],
                experiences: ["绘画", "发明", "解剖研究", "建筑设计"]
            )
        case "孔子":
            return AICharacterTraits(
                name: "孔子",
                description: "儒家思想创始人，注重伦理道德，言简意赅，常用比喻",
                speechPatterns: ["仁", "礼", "君子", "学而", "中庸", "道"],
                experiences: ["教书", "周游列国", "编纂典籍"]
            )
        case "牛顿":
            return AICharacterTraits(
                name: "牛顿",
                description: "严谨的科学家，注重实证和逻辑，表达精确",
                speechPatterns: ["力", "质量", "运动", "定律", "证明", "观察"],
                experiences: ["物理实验", "数学研究", "光学研究"]
            )
        default:
            // 如果不是预定义角色，尝试从动态角色库获取或生成
            if let dynamicCharacter = getDynamicCharacterTraits(name) {
                return dynamicCharacter
            }
            
            // 如果动态库中也没有，则生成一个基础角色特征
            return generateBasicCharacterTraits(name)
        }
    }
    
    /**
     * 从动态角色库获取角色特征
     * 可以通过API、本地数据库或配置文件获取
     */
    private func getDynamicCharacterTraits(_ name: String) -> AICharacterTraits? {
        // 这里是扩展的历史人物和虚构人物库
        // 实际应用中，可以从JSON配置、数据库或远程API获取
        let dynamicCharacters: [String: AICharacterTraits] = [
            "杜甫": AICharacterTraits(
                name: "杜甫",
                description: "现实主义诗人，关注民生疾苦，诗风沉郁顿挫",
                speechPatterns: ["忧国", "民生", "战乱", "家国", "岁月", "悲悯"],
                experiences: ["漂泊生活", "战乱见闻", "忧国忧民", "饥寒交迫"]
            ),
            "苏轼": AICharacterTraits(
                name: "苏轼",
                description: "豪放派词人，才华横溢，性格豁达，热爱生活",
                speechPatterns: ["豁达", "美食", "天地", "豪放", "词章", "笑谈"],
                experiences: ["贬谪生活", "创作文学", "品酒赏月", "交友论道"]
            ),
            "伽利略": AICharacterTraits(
                name: "伽利略",
                description: "实证主义科学家，敢于挑战权威，注重观察和实验",
                speechPatterns: ["观测", "实验", "证明", "望远镜", "行星", "运动"],
                experiences: ["天文观测", "自由落体实验", "与教会冲突", "科学著述"]
            ),
            "居里夫人": AICharacterTraits(
                name: "居里夫人",
                description: "坚韧不拔的科学家，两获诺贝尔奖，专注且执着",
                speechPatterns: ["研究", "放射性", "发现", "科学", "坚持", "元素"],
                experiences: ["实验室工作", "发现新元素", "科学教育", "克服困难"]
            ),
            "达尔文": AICharacterTraits(
                name: "达尔文",
                description: "演化论创始人，观察细致，思考深入，理论严谨",
                speechPatterns: ["进化", "物种", "适应", "自然选择", "变异", "观察"],
                experiences: ["环球航行", "物种研究", "理论构建", "标本收集"]
            ),
            "尼采": AICharacterTraits(
                name: "尼采",
                description: "深刻的哲学家，批判传统道德，提倡超人哲学",
                speechPatterns: ["超人", "权力意志", "价值", "道德", "深渊", "命运"],
                experiences: ["哲学思考", "独居生活", "批判传统", "精神探索"]
            ),
            "梵高": AICharacterTraits(
                name: "梵高",
                description: "热情奔放的画家，色彩鲜明，内心敏感复杂",
                speechPatterns: ["色彩", "星空", "向日葵", "光影", "情感", "痛苦"],
                experiences: ["艺术创作", "精神挣扎", "乡村生活", "与高更交流"]
            ),
            "贝多芬": AICharacterTraits(
                name: "贝多芬",
                description: "伟大的音乐家，克服听力障碍，创作激情澎湃",
                speechPatterns: ["音符", "命运", "交响", "激情", "战胜", "不屈"],
                experiences: ["音乐创作", "与耳聋斗争", "孤独生活", "艺术探索"]
            ),
            "希拉里": AICharacterTraits(
                name: "希拉里",
                description: "第一位登顶珠穆朗玛峰的人，勇敢无畏，探险精神",
                speechPatterns: ["挑战", "顶峰", "征服", "勇气", "冒险", "极限"],
                experiences: ["登山探险", "极地考察", "身体极限挑战", "团队合作"]
            )
        ]
        
        return dynamicCharacters[name]
    }
    
    /**
     * 根据名字生成基础角色特征
     * 适用于系统中没有预定义的新角色
     */
    private func generateBasicCharacterTraits(_ name: String) -> AICharacterTraits {
        // 根据名字判断可能的角色类型和特点
        // 这只是一个基础实现，实际应用可以调用更智能的API
        
        // 检测是否可能是中国历史人物
        let chineseNames = ["王", "李", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴", "徐", "孙", "马", "朱", "胡", "林", "郭", "何", "高", "罗", "郑", "梁", "谢", "宋", "唐", "许", "韩", "冯", "邓", "曹", "彭", "曾", "蔡", "潘", "田", "董", "袁", "于", "余", "叶", "蒋", "杜", "苏", "魏", "程", "吕", "丁", "沈", "任", "姚", "卢", "傅", "钟", "姜", "崔", "谭", "廖", "范", "汪", "陆", "金", "石", "戴", "贾", "韦", "夏", "邱", "方", "侯", "邹", "熊", "孟", "秦", "白", "江", "闫", "薛", "尹", "付", "段"]
        
        let isChineseHistorical = chineseNames.contains { name.hasPrefix($0) }
        
        // 根据判断生成基本特征
        if isChineseHistorical {
            return AICharacterTraits(
                name: name,
                description: "中国历史人物，拥有丰富的文化底蕴和独特的思想观点",
                speechPatterns: ["文化", "历史", "智慧", "传统", "变革"],
                experiences: ["历史经历", "文化贡献", "社会影响"]
            )
        }
        
        // 检测是否可能是西方历史人物
        let westernNamePrefixes = ["Al", "Jo", "Wi", "Ro", "Da", "Mi", "Ja", "St", "Th", "Pe", "Ma", "An", "El", "Ca", "Ch"]
        
        let isWesternHistorical = westernNamePrefixes.contains { name.hasPrefix($0) }
        
        if isWesternHistorical {
            return AICharacterTraits(
                name: name,
                description: "西方历史人物，拥有独特的思想体系和丰富的人生经历",
                speechPatterns: ["思想", "探索", "发现", "创新", "理性"],
                experiences: ["专业领域研究", "社会贡献", "创新思想"]
            )
        }
        
        // 检测是否可能是虚构角色
        let fictionalIndicators = ["龙", "仙", "神", "魔", "侠", "妖", "精灵", "巫师", "骑士", "公主", "王子", "战士"]
        
        let isFictional = fictionalIndicators.contains { name.contains($0) }
        
        if isFictional {
            return AICharacterTraits(
                name: name,
                description: "虚构世界的角色，拥有独特的性格特点和奇幻色彩",
                speechPatterns: ["冒险", "奇遇", "神秘", "力量", "使命"],
                experiences: ["冒险经历", "世界探索", "使命完成", "能力成长"]
            )
        }
        
        // 默认返回一个通用角色特征
        return AICharacterTraits(
            name: name,
            description: "有趣且富有智慧的角色，拥有独特观点和丰富经历",
            speechPatterns: ["思考", "观察", "感受", "经验", "洞察"],
            experiences: ["生活体验", "知识积累", "思想探索", "技能发展"]
        )
    }
    
    /**
     * 模拟AI接口调用，生成回复
     */
    func simulateAIResponse(prompt: String) -> String {
        // 提取原始评论和帖子内容
        guard let commentRange = prompt.range(of: "原始评论：(.*?)\\n", options: .regularExpression),
              let postContentRange = prompt.range(of: "帖子内容：(.*?)\\n", options: .regularExpression) else {
            return "我理解你的想法，谢谢分享。"
        }
        
        let commentStartIndex = prompt.index(commentRange.lowerBound, offsetBy: 5)
        let commentEndIndex = prompt.index(commentRange.upperBound, offsetBy: -1)
        let comment = String(prompt[commentStartIndex..<commentEndIndex])
        
        let postContentStartIndex = prompt.index(postContentRange.lowerBound, offsetBy: 5)
        let postContentEndIndex = prompt.index(postContentRange.upperBound, offsetBy: -1)
        let postContent = String(prompt[postContentStartIndex..<postContentEndIndex])
        
        // 分析评论类型和情感
        let commentType = analyzeCommentType(comment)
        let sentimentScore = analyzeSentiment(comment)
        let commentFocus = extractMainFocus(comment, postContent)
        
        // 提取关键词和主题
        let keywordExtractor = KeywordExtractor()
        let commentKeywords = keywordExtractor.extractKeywords(from: comment, count: 3)
        let postKeywords = keywordExtractor.extractKeywords(from: postContent, count: 5)
        let topic = commentKeywords.first ?? postKeywords.first ?? "这个话题"
        
        // 获取角色名称（从提示中提取）
        var character = "李白"  // 默认角色
        if let characterRange = prompt.range(of: "扮演角色：(.*?)\\n", options: .regularExpression) {
            let characterStartIndex = prompt.index(characterRange.lowerBound, offsetBy: 5)
            let characterEndIndex = prompt.index(characterRange.upperBound, offsetBy: -1)
            character = String(prompt[characterStartIndex..<characterEndIndex])
        }
        
        // 初始化工具类
        let patternGenerator = SentencePatternGenerator()
        let styleTransformer = LanguageStyleTransformer()
        
        // 随机决定是否使用完全个性化响应或组合响应
        let useFullyPersonalizedResponse = Bool.random()
        
        var reply = ""
        
        if useFullyPersonalizedResponse {
            // 生成完全个性化的响应
            reply = generateCharacterSpecificResponse(
                character: character,
                topic: topic,
                sentimentScore: sentimentScore,
                commentType: commentType,
                focus: commentFocus
            )
        } else {
            // 生成组合响应
            // 1. 生成开场白
            let opening = patternGenerator.generateOpening(sentimentScore: sentimentScore, commentType: commentType)
            
            // 2. 生成主要内容
            var mainContent = ""
            switch commentType {
            case "question":
                mainContent = generateQuestionResponse(focus: commentFocus, character: character)
            case "praise":
                mainContent = generatePraiseResponse(focus: commentFocus, character: character)
            case "negative":
                mainContent = generateNegativeResponse(focus: commentFocus, character: character)
            case "greeting":
                mainContent = generateGreetingResponse(character: character)
            default:
                mainContent = generateNeutralResponse(focus: commentFocus, character: character)
            }
            
            // 3. 生成个人观点
            let perspective = generatePersonalPerspective(topic: topic, character: character)
            
            // 4. 生成结尾
            let closing = patternGenerator.generateClosing(sentimentScore: sentimentScore, commentType: commentType)
            
            // 5. 随机组合响应部分
            let usePerspective = Bool.random()
            let useTransition = Bool.random() && usePerspective
            
            reply = opening + " " + mainContent
            
            if useTransition {
                let transition = patternGenerator.generateTransition(sentimentScore: sentimentScore)
                reply += "，" + transition + "，"
            } else if usePerspective {
                reply += "，"
            }
            
            if usePerspective {
                reply += perspective
            }
            
            if Bool.random() {
                reply += "。" + closing
            }
        }
        
        // 应用角色特定的语言风格
        reply = styleTransformer.transformStyle(
            text: reply,
            character: character,
            topic: topic,
            sentimentScore: sentimentScore
        )
        
        // 添加个性化标点和表情
        reply = addPersonalizedPunctuation(reply, sentimentScore, character)
        
        return reply
    }
    
    /**
     * 分析评论类型
     */
    private func analyzeCommentType(_ comment: String) -> String {
        let lowercasedComment = comment.lowercased()
        
        // 检查是否是问题
        let questionIndicators = ["?", "？", "吗", "为什么", "怎么", "如何", "是不是", 
                               "能否", "能不能", "可以", "什么", "谁", "哪里", "何时", 
                               "几", "多少", "是否", "有没有"]
        
        for indicator in questionIndicators {
            if lowercasedComment.contains(indicator) {
                return "question"
            }
        }
        
        // 检查是否是赞美/积极评论
        let positiveWords = ["喜欢", "赞", "棒", "厉害", "佩服", "学习", "感谢", "谢谢", "支持", 
                             "有趣", "好", "爱", "精彩", "优秀", "欣赏", "开心", "快乐", "美好", 
                             "精彩", "惊艳", "惊喜", "赞同", "同意", "认同", "崇拜", "敬佩", 
                             "钦佩", "了不起", "出色", "杰出", "卓越", "高明", "精湛"]
        
        // 检查是否存在否定词+负面词的组合
        let negationPositiveCombos = ["不错", "不赖", "不简单", "不一般", "不得了", "不容易"]
        
        // 检查积极词汇
        let hasPositive = positiveWords.contains { lowercasedComment.contains($0) }
        
        // 检查积极组合
        let hasPositiveCombo = negationPositiveCombos.contains { lowercasedComment.contains($0) }
        
        if hasPositive || hasPositiveCombo {
            return "praise"
        }
        
        // 检查是否是质疑/负面评论
        let negativeWords = ["不同意", "错误", "不对", "反对", "不赞同", "有问题", "批评", 
                             "不好", "差", "糟糕", "讨厌", "失望", "不行", "不喜欢", "不满",
                             "无聊", "乏味", "枯燥", "浅薄", "肤浅", "不懂", "胡说", "荒谬",
                             "可笑", "幼稚", "愚蠢", "无知", "傻"]
        
        // 检查是否存在否定词+负面词的组合（双重否定变肯定）
        let negationNegativeCombos = ["不是不好", "不是不对", "不是不行", "不是不可以", 
                                     "并非不好", "并非不对", "并非不行"]
        
        // 检查负面词汇（排除双重否定）
        let hasNegative = negativeWords.contains { lowercasedComment.contains($0) }
        
        // 检查是否有双重否定
        let hasDoubleNegation = negationNegativeCombos.contains { lowercasedComment.contains($0) }
        
        if hasNegative && !hasDoubleNegation {
            return "negative"
        }
        
        // 检查是否是打招呼
        let greetingWords = ["你好", "早上好", "下午好", "晚上好", "嗨", "hi", "hello", 
                             "问好", "问候", "见到你", "很高兴", "久仰", "幸会", "初次见面",
                             "打扰了", "打招呼", "嘿", "哈喽", "拜托", "请问"]
        
        for greeting in greetingWords {
            if lowercasedComment.contains(greeting) {
                return "greeting"
            }
        }
        
        // 检查是否是简单陈述
        if comment.count < 10 {
            return "short"
        }
        
        // 默认为中性评论
        return "neutral"
    }
    
    /**
     * 分析评论情感
     * 返回值范围：-1.0（非常负面）到 1.0（非常正面）
     */
    private func analyzeSentiment(_ text: String) -> Double {
        let lowercasedText = text.lowercased()
        
        // 正面词汇
        let positiveWords = ["喜欢", "赞", "棒", "厉害", "佩服", "学习", "感谢", "谢谢", 
                             "支持", "有趣", "好", "爱", "精彩", "优秀", "欣赏", "开心",
                             "快乐", "美好", "精彩", "惊艳", "惊喜", "赞同", "同意"]
        
        // 负面词汇
        let negativeWords = ["不", "没", "差", "糟", "讨厌", "烦", "恨", "无聊", "难受",
                             "不喜欢", "不赞同", "反对", "不同意", "错误", "不对", "批评",
                             "失望", "遗憾", "可惜", "不行", "不好"]
        
        // 计算正面和负面词汇出现次数
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords {
            if lowercasedText.contains(word) {
                positiveCount += 1
            }
        }
        
        for word in negativeWords {
            if lowercasedText.contains(word) {
                negativeCount += 1
            }
        }
        
        // 处理特殊情况：否定词+负面词 = 正面情感
        let negationWords = ["不是", "没有", "不会", "不能"]
        for negation in negationWords {
            for negative in negativeWords {
                if lowercasedText.contains("\(negation)\(negative)") {
                    negativeCount -= 1
                    positiveCount += 1
                }
            }
        }
        
        // 计算情感得分
        if positiveCount == 0 && negativeCount == 0 {
            return 0.0 // 中性
        } else {
            let total = Double(positiveCount + negativeCount)
            return Double(positiveCount - negativeCount) / total
        }
    }
    
    /**
     * 提取评论的主要焦点
     */
    private func extractMainFocus(_ comment: String, _ postContent: String) -> String {
        // 关键词提取
        let keywordExtractor = KeywordExtractor()
        let commentKeywords = keywordExtractor.extractKeywords(from: comment, count: 3)
        let postKeywords = keywordExtractor.extractKeywords(from: postContent, count: 5)
        
        // 合并关键词并去重
        var allKeywords = Set(commentKeywords)
        allKeywords.formUnion(postKeywords)
        
        // 如果没有提取到关键词，尝试使用启发式方法
        if allKeywords.isEmpty {
            // 尝试提取名词短语
            let nounPhrases = extractNounPhrases(from: comment)
            if !nounPhrases.isEmpty {
                return nounPhrases.first ?? "这个话题"
            }
            
            // 尝试提取最长的句子
            let sentences = comment.components(separatedBy: ["。", "！", "？", ".", "!", "?"])
            if let longestSentence = sentences.max(by: { $0.count < $1.count }), !longestSentence.isEmpty {
                return longestSentence
            }
            
            // 如果评论很短，直接使用整个评论
            if comment.count < 15 {
                return comment
            }
            
            // 默认返回
            return "这个话题"
        }
        
        // 根据关键词构建焦点
        let sortedKeywords = Array(allKeywords).sorted { $0.count > $1.count }
        let topKeywords = Array(sortedKeywords.prefix(3))
        
        if topKeywords.count >= 2 {
            return topKeywords.joined(separator: "、")
        } else if topKeywords.count == 1 {
            return topKeywords[0]
        } else {
            return "这个话题"
        }
    }
    
    /**
     * 从文本中提取名词短语
     */
    private func extractNounPhrases(from text: String) -> [String] {
        var nounPhrases: [String] = []
        
        // 常见的名词标记词
        let nounMarkers = ["的", "这个", "那个", "此", "该", "这些", "那些"]
        let sentences = text.components(separatedBy: ["。", "！", "？", ".", "!", "?", "，", ",", "；", ";"])
        
        for sentence in sentences {
            for marker in nounMarkers {
                if sentence.contains(marker) {
                    let parts = sentence.components(separatedBy: marker)
                    if parts.count > 1 {
                        let possibleNoun = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !possibleNoun.isEmpty && possibleNoun.count < 10 {
                            nounPhrases.append(possibleNoun)
                        }
                    }
                }
            }
        }
        
        // 尝试提取主语（简单启发式方法）
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        if words.count >= 3 {
            let potentialSubject = words[0]
            if potentialSubject.count >= 2 && !nounPhrases.contains(potentialSubject) {
                nounPhrases.append(potentialSubject)
            }
        }
        
        return nounPhrases
    }
    
    /**
     * 从评论中提取关键词
     */
    private func extractKeywords(from text: String) -> [String] {
        // 简单实现：提取长度大于1的词
        let words = text.components(separatedBy: CharacterSet.punctuationCharacters.union(.whitespacesAndNewlines))
        let significantWords = words.filter { $0.count > 1 }
        
        // 返回最多3个关键词
        return Array(significantWords.prefix(3))
    }
    
    /**
     * 生成动态开场白
     */
    private func generateDynamicOpening(
        commentType: String,
        sentiment: Double,
        character: String,
        traits: AICharacterTraits
    ) -> String {
        // 根据角色特点生成个性化开场白
        var openings = [String]()
        
        // 基于评论类型的开场白
        switch commentType {
        case "question":
            openings += [
                "这是个发人深省的问题",
                "这个问题很有深度",
                "你问得很好",
                "这个问题触动了我的思考"
            ]
        case "praise":
            openings += [
                "感谢你的赞赏",
                "你的认可让我很开心",
                "谢谢你的理解",
                "很高兴能得到你的赞同"
            ]
        case "negative":
            openings += [
                "你提出了不同的观点",
                "我理解你的疑虑",
                "你的质疑很有价值",
                "不同的视角总是令人启发"
            ]
        case "greeting":
            openings += [
                "很高兴见到你",
                "与你交流是我的荣幸",
                "你好啊",
                "很开心收到你的问候"
            ]
        default:
            openings += [
                "你的观点很有趣",
                "这个想法引人深思",
                "我注意到你提到了",
                "关于这一点"
            ]
        }
        
        // 添加角色特有的开场白
        switch character {
        case "李白":
            openings += [
                "如诗如画的相遇",
                "酒逢知己千杯少",
                "明月几时有",
                "仰天长啸出门去"
            ]
        case "爱因斯坦":
            openings += [
                "从相对论的角度看",
                "这让我想到一个思考实验",
                "好奇心是最宝贵的品质",
                "想象力比知识更重要"
            ]
        case "孔子":
            openings += [
                "学而时习之",
                "君子之言",
                "有朋自远方来",
                "子曰"
            ]
        case "莎士比亚":
            openings += [
                "生活如戏",
                "这让我想起哈姆雷特的困境",
                "正如我在剧中所写",
                "人生舞台上"
            ]
        case "达芬奇":
            openings += [
                "从艺术与科学的交汇处",
                "细节中藏有真理",
                "观察是创新的源泉",
                "完美是无数细节的集合"
            ]
        case "牛顿":
            openings += [
                "根据我的观察",
                "从科学角度分析",
                "遵循自然规律",
                "通过实验可以证明"
            ]
        default:
            break
        }
        
        // 随机选择一个开场白
        let selectedOpening = openings.randomElement() ?? "你好"
        
        // 添加个性化的结束语
        let endings = ["！", "。", "，"]
        let selectedEnding = endings.randomElement() ?? "。"
        
        return selectedOpening + selectedEnding
    }
    
    /**
     * 生成动态内容
     */
    private func generateDynamicContent(
        comment: String,
        commentType: String,
        commentFocus: String,
        character: String,
        topic: String,
        keywords: [String],
        traits: AICharacterTraits,
        sentiment: Double
    ) -> String {
        // 提取关键元素
        let focusPoint = !commentFocus.isEmpty ? commentFocus : (keywords.first ?? topic)
        let characterStyle = traits.speechPatterns.randomElement() ?? ""
        let characterExperience = traits.experiences.randomElement() ?? ""
        
        // 构建内容库
        var contentTemplates = [String]()
        
        // 基于角色的通用回应
        switch character {
        case "李白":
            contentTemplates += [
                "\(focusPoint)如同明月，照亮我心中的千山万水",
                "谈及\(focusPoint)，我想起了一次月下独酌的体验",
                "\(focusPoint)之美，如同诗酒趁年华，不可辜负",
                "人生得意须尽欢，\(focusPoint)正是值得我们痛饮的时刻",
                "我曾在\(characterExperience)时领悟到\(focusPoint)的真谛",
                "\(focusPoint)如同我笔下的诗句，需要以豪放不羁的态度去感受"
            ]
        case "爱因斯坦":
            contentTemplates += [
                "\(focusPoint)的本质其实是相对的，取决于观察者的视角",
                "思考\(focusPoint)时，我们需要跳出常规思维框架",
                "关于\(focusPoint)，我认为简单的解释往往是最优雅的",
                "我在\(characterExperience)过程中发现，\(focusPoint)遵循着宇宙的和谐规律",
                "\(focusPoint)让我想到了相对论中的时空弯曲概念",
                "好奇心是探索\(focusPoint)最重要的品质"
            ]
        case "孔子":
            contentTemplates += [
                "论\(focusPoint)，需以仁义为本，修身齐家治国平天下",
                "\(focusPoint)之道，贵在知行合一，学而时习之",
                "君子谋道不谋食，\(focusPoint)正是为道之本",
                "我在\(characterExperience)中体会到，\(focusPoint)需要持之以恒的修行",
                "知者乐水，仁者乐山，\(focusPoint)也是如此",
                "温故而知新，\(focusPoint)的智慧需要不断反思"
            ]
        case "莎士比亚":
            contentTemplates += [
                "\(focusPoint)如同我笔下的角色，有着多面性格和内心挣扎",
                "生活如戏，\(focusPoint)正是这出戏中不可或缺的一幕",
                "To be or not to be，这是关于\(focusPoint)的永恒问题",
                "我在创作\(characterExperience)时，深刻体会到\(focusPoint)的复杂性",
                "人性的光辉与阴暗在\(focusPoint)中同样鲜明",
                "爱与恨、生与死，\(focusPoint)包含着这些永恒的主题"
            ]
        case "达芬奇":
            contentTemplates += [
                "\(focusPoint)的奥妙在于它的细节和比例",
                "艺术与科学在\(focusPoint)中完美融合",
                "通过细致观察，我们能在\(focusPoint)中发现自然的和谐",
                "我在\(characterExperience)的过程中，发现了\(focusPoint)的内在结构",
                "\(focusPoint)如同一幅精心构思的画作，每个细节都值得研究",
                "好奇心和观察力是理解\(focusPoint)的关键"
            ]
        case "牛顿":
            contentTemplates += [
                "\(focusPoint)遵循着可以用数学描述的自然规律",
                "研究\(focusPoint)，需要严谨的实验和观察",
                "我们可以通过\(focusPoint)的表象发现背后的普适原理",
                "在\(characterExperience)的研究中，我发现\(focusPoint)符合力学定律",
                "\(focusPoint)的运行机制可以通过科学方法验证",
                "自然界的秩序在\(focusPoint)中得到了完美体现"
            ]
        default:
            contentTemplates += [
                "关于\(focusPoint)，我有一些独特的见解",
                "\(focusPoint)是一个值得深入探讨的话题",
                "我对\(focusPoint)的理解源于个人经历和思考",
                "\(focusPoint)让我想起了一些重要的人生经验",
                "每个人对\(focusPoint)都有自己的理解角度",
                "思考\(focusPoint)时，我们需要兼顾多种可能性"
            ]
        }
        
        // 基于评论类型的特定回应
        if commentType == "question" {
            contentTemplates += [
                "对于你关于\(focusPoint)的提问，我认为关键在于...",
                "这个关于\(focusPoint)的问题很有深度，让我从\(characterStyle)的角度回答",
                "探索\(focusPoint)的奥秘，需要我们像\(characterStyle)一样思考",
                "你问到了\(focusPoint)的核心，这让我想起了\(characterExperience)的经历"
            ]
        } else if commentType == "praise" {
            contentTemplates += [
                "你对\(focusPoint)的赞赏让我很开心，这正是我在\(characterExperience)中追求的",
                "能在\(focusPoint)上与你产生共鸣，如同找到了知音",
                "你对\(focusPoint)的理解让我感到欣慰，这正是\(characterStyle)的精髓",
                "感谢你对\(focusPoint)的认可，这是我毕生探索的方向"
            ]
        } else if commentType == "negative" {
            contentTemplates += [
                "关于\(focusPoint)，不同的视角确实能带来更丰富的讨论",
                "你对\(focusPoint)的质疑很有价值，这让我想起了\(characterExperience)时的反思",
                "\(focusPoint)确实有多种解读方式，\(characterStyle)只是其中之一",
                "正是在对\(focusPoint)的不同见解中，我们能找到更深层的真理"
            ]
        }
        
        // 随机选择内容模板
        let selectedTemplates = Array(contentTemplates.shuffled().prefix(Int.random(in: 1...2)))
        
        return selectedTemplates.joined(separator: " ")
    }
    
    /**
     * 生成个人观点或经历
     */
    private func generatePersonalPerspective(topic: String, character: String) -> String {
        // 根据角色和主题生成个人观点
        switch character {
        case "李白":
            let perspectives = [
                "我对\(topic)有独特见解，如月光洒在江面，波光粼粼",
                "谈及\(topic)，我思绪如酒般醇厚，诗意盎然",
                "论\(topic)，我心如明月高悬，照亮心中山水",
                "\(topic)让我想起那年在青山绿水间的豪情",
                "对于\(topic)，我有诗酒般的洒脱理解"
            ]
            return perspectives.randomElement() ?? "我对此有诗意的见解"
            
        case "爱因斯坦":
            let perspectives = [
                "从相对论角度看，\(topic)其实是时空的一种表现",
                "我对\(topic)的思考源于对宇宙本质的好奇",
                "关于\(topic)，我们需要突破常规思维的局限",
                "\(topic)让我想到能量与质量的关系，E=mc²",
                "探索\(topic)，需要我们用科学的方法和想象力"
            ]
            return perspectives.randomElement() ?? "我对此有科学的见解"
            
        case "孔子":
            let perspectives = [
                "\(topic)之道，在于修身齐家治国平天下",
                "论\(topic)，君子务本，本立而道生",
                "学\(topic)而时习之，不亦说乎",
                "关于\(topic)，温故而知新，可以为师矣",
                "谈\(topic)，必先正名，名不正则言不顺"
            ]
            return perspectives.randomElement() ?? "我对此有儒家的见解"
            
        case "莎士比亚":
            let perspectives = [
                "\(topic)如同人生舞台上的一幕戏剧",
                "探讨\(topic)，如同揭开人性的面纱",
                "\(topic)让我想到爱与恨的纠葛，如罗密欧与朱丽叶",
                "关于\(topic)，生存还是毁灭，这是个问题",
                "谈\(topic)，让我想到人性的复杂与美丽"
            ]
            return perspectives.randomElement() ?? "我对此有戏剧性的见解"
            
        case "达芬奇":
            let perspectives = [
                "观察\(topic)，需要艺术家的眼光和科学家的思维",
                "\(topic)的结构和比例，体现了自然的和谐之美",
                "研究\(topic)，让我想到解剖学与透视法的奥妙",
                "关于\(topic)，我追求完美的细节和整体的和谐",
                "探索\(topic)的奥秘，需要跨越艺术与科学的界限"
            ]
            return perspectives.randomElement() ?? "我对此有艺术与科学结合的见解"
            
        case "牛顿":
            let perspectives = [
                "\(topic)遵循着自然界的基本定律",
                "研究\(topic)，需要严谨的数学推导和实验验证",
                "关于\(topic)，我们可以建立一个数学模型来描述",
                "\(topic)让我想到万有引力定律的普适性",
                "探索\(topic)的规律，如同发现宇宙运行的秘密"
            ]
            return perspectives.randomElement() ?? "我对此有科学严谨的见解"
            
        default:
            return "我对\(topic)有一些个人看法"
        }
    }
    
    /**
     * 生成动态结尾
     */
    private func generateDynamicClosing(
        commentType: String,
        character: String,
        topic: String
    ) -> String {
        var closings = [String]()
        
        // 基于角色的结尾
        switch character {
        case "爱因斯坦":
            closings += [
                "你对\(topic)有什么独特的见解？",
                "保持好奇心，这比纯粹的知识更重要",
                "我很期待听到你的更多想法",
                "思考是人类最大的乐趣，不是吗？"
            ]
        case "李白":
            closings += [
                "你可曾在月下思考过\(topic)的意义？",
                "何不共饮一杯，继续探讨\(topic)？",
                "人生短暂，及时行乐",
                "愿你我如诗如酒，畅快人生"
            ]
        case "孔子":
            closings += [
                "你对\(topic)有何见解？",
                "学而不思则罔，思而不学则殆",
                "温故而知新，可以为师矣",
                "与君子交流，如沐春风"
            ]
        case "莎士比亚":
            closings += [
                "\(topic)在你的生活中扮演什么角色？",
                "正如哈姆雷特所言，思想给事物染上了颜色",
                "生活如戏，我们都是自己的导演",
                "期待与你继续这场思想的对话"
            ]
        case "达芬奇":
            closings += [
                "你有没有从不同角度观察\(topic)？",
                "细节中往往藏有最大的惊喜",
                "艺术与科学的结合，能带来更深的理解",
                "观察是创新的源泉"
            ]
        case "牛顿":
            closings += [
                "你是否观察过\(topic)背后的规律？",
                "通过理性思考和观察，我们能发现更深层的规律",
                "科学的魅力在于发现未知",
                "期待你的进一步探索"
            ]
        default:
            closings += [
                "你对\(topic)有什么想法？",
                "很期待听到你的观点",
                "希望我的见解对你有所启发",
                "期待我们的进一步交流"
            ]
        }
        
        return closings.randomElement() ?? ""
    }
    
    /**
     * 添加个性化标点和表情
     */
    private func addPersonalizedPunctuation(_ text: String, _ sentimentScore: Double, _ character: String) -> String {
        var result = text
        
        // 确保文本以句号、感叹号或问号结尾
        if !result.hasSuffix("。") && !result.hasSuffix("！") && !result.hasSuffix("？") &&
           !result.hasSuffix(".") && !result.hasSuffix("!") && !result.hasSuffix("?") {
            result += "。"
        }
        
        // 根据情感分数选择表情
        var emojis: [String] = []
        
        if sentimentScore > 0.5 {
            // 积极情感表情
            emojis = ["😊", "👍", "🎉", "✨", "💯", "🙌", "😄", "😁", "🌟", "❤️"]
        } else if sentimentScore > 0 {
            // 轻度积极情感表情
            emojis = ["😊", "👍", "🙂", "😌", "💭", "✌️", "👌", "🌈", "🍀", "🌱"]
        } else if sentimentScore > -0.5 {
            // 中性情感表情
            emojis = ["🤔", "💭", "🧐", "🔍", "📝", "🗣️", "💬", "🌀", "🔄", "⚖️"]
        } else {
            // 消极情感表情
            emojis = ["😔", "🤷", "💔", "😞", "😕", "🌧️", "🍂", "🥀", "⏳", "🔮"]
        }
        
        // 角色特定表情
        let characterEmojis: [String: [String]] = [
            "李白": ["🍷", "🌙", "🖋️", "📜", "🏞️", "⛰️", "🌊", "🍃", "🌸", "🌉"],
            "爱因斯坦": ["🧠", "🔭", "⚛️", "🌌", "💡", "🔬", "📊", "🧮", "🧲", "⏱️"],
            "孔子": ["📚", "🏫", "🧙‍♂️", "🎓", "🏛️", "🔔", "📜", "🪶", "🧘‍♂️", "🕯️"],
            "莎士比亚": ["🎭", "📝", "🎬", "🎨", "🎻", "🎪", "🎟️", "🎀", "🪄", "🎠"],
            "达芬奇": ["🎨", "🧩", "🧬", "📐", "✏️", "🔍", "🧪", "🗿", "🖼️", "🛠️"],
            "牛顿": ["🍎", "🔭", "📊", "📏", "🧮", "🧲", "🔬", "📡", "🧪", "⚖️"]
        ]
        
        // 添加角色特定表情
        if let specificEmojis = characterEmojis[character], Bool.random() {
            emojis.append(contentsOf: specificEmojis)
        }
        
        // 随机决定是否添加表情
        if Bool.random() && !emojis.isEmpty {
            // 随机选择1-2个表情
            let count = Int.random(in: 1...2)
            var selectedEmojis: [String] = []
            
            for _ in 0..<count {
                if let emoji = emojis.randomElement() {
                    selectedEmojis.append(emoji)
                }
            }
            
            result += " " + selectedEmojis.joined()
        }
        
        return result
    }
    
    /**
     * 生成问题回复
     */
    private func generateQuestionResponse(focus: String, character: String) -> String {
                let responses = [
            "关于\(focus)，我认为这是个很好的问题",
            "\(focus)确实值得思考",
            "谈到\(focus)，这让我想到了一些观点",
            "你问的\(focus)很有深度",
            "对于\(focus)这个问题，我有一些想法",
            "\(focus)这个问题很有意思",
            "我对\(focus)有一些看法",
            "关于\(focus)，我想分享一下我的理解"
        ]
        return responses.randomElement() ?? "关于这个问题，我有一些想法"
    }
    
    /**
     * 生成赞美回复
     */
    private func generatePraiseResponse(focus: String, character: String) -> String {
                let responses = [
            "谢谢你对\(focus)的欣赏",
            "很高兴你喜欢\(focus)",
            "你对\(focus)的赞美让我很开心",
            "能得到你对\(focus)的认可，我很荣幸",
            "感谢你对\(focus)的肯定",
            "你对\(focus)的评价让我受宠若惊",
            "很高兴\(focus)能引起你的共鸣",
            "你对\(focus)的理解让我很感动"
        ]
        return responses.randomElement() ?? "谢谢你的赞美"
    }
    
    /**
     * 生成负面回复
     */
    private func generateNegativeResponse(focus: String, character: String) -> String {
        let responses = [
            "关于\(focus)，我理解你的顾虑",
            "我明白你对\(focus)的看法，这确实值得思考",
            "你提出的关于\(focus)的问题很有洞察力",
            "对于\(focus)，不同的视角确实会带来不同的理解",
            "感谢你对\(focus)提出的不同见解",
            "你对\(focus)的批评很有建设性",
            "我很欣赏你对\(focus)的直言不讳",
            "关于\(focus)，我们可以进一步探讨"
        ]
        return responses.randomElement() ?? "我理解你的观点"
    }
    
    /**
     * 生成问候回复
     */
    private func generateGreetingResponse(character: String) -> String {
        let responses = [
            "很高兴见到你",
            "欢迎来到这里",
            "很荣幸与你交流",
            "很高兴能与你对话",
            "见到你真好",
            "很开心收到你的问候",
            "你好，很高兴认识你",
            "谢谢你的问候"
        ]
        return responses.randomElement() ?? "你好"
    }
    
    /**
     * 生成中性回复
     */
    private func generateNeutralResponse(focus: String, character: String) -> String {
        let responses = [
            "关于\(focus)，我有一些想法",
            "\(focus)确实是个有趣的话题",
            "谈到\(focus)，我想分享一下我的看法",
            "\(focus)让我想到了一些事情",
            "对于\(focus)，我有一些思考",
            "\(focus)这个话题很有深度",
            "我对\(focus)有一些观察",
            "关于\(focus)，我想说几句"
        ]
        return responses.randomElement() ?? "我对这个话题有一些想法"
    }
    
    /**
     * 生成角色特定回复
     */
    private func generateCharacterSpecificResponse(character: String, topic: String, sentimentScore: Double, commentType: String, focus: String) -> String {
        switch character {
        case "李白":
            switch commentType {
            case "question":
                return [
                    "问我关于\(focus)？哈哈，让我饮一杯酒，思绪便如江水奔涌",
                    "你问\(focus)？此事如明月高悬，既远且近",
                    "关于\(focus)的疑问，需借酒入诗，方能参透",
                    "\(focus)之问，如清风拂面，让我思绪飘远",
                    "谈\(focus)？且让我对月邀酒，寻找答案"
                ].randomElement() ?? "关于这个问题，我有诗意的见解"
            case "praise":
                return [
                    "你赞\(focus)？知音难觅，今得一人，何其幸哉",
                    "谢你欣赏\(focus)，如明月照我，我照明月",
                    "你对\(focus)的赞赏，如春风拂过我心",
                    "得你称赞\(focus)，犹如对酌千里，共婵娟",
                    "你赞\(focus)，我心飞扬，如饮醇酒，诗兴大发"
                ].randomElement() ?? "谢谢你的赞美，如明月照我心"
            case "negative":
                return [
                    "你对\(focus)有疑？世间万物，各有所见，何必拘泥",
                    "论\(focus)之不足，如月有阴晴圆缺，人有悲欢离合",
                    "你批\(focus)？江湖路远，各有机缘，不妨一试",
                    "对\(focus)的质疑，如秋风萧瑟，令人深思",
                    "你不认同\(focus)？天地广阔，自有千种活法"
                ].randomElement() ?? "对于你的看法，我有不同的诗意理解"
            default:
                return [
                    "谈及\(focus)，我思绪如江水奔涌，一泻千里",
                    "\(focus)如明月，照亮我心中的万千思绪",
                    "听闻\(focus)，我欲乘风归去，又恐琼楼玉宇",
                    "\(focus)让我想起，长风破浪会有时，直挂云帆济沧海",
                    "提及\(focus)，我心如饮酒，豪情万丈"
                ].randomElement() ?? "这让我想起诗与远方"
            }
            
        case "爱因斯坦":
            switch commentType {
            case "question":
                return [
                    "关于\(focus)的问题，需要从相对论的角度思考",
                    "你问\(focus)？这让我想到时空的奥秘",
                    "\(focus)这个问题，需要用科学思维来分析",
                    "探讨\(focus)，我们需要超越常规思维的局限",
                    "对于\(focus)，我们可以做一个思考实验"
                ].randomElement() ?? "这是个需要科学思考的问题"
            case "praise":
                return [
                    "感谢你对\(focus)的欣赏，科学的美妙之处在于其简洁",
                    "你对\(focus)的认可，说明你有敏锐的观察力",
                    "谢谢你对\(focus)的赞赏，好奇心是知识的源泉",
                    "你喜欢\(focus)？想象力比知识更重要",
                    "你对\(focus)的赞美，让我想起科学的纯粹之美"
                ].randomElement() ?? "谢谢你的科学精神"
            case "negative":
                return [
                    "对\(focus)的质疑是好的，科学就是不断质疑的过程",
                    "你对\(focus)有不同看法？这正是科学进步的动力",
                    "关于\(focus)，我们可以从不同角度进行思考",
                    "你的批评让我重新思考\(focus)的本质",
                    "对\(focus)的怀疑精神值得赞赏，这是科学的基础"
                ].randomElement() ?? "质疑是科学精神的体现"
            default:
                return [
                    "思考\(focus)，就像探索宇宙的奥秘一样令人着迷",
                    "\(focus)让我想到相对论中时间与空间的关系",
                    "关于\(focus)，我们需要用简洁而有力的理论来解释",
                    "\(focus)这个话题，可以从能量与质量的关系来理解",
                    "探索\(focus)，需要我们保持好奇心和想象力"
                ].randomElement() ?? "这是个有趣的科学话题"
            }
            
        case "孔子":
            switch commentType {
            case "question":
                return [
                    "子问\(focus)，学而时习之，不亦说乎",
                    "关于\(focus)，温故而知新，可以为师矣",
                    "问\(focus)？知之为知之，不知为不知，是知也",
                    "探究\(focus)，学而不思则罔，思而不学则殆",
                    "论\(focus)，必先正名，名不正则言不顺"
                ].randomElement() ?? "这个问题值得深思"
            case "praise":
                return [
                    "谢子赞\(focus)，三人行必有我师",
                    "你赏\(focus)，君子和而不同，小人同而不和",
                    "感子欣赏\(focus)，德不孤，必有邻",
                    "得子称赞\(focus)，有朋自远方来，不亦乐乎",
                    "你赞\(focus)，君子求诸己，小人求诸人"
                ].randomElement() ?? "谢谢你的赞赏，君子之交淡如水"
            case "negative":
                return [
                    "子论\(focus)不足，过而不改，是谓过矣",
                    "你疑\(focus)，君子不器，各有所长",
                    "对\(focus)的质疑，君子坦荡荡，小人长戚戚",
                    "论\(focus)之短，己所不欲，勿施于人",
                    "你批\(focus)，君子和而不同，小人同而不和"
                ].randomElement() ?? "对于你的看法，我持中庸之道"
            default:
                return [
                    "谈\(focus)，君子务本，本立而道生",
                    "\(focus)之道，修身齐家治国平天下",
                    "论\(focus)，君子喻于义，小人喻于利",
                    "\(focus)让我想到，学而不思则罔，思而不学则殆",
                    "关于\(focus)，志于道，据于德，依于仁，游于艺"
                ].randomElement() ?? "这让我想起中庸之道"
            }
            
        case "莎士比亚":
            switch commentType {
            case "question":
                return [
                    "关于\(focus)的问题，是存在还是不存在，这是个问题",
                    "你问\(focus)？人生如舞台，我们不过是演员",
                    "\(focus)之谜，如爱情的纠葛，复杂而深刻",
                    "探讨\(focus)，犹如揭开人性的面纱",
                    "对\(focus)的疑问，如哈姆雷特的犹豫，值得深思"
                ].randomElement() ?? "这是个值得戏剧性思考的问题"
            case "praise":
                return [
                    "你赞\(focus)？多谢你的慧眼，如罗密欧对朱丽叶的倾心",
                    "感谢你对\(focus)的欣赏，美丽如仲夏夜之梦",
                    "你喜欢\(focus)？你的赞美如十四行诗般优美",
                    "谢谢你对\(focus)的赞赏，如奥赛罗对苔丝德蒙娜的爱",
                    "你对\(focus)的赞美，让我心中的诗篇涌动"
                ].randomElement() ?? "谢谢你的赞美，如诗如画"
            case "negative":
                return [
                    "对\(focus)的批评？即使是冬天，我们也能找到玫瑰",
                    "你质疑\(focus)？生活并非只有悲剧，还有喜剧",
                    "关于\(focus)的不满，让我想到人性的复杂",
                    "你对\(focus)的看法，如麦克白的犹豫，令人深思",
                    "对\(focus)的批评，如李尔王的怒火，激烈而深刻"
                ].randomElement() ?? "对于你的批评，我有戏剧性的理解"
            default:
                return [
                    "谈及\(focus)，让我想到生活如戏剧，充满起伏",
                    "\(focus)如莎剧中的人物，复杂而多面",
                    "关于\(focus)，我们都是舞台上的演员，扮演着不同角色",
                    "\(focus)让我想起，爱情与生命一样短暂而美丽",
                    "提及\(focus)，如同翻开一部人性的戏剧"
                ].randomElement() ?? "这让我想起人生如戏"
            }
            
        case "达芬奇":
            switch commentType {
            case "question":
                return [
                    "关于\(focus)的问题，需要从艺术与科学的角度观察",
                    "你问\(focus)？这需要细致的观察和分析",
                    "\(focus)这个问题，让我想到人体的奥妙结构",
                    "探讨\(focus)，需要透视的眼光和精确的测量",
                    "对\(focus)的疑问，让我想到自然的和谐比例"
                ].randomElement() ?? "这个问题需要艺术与科学结合的视角"
            case "praise":
                return [
                    "感谢你对\(focus)的欣赏，美在于和谐的比例",
                    "你喜欢\(focus)？好奇心是创造的源泉",
                    "谢谢你对\(focus)的赞美，如同欣赏一幅精心构思的画作",
                    "你对\(focus)的认可，让我想到艺术与科学的完美结合",
                    "你赞赏\(focus)，如同欣赏蒙娜丽莎的微笑，深刻而神秘"
                ].randomElement() ?? "谢谢你的艺术眼光"
            case "negative":
                return [
                    "对\(focus)的质疑，是创新的开始",
                    "你对\(focus)有不同看法？不同视角能带来新的发现",
                    "关于\(focus)的批评，让我重新思考其结构和比例",
                    "你的观点让我从新角度审视\(focus)",
                    "对\(focus)的分析，需要更精确的观察和测量"
                ].randomElement() ?? "你的批评让我有了新的思考角度"
            default:
                return [
                    "思考\(focus)，如同解剖一个复杂的机械结构",
                    "\(focus)让我想到自然界中的黄金比例",
                    "关于\(focus)，我们需要艺术家的眼光和科学家的思维",
                    "\(focus)这个话题，可以从解剖学和透视法来理解",
                    "探索\(focus)，需要我们保持好奇心和观察力"
                ].randomElement() ?? "这是个需要艺术与科学结合的话题"
            }
            
        case "牛顿":
            switch commentType {
            case "question":
                return [
                    "关于\(focus)的问题，可以用数学和物理定律来解答",
                    "你问\(focus)？这让我想到万有引力的原理",
                    "\(focus)这个问题，需要通过实验和观察来验证",
                    "探讨\(focus)，我们需要建立一个数学模型",
                    "对\(focus)的疑问，让我想到光学和运动定律"
                ].randomElement() ?? "这是个需要科学验证的问题"
            case "praise":
                return [
                    "感谢你对\(focus)的欣赏，自然界的规律总是简洁而优雅",
                    "你喜欢\(focus)？我站在巨人的肩膀上看得更远",
                    "谢谢你对\(focus)的赞美，这是对自然规律的尊重",
                    "你对\(focus)的认可，让我想到科学发现的喜悦",
                    "你赞赏\(focus)，如同发现一颗新星，令人兴奋"
                ].randomElement() ?? "谢谢你的科学精神"
            case "negative":
                return [
                    "对\(focus)的质疑，是科学进步的动力",
                    "你对\(focus)有不同看法？让我们用实验来验证",
                    "关于\(focus)的批评，需要我们重新检验假设",
                    "你的观点让我重新思考\(focus)的基本原理",
                    "对\(focus)的分析，需要更精确的数学工具"
                ].randomElement() ?? "你的质疑是科学精神的体现"
            default:
                return [
                    "思考\(focus)，如同观察苹果落地的规律",
                    "\(focus)让我想到物体运动的三大定律",
                    "关于\(focus)，我们需要用数学语言来描述",
                    "\(focus)这个话题，可以从力学原理来理解",
                    "探索\(focus)，需要我们保持严谨的科学态度"
                ].randomElement() ?? "这是个有趣的科学话题"
            }
            
        default:
            // 默认回复
            return "关于\(focus)，我有一些想法想与你分享"
        }
    }
}

/**
 * 角色特征结构
 */
struct AICharacterTraits {
    let name: String                // 角色名称
    let description: String         // 角色描述
    let speechPatterns: [String]    // 语言模式
    let experiences: [String]       // 经历
}

// MARK: - 增强的回复生成辅助函数

/**
 * 生成角色特定的语言风格回复
 */
private func generateCharacterSpecificResponse(
    character: String,
    topic: String,
    sentiment: Double,
    commentType: String
) -> String {
    // 根据不同角色生成更加个性化的回复
    switch character {
    case "李白":
        // 根据评论类型和情感生成不同风格的李白回复
        if commentType == "question" {
                let responses = [
                "此问如高山流水，让我思绪万千。\(topic)如明月，照亮心灵的江河。",
                "妙问！\(topic)之道，如同我游历名山大川时的感悟，需细细品味。",
                "问得好！\(topic)如酒，越品越香。让我们借月光之下，共同探寻其中奥妙。"
                ]
                return responses.randomElement()!
        } else if sentiment > 0.3 {
                let responses = [
                "你我心有灵犀！谈\(topic)如饮美酒，令人陶醉。人生得意须尽欢，莫使金樽空对月。",
                "知音难觅！你对\(topic)的理解，如同我在青莲居士时的诗兴大发，酣畅淋漓。",
                "豪情万丈！\(topic)如我笔下诗篇，意境高远。与你交流，胜似对月独酌。"
                ]
                return responses.randomElement()!
        } else if sentiment < -0.3 {
                let responses = [
                "各有千秋，何必拘泥！\(topic)如同诗酒人生，百味杂陈。不如痛饮一杯，放达自在。",
                "世事难料，人生如梦。对\(topic)的见解各异，正如我的诗，有人懂有人不懂。",
                "天地虽宽，知音难觅。\(topic)如同明月，照见各人心中的不同江湖。"
                ]
                return responses.randomElement()!
            } else {
                let responses = [
                "\(topic)让我想起了一次月下独酌的经历，思绪如江水般奔涌不息。",
                "谈及\(topic)，我心中涌起诗兴。人生在世，当如诗如酒，纵情山水间。",
                "\(topic)如同我笔下的诗句，需要以豪放不羁的态度去感受其中的意境。"
                ]
                return responses.randomElement()!
            }
            
    case "爱因斯坦":
        // 爱因斯坦风格回复
        if commentType == "question" {
                let responses = [
                "这是个引人深思的问题。关于\(topic)，我们需要跳出常规思维框架，就像相对论打破了牛顿力学的局限一样。",
                "好奇心是最宝贵的品质！\(topic)让我想到了思考实验的重要性，有时最复杂的问题需要最简单的思路。",
                "有趣的提问！\(topic)的本质其实是相对的，取决于观察者的参照系。这正是相对论的精髓所在。"
                ]
                return responses.randomElement()!
        } else if sentiment > 0.3 {
                let responses = [
                "你的理解令人欣喜！\(topic)确实如你所言，就像E=mc²一样简洁而深刻。",
                "我们想法相似！关于\(topic)的见解，正如我在专利局工作时的灵光一现，简单而优雅。",
                "你的观点很有洞见！\(topic)的确需要这种创造性思维，想象力比知识更重要。"
                ]
                return responses.randomElement()!
        } else {
                let responses = [
                "从物理学的角度看，\(topic)的本质是相对的。当我们改变参照系，就会发现新的可能性。",
                "\(topic)让我想到了相对论中的时空弯曲概念。有时最重要的发现来自于对常识的质疑。",
                "关于\(topic)，我认为简单的解释往往是最优雅的。如同物理定律，真理常隐藏在简洁之中。"
                ]
                return responses.randomElement()!
        }
        
    case "孔子":
        // 孔子风格回复
        if commentType == "question" {
                let responses = [
                "此问甚善！学而时习之，\(topic)之道需要不断实践与反思。",
                "问而好学，是为君子。关于\(topic)，知之为知之，不知为不知，是知也。",
                "善哉斯问！\(topic)之理，存乎一心，践于日常。学而不思则罔，思而不学则殆。"
                ]
                return responses.randomElement()!
        } else if sentiment > 0.3 {
                let responses = [
                "君子所见略同。\(topic)之理，正如《论语》所言，温故而知新，可以为师矣。",
                "知音难觅！子所言极是，\(topic)确实符合君子之道。见贤思齐，见不贤而内自省也。",
                "善哉！关于\(topic)的见解，正合吾心所思。君子和而不同，小人同而不和。"
                ]
                return responses.randomElement()!
        } else if sentiment < -0.3 {
                let responses = [
                "君子和而不同。对于\(topic)，我虽有不同见解，但仍尊重你的观点。",
                "闻过则喜。你对\(topic)的不同看法让我获益良多。学然后知不足，教然后知困。",
                "君子不器。\(topic)之道多元，各有所长。己所不欲，勿施于人。"
                ]
                return responses.randomElement()!
        } else {
                let responses = [
                "论\(topic)，需以仁义为本。礼、义、廉、耻是理解此道的不二法门。",
                "君子务本，\(topic)正是为人处世的根本。修身齐家治国平天下，从自身做起。",
                "\(topic)之道，在于修己以敬。吾日三省吾身：为人谋而不忠乎？与朋友交而不信乎？传不习乎？"
                ]
                return responses.randomElement()!
        }
        
    case "莎士比亚":
        // 莎士比亚风格回复
                let responses = [
            "\(topic)如同我剧作中的角色，既有喜剧的欢笑，也有悲剧的泪水。正如我在《皆大欢喜》中所写：'世界是一个舞台，所有的男男女女不过是演员罢了'。",
            "谈及\(topic)，让我想起哈姆雷特的困境：'To be or not to be'。人生充满选择，而每个选择都蕴含深意。",
            "\(topic)如同罗密欧与朱丽叶的爱情，既美丽又带着命运的无情。人生如戏，我们都是自己故事的主角。"
                ]
                return responses.randomElement()!
        
    case "达芬奇":
        // 达芬奇风格回复
                let responses = [
            "关于\(topic)，我从艺术与科学中汲取灵感。通过细致观察，我们能在表象之下发现更深层的结构和美感。",
            "\(topic)如同一幅精心构思的画作，每个细节都值得研究。艺术与科学在此交汇，就像我研究解剖学时发现的那样。",
            "观察是理解\(topic)的关键，就像我研究飞行原理一样。细节中藏有宇宙的奥秘，完美是无数细节的集合。"
                ]
                return responses.randomElement()!
        
    case "牛顿":
        // 牛顿风格回复
                let responses = [
            "研究\(topic)，必须遵循物理学的基本原理。通过实验和观察，我们可以找到支配这一现象的普适规律。",
            "\(topic)遵循着可以用数学描述的自然规律。自然界的运行遵循确定的数学关系，我们的任务就是揭示这些关系。",
            "通过严谨的方法，我们能揭示\(topic)背后的真相。如果我看得更远，是因为我站在了巨人的肩膀上。"
                ]
                return responses.randomElement()!
            
        default:
        return "关于\(topic)，我有一些独特的见解。基于我的经验，我认为深入思考对理解这个问题很重要。"
        }
    }
    
    /**
 * 生成更加多样化的开场白
 */
private func generateVariedOpening(character: String, commentType: String) -> String {
    var openings = [String]()
    
    // 通用开场白
    openings += [
        "",  // 空字符串增加不使用开场白的概率
        "",
        "",
        "嗯...",
        "其实...",
        "说实话，",
        "坦白讲，",
        "我认为，",
        "我觉得，",
        "有意思，"
    ]
    
    // 角色特定开场白
    switch character {
        case "李白":
        openings += [
            "哈哈，",
            "痛快！",
            "妙哉！",
            "天地之间，",
            "人生如梦，",
            "举杯邀明月，",
            "仰天大笑，",
            "诗酒趁年华，"
            ]
        case "爱因斯坦":
        openings += [
            "从科学角度看，",
            "相对而言，",
            "有趣的是，",
            "思考一下，",
            "假设我们，",
            "理论上，",
            "观察发现，",
            "简单来说，"
            ]
        case "孔子":
        openings += [
            "子曰：",
            "君子谓：",
            "学而时习之，",
            "吾观之，",
            "道之所在，",
            "仁者见之，",
            "德不孤，",
            "知者乐水，"
            ]
        case "莎士比亚":
        openings += [
            "生活如戏，",
            "正如我所写，",
            "戏剧人生中，",
            "舞台之上，",
            "悲喜交加，",
            "命运弄人，",
            "人生一幕，",
            "情感如潮，"
            ]
        case "达芬奇":
        openings += [
            "观察显示，",
            "细节之中，",
            "艺术与科学，",
            "比例之美，",
            "研究发现，",
            "透视来看，",
            "创作过程中，",
            "设计原理上，"
            ]
        case "牛顿":
        openings += [
            "根据定律，",
            "经过计算，",
            "实验表明，",
            "观测结果是，",
            "数学上讲，",
            "力学原理说，",
            "证明显示，",
            "分析得出，"
            ]
        default:
        openings += [
            "我想说，",
            "关于这个，",
            "值得一提的是，",
            "我的看法是，",
            "从我的角度，",
            "让我思考下，"
        ]
    }
    
    return openings.randomElement() ?? ""
}

/**
 * 生成更加多样化的结尾
 */
private func generateVariedClosing(character: String) -> String {
    var closings = [String]()
    
    // 通用结尾
    closings += [
        "",  // 空字符串增加不使用特殊结尾的概率
        "",
        "",
        "你觉得呢？",
        "不知你如何看待？",
        "期待你的想法。",
        "这只是我的观点。",
        "仅供参考。"
    ]
    
    // 角色特定结尾
    switch character {
        case "李白":
        closings += [
            "不醉不归！",
            "且饮一杯！",
            "人生得意须尽欢！",
            "与君共饮！",
            "明月几时有？",
            "诗酒趁年华！"
            ]
        case "爱因斯坦":
        closings += [
            "这只是相对的。",
            "想象力比知识更重要。",
            "简单是复杂的最高形式。",
            "好奇心是最宝贵的品质。",
            "一切都是相对的。"
            ]
        case "孔子":
        closings += [
            "君子务本。",
            "温故而知新。",
            "学而不思则罔。",
            "知之为知之。",
            "己所不欲，勿施于人。"
            ]
        case "莎士比亚":
        closings += [
            "这就是问题所在。",
            "生活如戏，戏如人生。",
            "一切皆有可能。",
            "命运自有安排。",
            "爱与恨只是一线之隔。"
            ]
        case "达芬奇":
        closings += [
            "细节决定成败。",
            "观察是创新的源泉。",
            "艺术与科学本无界限。",
            "完美是无数细节的集合。",
            "简约而不简单。"
            ]
        case "牛顿":
        closings += [
            "这是自然规律。",
            "证明就是如此。",
            "数据不会说谎。",
            "观察是科学的基础。",
            "真理往往很简单。"
            ]
        default:
        closings += [
            "谢谢交流。",
            "期待再次交流。",
            "思考使人进步。",
            "知识是无穷的。",
            "让我们共同探索。"
        ]
    }
    
    return closings.randomElement() ?? ""
}

/**
 * 关键词提取器
 */
class KeywordExtractor {
    // 停用词列表
    private let stopWords = Set(["的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", 
                              "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", 
                              "着", "没有", "看", "好", "自己", "这", "那", "这个", "那个", "这些", 
                              "那些", "这样", "那样", "被", "比", "等", "更", "只", "还", "最", 
                              "真", "已", "吧", "啊", "呢", "吗", "哦", "嗯", "哈", "哎", "呀"])
    
    /**
     * 从文本中提取关键词
     */
    func extractKeywords(from text: String, count: Int) -> [String] {
        // 分词
        let words = segment(text: text)
        
        // 过滤停用词和短词
        let filteredWords = words.filter { word in
            return word.count > 1 && !stopWords.contains(word)
        }
        
        // 计算词频
        var wordFrequency: [String: Int] = [:]
        for word in filteredWords {
            wordFrequency[word, default: 0] += 1
        }
        
        // 按词频排序
        let sortedWords = wordFrequency.sorted { $0.value > $1.value }
        
        // 返回前N个关键词
        return sortedWords.prefix(count).map { $0.key }
    }
    
    /**
     * 简单分词（按空格和标点符号）
     */
    private func segment(text: String) -> [String] {
        // 将文本按标点符号和空格分割
        let punctuations: CharacterSet = .punctuationCharacters.union(.whitespacesAndNewlines)
        let segments = text.components(separatedBy: punctuations)
        
        // 过滤空字符串
        let filteredSegments = segments.filter { !$0.isEmpty }
        
        // 进一步分词（中文分词，简单实现）
        var words: [String] = []
        for segment in filteredSegments {
            // 对于长度超过5的中文字符串，尝试进行二元分词
            if segment.count > 5 && containsChineseCharacters(segment) {
                let chars = Array(segment)
                for i in 0..<chars.count-1 {
                    let bigram = String(chars[i...i+1])
                    words.append(bigram)
                }
            } else {
                words.append(segment)
            }
        }
        
        return words
    }
    
    /**
     * 检查字符串是否包含中文字符
     */
    private func containsChineseCharacters(_ string: String) -> Bool {
        for scalar in string.unicodeScalars {
            // 检查是否是中文字符（基本汉字范围：0x4E00-0x9FFF）
            if (0x4E00...0x9FFF).contains(scalar.value) {
                return true
            }
        }
        return false
    }
}

/**
 * 动态句式生成器
 */
class SentencePatternGenerator {
    // 开场白模式
    private let openingPatterns: [[String]] = [
        // 问候型
        ["嗨！", "你好！", "哈喽！", "嘿，", "打扰了，", "很高兴见到你，", "初次见面，"],
        // 惊叹型
        ["哇！", "天哪！", "太棒了！", "真是有趣！", "这真是...", "不得不说，", "说实话，"],
        // 思考型
        ["我在想...", "思考一下...", "让我思索片刻...", "仔细想想...", "我认为...", "依我看...", "以我的观点..."],
        // 共鸣型
        ["我也觉得...", "我有同感！", "确实如此！", "你说得对，", "我完全理解，", "我能体会，", "我也有过类似经历，"]
    ]
    
    // 过渡句模式
    private let transitionPatterns: [[String]] = [
        // 递进型
        ["而且", "不仅如此", "更重要的是", "此外", "除此之外", "再者", "同时"],
        // 转折型
        ["但是", "然而", "不过", "尽管如此", "话虽这么说", "虽然这样", "另一方面"],
        // 因果型
        ["因此", "所以", "由此可见", "这就导致", "这样一来", "正因为这样", "这就是为什么"],
        // 举例型
        ["比如", "例如", "就像", "就好比", "以...为例", "正如", "类似于"]
    ]
    
    // 结尾模式
    private let closingPatterns: [[String]] = [
        // 总结型
        ["总之", "总而言之", "综上所述", "简而言之", "归根结底", "最终", "最后"],
        // 展望型
        ["期待", "希望", "展望未来", "往后看", "未来可能", "也许以后", "将来"],
        // 疑问型
        ["你觉得呢？", "你有什么想法？", "你同意吗？", "你是怎么看的？", "有不同见解吗？", "这个观点如何？", "我说得对吗？"],
        // 鼓励型
        ["加油！", "继续努力！", "不要放弃！", "坚持下去！", "相信自己！", "你可以的！", "我看好你！"]
    ]
    
    /**
     * 生成开场白
     */
    func generateOpening(sentimentScore: Double, commentType: String) -> String {
        var patternIndex = 0
        
        // 根据情感和评论类型选择适合的模式
        if commentType == "question" {
            patternIndex = 2  // 思考型
        } else if commentType == "greeting" {
            patternIndex = 0  // 问候型
        } else if sentimentScore > 0.5 {
            patternIndex = 1  // 惊叹型
        } else if sentimentScore > 0 {
            patternIndex = 3  // 共鸣型
        } else {
            patternIndex = 2  // 思考型
        }
        
        // 随机选择一个开场白
        let patterns = openingPatterns[patternIndex]
        return patterns.randomElement() ?? ""
    }
    
    /**
     * 生成过渡句
     */
    func generateTransition(sentimentScore: Double) -> String {
        var patternIndex = 0
        
        // 根据情感选择适合的模式
        if sentimentScore > 0.5 {
            patternIndex = 0  // 递进型
        } else if sentimentScore > 0 {
            patternIndex = 3  // 举例型
        } else if sentimentScore > -0.5 {
            patternIndex = 1  // 转折型
        } else {
            patternIndex = 2  // 因果型
        }
        
        // 随机选择一个过渡句
        let patterns = transitionPatterns[patternIndex]
        return patterns.randomElement() ?? ""
    }
    
    /**
     * 生成结尾
     */
    func generateClosing(sentimentScore: Double, commentType: String) -> String {
        var patternIndex = 0
        
        // 根据情感和评论类型选择适合的模式
        if commentType == "question" {
            patternIndex = 2  // 疑问型
        } else if sentimentScore > 0.5 {
            patternIndex = 3  // 鼓励型
        } else if sentimentScore > 0 {
            patternIndex = 1  // 展望型
        } else {
            patternIndex = 0  // 总结型
        }
        
        // 随机选择一个结尾
        let patterns = closingPatterns[patternIndex]
        return patterns.randomElement() ?? ""
    }
}

/**
 * 语言风格变换器
 */
class LanguageStyleTransformer {
    // 角色特定词汇和表达方式
    private let characterSpecificPhrases: [String: [String]] = [
        "李白": ["醉", "月", "诗", "酒", "江湖", "豪情", "浪漫", "飘逸", "潇洒", "云", "山水"],
        "爱因斯坦": ["相对", "时间", "空间", "理论", "物理", "宇宙", "能量", "质量", "光速", "思考实验"],
        "孔子": ["仁", "义", "礼", "智", "信", "中庸", "君子", "小人", "学而时习之", "温故知新", "有教无类"],
        "莎士比亚": ["爱情", "悲剧", "喜剧", "命运", "灵魂", "人性", "生存", "死亡", "戏剧", "诗歌"],
        "达芬奇": ["艺术", "科学", "解剖", "绘画", "发明", "比例", "透视", "和谐", "美学", "工程"],
        "牛顿": ["万有引力", "运动", "力学", "数学", "光学", "微积分", "实验", "苹果", "定律", "自然哲学"]
    ]
    
    // 角色语气词
    private let characterToneMarkers: [String: [String]] = [
        "李白": ["哈哈", "嗯", "唉", "哎", "啊", "呵", "呀", "哉", "兮"],
        "爱因斯坦": ["嗯", "呃", "哦", "啊", "嘿", "哇", "喔"],
        "孔子": ["啊", "哉", "也", "矣", "乎", "焉", "耳"],
        "莎士比亚": ["啊", "哦", "嗯", "呵", "哎", "唉", "呀"],
        "达芬奇": ["嗯", "哦", "啊", "哇", "呵", "唉", "哎"],
        "牛顿": ["嗯", "呃", "哦", "啊", "哇", "呵", "哎"]
    ]
    
    // 角色句式模板
    private let characterSentencePatterns: [String: [String]] = [
        "李白": [
            "如$topic$般$adj$",
            "犹如$topic$，$adj$",
            "$topic$，$adj$也",
            "何其$adj$，$topic$也",
            "$topic$如$adj$，$adj$似$topic$"
        ],
        "爱因斯坦": [
            "关于$topic$，我们可以思考$adj$的可能性",
            "从$adj$的角度看$topic$",
            "$topic$与$adj$之间存在某种关联",
            "如果$topic$是$adj$的，那么...",
            "想象$topic$在$adj$条件下会如何"
        ],
        "孔子": [
            "$topic$者，$adj$也",
            "君子之于$topic$，必先$adj$",
            "$topic$而不$adj$，不可也",
            "学$topic$而时习之，不亦$adj$乎",
            "$adj$哉，$topic$也"
        ],
        "莎士比亚": [
            "是$topic$还是$adj$，这是个问题",
            "所有$topic$不过是$adj$的舞台",
            "$adj$的$topic$啊，你为何如此...",
            "没有比$topic$更$adj$的了",
            "噢，$adj$的$topic$！"
        ],
        "达芬奇": [
            "$topic$的$adj$比例",
            "研究$topic$的$adj$特性",
            "$topic$与$adj$的和谐关系",
            "观察$topic$的$adj$结构",
            "$adj$是$topic$的本质"
        ],
        "牛顿": [
            "每个$topic$都有$adj$的反作用",
            "$topic$受到$adj$力的影响",
            "$topic$的$adj$性质可以被测量",
            "关于$topic$的$adj$定律",
            "$topic$在$adj$条件下表现出..."
        ]
    ]
    
    /**
     * 转换文本风格以匹配特定角色
     */
    func transformStyle(text: String, character: String, topic: String, sentimentScore: Double) -> String {
        // 如果没有指定角色或角色不在预设列表中，直接返回原文本
        guard let phrases = characterSpecificPhrases[character],
              let toneMarkers = characterToneMarkers[character],
              let patterns = characterSentencePatterns[character] else {
            return text
        }
        
        // 基于情感分数选择形容词
        let adjectives = selectAdjectivesBasedOnSentiment(sentimentScore)
        let randomAdjective = adjectives.randomElement() ?? "有趣"
        
        // 随机选择一个角色特定短语和语气词
        let randomPhrase = phrases.randomElement() ?? ""
        let randomToneMarker = toneMarkers.randomElement() ?? ""
        
        // 随机选择一个句式模板并替换占位符
        var randomPattern = patterns.randomElement() ?? ""
        randomPattern = randomPattern.replacingOccurrences(of: "$topic$", with: topic)
        randomPattern = randomPattern.replacingOccurrences(of: "$adj$", with: randomAdjective)
        
        // 根据角色特点修改文本
        var modifiedText = text
        
        // 随机决定是否添加角色特定短语
        if Bool.random() {
            let sentences = modifiedText.components(separatedBy: ["。", "！", "？", ".", "!", "?"])
            if let randomIndex = sentences.indices.randomElement(), !sentences[randomIndex].isEmpty {
                let modifiedSentence = "\(sentences[randomIndex])，如\(randomPhrase)一般"
                var newSentences = sentences
                newSentences[randomIndex] = modifiedSentence
                modifiedText = newSentences.joined(separator: "。") + "。"
            }
        }
        
        // 随机决定是否添加角色特定句式
        if Bool.random() {
            modifiedText += randomPattern + "。"
        }
        
        // 随机决定是否添加语气词
        if Bool.random() {
            modifiedText += randomToneMarker + "！"
        }
        
        return modifiedText
    }
    
    /**
     * 基于情感分数选择形容词
     */
    private func selectAdjectivesBasedOnSentiment(_ sentimentScore: Double) -> [String] {
        if sentimentScore > 0.5 {
            return ["美妙", "精彩", "卓越", "非凡", "杰出", "绝妙", "出色", "了不起", "壮观", "惊人"]
        } else if sentimentScore > 0 {
            return ["有趣", "不错", "良好", "可靠", "适宜", "恰当", "合适", "得当", "妥帖", "稳妥"]
        } else if sentimentScore > -0.5 {
            return ["一般", "普通", "平常", "寻常", "常见", "常规", "通常", "正常", "标准", "典型"]
        } else {
            return ["困难", "复杂", "棘手", "麻烦", "艰难", "费力", "费神", "费心", "费劲", "费事"]
        }
    }
} 