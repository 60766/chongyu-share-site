import Foundation
import Combine

/**
 * 用户兴趣跟踪器
 * 记录和分析用户的兴趣偏好，提供个性化内容推荐
 */
class UserInterestTracker {
    // 单例实例
    static let shared = UserInterestTracker()
    
    // 用户兴趣模型
    private(set) var interestModel = UserInterestModel()
    
    // 发布者，用于通知兴趣变化
    private let interestChangeSubject = PassthroughSubject<UserInterestModel, Never>()
    var interestChangePublisher: AnyPublisher<UserInterestModel, Never> {
        return interestChangeSubject.eraseToAnyPublisher()
    }
    
    // 用户兴趣模型结构
    struct UserInterestModel: Codable {
        // 情境偏好计数
        var situationCounts: [String: Int] = [
            "寻找答案": 0,
            "做决定": 0,
            "需要灵感": 0,
            "思考人生": 0
        ]
        
        // 期望偏好计数
        var expectationCounts: [String: Int] = [
            "被看见": 0,
            "新视角": 0,
            "实用建议": 0,
            "共鸣与安慰": 0
        ]
        
        // 历史人物偏好计数
        var figureCounts: [String: Int] = [
            "爱因斯坦": 0,
            "莎士比亚": 0,
            "达芬奇": 0,
            "孔子": 0,
            "牛顿": 0,
            "李白": 0
        ]
        
        // 关键词频率统计
        var keywordFrequency: [String: Int] = [:]
        
        // 用户互动记录
        var interactionHistory: [InteractionRecord] = []
        
        // 互动记录结构
        struct InteractionRecord: Codable {
            let timestamp: Date
            let situation: String
            let expectation: String
            let figure: String
            let keyword: String?
            let interactionType: InteractionType
            
            enum InteractionType: String, Codable {
                case view       // 查看内容
                case like       // 点赞
                case bookmark   // 收藏
                case comment    // 评论
                case share      // 分享
            }
        }
    }
    
    /**
     * 记录用户选择的情境和期望
     * @param situation 用户选择的情境
     * @param expectation 用户选择的期望
     */
    func trackSituationExpectation(situation: String, expectation: String) {
        // 更新情境计数
        if var count = interestModel.situationCounts[situation] {
            count += 1
            interestModel.situationCounts[situation] = count
        }
        
        // 更新期望计数
        if var count = interestModel.expectationCounts[expectation] {
            count += 1
            interestModel.expectationCounts[expectation] = count
        }
        
        // 保存更新并通知变化
        saveInterestModel()
        interestChangeSubject.send(interestModel)
    }
    
    /**
     * 记录用户与历史人物的互动
     * @param figure 历史人物名称
     * @param interactionType 互动类型
     * @param situation 情境
     * @param expectation 期望
     * @param keyword 关键词
     */
    func trackFigureInteraction(
        figure: String,
        interactionType: UserInterestModel.InteractionRecord.InteractionType,
        situation: String,
        expectation: String,
        keyword: String? = nil
    ) {
        // 更新历史人物计数
        if var count = interestModel.figureCounts[figure] {
            // 根据互动类型给予不同权重
            switch interactionType {
            case .view:
                count += 1
            case .like:
                count += 2
            case .bookmark:
                count += 3
            case .comment:
                count += 2
            case .share:
                count += 3
            }
            interestModel.figureCounts[figure] = count
        }
        
        // 记录关键词
        if let keyword = keyword, !keyword.isEmpty {
            let normalizedKeyword = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            interestModel.keywordFrequency[normalizedKeyword] = (interestModel.keywordFrequency[normalizedKeyword] ?? 0) + 1
        }
        
        // 添加互动记录
        let record = UserInterestModel.InteractionRecord(
            timestamp: Date(),
            situation: situation,
            expectation: expectation,
            figure: figure,
            keyword: keyword,
            interactionType: interactionType
        )
        interestModel.interactionHistory.append(record)
        
        // 保持历史记录在合理范围内
        if interestModel.interactionHistory.count > 100 {
            interestModel.interactionHistory.removeFirst(interestModel.interactionHistory.count - 100)
        }
        
        // 保存更新并通知变化
        saveInterestModel()
        interestChangeSubject.send(interestModel)
    }
    
