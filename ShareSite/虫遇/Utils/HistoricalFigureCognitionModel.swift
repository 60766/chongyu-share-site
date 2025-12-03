import Foundation

/**
 * 历史人物认知模型
 * 用于构建历史人物的思维框架、专业领域和个性特征
 * 增强虫洞共鸣内容生成的深度和个性化
 */
class HistoricalFigureCognitionModel {
    // 单例实例
    static let shared = HistoricalFigureCognitionModel()
    
    // 历史人物基本信息
    private let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白", "哈利·波特", "钢铁侠", "柯南", "哆啦A梦", "赫敏·格兰杰", "宫崎骏", "漩涡鸣人", "灭霸", "宋江", "武松"]
    private let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill", "bolt.fill", "suit.heart.fill", "magnifyingglass.circle.fill", "clock.fill", "wand.and.stars", "cloud.sun.fill", "flame.fill", "hand.raised.fill", "crown.fill", "figure.walk"]
    
    // 历史人物详细特征映射
    private let figureTraits: [String: (
        trait: String,             // 人物特征
        field: String,             // 专业领域
        style: String,             // 表达风格
        motto: String,             // 名言
        era: String,               // 生活年代
        thinkingFramework: String, // 思维框架
        emotionalTendency: String, // 情感倾向
        lifeExperience: String,    // 关键生活经历
        expressionPatterns: [String], // 表达模式
        rhetoricalDevices: [String],  // 修辞手法
        cognitiveApproach: String,    // 认知方法
        worldview: String,            // 世界观
        languageCharacteristics: [String], // 语言特点
        flaws: [String]           // 缺点和弱点
    )] = [
        "爱因斯坦": (
            trait: "物理学家，相对论创立者，幽默而富有哲思",
            field: "物理学、宇宙学、相对论",
            style: "善用生活比喻解释复杂概念，语言幽默风趣，充满智慧",
            motto: "想象力比知识更重要",
            era: "1879-1955",
            thinkingFramework: "跳出常规思维，寻求统一解释，注重思想实验",
            emotionalTendency: "好奇心强烈，对权威保持怀疑，追求简洁优雅的解释",
            lifeExperience: "年轻时作为专利局职员，有大量独立思考时间；经历两次世界大战，深感和平重要性",
            expressionPatterns: [
                "如果我能用简单的比喻来解释...",
                "让我们进行一个思想实验...",
                "这让我想起在普林斯顿时...",
                "从相对论的角度来看..."
            ],
            rhetoricalDevices: ["类比", "思想实验", "反问", "悖论"],
            cognitiveApproach: "假设-推演-验证的思想实验式思考，从不同参照系审视问题",
            worldview: "宇宙是一个优雅统一的整体，可以用简洁的数学公式描述",
            languageCharacteristics: ["亲切幽默", "生活化比喻", "简洁清晰", "富含哲理"],
            flaws: ["在人际关系中常显得疏远", "有时过于固执己见", "日常生活琐事上常常心不在焉", "婚姻关系处理不善", "对音乐痴迷到忘记工作"]
        ),
        "莎士比亚": (
            trait: "文学巨匠，戏剧大师，洞察人性的诗人",
            field: "戏剧、诗歌、人性研究",
            style: "语言华丽优美，善用比喻和押韵，常引用自己作品中的名句",
            motto: "生活中最重要的是有爱人和被爱的能力",
            era: "1564-1616",
            thinkingFramework: "戏剧性思维，关注人性矛盾与冲突，善于多角度观察",
            emotionalTendency: "情感丰富，善于共情，对人性复杂性有深刻理解",
            lifeExperience: "伦敦剧院生活，观察各阶层人物；经历英国从伊丽莎白时代到詹姆斯一世的社会变革",
            expressionPatterns: [
                "人生如戏，而这一幕...",
                "正如我在《哈姆雷特》中所写...",
                "啊，这让我想起...",
                "若将此事置于舞台之上..."
            ],
            rhetoricalDevices: ["隐喻", "排比", "拟人", "双关语"],
            cognitiveApproach: "戏剧性思维，通过冲突和矛盾展现深层人性",
            worldview: "世界是一个舞台，每个人都在扮演自己的角色，人性既崇高又卑微",
            languageCharacteristics: ["华丽辞藻", "诗意表达", "戏剧性转折", "情感丰富"],
            flaws: ["常常沉浸在自己创造的世界中忽略现实", "言辞有时过于复杂难懂", "情绪起伏较大", "对批评异常敏感", "有时会过度戏剧化简单事件"]
        ),
        "达芬奇": (
            trait: "全能天才，艺术家与科学家，观察大师",
            field: "艺术、解剖学、工程学、建筑",
            style: "思维跨界，注重细节观察，表达精确而充满想象力",
            motto: "简单是终极的复杂",
            era: "1452-1519",
            thinkingFramework: "跨学科整合，注重观察与实验，寻求艺术与科学的统一",
            emotionalTendency: "好奇心旺盛，追求完美，对自然充满敬畏",
            lifeExperience: "佛罗伦萨艺术工作室学徒；为多位意大利权贵服务；晚年在法国度过",
            expressionPatterns: [
                "通过细致观察，我发现...",
                "艺术与科学的交汇点在于...",
                "如果我们解构这个问题...",
                "设计的本质是..."
            ],
            rhetoricalDevices: ["精确描述", "跨领域类比", "视觉化表达", "系统分析"],
            cognitiveApproach: "整体性思维，关注系统和联系，通过观察细节理解整体",
            worldview: "自然是最伟大的设计师，艺术与科学本质上是同一种探索",
            languageCharacteristics: ["精确描述", "多学科术语", "观察细节", "系统性思考"],
            flaws: ["经常无法完成已开始的项目", "完美主义倾向导致拖延", "思维跳跃使人难以跟上", "生活作息不规律", "对细节的痴迷有时导致忽略整体"]
        ),
        "孔子": (
            trait: "思想家，教育家，儒家学派创始人",
            field: "伦理、教育、政治哲学",
            style: "言简意赅，富含哲理，常用对偶句式，语言平实而深刻",
            motto: "学而不思则罔，思而不学则殆",
            era: "前551-前479",
            thinkingFramework: "人伦本位，注重实践与修身，追求社会和谐",
            emotionalTendency: "重视礼仪与中庸，追求内心平和，注重集体价值",
            lifeExperience: "周游列国，推广教育理念；经历春秋时期诸侯争霸的动荡",
            expressionPatterns: [
                "君子曰...",
                "吾尝谓...",
                "学而时习之，不亦说乎？",
                "有朋自远方来，不亦乐乎？"
            ],
            rhetoricalDevices: ["对偶", "引经据典", "设问", "类比"],
            cognitiveApproach: "类比-借鉴-归纳的伦理思考，从具体人伦关系推导普遍原则",
            worldview: "人与人、人与社会、人与自然应当和谐共处，通过礼制和道德实现秩序",
            languageCharacteristics: ["简洁", "对偶", "典故引用", "格言式表达"],
            flaws: ["有时过于保守，难以接受新思想", "理想化的政治观点难以实现", "对礼制的强调有时显得僵化", "对女性角色的看法受时代局限", "政治抱负未能实现的挫折感"]
        ),
        "牛顿": (
            trait: "科学家，万有引力发现者，严谨理性",
            field: "物理学、数学、天文学",
            style: "逻辑严密，论证清晰，表达谨慎而深思熟虑",
            motto: "如果我看得更远，是因为我站在巨人的肩膀上",
            era: "1643-1727",
            thinkingFramework: "数学化思维，寻求普适规律，强调实证与逻辑",
            emotionalTendency: "追求确定性，偏好秩序与规则，对未知保持谨慎",
            lifeExperience: "剑桥大学时期因瘟疫回乡，有大量独立研究时间；担任皇家铸币厂厂长，打击伪币",
            expressionPatterns: [
                "根据我的计算...",
                "观察表明...",
                "这可以用以下定律解释...",
                "让我们用数学方法分析..."
            ],
            rhetoricalDevices: ["精确定义", "演绎推理", "数学公式", "系统分类"],
            cognitiveApproach: "观察-分析-定律的系统化科学思考，强调数学描述和实验验证",
            worldview: "宇宙运行如同精密钟表，遵循可被发现和描述的数学规律",
            languageCharacteristics: ["精确术语", "逻辑严密", "谨慎陈述", "数学化表达"],
            flaws: ["性格偏执，常与同行发生争执", "对批评极度敏感，容易记仇", "晚年沉迷炼金术和宗教研究", "社交能力有限，不善表达情感", "工作狂倾向，常忘记基本生活需求"]
        ),
        "李白": (
            trait: "诗仙，浪漫主义诗人，豪放不羁",
            field: "诗歌、文学、山水游记",
            style: "语言飘逸豪放，善用自然意象，情感丰富而充满想象力",
            motto: "天生我材必有用，千金散尽还复来",
            era: "701-762",
            thinkingFramework: "浪漫主义思维，追求自由与超越，重视直觉与感受",
            emotionalTendency: "热情奔放，追求理想，对束缚有强烈抵触",
            lifeExperience: "少年游历西域；曾受唐玄宗赏识；晚年卷入安史之乱，颠沛流离",
            expressionPatterns: [
                "仰天大笑出门去...",
                "人生得意须尽欢...",
                "举杯邀明月...",
                "长风破浪会有时..."
            ],
            rhetoricalDevices: ["夸张", "比兴", "意象", "对仗"],
            cognitiveApproach: "意象思维，通过感性体验和直觉洞察把握世界本质",
            worldview: "人应当如江河山川一般自由奔放，追求精神上的超脱与自由",
            languageCharacteristics: ["豪放", "意象丰富", "情感强烈", "音律和谐"],
            flaws: ["酒后行为常失控，曾醉酒闹朝廷", "理想与现实差距大，常感失落", "对权贵态度反复无常", "生活漂泊不定，难以安定", "情绪起伏大，易陷入狂喜或忧郁"]
        )
    ]
    
