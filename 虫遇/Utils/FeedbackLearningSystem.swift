import Foundation
import Combine

/**
 * 反馈学习系统
 * 收集用户反馈并优化内容生成
 */
class FeedbackLearningSystem {
    // 单例实例
    static let shared = FeedbackLearningSystem()
    
    // 用户兴趣跟踪器
    private let interestTracker = UserInterestTracker.shared
    
    // 发布者，用于通知反馈分析结果
    private let feedbackAnalysisSubject = PassthroughSubject<FeedbackAnalysisResult, Never>()
    var feedbackAnalysisPublisher: AnyPublisher<FeedbackAnalysisResult, Never> {
        return feedbackAnalysisSubject.eraseToAnyPublisher()
    }
    
    // 反馈类型
    enum FeedbackType: String, Codable {
        case positive    // 正面反馈
        case neutral     // 中性反馈
        case negative    // 负面反馈
    }
    
    // 反馈维度
    enum FeedbackDimension: String, Codable {
        case relevance       // 相关性
        case novelty         // 新颖性
        case usefulness      // 实用性
        case emotionalImpact // 情感影响
        case clarity         // 清晰度
    }
    
    // 反馈记录结构
    struct FeedbackRecord: Codable {
        let timestamp: Date
        let postId: String
        let figure: String
        let situation: String
        let expectation: String
        let keyword: String?
        let feedbackType: FeedbackType
        let feedbackDimension: FeedbackDimension?
        let explicitRating: Int?  // 1-5星评分
        let commentText: String?
        let userAction: UserInterestTracker.UserInterestModel.InteractionRecord.InteractionType
    }
    
    // 反馈分析结果
    struct FeedbackAnalysisResult: Codable {
        var overallSatisfaction: Double = 0.0  // 0-1
        var dimensionScores: [FeedbackDimension: Double] = [:]
        var figurePerformance: [String: Double] = [:]
        var situationPerformance: [String: Double] = [:]
        var expectationPerformance: [String: Double] = [:]
        var improvementAreas: [FeedbackDimension] = []
        var recommendedFigures: [String] = []
    }
    
    // 反馈记录集合
    private var feedbackRecords: [FeedbackRecord] = []
    
    // 反馈权重配置
    private struct FeedbackWeights {
        static let like = 0.7
        static let bookmark = 0.9
        static let comment = 0.6
        static let share = 0.8
        static let view = 0.3
        static let explicitRating = 1.0
    }
    
    /**
     * 记录用户反馈
     * @param postId 帖子ID
     * @param figure 历史人物
     * @param situation 情境
     * @param expectation 期望
     * @param keyword 关键词
     * @param feedbackType 反馈类型
     * @param feedbackDimension 反馈维度
     * @param explicitRating 显式评分
     * @param commentText 评论文本
     * @param userAction 用户操作
     */
    func recordFeedback(
        postId: String,
        figure: String,
        situation: String,
        expectation: String,
        keyword: String? = nil,
        feedbackType: FeedbackType? = nil,
        feedbackDimension: FeedbackDimension? = nil,
        explicitRating: Int? = nil,
        commentText: String? = nil,
        userAction: UserInterestTracker.UserInterestModel.InteractionRecord.InteractionType
    ) {
        // 根据用户操作推断反馈类型
        let inferredFeedbackType = feedbackType ?? inferFeedbackType(from: userAction, explicitRating: explicitRating)
        
        // 创建反馈记录
        let record = FeedbackRecord(
            timestamp: Date(),
            postId: postId,
            figure: figure,
            situation: situation,
            expectation: expectation,
            keyword: keyword,
            feedbackType: inferredFeedbackType,
            feedbackDimension: feedbackDimension,
            explicitRating: explicitRating,
            commentText: commentText,
            userAction: userAction
        )
        
        // 添加到反馈记录集合
        feedbackRecords.append(record)
        
        // 同时更新用户兴趣跟踪器
        interestTracker.trackFigureInteraction(
            figure: figure,
            interactionType: userAction,
            situation: situation,
            expectation: expectation,
            keyword: keyword
        )
        
        // 保存反馈记录
        saveFeedbackRecords()
        
        // 如果累积了足够的反馈，触发分析
        if feedbackRecords.count % 5 == 0 {
            let analysisResult = analyzeFeedback()
            feedbackAnalysisSubject.send(analysisResult)
        }
    }
    
