import Foundation

/**
 * 语义处理器
 * 负责分析评论和帖子内容的语义
 */
class SemanticProcessor {
    
    /**
     * 分析评论语义
     */
    func analyze(comment: String, postContent: String) -> SemanticModel {
        // 1. 提取关键词
        let commentKeywords = extractKeywords(from: comment)
        let postKeywords = extractKeywords(from: postContent)
        
        // 2. 识别评论意图和情感
        let intent = classifyIntent(comment)
        let sentiment = analyzeSentiment(comment)
        
        // 3. 内容关联性分析
        let relevance = calculateRelevance(comment, postContent)
        let focusAspect = identifyFocusAspect(comment, postContent, commentKeywords, postKeywords)
        
        // 4. 构建语义模型
        return SemanticModel(
            keywords: commentKeywords,
            intent: intent,
            sentiment: sentiment,
            relevance: relevance,
            focusAspect: focusAspect,
            deepMeaning: extractDeepMeaning(comment, intent, sentiment)
        )
    }
    
    /**
     * 提取关键词
     */
    private func extractKeywords(from text: String) -> [String] {
        // 移除标点符号和多余空格
        let cleanText = text.replacingOccurrences(of: "[\\p{P}\\p{S}]", with: " ", options: .regularExpression)
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 分词
        let words = cleanText.components(separatedBy: " ")
        
        // 过滤停用词
        let stopwords = ["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这"]
        let filteredWords = words.filter { word in
            return word.count > 1 && !stopwords.contains(word)
        }
        
        // 按词频排序
        var wordFrequency: [String: Int] = [:]
        for word in filteredWords {
            wordFrequency[word, default: 0] += 1
        }
        
        let sortedWords = wordFrequency.sorted { $0.value > $1.value }.map { $0.key }
        
        // 返回前5个关键词
        return Array(sortedWords.prefix(5))
    }
    
    /**
     * 分类评论意图
     */
    private func classifyIntent(_ comment: String) -> CommentIntent {
        let lowercasedComment = comment.lowercased()
        
        // 检查是否是问题
        let questionIndicators = ["?", "？", "吗", "为什么", "怎么", "如何", "是不是", 
                               "能否", "能不能", "可以", "什么", "谁", "哪里", "何时", 
                               "几", "多少", "是否", "有没有"]
        
        for indicator in questionIndicators {
            if lowercasedComment.contains(indicator) {
                return .question
            }
        }
        
        // 检查是否是赞美/积极评论
        let positiveWords = ["喜欢", "赞", "棒", "厉害", "佩服", "学习", "感谢", "谢谢", "支持", 
                             "有趣", "好", "爱", "精彩", "优秀", "欣赏", "开心", "快乐", "美好"]
        
        // 检查积极词汇
        for word in positiveWords {
            if lowercasedComment.contains(word) {
                return .praise
            }
        }
        
        // 检查是否是质疑/负面评论
        let negativeWords = ["不同意", "错误", "不对", "反对", "不赞同", "有问题", "批评", 
                             "不好", "差", "糟糕", "讨厌", "失望", "不行", "不喜欢"]
        
        for word in negativeWords {
            if lowercasedComment.contains(word) {
                return .negative
            }
        }
        
        // 检查是否是打招呼
        let greetingWords = ["你好", "早上好", "下午好", "晚上好", "嗨", "hi", "hello"]
        
        for greeting in greetingWords {
            if lowercasedComment.contains(greeting) {
                return .greeting
            }
        }
        
        // 检查是否是简单表情或短评论
        if comment.count < 5 {
            if comment.contains("哈") || comment.contains("😄") || comment.contains("😂") {
                return .emotion
            }
            return .short
        }
        
        // 默认为中性评论
        return .neutral
    }
    
    /**
     * 分析评论情感
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
     * 计算评论与帖子的相关度
     */
    private func calculateRelevance(_ comment: String, _ postContent: String) -> Double {
        let commentKeywords = extractKeywords(from: comment)
        let postKeywords = extractKeywords(from: postContent)
        
        // 计算关键词重叠数
        var matchCount = 0
        for keyword in commentKeywords {
            if postKeywords.contains(keyword) {
                matchCount += 1
            }
        }
        
        // 计算相关度得分
        if commentKeywords.isEmpty {
            return 0.3 // 默认相关度
        }
        
        return Double(matchCount) / Double(commentKeywords.count)
    }
    
    /**
     * 识别评论关注的方面
     */
    private func identifyFocusAspect(_ comment: String, _ postContent: String, _ commentKeywords: [String], _ postKeywords: [String]) -> String? {
        // 1. 尝试从评论关键词和帖子关键词的交集中找出关注点
        let commonKeywords = commentKeywords.filter { postKeywords.contains($0) }
        if let mainKeyword = commonKeywords.first {
            return mainKeyword
        }
        
        // 2. 如果没有交集，使用评论的主要关键词
        if let mainCommentKeyword = commentKeywords.first {
            return mainCommentKeyword
        }
        
        // 3. 如果评论没有明显关键词，尝试推断主题
        if comment.count < 10 {
            // 短评论，可能是对整体的反应
            return "整体内容"
        }
        
        // 4. 尝试从帖子内容推断主题
        let topics = ["科学", "艺术", "哲学", "情感", "生活", "技术", "历史", "文化"]
        for topic in topics {
            if postContent.contains(topic) {
                return topic
            }
        }
        
        return "一般话题"
    }
    
    /**
     * 提取评论深层含义
     */
    private func extractDeepMeaning(_ comment: String, _ intent: CommentIntent, _ sentiment: Double) -> String {
        switch intent {
        case .question:
            return "提问寻求信息或观点"
        case .praise:
            return "表达赞赏或认同"
        case .negative:
            return "表达质疑或不满"
        case .greeting:
            return "社交性问候"
        case .emotion:
            return sentiment > 0 ? "表达积极情绪" : "表达消极情绪"
        case .short:
            return "简短回应"
        case .neutral:
            if sentiment > 0.5 {
                return "积极讨论或分享"
            } else if sentiment < -0.5 {
                return "消极评价或批评"
            } else {
                return "中性陈述或讨论"
            }
        }
    }
}

/**
 * 评论意图枚举
 */
enum CommentIntent {
    case question    // 问题
    case praise      // 赞美
    case negative    // 负面评价
    case greeting    // 问候
    case emotion     // 情绪表达
    case short       // 短评论
    case neutral     // 中性评论
}

/**
 * 语义模型
 */
struct SemanticModel {
    let keywords: [String]
    let intent: CommentIntent
    let sentiment: Double
    let relevance: Double
    let focusAspect: String?
    let deepMeaning: String
    
    var possibleTopics: [String] {
        var topics = [String]()
        if let focus = focusAspect {
            topics.append(focus)
        }
        topics.append(contentsOf: keywords)
        return topics
    }
} 