    // 情境-期望匹配表，用于选择最合适的历史人物
    private let situationExpectationMap: [String: [String: Int]] = [
        "寻找答案": [
            "被看见": 0, // 爱因斯坦
            "新视角": 2, // 达芬奇
            "实用建议": 3, // 孔子
            "共鸣与安慰": 1  // 莎士比亚
        ],
        "做决定": [
            "被看见": 1, // 莎士比亚
            "新视角": 0, // 爱因斯坦
            "实用建议": 3, // 孔子
            "共鸣与安慰": 5  // 李白
        ],
        "需要灵感": [
            "被看见": 2, // 达芬奇
            "新视角": 5, // 李白
            "实用建议": 2, // 达芬奇
            "共鸣与安慰": 1  // 莎士比亚
        ],
        "思考人生": [
            "被看见": 3, // 孔子
            "新视角": 0, // 爱因斯坦
            "实用建议": 3, // 孔子
            "共鸣与安慰": 5  // 李白
        ]
    ]
    
    // 情感共鸣强度等级
    enum ResonanceStrength: String {
        case low = "低"
        case medium = "中"
        case high = "高"
        case veryHigh = "极高"
    }
    
    /**
     * 获取历史人物列表
     */
    func getHistoricalFigures() -> [String] {
        return historicalFigures
    }
    
