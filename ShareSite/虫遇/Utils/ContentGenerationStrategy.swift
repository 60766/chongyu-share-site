import Foundation

/**
 * 内容生成策略
 * 实现多层次内容生成模型，增强虫洞共鸣内容的深度和多样性
 */
class ContentGenerationStrategy {
    // 单例实例
    static let shared = ContentGenerationStrategy()
    
    // 历史人物认知模型
    private let cognitionModel = HistoricalFigureCognitionModel.shared
    
    // 内容生成层次
    enum ContentLayer {
        case surface       // 表层内容：基本回应
        case contextual    // 情境内容：考虑用户当前情境
        case personalized  // 个性化内容：融入用户关键词和兴趣
        case interactive   // 互动内容：引导用户进一步思考
        case emotional     // 情感内容：建立情感连接
        case cognitive     // 认知内容：展现人物独特思维方式
        case worldview     // 世界观内容：表达人物核心价值观
    }
    
    // 内容生成风格
    enum ContentStyle {
        case formal        // 正式学术风格
        case poetic        // 诗意文学风格
        case philosophical // 哲学思辨风格
        case practical     // 实用建议风格
        case narrative     // 叙事故事风格
        case humorous      // 幽默风趣风格
    }
    
    /**
     * 根据历史人物选择合适的内容风格
     * @param figure 历史人物名称
     * @return 内容风格
     */
    func styleForFigure(_ figure: String) -> ContentStyle {
        switch figure {
        case "爱因斯坦":
            return .philosophical
        case "莎士比亚":
            return .poetic
        case "达芬奇":
            return .formal
        case "孔子":
            return .philosophical
        case "牛顿":
            return .formal
        case "李白":
            return .poetic
        default:
            return .narrative
        }
    }
    
    /**
     * 生成多层次内容
     * @param figure 历史人物名称
     * @param situation 用户情境
     * @param expectation 用户期望
     * @param keyword 关键词
     * @param includeLayers 需要包含的内容层次
     * @return 生成的内容
     */
    func generateLayeredContent(
        figure: String,
        situation: String,
        expectation: String,
        keyword: String? = nil,
        includeLayers: Set<ContentLayer> = [.surface, .contextual, .personalized, .cognitive, .worldview]
    ) -> String {
        // 获取基础模板
        let baseTemplate = cognitionModel.generatePersonalizedTemplate(
            for: figure,
            situation: situation,
            expectation: expectation,
            keyword: keyword
        )
        
        // 如果只需要表层内容，直接返回基础模板
        if includeLayers == [.surface] {
            return baseTemplate
        }
        
        // 根据历史人物选择内容风格
        let style = styleForFigure(figure)
        
        // 构建多层次内容
        var content = baseTemplate
        
        // 添加认知内容层 - 展现人物独特思维方式
        if includeLayers.contains(.cognitive) {
            content = enrichWithCognitiveLayer(content, figure: figure, situation: situation)
        }
        
        // 添加情境内容层
        if includeLayers.contains(.contextual) {
            content = enrichWithContextualLayer(content, figure: figure, situation: situation, style: style)
        }
        
        // 添加个性化内容层
        if includeLayers.contains(.personalized) && keyword != nil {
            content = enrichWithPersonalizedLayer(content, figure: figure, keyword: keyword!, style: style)
        }
        
        // 添加世界观内容层 - 表达人物核心价值观
        if includeLayers.contains(.worldview) {
            content = enrichWithWorldviewLayer(content, figure: figure, expectation: expectation)
        }
        
        // 添加互动内容层
        if includeLayers.contains(.interactive) {
            content = enrichWithInteractiveLayer(content, figure: figure, situation: situation, style: style)
        }
        
        // 添加情感内容层
        if includeLayers.contains(.emotional) {
            content = enrichWithEmotionalLayer(content, figure: figure, expectation: expectation, style: style)
        }
        
        // 应用人物特有的表达模式和修辞手法
        content = applyFigureExpressionStyle(content, figure: figure)
        
        return content
    }
    
