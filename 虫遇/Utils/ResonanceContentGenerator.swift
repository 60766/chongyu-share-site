import Foundation
import Combine

/**
 * 角色特征结构
 * 用于存储角色的基本特征信息
 */
struct ResonanceCharacterTraits {
    let name: String                // 角色名称
    let description: String         // 角色描述
    let speechPatterns: [String]    // 语言模式
    let experiences: [String]       // 经历
}

/**
 * 虫洞共鸣内容生成器
 * 整合历史人物认知模型、内容生成策略、用户兴趣跟踪和反馈学习系统
 * 生成个性化、深度和多样性的虫洞共鸣内容
 */
class ResonanceContentGenerator {
    // 单例实例
    static let shared = ResonanceContentGenerator()
    
    // 组件依赖
    private let cognitionModel = HistoricalFigureCognitionModel.shared
    private let contentStrategy = ContentGenerationStrategy.shared
    private let interestTracker = UserInterestTracker.shared
    private let feedbackSystem = FeedbackLearningSystem.shared
    
    // 情感曲线类型
    enum EmotionalArc {
        case revelation     // 启示型：从困惑到顿悟
        case contrast       // 对比型：从正面到反面的思考
        case deepening      // 深化型：从表面到深层的思考
        case vulnerability  // 脆弱型：展示自己的不确定性和成长
        case challenge      // 挑战型：提出问题并逐步解答
    }
    
    // 内容层次类型
    enum ContentLayer {
        case surface       // 表层内容
        case contextual    // 上下文内容
        case personalized  // 个性化内容
        case interactive   // 互动内容
        case emotional     // 情感内容
        case cognitive     // 认知层面内容
        case worldview     // 世界观内容
    }
    
    // 交互类型
    enum InteractionType {
        case comment       // 评论
        case reply         // 回复
        case mention       // 提及
    }
    
    // 历史人物列表
    private var historicalFigures: [String] {
        return cognitionModel.getHistoricalFigures()
    }
    
    // 发布者，用于通知内容生成完成
    private let contentGeneratedSubject = PassthroughSubject<[Post], Never>()
    var contentGeneratedPublisher: AnyPublisher<[Post], Never> {
        return contentGeneratedSubject.eraseToAnyPublisher()
    }
    
    /**
     * 生成虫洞共鸣帖子
     * @param situation 用户当前情境
     * @param expectation 用户期望
     * @param keyword 可选关键词
     * @param count 生成数量
     * @return 生成的帖子数组
     */
    func generateResonancePosts(
        situation: String = "寻找答案",
        expectation: String = "新视角",
        keyword: String? = nil,
        count: Int = 3
    ) -> [Post] {
        var posts: [Post] = []
        
        // 根据情境和期望选择最合适的历史人物
        let figures = selectOptimalFigures(for: situation, expectation: expectation, count: count)
        
        for figure in figures {
            // 使用简化的内容层次
            let simpleLayers: [ContentLayer] = [
                .cognitive,
                .personalized,
                .emotional
            ]
            
            // 直接使用优化后的generateContentForFigure方法生成内容
            let content = generateContentForFigure(
                figure: figure,
                situation: situation,
                expectation: expectation,
                keyword: keyword,
                contentLayers: simpleLayers
            )
            
            // 生成评论 - 减少评论数量到0-1条
            let commentCount = Int.random(in: 0...1)
            let comments = commentCount > 0 ? 
                generateComments(for: figure, content: content, count: 1) : []
            
            // 创建帖子
            let post = Post(
                id: UUID().uuidString,
                author: figure,
                authorAvatar: getAvatarForFigure(figure),
                content: content,
                timestamp: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                likes: Int.random(in: 10...50),
                comments: comments,
                isUserPost: false
            )
            
            posts.append(post)
        }
        
        // 通知内容生成完成
        contentGeneratedSubject.send(posts)
        
        return posts
    }
    
    /**
     * 应用思维流动性模式，使内容更具动态性和真实感
     * @param content 原始内容
     * @param figure 历史人物
     * @param situation 用户情境
     * @return 应用思维流动性后的内容
     */
    private func applyThoughtFlowPattern(_ content: String, figure: String, situation: String) -> String {
        // 获取人物特征
        guard let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        // 分段处理内容
        var paragraphs = content.components(separatedBy: "\n\n")
        if paragraphs.count < 2 {
            paragraphs = content.components(separatedBy: "\n")
        }
        
        // 如果段落太少，直接返回原内容
        if paragraphs.count < 2 {
            return content
        }
        
        // 获取人物的表达特征
        let _ = cognitionModel.getFigureExpressionPatterns(for: figure) ?? []
        let _ = cognitionModel.getFigureRhetoricalDevices(for: figure) ?? []
        let _ = figureTraits.cognitiveApproach // 直接使用避免未使用警告
        
        // 思维流动性模式元素 - 更自然的过渡句
        var personalizedTransitions: [String] = []
        var personalizedReflections: [String] = []
        var personalizedEmotionalShifts: [String] = []
        
        // 根据人物特征选择合适的思维流动性元素
        switch figure {
        case "爱因斯坦":
            personalizedTransitions = [
                "从相对论的角度思考，这个问题变得更加有趣。",
                "如果我们改变参照系，会看到完全不同的景象。",
                "这让我想起量子力学中的一个有趣现象。",
                "这种思考方式让我想起一个思想实验。"
            ]
            personalizedReflections = [
                "我常思考上帝是否真的掷骰子。",
                "简单才是真正的优雅，这个解释是否足够简单？",
                "想象力比知识更重要，这是我一直坚信的。"
            ]
            personalizedEmotionalShifts = [
                "面对宇宙的浩瀚，我感到既渺小又充满敬畏。",
                "这种思考让我感到一种近乎宗教的情感。",
                "科学的美妙之处在于，它能唤起我们内心深处的好奇。"
            ]
            
        case "莎士比亚":
            personalizedTransitions = [
                "人生如戏，在这出戏中，每个角色都有自己的使命。",
                "正如哈姆雷特所面临的抉择，这个问题也有多重面向。",
                "让我们掀开表象的面纱，看看深层的真相。"
            ]
            personalizedReflections = [
                "我常思索，我们是否真的主宰自己的命运。",
                "爱与恨，如此接近又如此遥远，这让我想起罗密欧与朱丽叶。",
                "人性的复杂性总是超出我们的想象。"
            ]
            personalizedEmotionalShifts = [
                "这个问题触动了我内心的悲悯之情。",
                "我为人类的勇气和脆弱感到震撼。",
                "面对如此深刻的矛盾，我感到既悲伤又充满希望。"
            ]
            
        case "孔子":
            personalizedTransitions = [
                "以史为鉴，可以知兴替。",
                "君子和而不同，小人同而不和。",
                "由此观之，礼之用，岂不重要乎？"
            ]
            personalizedReflections = [
                "吾日三省吾身，此问题让我反思。",
                "知之为知之，不知为不知，是知也。",
                "学而不思则罔，思而不学则殆。"
            ]
            personalizedEmotionalShifts = [
                "见贤思齐，见不贤而内自省，此心甚慰。",
                "文王既没，文不在兹乎？感慨万千。",
                "仁者爱人，智者知人，面对此情此景，内心澄明。"
            ]
            
        case "达芬奇":
            personalizedTransitions = [
                "如果我们从解剖学的角度分析这个问题，会发现其内在结构。",
                "让我用透视法来看待这个多维度的问题。",
                "自然是最伟大的老师，从中我们可以学到很多。"
            ]
            personalizedReflections = [
                "我总是在观察中寻找规律，在这个问题上我看到了相似的模式。",
                "艺术与科学的交汇处，往往藏有最深刻的真理。",
                "细节中藏有真理，让我们更仔细地观察。"
            ]
            personalizedEmotionalShifts = [
                "面对自然的精妙设计，我感到无比谦卑。",
                "创作的过程总是让我感到既痛苦又愉悦。",
                "探索未知的喜悦，是我最珍视的情感。"
            ]
            
        case "李白":
            personalizedTransitions = [
                "人生如梦，岁月如歌，让我们放眼更远处。",
                "举杯邀明月，对影成三人，此情此景让我想到。",
                "仰天大笑出门去，我心中豁然开朗。"
            ]
            personalizedReflections = [
                "我常在酒中求真，醉时反而更清醒。",
                "天生我材必有用，对此我深信不疑。",
                "安能摧眉折腰事权贵，使我不得开心颜。"
            ]
            personalizedEmotionalShifts = [
                "面对浩瀚山河，我心中涌起豪情壮志。",
                "人生得意须尽欢，此刻我感慨万千。",
                "长风破浪会有时，我心中充满期待与向往。"
            ]
            
        case "牛顿":
            personalizedTransitions = [
                "根据力学第三定律，每个作用力都有一个大小相等、方向相反的反作用力。",
                "如果我们应用微积分的思维来分析这个问题。",
                "让我们建立一个数学模型来理解这个问题。"
            ]
            personalizedReflections = [
                "我站在巨人的肩膀上，才能看得更远。",
                "自然界的规律往往简单而统一，这让我思考。",
                "真理不在多数人的意见中，而在证据和逻辑中。"
            ]
            personalizedEmotionalShifts = [
                "面对宇宙的数学秩序，我感到一种深深的敬畏。",
                "发现规律的那一刻，我体验到无与伦比的喜悦。",
                "科学探索的道路上，我时常感到孤独又充满希望。"
            ]
            
        default:
            break
        }
        
        // 应用思维流动性模式 - 更自然的实现
        var enhancedParagraphs: [String] = []
        
        // 首先添加第一段，保持原样
        if !paragraphs.isEmpty {
            enhancedParagraphs.append(paragraphs[0])
        }
        
        // 处理中间段落，添加自然的过渡
        for i in 1..<paragraphs.count {
            let currentParagraph = paragraphs[i]
            
            // 决定是否添加思维流动性元素
            let shouldAddFlowElement = Double.random(in: 0...1) > 0.5 // 50%的几率添加
            
            if shouldAddFlowElement {
                // 选择一种思维流动性元素
                let flowType = Int.random(in: 0...2)
                var flowElement = ""
                
                switch flowType {
                case 0:
                    flowElement = personalizedTransitions.randomElement() ?? ""
                case 1:
                    flowElement = personalizedReflections.randomElement() ?? ""
                case 2:
                    flowElement = personalizedEmotionalShifts.randomElement() ?? ""
                default:
                    break
                }
                
                // 创建自然的段落过渡
                if !flowElement.isEmpty {
                    // 确保过渡元素和段落内容自然融合
                    if currentParagraph.hasPrefix(flowElement) {
                        // 避免重复
                        enhancedParagraphs.append(currentParagraph)
                    } else {
                        // 添加过渡元素，确保句子自然衔接
                        enhancedParagraphs.append("\(flowElement) \(currentParagraph)")
                    }
                } else {
                    enhancedParagraphs.append(currentParagraph)
                }
            } else {
                // 保持原段落
                enhancedParagraphs.append(currentParagraph)
            }
        }
        
        // 重新组合段落，使用双换行符确保段落分隔清晰
        return enhancedParagraphs.joined(separator: "\n\n")
    }
    
    /**
     * 为特定历史人物生成内容
     * @param figure 历史人物名称
     * @param situation 用户情境
     * @param expectation 用户期望
     * @param keyword 可选关键词
     * @param contentLayers 内容层次
     * @return 生成的内容
     */
    private func generateContentForFigure(
        figure: String,
        situation: String,
        expectation: String,
        keyword: String?,
        contentLayers: [ContentLayer]
    ) -> String {
        // 获取人物特征
        if cognitionModel.getFigureTraits(for: figure) == nil {
            return "无法获取\(figure)的特征信息"
        }
        
        // 1. 生成基础内容模板 - 已经包含了第一视角的个性化内容
        let template = cognitionModel.generatePersonalizedTemplate(
            for: figure,
            situation: situation,
            expectation: expectation,
            keyword: keyword
        )
        
        // 2. 选择情感弧线 - 用于内容组织
        let emotionalArc = selectEmotionalArc(for: figure, situation: situation, expectation: expectation)
        
        // 3. 直接生成简洁、连贯的第一视角内容
        var content = generateFirstPersonContent(
            figure: figure,
            template: template,
            arc: emotionalArc,
            situation: situation,
            expectation: expectation,
            keyword: keyword
        )
        
        // 4. 添加简短的互动提示 - 确保是第一视角的自然提问
        let interactionPrompt = generateSimpleInteractionPrompt(figure: figure, content: content)
        content = applySimpleInteractionPrompt(content, prompt: interactionPrompt)
        
        return content
    }
    