    /**
     * 从用户操作推断反馈类型
     * @param userAction 用户操作
     * @param explicitRating 显式评分
     * @return 推断的反馈类型
     */
    private func inferFeedbackType(
        from userAction: UserInterestTracker.UserInterestModel.InteractionRecord.InteractionType,
        explicitRating: Int? = nil
    ) -> FeedbackType {
        // 如果有显式评分，优先使用评分判断
        if let rating = explicitRating {
            if rating >= 4 {
                return .positive
            } else if rating >= 2 {
                return .neutral
            } else {
                return .negative
            }
        }
        
        // 根据用户操作推断
        switch userAction {
        case .like, .bookmark, .share:
            return .positive
        case .comment:
            return .neutral  // 评论可能是任何情绪，默认为中性
        case .view:
            return .neutral  // 仅查看，默认为中性
        }
    }
    
    /**
     * 分析反馈数据
     * @return 反馈分析结果
     */
    func analyzeFeedback() -> FeedbackAnalysisResult {
        var result = FeedbackAnalysisResult()
        
        // 如果没有足够的反馈数据，返回默认结果
        if feedbackRecords.isEmpty {
            return result
        }
        
        // 计算总体满意度
        var totalSatisfactionScore = 0.0
        var totalWeight = 0.0
        
        // 初始化维度得分、人物表现、情境表现和期望表现的计数器
        var dimensionScores: [FeedbackDimension: (total: Double, count: Int)] = [:]
        var figurePerformance: [String: (total: Double, count: Int)] = [:]
        var situationPerformance: [String: (total: Double, count: Int)] = [:]
        var expectationPerformance: [String: (total: Double, count: Int)] = [:]
        
        // 分析每条反馈记录
        for record in feedbackRecords {
            // 计算反馈权重
            var weight = 0.0
            switch record.userAction {
            case .like:
                weight = FeedbackWeights.like
            case .bookmark:
                weight = FeedbackWeights.bookmark
            case .comment:
                weight = FeedbackWeights.comment
            case .share:
                weight = FeedbackWeights.share
            case .view:
                weight = FeedbackWeights.view
            }
            
            // 如果有显式评分，增加权重
            if record.explicitRating != nil {
                weight += FeedbackWeights.explicitRating
            }
            
            // 计算满意度得分
            var satisfactionScore = 0.0
            switch record.feedbackType {
            case .positive:
                satisfactionScore = 1.0
            case .neutral:
                satisfactionScore = 0.5
            case .negative:
                satisfactionScore = 0.0
            }
            
            // 如果有显式评分，融合评分
            if let rating = record.explicitRating {
                let normalizedRating = Double(rating - 1) / 4.0  // 将1-5转换为0-1
                satisfactionScore = (satisfactionScore + normalizedRating) / 2.0
            }
            
            // 累加总体满意度
            totalSatisfactionScore += satisfactionScore * weight
            totalWeight += weight
            
            // 更新维度得分
            if let dimension = record.feedbackDimension {
                let currentScore = dimensionScores[dimension]?.total ?? 0.0
                let currentCount = dimensionScores[dimension]?.count ?? 0
                dimensionScores[dimension] = (total: currentScore + satisfactionScore, count: currentCount + 1)
            }
            
            // 更新人物表现
            let figureScore = figurePerformance[record.figure]?.total ?? 0.0
            let figureCount = figurePerformance[record.figure]?.count ?? 0
            figurePerformance[record.figure] = (total: figureScore + satisfactionScore, count: figureCount + 1)
            
            // 更新情境表现
            let situationScore = situationPerformance[record.situation]?.total ?? 0.0
            let situationCount = situationPerformance[record.situation]?.count ?? 0
            situationPerformance[record.situation] = (total: situationScore + satisfactionScore, count: situationCount + 1)
            
            // 更新期望表现
            let expectationScore = expectationPerformance[record.expectation]?.total ?? 0.0
            let expectationCount = expectationPerformance[record.expectation]?.count ?? 0
            expectationPerformance[record.expectation] = (total: expectationScore + satisfactionScore, count: expectationCount + 1)
        }
        
        // 计算总体满意度
        if totalWeight > 0 {
            result.overallSatisfaction = totalSatisfactionScore / totalWeight
        }
        
        // 计算各维度平均得分
        for (dimension, data) in dimensionScores {
            if data.count > 0 {
                result.dimensionScores[dimension] = data.total / Double(data.count)
            }
        }
        
        // 计算各历史人物平均表现
        for (figure, data) in figurePerformance {
            if data.count > 0 {
                result.figurePerformance[figure] = data.total / Double(data.count)
            }
        }
        
        // 计算各情境平均表现
        for (situation, data) in situationPerformance {
            if data.count > 0 {
                result.situationPerformance[situation] = data.total / Double(data.count)
            }
        }
        
        // 计算各期望平均表现
        for (expectation, data) in expectationPerformance {
            if data.count > 0 {
                result.expectationPerformance[expectation] = data.total / Double(data.count)
            }
        }
        
        // 识别需要改进的维度（得分低于0.6的维度）
        result.improvementAreas = result.dimensionScores
            .filter { $0.value < 0.6 }
            .sorted { $0.value < $1.value }
            .map { $0.key }
        
        // 推荐表现最好的历史人物（得分高于0.7的人物）
        result.recommendedFigures = result.figurePerformance
            .filter { $0.value > 0.7 }
            .sorted { $0.value > $1.value }
            .map { $0.key }
        
        return result
    }
    
