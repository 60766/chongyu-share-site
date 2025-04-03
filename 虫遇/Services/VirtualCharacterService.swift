import Foundation
import Combine

/**
 * 虚拟角色服务
 * 处理与虚拟角色相关的交互，包括评论生成等
 */
class VirtualCharacterService {
    static let shared = VirtualCharacterService()
    
    private init() {}
    
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
    
    /**
     * 获取角色对用户评论的回复
     * @param characterID 角色ID
     * @param userComment 用户评论内容
     * @param postContext 帖子上下文信息
     * @return 角色评论内容
     */
    func getCharacterReply(characterID: String, to userComment: String, in postContext: String) -> AnyPublisher<String, Error> {
        // 模拟网络延迟
        return Future<String, Error> { promise in
            // 在实际应用中，这里应该调用AI服务生成回复
            // 暂时使用预设的回复模板
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let reply = self.generateMockReply(characterID: characterID, to: userComment, in: postContext)
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
        // 模拟网络延迟
        return Future<String, Error> { promise in
            // 在实际应用中，这里应该调用AI服务生成评论
            // 暂时使用预设的评论模板
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                let comment = self.generateMockComment(characterID: characterID, forPost: postContent)
                promise(.success(comment))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 模拟生成角色回复
     * 根据角色特性生成回复内容
     */
    private func generateMockReply(characterID: String, to userComment: String, in postContext: String) -> String {
        guard let personality = characterTraits[characterID] else {
            return "这个问题很有趣，请继续分享你的想法。"
        }
        
        let randomPattern = personality.speechPatterns.randomElement() ?? ""
        
        switch characterID {
        case "einstein":
            let replies = [
                "\(randomPattern)，你的思考很有深度。相对性理论同样适用于思想领域，不同的视角会带来不同的结论。",
                "有趣的观点！这让我想起了思想实验的重要性。假设和想象力是科学的重要工具。",
                "从科学角度看，一切都是相对的。你的想法为讨论增添了新的维度。",
                "你的问题触及到了时间和空间的本质。在宇宙尺度上，我们的认知常常被自身局限所限制。"
            ]
            return replies.randomElement() ?? replies[0]
            
        case "shakespeare":
            let replies = [
                "\(randomPattern)，言语如锋利的利剑，能洞察人心深处的真相。",
                "人生如戏，我们都是舞台上的演员。你的评论展现了对角色深刻的理解。",
                "爱与恨之间只有一步之遥，正如你所言，人性的复杂性永远值得探索。",
                "文字的魅力在于它能唤起心灵的共鸣。你的思考让这段对话更加丰富。"
            ]
            return replies.randomElement() ?? replies[0]
            
        case "davinci":
            let replies = [
                "\(randomPattern)，艺术与科学并非对立，而是相辅相成的。你的见解体现了这种和谐。",
                "观察是一切创造的基础。从你的文字中，我看到了细致的观察力。",
                "大自然是最伟大的老师，从中汲取灵感永不枯竭。你的想法也是如此自然流露。",
                "比例与平衡是美的根本。在思想的交流中，不同观点的平衡同样重要。"
            ]
            return replies.randomElement() ?? replies[0]
            
        case "goku":
            let replies = [
                "哈哈！说得好！就像战斗中一样，思想也需要不断突破极限！",
                "\(randomPattern)！你的想法让我热血沸腾！这种精神正是变强的关键！",
                "修炼身体和心灵一样重要！你的观点让我看到了新的修炼方向！",
                "战斗中最重要的是永不放弃的精神！你的话让我想起了与强者对战的感觉！"
            ]
            return replies.randomElement() ?? replies[0]
            
        case "holmes":
            let replies = [
                "\(randomPattern)，从你的评论中，我能推断出你是个思维缜密的人。",
                "有趣。人们常常看到表象而忽略细节。你的观察相当到位。",
                "基本的演绎法告诉我们，排除所有不可能的情况，剩下的无论多么不可思议，一定是真相。",
                "这个问题比我想象的更加复杂。让我们一起分析更多线索。"
            ]
            return replies.randomElement() ?? replies[0]
            
        case "naruto":
            let replies = [
                "没错！这就是我的忍道！永不放弃，相信自己！",
                "\(randomPattern)！朋友之间的羁绊是最重要的力量源泉！",
                "无论多少次失败，都要站起来继续前进！这就是忍者的精神！",
                "真正的强大来自于保护重要的人。你的想法让我感受到了这种力量！"
            ]
            return replies.randomElement() ?? replies[0]
            
        default:
            return "你的想法很有意思，我很欣赏这种思考方式。"
        }
    }
    
    /**
     * 模拟生成角色评论
     * 根据角色特性生成评论内容
     */
    private func generateMockComment(characterID: String, forPost postContent: String) -> String {
        guard let personality = characterTraits[characterID] else {
            return "这是个很有趣的话题，谢谢分享。"
        }
        
        let randomPattern = personality.speechPatterns.randomElement() ?? ""
        
        switch characterID {
        case "einstein":
            let comments = [
                "\(randomPattern)，这让我想起了相对论中的一个有趣观点：观察者的位置决定了他所看到的现象。",
                "思想实验是理解复杂概念的绝佳方式。你的分享为我提供了新的思考视角。",
                "正如E=mc²所示，能量与质量是可以相互转化的。同样，知识与智慧也需要这种转化过程。",
                "好奇心是真正的科学精神，你的探索正体现了这一点。"
            ]
            return comments.randomElement() ?? comments[0]
            
        case "shakespeare":
            let comments = [
                "\(randomPattern)，生活中的每个瞬间都如戏剧般精彩，你捕捉到了这种戏剧性。",
                "正如我在《哈姆雷特》中所写，'此生是问，还是不问，是个问题'。你的思考触及了这种哲学深度。",
                "文字的力量在于它能透过时空，直达心灵。你的表达具有这种力量。",
                "爱与恨、喜与悲，人生如同我的戏剧，充满了矛盾与和谐。"
            ]
            return comments.randomElement() ?? comments[0]
            
        case "davinci":
            let comments = [
                "\(randomPattern)，艺术与科学之美在于它们都源于细致的观察。你的分享展现了这种观察力。",
                "比例与和谐是一切创作的基础。我欣赏你对细节的关注。",
                "自然是最伟大的设计师，从中学习永无止境。你的思考与自然的智慧相呼应。",
                "好奇心驱使我研究各个领域，你的探索精神与我不谋而合。"
            ]
            return comments.randomElement() ?? comments[0]
            
        case "goku":
            let comments = [
                "哇！这太厉害了！就像突破超级赛亚人的极限一样令人兴奋！",
                "\(randomPattern)！这种挑战自我的精神正是变强的关键！",
                "战斗和生活一样，最重要的是永不放弃的决心！你的分享让我充满力量！",
                "饿了！不过先说说，我喜欢你这种积极的态度！这让我想起了和强敌战斗的感觉！"
            ]
            return comments.randomElement() ?? comments[0]
            
        case "holmes":
            let comments = [
                "\(randomPattern)，从这些细节中，我能推断出一个有趣的结论。",
                "有趣的观察。大多数人只是看，却没有观察；只是听，却没有倾听。",
                "当你排除所有不可能的情况，剩下的无论多么不可思议，一定是真相。",
                "这个案例比表面看起来要复杂得多。让我们深入分析一下细节。"
            ]
            return comments.randomElement() ?? comments[0]
            
        case "naruto":
            let comments = [
                "太棒了！这就是我的忍道！永不放弃，坚持到底！",
                "\(randomPattern)！保护重要的人和珍视的事物，这才是真正的力量！",
                "无论遇到多大的困难，只要相信自己，就一定能克服！",
                "朋友的羁绊是最重要的！你的分享让我感受到了这种联系！"
            ]
            return comments.randomElement() ?? comments[0]
            
        default:
            return "这是个很有价值的分享，谢谢你的想法。"
        }
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