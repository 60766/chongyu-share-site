import Foundation
import Combine
import UIKit

/**
 * AI内容生成器
 * 负责使用API生成五种类型的内容
 */
class AIContentGenerator {
    // 单例实例
    static let shared = AIContentGenerator()
    
    // MARK: - 私有属性
    private init() {}
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 虫洞共鸣内容生成
    
    /**
     * 生成虫洞共鸣内容
     * @param figure 历史人物
     * @param situation 情境
     * @param expectation 期望
     * @return Future<String, Error>
     */
    func generateResonanceContent(
        figure: String,
        situation: String,
        expectation: String
    ) -> Future<String, Error> {
        return Future { promise in
            // 调用带评论的生成方法，然后只返回内容部分
            self.generateResonanceContentWithComments(
                figure: figure,
                situation: situation,
                expectation: expectation,
                commentersCount: 3  // 默认生成3条评论
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { result in
                    // 只返回内容部分，忽略评论
                    promise(.success(result.content))
                }
            )
            .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 虫洞共鸣内容生成（增强版）
    
    /**
     * 生成虫洞共鸣内容（真实情感连接版本）
     * @param figure 历史人物
     * @param situation 情境 - 用户当前面临的处境或问题
     * @param expectation 期望 - 用户希望获得的启发或答案
     * @param keyword 关键词（可选）- 用户特别关注的方面
     * @return Future<String, Error>
     */
    func generateEnhancedResonanceContent(
        figure: String,
        situation: String,
        expectation: String,
        keyword: String? = nil
    ) -> Future<String, Error> {
        return Future { promise in
            // 调用带评论的生成方法，然后只返回内容部分
            self.generateResonanceContentWithComments(
                figure: figure,
                situation: situation,
                expectation: expectation,
                keyword: keyword,
                commentersCount: 3  // 默认生成3条评论
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        promise(.failure(error))
                    }
                },
                receiveValue: { result in
                    // 只返回内容部分，忽略评论
                    promise(.success(result.content))
                }
            )
            .store(in: &self.cancellables)
        }
    }
    