    /**
     * 获取用户最常使用的情境
     * @return 最常用情境
     */
    func getMostFrequentSituation() -> String? {
        return interestModel.situationCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /**
     * 获取用户最常使用的期望
     * @return 最常用期望
     */
    func getMostFrequentExpectation() -> String? {
        return interestModel.expectationCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /**
     * 获取用户最喜欢的历史人物
     * @return 最喜欢的历史人物
     */
    func getFavoriteFigure() -> String? {
        return interestModel.figureCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /**
     * 获取用户最常用的关键词
     * @param limit 返回数量限制
     * @return 最常用关键词列表
     */
    func getTopKeywords(limit: Int = 5) -> [String] {
        let sortedKeywords = interestModel.keywordFrequency.sorted(by: { $0.value > $1.value })
        return sortedKeywords.prefix(limit).map { $0.key }
    }
    
    /**
     * 基于用户兴趣推荐历史人物
     * @param situation 当前情境
     * @param expectation 当前期望
     * @return 推荐的历史人物名称
     */
    func recommendFigureBasedOnInterests(situation: String, expectation: String) -> String {
        // 获取历史人物认知模型
        let cognitionModel = HistoricalFigureCognitionModel.shared
        let historicalFigures = cognitionModel.getHistoricalFigures()
        
        // 计算每个历史人物的推荐分数
        var figureScores: [String: Double] = [:]
        
        for figure in historicalFigures {
            var score: Double = 0
            
            // 基于历史互动的得分
            if let count = interestModel.figureCounts[figure] {
                score += Double(count) * 0.5
            }
            
            // 基于情境-期望匹配的得分
            let figureIndex = historicalFigures.firstIndex(of: figure) ?? 0
            let matchingFigureIndex = cognitionModel.selectOptimalFigureForSituation(
                situation,
                expectation: expectation
            )
            
            if figureIndex == matchingFigureIndex {
                score += 5.0
            }
            
            // 基于最近互动的得分
            let recentInteractions = interestModel.interactionHistory.suffix(10)
            for interaction in recentInteractions where interaction.figure == figure {
                score += 0.3
            }
            
            figureScores[figure] = score
        }
        
        // 返回得分最高的历史人物
        if let topFigure = figureScores.max(by: { $0.value < $1.value })?.key {
            return topFigure
        }
        
        // 如果没有足够数据，返回默认推荐
        return historicalFigures[cognitionModel.selectOptimalFigureForSituation(situation, expectation: expectation)]
    }
    
    /**
     * 分析用户兴趣模式
     * @return 兴趣分析结果
     */
    func analyzeInterestPatterns() -> InterestAnalysisResult {
        var result = InterestAnalysisResult()
        
        // 分析情境偏好
        if let mostFrequentSituation = getMostFrequentSituation(),
           let count = interestModel.situationCounts[mostFrequentSituation],
           count > 0 {
            result.dominantSituation = mostFrequentSituation
            
            // 计算情境多样性
            let totalSituations = interestModel.situationCounts.values.reduce(0, +)
            if totalSituations > 0 {
                let dominance = Double(count) / Double(totalSituations)
                result.situationDiversity = 1.0 - dominance
            }
        }
        
        // 分析期望偏好
        if let mostFrequentExpectation = getMostFrequentExpectation(),
           let count = interestModel.expectationCounts[mostFrequentExpectation],
           count > 0 {
            result.dominantExpectation = mostFrequentExpectation
            
            // 计算期望多样性
            let totalExpectations = interestModel.expectationCounts.values.reduce(0, +)
            if totalExpectations > 0 {
                let dominance = Double(count) / Double(totalExpectations)
                result.expectationDiversity = 1.0 - dominance
            }
        }
        
        // 分析历史人物偏好
        if let favoriteFigure = getFavoriteFigure(),
           let count = interestModel.figureCounts[favoriteFigure],
           count > 0 {
            result.favoriteFigure = favoriteFigure
            
            // 计算历史人物多样性
            let totalFigures = interestModel.figureCounts.values.reduce(0, +)
            if totalFigures > 0 {
                let dominance = Double(count) / Double(totalFigures)
                result.figureDiversity = 1.0 - dominance
            }
        }
        
        // 分析关键词偏好
        result.topKeywords = getTopKeywords(limit: 5)
        
        // 分析互动模式
        let interactionCounts = interestModel.interactionHistory.reduce(into: [UserInterestModel.InteractionRecord.InteractionType: Int]()) { counts, record in
            counts[record.interactionType, default: 0] += 1
        }
        
        if let (dominantInteraction, _) = interactionCounts.max(by: { $0.value < $1.value }) {
            result.dominantInteractionType = dominantInteraction
        }
        
        return result
    }
    
    // 兴趣分析结果结构
    struct InterestAnalysisResult {
        var dominantSituation: String?
        var dominantExpectation: String?
        var favoriteFigure: String?
        var topKeywords: [String] = []
        var dominantInteractionType: UserInterestModel.InteractionRecord.InteractionType?
        var situationDiversity: Double = 0.0  // 0-1，越高表示越多样化
        var expectationDiversity: Double = 0.0
        var figureDiversity: Double = 0.0
    }
    
    // MARK: - 私有方法
    
    /**
     * 保存用户兴趣模型到本地存储
     */
    private func saveInterestModel() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(interestModel)
            UserDefaults.standard.set(data, forKey: "userInterestModel")
        } catch {
            print("无法保存用户兴趣模型: \(error.localizedDescription)")
        }
    }
    
    /**
     * 从本地存储加载用户兴趣模型
     */
    private func loadInterestModel() {
        if let data = UserDefaults.standard.data(forKey: "userInterestModel") {
            do {
                let decoder = JSONDecoder()
                interestModel = try decoder.decode(UserInterestModel.self, from: data)
            } catch {
                print("无法加载用户兴趣模型: \(error.localizedDescription)")
            }
        }
    }
    
    // 私有初始化方法，确保单例模式
    private init() {
        loadInterestModel()
    }
} 