    /**
     * 获取特定情境和期望的最佳历史人物
     * @param situation 情境
     * @param expectation 期望
     * @return 最佳历史人物名称
     */
    func getBestFigureForSituationExpectation(situation: String, expectation: String) -> String? {
        // 过滤出匹配情境和期望的反馈记录
        let relevantRecords = feedbackRecords.filter {
            $0.situation == situation && $0.expectation == expectation
        }
        
        if relevantRecords.isEmpty {
            return nil
        }
        
        // 计算每个历史人物的平均满意度
        var figureScores: [String: (total: Double, count: Int)] = [:]
        
        for record in relevantRecords {
            var satisfactionScore = 0.0
            switch record.feedbackType {
            case .positive:
                satisfactionScore = 1.0
            case .neutral:
                satisfactionScore = 0.5
            case .negative:
                satisfactionScore = 0.0
            }
            
            if let rating = record.explicitRating {
                let normalizedRating = Double(rating - 1) / 4.0  // 将1-5转换为0-1
                satisfactionScore = (satisfactionScore + normalizedRating) / 2.0
            }
            
            let currentScore = figureScores[record.figure]?.total ?? 0.0
            let currentCount = figureScores[record.figure]?.count ?? 0
            figureScores[record.figure] = (total: currentScore + satisfactionScore, count: currentCount + 1)
        }
        
        // 计算平均分数并找出最高分的历史人物
        var bestFigure: String? = nil
        var highestScore = 0.0
        
        for (figure, data) in figureScores {
            if data.count > 0 {
                let averageScore = data.total / Double(data.count)
                if averageScore > highestScore {
                    highestScore = averageScore
                    bestFigure = figure
                }
            }
        }
        
        return bestFigure
    }
    
    /**
     * 获取用户反馈的主要关注维度
     * @return 主要关注维度及其频率
     */
    func getPrimaryFeedbackDimensions() -> [(FeedbackDimension, Int)] {
        var dimensionCounts: [FeedbackDimension: Int] = [:]
        
        for record in feedbackRecords {
            if let dimension = record.feedbackDimension {
                dimensionCounts[dimension, default: 0] += 1
            }
        }
        
        return dimensionCounts.sorted { $0.value > $1.value }
    }
    
