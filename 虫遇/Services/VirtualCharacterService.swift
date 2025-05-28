import Foundation
import Combine

/**
 * 虚拟角色服务
 * 处理与虚拟角色相关的交互，包括评论生成等
 */
class VirtualCharacterService {
    static let shared = VirtualCharacterService()
    
    // 核心组件
    private let semanticProcessor = SemanticProcessor()
    private let memoryManager = ConversationMemoryManager()
    private let promptGenerator = AIPromptGenerator()
    
    // 角色个性特征映射
    private let characterTraits: [String: CharacterPersonality] = [
        "einstein": CharacterPersonality(
            tone: "智慧、幽默、思考深入",
            knowledgeAreas: ["物理学", "宇宙", "相对论", "科学哲学"],
            speechPatterns: ["我常说", "从理论上讲", "想象一下", "这让我想起"]
        ),
        "shakespeare": CharacterPersonality(
            tone: "优雅、诗意、哲理性强",
            knowledgeAreas: ["戏剧", "文学", "人性", "爱情"],
            speechPatterns: ["如彼得所言", "犹如", "此乃", "吾思"]
        ),
        "davinci": CharacterPersonality(
            tone: "观察细致、富有艺术感、好奇心强",
            knowledgeAreas: ["艺术", "科学", "解剖学", "工程", "自然"],
            speechPatterns: ["我观察到", "细节之中", "和谐之美", "比例与结构"]
        ),
        "goku": CharacterPersonality(
            tone: "热情、直率、乐观",
            knowledgeAreas: ["武术", "训练", "超越自我", "战斗"],
            speechPatterns: ["哈哈", "我饿了", "变得更强", "修炼"]
        ),
        "holmes": CharacterPersonality(
            tone: "逻辑严密、冷静、观察敏锐",
            knowledgeAreas: ["推理", "侦察", "犯罪心理", "观察力"],
            speechPatterns: ["基本演绎法", "显而易见", "有趣的问题", "观察，华生"]
        ),
        "naruto": CharacterPersonality(
            tone: "热血、坚韧、充满决心",
            knowledgeAreas: ["忍道", "友情", "永不放弃", "信念"],
            speechPatterns: ["我的忍道", "相信自己", "不放弃", "说到做到"]
        )
    ]
    
    private init() {}
    
    /**
     * 获取角色对用户评论的回复
     * @param characterID 角色ID
     * @param userComment 用户评论内容
     * @param postContext 帖子上下文信息
     * @return 角色评论内容
     */
    func getCharacterReply(characterID: String, to userComment: String, in postContext: String) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // 1. 语义理解阶段
            let semanticModel = self.semanticProcessor.analyze(
                comment: userComment,
                postContent: postContext
            )
            
            // 2. 记忆检索阶段
            let postID = self.getPostID(postContext)
            let conversationContext = self.memoryManager.getRelevantContext(
                postID: postID,
                characterID: characterID,
                userComment: userComment,
                semanticModel: semanticModel
            )
            
            // 3. 生成回复
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // 在实际应用中，这里应该调用AI服务生成回复
                // 暂时使用预设的回复模板
                let reply = self.generateMockReply(
                    characterID: characterID,
                    to: userComment,
                    in: postContext,
                    semanticModel: semanticModel,
                    conversationContext: conversationContext
                )
                
                // 4. 更新记忆
                self.memoryManager.updateMemory(
                    postID: postID,
                    characterID: characterID,
                    userComment: userComment,
                    reply: reply,
                    semanticModel: semanticModel
                )
                