    /**
     * 丰富认知内容层
     * 展现历史人物独特的思维方式
     */
    private func enrichWithCognitiveLayer(_ content: String, figure: String, situation: String) -> String {
        guard let cognitiveApproach = cognitionModel.getFigureCognitiveApproach(for: figure) else {
            return content
        }
        
        var enrichedContent = content
        
        // 根据不同情境，展示人物如何运用其认知方法
        let cognitiveApplications: [String: [String]] = [
            "寻找答案": [
                "当我寻找问题的答案时，我通常采用%@。这种思考方式让我能够看到常人忽略的联系。",
                "面对未知问题，%@是我的思考利器。它帮助我在复杂中找到简单，在混沌中发现秩序。",
                "我发现%@特别适合解决需要突破常规思维的问题。"
            ],
            "做决定": [
                "在做重要决定时，我依靠%@。这种方法让我能够全面评估各种可能性。",
                "决策过程中，%@帮助我避开情绪的干扰，找到最合理的选择。",
                "我认为做决定时最重要的是%@，这样才能确保决策的稳健性。"
            ],
            "需要灵感": [
                "灵感并非凭空而来，我通过%@激发创造力。这种方法让思想自由流动。",
                "当我需要新想法时，%@总能打开我思维的新通道。",
                "创新思考需要方法，我发现%@是连接看似不相关概念的桥梁。"
            ],
            "思考人生": [
                "对于人生的深层思考，我采用%@。这帮助我超越表面现象，触及本质。",
                "思考人生意义时，%@让我能够同时关注细节和全局。",
                "我通过%@来审视自己的生活和选择，这为我提供了独特的洞察力。"
            ]
        ]
        
        // 选择一个认知应用场景
        if let applications = cognitiveApplications[situation], let application = applications.randomElement() {
            let cognitiveContent = String(format: application, cognitiveApproach)
            enrichedContent += "\n\n" + cognitiveContent
        }
        
        return enrichedContent
    }
    
    /**
     * 丰富世界观内容层
     * 表达历史人物的核心价值观和世界观
     */
    private func enrichWithWorldviewLayer(_ content: String, figure: String, expectation: String) -> String {
        guard let worldview = cognitionModel.getFigureWorldview(for: figure) else {
            return content
        }
        
        var enrichedContent = content
        
        // 根据不同期望，展示人物世界观的不同侧面
        let worldviewApplications: [String: [String]] = [
            "被看见": [
                "我一直相信，%@。这种信念让我能够理解你被看见的渴望。",
                "在我的世界观中，%@。这也是为什么我能理解你希望被真正理解的心情。",
                "我的核心信念是%@。正是这种观点让我能够看到每个人的独特价值。"
            ],
            "新视角": [
                "我的世界观可以概括为：%@。这种视角或许能为你提供一个全新的思考角度。",
                "我始终认为%@。这种独特视角可能会启发你看待问题的新方式。",
                "在我看来，%@。这种思维方式打破了常规，或许能给你带来启示。"
            ],
            "实用建议": [
                "基于我的信念——%@，我认为最实用的建议往往源于对基本原则的理解。",
                "我的世界观是%@。这一原则可以指导你做出更明智的选择。",
                "我一生都在践行%@这一理念。这种实用哲学可能对你当前的情况有所帮助。"
            ],
            "共鸣与安慰": [
                "在我最困难的时刻，支持我的信念是%@。希望这也能给你带来一些安慰。",
                "我发现%@这一世界观在面对挑战时特别有力量。它提醒我们，困境并非永恒。",
                "我始终相信%@。正是这种信念让我能够与你的处境产生共鸣。"
            ]
        ]
        
        // 选择一个世界观应用场景
        if let applications = worldviewApplications[expectation], let application = applications.randomElement() {
            let worldviewContent = String(format: application, worldview)
            enrichedContent += "\n\n" + worldviewContent
        }
        
        return enrichedContent
    }
    
    /**
     * 丰富情境内容层
     * 根据用户情境提供更具体的内容
     */
    private func enrichWithContextualLayer(_ content: String, figure: String, situation: String, style: ContentStyle) -> String {
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        var enrichedContent = content
        let situationContexts: [String: [String]] = [
            "寻找答案": [
                "在探索未知时，保持好奇心是关键。",
                "问题本身常常比答案更有价值。",
                "有时答案就在我们意想不到的地方。"
            ],
            "做决定": [
                "决策时，权衡利弊只是第一步。",
                "最困难的决定往往需要直面内心真正的渴望。",
                "有时不做决定本身就是一种决定。"
            ],
            "需要灵感": [
                "灵感常在意想不到的时刻降临。",
                "创造力需要不同领域知识的碰撞。",
                "有时需要暂时远离问题，答案才会浮现。"
            ],
            "思考人生": [
                "人生的意义不在于寻找答案，而在于体验过程。",
                "了解自己比了解世界更困难，却更重要。",
                "真正的智慧是知道自己不知道什么。"
            ]
        ]
        
        // 根据情境选择合适的上下文内容
        if let contexts = situationContexts[situation], let context = contexts.randomElement() {
            // 根据不同风格添加情境内容
            switch style {
            case .formal:
                enrichedContent += "\n\n从\(traits.field)的角度分析，\(context)这一点在\(situation)的情境中尤为重要。"
            case .poetic:
                enrichedContent += "\n\n如同\(traits.field)中所探索的，\(context)这种体验如同一场心灵的旅程。"
            case .philosophical:
                enrichedContent += "\n\n思考\(situation)时，我常常发现\(context)这一哲理在不同时空中依然闪耀着智慧的光芒。"
            case .practical:
                enrichedContent += "\n\n在处理\(situation)的实际问题时，请记住\(context)这会为你提供一个清晰的方向。"
            case .narrative:
                enrichedContent += "\n\n我曾经历过类似的\(situation)。那时我发现\(context)这个道理改变了我的视角。"
            case .humorous:
                enrichedContent += "\n\n面对\(situation)，有时我们太认真反而看不清。记住，\(context)说不定答案就在你发笑的瞬间。"
            }
        }
        
        return enrichedContent
    }
    