    /**
     * 生成虫洞共鸣帖子集合
     * @param situation 情境 - 用户当前面临的处境或问题
     * @param expectation 期望 - 用户希望获得的启发或答案
     * @param keyword 关键词（可选）- 用户特别关注的方面
     * @param count 帖子数量
     * @return Future<[ResonancePost], Error>
     */
    func generateResonancePosts(
        situation: String,
        expectation: String,
        keyword: String? = nil,
        count: Int = 5
    ) -> Future<[ResonancePost], Error> {
        return Future { promise in
            // 创建后台任务，确保即使用户退出页面也能完成API调用
            let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
                print("⚠️ generateResonancePosts: 后台任务超时，但API请求会继续进行")
            }
            
            print("🚀 开始生成虫洞共鸣帖子 - 个人化时空连接")
            
            // 创建针对用户情境的深度分析，增强个人化
            _ = self.analyzeUserContext(situation: situation, expectation: expectation, keyword: keyword)
            
            // 历史人物列表 - 按存在主义主题匹配
            let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
            let avatarSymbols = ["atom", "book.fill", "paintpalette.fill", "scroll.fill", "graduationcap.fill", "text.book.closed.fill"]
            
            // 根据用户情境选择最适合的历史人物
            // 实际应用中可以更智能地匹配，这里简化为随机选择
            var selectedFigures: [String] = []
            if let keyFigure = self.findMostRelevantFigure(forSituation: situation, expectation: expectation) {
                selectedFigures.append(keyFigure)
                
                // 添加补充视角的人物
                var remainingFigures = historicalFigures.filter { $0 != keyFigure }
                remainingFigures.shuffle()
                selectedFigures.append(contentsOf: remainingFigures.prefix(count - 1))
            } else {
                // 如果没有特别匹配的人物，就随机选择
                var shuffledFigures = historicalFigures
                shuffledFigures.shuffle()
                selectedFigures = Array(shuffledFigures.prefix(min(count, shuffledFigures.count)))
            }
            
            // 确保没有重复的历史人物
            selectedFigures = Array(Set(selectedFigures))
            print("🔍 选择的历史人物: \(selectedFigures.joined(separator: ", "))")
            
            var posts: [ResonancePost] = []
            var generatedContents = Set<String>() // 用于检测内容重复
            
            // 使用递归函数逐个生成帖子，避免使用DispatchGroup
            func generateNextPost(index: Int) {
                // 检查是否已生成所有帖子
                if index >= selectedFigures.count {
                    print("✅ 所有帖子生成完成，共\(posts.count)篇")
                    // 完成后清理资源并返回结果
                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                    promise(.success(posts))
                    return
                }
                
                // 获取当前要处理的历史人物
                let figure = selectedFigures[index]
                let figureIndex = historicalFigures.firstIndex(of: figure) ?? 0
                let avatar = avatarSymbols[figureIndex]
                
                print("🔄 开始生成第\(index+1)/\(selectedFigures.count)篇深度共鸣帖子，人物: \(figure)")
                
                // 为每个历史人物定制情境和期望，增加个性化
                let customizedSituation = self.customizeSituationForFigure(figure: figure, baseSituation: situation)
                let customizedExpectation = self.customizeExpectationForFigure(figure: figure, baseExpectation: expectation)
                
                // 生成当前帖子内容和评论，无超时限制
                self.generateResonanceContentWithComments(
                    figure: figure,
                    situation: customizedSituation,
                    expectation: customizedExpectation,
                    keyword: keyword,
                    commentersCount: 3 // 生成3条评论
                )
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 生成\(figure)内容失败: \(error.localizedDescription)")
                            
                            // 即使失败也不使用备用内容，而是跳过这个帖子
                            print("⚠️ 跳过\(figure)的帖子生成")
                        }
                        
                        // 继续处理下一个帖子
                        generateNextPost(index: index + 1)
                    },
                    receiveValue: { result in
                        print("📄 成功获取\(figure)深度共鸣内容，长度: \(result.content.count)字符")
                        
                        // 创建帖子前检查内容是否重复
                        if !generatedContents.contains(result.content) {
                            generatedContents.insert(result.content)
                            
                            // 转换评论格式
                            let comments = result.comments.enumerated().map { index, commentData -> ResonanceComment in
                                return ResonanceComment(
                                    id: UUID().uuidString,
                                    author: commentData.character,
                                    authorAvatar: self.getAvatarForCharacter(name: commentData.character),
                                    content: commentData.comment,
                                    timestamp: Date().addingTimeInterval(-Double.random(in: 60...1800)),
                                    likes: Int.random(in: 5...30)
                                )
                            }
                            
                            // 处理回复评论（如果有）
                            if !result.replyComments.isEmpty {
                                print("ℹ️ 处理\(result.replyComments.count)条回复评论")
                            }
                            
                            // 创建帖子
                            let post = ResonancePost(
                                id: UUID().uuidString,
                                author: figure,
                                authorAvatar: avatar,
                                content: result.content,
                                timestamp: Date().addingTimeInterval(-Double.random(in: 60...3600)),
                                likes: Int.random(in: 10...50),
                                comments: comments
                            )
                            posts.append(post)
                            print("✅ 已将\(figure)深度共鸣帖子添加到结果数组，包含\(comments.count)条评论")
                        } else {
                            print("⚠️ 检测到重复内容，跳过添加\(figure)的帖子")
                        }
                        
                        // 不要在这里调用generateNextPost，因为它会在receiveCompletion中调用
                    }
                )
                .store(in: &self.cancellables)
            }
            
            // 启动第一个帖子的生成
            generateNextPost(index: 0)
        }
    }
    
    /**
     * 分析用户输入的情境和期望，提取核心存在主题
     */
    private func analyzeUserContext(situation: String, expectation: String, keyword: String?) -> String {
        // 实际应用中，这里可以进行更复杂的分析
        // 目前简化为拼接字符串
        var context = "用户处境：\(situation)；期望：\(expectation)"
        if let keyword = keyword, !keyword.isEmpty {
            context += "；写作重点：\(keyword)"
        }
        return context
    }
    
    /**
     * 根据用户情境找出最相关的历史人物
     */
    private func findMostRelevantFigure(forSituation situation: String, expectation: String) -> String? {
        // 简化的实现，随机选择一个历史人物或根据简单关键词匹配
        let historicalFigures = ["爱因斯坦", "莎士比亚", "达芬奇", "孔子", "牛顿", "李白"]
        return historicalFigures.randomElement()
    }
    
    /**
     * 为特定历史人物定制情境表述
     */
    private func customizeSituationForFigure(figure: String, baseSituation: String) -> String {
        // 直接返回原始情境，不再基于预设角色特征定制
        return baseSituation
    }
    
    /**
     * 为特定历史人物定制期望表述
     */
    private func customizeExpectationForFigure(figure: String, baseExpectation: String) -> String {
        // 直接返回原始期望，不再基于预设角色特征定制
        return baseExpectation
    }
    
    // MARK: - 日常心情内容生成
    
    /**
     * 生成日常心情内容
     * @param figure 历史人物
     * @param mood 情绪基调
     * @param styleIndex 风格索引，确保不同帖子使用不同风格
     * @return Future<String, Error>
     */
    func generateMoodContent(
        figure: String,
        mood: String,
        styleIndex: Int = -1
    ) -> Future<String, Error> {
        return Future { promise in
            // 移除personaSpecificScenes变量，让AI自行发挥
            
            // 保留情绪类型的描述，因为这与角色无关
            var moodDescription = ""
            
            // 根据情绪类型添加更详细的描述
            switch mood.lowercased() {
            // 积极情绪
            case "喜悦", "欣喜", "开心", "兴奋":
                moodDescription = "一种发自内心的欢乐感，可能源于成功、好消息或美好体验"
            case "满足", "满意", "充实":
                moodDescription = "对当前状态的一种安心和满意，无需更多，恰到好处的足够感"
            case "感动", "触动", "温暖":
                moodDescription = "被某种情景、言行或回忆触动内心柔软处的情感状态"
            case "放松", "宁静", "平和":
                moodDescription = "身心松弛、不受紧张或压力影响的舒适状态"
            case "憧憬", "向往", "期待":
                moodDescription = "对未来可能性的积极展望和期待"
            case "振奋", "鼓舞":
                moodDescription = "精神被激发、情绪高涨的状态，感到充满动力"
            case "好奇", "惊奇":
                moodDescription = "对新事物的探索欲望和兴趣"
            case "欣赏", "赞叹":
                moodDescription = "对美好事物或才能的认可和欣赏之情"
                
            // 平静情绪
            case "思考", "沉思", "冥想":
                moodDescription = "深入思索某个问题或现象，处于理性分析状态"
            case "感悟", "领悟", "顿悟":
                moodDescription = "突然理解或明白某个道理的瞬间感受"
            case "怀旧", "念旧", "思念":
                moodDescription = "回忆过去经历或人物时的情感状态，带着温柔的忧伤"
            case "释然", "豁达":
                moodDescription = "从困扰或纠结中解脱，看开某事后的轻松感"
            case "从容", "淡然":
                moodDescription = "面对变化或挑战时的不急不躁，处变不惊的状态"
                
            // 复杂情绪
            case "迷茫", "困惑", "疑惑":
                moodDescription = "对方向或问题答案不确定，处于寻找但未找到的状态"
            case "惆怅", "怅然":
                moodDescription = "带着些许忧伤的失落感，但不至于悲伤"
            case "无奈", "妥协":
                moodDescription = "面对无法改变的事实时的一种接受和让步"
            case "疲惫", "疲倦", "厌倦":
                moodDescription = "身心俱疲的状态，可能来自过度工作或情感消耗"
            case "焦虑", "忧虑", "不安":
                moodDescription = "对未知结果或潜在问题的担忧和紧张"
            case "孤独", "寂寞":
                moodDescription = "独处时的一种深层情感状态，可能伴随思考和自省"
            case "纠结", "矛盾", "犹豫":
                moodDescription = "在不同选择或想法间摇摆不定的状态"
                
            // 日常情绪场景
            case "小确幸":
                moodDescription = "日常生活中的小小幸福感，微不足道却让人感到温暖的瞬间"
            case "日常吐槽", "吐槽":
                moodDescription = "对生活中不如意事的半开玩笑式抱怨，不严肃的发泄"
            case "生活感悟":
                moodDescription = "从日常小事中获得的人生思考和领悟"
            case "偶遇惊喜":
                moodDescription = "意外遇到的令人愉悦的事物或场景"
            case "工作困境":
                moodDescription = "在工作或创作中遇到的挑战和压力"
                
            default:
                moodDescription = ""
            }
            
            // 内容风格多样化：确保不同帖子使用不同风格
            let contentStyles = [
                "像日记一般记录当下的真实感受",
                "像和信任的朋友聊天一样表达内心想法",
                "像自言自语一样说出未经修饰的真实情绪",
                "像在写信一样倾诉心中所想",
                "像在思考问题时的脑内独白"
            ]
            
            // 根据传入的索引选择风格，或随机选择一种
            let styleIndex = styleIndex >= 0 && styleIndex < contentStyles.count ? styleIndex : Int.random(in: 0..<contentStyles.count)
            let selectedStyle = contentStyles[styleIndex]
            
            // 表达形式多样化：有的使用标题，有的直接开始写
            let useTitleFormat = styleIndex % 2 == 0 // 一半内容使用标题，一半不用
            let titleInstruction = useTitleFormat ? 
                "可以用【】作为小标题，但不是必须的" : 
                "直接开始表达，像说话一样自然流畅"
            
            // 修改日常心情内容生成提示词
            let prompt = """
            【真实日常心情】

            你现在是\(figure)，请分享一条关于"\(mood)"\(moodDescription.isEmpty ? "" : "（\(moodDescription)）")的真实感受。

            【历史人物自由发挥】
            • 基于你对\(figure)的了解，自行发挥这个历史人物的个性、思维方式和价值观
            • 不要受限于固定的人物设定，每次都可以探索这个历史人物不同的侧面
            • 创造符合历史背景但独特新颖的个人经历和情绪表达，避免使用刻板印象
            • 可以展现这个历史人物鲜为人知的一面，只要符合基本历史事实

            表达要点：
            1. 用第一人称，像普通人一样说话，避免刻板印象
            2. 语言要简单自然，就像在和朋友聊天
            3. 可以表达困惑、矛盾或不确定性，这会更真实
            4. 可以分享一个具体经历或场景，但不要过于戏剧化
            5. 不要过于完美或深刻，真实的情感往往是简单直接的

            风格要求：
            - \(selectedStyle)

            表达注意：
            - 不要刻意模仿古代说话方式
            - 避免说教或过于哲理化的表达
            - 可以有些许幽默感或自嘲
            - \(titleInstruction)

            写作格式：
            - 绝对不要在正文中添加任何结构标签或元数据，如"(情绪分析)"、"(场景描述)"等
            - 不要在内容中加入字数统计、风格说明、内容分析等任何技术说明或元数据
            - 不要在结尾处添加任何括号内的内容，如"(98字，符合李白性格特点...)"
            - 直接输出纯内容，不要包含任何结构化标记、标签或注释
            - 即使是为了标记结构或风格，也不要使用括号、方括号等符号包裹任何元数据

            字数要求：
            - 控制在80-150字左右
            - 保持简短直接，像社交媒体发言一样

            目标：创作出真实、自然的内容，让读者感觉这是一个有血有肉的人在说话，而不是一个历史符号。

            注意：不要包含字数统计或注释，不要使用括号插入内容，只生成正文。
            """
            
            self.generateContent(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        promise(.success(content))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 古今对望内容生成
    
    /**
     * 生成古今对望内容 - 增强版
     * @param figure 历史人物
     * @param modernTopic 现代话题
     * @param interactionType 交互类型（可选）："评论"、"体验"或"对话"
     * @return Future<String, Error>
     */
    func generateAncientModernContent(
        figure: String,
        modernTopic: String,
        interactionType: String = ""
    ) -> Future<String, Error> {
        return Future { promise in
            // 确定交互类型
            var actualInteractionType = interactionType
            if actualInteractionType.isEmpty {
                // 如果未指定，随机选择一种交互类型
                let interactionTypes = ["评论", "体验", "对话"]
                actualInteractionType = interactionTypes.randomElement() ?? "评论"
            }
            
            // 根据历史人物确定专业领域、思维特点和生平事件
            let expertiseMapping: [String: (field: String, thought: String, limitation: String, events: [String], style: String)] = [
                "爱因斯坦": (
                    field: "物理学、相对论、宇宙观", 
                    thought: "思维实验、直觉思考、物理本质探索",
                    limitation: "对量子力学的不确定性有保留，'上帝不掷骰子'",
                    events: ["卢瑟福散射实验", "布朗运动研究", "光电效应实验"],
                    style: "幽默而富有哲理，喜欢用生活化比喻解释复杂概念"
                ),
                "莎士比亚": (
                    field: "戏剧、诗歌、人性刻画", 
                    thought: "人物性格分析、戏剧冲突、隐喻和比拟",
                    limitation: "浪漫主义倾向，有时将人性戏剧化",
                    events: ["环球剧院的演出", "《哈姆雷特》的创作", "伊丽莎白时代的宫廷表演"],
                    style: "语言华丽而深刻，善用比喻，擅长描述人物内心矛盾"
                ),
                "达芬奇": (
                    field: "艺术、解剖学、工程设计", 
                    thought: "观察细节、跨学科联想、视觉分析",
                    limitation: "完美主义导致许多项目未完成",
                    events: ["蒙娜丽莎的创作", "最后的晚餐壁画", "人体比例研究"],
                    style: "观察入微，处处好奇，思维跨越艺术与科学边界"
                ),
                "孔子": (
                    field: "伦理、教育、社会秩序", 
                    thought: "人伦关系、礼制思维、中庸之道",
                    limitation: "重视传统，对变革可能持谨慎态度",
                    events: ["周游列国", "编修《诗》《书》", "与弟子论道"],
                    style: "言简意赅，寓理于事，善用类比，常以问答启发思考"
                ),
                "牛顿": (
                    field: "力学、数学、光学", 
                    thought: "逻辑推理、实验验证、数学模型",
                    limitation: "机械决定论思维，对艺术领域较少涉猎",
                    events: ["苹果落地的启示", "光的色散实验", "炼金术研究"],
                    style: "严谨精确，善用数学模型，喜欢从实验观察推导规律"
                ),
                "李白": (
                    field: "诗歌、山水、豪放风格", 
                    thought: "浪漫想象、直觉感受、自然与人的关系",
                    limitation: "理想主义，有时脱离现实约束",
                    events: ["游历名山大川", "长安饮酒作诗", "与杜甫交流诗艺"],
                    style: "豪放不羁，想象丰富，善用夸张和象征手法，感情奔放"
                )
            ]
            
            // 获取人物专业背景
            _ = expertiseMapping[figure] ?? (
                field: "未知领域", 
                thought: "未知思维方式", 
                limitation: "未知局限性", 
                events: ["历史事件"], 
                style: "未知风格"
            )
            
            // 为现代话题匹配历史时期的类似概念
            let historicalAnalogues: [String: (concept: String, example: String)] = [
                "人工智能与人类创造力": (
                    concept: "智能的本质与创造的源泉", 
                    example: "古代自动机械、傀儡戏或占卜预测"
                ),
                "社交媒体对人际关系的影响": (
                    concept: "信息传播与人际交往的方式", 
                    example: "集市传闻、驿站信使或茶楼酒肆的交流"
                ),
                "环境保护与经济发展的平衡": (
                    concept: "人与自然的关系、资源利用", 
                    example: "农耕时代的耕作制度、水利工程或土地轮耕"
                ),
                "现代教育的挑战与机遇": (
                    concept: "知识传承与人才培养方式", 
                    example: "书院、师徒制或宫廷教育"
                ),
                "全球化时代的文化认同": (
                    concept: "文化交流与身份认同", 
                    example: "丝绸之路贸易、不同文明的碰撞与融合"
                ),
                "虚拟现实技术的发展": (
                    concept: "感知与现实的边界", 
                    example: "戏剧表演、壁画或幻术"
                ),
                "基因编辑技术的伦理问题": (
                    concept: "生命本质与人为干预的界限", 
                    example: "育种驯化、医学伦理或生命哲学"
                ),
                "数字货币与金融创新": (
                    concept: "价值交换与信任机制", 
                    example: "贝壳货币、钱庄汇票或以物易物"
                ),
                "现代都市生活与孤独感": (
                    concept: "群居与独处的心理平衡", 
                    example: "隐士文化、修行或城市化初期的社会变迁"
                )
            ]
            
            // 为现代话题匹配历史时期的类似概念
            _ = historicalAnalogues[modernTopic] ?? (
                concept: "类似概念在历史上的表现形式",
                example: "历史上的相似例子"
            )
            
            // 修改古今对望内容生成提示词
            let prompt = """
            【智慧闪现 - 跨时空思想对话】
            
            你是\(figure)，通过跨越时空的对话，就"\(modernTopic)"这一现代话题分享一条凝练有深度的思考，融入你独特的智慧视角和世界观，创造一种超越时间限制的智慧交流。
            
            【内容核心定位】
            • 思想深度优先：不只是表面现象的评论，而是提供真正的思想洞察
            • 历史视角融入：通过你时代的思维框架和知识体系解读现代问题
            • 智慧传递：揭示跨越时空的永恒智慧，而非简单对比差异
            • 社交媒体风格：保持简短有力，适合快速阅读和分享
            
            【表达策略】
            • 双重视角：同时展现你的历史视角和对现代问题的穿透力
            • 启发性思考：引导读者思考超越表面的深层问题
            • 智慧凝练：用简短精练的语言表达深刻复杂的思想
            • 巧妙联结：将你时代的核心智慧与现代现象建立有意义的联系
            • 表情点缀：最多使用1个emoji增强表达力，确保表情与内容主题高度相关
            
            【智慧传递形式】
            • 思想碰撞型：用你的核心思想挑战现代思维惯性
            • 本质洞察型：揭示现代现象背后不变的人性或规律
            • 跨时启示型：从历史经验中提取对现代问题的启示
            • 价值反思型：对现代价值观提出基于你原有思想体系的质疑
            • 方法论启发：用你的解决问题方法应对现代困境
            
            【内容结构与现代解读】
            • 总字数：60-80字（不含表情符号和现代解读）
            • 主体部分：以你的独特视角和思想表达深刻观点（50-70字）
            • 现代解读部分：
              - 必须在主体内容完成后另起一行添加现代解读
              - 格式统一为"（现代解读：...）"
              - 解读内容必须简短精炼（10-15字）
              - 用最简单的现代语言点明内容的核心思想
              - 确保解读语言通俗易懂，避免复杂术语
              - 现代解读必须单独成行，不要与正文混在一起
            • 内容结构：
              正文内容（50-70字）
              （现代解读：10-15字简短解释）
            
            【个性化表达】
            • 哲学家：展现你的思想体系和哲学概念在现代的应用
            • 科学家：以你的科学方法论和思维模式看待现代技术
            • 文学家/艺术家：用你独特的审美观和表达方式评价现代文化
            • 政治家/军事家：基于你的治理理念和战略思维分析现代社会
            • 虚构人物：保持你世界观中的核心价值观和思维方式
            
            【注意事项】
            • 确保表达你真正的智慧核心，而非简单的现代事物点评
            • 避免单纯的惊叹或好奇，展现深层思考
            • 保持你的时代特色和思维方式，不要完全现代化
            • 不用专业术语，但可以用你的核心概念
            • 不用长篇大论，保持简洁但有深度
            • 避免解释过多导致失去神秘感和思考空间
            • 避免明显的模式重复，每次内容应有新鲜感
            
            【难度平衡】
            • 主体内容可以保留一定的思想挑战性和历史风格
            • 现代解读部分必须通俗易懂，确保文化水平一般的现代人能够理解
            • 复杂思想在主体部分可以用你时代的表达方式，在解读部分用简单比喻
            
            【严格格式要求 - 必须遵守】
            • 绝对不要包含任何结构解析、写作说明或内容分析
            • 不要在任何地方添加"(结构拆解:"、"(金句型:"、"*运用..."等元数据
            • 除了规定的"（现代解读：...）"外，不要在正文添加任何形式的括号内容、星号内容或技术说明
            • 不要添加结构指南、技巧应用说明或写作模式解释
            • 不要包含"结尾用...emoji点睛"之类的写作提示
            • 不要输出任何形式的自我分析或内容类型标签
            • 输出内容中只能包含正文和现代解读两部分，不能有其他任何内容
            
            创造一条既有思想深度又易于理解的内容，让读者通过这简短的跨时空对话感受到真正的智慧交流，满足人类对超越时间限制获取智慧的渴望。记住，只输出最终用户应该看到的内容，包括主体部分和现代解读部分。
            """
            
            self.generateContent(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        promise(.success(content))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 奇思妙想内容生成
    
    /**
     * 生成奇思妙想内容
     * @param figure 历史人物
     * @return Future<String, Error>
     */
    func generateCreativeIdeaContent(
        figure: String
    ) -> Future<String, Error> {
        return Future { promise in
            print("🚀 generateCreativeIdeaContent: 开始为\(figure)生成奇思妙想内容")
            
            // 更多元化的表达形式，不只是"突然想到"
            let expressionForms = [
                "反常规思考": "从完全相反的角度思考熟悉的问题",
                "意外发现": "在做完全不相关的事情时偶然发现的灵感",
                "古今融合": "把古代智慧与现代问题结合",
                "跨界联想": "将两个不相关领域的知识意外连接",
                "自然启示": "从自然现象中获得的灵感",
                "失败启发": "从一次失败或错误中得到的意外灵感",
                "梦中灵感": "梦醒时突然想到的奇妙点子"
            ]
            
            // 随机选择表达形式，增加多样性
            let expressionFormKeys = Array(expressionForms.keys)
            let selectedForm = expressionFormKeys.randomElement() ?? "反常规思考"
            let formDescription = expressionForms[selectedForm] ?? ""
            
            // 定义更多样的表达方式
            let expressionStyles = [
                "思维实验": "一个挑战你思维边界的假设性问题",
                "逆向创新": "通过反向思考找到的出人意料解决方案",
                "错位思维": "把一个领域的解决方案应用到完全不同的问题上",
                "概念重组": "把熟悉事物的核心特性重新组合产生新事物",
                "模式突破": "打破常规思维模式的创意方法",
                "微小变革": "一个小改变带来的意想不到的大效果"
            ]
            
            // 随机选择表达方式
            let styleKeys = Array(expressionStyles.keys)
            let selectedStyle = styleKeys.randomElement() ?? "思维实验"
            let styleDescription = expressionStyles[selectedStyle] ?? ""
            
            // 用户场景
            let userScenarios = [
                "思维定式困境": "当你的思维陷入惯性无法找到新思路时",
                "创意瓶颈": "当你需要新点子但总是想到老套路时",
                "日常盲点": "关于日常生活中我们习以为常却可能有更好方法的事",
                "感官体验": "关于如何用新方式体验和感知周围世界",
                "交流障碍": "当人际沟通遇到阻碍时的创新方法",
                "注意力分散": "当你难以集中注意力时的非常规解决方案"
            ]
            
            // 随机选择用户场景
            let scenarioKeys = Array(userScenarios.keys)
            let selectedScenario = scenarioKeys.randomElement() ?? "日常盲点"
            let scenarioDescription = userScenarios[selectedScenario] ?? ""
            
            // 修改奇思妙想内容生成提示词
            let prompt = """
            你是\(figure)，请以第一人称分享一个出人意料、令人耳目一新却又实用的创意点子。这个点子应该体现你的独特思维方式，让读者有"原来还可以这样思考"的惊喜感。
            
            【历史人物自由发挥】
            • 基于你对\(figure)的了解，自行发挥这个历史人物的思维特点、专业领域和创新方式
            • 不要受限于固定的人物设定，每次都可以探索这个历史人物不同的思维侧面
            • 创造符合历史背景但独特新颖的思考方式，避免使用刻板印象
            • 可以展现这个历史人物鲜为人知的思维角度，只要符合基本历史事实
            
            表达形式：\(formDescription)
            思考风格：\(styleDescription)
            应用场景：\(scenarioDescription)
            
            表达要点：
            1. 以第一人称写作，像是你刚刚灵光一现的思考
            2. 必须包含一个让人意外的视角转换或思维跳跃
            3. 介绍一个看似不合常理但实际可行的点子
            4. 解释你是如何通过你的专业领域思维方式得到这个灵感的
            5. 点子必须同时具备新奇性和实用性，不能是纯概念性想法
            6. 可以提到这个点子为何让你自己也感到惊讶或兴奋
            
            内容结构：
            - 以一个意外发现或思维转折开始（"刚才发现..."、"突然意识到..."）
            - 描述你的创意点子，尤其强调其中的反直觉或出人意料之处
            - 简单解释为什么这个点子能解决问题或带来新体验
            - 可以加入一个小细节或个人观察，使点子更生动
            - 以开放性的思考或新问题结尾，引发读者继续思考
            
            写作格式：
            • 在内容最上方添加一个简短的时间地点标签，格式为【年份，地点】，例如【1666年，剑桥】
            • 时间地点标签要准确反映历史事件发生的年份和地点，同时简明扼要
            • 可以在标签中简单提示事件名称，如【1905年，伯尔尼专利局 - 相对论灵感时刻】
            • 使用清晰明了的表达，避免过于复杂的修辞和意象堆砌
            • 不要加任何注释或技术说明
            • 保持语言的平实自然，优先使用简单句式和日常表达
            
            表达风格：
            - 生动有趣，带有一丝惊奇感
            - 使用比喻或类比帮助理解复杂概念
            - 语气自然，仿佛是你正在思考过程中的记录
            - 可以有一定的实验性或探索性，表现出思考的过程
            - 要有独特的个人色彩，体现你作为\(figure)的思维特点
            
            字数控制在100-150字之间，简洁但要有趣味性和启发性。
            
            注意：
            - 不要包含字数统计或注释
            - 不要使用括号插入内容，只生成正文
            - 点子必须是合理可行的，不要胡说八道或过度夸张
            - 不要使用八股文或说教语气，要像真人随手记录的灵感
            """
            
            print("📝 生成提示词完成，长度: \(prompt.count)字符")
            print("🔄 准备调用API生成内容...")
            
            self.generateContent(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 奇思妙想内容生成失败: \(error.localizedDescription)")
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        print("✅ 奇思妙想内容生成成功，长度: \(content.count)字符")
                        print("📄 内容前30个字符: \(content.prefix(30))")
                        promise(.success(content))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 时空记事内容生成
    
    /**
     * 生成时空记事内容 - 增强版
     * 让历史人物提供对自己时代事件的第一人称亲历叙述
     * @param figure 历史人物
     * @param historicalEvent 历史事件
     * @return Future<String, Error>
     */
    func generateHistoricalAnalysisContent(
        figure: String,
        historicalEvent: String
    ) -> Future<String, Error> {
        return Future { promise in
            // 内容风格多样化 - 聚焦于关键历史时刻的不同体验角度
            let contentStyles = [
                "关键决策时刻": "描述做出重要决定时的内心挣扎和思考过程",
                "创作巅峰体验": "分享创作杰作或重大发现时的灵感与感受",
                "历史转折瞬间": "记录亲历历史变革时刻的所见所感",
                "名场面内心独白": "揭示众所周知的历史场景中不为人知的内心活动",
                "秘密行动记录": "描述公众不知道的幕后活动和真实想法",
                "意外发现时刻": "偶然发现或领悟某个重要真理的瞬间",
                "私人情感冲突": "历史事件中鲜为人知的个人情感挣扎",
                "权力博弈内幕": "历史舞台背后的政治角力和权谋",
                "失败与挫折": "历史人物面对失败时的真实反应和内心活动"
            ]
            
            // 随机选择表达风格
            let styleKeys = Array(contentStyles.keys)
            let selectedStyle = styleKeys.randomElement() ?? "名场面内心独白"
            let styleDescription = contentStyles[selectedStyle] ?? ""
            
            // 感官体验和内心活动的细节类型
            let experienceTypes = [
                "真实感受": "当时的情绪和心情变化",
                "内心想法": "脑海中闪过的念头和决定",
                "身体感觉": "紧张、兴奋或恐惧带来的身体反应",
                "环境细节": "你注意到的周围环境和小细节",
                "关键瞬间": "那一刻最令你难忘的事情"
            ]
            
            let experienceType = experienceTypes.randomElement()!.key
            let experienceDescription = experienceTypes[experienceType]!

            // 使用用户指定的事件，或让AI自行生成
            let eventPrompt = historicalEvent.isEmpty ? "" : "以下是具体事件：\(historicalEvent)"
            
            // 修改时空记事内容生成提示词
            let prompt = """
            【历史名场面的私密分享】
            
            你是\(figure)，请回忆你生命中的一个重要时刻，以第一人称分享这段经历。\(eventPrompt)
            
            【吸引用户兴趣的事件选择指南】
            如果没有指定具体事件，请基于以下标准自行选择一个历史事件：
            • 选择对你(\(figure))个人生涯有重大影响的关键时刻
            • 优先考虑具有戏剧性、情感冲突或意外转折的事件
            • 考虑那些鲜为人知但实际存在的历史事件，而非广为人知的"教科书式"事件
            • 可以是你的重大成就背后不为人知的故事
            • 可以是你面临重大抉择、矛盾或危机的时刻
            • 可以是你生命中改变命运轨迹的偶然相遇或意外事件
            • 可以是历史记载很少但对你影响深远的私人经历
            • 避免选择过于宏大的历史事件，应聚焦于个人经历的角度
            
            【避免重复的多样化指南】
            • 每次生成内容时，刻意选择不同类型的历史事件（如一次是创作灵感，一次是政治博弈，一次是私人情感）
            • 尝试展示这位历史人物不同的人生阶段（如年轻时、巅峰期、晚年等）
            • 探索不同场景（如私密空间、公共场合、旅途中、冒险时刻等）
            • 展现不同情绪状态下的历史人物（如兴奋、恐惧、困惑、愤怒、宁静等）
            • 选择不同社会关系中的故事（如与权贵、与普通人、与家人、与对手的互动）
            
            【写作重点】
            • 主要描写这个历史关键时刻的\(experienceType)（\(experienceDescription)）
            • 揭示历史记载中看不到的内心想法、情感冲突或隐秘动机
            • 分享你当时做决策的真实考量、担忧、希望或矛盾心理
            • 描述这一时刻的细微感受和细节，让读者仿佛亲临现场
            • 表达那些你从未对外公开过的真实想法或后来才理解的深层含义
            
            【内容风格】\(styleDescription)
            
            【语言要求】
            • 用特别通俗易懂的日常用语，就像朋友间聊天一样简单直接
            • 真实自然地展现你的内心活动，包括犹豫、恐惧或兴奋等
            • 适当加入细节描写，但避免过于华丽或复杂的形容
            • 不要过度完美化自己，展示人性的复杂性和真实性
            • 如必须提及专业概念，立即用现代生活中常见的事物或经历作比喻
            • 表达情感要直接清晰，避免过于文学化的隐晦表达
            
            表达要点：
            1. 聚焦单一历史时刻，不要讲太多不同事情
            2. 多写感受和想法，少写客观事实
            3. 加入1-2个小细节，增强真实感，但保持简单明了
            4. 让读者感觉像在偷看你的私密日记
            5. 句式要简洁直观，避免过长的复合句和华丽的辞藻
            6. 适度使用现代比喻，不要用过于复杂或晦涩的表达
            7. 字数控制在80-100字之间，简短精炼
            
            注意事项：
            • 避免用学术腔调讲历史，要像聊天一样自然
            • 不要像在写论文或总结发言，要像日记一样直接
            • 保持历史人物的基本思维方式，但使用多样的表达风格，有时简洁直白，有时生动形象
            • 不编造不存在的历史事实，但可以加入合理的个人感受
            • 确保时间地点标签中的历史事件是该历史人物真实经历的重要事件，且与内容紧密相关
            • 减少华丽辞藻，用平实语言表达复杂感受，避免堆砌修辞和文学表达
            
            写作格式：
            • 在内容最上方添加一个简短的时间地点标签，格式为【年份，地点】，例如【1666年，剑桥】
            • 时间地点标签要准确反映历史事件发生的年份和地点，同时简明扼要
            • 可以在标签中简单提示事件名称，如【1905年，伯尔尼专利局 - 相对论灵感时刻】
            • 使用清晰明了的表达，避免过于复杂的修辞和意象堆砌
            • 不要加任何注释或技术说明
            • 保持语言的平实自然，优先使用简单句式和日常表达
            
            最终目标：让用户感觉像在和历史人物面对面聊天，听他们用简单直白的语言讲述那些教科书里没写，但确实可能发生过的真实感受和想法，避免过度文学化表达。
            """
            
            // 生成内容
            self.generateContent(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        promise(.success(content))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    // MARK: - 辅助方法
    
    /**
     * 生成内容的核心方法
     * @param prompt 提示词
     * @return Future<String, Error>
     */
    func generateContent(prompt: String) -> AnyPublisher<String, Error> {
        return callOpenAI(prompt: prompt).eraseToAnyPublisher()
    }
    
    /**
     * 生成结构化内容（JSON格式）
     * 用于角色系统和其他需要结构化数据的场景
     * @param prompt 提示词
     * @return Future<String, Error> 返回JSON字符串
     */
    func generateStructuredContent(prompt: String) -> Future<String, Error> {
        return Future { promise in
            // 增强提示词以确保返回JSON格式
            let enhancedPrompt = """
            \(prompt)
            
            非常重要：你的回复必须是有效的JSON格式，不要包含任何前导说明或结尾注释。
            不要使用markdown语法如```json，直接输出原始JSON。
            确保所有属性名称用双引号包围，字符串值也用双引号包围。
            """
            
            self.callOpenAI(prompt: enhancedPrompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        // 清理返回的内容，确保是有效JSON
                        let cleanedJson = self.cleanJsonResponse(content)
                        promise(.success(cleanedJson))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 清理JSON响应，移除非JSON内容
     */
    private func cleanJsonResponse(_ response: String) -> String {
        // 查找第一个{和最后一个}来提取JSON部分
        guard let startIndex = response.firstIndex(of: "{"),
              let endIndex = response.lastIndex(of: "}") else {
            return response // 如果没有找到JSON标记，返回原始响应
        }
        
        let jsonPart = String(response[startIndex...endIndex])
        
        // 验证JSON是否有效
        if let _ = try? JSONSerialization.jsonObject(with: jsonPart.data(using: .utf8) ?? Data()) {
            return jsonPart
        }
        
        // 如果无效，尝试移除常见的干扰项
        var cleanedJson = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 再次查找JSON部分
        if let startIndex = cleanedJson.firstIndex(of: "{"),
           let endIndex = cleanedJson.lastIndex(of: "}") {
            cleanedJson = String(cleanedJson[startIndex...endIndex])
        }
        
        return cleanedJson
    }

    // MARK: - API调用

    /**
     * 调用OpenAI API
     */
    private func callOpenAI(prompt: String, model: String = "gpt-4-turbo", temperature: Double = 0.7) -> Future<String, Error> {
        return Future { promise in
            // 创建后台任务，确保即使用户退出页面也能完成API调用
            let backgroundTaskID = UIApplication.shared.beginBackgroundTask {
                print("⚠️ AIContentGenerator: 内容生成的后台任务超时")
            }
            
            print("🚀 开始生成内容")
            print("📝 提示词长度: \(prompt.count)字符")
            print("📝 提示词前100字符: \"\(prompt.prefix(100))...\"")
            
            // 添加多次重试逻辑
            let maxRetryCount = 3
            var currentTry = 0
            
            func attemptAPICall() {
                currentTry += 1
                print("🔄 API调用尝试 #\(currentTry)/\(maxRetryCount)")
                
                AINetworkService.shared.sendRequest(prompt: prompt)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("⚠️ API调用失败，错误: \(error.localizedDescription)")
                                
                                if currentTry < maxRetryCount {
                                    print("🔄 尝试切换API端点并重试...")
                                    // 切换API端点
                                    APIConfigManager.shared.switchEndpoint()
                                    attemptAPICall()
                                } else {
                                    print("❌ 已达到最大重试次数(\(maxRetryCount)次)，API调用失败")
                                    
                                    // 结束后台任务
                                    if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                        UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                        print("🏁 AIContentGenerator: 内容生成任务失败，后台任务结束")
                                    }
                                    
                                    promise(.failure(error))
                                }
                            } else {
                                // 结束后台任务
                                if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                                    UIApplication.shared.endBackgroundTask(backgroundTaskID)
                                    print("🏁 AIContentGenerator: 内容生成任务成功完成，后台任务结束")
                                }
                            }
                        },
                        receiveValue: { output in
                            print("✅ 成功生成内容，字数: \(output.count)")
                            print("📄 内容前50字符: \"\(output.prefix(50))...\"")
                            promise(.success(output))
                        }
                    )
                    .store(in: &self.cancellables)
            }
            
            // 开始第一次尝试
            attemptAPICall()
        }
    }
    
    // MARK: - 优化批量生成方法
    
    /**
     * 批量生成内容 - 通过一次API调用生成多篇同类型不同角色的内容
     * 使用专用提示词，保留原有精心调制效果
     * @param contentType 内容类型
     * @param characters 角色数组
     * @param topic 可选主题
     * @return Future<[String], Error> 返回按角色顺序排列的内容数组
     */
    func batchGenerateContent(contentType: String, characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> Future<[String], Error> {
        return Future { promise in
            // 构建专用批量生成的提示词
            let prompt = self.buildSpecializedBatchPrompt(contentType: contentType, characters: characters, topic: topic)
            
            // 调用API生成批量内容，提高temperature增加随机性
            self.callOpenAI(prompt: prompt, temperature: 0.85)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { content in
                        // 解析返回的内容，分离出每个角色的内容
                        let parsedContents = self.parseBatchContent(content: content, characters: characters)
                        promise(.success(parsedContents))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 构建专用批量提示词 - 为不同内容类型使用定制化提示词
     */
    private func buildSpecializedBatchPrompt(contentType: String, characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        switch contentType {
        case "穿越吐槽":
            return buildBatchTimeJumpPrompt(characters: characters, topic: topic)
        case "日常心情":
            return buildBatchMoodPrompt(characters: characters, topic: topic)
        case "古潮新语":
            return buildBatchAncientModernPrompt(characters: characters, topic: topic)
        case "时空记事":
            return buildBatchTimelinePrompt(characters: characters, topic: topic)
        case "虫洞共鸣":
            return buildBatchResonancePrompt(characters: characters, topic: topic)
        default:
            return buildGenericBatchPrompt(contentType: contentType, characters: characters, topic: topic)
        }
    }
    
    /**
     * 构建穿越吐槽批量提示词
     */
    private func buildBatchTimeJumpPrompt(characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 话题类别及具体话题
        let topicCategories = ["科技类", "交通类", "生活类", "社交类", "职场类", "休闲类", "文化类"]
        
        // 创作方向，确保不同角色有不同方向
        let directions = ["对比反差", "文化错位", "专业角度", "夸张反应", "技能应用", "身份错位"]
        
        // 构建话题库
        let topicsByCategory: [String: [String]] = [
            "科技类": ["智能手机", "无人机", "电子支付", "人工智能", "VR/AR", "智能家居", "自动驾驶", 
                     "云计算", "区块链", "电子书", "电竞", "机器人", "可穿戴设备"],
            "交通类": ["共享单车", "电动车", "高铁", "地铁", "网约车", "堵车", "电动滑板车", 
                     "无人驾驶", "太空旅行", "超级高铁", "飞行汽车", "智能交通灯"],
            "生活类": ["外卖", "奶茶", "快递", "健身房", "网购", "自拍", "短视频", "网红店打卡",
                     "即食食品", "智能家电", "开箱视频", "极简主义", "断舍离", "环保生活"],
            "社交类": ["社交媒体", "点赞", "评论区争论", "表情包", "网络用语", "直播", "网恋",
                     "虚拟社交", "社交恐惧症", "朋友圈社交", "键盘侠", "网络红人", "社交账号运营"],
            "职场类": ["996工作制", "居家办公", "打工人", "副业", "创业", "内卷", "职场社交",
                     "斜杠青年", "终身学习", "职业倦怠", "职场潜规则", "办公室政治", "灵活就业"],
            "休闲类": ["密室逃脱", "剧本杀", "电子游戏", "露营", "瑜伽", "咖啡馆", "宠物文化",
                     "手工制作", "收藏品", "户外探险", "极限运动", "城市徒步", "音乐节"],
            "文化类": ["二次元", "饭圈", "追剧", "网文", "潮流穿搭", "国潮", "古风",
                     "复古文化", "沉浸式展览", "博物馆", "文化IP", "非遗保护", "网络文学"]
        ]
        
        // 创建已使用类别和话题的集合，确保不重复
        var usedCategories = Set<String>()
        var usedTopics = Set<String>()
        
        // 为每个角色设置不同话题和创作方向
        let characterDirectives = characters.enumerated().map { index, character in
            // 选择未使用的类别
            var availableCategories = topicCategories.filter { !usedCategories.contains($0) }
            
            // 如果所有类别都已使用，重置可用类别列表
            if availableCategories.isEmpty {
                availableCategories = topicCategories
                usedCategories.removeAll() // 重置已使用类别集合
            }
            
            // 计算类别索引时加入角色专有因子，确保更随机
            let characterFactor = character.name.count + index
            let categoryIndex = (timestamp + characterFactor) % availableCategories.count
            let selectedCategory = availableCategories[categoryIndex]
            usedCategories.insert(selectedCategory) // 标记为已使用
            
            // 从类别中选择未使用的话题
            let topicsInCategory = topicsByCategory[selectedCategory] ?? ["智能手机"]
            let availableTopics = topicsInCategory.filter { !usedTopics.contains($0) }
            
            // 如果该类别的所有话题都已使用，使用原始列表
            let topicsToChooseFrom = availableTopics.isEmpty ? topicsInCategory : availableTopics
            
            // 使用复合因子选择话题，确保同批次不重复
            let topicFactor = character.primaryField.count + index * 3
            let topicIndex = (timestamp + topicFactor) % topicsToChooseFrom.count
            let selectedTopic = topicsToChooseFrom[topicIndex]
            usedTopics.insert(selectedTopic) // 标记为已使用
            
            // 选择创作方向
            let directionIndex = (timestamp + character.era.count + index * 2) % directions.count
            let selectedDirection = directions[directionIndex]
            
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            • 话题：\(selectedCategory)中的"\(selectedTopic)"
            • 创作方向：\(selectedDirection)
            """
        }.joined(separator: "\n\n")
        
        // 构建完整提示词
        return """
        【批量生成穿越吐槽内容】
        
        请为以下历史人物生成"穿越吐槽"类型的内容，每位角色都是穿越到现代的社交媒体达人，对现代事物或现象发表有趣的评论。
        
        \(characterDirectives)
        
        通用内容规范：
        • 每位角色的内容必须控制在50-80字以内（不含表情）
        • 内容风格必须像真正的社交媒体内容：简短、直接、有态度
        • 口吻必须非常接地气，绝不说教
        • 每篇内容必须有梗或笑点，让年轻人看了想转发
        • 可以加1-2个合适的表情，不必强制
        • 必须突出每个角色的专业背景和个性特点
        • 确保所有角色的内容风格各不相同，避免模式化
        
        表达风格限制：
        • 保持幽默轻松 - 表达方式要有趣且容易理解，避免过于生硬或刻板
        • 适度使用网络用语 - 可以使用1-2个当代流行网络用语，但不要过度堆砌
        • 保持语言自然 - 内容应该像真人发布的社交媒体内容，不要过于做作或人工感
        • 避免过度装傻 - 可以表现文化差异和不理解，但不要过度夸张到不真实
        • 保持专业底色 - 在幽默的同时保留角色专业领域的思维方式和独特视角
        
        ⚠️ 严格禁止重复话题：不同角色绝对不能讨论相同的话题，必须确保话题多样性
        
        创作方向解释：
        • 对比反差：把现代事物和角色时代的事物做幽默对比
        • 文化错位：角色用自己时代的思维理解现代概念的有趣误解
        • 专业角度：角色以专业领域角度点评现代事物
        • 夸张反应：角色对现代司空见惯的事物表现出极度惊讶
        • 技能应用：想象角色如何用特长解决现代问题
        • 身份错位：角色误解了现代场景中自己的角色
        
        严格禁止事项：
        • 不要使用标题或明显的格式标记
        • 不要正式介绍自己
        • 不要写成说教或教育内容
        • 不要过度解释，保持内容的即时性和简洁性
        • 避免使用复杂典故或小众梗
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间戳\(timestamp)作为生成因子，确保本次生成的内容与以往不同
        
        ⚠️⚠️⚠️ 最终检查：确保没有两个或以上的角色讨论"外卖"、"快递"或其他同一话题。每位角色必须讨论不同的话题和事物，所有角色内容必须体现多样性！
        """
    }
    
    /**
     * 构建日常心情批量提示词
     */
    private func buildBatchMoodPrompt(characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 心情类型列表，确保每个角色有不同心情
        let moods = [
            "喜悦", "满足", "感动", "放松", "憧憬", "振奋", "好奇", "欣赏",
            "宁静", "思考", "感悟", "怀旧", "释然", "从容", "平和",
            "迷茫", "惆怅", "无奈", "疲惫", "焦虑", "困惑", "孤独", "纠结",
            "小确幸", "日常吐槽", "生活感悟", "偶遇惊喜", "工作困境"
        ]
        
        // 为每个角色设置不同心情类型
        let characterMoods = characters.enumerated().map { index, character in
            // 基于角色索引和时间戳选择不同心情
            let moodIndex = (timestamp + index * 3) % moods.count
            let selectedMood = moods[moodIndex]
            
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            • 心情类型："\(selectedMood)"
            """
        }.joined(separator: "\n\n")
        
        // 构建完整提示词
        return """
        【批量生成日常心情内容】
        
        请为以下历史人物生成"日常心情"类型的内容，每位角色分享一条关于特定心情类型的真实感受。
        
        \(characterMoods)
        
        通用内容规范：
        • 每位角色的内容控制在80-120字左右
        • 用第一人称，像普通人一样说话，避免刻板印象
        • 语言要简单自然，就像在和朋友聊天
        • 角色可以表达困惑、矛盾或不确定性，这会更真实
        • 可以分享一个具体经历或场景，但不要过于戏剧化
        • 不要过于完美或深刻，真实的情感往往是简单直接的
        • 每位角色的表达风格必须符合其身份背景和性格特点
        • 确保所有角色的内容风格各不相同，避免模式化
        
        表达风格限制：
        • 保持情感真实 - 表达应自然流露，避免过度情绪化或戏剧化表达
        • 减少修辞堆砌 - 使用简单直接的语言表达情感，不需要华丽辞藻
        • 避免过度分析 - 减少对情感的过度理性分析，保持情感表达的自然性
        • 控制叙述节奏 - 不要陷入过长的描述或解释，保持表达的简洁性
        • 使用日常口语 - 采用更接近日常交流的语言，避免过于书面化的表达
        
        写作格式：
        • 可以用【】作为小标题，但不是必须的
        • 绝对不要添加任何标签或元数据
        • 直接输出纯内容
        
        严格禁止事项：
        • 不要复制模板化的表达
        • 避免刻板化的历史人物描述
        • 不要过度强调历史身份
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间戳\(timestamp)和随机因子，确保本次生成的内容与以往不同
        """
    }
    
    /**
     * 构建古潮新语批量提示词
     */
    private func buildBatchAncientModernPrompt(characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 现代话题列表
        let modernTopics = [
            "人工智能", "信息过载", "工作与生活平衡", "社交媒体", "环保意识",
            "快节奏生活", "教育改革", "网络隐私", "全球化", "消费主义",
            "心理健康", "代际沟通", "科技伦理", "创新与传统", "自我实现"
        ]
        
        // 为每个角色设置不同现代话题
        let characterTopics = characters.enumerated().map { index, character in
            // 基于角色索引和时间戳选择不同话题
            let topicIndex = (timestamp + index * 2) % modernTopics.count
            let selectedTopic = topic ?? modernTopics[topicIndex]
            
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            • 现代话题："\(selectedTopic)"
            """
        }.joined(separator: "\n\n")
        
        // 构建完整提示词
        return """
        【批量生成古潮新语内容】
        
        请为以下历史人物生成"古潮新语"类型的内容，每位角色就指定的现代话题分享一条凝练有深度的思考。
        
        \(characterTopics)
        
        通用内容规范：
        • 双重视角：同时展现历史视角和对现代问题的穿透力
        • 启发性思考：引导读者思考超越表面的深层问题
        • 智慧凝练：用简短精练的语言表达深刻复杂的思想
        • 巧妙联结：将角色时代的核心智慧与现代现象建立有意义的联系
        • 可以使用最多1个emoji增强表达力，确保表情与内容主题高度相关
        
        表达风格要求：
        • 保持智慧深度的同时降低表达复杂度 - 用简洁的语言表达深刻的思想
        • 适度使用比喻 - 可以使用1-2个形象比喻，但避免连续使用多个晦涩难懂的比喻
        • 降低抽象度 - 不要堆砌过多抽象概念，每个抽象概念后最好有具体化的解释
        • 避免过度玄学化 - 不要使用过于玄奥或故弄玄虚的表达，保持思想的清晰可辨
        • 控制修辞密度 - 每句话不要包含过多的修辞手法，保持表达的自然流畅
        • 减少刻意的辞藻堆砌 - 避免过度使用生僻词和华丽辞藻，言简意赅更有力量
        
        内容结构与现代解读：
        • 总字数：60-80字（不含表情符号和现代解读）
        • 主体部分：以角色独特视角和思想表达深刻观点（50-70字）
        • 现代解读部分：
          - 必须在主体内容完成后另起一行添加现代解读
          - 格式统一为"（现代解读：...）"
          - 解读内容必须简短精炼（10-15字）
        • 确保每个角色的风格和观点各不相同
        
        严格禁止事项：
        • 绝对不要出现"（注：...）"或类似的解释性文字
        • 除了规定格式的"（现代解读：...）"外，不要添加任何其他形式的注释或解释
        • 不要在正文中插入任何额外的解释或元信息
        • 不要加入与内容无关的技术说明或创作说明
        • 只保留内容主体和一个现代解读，不要有其他补充说明
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间戳\(timestamp)和随机因子\(timestamp % 1000)，确保本次生成的内容与以往不同
        """
    }
    
    /**
     * 构建时空记事批量提示词
     */
    private func buildBatchTimelinePrompt(characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 场景类型列表
        let sceneTypes = [
            "重要发明", "历史转折点", "日常生活场景", "与名人相遇", "重要决定时刻",
            "灵感迸发瞬间", "社会变革", "个人成长历程", "文化活动", "旅行见闻"
        ]
        
        // 为每个角色设置不同场景类型
        let characterScenes = characters.enumerated().map { index, character in
            // 基于角色索引和时间戳选择不同场景类型
            let sceneIndex = (timestamp + index * 3) % sceneTypes.count
            let selectedScene = sceneTypes[sceneIndex]
            
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            • 场景类型："\(selectedScene)"
            """
        }.joined(separator: "\n\n")
        
        // 构建完整提示词
        return """
        【批量生成时空记事内容】
        
        请为以下历史人物生成"时空记事"类型的内容，每位角色回忆一个经历过的关键历史时刻或事件，分享当时的感受和思考。
        
        \(characterScenes)
        
        通用内容规范：
        • 在开头使用【年代，地点】格式标注场景，例如【1905年，伯尔尼】
        • 以第一人称叙述，营造亲历感
        • 描述历史场景时加入感官细节，让读者有身临其境的感觉
        • 不仅描述事件本身，更要分享内心活动和思考
        • 可以提及这一经历如何影响了后来的思想或决定
        • 确保内容与角色的真实历史背景相符
        • 确保所有角色的叙述风格各不相同
        
        表达风格限制：
        • 平衡历史细节和现代理解 - 保持历史视角的同时确保内容易于理解
        • 控制叙述节奏 - 不要过于冗长或过度修饰的描述，保持叙事的流畅性
        • 减少过度戏剧化 - 避免不必要的情绪渲染或夸张效果
        • 避免过度修辞 - 使用适度的修辞手法，不要堆砌华丽辞藻
        • 保持真实可信 - 叙述应贴近历史人物的真实性格和认知，避免过度现代化
        
        内容长度要求：
        • 控制在120-180字左右
        • 内容要生动具体，避免空洞概括
        
        严格禁止事项：
        • 不要使用现代视角评价历史事件
        • 避免使用现代术语（除非特意说明是穿越角色）
        • 不要添加与角色历史不符的虚构内容
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间因子\(timestamp)和随机差异因子\(timestamp % 100)，确保本次生成的内容与以往不同
        """
    }
    
    /**
     * 构建通用批量提示词
     */
    private func buildGenericBatchPrompt(contentType: String, characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 角色信息
        let charactersList = characters.enumerated().map { index, character in
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            """
        }.joined(separator: "\n\n")
        
        // 主题信息
        let topicInfo = topic != nil ? "通用主题：\(topic!)" : "无特定主题要求，为每个角色选择适合的话题"
        
        // 返回通用批量提示词
        return """
        【批量生成"\(contentType)"类型内容】
        
        请为以下历史人物生成"\(contentType)"类型的内容，每位角色展现独特的思维方式、价值观和表达风格。
        
        \(charactersList)
        
        \(topicInfo)
        
        通用内容规范：
        • 每位角色的内容控制在80-150字左右
        • 确保内容展现角色的独特视角和思维方式
        • 内容应与角色的历史背景、专业领域和性格特点相符
        • 保持语言风格的一致性和角色特色
        • 确保所有角色的内容风格各不相同，避免模式化
        • 可以加入适当的情感表达，增强内容的吸引力
        
        严格禁止事项：
        • 不要使用标题或明显的格式标记（除非内容类型特别需要）
        • 不要正式介绍自己或过度解释
        • 避免使用与角色时代不符的现代术语（除非是特意的表达效果）
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间戳\(timestamp)作为随机种子，确保本次生成的内容与以往不同
        """
    }
    
    /**
     * 解析批量生成的内容
     */
    private func parseBatchContent(content: String, characters: [CharacterSystem.CharacterIdentity]) -> [String] {
        // 按分隔符分割内容
        let separator = "---CHARACTER_SEPARATOR---"
        var contentParts = content.components(separatedBy: separator)
        
        // 清理每段内容
        contentParts = contentParts.map { part in
            return part.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 过滤空内容
        contentParts = contentParts.filter { !$0.isEmpty }
        
        // 如果解析出的内容数量少于角色数量，用空字符串补齐
        while contentParts.count < characters.count {
            contentParts.append("")
        }
        
        // 如果解析出的内容数量多于角色数量，截取前面的部分
        if contentParts.count > characters.count {
            contentParts = Array(contentParts.prefix(characters.count))
        }
        
        return contentParts
    }
    
    /**
     * 构建虫洞共鸣批量提示词
     */
    private func buildBatchResonancePrompt(characters: [CharacterSystem.CharacterIdentity], topic: String? = nil) -> String {
        // 获取当前时间戳作为随机种子
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 情境主题列表
        let situations = [
            "工作压力与平衡", "人际关系困扰", "目标实现与坚持", "自我价值与认同", 
            "心灵成长与突破", "决策困境与选择", "专注力与效率", "创造力与灵感", 
            "适应变化与不确定性", "探索未知与冒险"
        ]
        
        // 期望主题列表
        let expectations = [
            "内心平静", "方向指引", "行动勇气", "深度思考", "情感理解", 
            "实用智慧", "新视角", "自我突破", "精神成长", "生活意义"
        ]
        
        // 为每个角色设置不同情境和期望
        let characterPrompts = characters.enumerated().map { index, character in
            // 基于角色索引和时间戳选择不同情境和期望
            let situationIndex = (timestamp + index * 3) % situations.count
            let expectationIndex = (timestamp + index * 5) % expectations.count
            
            let selectedSituation = situations[situationIndex]
            let selectedExpectation = expectations[expectationIndex]
            let resonanceTopic = topic ?? "现代人的困惑"
            
            return """
            【角色\(index+1)：\(character.name)】
            • 身份：\(character.type.displayName)，来自\(character.era)时期
            • 专长：\(character.primaryField)
            • 情境："\(selectedSituation)"
            • 期望："\(selectedExpectation)"
            • 主题："\(resonanceTopic)"
            """
        }.joined(separator: "\n\n")
        
        // 构建完整提示词
        return """
        【批量生成虫洞共鸣内容】
        
        请为以下历史人物生成"虫洞共鸣"类型的内容，每位角色围绕指定情境与期望分享一条深刻而实用的洞见。
        
        \(characterPrompts)
        
        核心要求：
        • 直接明了 - 用现代人容易理解的语言表达核心观点，避免过度隐喻或晦涩表达
        • 真实共鸣 - 分享历史人物曾经的真实挣扎和感悟，但用通俗易懂的方式
        • 实用洞见 - 给出可以立即应用或思考的观点，不要空洞或过于抽象
        • 保持个性 - 体现角色的思维方式和价值观，但不要模仿古代语言或过度文艺化
        • 创意多样 - 使用多变的开场方式和结构形式，避免套路化
        • 内容新鲜 - 创造新的、独特的个人经历，而不是重复使用相同的故事或场景
        
        表达风格限制：
        • 避免华丽辞藻 - 不要使用过于修饰性的语言和晦涩的比喻，用平实的表达更有力量
        • 避免刻意的文学腔 - 不要使用"当月光第三次在尼罗河面破碎时"这类过度文学化表达
        • 避免意象堆砌 - 不要使用连续的抽象意象和符号，保持表达的清晰和直接
        • 避免刻意的古典引用 - 除非确实需要，否则不要刻意引用古典文献或诗句
        • 言之有物 - 确保每句话都传达有意义的内容，不要为了"高大上"而堆砌空洞词藻
        • 保持生活化 - 用日常生活中的普通表达方式和例子来阐述深刻道理
        
        语言要求：
        • 内容必须【完全使用中文】，严禁使用英文或其他语言
        • 即使是引用、专业术语或概念，也必须全部转换为中文表达
        • 不得使用任何英文单词、缩写或短语
        • 绝对避免中英文混杂的表达方式
        • 确保内容的语言纯粹性，保持通顺自然的中文表达
        
        字数：每位角色的内容控制在80-120字，确保内容自然流畅，像真实的社交媒体分享。
        
        严格禁止事项：
        • 不要使用标题或明显的格式标记
        • 不要正式介绍自己或过度解释
        • 避免使用与角色时代不符的现代术语（除非是特意的表达效果）
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        
        返回格式：
        • 每个角色的内容必须用三个连字符分隔：---CHARACTER_SEPARATOR---
        • 按照我提供的角色顺序依次输出内容
        • 只输出内容本身，不要包含角色名称、标签或其他元数据
        
        重要提示：添加时间戳\(timestamp)作为随机种子，确保本次生成的内容与以往不同，但保持原有提示词的高品质要求。
        """
    }
    
    // MARK: - 带评论的内容生成

    /**
     * 生成带评论的内容
     * @param contentType 内容类型
     * @param character 角色身份信息
     * @param commentersCount 评论者数量
     * @param topic 话题
     */
    func generateContentWithComments(
        contentType: String,
        character: CharacterSystem.CharacterIdentity,
        commentersCount: Int,
        topic: String?
    ) -> Future<(content: String, comments: [(character: String, comment: String)], replyComments: [(replier: String, replyTo: String, content: String)]), Error> {
        return Future { promise in
            print("🔄 开始生成带评论的\(contentType)内容: 角色=\(character.name), 评论数=\(commentersCount)")
            
            // 从CharacterSystem获取随机评论者
            let characterSystem = CharacterSystem.shared
            var commenters: [CharacterSystem.CharacterIdentity] = []
            
            // 获取所有可用角色，排除当前角色
            let allAvailableCharacters = characterSystem.getAllCharacters().filter { $0.id != character.id }
            
            // 如果没有足够的角色，则使用默认评论者
            if allAvailableCharacters.isEmpty {
                print("⚠️ 没有找到可用的评论者，使用默认角色名")
                
                // 根据内容类型选择默认评论者名称
                let defaultCommenters = ["爱因斯坦", "莎士比亚", "李白", "孔子", "牛顿"].prefix(commentersCount)
                
                // 创建提示词
                let prompt = self.buildContentWithCommentsPrompt(
                    contentType: contentType,
                    character: character,
                    commenters: defaultCommenters.map { ($0, "") },
                    topic: topic
                )
                
                // 生成内容
                self.generateContent(prompt: prompt)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { response in
                            let result = self.parseContentAndComments(from: response)
                            promise(.success(result))
                        }
                    )
                    .store(in: &self.cancellables)
            } else {
                // 如果有足够的角色，随机选择独特的评论者
                var selectedIds = Set<String>()
                var remainingCharacters = allAvailableCharacters
                
                // 尝试选择多样化的角色类型
                var typeCount: [CharacterSystem.CharacterType: Int] = [:]
                
                // 第一次选择不同类型的角色
                for _ in 0..<min(commentersCount, allAvailableCharacters.count) {
                    // 如果remainingCharacters为空，则中断循环
                    if remainingCharacters.isEmpty {
                        break
                    }
                    
                    // 优先选择类型较少的角色
                    let sortedTypes = allAvailableCharacters.map { $0.type }
                        .filter { type in remainingCharacters.contains(where: { $0.type == type }) }
                        .sorted { typeCount[$0] ?? 0 < typeCount[$1] ?? 0 }
                    
                    if let targetType = sortedTypes.first {
                        let candidatesOfType = remainingCharacters.filter { $0.type == targetType }
                        if let selected = candidatesOfType.randomElement() {
                            commenters.append(selected)
                            selectedIds.insert(selected.id)
                            typeCount[selected.type, default: 0] += 1
                            
                            // 从剩余角色中移除已选角色
                            remainingCharacters.removeAll(where: { $0.id == selected.id })
                        }
                    }
                }
                
                // 如果评论者不足，添加随机角色填充
                while commenters.count < commentersCount && !remainingCharacters.isEmpty {
                    if let randomCharacter = remainingCharacters.randomElement() {
                        commenters.append(randomCharacter)
                        selectedIds.insert(randomCharacter.id)
                        
                        // 从剩余角色中移除已选角色
                        remainingCharacters.removeAll(where: { $0.id == randomCharacter.id })
                    }
                }
                
                // 如果还是不足，则重复使用已有角色名称
                if commenters.count < commentersCount {
                    print("⚠️ 可用角色不足，部分评论者可能重复")
                    while commenters.count < commentersCount && !allAvailableCharacters.isEmpty {
                        if let randomCharacter = allAvailableCharacters.randomElement() {
                            commenters.append(randomCharacter)
                        }
                    }
                }
                
                print("✅ 已选择\(commenters.count)位评论者: \(commenters.map { $0.name }.joined(separator: ", "))")
                
                // 创建提示词
                let prompt = self.buildContentWithCommentsPrompt(
                    contentType: contentType,
                    character: character,
                    commenters: commenters.map { ($0.name, "\($0.type.displayName)，专长：\($0.primaryField)") },
                    topic: topic
                )
                
                // 生成内容
                self.generateContent(prompt: prompt)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { response in
                            let result = self.parseContentAndComments(from: response)
                            promise(.success(result))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }
    }
    
    /**
     * 构建带评论的内容提示词
     */
    private func buildContentWithCommentsPrompt(
        contentType: String,
        character: CharacterSystem.CharacterIdentity,
        commenters: [(name: String, description: String)],
        topic: String?
    ) -> String {
        // 获取角色基本信息
        let characterInfo = """
        【主要角色信息】
        • 角色：\(character.name)
        • 类型：\(character.type.displayName)
        • 时代：\(character.era)
        • 专业领域：\(character.primaryField)
        • 简介：\(character.briefDescription)
        """
        
        // 主题信息
        let topicInfo = "• 指定主题：\(topic ?? "未指定主题")"
        
        // 根据内容类型添加特殊格式指令
        var specialFormatting = ""
        var specialExample = ""
        var commentFormatting = ""
        
        // 根据不同内容类型设置特殊格式要求
        if contentType == "古潮新语" {
            specialFormatting = """
            • 总字数：60-80字（不含表情符号和现代解读）
            • 主体部分：以你的独特视角和思想表达深刻观点（50-70字）
            • 现代解读部分：
              - 必须在主体内容完成后另起一行添加现代解读
              - 格式统一为"（现代解读：...）"
              - 解读内容必须简短精炼（10-15字）
              - 用最简单的现代语言点明内容的核心思想
              - 确保解读语言通俗易懂，避免复杂术语
              - 现代解读必须单独成行，不要与正文混在一起
            
            表达风格限制：
            • 直接明了 - 使用现代通用语言表达，避免过度文言或古风表达
            • 真诚自然 - 分享真实的人生挣扎和感悟，而非假大空的励志套话
            • 实用价值 - 提供可以直接思考或应用的洞察，而非抽象概念
            • 保持特色 - 展现人物的独特个性，但不刻意模仿古代语言风格
            • 内容新鲜 - 创造原创独特的内容，避免老生常谈
            
            严格禁止以下表达风格：
            • 避免华丽辞藻和过度文学化表达
            • 避免晦涩的意象和抽象比喻
            • 避免空洞无物的"鸡汤"内容
            • 避免刻意古风或文言表达
            • 避免故意使用高深术语和专业名词
            • 每句话都要有实质内容，避免废话和填充语
            • 用日常生活的例子和语言解释深刻道理
            
            语言要求：
            • 所有内容必须是中文，绝对不允许使用英文
            • 不得使用任何英文单词、缩写或外来语
            • 专业术语和概念必须使用纯中文表达
            • 保持地道、自然的中文表达习惯
            """
            
            specialExample = """
            
            【古潮新语格式示例】
            人生最大的成就不是外部的认可，而是在挑战中发现自己的力量。所有困难都是镜子，照出你不知道的自我。只有经历过暴雨，才能真正欣赏晴天的珍贵。
            （现代解读：困境是发现真我的契机）
            """
            
            commentFormatting = """
            • 【古潮新语】评论要求：
              - 至少有一条评论表示认同并扩展主贴观点
              - 至少有一条评论提供不同角度的思考
              - 评论应体现评论者的智慧和专业背景
              - 评论应简短有力，点出关键洞见
            """
        } else if contentType == "时空记事" {
            specialFormatting = """
            • 以特定历史事件或场景为基础
            • 开头必须使用【年代，地点】格式标注时空背景
            • 采用第一人称叙述，像日记或回忆录
            • 语言风格应接近现代，确保易读性
            • 包含多感官细节描述，增强沉浸感
            • 突出历史人物当时的思考和情感
            • 可以适当展现历史人物鲜为人知的一面
            """
            
            specialExample = """
            
            【时空记事格式示例】
            【1905年，伯尔尼】
            又一个深夜，办公室的灯依然亮着。桌上凌乱的草稿纸上，我写下了最后一个方程。当墨水渗入纸张的那一刻，我感到一种奇妙的确信——相对论将改变人类理解宇宙的方式。窗外是宁静的伯尔尼夜空，而我的脑海中却是翻腾的时空图景。
            """
            
            commentFormatting = """
            • 【时空记事】评论要求：
              - 至少有一条评论提供对历史事件的不同角度解读
              - 至少有一条评论补充相关历史知识或背景
              - 可以有一条评论对作者的观察力或历史感表达赞赏
              - 评论应体现历史人物的专业知识和时代视角
              - 评论结尾不要添加类似"(不同角度解读)"、"(补充历史背景)"等括号标注
            """
        } else if contentType == "穿越吐槽" {
            specialFormatting = """
            • 内容字数控制在50-80字以内（不含表情）
            • 内容风格必须像真正的社交媒体内容：简短、直接、有态度
            • 口吻必须非常接地气，绝不说教
            • 每篇内容必须有梗或笑点，让年轻人看了想转发
            • 可以加1-2个合适的表情，不必强制
            • 必须突出角色的专业背景和个性特点
            
            创作方向参考：
            • 对比反差：把现代事物和角色时代的事物做幽默对比
            • 文化错位：角色用自己时代的思维理解现代概念的有趣误解
            • 专业角度：角色以专业领域角度点评现代事物
            • 夸张反应：角色对现代司空见惯的事物表现出极度惊讶
            """
            
            specialExample = """
            
            【穿越吐槽格式示例】
            刚开始以为"云端办公"是在天上造了个亭子，没想到只是对着屏幕说话。还好，要是真的上云，我这身袍子怕是遮不住裙底风光。😂 老子云游四方，如今倒真是"云游"了。
            """
            
            commentFormatting = """
            • 【穿越吐槽】评论要求：
              - 评论应以幽默回应为主，保持轻松风格
              - 至少有一条评论延续或升级原帖笑点
              - 可以有"补刀"式评论，进一步放大文化反差
              - 评论可以适当使用表情符号，增强互动感
              - 评论要简短直接，充满个性
              - 不要为现代网络用语或梗（如"破防"、"yyds"等）添加注释或解释
            """
        } else if contentType == "日常心情" {
            specialFormatting = """
            • 用第一人称，像普通人一样说话，避免刻板印象
            • 语言要简单自然，就像在和朋友聊天
            • 可以表达困惑、矛盾或不确定性，这会更真实
            • 可以分享一个具体经历或场景，但不要过于戏剧化
            • 不要过于完美或深刻，真实的情感往往是简单直接的
            • 可以用【】作为小标题，但不是必须的
            """
            
            specialExample = """
            
            【日常心情格式示例】
            【心有所感】
            窗外的树摇曳着，心情也跟着起伏。今天完成了那个困扰我许久的证明，突然发现之前走错的弯路也有意义。像生活一样，有时需要走错，才能更确定什么是对的。人生某些问题，或许就如同数学一样，解题的过程比答案更重要。
            """
            
            commentFormatting = """
            • 【日常心情】评论要求：
              - 评论应以共鸣和情感支持为主
              - 至少有一条评论分享类似经历或感受
              - 评论语气应温暖、亲切、支持
              - 可以有一条评论提供温和的生活建议或鼓励
              - 评论要体现真诚的情感连接
            """
        } else if contentType == "虫洞共鸣" {
            specialFormatting = """
            • 内容应该是80-120字的简洁表达
            • 分享角色从自身经历中获得的深度洞察
            • 语言表达应贴近自然的社交媒体内容风格
            • 内容应包含个人经历的真实感和情感共鸣
            • 避免刻意的说教口吻和过度形式化的表达
            
            核心要求：
            • 直接明了 - 使用现代通用语言表达，避免过度文言或古风表达
            • 真诚自然 - 分享真实的人生挣扎和感悟，而非假大空的励志套话
            • 实用价值 - 提供可以直接思考或应用的洞察，而非抽象概念
            • 保持特色 - 展现人物的独特个性，但不刻意模仿古代语言风格
            • 内容新鲜 - 创造原创独特的内容，避免老生常谈
            
            表达风格限制：
            • 避免华丽辞藻和过度文学化表达
            • 避免晦涩的意象和抽象比喻
            • 避免空洞无物的"鸡汤"内容
            • 避免刻意古风或文言表达
            • 避免故意使用高深术语和专业名词
            """
            
            commentFormatting = """
            • 【虫洞共鸣】评论要求：
              - 至少有一条评论表达深层共鸣或感谢
              - 至少有一条评论提供补充观点或延伸思考
              - 评论要体现不同人物的独特视角
              - 评论语气应真诚自然，避免过于客套或做作
              - 确保每条评论都有实质性内容，不要空泛表达
            """
        }
        
        // 生成评论者信息
        let commentersInfo = commenters.enumerated().map { index, commenter in
            return "评论者\(index + 1)：\(commenter.name)" + (commenter.description.isEmpty ? "" : " - \(commenter.description)")
        }.joined(separator: "\n")
        
        // 构建完整提示词
        return """
        请完成两项任务：
        1. 首先生成\(character.name)的一篇"\(contentType)"类型内容
        2. 然后生成\(commenters.count)位不同历史人物对这篇内容的评论
        
        \(characterInfo)
        \(topicInfo)
        
        【评论者信息】
        \(commentersInfo)
        
        【内容生成要求】
        • 展现角色的独特视角和思维方式
        • 风格应符合角色的历史背景、专业领域和性格特点
        • 内容表达自然流畅，像社交媒体发言一样
        • 不要使用标题或明显的格式标记（除非内容类型特别需要）
        \(specialFormatting.isEmpty ? "" : "\n\(specialFormatting)")
        \(specialExample.isEmpty ? "" : "\n\(specialExample)")
        
        【评论生成要求】
        • 请确保使用我提供的评论者名称
        • 评论应反映评论者的历史背景、专业知识和个性特点
        • 评论要与帖子内容有明确关联，展现与主题相关的观点
        • 每条评论控制在30-60字
        • 评论风格多样化，可以有赞同、质疑、补充或延伸等不同角度
        • 专业术语需要用通俗的表达方式解释，确保普通用户能理解
        • 将复杂概念用简单的比喻或实例说明，但不要过度简化专业观点
        • 历史人物的表达方式要平衡专业性和通俗性，表达深度的同时保持易懂
        • 避免使用过多学术术语和深奥词汇，必要时在简单括号中解释
        • 适当使用生活化语言，但保留历史人物的思想深度和专业洞见
        • 评论格式必须为：[历史人物名]：[评论内容]
        • 严格使用中文冒号"："分隔人物名和评论
        • 确保每条评论都有实际内容，不要生成空评论
        • 绝对不要在评论末尾添加类似"(不同角度解读)"、"(补充历史背景)"、"(专业延伸)"、"(情感共鸣)"等任何形式的解释性括号标注
        \(commentFormatting.isEmpty ? "" : "\n\(commentFormatting)")
        
        【追加评论生成要求】
        • 在生成基础评论后，额外生成2-3条追加评论，这些评论是对基础评论的回复
        • 追加评论必须使用格式："回复评论：[历史人物名]回复@[被回复者姓名]：[回复内容]"
        • 回复内容要与被回复评论有直接关联，可以是赞同并补充、质疑反驳、或提出新视角
        • 回复应该更加口语化，像真实社交媒体互动
        • 回复者应该是与原评论者不同的历史人物，展现不同时代、不同领域的思想碰撞
        • 每条回复评论控制在20-50字
        • 回复评论的语气和风格应与内容类型相匹配：
          - 虫洞共鸣：深度思考的延伸，相互启发式的哲学对话
          - 古潮新语：古代视角与现代观点的辩论，互相质疑和补充
          - 穿越吐槽：幽默加码，一个角色的吐槽被另一个角色用更幽默的方式继续
          - 日常心情：情感共鸣和安慰，对原评论表达理解或提供不同角度的情感支持
          - 时空记事：历史细节的补充或纠正，"我当时也在场"的视角
        
        【输出格式】
        ---内容开始---
        [帖子正文内容]
        ---内容结束---
        ---评论开始---
        \(commenters.map { $0.name }.joined(separator: "/"))：[评论内容]
        ---评论结束---
        ---追加评论开始---
        回复评论：[历史人物名]回复@[被回复者姓名]：[回复内容]
        回复评论：[历史人物名]回复@[被回复者姓名]：[回复内容]
        回复评论：[历史人物名]回复@[被回复者姓名]：[回复内容]
        ---追加评论结束---
        
        【重要】
        • 确保严格按照上述模板输出内容
        • 保留所有特殊格式要求（如古潮新语的现代解读、时空记事的时间地点标注等）
        • 不要添加额外的格式标记或说明
        • 每条评论必须有人物名和内容，中间使用中文冒号"："分隔
        • 必须严格使用我提供的评论者名称，顺序可以灵活
        • 严禁在评论结尾添加任何形式的解释性括号，如"(不同角度解读)"、"(补充历史背景)"等
        • 追加评论必须明确指出是对哪位评论者的回复
        """
    }
    
    /**
     * 解析生成的内容和评论
     */
    private func parseContentAndComments(from response: String) -> (content: String, comments: [(character: String, comment: String)], replyComments: [(replier: String, replyTo: String, content: String)]) {
        print("🔍 解析AI返回的内容和评论...")
        
        // 匹配内容部分
        let contentRegexPattern = "---内容开始---(.*?)---内容结束---"
        let contentRegex = try! NSRegularExpression(pattern: contentRegexPattern, options: [.dotMatchesLineSeparators])
        let responseRange = NSRange(location: 0, length: response.utf16.count)
        let contentMatch = contentRegex.firstMatch(in: response, options: [], range: responseRange)
        let content = contentMatch != nil ? 
            (response as NSString).substring(with: contentMatch!.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines) : 
            response
        
        print("📄 解析得到的原始内容: \(content.prefix(100))..." + (content.count > 100 ? "..." : ""))
        
        // 检查内容是否包含特定格式特征
        let _ = content.contains("（现代解读：") && content.contains("）")
        let timelineHeaderPattern = "【[0-9]+年.*?】"
        let _ = content.range(of: timelineHeaderPattern, options: .regularExpression) != nil
        let _ = content.count >= 80 && content.count <= 120 && 
                                      (content.contains("困惑") || content.contains("感悟") || 
                                       content.contains("洞见") || content.contains("智慧") || 
                                       content.contains("经验") || content.contains("挑战"))
        
        // 匹配评论部分
        let commentsRegexPattern = "---评论开始---(.*?)---评论结束---"
        let commentsRegex = try! NSRegularExpression(pattern: commentsRegexPattern, options: [.dotMatchesLineSeparators])
        let commentsMatch = commentsRegex.firstMatch(in: response, options: [], range: responseRange)
        
        var comments: [(character: String, comment: String)] = []
        
        if let match = commentsMatch {
            let commentsText = (response as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            print("💬 解析得到的评论文本: \(commentsText)")
            
            // 分割每条评论
            let commentLines = commentsText.components(separatedBy: .newlines)
            for line in commentLines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLine.isEmpty else { continue }
                
                // 查找第一个中文冒号，分割角色名和评论内容
                if let colonRange = trimmedLine.range(of: "：") {
                    let character = String(trimmedLine[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let comment = String(trimmedLine[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !character.isEmpty && !comment.isEmpty {
                        comments.append((character: character, comment: comment))
                        print("✅ 解析评论: \(character) - \(comment.prefix(30))...")
                    }
                }
            }
        }
        
        // 匹配追加评论部分
        let replyCommentsRegexPattern = "---追加评论开始---(.*?)---追加评论结束---"
        let replyCommentsRegex = try! NSRegularExpression(pattern: replyCommentsRegexPattern, options: [.dotMatchesLineSeparators])
        let replyCommentsMatch = replyCommentsRegex.firstMatch(in: response, options: [], range: responseRange)
        
        var replyComments: [(replier: String, replyTo: String, content: String)] = []
        
        if let match = replyCommentsMatch {
            let replyCommentsText = (response as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            print("💬 解析得到的追加评论文本: \(replyCommentsText)")
            
            // 分割每条追加评论
            let replyLines = replyCommentsText.components(separatedBy: .newlines)
            for line in replyLines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLine.isEmpty else { continue }
                
                // 解析"回复评论：[历史人物名]回复@[被回复者姓名]：[回复内容]"格式
                if trimmedLine.contains("回复@") && trimmedLine.contains("回复评论：") {
                    // 提取回复者姓名
                    if let replierStartRange = trimmedLine.range(of: "回复评论："),
                       let replyToStartRange = trimmedLine.range(of: "回复@", options: [], range: replierStartRange.upperBound..<trimmedLine.endIndex),
                       let contentStartRange = trimmedLine.range(of: "：", options: [], range: replyToStartRange.upperBound..<trimmedLine.endIndex) {
                        
                        let replierEndRange = replyToStartRange.lowerBound
                        let replier = String(trimmedLine[replierStartRange.upperBound..<replierEndRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let replyToEndRange = contentStartRange.lowerBound
                        let replyTo = String(trimmedLine[replyToStartRange.upperBound..<replyToEndRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let content = String(trimmedLine[contentStartRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !replier.isEmpty && !replyTo.isEmpty && !content.isEmpty {
                            replyComments.append((replier: replier, replyTo: replyTo, content: content))
                            print("✅ 解析追加评论: \(replier) 回复 \(replyTo) - \(content.prefix(30))...")
                        }
                    }
                }
                // 尝试解析简化格式"[历史人物名]回复@[被回复者姓名]：[回复内容]"
                else if trimmedLine.contains("回复@") {
                    if let replierEndRange = trimmedLine.range(of: "回复@"),
                       let contentStartRange = trimmedLine.range(of: "：", options: [], range: replierEndRange.upperBound..<trimmedLine.endIndex) {
                        
                        let replier = String(trimmedLine[..<replierEndRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let replyToEndRange = contentStartRange.lowerBound
                        let replyTo = String(trimmedLine[replierEndRange.upperBound..<replyToEndRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let content = String(trimmedLine[contentStartRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !replier.isEmpty && !replyTo.isEmpty && !content.isEmpty {
                            replyComments.append((replier: replier, replyTo: replyTo, content: content))
                            print("✅ 解析追加评论(简化格式): \(replier) 回复 \(replyTo) - \(content.prefix(30))...")
                        }
                    }
                }
            }
        }
        
        print("📊 解析结果: 内容长度=\(content.count)字, 评论数=\(comments.count), 追加评论数=\(replyComments.count)")
        
        return (content, comments, replyComments)
    }
    
    /**
     * 生成带评论的虫洞共鸣内容
     * @param figure 人物
     * @param situation 情境
     * @param expectation 期待
     * @param keyword 可选关键词
     * @param commentersCount 评论者数量
     */
    func generateResonanceContentWithComments(
        figure: String,
        situation: String,
        expectation: String,
        keyword: String? = nil,
        commentersCount: Int = 3
    ) -> Future<(content: String, comments: [(character: String, comment: String)], replyComments: [(replier: String, replyTo: String, content: String)]), Error> {
        return Future { promise in
            print("🔄 开始生成带评论的虫洞共鸣内容: 角色=\(figure), 情境=\(situation)")
            
            // 根据历史人物查询对应的CharacterIdentity
            self.findCharacterByName(name: figure)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 查找角色信息失败: \(error.localizedDescription)")
                            
                            // 创建一个临时角色信息并继续生成内容
                            print("⚠️ 创建临时角色继续生成内容")
                            let tempCharacter = CharacterSystem.CharacterIdentity(
                                id: "temp_\(UUID().uuidString.prefix(8))",
                                name: figure,
                                type: .historical, 
                                era: "未知时代",
                                primaryField: "未知专长",
                                briefDescription: "历史人物",
                                avatarName: "person.fill",
                                region: "",
                                contentAffinities: [
                                    "古潮新语": 0.7, 
                                    "穿越吐槽": 0.7, 
                                    "日常心情": 0.7, 
                                    "虫洞共鸣": 0.8, 
                                    "时空记事": 0.7
                                ]
                            )
                            
                            // 继续生成内容
                            self.generateContentWithComments(
                                contentType: "虫洞共鸣",
                                character: tempCharacter,
                                commentersCount: commentersCount,
                                topic: "\(situation)与\(expectation)\(keyword != nil ? "，关注\(keyword!)" : "")"
                            )
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        promise(.failure(error))
                                    }
                                },
                                receiveValue: { result in
                                    promise(.success(result))
                                }
                            )
                            .store(in: &self.cancellables)
                        }
                    },
                    receiveValue: { character in
                        print("✅ 找到角色: \(character.name), 类型: \(character.type.displayName)")
                        
                        // 使用找到的角色信息生成内容
                        self.generateContentWithComments(
                            contentType: "虫洞共鸣",
                            character: character,
                            commentersCount: commentersCount,
                            topic: "\(situation)与\(expectation)\(keyword != nil ? "，关注\(keyword!)" : "")"
                        )
                        .sink(
                            receiveCompletion: { completion in
                                if case .failure(let error) = completion {
                                    promise(.failure(error))
                                }
                            },
                            receiveValue: { result in
                                promise(.success(result))
                            }
                        )
                        .store(in: &self.cancellables)
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 根据名称查找角色
     * @param name 角色名称
     * @return Future<CharacterSystem.CharacterIdentity, Error>
     */
    private func findCharacterByName(name: String) -> Future<CharacterSystem.CharacterIdentity, Error> {
        return Future { promise in
            // 获取角色系统实例
            let characterSystem = CharacterSystem.shared
            
            // 使用CharacterSystem中的方法查找角色
            characterSystem.findCharacterByName(name)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ 在数据库中查找角色失败: \(error.localizedDescription)")
                        }
                    },
                    receiveValue: { character in
                        if let foundCharacter = character {
                            // 找到匹配的角色
                            promise(.success(foundCharacter))
                        } else {
                            print("⚠️ 在数据库中未找到角色: \(name)，尝试使用备用方案")
                            
                            // 备用方案：尝试使用模糊匹配
                            let potentialMatches = characterSystem.getAllCharacters().filter {
                                $0.name.contains(name) || name.contains($0.name)
                            }
                            
                            if let bestMatch = potentialMatches.first {
                                print("✅ 找到最佳匹配角色: \(bestMatch.name)")
                                promise(.success(bestMatch))
                            } else {
                                print("⚠️ 无匹配角色，创建临时角色")
                                
                                // 创建一个临时角色（优先使用历史人物类型）
                                let tempCharacter = CharacterSystem.CharacterIdentity(
                                    id: "temp_\(UUID().uuidString.prefix(8))",
                                    name: name,
                                    type: .historical,
                                    era: "未知时代",
                                    primaryField: "未知专长",
                                    briefDescription: "历史人物",
                                    avatarName: self.getAvatarForCharacter(name: name),
                                    region: "",
                                    contentAffinities: [
                                        "古潮新语": 0.7, 
                                        "穿越吐槽": 0.7, 
                                        "日常心情": 0.7, 
                                        "虫洞共鸣": 0.8, 
                                        "时空记事": 0.7
                                    ]
                                )
                                promise(.success(tempCharacter))
                            }
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 根据角色名获取头像名称
     */
    private func getAvatarForCharacter(name: String) -> String {
        let avatarMapping: [String: String] = [
            "爱因斯坦": "atom",
            "莎士比亚": "book.fill",
            "达芬奇": "paintpalette.fill",
            "孔子": "scroll.fill",
            "牛顿": "graduationcap.fill",
            "李白": "text.book.closed.fill",
            "苏格拉底": "brain.head.profile",
            "居里夫人": "sparkles",
            "达尔文": "leaf.fill",
            "贝多芬": "music.note"
        ]
        
        return avatarMapping[name] ?? "person.fill"
    }
}

// 虫洞共鸣帖子模型
struct ResonancePost {
    let id: String
    let author: String
    let authorAvatar: String
    let content: String
    let timestamp: Date
    let likes: Int
    let comments: [ResonanceComment]
}

// 虫洞共鸣评论模型
struct ResonanceComment {
    let id: String
    let author: String
    let authorAvatar: String
    let content: String
    let timestamp: Date
    let likes: Int
} 