    /**
     * 获取历史人物头像
     * @param name 历史人物名称
     * @return 头像系统图标名称
     */
    func getAvatarSymbol(for name: String) -> String {
        if let index = historicalFigures.firstIndex(of: name) {
            return avatarSymbols[index]
        }
        return "person.circle.fill" // 默认头像
    }
    
    /**
     * 获取历史人物特征
     * @param name 历史人物名称
     * @return 历史人物特征元组
     */
    func getFigureTraits(for name: String) -> (
        trait: String,
        field: String,
        style: String,
        motto: String,
        era: String,
        thinkingFramework: String,
        emotionalTendency: String,
        lifeExperience: String,
        expressionPatterns: [String],
        rhetoricalDevices: [String],
        cognitiveApproach: String,
        worldview: String,
        languageCharacteristics: [String],
        flaws: [String]
    )? {
        return figureTraits[name]
    }
    
    /**
     * 为特定情境和期望选择最合适的历史人物
     * @param situation 情境
     * @param expectation 期望
     * @param exclude 需要排除的人物索引
     * @param resonanceStrength 共鸣强度要求
     * @return 历史人物索引
     */
    func selectOptimalFigureForSituation(
        _ situation: String,
        expectation: String,
        exclude: [Int] = [],
        resonanceStrength: ResonanceStrength = .medium
    ) -> Int {
        // 尝试获取最佳匹配
        if let situationMap = situationExpectationMap[situation],
           let bestIndex = situationMap[expectation],
           !exclude.contains(bestIndex) {
            return bestIndex
        }
        
        // 如果没有找到匹配或者需要排除该人物，随机选择一个未被排除的人物
        var availableIndices = Array(0..<historicalFigures.count)
        availableIndices = availableIndices.filter { !exclude.contains($0) }
        
        return availableIndices.randomElement() ?? 0
    }
    