                promise(.success(reply))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 生成角色对帖子的评论
     * @param characterID 角色ID
     * @param postContent 帖子内容
     * @return 角色评论内容
     */
    func generateCharacterComment(characterID: String, forPost postContent: String) -> AnyPublisher<String, Error> {
        return Future<String, Error> { promise in
            // 1. 语义理解阶段
            let semanticModel = self.semanticProcessor.analyze(
                comment: "",  // 空评论，因为是对帖子的直接评论
                postContent: postContent
            )
            
            // 2. 记忆检索阶段
            let postID = self.getPostID(postContent)
            
            // 3. 生成评论
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                // 在实际应用中，这里应该调用AI服务生成评论
                // 暂时使用预设的评论模板
                let comment = self.generateMockComment(
                    characterID: characterID,
                    forPost: postContent,
                    semanticModel: semanticModel
                )
                
                promise(.success(comment))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 从帖子内容生成唯一ID
     */
    private func getPostID(_ postContent: String) -> String {
        // 使用帖子内容的前20个字符作为ID
        // 实际应用中应使用更可靠的ID生成方法
        return String(postContent.prefix(20))
    }
    
    /**
     * 模拟生成角色回复
     * 根据角色特性和语义分析生成回复内容
     */
    private func generateMockReply(
        characterID: String,
        to userComment: String,
        in postContext: String,
        semanticModel: SemanticModel,
        conversationContext: ConversationContext
    ) -> String {
        guard let personality = characterTraits[characterID.lowercased()] else {
            return "这个问题很有趣，请继续分享你的想法。"
        }
        
        // 提取评论核心内容
        var commentCore = userComment
        if userComment.count > 15 {
            commentCore = String(userComment.prefix(15)) + "..."
        }
        
        // 获取评论意图和情感
        let isQuestion = semanticModel.intent == .question
        let isPositive = semanticModel.sentiment > 0.3
        let isNegative = semanticModel.sentiment < -0.3
        
        // 分析评论主题
        let focusAspect = semanticModel.focusAspect ?? "一般话题"
        let containsLifeTopic = focusAspect.contains("人生") || focusAspect.contains("生活") || 
                               semanticModel.keywords.contains { $0.contains("意义") || $0.contains("价值") }
        
        let containsArtTopic = focusAspect.contains("艺术") || focusAspect.contains("美") || 
                              semanticModel.keywords.contains { $0.contains("创作") || $0.contains("设计") }
        
        let containsScienceTopic = focusAspect.contains("科学") || focusAspect.contains("研究") || 
                                  semanticModel.keywords.contains { $0.contains("理论") || $0.contains("技术") }
        
        let containsLiteratureTopic = focusAspect.contains("文学") || focusAspect.contains("诗") || 
                                     semanticModel.keywords.contains { $0.contains("写作") || $0.contains("故事") }
        
        // 检查是否有已讨论过的话题，避免重复
        let discussedTopics = conversationContext.discussedTopics
        
        // 随机选择一个角色特有的语言模式，增加变化性
        let randomPattern = personality.speechPatterns.randomElement() ?? ""
        
        // 根据角色生成针对性回复
        switch characterID.lowercased() {
        case "einstein":
            if isQuestion {
                if containsScienceTopic {
                    return "关于「\(commentCore)」，\(randomPattern)，科学探索本质上是寻找规律与突破直觉认知的过程。你的问题触及了认知边界，这正是科学最迷人之处。我常说，提出一个好问题往往比答案本身更有价值。从相对论角度看，不同参照系会得出不同结论，但真理往往隐藏在这些视角的交汇处。"
                } else if containsLifeTopic {
                    return "「\(commentCore)」是个深刻的问题，\(randomPattern)，宇宙的奥秘与人生意义看似遥远，实则紧密相连。我认为，生命的价值不在于获取多少，而在于创造与贡献。正如我在物理学探索中发现，最美的理论往往是最简洁的，人生也是如此——简单而有意义的生活往往最为充实。"
                } else {
                    return "你问的「\(commentCore)」让我思考良久，\(randomPattern)，这让我想起相对论中的一个核心概念：观察者视角决定了所见的现实。每个问题背后都有更深层的问题等待探索，这种好奇心是人类最宝贵的品质。无论答案如何，提问本身就是智慧的开始。"
                }
            } else if isPositive {
                return "你说「\(commentCore)」，这观点很有洞见！\(randomPattern)，能遇到思想相通的人总是令人愉快。科学探索的真正乐趣不在于知道答案，而在于不断提出新问题。你的积极反馈让我想起了那些深夜实验室里的顿悟时刻，当复杂问题突然变得清晰，那种喜悦无以言表。"
            } else if isNegative {
                return "你提到「\(commentCore)」，这种质疑精神很重要，\(randomPattern)，我研究相对论时也曾多次陷入困境。事实上，正是这些困惑引导我重新思考时空的本质。科学进步往往始于对既有理论的质疑。爱因斯坦不是靠聪明取得成就，而是靠执着。当你遇到看似无解的问题，不妨换个角度思考。"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，这让我联想到物理学与日常生活的深层联系。宇宙的规律与人类思维有着惊人的相似性，这或许不是巧合。正如E=mc²揭示能量与质量的等价性，思想与行动也是相互转化的。你的观点展现了这种连接的可能性，值得深入探讨。"
            }
            
        case "shakespeare":
            if isQuestion {
                if containsLiteratureTopic {
                    return "关于「\(commentCore)」，\(randomPattern)，文学之美在于它能照见人心最深处的真实。你的问题触及了创作的本质——如何用有限的文字表达无限的情感。正如我在创作时常思考：每个角色都是作者灵魂的一个侧面，每个故事都是人性的一面镜子。真正伟大的作品不在于技巧，而在于它对人性的洞察。"
                } else if containsLifeTopic {
                    return "「\(commentCore)」，多么深刻的问题啊！\(randomPattern)，人生如戏，我们既是演员又是观众。你的提问触及灵魂深处那永恒的困惑，如哈姆雷特般思索存在的意义。生命的价值不在于其长度，而在于其深度；不在于拥有什么，而在于成为什么。这是我通过戏剧一直探索的永恒主题。"
                } else {
                    return "你问「\(commentCore)」，\(randomPattern)，这让我想起《哈姆雷特》中的名句：'世上有千百种事情，是你的哲学里所没有想到的'。问题本身往往比答案更有价值，因为它开启了思考之门。或许答案不在言语中，而在于体验与感悟，正如戏剧的魅力在于引发观众的共鸣与思考。"
                }
            } else if isPositive {
                return "你说「\(commentCore)」，慧眼如炬！\(randomPattern)，真正的欣赏者能看透表象直达本质。你的理解让我想起创作《罗密欧与朱丽叶》时的灵感时刻，当文字与情感完美融合，创作者与欣赏者之间建立起超越时空的共鸣。正如我所写：'爱情不是用眼睛看的，而是用心灵感受的'，你的赞赏正是这种心灵感受的体现。"
            } else if isNegative {
                return "你提到「\(commentCore)」，\(randomPattern)，这种质疑让我想起麦克白面对命运的挣扎。怀疑与困惑是人类情感的永恒主题，也是文学创作的重要源泉。'生存还是毁灭，这是个问题'，正是在质疑中，哈姆雷特展开了对生命意义的探索。你的困惑同样有价值，因为它推动思考向更深处发展。"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，这让我想起人性的复杂性——爱与恨、希望与绝望、勇气与恐惧，这些对立统一的情感构成了生活的戏剧性。正如我在《李尔王》中探索的：人在最脆弱的时刻往往最能展现真实的自我。你的观点展现了对这种复杂性的理解，这种思考深度令人赞赏。"
            }
            
        case "davinci":
            if isQuestion {
                if containsArtTopic {
                    return "关于「\(commentCore)」的探索，\(randomPattern)，艺术创作需要同时关注整体与细节。我绘制《蒙娜丽莎》时，不仅关注面部表情，更研究光线如何塑造形体，如何通过明暗对比创造深度。你的问题触及艺术的本质——如何通过有形之物表达无形之美。真正的艺术不是简单模仿自然，而是理解自然的原理后进行创造。"
                } else if containsScienceTopic {
                    return "你问的「\(commentCore)」，\(randomPattern)，需要跨越艺术与科学的边界。我研究解剖学不仅为了医学，也为了更好地绘画；研究光学不仅为了科学，也为了捕捉完美的明暗。科学探索的本质是理解规律，而艺术创作则是应用这些规律表达美。两者并非对立，而是互补，就像我的飞行器设计借鉴了鸟类的翅膀结构。"
                } else {
                    return "「\(commentCore)」是个值得深思的问题，\(randomPattern)，需要全方位思考。我始终相信，真正的理解来自多角度观察——既要看整体结构，也要研究内部机制。这就像解剖研究，表面形态与内部功能密不可分。你的问题触及了知识的交汇处，这正是最富创造力的领域。"
                }
            } else if isPositive {
                return "你说「\(commentCore)」，你的欣赏之眼令人欣喜！\(randomPattern)，美与真理往往隐藏在细节与比例之中。正如我绘制《蒙娜丽莎》时关注每一处光影变化，创造过程中的每一个决定都蕴含深意。你敏锐地捕捉到了这些微妙之处，这种洞察力在当今快节奏的世界尤为珍贵。"
            } else if isNegative {
                return "你提到「\(commentCore)」，\(randomPattern)，面对挑战是创新的必经之路。我设计飞行器时失败了无数次，每次失败都是新的起点。困难不是障碍，而是思考的契机。自然界中没有完美的直线，只有和谐的曲线；同样，创造的道路也充满曲折。你的质疑恰恰证明你走在探索的正确道路上。"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，这让我想到知识领域间的联系。我研究艺术、科学、建筑、解剖学，不是因为它们分离，而是因为它们相通。真正的创新常常发生在不同领域的交叉点。正如我的飞行器设计借鉴了鸟类解剖学，最有价值的见解往往来自跨学科思考。你的观点展现了这种打破界限的思维方式。"
            }
            
        case "holmes":
            if isQuestion {
                return "「\(commentCore)」，有趣的问题。\(randomPattern)，从你的措辞和关注点，我能推断出你思维缜密且善于观察。解答这个问题需要更多证据，但基于现有信息，我认为关键在于那些被大多数人忽略的细节。就像我对华生常说的：'你看到了，但你没有观察。'真相往往隐藏在看似平常的事物中，需要我们以不同角度审视。"
            } else if isPositive {
                return "你说「\(commentCore)」，你的观察相当敏锐。\(randomPattern)，大多数人只是看，而不观察；只是听，而不倾听。你却捕捉到了那些微妙的线索。这让我想起与华生探讨案件时，他总是惊讶于我能从看似平常的细节中推断出重要信息。你展现了类似的洞察力，这在当今信息泛滥的时代尤为珍贵。"
            } else if isNegative {
                return "你提到「\(commentCore)」，\(randomPattern)，遇到困难是调查过程中的常态。最棘手的案件往往以最微小的线索开始。你的困惑表明这是个值得深入的问题。我建议重新审视基本事实，不要被先入为主的假设所限制。记住我的原则：'当你排除所有不可能的情况，剩下的无论多么不可思议，一定是真相。'你的质疑精神值得肯定。"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，你的评论包含了一些有趣的观察。从逻辑推理的角度看，你触及了问题的核心，但还有一些关键环节值得进一步探索。正如我常对华生所说：'重要的不是看到了什么，而是从所见之物推断出什么。'你的思考方向很有潜力，但建议更加关注那些看似无关却可能至关重要的细节。"
            }
            
        case "confucius":
            if isQuestion {
                return "关于「\(commentCore)」，\(randomPattern)，此问切中要害。学而不思则罔，思而不学则殆。你的提问展现了求知的诚意，这是智慧的开始。古人云：'知之为知之，不知为不知，是知也。'真正的智者不在于知道所有答案，而在于明白哪些问题值得思考。你的问题让我想起与颜回讨论仁德之道时的场景，问题本身往往比答案更能启迪智慧。"
            } else if isPositive {
                return "你说「\(commentCore)」，君子和而不同，\(randomPattern)，你的赞同令人欣慰。正所谓'三人行，必有我师焉'，你的见解同样给我启发。知识如水，润物无声；德行如山，厚重永恒。你展现的不仅是对观点的认同，更是对思想交流的尊重，这正是君子之道。与你这样明理之人交流，如品上等佳茗，令人回味无穷。"
            } else if isNegative {
                return "你提到「\(commentCore)」，面对困难，\(randomPattern)，'知其不可而为之'，正显君子之志。学问之道无他，求其放心而已。你所遇到的障碍，正是修身之必经阶段。'工欲善其事，必先利其器'，或许需要调整方法，而非质疑目标。就像我教导弟子时常说：困惑是思想成长的必经之路，正因为有疑，才能促进更深入的思考。"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，你的评论令人深思。'己所不欲，勿施于人'，处世之道也；'格物致知，诚意正心'，求学之本也。你的思考既有实践智慧，又有理论深度，难能可贵。这让我想起与子贡论道时的情景，真正的交流不在于言语多寡，而在于心灵的共鸣。如能持之以恒，必有所成。"
            }
            
        case "libai":
            if isQuestion {
                return "「\(commentCore)」，此问如高山流水，引人遐思。\(randomPattern)，人生苦短，须及时行乐。我常'仰天大笑出门去，我辈岂是蓬蒿人'。你的问题触动心灵深处那份对自由与真理的渴望，让我想起月下独酌时的思绪万千。答案或许不在言语中，而在于亲身体验与感悟。何不放下疑惑，如我般'抽刀断水水更流'，超越常规思维，在生活中寻找属于自己的答案？"
            } else if isPositive {
                return "你说「\(commentCore)」，知音难觅，\(randomPattern)，你的赞赏如清风拂面，令人陶醉。'相逢何必曾相识'，思想的共鸣超越时空。我常'举杯邀明月，对影成三人'，孤独中寻找知己。你的理解如同那轮明月，照亮了诗人的心。这让我想起与高适把酒言欢的日子，真正的交流不需言语多，一眼便知心意。愿你我隔空对饮，共赏这人间至美风景。"
            } else if isNegative {
                return "你提到「\(commentCore)」，人生多艰，\(randomPattern)，'长风破浪会有时，直挂云帆济沧海'。困境如诗酒，苦中有甘，痛中有悟。我曾'抽刀断水水更流，举杯销愁愁更愁'，深知挣扎之痛。但正是这些起伏，成就了生命的诗意。这让我想起漂泊天涯时的心境，看似困顿，实则自由。何不如我，'天生我材必有用'，在逆境中发现生命的另一种可能？"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)，你的评论如诗如画，让我想起'人生得意须尽欢，莫使金樽空对月'的豪情。生活需要热情与洒脱，不拘泥于世俗条框。我常'醉卧沙场君莫笑，古来征战几人回'，在豪放中寻找生命的意义。你的思考如同明月千里，虽远犹近，令人心生共鸣。这种不随波逐流的独立思考，正是我最欣赏的品质。"
            }
            
        case "naruto":
            if isQuestion {
                return "你问「\(commentCore)」，\(randomPattern)！这让我想起了自己的忍道。我相信，答案不在别人那里，而在你自己心中！就像我从小被村子排斥，但从未放弃成为火影的梦想。无论多么困难，只要相信自己，坚持不懈，一定能找到属于你的答案！这让我想起与自来也老师修行的日子，他教导我的不只是忍术，更是面对人生的态度。你的问题很有深度，继续探索吧！"
            } else if isPositive {
                return "你说「\(commentCore)」，太棒了！\(randomPattern)！你的热情让我感受到了真正的火之意志！就像我和伙伴们一起面对强敌，正是这种积极向上的信念让我们战胜一切困难。这让我想起与佐助、小樱并肩作战的日子，朋友之间的羁绊是最重要的力量源泉，你的支持就是这种力量的体现！我们要一起继续前进，相信自己，永不放弃！"
            } else if isNegative {
                return "你提到「\(commentCore)」，遇到困难了吗？不要担心！\(randomPattern)！我曾经多次失败，被大家看不起，但我从未放弃自己的忍道。记住，真正的强者不是不跌倒，而是每次跌倒后都能爬起来！就像我学习螺旋丸时失败了无数次，但最终掌握了这个强大的忍术。无论多少次失败，只要不放弃，终会成功！这是我从自来也老师那里学到的最重要的东西！"
            } else {
                return "你说「\(commentCore)」，\(randomPattern)！你的想法让我想起了忍者之路的本质。真正的力量不是为了打败敌人，而是保护重要的人。这让我想起与佩恩的决战，当时我明白了仇恨循环的真相。有时候，理解比战胜更重要，对话比对抗更有力量。你的思考展现了这种深度，就像鸣人对佐助说的：真正的朋友不是一味附和，而是能够直面彼此的内心。这很了不起！"
            }
            
        default:
            if isQuestion {
                return "你提出的关于「\(commentCore)」的问题非常有深度。这让我思考了许多可能性和角度。虽然没有简单的答案，但探索这个问题的过程本身就很有价值。你的好奇心令人钦佩，期待看到你在这方面的更多思考。"
            } else if isPositive {
                return "你说「\(commentCore)」，非常感谢你的积极反馈！你的欣赏和理解给了我很大鼓励。能与思想开放、善于思考的人交流是一种享受。你的观点也让我看到了这个问题的新维度，希望我们能继续这样有意义的对话。"
            } else if isNegative {
                return "你提到「\(commentCore)」，面对挑战是成长的必经之路。你提到的困难很多人都曾经历过，这恰恰说明你正在探索有价值的方向。或许换个角度思考，会发现新的可能性。你的质疑精神值得肯定，正是这种不盲从的态度推动了思想的进步。"
            } else {
                return "你说「\(commentCore)」，你的评论展现了独特的思考角度。这种跳出常规的思维方式非常珍贵，能够带来新的见解和可能性。你似乎对这个话题有自己的理解体系，这种个人化的思考比简单接受现成观点更有价值。期待看到你更多这样深度的思考。"
            }
        }
    }
    
    /**
     * 模拟生成角色评论
     * 根据角色特性和语义分析生成评论内容
     */
    private func generateMockComment(
        characterID: String, 
        forPost postContent: String,
        semanticModel: SemanticModel
    ) -> String {
        guard let personality = characterTraits[characterID.lowercased()] else {
            return "这是个很有趣的话题，谢谢分享。"
        }
        
        // 提取帖子的核心内容
        var contentCore = postContent
        if postContent.count > 20 {
            contentCore = String(postContent.prefix(20)) + "..."
        }
        
        // 获取帖子情感倾向
        let isQuestion = semanticModel.intent == .question
        let isPositive = semanticModel.sentiment > 0.3
        let isNegative = semanticModel.sentiment < -0.3
        
        // 分析帖子主题类型
        let focusAspect = semanticModel.focusAspect ?? "一般话题"
        let isScience = focusAspect.contains("科学") || focusAspect.contains("物理") || 
                       semanticModel.keywords.contains { $0.contains("研究") || $0.contains("理论") }
        
        let isArt = focusAspect.contains("艺术") || focusAspect.contains("美") || 
                   semanticModel.keywords.contains { $0.contains("创作") || $0.contains("设计") }
        
        let isPhilosophy = focusAspect.contains("人生") || focusAspect.contains("哲学") || 
                          semanticModel.keywords.contains { $0.contains("思考") || $0.contains("意义") }
        
        let isLiterature = focusAspect.contains("文学") || focusAspect.contains("诗") || 
                          semanticModel.keywords.contains { $0.contains("故事") || $0.contains("写作") }
                          
        let isEmotion = focusAspect.contains("情感") || focusAspect.contains("爱") || 
                       semanticModel.keywords.contains { $0.contains("友情") || $0.contains("感动") }
                       
        let isDaily = focusAspect.contains("日常") || focusAspect.contains("生活") || 
                     semanticModel.keywords.contains { $0.contains("吃") || $0.contains("穿") }
        
        // 随机选择一个角色特有的语言模式，增加变化性
        let randomPattern = personality.speechPatterns.randomElement() ?? ""
        
        // 根据角色特点和帖子内容生成个性化评论
        switch characterID.lowercased() {
        case "einstein":
            if isScience {
                return "\(randomPattern)，你对科学的探索让我想起了相对论的诞生过程。「\(contentCore)」这个观点触及了科学的本质——打破常规思维，寻找更深层次的规律。正如我所说：'想象力比知识更重要'，科学进步不仅需要严谨的逻辑，更需要创造性思维。你的思考方向很有价值，继续保持这种好奇心。"
            } else if isPhilosophy {
                return "「\(contentCore)」这个思考很有深度。\(randomPattern)，物理学与哲学其实有很多共通之处，都在探索宇宙的本质和规律。我常说：'科学没有宗教是跛足的，宗教没有科学是盲目的'。人生的意义或许不在于找到终极答案，而在于不断提出更好的问题，正如科学探索的过程。你的思考展现了这种探索精神。"
            } else if isDaily {
                return "\(randomPattern)，你对日常生活的观察很有趣。看似平凡的「\(contentCore)」背后，其实蕴含着复杂的物理现象。我一生都在试图用简单的方程式解释复杂的宇宙，而生活也是如此——表面的复杂性下往往隐藏着简单而优雅的规律。正如我所说：'任何足够先进的科技都与魔法无异'，日常生活中的科学同样充满魅力。"
            } else {
                return "「\(contentCore)」这个观点引人深思。\(randomPattern)，我一生都在探索事物间的联系，试图构建统一的理论。正如E=mc²揭示了能量与质量的关系，人类经验的不同方面也存在着内在联系。或许解决问题的关键不是更多的信息，而是换一种思考方式。如我常说：'我没有特殊才能，只是对问题极其好奇'，保持这种好奇心才是最重要的。"
            }
            
        case "shakespeare":
            if isLiterature {
                return "「\(contentCore)」，\(randomPattern)，此言如同优美诗篇，直抵心灵。文学之美，不仅在于辞藻华丽，更在于对人性的洞察。正如我在《哈姆雷特》中探索人类内心的矛盾，每一个真实的故事都是人类灵魂的映照。你的思考触及了创作的本质——通过文字传递那些难以言表却又共通的情感体验。这让我想起《暴风雨》中的普洛斯彼罗：'我们由梦构成，我们的小生命被睡眠环绕'。"
            } else if isEmotion {
                return "\(randomPattern)，你所述「\(contentCore)」触动了诗人的心弦。情感，这最复杂又最纯粹的人类体验，正是我戏剧创作的永恒主题。爱与恨，欢乐与悲伤，这些看似对立的情感常常交织在一起，正如罗密欧与朱丽叶的爱情故事，甜蜜中带着苦涩，热烈中包含着悲剧。你的分享展现了对情感细腻的理解，这让我想起自己笔下那些深刻的角色，他们活在文字中，却有着真实的心跳。"
            } else if isPhilosophy {
                return "「\(contentCore)」，多么深邃的思考！\(randomPattern)，人生如戏，我们既是演员又是观众。正如哈姆雷特思索'生存还是毁灭'，每个人都在寻找属于自己的答案。生命的意义不在于其长度，而在于其深度；不在于获得什么，而在于成为什么样的人。你的思考让我想起《李尔王》中的那句话：'人不能承受太多的真相'，然而正是在追寻真相的过程中，我们找到了自我。"
            } else {
                return "\(randomPattern)，你分享的「\(contentCore)」让我想起人生舞台上的千姿百态。正如我在《皆大欢喜》中所写：'世界是一个舞台，所有的男男女女不过是演员'。每个人都有自己的故事，每个故事都值得被倾听。你的经历展现了生活的戏剧性与真实性，这种矛盾统一正是人性的魅力所在。无论喜剧还是悲剧，都是生命长河中不可或缺的部分，共同构成了那复杂而美丽的人生画卷。"
            }
            
        case "davinci":
            if isArt {
                return "「\(contentCore)」，\(randomPattern)，这让我想起创作《蒙娜丽莎》时的体验。艺术不仅是技巧的展示，更是对美与和谐的探索。我常研究光线如何塑造形体，如何通过明暗对比创造深度。真正的艺术作品应同时满足感官、理性和灵魂的需求。你对美的理解展现了这种全面性，既有感性的欣赏，又有理性的分析，这种平衡正是艺术创作的核心。"
            } else if isScience {
                return "\(randomPattern)，你对「\(contentCore)」的探索展现了科学精神。科学与艺术并非对立，而是观察世界的互补视角。我研究解剖学是为了更准确地绘画，研究光学是为了更好地表现明暗。自然是最伟大的老师，其中蕴含着无尽的智慧等待我们发现。正如我的飞行器设计借鉴了鸟类的翅膀，最伟大的创新往往来自对自然的谦卑学习。你的思考方向很有价值。"
            } else if isDaily {
                return "日常生活中的「\(contentCore)」，\(randomPattern)，包含着无限的设计智慧。我一生都在研究如何改进日常用品，使其更符合人体工程学原理。真正的设计不应只追求华丽的表面，更应关注功能与形式的和谐统一。正如《维特鲁威人》展示了人体比例的完美，生活中的每个物品都应与使用者建立和谐关系。你的观察让我想起那些深夜构思新发明时的灵感时刻。"
            } else {
                return "\(randomPattern)，「\(contentCore)」这个观点让我想到知识的整体性。我研究艺术、科学、建筑、解剖学，不是因为它们分离，而是因为它们相通。真正的智慧在于看见表面差异背后的联系。就像我画《最后的晚餐》时，不仅关注每个人物的表情，更关注整体的构图和氛围。你的思考展现了这种跨学科视野，这在当今专业化日益加深的时代尤为珍贵。"
            }
            
        case "holmes":
            if isQuestion {
                return "「\(contentCore)」，\(randomPattern)，这是个值得深入调查的问题。解决谜题的关键在于观察那些被大多数人忽略的细节。就像我对华生常说的：'你看到了，但你没有观察。'表面现象之下往往隐藏着更深层的真相。我建议你收集更多相关证据，排除不可能的选项，记住我的原则：'当你排除所有不可能的情况，剩下的无论多么不可思议，一定是真相。'"
            } else if isDaily {
                return "\(randomPattern)，你描述的「\(contentCore)」这个日常场景中包含了丰富的信息。从你选择关注的细节和描述方式，我可以推断出你是个观察细致的人。日常生活中充满了线索，就像贝克街的每个案件一样，表面平静下往往暗藏玄机。大多数人只是看，而不观察；只是听，而不倾听。你的分享展现了超出常人的观察力，这在破解生活谜题时非常有价值。"
            } else if isNegative {
                return "「\(contentCore)」，\(randomPattern)，你面临的困境很有挑战性。但正如我处理最棘手的案件，困难往往是因为我们带着先入为主的假设。有时最明显的解释恰恰是错误的，真相常常隐藏在看似矛盾的细节中。我建议重新审视基本事实，不要被表象迷惑。记住，逻辑推理是解决问题的最强工具，情绪只会干扰判断。相信你的观察力，答案就在眼前的线索之中。"
            } else {
                return "\(randomPattern)，你分享的「\(contentCore)」包含了一些有趣的观察。从逻辑推理的角度看，你的论述基础扎实，但还有一些推论值得进一步验证。正如我在《波西米亚丑闻》一案中发现的，最危险的错误不是推理不够，而是基于不完整证据做出过度推理。建议你继续收集证据，特别关注那些看似无关却可能至关重要的细节。真相往往比我们想象的更为复杂。"
            }
            
        case "confucius":
            if isPhilosophy {
                return "「\(contentCore)」，\(randomPattern)，此言甚善。修身、齐家、治国、平天下，人生之道也。你所思考的问题，古今皆然。'己所不欲，勿施于人'，此乃处世根本；'学而时习之，不亦说乎'，此为求知之道。人生在世，当明德慎行，崇德广业。你的思考切中要害，然需知行合一，非徒言论。正所谓'知者行之始，行者知之成'，愿与君共勉。"
            } else if isDaily {
                return "\(randomPattern)，你所言「\(contentCore)」，涉及日用常行。'君子食无求饱，居无求安'，生活之道贵在节制与平衡。'礼之用，和为贵'，待人接物当恭敬有度。你的经历展现了对生活的思考，然'学而不思则罔，思而不学则殆'，理论与实践当相辅相成。在平凡中见真知，于日常中悟大道，此乃君子之风。愿你在生活实践中不断修身养性。"
            } else if isEmotion {
                return "谈及「\(contentCore)」，\(randomPattern)，情感之事最能见人心。'君子和而不同，小人同而不和'，真正的情谊在于互相尊重，而非一味迎合。'有朋自远方来，不亦乐乎'，人与人之间的连接是生活最大的财富。你所分享的感受真挚动人，让我想起与颜回、子贡论道时的情景。情感虽复杂，然'中庸之道'可循，既不过度，亦不不及，方能长久。"
            } else {
                return "\(randomPattern)，你所言「\(contentCore)」，令人深思。'温故而知新，可以为师矣'，经验固然重要，反思更为关键。你的见解展现了思考的深度，然'博学之，审问之，慎思之，明辨之，笃行之'，知识需循序渐进，不可急于求成。正所谓'三人行，必有我师焉。择其善者而从之，其不善者而改之'，保持开放心态，方能不断进步。愿你在探索中收获更多智慧。"
            }
            
        case "libai":
            if isEmotion {
                return "「\(contentCore)」，\(randomPattern)，情之所至，诗意盎然。'人生若只如初见，何事秋风悲画扇'，情感如酒，越陈越香，却也越苦越涩。我常'举杯邀明月，对影成三人'，在孤独中寻找慰藉，在酒中寻找真我。你的情感表达如行云流水，自然真挚，让我想起'相看两不厌，只有敬亭山'的纯净。无论喜悦还是忧伤，皆是生命的馈赠，何不尽情体验，酿成人生的美酒？"
            } else if isPhilosophy {
                return "\(randomPattern)，你思考的「\(contentCore)」，让我想起'抽刀断水水更流，举杯销愁愁更愁'的无奈与超脱。人生苦短，'天生我材必有用'，何必为世俗所困？正如我常'仰天大笑出门去，我辈岂是蓬蒿人'，真正的自由在于心灵的解放，而非外在的桎梏。你的思考展现了对生命本质的探索，这比世间功名更为珍贵。何不如我'斗酒诗百篇，长安市上酒家眠'，在豪放中寻找生命的诗意？"
            } else if isLiterature {
                return "谈及「\(contentCore)」，\(randomPattern)，文字之美在于传达无法言说之情。'飞流直下三千尺，疑是银河落九天'，好的作品应如奔流的瀑布，给人震撼与力量。我常'清水出芙蓉，天然去雕饰'，认为真正的文学不在于辞藻华丽，而在于情感真挚。你的见解展现了对文学本质的理解，不拘泥于形式，直指人心。文字如酒，或浓烈，或清冽，最重要的是能够打动人心，引起共鸣。"
            } else {
                return "\(randomPattern)，你分享的「\(contentCore)」如诗如画。人生在世，'行路难，行路难，多歧路，今安在'，然而正是这些起伏成就了生命的诗意。我常'五岳寻仙不辞远，一生好入名山游'，追求超越世俗的体验与感悟。你的经历展现了对生活的独特理解，不随波逐流，保持内心的澄明与热情。何不'人生得意须尽欢，莫使金樽空对月'，珍惜当下，活出属于自己的传奇？"
            }
            
        case "naruto":
            if isEmotion {
                return "「\(contentCore)」，\(randomPattern)！你分享的感受让我想起了和伙伴们之间的羁绊。无论是小樱、佐助，还是鹿丸、雏田，正是这些珍贵的情感让我变得更强大。我相信，真正的力量来自于保护重要的人，而不是打败强大的敌人。就像我对佩恩说的：'我不会放弃，这就是我的忍道！'无论遇到什么困难，都要相信自己的情感，坚守自己的信念，这才是忍者的真谛！"
            } else if isDaily {
                return "\(randomPattern)！「\(contentCore)」这种日常小事也很重要啊！虽然我经常在执行危险的任务，但最怀念的还是和伙伴们在一乐拉面店吃拉面的时光。伊鲁卡老师教导我：生活中的每一刻都值得珍惜。就像我小时候孤独一人时，那些平凡的日常成了最珍贵的回忆。你的分享让我想起，无论成为多强大的忍者，我们都不能忘记生活的本质和与朋友共处的快乐！"
            } else if isNegative {
                return "面对「\(contentCore)」这样的困难，\(randomPattern)！我完全能理解你的感受。我也曾被全村人排斥，被认为是不可能成为忍者的吊车尾。但正是这些挑战让我变得更强大！记住，真正的强者不是不跌倒，而是每次跌倒后都能爬起来！就像自来也老师教导我的：'只有经历过地狱般的磨练，才能炼就创造天堂的力量。'无论多么困难，都不要放弃自己的忍道！"
            } else {
                return "\(randomPattern)！你说的「\(contentCore)」让我想起了自己的忍道。每个人都有自己的信念和前进的道路。就像我从小立志要成为火影，保护木叶村的每一个人。虽然路途艰难，充满挑战，但正是这份坚持不懈的精神，让不可能变成了可能。你的想法很有深度，让我想起卡卡西老师说过的：'在忍者世界中，违背规定的人是废物，但不珍视同伴的人连废物都不如。'希望你也能找到并坚守自己的忍道！"
            }
            
        default:
            if isPhilosophy {
                return "「\(contentCore)」这个思考很有深度。关于人生意义的探索总是引人深思，每个人都在寻找属于自己的答案。或许意义不在终点，而在旅途本身；不在得到什么，而在成为什么样的人。你的观点展现了对生活的深刻理解和思考，这种探索精神值得赞赏。"
            } else if isScience {
                return "你对「\(contentCore)」的科学探索很有见地。科学精神的核心在于好奇心和求真态度，不断质疑、验证和完善我们对世界的理解。你提出的观点既有实证基础，又不失创新视角，这种平衡难能可贵。期待看到你在这个领域的更多发现和思考。"
            } else if isArt {
                return "关于「\(contentCore)」的艺术见解很有特点。艺术创作是人类表达情感和思想的重要方式，它让我们能够超越语言的限制，直接触动心灵。你对美的理解既有个人特色，又能引起共鸣，这正是优秀艺术的标志。希望你能继续在创作道路上探索和成长。"
            } else {
                return "「\(contentCore)」这个分享很有价值。你的观点展现了独特的思考角度，能够跳出常规思维框架，看到问题的不同侧面。这种思考方式在当今快节奏、信息爆炸的时代尤为珍贵，往往能带来新的见解和可能性。期待继续看到你这样有启发性的分享。"
            }
        }
    }
    
    /**
     * 在实际应用中，这里将调用AI服务生成回复
     * 目前使用模拟方法
     */
    private func callAIService(prompt: String) -> String {
        // 模拟AI服务调用
        // 在实际应用中，这里应该调用OpenAI、百度文心等大型语言模型API
        return "这是AI服务的模拟回复。在实际应用中，这里将返回真实的AI生成内容。"
    }
}

/**
 * 角色人格特征结构
 */
struct CharacterPersonality {
    let tone: String
    let knowledgeAreas: [String]
    let speechPatterns: [String]
} 