    /**
     * 丰富个性化内容层
     * 根据用户关键词提供更具针对性的内容
     */
    private func enrichWithPersonalizedLayer(_ content: String, figure: String, keyword: String, style: ContentStyle) -> String {
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        var enrichedContent = content
        
        // 计算关键词与历史人物的相关度
        let relevance = cognitionModel.calculateRelevance(figure: figure, keyword: keyword)
        
        // 根据不同风格和相关度添加个性化内容
        if relevance > 7 {
            // 高相关度
            switch style {
            case .formal:
                enrichedContent += "\n\n关于'\(keyword)'，我在\(traits.field)中进行过深入研究。具体来说，..."
            case .poetic:
                enrichedContent += "\n\n'\(keyword)'如同\(traits.field)中的一颗明珠，闪耀着独特的光芒。我曾写道..."
            case .philosophical:
                enrichedContent += "\n\n'\(keyword)'引发了我对\(traits.field)本质的思考。在我看来，..."
            case .practical:
                enrichedContent += "\n\n在实践中运用'\(keyword)'的关键在于..."
            case .narrative:
                enrichedContent += "\n\n我与'\(keyword)'的故事始于..."
            case .humorous:
                enrichedContent += "\n\n说到'\(keyword)'，这让我想起一个有趣的经历..."
            }
        } else if relevance > 3 {
            // 中等相关度
            switch style {
            case .formal:
                enrichedContent += "\n\n虽然'\(keyword)'不是我的专长领域，但从\(traits.field)的角度看，..."
            case .poetic:
                enrichedContent += "\n\n'\(keyword)'如同远方的星辰，虽不在我的天空，却同样闪烁着光芒..."
            case .philosophical:
                enrichedContent += "\n\n思考'\(keyword)'时，我们可以借鉴\(traits.field)中的一些原理..."
            case .practical:
                enrichedContent += "\n\n处理'\(keyword)'相关问题时，可以尝试这样的方法..."
            case .narrative:
                enrichedContent += "\n\n虽然我的时代没有'\(keyword)'，但类似的概念让我想起..."
            case .humorous:
                enrichedContent += "\n\n如果我的时代有'\(keyword)'，或许我会..."
            }
        } else {
            // 低相关度
            enrichedContent += "\n\n虽然'\(keyword)'超出了我的时代背景，但人类的基本需求和挑战是相通的。或许，..."
        }
        
        return enrichedContent
    }
    
    /**
     * 丰富互动内容层
     * 添加引导用户思考的问题或建议
     */
    private func enrichWithInteractiveLayer(_ content: String, figure: String, situation: String, style: ContentStyle) -> String {
        var enrichedContent = content
        
        // 根据情境准备开放性问题
        let openQuestions: [String: [String]] = [
            "寻找答案": [
                "你是否考虑过问题本身可能需要重新定义？",
                "答案可能不止一个，你最希望找到哪种类型的答案？",
                "如果暂时找不到答案，这个过程本身对你有什么启发？"
            ],
            "做决定": [
                "在做这个决定时，你最担心的是什么？",
                "如果回顾未来，你希望自己现在做出什么选择？",
                "这个决定对你人生的意义是什么？"
            ],
            "需要灵感": [
                "你尝试过从完全不相关的领域寻找灵感吗？",
                "如果没有任何限制，你会如何发挥创意？",
                "有时灵感来自于限制，你能为自己设定什么有创意的约束吗？"
            ],
            "思考人生": [
                "什么是你生命中最珍视的价值？",
                "如果可以给年轻的自己一个建议，会是什么？",
                "你希望在生命的终点回首时，看到自己实现了什么？"
            ]
        ]
        
        // 选择一个开放性问题
        if let questions = openQuestions[situation], let question = questions.randomElement() {
            // 根据不同风格添加互动内容
            switch style {
            case .formal:
                enrichedContent += "\n\n作为进一步的思考，我想请你考虑：\(question)"
            case .poetic:
                enrichedContent += "\n\n让我们一起探索这个问题：\(question)"
            case .philosophical:
                enrichedContent += "\n\n值得深思的是：\(question)"
            case .practical:
                enrichedContent += "\n\n为了更好地应用这些想法，请思考：\(question)"
            case .narrative:
                enrichedContent += "\n\n在你的故事中，或许可以问自己：\(question)"
            case .humorous:
                enrichedContent += "\n\n这可能听起来有点奇怪，但试着想想：\(question)"
            }
        }
        
        return enrichedContent
    }
    