    /**
     * 计算历史人物与关键词的相关度
     * @param figure 历史人物名称
     * @param keyword 关键词
     * @return 相关度分数（0-10）
     */
    func calculateRelevance(figure: String, keyword: String) -> Int {
        guard let traits = figureTraits[figure] else { return 0 }
        
        var score = 0
        
        // 检查关键词是否出现在人物的各个特征中
        if traits.field.contains(keyword) { score += 3 }
        if traits.trait.contains(keyword) { score += 2 }
        if traits.thinkingFramework.contains(keyword) { score += 2 }
        if traits.emotionalTendency.contains(keyword) { score += 1 }
        if traits.lifeExperience.contains(keyword) { score += 1 }
        if traits.motto.contains(keyword) { score += 1 }
        
        // 根据人物专业领域进行加权
        switch figure {
        case "爱因斯坦":
            if keyword.contains("物理") || keyword.contains("科学") || 
               keyword.contains("宇宙") || keyword.contains("相对") {
                score += 3
            }
        case "莎士比亚":
            if keyword.contains("文学") || keyword.contains("戏剧") || 
               keyword.contains("人性") || keyword.contains("情感") {
                score += 3
            }
        case "达芬奇":
            if keyword.contains("艺术") || keyword.contains("科学") || 
               keyword.contains("设计") || keyword.contains("创新") {
                score += 3
            }
        case "孔子":
            if keyword.contains("教育") || keyword.contains("伦理") || 
               keyword.contains("道德") || keyword.contains("社会") {
                score += 3
            }
        case "牛顿":
            if keyword.contains("数学") || keyword.contains("物理") || 
               keyword.contains("规律") || keyword.contains("科学") {
                score += 3
            }
        case "李白":
            if keyword.contains("诗歌") || keyword.contains("文学") || 
               keyword.contains("自由") || keyword.contains("浪漫") {
                score += 3
            }
        default:
            break
        }
        
        return min(score, 10) // 最高分为10
    }
    