    /**
     * 根据反馈优化内容生成策略
     * @param situation 情境
     * @param expectation 期望
     * @return 优化建议
     */
    func optimizeContentGenerationStrategy(situation: String, expectation: String) -> ContentOptimizationSuggestion {
        var suggestion = ContentOptimizationSuggestion()
        
        // 分析反馈
        let analysisResult = analyzeFeedback()
        
        // 设置总体满意度
        suggestion.currentSatisfactionLevel = analysisResult.overallSatisfaction
        
        // 获取该情境-期望组合的最佳历史人物
        if let bestFigure = getBestFigureForSituationExpectation(situation: situation, expectation: expectation) {
            suggestion.recommendedFigure = bestFigure
        } else {
            // 如果没有足够数据，使用兴趣跟踪器的推荐
            suggestion.recommendedFigure = interestTracker.recommendFigureBasedOnInterests(
                situation: situation,
                expectation: expectation
            )
        }
        
        // 确定需要改进的内容维度
        suggestion.dimensionsToFocus = analysisResult.improvementAreas
        
        // 确定内容层次优先级
        let userInterests = interestTracker.analyzeInterestPatterns()
        
        // 根据用户兴趣多样性确定内容层次
        var contentLayers: Set<ContentGenerationStrategy.ContentLayer> = [.surface, .contextual]
        
        // 如果用户有明确的情境偏好，添加情境层
        if userInterests.situationDiversity < 0.5 && userInterests.dominantSituation != nil {
            contentLayers.insert(.contextual)
        }
        
        // 如果用户有关键词兴趣，添加个性化层
        if !userInterests.topKeywords.isEmpty {
            contentLayers.insert(.personalized)
        }
        
        // 如果用户倾向于互动（评论、分享），添加互动层
        if userInterests.dominantInteractionType == .comment || userInterests.dominantInteractionType == .share {
            contentLayers.insert(.interactive)
        }
        
        // 如果用户期望是"共鸣与安慰"或"被看见"，添加情感层
        if userInterests.dominantExpectation == "共鸣与安慰" || userInterests.dominantExpectation == "被看见" {
            contentLayers.insert(.emotional)
        }
        
        suggestion.recommendedContentLayers = contentLayers
        
        // 根据分析结果确定内容风格
        if let recommendedFigure = suggestion.recommendedFigure {
            suggestion.recommendedContentStyle = ContentGenerationStrategy.shared.styleForFigure(recommendedFigure)
        }
        
        return suggestion
    }
    
    // 内容优化建议结构
    struct ContentOptimizationSuggestion {
        var currentSatisfactionLevel: Double = 0.0
        var recommendedFigure: String?
        var dimensionsToFocus: [FeedbackDimension] = []
        var recommendedContentLayers: Set<ContentGenerationStrategy.ContentLayer> = [.surface, .contextual]
        var recommendedContentStyle: ContentGenerationStrategy.ContentStyle?
    }
    
    // MARK: - 私有方法
    
    /**
     * 保存反馈记录到本地存储
     */
    private func saveFeedbackRecords() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(feedbackRecords)
            UserDefaults.standard.set(data, forKey: "feedbackRecords")
        } catch {
            #if DEBUG
            debugLog("无法保存反馈记录: \(error.localizedDescription)")
            #endif
        }
    }
    
    /**
     * 从本地存储加载反馈记录
     */
    private func loadFeedbackRecords() {
        if let data = UserDefaults.standard.data(forKey: "feedbackRecords") {
            do {
                let decoder = JSONDecoder()
                feedbackRecords = try decoder.decode([FeedbackRecord].self, from: data)
            } catch {
                #if DEBUG
                debugLog("无法加载反馈记录: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // 私有初始化方法，确保单例模式
    private init() {
        loadFeedbackRecords()
    }
} 