    /**
     * 丰富情感内容层
     * 增加情感共鸣和连接
     */
    private func enrichWithEmotionalLayer(_ content: String, figure: String, expectation: String, style: ContentStyle) -> String {
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        var enrichedContent = content
        
        // 根据期望选择情感内容
        let emotionalContent: [String: [String]] = [
            "被看见": [
                "被理解的渴望是人类共通的情感",
                "每个人都希望自己的声音被听到",
                "真正的连接来自于被真实地看见"
            ],
            "新视角": [
                "突破思维的局限往往伴随着不适感",
                "新的视角可以照亮我们从未注意的角落",
                "改变看问题的方式，问题本身也会改变"
            ],
            "实用建议": [
                "知行合一是智慧的真谛",
                "最有价值的建议往往源于亲身经历",
                "实践出真知，行动是最好的老师"
            ],
            "共鸣与安慰": [
                "痛苦中，知道不是一个人承受，就是最大的安慰",
                "理解比解决更重要，共情比建议更有力量",
                "人生的旅途上，我们都是彼此的同行者"
            ]
        ]
        
        // 选择一个情感内容
        if let emotions = emotionalContent[expectation], let emotion = emotions.randomElement() {
            // 根据不同风格添加情感内容
            switch style {
            case .formal:
                enrichedContent += "\n\n在结束之前，我想说：\(emotion)。这是我从\(traits.era)年代到现在的体悟。"
            case .poetic:
                enrichedContent += "\n\n如同星河流转，时光荏苒，但\(emotion)。这份情感跨越时空，与你共鸣。"
            case .philosophical:
                enrichedContent += "\n\n无论时代如何变迁，\(emotion)。这是人类永恒的智慧。"
            case .practical:
                enrichedContent += "\n\n请记住，\(emotion)。这不仅是一种认知，更是一种力量。"
            case .narrative:
                enrichedContent += "\n\n在我的故事结尾，我想与你分享：\(emotion)。愿这个领悟能伴随你前行。"
            case .humorous:
                enrichedContent += "\n\n说了这么多，其实最想告诉你：\(emotion)。这可能是我穿越时空最想传达的信息。"
            }
        }
        
        return enrichedContent
    }
    
    /**
     * 应用历史人物特有的表达模式和修辞手法
     * 使内容更具个性化特征
     */
    private func applyFigureExpressionStyle(_ content: String, figure: String) -> String {
        // 获取人物特有的表达模式
        guard let expressionPatterns = cognitionModel.getFigureExpressionPatterns(for: figure),
              let rhetoricalDevices = cognitionModel.getFigureRhetoricalDevices(for: figure),
              let languageCharacteristics = cognitionModel.getFigureLanguageCharacteristics(for: figure) else {
            return content
        }
        
        var styledContent = content
        
        // 随机选择一个表达模式插入到内容中
        if let expressionPattern = expressionPatterns.randomElement() {
            // 确保不重复添加表达模式
            if !styledContent.contains(expressionPattern) {
                let insertPosition = styledContent.count / 2 // 在内容中间位置插入
                let index = styledContent.index(styledContent.startIndex, offsetBy: min(insertPosition, styledContent.count))
                
                // 找到最近的段落结束位置
                var insertIndex = styledContent.index(before: index)
                while insertIndex > styledContent.startIndex && styledContent[insertIndex] != "。" {
                    insertIndex = styledContent.index(before: insertIndex)
                }
                
                if styledContent[insertIndex] == "。" {
                    insertIndex = styledContent.index(after: insertIndex)
                }
                
                styledContent.insert(contentsOf: "\n\n\(expressionPattern) ", at: insertIndex)
            }
        }
        
        // 根据人物的修辞特点调整内容风格
        if let rhetoricalDevice = rhetoricalDevices.randomElement(),
           let languageCharacteristic = languageCharacteristics.randomElement() {
            
            // 添加风格说明作为结尾
            styledContent += "\n\n【这段文字体现了我作为\(figure)的\(languageCharacteristic)风格和善用\(rhetoricalDevice)的特点。】"
        }
        
        return styledContent
    }
    
    // 私有初始化方法，确保单例模式
    private init() {}
} 