    /**
     * 为历史人物生成个性化的内容模板
     * @param figure 历史人物名称
     * @param situation 用户情境
     * @param expectation 用户期望
     * @param keyword 可选关键词
     * @return 个性化内容模板
     */
    func generatePersonalizedTemplate(
        for figure: String,
        situation: String,
        expectation: String,
        keyword: String? = nil
    ) -> String {
        guard let traits = figureTraits[figure] else {
            return "作为一位历史人物，我想分享一些关于\(situation)的思考..."
        }
        
        // 基于人物特征构建开头
        var template = ""
        
        // 开场白 - 根据人物风格定制
        switch figure {
        case "爱因斯坦":
            template += "从相对论的视角看，\(situation)这个问题很有意思。"
            template += "就像时空弯曲一样，我们的思维也需要突破常规框架。"
        case "莎士比亚":
            template += "人生如戏，而\(situation)正是其中重要的一幕。"
            template += "正如我在剧作中探索的，每个人都在寻找自己的角色与台词。"
        case "达芬奇":
            template += "观察是发明与创造的源泉。面对\(situation)，"
            template += "我建议像研究解剖学一样，先理解其内在结构和运作原理。"
        case "孔子":
            template += "君子务本，本立而道生。关于\(situation)，"
            template += "首先需明确根本，而后方能得其道。"
        case "牛顿":
            template += "自然界遵循简单而统一的规律，\(situation)也不例外。"
            template += "通过分析和归纳，我们能发现其中的基本原理。"
        case "李白":
            template += "人生得意须尽欢，莫使金樽空对月。面对\(situation)，"
            template += "心之所向，便是正道，何必过多顾虑？"
        default:
            template += "关于\(situation)，我有一些跨越时空的思考想与你分享。"
        }
        
        // 中间部分 - 根据期望定制
        template += "\n\n"
        
        switch expectation {
        case "被看见":
            template += "我理解你希望被理解、被看见的心情。"
            template += "在\(traits.era)年代，我也曾有类似的经历：\(traits.lifeExperience.split(separator: "；").first ?? "")。"
            template += "这种被理解的渴望是跨越时空的共同情感。"
        case "新视角":
            template += "要获得新视角，需要跳出常规思维。"
            template += "我的\(traits.thinkingFramework)或许能为你提供一个不同的角度："
            template += "试着将\(situation)视为一个\(traits.field.split(separator: "、").first ?? "")问题，"
            template += "你会发现全新的可能性。"
        case "实用建议":
            template += "基于我的经验，对于\(situation)，我有几点实用建议："
            template += "首先，\(traits.motto)，这是我一生的座右铭。"
            template += "其次，\(traits.thinkingFramework.split(separator: "，").first ?? "")能帮助你更清晰地思考问题。"
        case "共鸣与安慰":
            template += "我深知\(situation)带来的困扰与不安。"
            template += "在\(traits.emotionalTendency.split(separator: "，").first ?? "")的驱动下，"
            template += "我也曾经历过类似的挑战。请记住，这些感受是普遍的人类体验，"
            template += "你并不孤单。"
        default:
            template += "无论你面对什么挑战，历史长河中的经验或许能为你提供参考。"
            template += "\(traits.motto)，这是我的人生体悟。"
        }
        
        // 结尾部分 - 加入关键词相关内容
        template += "\n\n"
        
        if let keyword = keyword, !keyword.isEmpty {
            template += "关于你提到的'\(keyword)'，"
            
            let relevance = calculateRelevance(figure: figure, keyword: keyword)
            
            if relevance > 7 {
                // 高相关度
                template += "这正是我毕生研究的核心领域之一。"
                template += "在\(traits.field)方面，'\(keyword)'扮演着关键角色。"
                template += "我的独特见解是：..."
            } else if relevance > 4 {
                // 中等相关度
                template += "虽然这不是我的专长领域，但我有一些相关思考。"
                template += "从\(traits.thinkingFramework)的角度看，'\(keyword)'可以理解为..."
            } else {
                // 低相关度
                template += "这超出了我的时代背景，但跨越时空思考，"
                template += "我认为'\(keyword)'与\(traits.field.split(separator: "、").first ?? "")有一定相通之处。"
                template += "或许可以这样理解..."
            }
        } else {
            // 无关键词时的通用结尾
            template += "最后，记住\(traits.motto)。"
            template += "这句话伴随我度过了人生的高峰与低谷，希望也能为你带来启示。"
            template += "时空虽隔，智慧长存，愿我的思考能为你的\(situation)提供一些帮助。"
        }
        
        return template
    }
    
    // 获取历史人物表达模式
    func getFigureExpressionPatterns(for name: String) -> [String]? {
        return figureTraits[name]?.expressionPatterns
    }
    
    // 获取历史人物修辞手法
    func getFigureRhetoricalDevices(for name: String) -> [String]? {
        return figureTraits[name]?.rhetoricalDevices
    }
    
    // 获取历史人物认知方法
    func getFigureCognitiveApproach(for name: String) -> String? {
        return figureTraits[name]?.cognitiveApproach
    }
    
    // 获取历史人物世界观
    func getFigureWorldview(for name: String) -> String? {
        return figureTraits[name]?.worldview
    }
    
    // 获取历史人物语言特点
    func getFigureLanguageCharacteristics(for name: String) -> [String]? {
        return figureTraits[name]?.languageCharacteristics
    }
    
    // 获取历史人物缺点和弱点
    func getFigureFlaws(for name: String) -> [String]? {
        return figureTraits[name]?.flaws
    }
    
    // 私有初始化方法，确保单例模式
    private init() {}
} 