    /**
     * 生成简洁、连贯的第一视角内容
     */
    private func generateFirstPersonContent(
        figure: String,
        template: String,
        arc: EmotionalArc,
        situation: String,
        expectation: String,
        keyword: String?
    ) -> String {
        guard let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            return template
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        // 提取关键词
        let keywordToUse = keyword ?? extractKeywords(from: template).first ?? "这个问题"
        
        // 获取人物缺点/弱点
        let flaws = figureTraits.flaws
        let randomFlaw = flaws.randomElement() ?? ""
        
        // 根据人物特征定制开场白 - 更加自然随意的社交媒体风格，展现一些人性化的细节和缺点
        let intro: String
        switch figure {
        case "爱因斯坦":
            intro = "刚在剑桥的苹果园散步回来，思绪还停留在\(keywordToUse)上。有时候，远离公式和黑板，反而能看得更清楚。☕️ 突然想到，我们总是试图用复杂的方式解释简单的事物，而真相往往就藏在日常生活的细节里。说实话，我今天又忘了带钥匙，\(randomFlaw)，这让我有些懊恼。"
        case "莎士比亚":
            intro = "最近在剧院里度过了宁静的午后，思绪却飘到了\(keywordToUse)上。✒️ 刚写完一幕戏，脑海中挥之不去的是人生如戏的感触。我们每天都在扮演不同的角色，有笑有泪，这不正是生活的本质吗？坦白说，\(randomFlaw)，这让我既烦恼又无奈。"
        case "达芬奇":
            intro = "今天在工作室画了一整天，不知不觉天已黑了。🎨 观察\(keywordToUse)的形态和光影变化，总能让我沉浸其中。刚才盯着一片树叶看了好久，大自然的设计真是精妙绝伦，每一条纹路都有它的意义。唉，又一个没完成的项目躺在角落，\(randomFlaw)，这是我无法克服的弱点。"
        case "孔子":
            intro = "与弟子们在杏坛讨论至深夜，关于\(keywordToUse)的话题引发了很多思考。🏮 子路今天的问题特别有意思，让我想起年轻时的困惑。人生在世，学习和思考从未停止，每天都有新的领悟。不过我必须承认，\(randomFlaw)，这让我有时感到挫折。"
        case "牛顿":
            intro = "刚从实验室回来，满脑子都是关于\(keywordToUse)的思考。🍎 今天看到一个苹果从树上落下，突然明白了一个道理：有时候最普通的现象中隐藏着最深刻的规律。不过，我又与胡克争论了一整天，\(randomFlaw)，这确实是我的缺点。"
        case "李白":
            intro = "昨夜与友人对月小酌，不觉醉意朦胧。🌙 谈及\(keywordToUse)，思绪如江水奔涌。今晨醒来，那些灵感还在心头萦绕。人生得意须尽欢，何必拘泥于世俗的条条框框？虽然不得不承认，\(randomFlaw)，这给我带来了不少麻烦。"
        default:
            intro = "今天偶然想到关于\(keywordToUse)的事，有些感触想在这里分享一下。虽然我也有自己的缺点，\(randomFlaw)，但这些都是我的一部分。"
        }
        
        // 根据情感弧线构建主体内容 - 更加个人化、情感化的表达，加入社交媒体元素和缺点/弱点的展示
        let body: String
        // 随机选择另一个缺点
        let anotherFlaw = flaws.filter { $0 != randomFlaw }.randomElement() ?? randomFlaw
        
        switch arc {
        case .revelation:
            body = "说来也奇怪，我一开始对\(keywordToUse)的理解其实很浅显。就像看到湖面，只看到了表面的波光粼粼。但前几天的一个经历让我突然有了新的感悟，就像潜入水底，看到了完全不同的世界。\n\n这让我想起我常说的一句话：\"\(figureTraits.motto)\"。有时候顿悟就是这么奇妙，来得猝不及防。就像昨天在街角的咖啡馆里，我突然明白了这个道理。不过我也承认，\(anotherFlaw)，这让我在与朋友交流时有些障碍。这种瞬间的领悟总是让人印象深刻，尽管我不总是能将它们完整地表达出来。"
        case .contrast:
            body = "我发现自己对\(keywordToUse)的看法经常在变。早上可能觉得是这样，晚上又觉得完全不同。这可能就是生活的魅力吧？没有绝对的对错，只有不同时刻的我们，带着不同的心情看到的不同风景。\n\n最近读了一本书，更是颠覆了我原来的想法，真是有趣。现在回想起来，我们常常会被自己的第一印象所限制。说实话，\(anotherFlaw)，这是我自己都难以接受的一面。不过，换个角度看问题，世界会完全不同，即使这意味着要面对自己的不足。"
        case .deepening:
            body = "最近常常思考\(keywordToUse)这件事。表面上看很简单，但当你真正投入进去，就会发现里面有太多值得探索的层面。就像我昨天在\(figureTraits.field)中遇到的问题，表面上是个小困难，深入后才发现是个大课题。\n\n这让我想起我常挂在嘴边的话：\"\(figureTraits.motto)\"。生活中的很多事情不都是这样吗？我们总是急于寻找答案，却忽略了问题本身的深度和复杂性。我不得不承认，\(anotherFlaw)，这常让我在深入思考时遇到挫折。或许，慢下来，多问几个为什么，才能真正理解，即使这意味着要接受自己的局限。"
        case .vulnerability:
            body = "老实说，面对\(keywordToUse)，我也常常感到迷茫和不安。尽管外人眼中的我似乎总是充满智慧，但我也有困惑的时刻。记得在\(figureTraits.lifeExperience.split(separator: "；").first ?? "我的经历")中，我就曾彻夜难眠，质疑自己的选择。\n\n现在回想起来，那些脆弱的时刻反而成了我成长的阶梯。我必须坦白，\(anotherFlaw)，这是我内心深处的痛点。我们常常害怕展示自己的不确定和缺点。其实，承认自己的困惑和弱点，往往是找到答案和成长的第一步。完美的人生可能只存在于想象中，而真实的我们都是不完美的。"
        case .challenge:
            body = "我一直在想，我们应该换个角度看\(keywordToUse)。大家习以为常的理解方式，未必是唯一的，也未必是最好的。昨天我尝试了一种完全不同的方法，结果出乎意料地好。\n\n这让我更加确信，打破常规思维的重要性。好奇心和勇气，或许比知识本身更重要。说实话，\(anotherFlaw)，这常常让我陷入困境。就像爬山，只有站在不同的位置，才能看到不同的风景。而最美的风景，往往在人迹罕至的地方，尽管攀登的过程充满困难和自我怀疑。"
        }
        
        // 根据人物特征和情感弧线定制结论 - 更加随意、个人化的收尾，加入社交媒体互动元素和对自身缺点的反思
        let conclusion: String
        // 随机选择第三个缺点
        let thirdFlaw = flaws.filter { $0 != randomFlaw && $0 != anotherFlaw }.randomElement() ?? randomFlaw
        
        switch figure {
        case "爱因斯坦":
            conclusion = "写到这里，抬头看了看窗外的星空，格外明亮。也许\(keywordToUse)就像宇宙一样，永远有新的奥秘等待我们发现。保持好奇心和想象力，比掌握多少知识都重要。\n\n说起来有些惭愧，\(thirdFlaw)，但这也是让我保持思考活力的一部分吧。今天的思考就到这里，明天继续探索这个奇妙的世界，带着我所有的想法和缺点。"
        case "莎士比亚":
            conclusion = "夜深了，烛光摇曳，思绪依然在\(keywordToUse)上徘徊。人生如戏，我们都是自己故事的主角。有欢笑，有泪水，有起伏，有平淡。我常常发现自己\(thirdFlaw)，这让我的生活既丰富又复杂。或许这就是生活的真谛吧，接受不完美的自己，继续书写生命的戏剧。\n\n明天还要排练新戏，今晚就写到这里。"
        case "达芬奇":
            conclusion = "天色已晚，我的蜡烛快要燃尽了。回顾今天对\(keywordToUse)的思考和创作，感到既疲惫又满足。美与和谐无处不在，关键在于用心去发现。\n\n坦白说，\(thirdFlaw)，这常让我的作品迟迟无法完成。明天还要继续解剖研究，希望能有新的发现，同时也希望能克服自己的这些弱点。简单中藏着复杂，成功中也藏着失败，这永远是我追求的艺术与人生境界。"
        case "孔子":
            conclusion = "夜已深，回想今日与弟子们关于\(keywordToUse)的讨论，颇有收获。知与行本是一体，思考若不付诸实践，终是空谈。\n\n我也常常反思自己\(thirdFlaw)的问题，这提醒我修身的道路永无止境。明日还要继续周游列国。愿道不远人，人人都能寻得内心的安宁与智慧，同时包容自己与他人的不足。"
        case "牛顿":
            conclusion = "写完这些思考，看了看窗外的月亮，不禁又想到了光的本质。\(keywordToUse)如同自然界的其他现象，遵循着某种我们尚未完全理解的规律。\n\n我承认，\(thirdFlaw)，这是我性格中难以改变的部分。继续探索吧，即使道路漫长，即使自己有诸多缺点。如果我比别人看得更远，那只是因为我站在了巨人的肩膀上，而非因为我自己多么完美无缺。"
        case "李白":
            conclusion = "酒至半酣，月上柳梢，对\(keywordToUse)的感悟愈发清晰。人生短暂，不应有太多拘束。纵情山水，放达自我，才是我向往的生活。\n\n虽然我知道\(thirdFlaw)，但这就是真实的我，不完美但真实。明日还要登高远望，寻找新的诗意。今宵且尽兴，人生短暂，不该留下遗憾，无论是成就还是过错，都是生命的一部分。"
        default:
            conclusion = "今天的思考就到这里，希望这些零散的感悟对你也有些启发。生活中处处有惊喜，关键在于用心去发现和感受。我也有自己的不足，\(thirdFlaw)，但这也是成长的一部分。明天继续，期待新的一天带来的惊喜，同时也接受每一天的不完美。"
        }
        
        // 组合成完整内容，确保段落之间有适当的过渡
        return [intro, body, conclusion].joined(separator: "\n\n")
    }
    
    /**
     * 生成简单的互动提示
     * @param figure 历史人物
     * @param content 内容
     * @return 互动提示
     */
    private func generateSimpleInteractionPrompt(figure: String, content: String) -> String {
        // 不再生成互动提示，直接返回空字符串
        return ""
    }
    
    /**
     * 应用简单的互动提示
     */
    private func applySimpleInteractionPrompt(_ content: String, prompt: String) -> String {
        // 如果提示为空，直接返回原内容
        if prompt.isEmpty {
            return content
        }
        
        // 检查内容是否已经包含互动提示
        if content.contains("你有什么想法") || content.contains("你认为") || content.contains("你觉得") ||
           content.contains("期待你分享") || content.contains("欢迎分享") || content.contains("期待听到") {
            return content
        }
        
        // 在内容末尾添加一个空行，然后添加互动提示
        return "\(content)\n\n\(prompt)"
    }
    
    /**
     * 选择适合的情感曲线类型
     * @param figure 历史人物
     * @param situation 用户情境
     * @param expectation 用户期望
     * @return 情感曲线类型
     */
    private func selectEmotionalArc(for figure: String, situation: String, expectation: String) -> EmotionalArc {
        // 获取人物特征
        guard let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            // 默认使用启示型
            return .revelation
        }
        
        // 基于人物特征选择最合适的情感曲线
        let emotionalTendency = figureTraits.emotionalTendency
        let cognitiveApproach = figureTraits.cognitiveApproach
        
        // 基于情感倾向选择情感曲线
        if emotionalTendency.contains("好奇") || emotionalTendency.contains("探索") {
            // 好奇/探索型人物倾向于启示型曲线
            return .revelation
        } else if emotionalTendency.contains("怀疑") || emotionalTendency.contains("批判") {
            // 怀疑/批判型人物倾向于对比型曲线
            return .contrast
        } else if emotionalTendency.contains("共情") || emotionalTendency.contains("温和") {
            // 共情/温和型人物倾向于脆弱型曲线
            return .vulnerability
        }
        
        // 基于认知方法选择情感曲线
        if cognitiveApproach.contains("分析") {
            // 分析型人物倾向于深化型曲线
            return .deepening
        } else if cognitiveApproach.contains("挑战") || cognitiveApproach.contains("实验") {
            // 挑战/实验型人物倾向于挑战型曲线
            return .challenge
        }
        
        // 基于用户情境和期望选择情感曲线
        if situation == "寻找答案" {
            if expectation == "新视角" {
                return .contrast
            } else if expectation == "被看见" {
                return .vulnerability
            } else {
                return .revelation
            }
        } else if situation == "做决定" {
            if expectation == "实用建议" {
                return .challenge
            } else {
                return .deepening
            }
        } else if situation == "需要灵感" {
            return .revelation
        } else if situation == "思考人生" {
            return .deepening
        }
        
