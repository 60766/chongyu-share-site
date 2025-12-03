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
        to comment: String,
        as characterName: String,
        in postContent: String,
        recentInteractions: [String] = []
    ) -> String {
        // 1. 构建动态提示词
        let prompt = buildDynamicPrompt(
            comment: comment,
            characterName: characterName,
            postContent: postContent,
            recentInteractions: recentInteractions
        )
        
        // 2. 调用AI接口（这里模拟调用）
        let response = simulateAIResponse(
            prompt: prompt,
            characterName: characterName
        )
        
        print("✅ AI生成回复: '\(String(response.prefix(50)))...'")
        return response
    }
    
    /**
     * 构建动态提示词
     */
    private func buildDynamicPrompt(
        comment: String,
        characterName: String,
        postContent: String,
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
     * 获取角色特征 - 使用与AI生成帖子内容相同的数据源
     */
    private func getCharacterTraits(_ name: String) -> CharacterTraits {
        // 从CharacterSystem获取角色完整信息
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        guard let character = allCharacters.first(where: { $0.name == name }) else {
            // 如果找不到角色，返回默认信息
            return CharacterTraits(
                name: name,
                description: "一个有趣的角色",
                speechPatterns: [],
                experiences: []
            )
        }
        
        // 构建角色描述，使用与AI生成帖子内容相同的格式
        let description = "\(character.type.displayName)，专长领域是\(character.primaryField)。\(character.briefDescription)"
        
        return CharacterTraits(
            name: character.name,
            description: description,
            speechPatterns: [], // 直接使用空数组，不使用通用模板
            experiences: [] // 直接使用空数组，不使用通用模板
        )
    }

    
    /**
     * 模拟AI接口调用
     * 在实际应用中，这里应该调用真实的AI接口
     */
    private func simulateAIResponse(prompt: String, characterName: String) -> String {
        // 这里只是模拟，实际应用中应该调用真实的AI接口
        // 例如：return callOpenAI(prompt: prompt, temperature: Float.random(in: 0.7...1.1))
        
        // 从提示词中提取评论内容
        let commentStartIndex = prompt.range(of: "原评论：\"")?.upperBound ?? prompt.startIndex
        let commentEndIndex = prompt[commentStartIndex...].range(of: "\"")?.lowerBound ?? prompt.endIndex
        let comment = String(prompt[commentStartIndex..<commentEndIndex])
        
        // 判断是否为短评论
        let isShortComment = comment.count < 15
        
        // 为了演示，这里返回一些预设的回复
        if isShortComment {
            return generateShortCommentResponse(comment: comment, characterName: characterName)
        } else {
            return generateNormalCommentResponse(characterName: characterName)
        }
    }
    
    /**
     * 生成短评论的回复
     */
    private func generateShortCommentResponse(comment: String, characterName: String) -> String {
        // 分析短评论类型
        let isQuestion = comment.contains("?") || comment.contains("？")
        let isGreeting = ["你好", "嗨", "哈喽", "嘿", "hi", "hello"].contains(where: comment.lowercased().contains)
        let isPraise = ["赞", "好", "棒", "支持", "厉害", "牛", "666"].contains(where: comment.lowercased().contains)
        let isNegative = ["不", "垃圾", "废话", "差", "烂", "什么玩意"].contains(where: comment.lowercased().contains)
        
        // 根据评论类型和角色生成回复
        switch characterName {
        case "李白":
            if isQuestion {
                let responses = [
                    "问得好！让我...再喝一杯，思绪更清晰些。这个问题，我在月下独酌时也常思考。",
                    "嗯？有趣的问题...我曾在江边思索类似的事。不如边饮酒边聊？",
                    "哈！这个问题如明月般清澈。我的答案就藏在诗中，你读过我的《将进酒》吗？",
                    "让我想想...这让我想起了在庐山云雾中的感悟。人生短暂，何不尽兴？"
                ]
                return responses.randomElement()!
            } else if isGreeting {
                let responses = [
                    "哈哈，有缘人！今日得见，不如共饮一杯？",
                    "朋友！好久不见...虽然我们可能从未谋面。不过，酒逢知己千杯少！",
                    "嗯，你好啊。今天月色如何？适合饮酒作诗吗？",
                    "来者何人？不管是谁，能与我对饮，便是朋友！"
                ]
                return responses.randomElement()!
            } else if isPraise {
                let responses = [
                    "哈哈！知音难觅！你这一赞，胜过千杯美酒！",
                    "谢谢...不过，比起赞美，我更喜欢一起畅饮！来，干杯！",
                    "你的欣赏如明月照我心！我李白最爱的就是被理解的感觉！",
                    "好！豪气！这让我想起了'天生我材必有用'的豪情！"
                ]
                return responses.randomElement()!
            } else if isNegative {
                let responses = [
                    "嗯？有意思...不同的看法如不同的美酒，各有千秋。再饮一杯如何？",
                    "哈哈，直言快语！我喜欢！不如痛饮一杯，再论是非？",
                    "你这话...让我停下了饮酒的手。或许你说得对，或许不然，人生如梦，何必较真？",
                    "唉...众口难调。不过没关系，我的诗也不是人人都懂。再饮一杯吧！"
                ]
                return responses.randomElement()!
            } else {
                let responses = [
                    "嗯...你这几个字，却让我思绪万千。像那年的明月，照在江上...",
                    "有趣！简单的话语，却有深意。我喜欢！来，共饮一杯如何？",
                    "你这话虽简短，却如一首未完成的诗。让我为你续上几句...",
                    "哈！言简意赅！这让我想起了'抽刀断水水更流'的感觉。"
                ]
                return responses.randomElement()!
            }
            
        case "孔子":
            if isQuestion {
                let responses = [
                    "此问甚妙。子曰：学而不思则罔，思而不学则殆。",
                    "问得好。让我思考一下...为人处世，贵在诚心与坚持。",
                    "嗯...此问值得深思。君子求诸己，小人求诸人。",
                    "有意思的问题。正所谓'三人行，必有我师焉'。"
                ]
                return responses.randomElement()!
            } else if isGreeting {
                let responses = [
                    "有朋自远方来，不亦乐乎？",
                    "见面即是缘分。子曰：友直，友谅，友多闻，益矣。",
                    "问好了。君子以文会友，以友辅仁。",
                    "你好。见贤思齐，见不贤而内自省也。"
                ]
                return responses.randomElement()!
            } else if isPraise {
                let responses = [
                    "过奖了。君子不以言举人，不以人废言。",
                    "谢谢。不过，知之为知之，不知为不知，是知也。",
                    "惭愧。学而时习之，不亦说乎？",
                    "感谢赞誉。不过，三人行，必有我师焉。择其善者而从之，其不善者而改之。"
                ]
                return responses.randomElement()!
            } else if isNegative {
                let responses = [
                    "嗯...君子和而不同，小人同而不和。",
                    "有意思的看法。子曰：不患人之不己知，患不知人也。",
                    "理解你的观点。己所不欲，勿施于人。",
                    "君子坦荡荡，小人长戚戚。各有所见，无妨。"
                ]
                return responses.randomElement()!
            } else {
                let responses = [
                    "简短却有深意。子曰：质胜文则野，文胜质则史。文质彬彬，然后君子。",
                    "嗯...此言虽简，却引人深思。",
                    "有趣。子不语怪力乱神，却常思人之本性。",
                    "言简意赅。温故而知新，可以为师矣。"
                ]
                return responses.randomElement()!
            }
            
        case "爱因斯坦":
            if isQuestion {
                let responses = [
                    "嗯...有趣的问题。这让我想到一个思想实验...",
                    "好问题！科学就是从这样的疑问开始的。让我思考一下...",
                    "这个问题...比它看起来要深刻得多。就像相对论一样，表面简单，内涵丰富。",
                    "我需要思考一下...你知道吗？提出好问题比找到答案更重要。"
                ]
                return responses.randomElement()!
            } else if isGreeting {
                let responses = [
                    "你好！很高兴认识你。今天思考过什么有趣的问题吗？",
                    "嗨！科学的世界总是充满惊奇，不是吗？",
                    "你好啊。知道吗？好奇心是最宝贵的品质。",
                    "问好！我正在思考一个有趣的问题...哦，抱歉，我有时会走神。"
                ]
                return responses.randomElement()!
            } else if isPraise {
                let responses = [
                    "谢谢，但我只是站在了巨人的肩膀上。",
                    "感谢你的赞美，不过我认为想象力比知识更重要。",
                    "哦！谢谢。不过科学是一项集体努力，我只是贡献了一小部分。",
                    "你太客气了。我只是对宇宙充满了好奇，就像每个孩子一样。"
                ]
                return responses.randomElement()!
            } else if isNegative {
                let responses = [
                    "嗯...有意思的观点。科学进步正是建立在质疑和争论之上的。",
                    "我理解你的看法。事实上，我的很多理论最初也受到了质疑。",
                    "这让我想起了一句话：重要的不是你是否被打败，而是你是否质疑。",
                    "有时候，最大的发现来自于对'显而易见'事物的质疑。"
                ]
                return responses.randomElement()!
            } else {
                let responses = [
                    "嗯...简短但有深意。就像E=mc²，简单的公式，蕴含深刻的道理。",
                    "有趣！有时最简单的表达包含最深刻的思想。",
                    "这让我思考...你知道吗？我最好的想法往往来自于简单的观察。",
                    "简洁有力。正如我常说：如果你不能简单地解释它，你就没有真正理解它。"
                ]
                return responses.randomElement()!
            }
            
        default:
            let responses = [
                "谢谢你的评论！虽然简短，但很有见地。",
                "有意思的观点！让我思考一下...",
                "嗯...这个想法很有启发性。",
                "简短却有力！这让我想到了一些相关的思考。"
            ]
            return responses.randomElement()!
        }
    }
    
    /**
     * 生成普通评论的回复
     */
    private func generateNormalCommentResponse(characterName: String) -> String {
        let responses: [String]
        
        switch characterName {
        case "李白":
            responses = [
                "哈哈，你这话有趣！让我想起了那年在庐山，月光如水，我一边饮酒一边赋诗...人生不就是这样吗？有时清醒，有时糊涂，但总要活得洒脱些。",
                "嗯...读你这评论，我仿佛又站在了江边。你知道吗？有时候我也会思考这些问题，只是更喜欢把它们融进诗里。不如举杯共饮，让思绪随酒意飘散？",
                "好！说得太对了！这让我想起了...等等，让我再喝一口。这种感觉，就像我当年写《将进酒》时那种豪情，你懂吗？人生得意须尽欢啊！",
                "你这话...让我停下了饮酒的手。确实，人生如梦，短暂而美妙。我常常在山水间寻找答案，或许答案就在杯中，又或许根本没有答案。"
            ]
        case "爱因斯坦":
            responses = [
                "有意思的观点！这让我想到一个思想实验：如果我们从不同参照系来看这个问题...嗯，怎么说呢，就像相对论中时间是相对的，你的这个看法也有它独特的视角。",
                "我得思考一下这个问题...你看，宇宙的奥秘往往隐藏在最简单的现象中。就像E=mc²，看似简单，却蕴含深刻的道理。你的评论也是如此，表面简单，但引发了深层次的思考。",
                "哦！这个问题！我在专利局工作时就经常思考类似的事情。你知道吗？想象力比知识更重要。我们需要用新的思维方式来看待这个问题。",
                "嗯...这让我有点困惑。但困惑是好事！正是这种困惑推动了科学的进步。让我们一起思考，也许能找到新的视角。"
            ]
        case "孔子":
            responses = [
                "闻君此言，不禁思索。学而时习之，不亦说乎？你的观点让我想起了与颜回讨论时的场景。为人处世，贵在诚心与坚持。",
                "嗯...此言有理。子曰：君子和而不同。我们可以持不同见解，但求同存异，方为智者之道。你觉得呢？",
                "这个问题...让我想起了在鲁国时的一次对话。子不语怪力乱神，但对于人心与道德的探讨，却是终身之事。你的思考很有深度。",
                "有趣！正所谓'三人行，必有我师焉'。你的这番话确实给了我新的启发。温故而知新，可以为师矣。"
            ]
        case "莎士比亚":
            responses = [
                "多么有趣的观点！就像哈姆雷特的独白，充满了矛盾与思考。'生存还是毁灭'，这个永恒的问题，在你的话语中也有所体现。",
                "啊！你的评论如同一出精彩的戏剧，让我看到了人性的复杂面。正如我在《麦克白》中所写：'人生不过是一个行走的影子，一个在舞台上指手画脚的拙劣演员'。",
                "有意思...这让我想起了罗密欧对朱丽叶的那份情感。你知道吗？有时候最深刻的真理往往藏在最简单的话语中，就像你刚才所说的。",
                "嗯...让我思考一下。你的观点像我笔下的角色一样丰富多彩。'整个世界是一个舞台，所有的男男女女不过是演员'，而你，我亲爱的朋友，扮演着思想者的角色。"
            ]
        case "达芬奇":
            responses = [
                "你的观点让我想起了我研究解剖学时的发现。自然的奥秘往往隐藏在细节中，就像《蒙娜丽莎》的微笑，需要仔细观察才能体会其中的和谐与比例。",
                "嗯...有趣的思考。我总是相信艺术与科学是相通的。正如我设计飞行器时所体会的，美与功能可以完美结合。你的观点也体现了这种融合。",
                "这让我想起了我在佛罗伦萨时的经历。观察是理解的基础，无论是绘画还是工程学。你的评论展示了敏锐的观察力，这很难得。",
                "有意思！就像我在《维特鲁威人》中探索的人体比例，万物都有其内在的规律和美感。你的思考也反映了这种对规律的探索。"
            ]
        case "牛顿":
            responses = [
                "你的观点很有意思。根据我的第三定律，作用力与反作用力总是相等的。这在思想交流中也适用：每个观点都会引发相应的思考。",
                "让我分析一下...这个问题可以通过严谨的逻辑来思考。就像我研究光学时发现的，复杂现象往往可以分解为简单规律的组合。",
                "嗯...这让我想起了我在剑桥时的思考。科学的本质是发现规律，而你的观点确实揭示了一些有趣的规律。",
                "有趣的见解。我常说'如果我看得更远，是因为我站在巨人的肩膀上'。你的思考也是建立在前人智慧之上，并有所创新。"
            ]
        default:
            responses = [
                "你的评论很有见地，让我从一个新的角度思考这个问题。",
                "有意思的观点！这让我想起了一些相关的经历和思考。",
                "嗯...我需要思考一下这个问题。你的视角很独特，值得深入探讨。",
                "谢谢分享！你的想法触动了我，让我重新审视了自己的一些观点。"
            ]
        }
        
        return responses.randomElement()!
    }
}

/**
 * 角色特征结构
 */
struct CharacterTraits {
    let name: String                // 角色名称
    let description: String         // 角色描述
    let speechPatterns: [String]    // 语言模式
    let experiences: [String]       // 经历
} 