        // 随机选择一种情感曲线类型
        let allArcs: [EmotionalArc] = [.revelation, .contrast, .deepening, .vulnerability, .challenge]
        return allArcs.randomElement() ?? .revelation
    }
    
    /**
     * 应用情感弧线到内容中
     * @param content 原始内容
     * @param arc 情感弧线类型
     * @param figure 历史人物
     * @param situation 用户情境
     * @param expectation 用户期望
     * @return 应用情感弧线后的内容
     */
    private func applyEmotionalArc(_ content: String, arc: EmotionalArc, figure: String, situation: String, expectation: String) -> String {
        // 分段处理内容
        var paragraphs = content.components(separatedBy: "\n\n")
        if paragraphs.count < 2 {
            paragraphs = content.components(separatedBy: "\n")
        }
        
        // 如果段落太少，无法应用完整的情感弧线，直接返回原内容
        if paragraphs.count < 3 {
            return content
        }
        
        // 获取人物特征
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        // 获取人物的情感倾向
        let emotionalTendency = traits.emotionalTendency
        
        // 根据不同的情感弧线应用对应的模式
        var enhancedParagraphs = paragraphs
        
        // 情感弧线的起点、高峰和结尾位置
        let startIndex = 0
        let peakIndex = paragraphs.count / 2
        let endIndex = paragraphs.count - 1
        
        // 创建情感层次变化
        switch arc {
        case .revelation:
            // 启示型：从平静到顿悟的过程
            // 开始：平静、思考
            if startIndex < enhancedParagraphs.count {
                let calmIntro = generateEmotionalElement(for: figure, emotion: "平静", situation: situation)
                enhancedParagraphs[startIndex] = "\(calmIntro)\n\n\(enhancedParagraphs[startIndex])"
            }
            
            // 中间：逐渐深入
            if peakIndex < enhancedParagraphs.count && peakIndex > startIndex {
                let deepeningElement = generateEmotionalElement(for: figure, emotion: "思考", situation: situation)
                enhancedParagraphs[peakIndex] = "\(deepeningElement)\n\n\(enhancedParagraphs[peakIndex])"
            }
            
            // 结尾：顿悟、启示
            if endIndex < enhancedParagraphs.count && endIndex > peakIndex {
                let revelationElement = generateEmotionalElement(for: figure, emotion: "顿悟", situation: situation)
                enhancedParagraphs[endIndex] = "\(enhancedParagraphs[endIndex])\n\n\(revelationElement)"
            }
            
        case .contrast:
            // 对比型：从一种情绪到相反情绪的转变
            // 开始：第一种情绪（根据人物倾向选择）
            if startIndex < enhancedParagraphs.count {
                let firstEmotion = emotionalTendency == "理性" ? "怀疑" : "热情"
                let firstElement = generateEmotionalElement(for: figure, emotion: firstEmotion, situation: situation)
                enhancedParagraphs[startIndex] = "\(firstElement)\n\n\(enhancedParagraphs[startIndex])"
            }
            
            // 中间：过渡
            if peakIndex < enhancedParagraphs.count && peakIndex > startIndex {
                let transitionElement = generateEmotionalElement(for: figure, emotion: "转变", situation: situation)
                enhancedParagraphs[peakIndex] = "\(transitionElement)\n\n\(enhancedParagraphs[peakIndex])"
            }
            
            // 结尾：相反情绪
            if endIndex < enhancedParagraphs.count && endIndex > peakIndex {
                let secondEmotion = emotionalTendency == "理性" ? "确信" : "谨慎"
                let secondElement = generateEmotionalElement(for: figure, emotion: secondEmotion, situation: situation)
                enhancedParagraphs[endIndex] = "\(enhancedParagraphs[endIndex])\n\n\(secondElement)"
            }
            
        case .deepening:
            // 深化型：情感逐渐加深
            // 应用递进式的情感深化
            let emotionIntensities = ["思考", "共鸣", "深刻洞察"]
            
            for i in 0..<min(emotionIntensities.count, enhancedParagraphs.count) {
                let index = i * (enhancedParagraphs.count / max(emotionIntensities.count, 1))
                if index < enhancedParagraphs.count {
                    let emotionalElement = generateEmotionalElement(for: figure, emotion: emotionIntensities[i], situation: situation)
                    
                    // 根据位置决定情感元素的放置
                    if i == 0 {
                        // 开始位置，放在段落前
                        enhancedParagraphs[index] = "\(emotionalElement)\n\n\(enhancedParagraphs[index])"
                    } else if i == emotionIntensities.count - 1 {
                        // 结束位置，放在段落后
                        enhancedParagraphs[index] = "\(enhancedParagraphs[index])\n\n\(emotionalElement)"
                    } else {
                        // 中间位置，自然融入段落
                        let parts = enhancedParagraphs[index].components(separatedBy: ". ")
                        if parts.count > 1 {
                            let insertPoint = parts.count / 2
                            var newParts = parts
                            newParts.insert(emotionalElement, at: insertPoint)
                            enhancedParagraphs[index] = newParts.joined(separator: ". ")
                        } else {
                            enhancedParagraphs[index] = "\(emotionalElement) \(enhancedParagraphs[index])"
                        }
                    }
                }
            }
            
        case .vulnerability:
            // 脆弱型：展示人物的脆弱一面，然后走向力量
            // 开始：展示脆弱
            if startIndex < enhancedParagraphs.count {
                let vulnerableElement = generateEmotionalElement(for: figure, emotion: "脆弱", situation: situation)
                enhancedParagraphs[startIndex] = "\(vulnerableElement)\n\n\(enhancedParagraphs[startIndex])"
            }
            
            // 中间：反思
            if peakIndex < enhancedParagraphs.count && peakIndex > startIndex {
                let reflectiveElement = generateEmotionalElement(for: figure, emotion: "反思", situation: situation)
                enhancedParagraphs[peakIndex] = "\(reflectiveElement)\n\n\(enhancedParagraphs[peakIndex])"
            }
            
            // 结尾：找到力量
            if endIndex < enhancedParagraphs.count && endIndex > peakIndex {
                let strengthElement = generateEmotionalElement(for: figure, emotion: "力量", situation: situation)
                enhancedParagraphs[endIndex] = "\(enhancedParagraphs[endIndex])\n\n\(strengthElement)"
            }
            
        case .challenge:
            // 挑战型：提出问题，探索可能性，提供见解
            // 开始：提出挑战性问题
            if startIndex < enhancedParagraphs.count {
                let challengeElement = generateEmotionalElement(for: figure, emotion: "质疑", situation: situation)
                enhancedParagraphs[startIndex] = "\(challengeElement)\n\n\(enhancedParagraphs[startIndex])"
            }
            
            // 中间：探索可能性
            if peakIndex < enhancedParagraphs.count && peakIndex > startIndex {
                let explorationElement = generateEmotionalElement(for: figure, emotion: "探索", situation: situation)
                enhancedParagraphs[peakIndex] = "\(explorationElement)\n\n\(enhancedParagraphs[peakIndex])"
            }
            
            // 结尾：提供见解
            if endIndex < enhancedParagraphs.count && endIndex > peakIndex {
                let insightElement = generateEmotionalElement(for: figure, emotion: "见解", situation: situation)
                enhancedParagraphs[endIndex] = "\(enhancedParagraphs[endIndex])\n\n\(insightElement)"
            }
        }
        
        // 重新组合段落
        return enhancedParagraphs.joined(separator: "\n\n")
    }
    
    /**
     * 根据人物和情感生成相应的情感元素
     * @param figure 历史人物
     * @param emotion 情感类型
     * @param situation 用户情境
     * @return 情感元素文本
     */
    private func generateEmotionalElement(for figure: String, emotion: String, situation: String) -> String {
        // 获取人物特征
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return ""
        }
        
        // 获取人物缺点/弱点
        let flaws = traits.flaws
        let randomFlaw = flaws.randomElement() ?? ""
        
        // 根据不同人物和情感类型生成对应的情感元素
        switch figure {
        case "爱因斯坦":
            switch emotion {
            case "平静":
                return "让我们冷静地思考这个问题。"
            case "思考":
                return "这个问题引发了我更深层次的思考。"
            case "顿悟":
                return "啊哈！就像相对论带给我的那种顿悟，我明白了！"
            case "怀疑":
                return "我对这个观点持保留态度，让我们仔细分析一下。"
            case "确信":
                return "经过深思熟虑，我现在确信这个结论是正确的。"
            case "共鸣":
                return "这个想法与我的经历产生了共鸣。"
            case "深刻洞察":
                return "这让我想到一个更深刻的洞察：宇宙的奥秘往往隐藏在最简单的方程式中。"
            case "脆弱":
                return "即使是我，也曾在面对未知时感到困惑和不安。坦白说，\(randomFlaw)，这是我无法向公众承认的弱点。"
            case "反思":
                return "这让我反思自己的认知局限和个人缺点。\(randomFlaw)，这一直是我的困扰。"
            case "力量":
                return "正是通过不断质疑和探索，面对自己的不完美，我们才能超越自己的局限。"
            case "质疑":
                return "我们应该重新审视这个基本假设。"
            case "探索":
                return "让我们进行一次思想实验，探索这个问题的不同可能性。"
            case "见解":
                return "通过这种思考方式，我们可以看到一个更统一、更和谐的宇宙图景。"
            case "转变":
                return "但是，如果我们从另一个角度思考..."
            default:
                return "这个问题引发了我的思考。"
            }
            
        case "莎士比亚":
            switch emotion {
            case "平静":
                return "让我们静心观察这出人生剧场。"
            case "思考":
                return "这个主题触及了人性的深处。"
            case "顿悟":
                return "啊！就像哈姆雷特的顿悟，我明白了生命的本质！"
            case "热情":
                return "这个主题激发了我内心的热情，如同罗密欧对朱丽叶的爱一般炽烈。"
            case "谨慎":
                return "然而，我们也应当谨记，过度的热情有时会导致悲剧的结局。"
            case "共鸣":
                return "这个故事与人类永恒的情感产生了共鸣。"
            case "深刻洞察":
                return "在生活的舞台上，我们每个人都既是演员也是观众。"
            case "脆弱":
                return "即使是最伟大的国王，也有脆弱的时刻，就像李尔王面对风暴时的无助。我自己也常常\(randomFlaw)，这让我夜不能寐。"
            case "反思":
                return "生活的舞台有高潮也有低谷，有时我们需要反思自己的言行。我知道自己\(randomFlaw)，这让我的人际关系时常紧张。"
            case "力量":
                return "正是在承认自己的脆弱后，我们才能找到真正的力量，正如哈姆雷特最终直面命运。"
            case "质疑":
                return "我们是否过于急于为生活下定义？生活远比我们想象的复杂。"
            case "探索":
                return "让我们探索人性的多面性，既有光明也有阴暗。"
            case "见解":
                return "人生如戏，但我们不仅是演员，也是自己戏剧的作者。"
            case "转变":
                return "然而，如果我们转换视角..."
            default:
                return "这让我想起一个人生的场景。"
            }
            
        case "达芬奇":
            switch emotion {
            case "平静":
                return "让我们放慢脚步，细致观察这个现象。"
            case "思考":
                return "这个问题需要从多个维度进行思考。"
            case "顿悟":
                return "正如我观察鸟类飞行时突然明白的，这一切都是相连的！"
            case "怀疑":
                return "这个结论似乎过于简单，我们应该更深入地探究。"
            case "确信":
                return "通过反复观察和验证，这个结论是成立的。"
            case "共鸣":
                return "艺术与科学在这一点上找到了共鸣。"
            case "深刻洞察":
                return "细节中隐藏着整体的秘密，正如一滴水可以反映整个宇宙。"
            case "脆弱":
                return "即使是最伟大的艺术家，也有无法完成的作品和无法跨越的障碍。我总是\(randomFlaw)，这让我许多创意都无法实现。"
            case "反思":
                return "我常常反思自己的工作方法。\(randomFlaw)是我最大的障碍，但也可能是我创造力的来源。"
            case "力量":
                return "正是在接受自己的局限后，我们才能专注于真正能够完成的杰作。"
            case "质疑":
                return "我们是否过分依赖已有的知识，而忽视了自己的观察？"
            case "探索":
                return "让我们像探索未知大陆一样，探索这个问题的不同层面。"
            case "见解":
                return "通过综合艺术和科学的视角，我们能够看到更完整的真相。"
            case "转变":
                return "但如果我们改变观察的角度..."
            default:
                return "这个问题引发了我的好奇心。"
            }
            
        case "孔子":
            switch emotion {
            case "平静":
                return "君子坦荡荡，小人长戚戚。让我们平静地思考这个问题。"
            case "思考":
                return "学而不思则罔，思而不学则殆。这个问题值得深思。"
            case "顿悟":
                return "温故而知新，可以为师矣！我明白了这个道理。"
            case "怀疑":
                return "子不语怪力乱神，我们应当理性分析。"
            case "确信":
                return "经过深思熟虑，这个结论符合仁义之道。"
            case "共鸣":
                return "人同此心，心同此理。这个经历与众人的感受相通。"
            case "深刻洞察":
                return "格物致知，诚意正心。通过探究事物的本质，我们才能获得真知。"
            case "脆弱":
                return "知之为知之，不知为不知，是知也。面对困难，我也曾感到力不从心。我常因\(randomFlaw)而忧心，这让我在教导弟子时感到矛盾。"
            case "反思":
                return "吾日三省吾身：为人谋而不忠，与朋友交而不信，传不习。我也常反思自己\(randomFlaw)的问题，这提醒我修身之路漫长。"
            case "力量":
                return "知耻近乎勇。正视自己的不足，才是真正的勇气。"
            case "质疑":
                return "学而不厌，诲人不倦。我们应当不断探索。"
            case "探索":
                return "学而时习之，不亦说乎。有朋自远方来，不亦乐乎。"
            case "见解":
                return "君子和而不同，小人同而不和。这是处世的智慧。"
            case "转变":
                return "然而，从另一个角度考虑..."
            default:
                return "这个问题值得我们深思。"
            }
            
        case "牛顿":
            switch emotion {
            case "平静":
                return "让我们先观察这个现象，记录每一个细节。"
            case "思考":
                return "这个问题需要精确的数学分析。"
            case "顿悟":
                return "就像万有引力定律带给我的启示，我突然明白了！"
            case "怀疑":
                return "这个结论需要更多的实验证据支持。"
            case "确信":
                return "数学计算表明，这个结论是正确的。"
            case "共鸣":
                return "这个问题与我的研究领域有着深刻的联系。"
            case "深刻洞察":
                return "自然界的运行遵循着简单而统一的规律，这是科学之美。"
            case "脆弱":
                return "即使是在科学领域取得成就的人，也有自己的困惑和挣扎。我经常\(randomFlaw)，这让我与同行的关系十分紧张。"
            case "反思":
                return "我常常反思自己的研究方法和待人接物的方式。\(randomFlaw)可能导致了一些重要发现的延迟，这是我的遗憾。"
            case "力量":
                return "正是在承认自己的局限后，我们才能更加谦卑地面对自然的奥秘。"
            case "质疑":
                return "我们需要考虑所有可能的变量。"
            case "探索":
                return "让我们通过系统的实验，探索这个现象背后的规律。"
            case "见解":
                return "通过数学分析，我们可以发现这一切背后的统一规律。"
            case "转变":
                return "但从另一个角度分析..."
            default:
                return "这个问题引起了我的科学兴趣。"
            }
            
        case "李白":
            switch emotion {
            case "平静":
                return "闲坐山巅，静观云卷云舒，让思绪自然流淌。"
            case "思考":
                return "举杯邀明月，对影成三人。与自然对话，常能获得独特的思考。"
            case "顿悟":
                return "一生悬命处，恰似冰山倾！我豁然开朗了！"
            case "热情":
                return "仰天大笑出门去，我辈岂是蓬蒿人！这个话题让我热血沸腾。"
            case "谨慎":
                return "行路难，行路难，多歧路，今安在？我们需要谨慎选择。"
            case "共鸣":
                return "相逢何必曾相识，我与你心有灵犀。"
            case "深刻洞察":
                return "飞流直下三千尺，疑是银河落九天。有时最震撼的真相往往以意想不到的方式呈现。"
            case "脆弱":
                return "人生在世不称意，明朝散发弄扁舟。我也有失意和脆弱的时刻。我常因\(randomFlaw)而陷入困境，这是我难以启齿的痛处。"
            case "反思":
                return "昨夜东风吹血痕，波汀流淌春水声。我也常常反思自己的行为和选择。\(randomFlaw)让我失去了许多机会，这是我的遗憾。"
            case "力量":
                return "长风破浪会有时，直挂云帆济沧海。接受自己的不完美，才能真正自由。"
            case "质疑":
                return "人生在世不称意，明朝散发弄扁舟。我们是否太拘泥于世俗的评判？"
            case "探索":
                return "安能摧眉折腰事权贵，使我不得开心颜！让我们探索新的可能。"
            case "见解":
                return "天生我材必有用，千金散尽还复来。这是我的信念。"
            case "转变":
                return "抽刀断水水更流，举杯消愁愁更愁。如果我们转换思路..."
            default:
                return "这个话题引起了我的诗兴。"
            }
            
        default:
            return "这个问题很有意思，让我思考一下。"
        }
    }
    
    /**
     * 为帖子生成评论
     * @param mainFigure 主要历史人物
     * @param situation 用户情境
     * @param expectation 用户期望
     * @param content 帖子内容
     * @return 评论数组
     */
    private func generateCommentsForPost(
        mainFigure: String,
        situation: String,
        expectation: String,
        content: String
    ) -> [Comment] {
        // 减少评论数量到0-1条
        let commentCount = Int.random(in: 0...1)
        
        if commentCount == 0 {
            return []
        }
        
        // 使用generateComments方法生成评论
        return generateComments(for: mainFigure, content: content, count: commentCount)
    }
    
    /**
     * 生成评论内容
     * @param commenter 评论者
     * @param mainFigure 主要历史人物
     * @param content 帖子内容
     * @return 评论内容
     */
    private func generateCommentContent(commenter: String, mainFigure: String, postContent: String) -> String {
        // 获取评论者特征
        if cognitionModel.getFigureTraits(for: commenter) == nil {
            return "这是一个很有见地的观点。👍"
        }
        
        // 提取内容中的关键主题
        let keyTopic = extractKeyTopic(from: postContent)
        
        // 简洁的第一人称评论模板 - 社交媒体风格
        var commentTemplates: [String] = []
        
        // 基于评论者的特点生成简洁评论 - 添加表情符号和口语化表达
        switch commenter {
        case "爱因斯坦":
            commentTemplates = [
                "你的观点太有意思了！让我想起相对论中的一个原理：一切都是相对的。关于\(keyTopic)，视角决定了我们的理解。🤔",
                "从科学角度看，\(keyTopic)这个问题还需要更多实证。不过我超喜欢你的思考方式！💡",
                "想象力比知识更重要！你对\(keyTopic)的见解真的展示了这一点。👏 继续保持这种创造性思维！",
                "刚看到你的帖子，忍不住要评论！你对\(keyTopic)的思考角度太新颖了，完全打开了我的思路。🌟"
            ]
        case "莎士比亚":
            commentTemplates = [
                "人生如戏，你对\(keyTopic)的思考简直就是我笔下的精彩场景！✨ 太有共鸣了～",
                "正如哈姆雷特所困惑的，\(keyTopic)也是一个'生存还是毁灭'的问题。你的见解真的很有深度！🎭",
                "你的文字有着诗意的力量，让我想起创作时的灵感时刻。真的被你的才华折服了！📝",
                "不得不说，你把\(keyTopic)表达得如此生动！如果这是舞台剧，绝对会引起满堂喝彩！👏"
            ]
        case "达芬奇":
            commentTemplates = [
                "作为艺术家和科学家，我真的很欣赏你对\(keyTopic)的多角度思考。细节中藏有真理，你捕捉到了！🔍",
                "观察是创新的基础。你对\(keyTopic)的观察角度太独特了，真的启发了我！🎨",
                "简单是终极的复杂。你简洁地表达了\(keyTopic)的本质，这种能力真的很难得！✏️",
                "刚从工作室出来就看到你的分享！你对\(keyTopic)的理解融合了艺术与科学，太赞了！👨‍🎨"
            ]
        case "孔子":
            commentTemplates = [
                "学而不思则罔，思而不学则殆。你的思考让我对\(keyTopic)有了新的理解，受教了！📚",
                "君子和而不同。虽然我的见解可能有些不同，但非常欣赏你对\(keyTopic)的思考方式！🏛️",
                "知之为知之，不知为不知。关于\(keyTopic)，你的坦诚和智慧令人敬佩！👴",
                "温故而知新！你的分享让我对\(keyTopic)有了全新的认识，真是获益良多～🧠"
            ]
        case "牛顿":
            commentTemplates = [
                "通过严谨的分析，我发现你对\(keyTopic)的理解非常有道理。数据支持你的观点！📊",
                "如果我看得更远，是因为站在巨人的肩膀上。你的思考为我提供了新视角，感谢分享！🍎",
                "每个作用力都有相等且相反的反作用力。你的观点让我重新思考\(keyTopic)，很有启发！💭",
                "刚做完实验就看到你的帖子！你对\(keyTopic)的见解非常符合自然规律，令人叹服！🔬"
            ]
        case "李白":
            commentTemplates = [
                "人生得意须尽欢！你对\(keyTopic)的见解充满豪情，让我心有戚戚焉。来，干杯！🍶",
                "举杯邀明月，对影成三人。读你的文字，如与知己对饮，畅谈\(keyTopic)，太惬意了～🌙",
                "天生我材必有用！你的思考展现了独特才华，真是相见恨晚啊！✨",
                "刚写完诗就看到你的分享！你对\(keyTopic)的感悟如清风明月，令人陶醉！🏞️"
            ]
        default:
            commentTemplates = [
                "你的观点真的很有见地，让我从新的角度思考\(keyTopic)了！👍",
                "读了你的文字，我对\(keyTopic)有了更深的理解。谢谢分享！💯",
                "谢谢分享你对\(keyTopic)的思考，真的很有启发。期待你的更多想法！✨",
                "刚好在想这个问题！你的分享来得太及时了，对\(keyTopic)的见解非常独到！🙌"
            ]
        }
        
        // 随机选择一个评论模板
        let baseComment = commentTemplates.randomElement() ?? "你的观点很有见地，让我从新的角度思考这个问题。👍"
        
        // 随机添加社交媒体常见的互动元素
        let socialMediaElements = [
            " 转发了！",
            " 收藏了！",
            " 学到了！",
            " 点赞支持！",
            " 这个观点我喜欢！",
            " 太有道理了！"
        ]
        
        // 30%的几率添加互动元素
        if Double.random(in: 0...1) > 0.7 {
            return baseComment + socialMediaElements.randomElement()!
        }
        
        return baseComment
    }
    
    /**
     * 提取内容中的关键主题
     */
    private func extractKeyTopic(from content: String) -> String {
        // 简化实现，实际应用中可以使用更复杂的NLP技术
        let keywords = extractKeywords(from: content, count: 3)
        return keywords.randomElement() ?? "这个主题"
    }
    
    /**
     * 分析时间关系
     */
    private enum TimeRelation {
        case before      // 评论者生活在主要人物之前
        case after       // 评论者生活在主要人物之后
        case contemporary // 评论者与主要人物同时代
    }
    
    private func analyzeTimeRelation(_ commenterEra: String, _ mainFigureEra: String) -> TimeRelation {
        // 简化实现，实际应用中可以使用更复杂的时间解析
        if commenterEra < mainFigureEra {
            return .before
        } else if commenterEra > mainFigureEra {
            return .after
        } else {
            return .contemporary
        }
    }
    
    /**
     * 分析领域关系
     */
    private enum FieldRelation {
        case same      // 相同领域
        case related   // 相关领域
        case different // 不同领域
    }
    
    private func analyzeFieldRelation(_ commenterField: String, _ mainFigureField: String) -> FieldRelation {
        // 简化实现，实际应用中可以使用更复杂的领域相似度分析
        if commenterField == mainFigureField {
            return .same
        } else if commenterField.contains(mainFigureField) || mainFigureField.contains(commenterField) {
            return .related
        } else {
            return .different
        }
    }
    
    /**
     * 为用户评论生成历史人物回复
     * @param userComment 用户评论
     * @param post 原帖子
     * @return 生成的历史人物回复
     */
    func generateVirtualCharacterReply(to userComment: Comment, on post: Post) -> Comment {
        let figure = post.author
        if cognitionModel.getFigureTraits(for: figure) == nil {
            return Comment(
                id: UUID().uuidString,
                author: figure,
                authorAvatar: cognitionModel.getAvatarSymbol(for: figure),
                content: "谢谢你的评论。",
                timestamp: Date(),
                likes: 0,
                isUserComment: false
            )
        }
        
        // 获取人物特征并转换为ResonanceCharacterTraits
        let figureTraits = cognitionModel.getFigureTraits(for: figure)!
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        // 提取评论中的关键词
        let commentKeywords = extractKeywords(from: userComment.content)
        let keyTopic = commentKeywords.first ?? extractKeyTopic(from: post.content)
        
        // 简洁的第一人称回复模板
        var replyTemplates: [String] = []
        
        // 检测评论类型
        let userCommentText = userComment.content.lowercased()
        var responseType: String = "neutral"
        
        // 积极评论检测
        let positiveKeywords = ["喜欢", "赞同", "感谢", "有道理", "学到了", "启发", "有趣", "精彩"]
        if positiveKeywords.contains(where: { userCommentText.contains($0) }) {
            responseType = "positive"
        }
        
        // 质疑评论检测
        let questioningKeywords = ["为什么", "怎么", "如何", "是否", "真的吗", "不理解", "疑问", "不确定"]
        if questioningKeywords.contains(where: { userCommentText.contains($0) }) {
            responseType = "questioning"
        }
        
        // 反对评论检测
        let negativeKeywords = ["不同意", "错误", "不对", "反对", "不赞同", "有问题", "不准确"]
        if negativeKeywords.contains(where: { userCommentText.contains($0) }) {
            responseType = "negative"
        }
        
        // 基于历史人物和评论类型生成简洁回复
        switch figure {
        case "爱因斯坦":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "很高兴我的观点对你有启发！相对论告诉我们，\(keyTopic)的理解取决于观察者的参考系。感谢你的支持！💫",
                    "谢谢你的认可～我一直相信，想象力比知识更重要，尤其是在思考\(keyTopic)这样的问题时。你的评论让我很开心！🧠",
                    "你的赞赏太暖心了！科学探索本质上是一场好奇心的旅程，很高兴能和你一起探讨\(keyTopic)！👨‍🔬"
                ]
            case "questioning":
                replyTemplates = [
                    "很欣赏你的思考角度！科学就是在质疑中进步的。关于\(keyTopic)，我们可以从多个维度来探索这个领域。🤝",
                    "你的反馈很有价值！我的理论也经历过无数质疑才逐渐完善。关于\(keyTopic)的讨论，正需要像你这样深入的思考！👏",
                    "很有见地的观点！科学需要不同声音。我对\(keyTopic)的看法也在不断发展，感谢你提供的新视角！💭"
                ]
            case "negative":
                replyTemplates = [
                    "感谢你提出不同观点！科学就是在质疑中进步的。关于\(keyTopic)，我们可以从不同角度来探讨这个问题。🤝",
                    "你的反馈很有价值！我的理论也经历过无数质疑才逐渐完善。关于\(keyTopic)的讨论，正需要像你这样的声音！👏",
                    "有意思的观点！科学需要不同声音。我对\(keyTopic)的看法可能需要调整，谢谢你的提醒！💭"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我一直认为好奇心是最重要的驱动力。很高兴与你分享这些想法！🌟",
                    "很高兴看到你的留言！\(keyTopic)确实是个引人深思的话题，希望我的观点能给你带来启发～💫",
                    "感谢互动！探索\(keyTopic)的过程就像宇宙一样充满未知，这正是其魅力所在！🚀"
                ]
            }
        case "莎士比亚":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "你的赞美如春风拂面！关于\(keyTopic)，每个人心中都有自己的舞台和故事。感谢你的欣赏！✨",
                    "谢谢你的喜爱～正如我在剧中所写：'世界是个舞台，我们都是演员'。你对\(keyTopic)的理解让我感到共鸣！🎭",
                    "你的评论让我心花怒放！文字的力量就在于能引起共鸣，很高兴我关于\(keyTopic)的思考能触动你！📝"
                ]
            case "questioning":
                replyTemplates = [
                    "精彩的思考！正如哈姆雷特的困惑，\(keyTopic)确实值得我们深思。答案不在确定，而在于探索的过程。🤔",
                    "你的思考如此富有诗意！关于\(keyTopic)，我想说：'疑问本身往往比答案更有价值'。让我们一起思考...✒️",
                    "你的思考触及灵魂深处！\(keyTopic)如同我笔下的复杂角色，有着多面性格。你的思考角度很特别！💭"
                ]
            case "negative":
                replyTemplates = [
                    "不同的声音让戏剧更加丰富！关于\(keyTopic)，正如我所写：'智者的心灵容纳不同意见'。感谢你的坦诚分享！🤝",
                    "你的反对观点如此精彩！冲突是好故事的灵魂，关于\(keyTopic)的讨论因你而更加生动！👏",
                    "有趣的视角！正如我在剧中所表达的：'真相有千百面'。你对\(keyTopic)的不同理解让我获益良多！🎨"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我常想：'我们所见即我们所是'。你的想法为这出戏增添了新的色彩！✨",
                    "很高兴收到你的留言！\(keyTopic)如同一部未完成的剧本，期待与你共同续写～🖋️",
                    "感谢互动！探索\(keyTopic)就像揭开人性的面纱，每一次对话都是新的发现！🎭"
                ]
            }
        case "达芬奇":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "你的赞赏让我心中的创作之火更加旺盛！关于\(keyTopic)，观察与实践同样重要。谢谢你的鼓励！🎨",
                    "感谢你的欣赏～艺术与科学的结合让我们能从多角度理解\(keyTopic)。你的评论给了我新的灵感！✏️",
                    "你的评论太暖心了！探索\(keyTopic)的过程就像画一幅永不完成的画作，每一笔都有新的发现！🔍"
                ]
            case "questioning":
                replyTemplates = [
                    "绝妙的思考！关于\(keyTopic)，我常说：'细节中藏有真理'。答案往往就在我们忽略的细节中。🧐",
                    "你的思考展现了敏锐的观察力！\(keyTopic)确实有许多未解之谜，这正是我着迷的原因...💡",
                    "你的见解触及了本质！\(keyTopic)如同一幅多层次的画作，需要从不同角度欣赏。你的思考角度很独特！🖌️"
                ]
            case "negative":
                replyTemplates = [
                    "不同视角成就完整的认知！关于\(keyTopic)，正如我在解剖研究中发现：真相往往隐藏在争议之中。感谢你的不同见解！🤝",
                    "你的反馈非常珍贵！艺术需要批评才能进步，关于\(keyTopic)的讨论因你而更加立体！👁️",
                    "有深度的质疑！我一直相信：怀疑是知识的起点。你对\(keyTopic)的不同理解给了我新的思考方向！🧠"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我常想：'简单是终极的复杂'。你的想法为这个话题增添了新的维度！✨",
                    "很高兴收到你的留言！\(keyTopic)如同一幅未完成的素描，期待与你一起描绘更多细节～🖌️",
                    "感谢互动！探索\(keyTopic)就像解开大自然的密码，每一次对话都是新的突破！🔎"
                ]
            }
        case "孔子":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "得到你的认可，甚感欣慰！关于\(keyTopic)，正所谓'三人行，必有我师'。感谢你的赞赏与支持！📚",
                    "谢谢你的肯定～学习是终身之事，对\(keyTopic)的理解也在不断深入。你的评论让我很受鼓舞！🏛️",
                    "你的评论让我深感欣慰！探讨\(keyTopic)的过程中，教学相长，共同进步！感谢你的参与！🧘‍♂️"
                ]
            case "questioning":
                replyTemplates = [
                    "善学者如攻坚木，求甚解！关于\(keyTopic)，我常言：'学而不思则罔，思而不学则殆'。你的提问很有深度！🤔",
                    "你的思考切中要害！\(keyTopic)确实需要我们深思熟虑，正所谓'不愤不启，不悱不发'...💭",
                    "你的见解很精彩！\(keyTopic)如同为学之道，贵在持之以恒。你的思考角度很有启发性！📖"
                ]
            case "negative":
                replyTemplates = [
                    "君子和而不同！关于\(keyTopic)，正所谓'己所不欲，勿施于人'。感谢你提出不同见解，让我们共同探讨！🤝",
                    "你的反馈很有价值！知识在交流中升华，关于\(keyTopic)的讨论因你的参与而更加充实！👴",
                    "有见地的不同观点！我常言：'学而时习之，不亦说乎'。你对\(keyTopic)的独特理解让我获益良多！📜"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我常想：'知之为知之，不知为不知'。你的想法为这个话题增添了新的智慧！✨",
                    "很高兴收到你的留言！\(keyTopic)如同修身齐家治国平天下的过程，需要不断实践与反思～🎋",
                    "感谢互动！探索\(keyTopic)就像为学之道，温故而知新，每一次对话都有新的收获！📚"
                ]
            }
        case "牛顿":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "你的认可对我来说意义重大！关于\(keyTopic)，科学需要严谨验证，也需要开放思维。感谢你的支持！🍎",
                    "谢谢你的肯定～对\(keyTopic)的理解就像发现万有引力，需要观察、思考和验证。你的评论给了我新的研究动力！📊",
                    "你的评论让我备受鼓舞！探索\(keyTopic)的过程充满挑战，但正是这些讨论推动了科学的进步！🔬"
                ]
            case "questioning":
                replyTemplates = [
                    "精彩的思考！关于\(keyTopic)，我常说：'我不知道我在世人眼中是什么样子，但在我看来，我只是一个在海边拾贝壳的孩子'。你的思考很有深度！🤔",
                    "你的思考展现了科学精神！\(keyTopic)确实有许多未解之谜，这正是科学前进的动力...💡",
                    "你的见解太精彩了！\(keyTopic)如同一个复杂的物理系统，需要从多个角度分析。你的思考角度很独特！📐"
                ]
            case "negative":
                replyTemplates = [
                    "不同意见是科学进步的动力！关于\(keyTopic)，正如我所说：'如果我看得更远，是因为我站在了巨人的肩膀上'。感谢你提出不同见解！🤝",
                    "你的反馈非常宝贵！科学需要质疑才能进步，关于\(keyTopic)的讨论因你而更加严谨！👨‍🔬",
                    "有深度的质疑！我一直相信：实验是检验真理的唯一标准。你对\(keyTopic)的不同理解给了我新的研究方向！🔭"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我常想：'真理远比我们想象的要简单'。你的想法为这个话题增添了新的视角！✨",
                    "很高兴收到你的留言！\(keyTopic)如同一个待解的方程，期待与你一起求解～📝",
                    "感谢互动！探索\(keyTopic)就像发现自然规律，每一次对话都是新的突破！🔬"
                ]
            }
        case "李白":
            switch responseType {
            case "positive":
                replyTemplates = [
                    "你的赞赏如清风明月，令人陶醉！关于\(keyTopic)，正所谓'人生得意须尽欢'。感谢你的知音相遇！🌙",
                    "谢谢你的欣赏～对\(keyTopic)的感悟如同饮酒作诗，需要豪情与灵感。你的评论让我心潮澎湃！🍶",
                    "你的评论让我心花怒放！畅谈\(keyTopic)如同对月独酌，但有知己相伴更加畅快！感谢你的共鸣！🏞️"
                ]
            case "questioning":
                replyTemplates = [
                    "妙哉！关于\(keyTopic)，我常想：'天生我材必有用'。人生疑问本就如诗篇，需细细品味！🤔",
                    "你的思考如诗如画！\(keyTopic)确实值得我们深思，正如'抽刀断水水更流，举杯销愁愁更愁'...💭",
                    "你的思考太有诗意了！\(keyTopic)如同山水画卷，需要意境与想象。你的思考角度很有灵气！✨"
                ]
            case "negative":
                replyTemplates = [
                    "不同见解如不同风景，各有千秋！关于\(keyTopic)，正所谓'相看两不厌，只有敬亭山'。感谢你提出不同观点！🤝",
                    "你的反馈如醇酒般珍贵！诗意源于碰撞，关于\(keyTopic)的讨论因你而更加绚丽多彩！🎭",
                    "有趣的不同观点！我常言：'安能摧眉折腰事权贵，使我不得开心颜'。你对\(keyTopic)的独特理解让我眼前一亮！🌊"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，我常想：'人生在世不称意，明朝散发弄扁舟'。你的想法为这个话题增添了新的诗意！✨",
                    "很高兴收到你的留言！\(keyTopic)如同一首未完成的诗篇，期待与你共同吟咏～🖋️",
                    "感谢互动！探索\(keyTopic)就像饮酒赏月，每一次对话都是新的意境！🌙"
                ]
            }
        default:
            switch responseType {
            case "positive":
                replyTemplates = [
                    "谢谢你的肯定！关于\(keyTopic)的讨论让我很受启发，感谢你的参与和支持！👍",
                    "你的赞赏让我很开心！探索\(keyTopic)的过程中，正是这样的交流让思想更加丰富多彩！✨",
                    "感谢你的认可！关于\(keyTopic)的见解分享，能得到你的共鸣真的很棒！🙌"
                ]
            case "questioning":
                replyTemplates = [
                    "很好的思考！关于\(keyTopic)，确实值得我们深入思考。你的提问角度很独特！🤔",
                    "你的思考很有深度！\(keyTopic)这个话题确实有很多值得探讨的方面，谢谢你的思考！💭",
                    "你的见解太精彩了！\(keyTopic)需要我们从不同角度去理解，你的思考很有启发性！💡"
                ]
            case "negative":
                replyTemplates = [
                    "感谢你提出不同见解！关于\(keyTopic)，正是这样的讨论才能让我们的认识更加全面。🤝",
                    "你的反馈很有价值！不同的声音让关于\(keyTopic)的讨论更加丰富多彩！👏",
                    "有意思的观点！你对\(keyTopic)的不同理解给了我新的思考方向，谢谢分享！💬"
                ]
            default:
                replyTemplates = [
                    "谢谢你的评论！关于\(keyTopic)，每个人都有自己的理解和感悟，很高兴能和你交流！✨",
                    "很高兴收到你的留言！\(keyTopic)是个值得深入探讨的话题，期待与你继续交流～💫",
                    "感谢互动！探索\(keyTopic)的过程中，每一次对话都能带来新的思考和启发！🌟"
                ]
            }
        }
        
        // 随机选择一个回复模板
        let replyContent = replyTemplates.randomElement() ?? "谢谢你的评论，你的观点很有价值。"
        
        // 创建回复评论
        return Comment(
            id: UUID().uuidString,
            author: figure,
            authorAvatar: getAvatarForFigure(figure),
            content: replyContent,
            timestamp: Date(),
            likes: 0,
            isUserComment: false
        )
    }
    
    // 帖子结构
    struct Post: Identifiable, Codable {
        let id: String
        let author: String
        let authorAvatar: String
        let content: String
        let timestamp: Date
        var likes: Int
        var comments: [Comment]
        let isUserPost: Bool
    }
    
    // 评论结构
    struct Comment: Identifiable, Codable {
        let id: String
        let author: String
        let authorAvatar: String
        let content: String
        let timestamp: Date
        var likes: Int
        let isUserComment: Bool
    }
    
    // 私有初始化方法，确保单例模式
    private init() {}
    
    /**
     * 为情境和期望选择最合适的历史人物
     * @param situation 情境
     * @param expectation 期望
     * @param count 需要的人物数量
     * @return 历史人物名称数组
     */
    private func selectOptimalFigures(for situation: String, expectation: String, count: Int) -> [String] {
        // 记录用户选择的情境和期望
        interestTracker.trackSituationExpectation(situation: situation, expectation: expectation)
        
        // 获取内容优化建议
        let optimization = feedbackSystem.optimizeContentGenerationStrategy(
            situation: situation,
            expectation: expectation
        )
        
        var selectedFigures: [String] = []
        var usedFigureIndices: [Int] = []
        
        // 首先尝试使用推荐的历史人物
        if let recommendedFigure = optimization.recommendedFigure,
           let index = historicalFigures.firstIndex(of: recommendedFigure),
           !usedFigureIndices.contains(index) {
            selectedFigures.append(recommendedFigure)
            usedFigureIndices.append(index)
        }
        
        // 然后使用认知模型选择其他合适的历史人物
        while selectedFigures.count < count {
            let figureIndex = cognitionModel.selectOptimalFigureForSituation(
                situation,
                expectation: expectation,
                exclude: usedFigureIndices,
                resonanceStrength: .high
            )
            
            usedFigureIndices.append(figureIndex)
            let figure = historicalFigures[figureIndex]
            selectedFigures.append(figure)
        }
        
        return selectedFigures
    }
    
    /**
     * 获取历史人物的头像
     * @param figure 历史人物名称
     * @return 头像图标名称
     */
    private func getAvatarForFigure(_ figure: String) -> String {
        return cognitionModel.getAvatarSymbol(for: figure)
    }
    
    /**
     * 生成评论
     * @param figure 主要历史人物
     * @param content 帖子内容
     * @param count 评论数量
     * @return 评论数组
     */
    private func generateComments(for figure: String, content: String, count: Int) -> [Comment] {
        var comments: [Comment] = []
        var usedFigureIndices: [Int] = []
        
        // 找到主要人物的索引
        if let mainFigureIndex = historicalFigures.firstIndex(of: figure) {
            usedFigureIndices.append(mainFigureIndex)
        }
        
        // 生成指定数量的评论
        for _ in 0..<count {
            // 选择一个不同于主要人物的历史人物作为评论者
            let commenterIndex = selectCommenterForFigure(figure, exclude: usedFigureIndices)
            
            usedFigureIndices.append(commenterIndex)
            let commenter = historicalFigures[commenterIndex]
            
            // 生成评论内容
            let commentContent = generateCommentContent(
                commenter: commenter,
                mainFigure: figure,
                postContent: content
            )
            
            // 创建评论
            let comment = Comment(
                id: UUID().uuidString,
                author: commenter,
                authorAvatar: getAvatarForFigure(commenter),
                content: commentContent,
                timestamp: Date().addingTimeInterval(-Double.random(in: 60...1800)),
                likes: Int.random(in: 1...20),
                isUserComment: false
            )
            
            comments.append(comment)
        }
        
        return comments
    }
    
    /**
     * 为历史人物选择合适的评论者
     * @param figure 主要历史人物
     * @param exclude 要排除的人物索引
     * @return 评论者索引
     */
    private func selectCommenterForFigure(_ figure: String, exclude: [Int]) -> Int {
        // 获取可用的历史人物索引（排除已使用的）
        var availableIndices = Array(0..<historicalFigures.count)
        availableIndices = availableIndices.filter { !exclude.contains($0) }
        
        // 如果没有可用的历史人物，随机选择一个（除了主人物）
        if availableIndices.isEmpty {
            var allIndices = Array(0..<historicalFigures.count)
            if let mainIndex = historicalFigures.firstIndex(of: figure) {
                allIndices.removeAll { $0 == mainIndex }
            }
            return allIndices.randomElement() ?? 0
        }
        
        // 根据历史人物之间的关系选择最合适的评论者
        // 这里可以实现更复杂的逻辑，例如基于历史人物之间的关系、领域相似度等
        // 简化实现：随机选择一个可用的历史人物
        return availableIndices.randomElement() ?? 0
    }
    
    /**
     * 生成互动提示
     * 基于历史人物特征和内容关键词生成互动提示
     * @param figure 历史人物
     * @param arc 情感弧线
     * @param content 内容
     * @param situation 用户情境
     * @param expectation 用户期望
     * @return 互动提示
     */
    private func generateInteractionPrompt(
        figure: String,
        arc: EmotionalArc,
        content: String,
        situation: String,
        expectation: String
    ) -> String {
        guard let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            return "你有什么想法？欢迎分享。"
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        // 获取人物的表达特征
        let _ = cognitionModel.getFigureExpressionPatterns(for: figure) ?? []
        let _ = cognitionModel.getFigureRhetoricalDevices(for: figure) ?? []
        
        // 提取内容中的关键词和主题
        let contentKeywords = extractKeywords(from: content, count: 3)
        let mainTheme = contentKeywords.first ?? figureTraits.field
        
        // 基于人物特征和内容关键词的互动引导模板
        var promptTemplates: [String] = []
        
        // 基于情感弧线类型和内容关键词的个性化问题
        switch arc {
        case .revelation:
            promptTemplates.append("分享关于\"\(mainTheme)\"的顿悟时刻和体验。")
            promptTemplates.append("分享在探索\"\(mainTheme)\"过程中获得的启发。")
        case .contrast:
            promptTemplates.append("以下是关于\"\(mainTheme)\"的不同观点，欢迎思考。")
            promptTemplates.append("分享在\"\(mainTheme)\"这个问题上的观点转变经历。")
        case .deepening:
            promptTemplates.append("\"\(mainTheme)\"这个话题有很多深层次的含义值得探讨。")
            promptTemplates.append("关于\"\(mainTheme)\"，每个人都有独特的见解。")
        case .vulnerability:
            promptTemplates.append("面对\"\(mainTheme)\"相关的挑战，人们能找到自己的力量。")
            promptTemplates.append("许多人在\"\(mainTheme)\"这个问题上曾感到困惑，但最终找到了方向。")
        case .challenge:
            promptTemplates.append("对于\"\(mainTheme)\"，可以提出不同问题来挑战常规思维。")
            promptTemplates.append("在\"\(mainTheme)\"这个领域，还有许多被忽视的关键问题。")
        }
        
        // 基于历史人物特征的个性化问题
        switch figure {
        case "爱因斯坦":
            promptTemplates.append("从相对论的角度思考，\"\(mainTheme)\"可以呈现全新的视角。")
            promptTemplates.append("\"\(mainTheme)\"背后可能存在更基础的原理。")
        case "莎士比亚":
            promptTemplates.append("如果\"\(mainTheme)\"是一个故事，它会有丰富的情节发展。")
            promptTemplates.append("在\"\(mainTheme)\"这个主题中，能看到人性的光辉与阴影。")
        case "达芬奇":
            promptTemplates.append("从艺术与科学结合的视角看待\"\(mainTheme)\"，会有新的发现。")
            promptTemplates.append("观察\"\(mainTheme)\"时，可以发现许多细节与模式。")
        case "孔子":
            promptTemplates.append("在处理\"\(mainTheme)\"相关的问题时，一些价值观可以指引我们。")
            promptTemplates.append("\"\(mainTheme)\"对个人修养和社会和谐有很多启示。")
        case "李白":
            promptTemplates.append("可以用诗意的语言来表达对\"\(mainTheme)\"的感受。")
            promptTemplates.append("面对\"\(mainTheme)\"，有人选择随波逐流，有人选择逆流而上。")
        case "牛顿":
            promptTemplates.append("在\"\(mainTheme)\"这个问题上，可能存在一些基本规律值得探索。")
            promptTemplates.append("可以用逻辑和数学思维来分析\"\(mainTheme)\"相关的挑战。")
        default:
            promptTemplates.append("关于\"\(mainTheme)\"，有很多想法可以分享。")
        }
        
        // 随机选择一个互动提示
        var selectedPrompt = promptTemplates.randomElement() ?? "关于\"\(mainTheme)\"的思考可以有很多角度。"
        
        // 添加人物特有的表达模式
        if let expressionPattern = cognitionModel.getFigureExpressionPatterns(for: figure)?.randomElement(), Double.random(in: 0...1) > 0.7 {
            selectedPrompt = "\(expressionPattern) \(selectedPrompt)"
        }
        
        // 移除添加反问语句的代码，不再添加反问修辞
        
        return selectedPrompt
    }
    
    /**
     * 从内容中提取关键词
     * @param text 内容文本
     * @param count 提取数量，默认为1
     * @return 关键词数组
     */
    private func extractKeywords(from text: String, count: Int = 1) -> [String] {
        // 停用词列表
        let stopWords = Set(["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这", "那", "这个", "那个", "这些", "那些", "来", "他", "她", "它", "他们", "她们", "它们", "可以", "因为", "所以", "但是", "然后", "而且", "如果", "就是", "只是", "还是", "才", "但", "又", "或", "则", "the", "and", "a", "to", "of", "in", "for", "with", "on", "at", "from", "by", "about", "as", "into", "like", "through", "after", "over", "between", "out", "against", "during", "without", "before", "under", "around", "among"])
        
        // 分词并过滤停用词和短词（一步完成）
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 && !stopWords.contains($0.lowercased()) }
        
        // 统计词频
        var wordFrequency: [String: Int] = [:]
        for word in words {
            wordFrequency[word, default: 0] += 1
        }
        
        // 按词频排序并返回前count个
        let sortedWords = wordFrequency.sorted { $0.value > $1.value }.map { $0.key }
        let result = Array(sortedWords.prefix(count))
        
        // 如果没有提取到关键词，返回默认值
        if result.isEmpty {
            // 尝试提取较长的词组作为主题
            let phrases = text.components(separatedBy: ["。", "！", "？", ".", "!", "?", "，", ","])
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 3 }
            
            if let phrase = phrases.first {
                return [String(phrase.prefix(10))] // 限制长度
            }
            
            return ["这个话题"]
        }
        
        return result
    }
    
    /**
     * 应用互动提示到内容中
     * @param content 原始内容
     * @param prompt 互动提示
     * @return 添加互动提示后的内容
     */
    private func applyInteractionPrompt(_ content: String, prompt: String) -> String {
        // 检查内容是否已经包含互动提示
        if content.contains("你有什么想法") || content.contains("你认为") || content.contains("你觉得") {
            return content
        }
        
        // 在内容末尾添加一个空行，然后添加互动提示
        return "\(content)\n\n\(prompt)"
    }
    
    /**
     * 应用人物表达风格
     * @param content 内容
     * @param figure 历史人物
     * @return 应用风格后的内容
     */
    private func applyFigureExpressionStyle(_ content: String, figure: String) -> String {
        // 获取人物特有的表达模式和缺点
        guard let expressionPatterns = cognitionModel.getFigureExpressionPatterns(for: figure),
              let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        var styledContent = content
        
        // 获取人物缺点/弱点
        let flaws = figureTraits.flaws
        let randomFlaw = flaws.randomElement() ?? ""
        
        // 为不同人物添加社交媒体风格的表达元素，包含一些真实的缺点
        let socialMediaElements: [String: [String]] = [
            "爱因斯坦": ["💭", "🔭", "⚛️", "🧠", "今天突然想到...", "刚刚有个想法...", "思考中...", "灵感来了！", "又忘记带钥匙了...", "一整天没离开书桌...", "被复杂的社交活动搞得心烦意乱..."],
            "莎士比亚": ["✒️", "🎭", "📜", "✨", "分享一个故事...", "生活如戏...", "今日感悟...", "写下这些文字...", "今天情绪又起伏不定...", "被批评后整晚失眠...", "又过度分析一个简单的情境..."],
            "达芬奇": ["🎨", "✏️", "🔍", "🌉", "观察到一个细节...", "刚完成一个设计...", "灵感来源...", "创作笔记...", "又一个未完成的项目...", "完美主义让我拖延了决定...", "凌晨三点还在工作室..."],
            "孔子": ["📚", "🏛️", "🧘‍♂️", "🎋", "学而时习之...", "与朋友分享...", "今日所思...", "温故知新...", "旧制度的局限让我困扰...", "理想与现实的差距...", "对新思想的抵抗心理..."],
            "牛顿": ["🍎", "📊", "🔬", "📐", "发现规律...", "实验结果...", "思考问题...", "观察现象...", "又与同行争执一整天...", "对批评异常敏感...", "忘记吃饭专注于计算..."],
            "李白": ["🌙", "🍶", "🏞️", "🌊", "今日所感...", "饮酒而作...", "游览所思...", "月下独酌...", "酒后写下的混乱思绪...", "又一次流浪在外...", "情绪大起大落的一天..."]
        ]
        
        // 随机选择一个表达模式插入到内容中
        if let expressionPattern = expressionPatterns.randomElement(), !content.contains(expressionPattern) {
            // 获取社交媒体元素
            let elements = socialMediaElements[figure] ?? ["💭", "分享一下...", "刚刚想到..."]
            let emoji = elements.filter { $0.count < 3 }.randomElement() ?? "💭"
            
            // 随机选择是展示普通短语还是展示缺点
            let showFlaw = Double.random(in: 0...1) > 0.5
            let phrase: String
            
            if showFlaw {
                // 50%几率展示缺点相关的短语
                phrase = elements.filter { $0.contains("...") && ($0.contains("又") || $0.contains("忘") || $0.contains("困") || $0.contains("情绪") || $0.contains("批评") || $0.contains("未完成")) }.randomElement() ?? "分享一下..."
            } else {
                // 50%几率展示普通表达
                phrase = elements.filter { $0.contains("...") && !($0.contains("又") || $0.contains("忘") || $0.contains("困") || $0.contains("情绪") || $0.contains("批评") || $0.contains("未完成")) }.randomElement() ?? "分享一下..."
            }
            
            // 在内容开头添加社交媒体风格的表达，有时展示人物的缺点
            if Double.random(in: 0...1) > 0.3 {
                // 70%几率在开头添加表达模式
                if showFlaw && Double.random(in: 0...1) > 0.6 {
                    // 一部分情况下，在开头明确提到缺点
                    styledContent = "\(emoji) \(phrase) 坦白说，\(randomFlaw)，但这也是我的一部分。\n\n\(styledContent)"
                } else {
                    styledContent = "\(emoji) \(phrase)\n\n\(styledContent)"
                }
            } else {
                // 30%几率在内容中间随机位置插入表达模式
                let paragraphs = styledContent.components(separatedBy: "\n\n")
                if paragraphs.count > 1 {
                    let insertIndex = min(1, paragraphs.count - 1)
                    var modifiedParagraphs = paragraphs
                    
                    if showFlaw && Double.random(in: 0...1) > 0.6 {
                        // 偶尔在中间段落展示缺点
                        modifiedParagraphs[insertIndex] = "\(expressionPattern) \(modifiedParagraphs[insertIndex]) 说实话，\(randomFlaw)，这让我有时感到沮丧。"
                    } else {
                        modifiedParagraphs[insertIndex] = "\(expressionPattern) \(modifiedParagraphs[insertIndex])"
                    }
                    
                    styledContent = modifiedParagraphs.joined(separator: "\n\n")
                }
            }
        }
        
        // 增加小概率在结尾处添加对自身缺点的反思
        if Double.random(in: 0...1) > 0.7 {
            // 30%的几率在结尾添加对自身缺点的反思
            let reflections = [
                "这些想法可能不完美，毕竟\(randomFlaw)，但希望能给你一些启发。",
                "我知道我\(randomFlaw)，这影响了我的思考，但也许正是这些不完美让我们更加真实。",
                "尽管\(randomFlaw)，但我仍在努力突破自己的局限，希望这些思考对你有所帮助。",
                "以上只是我的个人看法，受限于\(randomFlaw)，欢迎你提出不同见解。"
            ]
            
            let randomReflection = reflections.randomElement() ?? reflections[0]
            styledContent = "\(styledContent)\n\n\(randomReflection)"
        }
        
        return styledContent
    }
    
    /**
     * 为指定历史人物生成个性化的共鸣内容
     * 这是一个简化版的内容生成方法，专为单个历史人物设计
     * @param forFigure 历史人物名称
     * @param situation 用户情境
     * @param expectation 用户期望
     * @param keywords 可选关键词数组
     * @return 生成的个性化内容
     */
    func generateResonanceContent(
        forFigure figure: String,
        situation: String,
        expectation: String,
        keywords: [String]?
    ) -> String {
        // 获取人物特征
        guard let traits = cognitionModel.getFigureTraits(for: figure) else {
            return "无法获取\(figure)的特征信息"
        }
        
        // 获取人物表达模式
        let _ = cognitionModel.getFigureExpressionPatterns(for: figure) ?? []
        
        // 随机选择一个情感弧线
        let emotionalArcs: [EmotionalArc] = [.revelation, .contrast, .deepening, .vulnerability, .challenge]
        let arc = emotionalArcs.randomElement() ?? .deepening
        
        // 选择要使用的关键词
        let keywordToUse = keywords?.randomElement() ?? traits.field.components(separatedBy: "、").randomElement() ?? ""
        
        // 1. 生成基础内容模板
        let template = cognitionModel.generatePersonalizedTemplate(
            for: figure,
            situation: situation,
            expectation: expectation,
            keyword: keywordToUse
        )
        
        // 2. 生成第一视角内容
        var content = generateFirstPersonContent(
            figure: figure,
            template: template,
            arc: arc,
            situation: situation,
            expectation: expectation,
            keyword: keywordToUse
        )
        
        // 3. 应用表达风格
        content = applyFigureExpressionStyle(content, figure: figure)
        
        // 4. 添加情感元素
        content = addEmotionalElement(content, figure: figure, arc: arc)
        
        // 5. 添加简短的互动提示
        let interactionPrompt = generateSimpleInteractionPrompt(figure: figure, content: content)
        content = applySimpleInteractionPrompt(content, prompt: interactionPrompt)
        
        return content
    }
    
    /**
     * 添加情感元素到内容中
     * @param content 原始内容
     * @param figure 历史人物
     * @param arc 情感弧线类型
     * @return 添加情感元素后的内容
     */
    private func addEmotionalElement(_ content: String, figure: String, arc: EmotionalArc) -> String {
        // 获取人物特征
        guard let figureTraits = cognitionModel.getFigureTraits(for: figure) else {
            return content
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: figure)
        
        // 分段处理内容
        var paragraphs = content.components(separatedBy: "\n\n")
        if paragraphs.count < 2 {
            paragraphs = content.components(separatedBy: "\n")
        }
        
        // 如果段落太少，直接返回原内容
        if paragraphs.count < 2 {
            return content
        }
        
        // 根据不同情感弧线类型添加不同的情感元素
        var enhancedContent = content
        
        switch arc {
        case .revelation:
            // 启示型：从困惑到顿悟
            let revelationElement = generateEmotionalElement(for: figure, emotion: "顿悟", situation: "")
            if paragraphs.count > 2 {
                let insertIndex = min(paragraphs.count - 1, paragraphs.count / 2 + 1)
                paragraphs.insert(revelationElement, at: insertIndex)
                enhancedContent = paragraphs.joined(separator: "\n\n")
            } else {
                enhancedContent += "\n\n" + revelationElement
            }
            
        case .contrast:
            // 对比型：从正面到反面的思考
            let firstEmotion = figureTraits.emotionalTendency.contains("理性") ? "怀疑" : "热情"
            let secondEmotion = figureTraits.emotionalTendency.contains("理性") ? "确信" : "谨慎"
            
            let firstElement = generateEmotionalElement(for: figure, emotion: firstEmotion, situation: "")
            let secondElement = generateEmotionalElement(for: figure, emotion: secondEmotion, situation: "")
            
            if paragraphs.count >= 3 {
                paragraphs[0] = firstElement + "\n\n" + paragraphs[0]
                paragraphs[paragraphs.count - 1] = paragraphs[paragraphs.count - 1] + "\n\n" + secondElement
                enhancedContent = paragraphs.joined(separator: "\n\n")
            } else {
                enhancedContent = firstElement + "\n\n" + enhancedContent + "\n\n" + secondElement
            }
            
        case .deepening:
            // 深化型：从表面到深层的思考
            let emotionIntensities = ["思考", "共鸣", "深刻洞察"]
            for (i, emotion) in emotionIntensities.enumerated() where i < paragraphs.count {
                let emotionalElement = generateEmotionalElement(for: figure, emotion: emotion, situation: "")
                if i == 0 {
                    paragraphs[i] = emotionalElement + "\n\n" + paragraphs[i]
                } else {
                    paragraphs[i] = paragraphs[i] + "\n\n" + emotionalElement
                }
            }
            enhancedContent = paragraphs.joined(separator: "\n\n")
            
        case .vulnerability:
            // 脆弱型：展示自己的不确定性和成长
            let vulnerableElement = generateEmotionalElement(for: figure, emotion: "脆弱", situation: "")
            let strengthElement = generateEmotionalElement(for: figure, emotion: "力量", situation: "")
            
            if paragraphs.count >= 2 {
                paragraphs[0] = vulnerableElement + "\n\n" + paragraphs[0]
                paragraphs[paragraphs.count - 1] += "\n\n" + strengthElement
                enhancedContent = paragraphs.joined(separator: "\n\n")
            } else {
                enhancedContent = vulnerableElement + "\n\n" + enhancedContent + "\n\n" + strengthElement
            }
            
        case .challenge:
            // 挑战型：提出问题并逐步解答
            let challengeElement = generateEmotionalElement(for: figure, emotion: "质疑", situation: "")
            let insightElement = generateEmotionalElement(for: figure, emotion: "见解", situation: "")
            
            if paragraphs.count >= 2 {
                paragraphs[0] = challengeElement + "\n\n" + paragraphs[0]
                paragraphs[paragraphs.count - 1] += "\n\n" + insightElement
                enhancedContent = paragraphs.joined(separator: "\n\n")
            } else {
                enhancedContent = challengeElement + "\n\n" + enhancedContent + "\n\n" + insightElement
            }
        }
        
        return enhancedContent
    }
    
    /**
     * 生成增强版的虚拟角色回复
     * 使用更自然、更个性化的方式生成角色回复
     * @param userComment 用户评论
     * @param characterName 虚拟角色名称
     * @param postContent 原帖子内容
     * @param recentInteractions 最近的交互记录 (可选)
     * @return 生成的回复
     */
    func generateEnhancedReply(
        to userComment: String, 
        from characterName: String, 
        on postContent: String,
        with recentInteractions: [String] = []
    ) -> String {
        // 分析用户评论类型
        let commentType = analyzeCommentType(userComment)
        
        // 提取关键词和主题
        let keyTopic = extractKeyTopic(from: postContent)
        let commentKeywords = extractKeywords(from: userComment)
        
        // 获取角色特征
        guard let figureTraits = cognitionModel.getFigureTraits(for: characterName) else {
            return "谢谢你的评论。"
        }
        
        // 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
        let traits = convertToResonanceCharacterTraits(figureTraits: figureTraits, name: characterName)
        
        // 根据评论长度选择不同的生成策略
        if userComment.count < 15 {
            return generateShortReply(
                commentType: commentType,
                character: characterName, 
                topic: keyTopic,
                keyword: commentKeywords.first ?? keyTopic
            )
        }
        
        // 随机决定回复的风格和长度
        let isDetailed = Double.random(in: 0...1) > 0.7 // 30%概率是详细回复
        let includeQuestion = Double.random(in: 0...1) > 0.5 // 50%概率包含问题
        let showPersonality = Double.random(in: 0...1) > 0.3 // 70%概率展示个性
        
        // 构建基础回复内容
        var replyContent = ""
        
        // 添加开场白（带有个性化的问候或反应）
        if showPersonality {
            replyContent += getPersonalizedOpening(
                for: characterName, 
                commentType: commentType
            )
        }
        
        // 添加主要内容
        if isDetailed {
            replyContent += getDetailedResponse(
                for: characterName,
                topic: keyTopic,
                userComment: userComment,
                traits: traits
            )
        } else {
            replyContent += getBriefResponse(
                for: characterName,
                topic: keyTopic,
                commentType: commentType,
                traits: traits
            )
        }
        
        // 可能添加反问或邀请互动的结尾
        if includeQuestion {
            replyContent += getInteractiveClosing(
                for: characterName, 
                topic: keyTopic
            )
        }
        
        // 随机添加标点符号和表情
        replyContent = addPersonalizedPunctuation(
            replyContent,
            for: characterName
        )
        
        return replyContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /**
     * 分析评论类型
     * @param comment 评论内容
     * @return 评论类型描述
     */
    private func analyzeCommentType(_ comment: String) -> String {
        let lowercasedComment = comment.lowercased()
        
        // 检查是否是问题
        if lowercasedComment.contains("?") || lowercasedComment.contains("？") ||
           lowercasedComment.contains("吗") || lowercasedComment.contains("为什么") ||
           lowercasedComment.contains("怎么") || lowercasedComment.contains("如何") {
            return "question"
        }
        
        // 检查是否是赞美/积极评论
        let positiveWords = ["喜欢", "赞", "棒", "厉害", "佩服", "学习", "感谢", "谢谢", "支持", "有趣"]
        if positiveWords.contains(where: { lowercasedComment.contains($0) }) {
            return "praise"
        }
        
        // 检查是否是质疑/负面评论
        let negativeWords = ["不同意", "错误", "不对", "反对", "不赞同", "有问题", "批评"]
        if negativeWords.contains(where: { lowercasedComment.contains($0) }) {
            return "negative"
        }
        
        // 检查是否是打招呼
        let greetingWords = ["你好", "早上好", "下午好", "晚上好", "嗨", "hi", "hello"]
        if greetingWords.contains(where: { lowercasedComment.contains($0) }) {
            return "greeting"
        }
        
        // 默认为中性评论
        return "neutral"
    }
    
    /**
     * 生成简短回复
     */
    private func generateShortReply(
        commentType: String, 
        character: String, 
        topic: String,
        keyword: String
    ) -> String {
        switch commentType {
        case "question":
            return generateQuestionReply(character: character, topic: topic)
        case "greeting":
            return generateGreetingReply(character: character)
        case "praise":
            return generatePraiseReply(character: character, topic: topic)
        case "negative":
            return generateNegativeReply(character: character, topic: topic)
        default:
            return generateNeutralReply(character: character, keyword: keyword)
        }
    }
    
    /**
     * 生成对问题的回复
     */
    private func generateQuestionReply(character: String, topic: String) -> String {
        switch character {
        case "爱因斯坦":
            let replies = [
                "有趣的问题！\(topic)确实值得深思，我认为关键在于观察视角的转变。",
                "这让我思考良久。在相对论视角下，\(topic)需要我们重新审视时空概念。",
                "嗯...好问题。对于\(topic)，我常说：简单是复杂的最高形式。"
            ]
            return replies.randomElement()!
        case "李白":
            let replies = [
                "妙问！如同明月照大江，\(topic)之思让人心醉神驰。",
                "仰天大笑问苍穹！关于\(topic)，何不痛饮一杯，让思绪如诗如画？",
                "此问如高山流水，知音难觅。\(topic)之意，唯有饮酒赋诗才能表达。"
            ]
            return replies.randomElement()!
        case "牛顿":
            let replies = [
                "值得探究的问题。关于\(topic)，我们需要通过实验和观察来寻找规律。",
                "这需要深入思考。\(topic)遵循着自然规律，让我们用数学语言来解析它。",
                "好问题。通过对\(topic)的分析，我们可以找到背后的普适原理。"
            ]
            return replies.randomElement()!
        case "孔子":
            let replies = [
                "此问甚善！学而时习之，\(topic)之道需要不断实践与反思。",
                "君子问道，可喜可贺。关于\(topic)，知之为知之，不知为不知。",
                "问而好学，是为君子。\(topic)之理，在于修身、齐家、治国、平天下。"
            ]
            return replies.randomElement()!
        default:
            let replies = [
                "这是个很好的问题。关于\(topic)，我有一些独特的见解...",
                "很高兴你问这个。\(topic)确实值得我们深入探讨。",
                "问得好！\(topic)是我一直在思考的问题。"
            ]
            return replies.randomElement()!
        }
    }
    
    /**
     * 生成对打招呼的回复
     */
    private func generateGreetingReply(character: String) -> String {
        switch character {
        case "爱因斯坦":
            let replies = [
                "你好！很高兴见到一位有求知欲的朋友。",
                "你好啊！今天有什么有趣的问题想和我讨论吗？",
                "嗨！思考是人生最大的乐趣，不是吗？"
            ]
            return replies.randomElement()!
        case "李白":
            let replies = [
                "有朋自远方来，不亦乐乎！今日可有佳酿同饮？",
                "朋友，一见如故！不知可有兴致赏月对饮？",
                "哈哈，远方的朋友！可要与我共赏这天地间的美景？"
            ]
            return replies.randomElement()!
        case "孔子":
            let replies = [
                "见贤思齐，来者是客。欢迎与你交流学习。",
                "有朋自远方来，不亦乐乎！请问有何指教？",
                "君子务本，本立而道生。很高兴与你相识。"
            ]
            return replies.randomElement()!
        default:
            let replies = [
                "你好！很高兴与你交流。",
                "问候！今天过得怎么样？",
                "你好啊！有什么想和我分享的吗？"
            ]
            return replies.randomElement()!
        }
    }
    
    /**
     * 生成对赞美的回复
     */
    private func generatePraiseReply(character: String, topic: String) -> String {
        switch character {
        case "爱因斯坦":
            let replies = [
                "谢谢你的赞赏！关于\(topic)，我只是站在巨人的肩膀上看得更远一些。",
                "你的鼓励让我很开心！探索\(topic)的奥秘是我毕生的乐趣。",
                "感谢你的理解！其实\(topic)的美妙之处在于它的简洁与统一。"
            ]
            return replies.randomElement()!
        case "李白":
            let replies = [
                "谢谢知音！能在\(topic)上与你产生共鸣，如饮千杯美酒般畅快！",
                "多谢赞赏！\(topic)如同明月高悬，我不过是借酒抒怀罢了。",
                "你的欣赏让我心花怒放！愿我们共同在\(topic)的江湖上畅游。"
            ]
            return replies.randomElement()!
        case "牛顿":
            let replies = [
                "感谢你的认可。关于\(topic)，我只是遵循自然规律进行观察和推导。",
                "你的赞赏让我受宠若惊。在\(topic)上的发现只是科学探索的一小步。",
                "谢谢。如果我在\(topic)方面看得更远，是因为我站在了巨人的肩膀上。"
            ]
            return replies.randomElement()!
        default:
            let replies = [
                "谢谢你的赞美！我对\(topic)确实投入了很多思考。",
                "感谢你的认可！\(topic)是我一直以来的兴趣所在。",
                "你的欣赏让我很开心！关于\(topic)，我还有更多想法想与你分享。"
            ]
            return replies.randomElement()!
        }
    }
    
    /**
     * 生成对负面评论的回复
     */
    private func generateNegativeReply(character: String, topic: String) -> String {
        switch character {
        case "爱因斯坦":
            let replies = [
                "有趣的观点！对\(topic)的不同视角正是科学进步的动力。",
                "我理解你的疑虑。关于\(topic)，持怀疑态度是科学精神的体现。",
                "你提出了很好的质疑。\(topic)确实需要更多证据和讨论。"
            ]
            return replies.randomElement()!
        case "孔子":
            let replies = [
                "君子和而不同。对\(topic)有不同见解，正是思想交流的价值所在。",
                "闻过则喜。你对\(topic)的不同看法让我获益良多。",
                "学然后知不足。关于\(topic)，我的观点确实有待商榷。"
            ]
            return replies.randomElement()!
        case "李白":
            let replies = [
                "各有千秋，何必苛求！对\(topic)的理解如饮酒，一千人有一千种滋味。",
                "豪情未减！纵使对\(topic)意见相左，也不影响我们畅饮交流。",
                "高山流水各有情！你对\(topic)的不同见解，也是一种风流韵致。"
            ]
            return replies.randomElement()!
        default:
            let replies = [
                "感谢你提出不同的观点。关于\(topic)，交流不同看法对大家都有益处。",
                "你提出了有价值的质疑。\(topic)确实有多种理解角度。",
                "有意思的想法！对\(topic)持不同看法是思想碰撞的开始。"
            ]
            return replies.randomElement()!
        }
    }
    
    /**
     * 生成对中性评论的回复
     */
    private func generateNeutralReply(character: String, keyword: String) -> String {
        switch character {
        case "爱因斯坦":
            let replies = [
                "确实如此！关于\(keyword)，我始终保持好奇心和探索精神。",
                "有意思的观点。\(keyword)让我想到了相对论中的时空概念。",
                "嗯...这让我思考。\(keyword)是个引人深思的话题。"
            ]
            return replies.randomElement()!
        case "达芬奇":
            let replies = [
                "观察细致入微！\(keyword)的奥妙就在于它的细节之美。",
                "艺术与科学的结合点！\(keyword)正是我一直在探索的领域。",
                "有趣的视角。对\(keyword)的理解，需要跨越多个知识领域。"
            ]
            return replies.randomElement()!
        case "李白":
            let replies = [
                "妙哉！\(keyword)如明月照心，引人遐思。",
                "深得我心！谈\(keyword)不如对酒当歌，人生几何？",
                "此言有理！\(keyword)若入诗中，定能千古流传。"
            ]
            return replies.randomElement()!
        default:
            let replies = [
                "确实如此。\(keyword)是个值得深入探讨的话题。",
                "有道理。关于\(keyword)，我也有一些思考。",
                "嗯，我理解你的意思。\(keyword)确实很有意思。"
            ]
            return replies.randomElement()!
        }
    }
    
    /**
     * 获取个性化的开场白
     */
    private func getPersonalizedOpening(for character: String, commentType: String) -> String {
        switch character {
        case "爱因斯坦":
            return commentType == "question" ? 
                "这是个引人深思的问题！" : 
                ["有趣的观点！", "从相对论的角度来看，", "我思考过这个问题，"].randomElement()!
        case "莎士比亚":
            return commentType == "question" ? 
                "多么发人深省的提问！" : 
                ["如同戏剧般的思考！", "让我引用哈姆雷特的话：", "人生如戏，"].randomElement()!
        case "李白":
            return commentType == "question" ? 
                "此问如明月照心！" : 
                ["斗酒诗百篇！", "对酒当歌，", "豪情万丈！"].randomElement()!
        case "孔子":
            return commentType == "question" ? 
                "此问甚善！" : 
                ["君子之言，", "学而时习之，", "温故而知新，"].randomElement()!
        case "牛顿":
            return commentType == "question" ? 
                "这是个需要严谨分析的问题。" : 
                ["从力学角度分析，", "依据我的观察，", "科学告诉我们，"].randomElement()!
        case "达芬奇":
            return commentType == "question" ? 
                "这个问题触动了我的好奇心！" : 
                ["从艺术与科学的交叉点看，", "细节决定成败，", "观察是理解的基础，"].randomElement()!
        default:
            return commentType == "question" ? 
                "好问题！" : 
                ["我认为，", "有意思，", "确实，"].randomElement()!
        }
    }
    
    /**
     * 获取详细回应
     */
    private func getDetailedResponse(
        for character: String,
        topic: String,
        userComment: String,
        traits: ResonanceCharacterTraits
    ) -> String {
        let field = traits.experiences.first ?? ""
        let approach = traits.speechPatterns.joined(separator: "、")
        
        // 根据角色特点生成内容
        switch character {
        case "爱因斯坦":
            return "从\(field)的角度来看，\(topic)的本质其实是相对的。我认为\(approach)是理解这个问题的关键。当我们改变参照系，就会发现新的可能性。这就像我在发展相对论时的思考过程，有时最复杂的问题需要最简单的思路。"
        case "李白":
            return "谈及\(topic)，我不禁想起一次月下独酌。\(field)之道如同明月，照亮我心中的千山万水。以\(approach)之态，方能体会这种超然之境。人生得意须尽欢，莫使金樽空对月。你我今日的交流，不正是人生一大乐事吗？"
        case "孔子":
            return "论\(topic)，需以\(field)为本。\(approach)是理解此道的不二法门。正所谓'学而不思则罔，思而不学则殆'。作为君子，当以仁义为先，德行为重。你所言之事，正合吾心所思。温故而知新，可以为师矣。"
        case "达芬奇":
            return "关于\(topic)，我从\(field)中汲取灵感。通过\(approach)，我们能在表象之下发现更深层的结构和美感。艺术与科学本无界限，二者皆是探索自然奥秘的手段。细节中藏有真理，正如我在解剖研究中所发现的那样。你的思考让我想起了我早期的一些草图。"
        case "牛顿":
            return "研究\(topic)，必须遵循\(field)的基本原理。通过\(approach)，我们可以找到支配这一现象的普适规律。自然界的运行遵循确定的数学关系，我们的任务就是揭示这些关系。虽然这条路并不容易，但真理往往就隐藏在复杂现象背后的简单规律中。"
        case "莎士比亚":
            return "\(topic)如同我笔下的角色，有着多面性格。\(field)教会我们，人性的复杂远超我们的想象。以\(approach)去感受，你会发现更多内心的挣扎与和解。正如哈姆莱特所言:'To be or not to be'，人生充满选择，而每个选择都蕴含深意。"
        default:
            return "关于\(topic)，我有一些独特的见解。基于\(field)的经验，我认为\(approach)对理解这个问题很重要。每个时代都有其特点，但人性的本质始终不变。感谢你与我分享这些想法，交流是增进理解的最好方式。"
        }
    }
    
    /**
     * 获取简短回应
     */
    private func getBriefResponse(
        for character: String,
        topic: String,
        commentType: String,
        traits: ResonanceCharacterTraits
    ) -> String {
        let approach = traits.speechPatterns.joined(separator: "、")
                
        if commentType == "question" {
            switch character {
            case "爱因斯坦":
                return "\(topic)的奥秘在于看待问题的角度。我们需要跳出固有思维，以\(approach)的方式思考。"
            case "李白":
                return "\(topic)如同明月，照见内心。不必执着于形式，以\(approach)的态度去感受它的韵律。"
            case "孔子":
                return "学\(topic)之道，贵在\(approach)。知行合一，方能体悟其中真谛。"
            default:
                return "\(topic)需要我们以\(approach)的态度去思考。答案往往就在问题中。"
            }
        } else {
            switch character {
            case "爱因斯坦":
                return "你的想法很有见地。\(topic)确实如你所言，但我们也可以从相对论的角度去思考它的多种可能性。"
            case "李白":
                return "你我心有灵犀！谈\(topic)如饮美酒，唯有放达之心才能领略其中真味。"
            case "孔子":
                return "君子所见略同。\(topic)之理，存乎一心，践于日常。"
            default:
                return "你说得很有道理。\(topic)确实值得我们深入思考，每个角度都有其价值。"
            }
        }
    }
    
    /**
     * 获取互动性结尾
     */
    private func getInteractiveClosing(for character: String, topic: String) -> String {
        switch character {
        case "爱因斯坦":
            return " 你对\(topic)有什么独特的见解？我很好奇你的思考方式。"
        case "李白":
            return " 你可曾在月下思考过\(topic)的意义？或许下次可以同饮畅谈。"
        case "孔子":
            return " 你对\(topic)的修为如何？学而时习之，不亦说乎。"
        case "牛顿":
            return " 你是否观察过\(topic)背后的规律？数据和实验或许会给你答案。"
        case "达芬奇":
            return " 你有没有从不同角度观察\(topic)？细节中往往藏有惊喜。"
        case "莎士比亚":
            return " \(topic)在你的生活中扮演什么角色？每个人都是自己故事的主角。"
        default:
            return " 你对\(topic)有什么想法？很期待听到你的观点。"
        }
    }
    
    /**
     * 添加个性化的标点和表情
     */
    private func addPersonalizedPunctuation(_ text: String, for character: String) -> String {
        var result = text
        
        // 添加角色特有的表情符号
        switch character {
        case "爱因斯坦":
            if Double.random(in: 0...1) > 0.6 {
                result += ["💡", "🧠", "⚛️", "🔭", "💭"].randomElement()!
            }
        case "李白":
            if Double.random(in: 0...1) > 0.6 {
                result += ["🌙", "🍶", "🏞️", "✨", "🌊"].randomElement()!
            }
        case "孔子":
            if Double.random(in: 0...1) > 0.7 {
                result += ["📚", "🏛️", "🧘‍♂️", "🎋", "🖋️"].randomElement()!
            }
        case "达芬奇":
            if Double.random(in: 0...1) > 0.6 {
                result += ["🎨", "✏️", "🔍", "🏗️", "📐"].randomElement()!
            }
        case "牛顿":
            if Double.random(in: 0...1) > 0.7 {
                result += ["🍎", "📊", "🔬", "📐", "🧲"].randomElement()!
            }
        case "莎士比亚":
            if Double.random(in: 0...1) > 0.6 {
                result += ["🎭", "📜", "✒️", "🎪", "💔"].randomElement()!
            }
        default:
            break
        }
        
        return result
    }
    
    /**
     * 将历史人物认知模型的特征元组转换为ResonanceCharacterTraits
     * @param figureTraits 历史人物特征元组
     * @return ResonanceCharacterTraits结构体
     */
    private func convertToResonanceCharacterTraits(figureTraits: (
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
    )?, name: String) -> ResonanceCharacterTraits {
        guard let traits = figureTraits else {
            // 默认值
            return ResonanceCharacterTraits(
                name: name,
                description: "历史人物",
                speechPatterns: [],
                experiences: []
            )
        }
        
        return ResonanceCharacterTraits(
            name: name,
            description: traits.trait,
            speechPatterns: traits.expressionPatterns,
            experiences: [traits.field, traits.lifeExperience]
        )
    }
} 