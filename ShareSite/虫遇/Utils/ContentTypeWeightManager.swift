import Foundation

/**
 * 内容类型权重管理器
 * 管理不同内容类型的权重，用于一键生成时的内容类型分配
 */
class ContentTypeWeightManager {
    // 单例模式
    static let shared = ContentTypeWeightManager()
    
    // 内容类型权重映射表
    private var contentTypeWeights: [String: Double] = [:]
    
    // 最后一次降权时间记录
    private var lastReducedDate: [String: Date] = [:]
    
    // 权重自动恢复周期（180天）
    private let weightRecoveryCycleDays: Double = 180
    
    // 最低权重限制
    private let minimumWeight: Double = 0.0
    
    // 是否正在生成内容的标志
    private var isGeneratingContent: Bool = false
    
    private init() {
        loadWeights()
        
        // 添加调试日志，显示初始权重
        print("📊 ContentTypeWeightManager初始化，当前权重设置：")
        for type in ContentGeneratorService.ContentType.allCases {
            let typeKey = type.rawValue
            let weight = contentTypeWeights[typeKey] ?? 1.0
            print("  - \(typeKey): \(weight)")
        }
        
        // 只有在不生成内容时才检查权重恢复
        if !isGeneratingContent {
            checkWeightRecovery()
        }
    }
    
    /**
     * 设置内容生成状态
     * 在生成内容期间暂时禁用权重恢复检查
     */
    func setGeneratingContent(_ generating: Bool) {
        isGeneratingContent = generating
        print("📊 ContentTypeWeightManager: 内容生成状态设置为 \(generating ? "生成中" : "未生成")")
    }
    
    /**
     * 减少内容类型权重
     * @param type 要减少权重的内容类型
     */
    func reduceContentType(_ type: ContentGeneratorService.ContentType) {
        let typeKey = type.rawValue
        
        // 获取当前权重，默认为1.0
        let currentWeight = contentTypeWeights[typeKey] ?? 1.0
        
        // 将权重降低50%，但不低于最低限制
        let newWeight = max(currentWeight * 0.5, minimumWeight)
        
        // 更新权重
        contentTypeWeights[typeKey] = newWeight
        
        // 记录降权时间
        lastReducedDate[typeKey] = Date()
        
        // 保存更新后的权重
        saveWeights()
        
        print("📉 已降低内容类型[\(typeKey)]的权重: \(currentWeight) -> \(newWeight)")
        
        // 如果权重非常低但不为0，直接降到0（加速测试）
        if newWeight < 0.1 && newWeight > 0 {
            print("⚠️ 权重已经非常低，直接设置为0进行测试")
            contentTypeWeights[typeKey] = 0.0
            saveWeights()
        }
        
        // 打印所有权重，方便调试
        printAllWeights()
    }
    
    /**
     * 获取内容类型权重
     * @param type 内容类型
     * @return 该类型的当前权重
     */
    func getWeight(for type: ContentGeneratorService.ContentType) -> Double {
        let weight = contentTypeWeights[type.rawValue] ?? 1.0
        return weight
    }
    
    /**
     * 获取内容类型权重百分比
     * 用于UI显示，将权重转换为百分比值
     * @param type 内容类型
     * @return 百分比值（0-100）
     */
    func getWeightPercentage(for type: ContentGeneratorService.ContentType) -> Double {
        let typeKey = type.rawValue
        
        // 检查该类型是否存在于权重映射中
        guard contentTypeWeights.keys.contains(typeKey) else {
            // 如果不存在，返回100%
            return 100.0
        }
        
        // 获取权重并转换为百分比
        let weight = getWeight(for: type)
        return weight * 100
    }
    
    /**
     * 重置内容类型权重
     * @param type 要重置的内容类型，如果为nil则重置所有类型
     */
    func resetWeight(for type: ContentGeneratorService.ContentType? = nil) {
        if let type = type {
            // 重置特定类型
            contentTypeWeights.removeValue(forKey: type.rawValue)
            lastReducedDate.removeValue(forKey: type.rawValue)
            print("🔄 已重置内容类型[\(type.rawValue)]的权重为默认值")
        } else {
            // 重置所有类型
            contentTypeWeights.removeAll()
            lastReducedDate.removeAll()
            print("🔄 已重置所有内容类型的权重为默认值")
        }
        
        saveWeights()
    }
    
    /**
     * 强制设置内容类型权重为0（用于测试）
     * @param type 要设置权重为0的内容类型
     */
    func forceZeroWeight(for type: ContentGeneratorService.ContentType) {
        let typeKey = type.rawValue
        
        // 获取当前权重，默认为1.0
        let currentWeight = contentTypeWeights[typeKey] ?? 1.0
        
        // 直接设置为0
        contentTypeWeights[typeKey] = 0.0
        
        // 记录降权时间
        lastReducedDate[typeKey] = Date()
        
        // 保存更新后的权重
        saveWeights()
        
        print("⚠️ 测试：已强制将内容类型[\(typeKey)]的权重从 \(currentWeight) 设置为 0.0")
    }
    
    /**
     * 检查是否需要基于时间自动恢复权重
     */
    private func checkWeightRecovery() {
        let now = Date()
        var hasChanges = false
        
        for (typeKey, reducedDate) in lastReducedDate {
            // 计算距离上次降权的天数
            let daysSinceReduced = now.timeIntervalSince(reducedDate) / (24 * 60 * 60)
            
            if daysSinceReduced >= weightRecoveryCycleDays {
                // 超过恢复周期，重置权重
                contentTypeWeights.removeValue(forKey: typeKey)
                lastReducedDate.removeValue(forKey: typeKey)
                hasChanges = true
                print("⏱️ 内容类型[\(typeKey)]的权重已自动恢复 (已过\(Int(daysSinceReduced))天)")
            } else if daysSinceReduced >= weightRecoveryCycleDays / 2 {
                // 过半恢复周期，权重部分恢复
                if let currentWeight = contentTypeWeights[typeKey], currentWeight < 1.0 {
                    // 逐渐恢复权重，但不超过1.0
                    let recoveryRatio = daysSinceReduced / weightRecoveryCycleDays
                    let newWeight = min(1.0, currentWeight + (1.0 - currentWeight) * recoveryRatio)
                    contentTypeWeights[typeKey] = newWeight
                    hasChanges = true
                    print("⏱️ 内容类型[\(typeKey)]的权重部分恢复: \(currentWeight) -> \(newWeight)")
                }
            }
        }
        
        // 如果有变更，保存更新
        if hasChanges {
            saveWeights()
        }
    }
    
    /**
     * 保存权重到用户默认设置
     */
    private func saveWeights() {
        UserDefaults.standard.set(contentTypeWeights, forKey: "contentTypeWeights")
        
        // 保存最后降权时间
        if let encodedData = try? JSONEncoder().encode(lastReducedDate) {
            UserDefaults.standard.set(encodedData, forKey: "contentTypeLastReducedDates")
        }
        
        // 强制立即同步
        UserDefaults.standard.synchronize()
        
        print("💾 权重已保存到UserDefaults")
    }
    
    /**
     * 从用户默认设置加载权重
     */
    private func loadWeights() {
        // 加载权重
        if let savedWeights = UserDefaults.standard.dictionary(forKey: "contentTypeWeights") as? [String: Double] {
            contentTypeWeights = savedWeights
            print("📂 从UserDefaults加载权重成功: \(contentTypeWeights)")
        } else {
            print("⚠️ 未找到保存的权重数据，使用默认权重")
        }
        
        // 加载最后降权时间
        if let savedDatesData = UserDefaults.standard.data(forKey: "contentTypeLastReducedDates"),
           let savedDates = try? JSONDecoder().decode([String: Date].self, from: savedDatesData) {
            lastReducedDate = savedDates
            print("📂 从UserDefaults加载降权时间成功")
        } else {
            print("⚠️ 未找到保存的降权时间数据")
        }
    }
    
    /**
     * 获取所有已减少权重的内容类型及其当前权重
     * @return 类型及权重的字典
     */
    func getAllReducedContentTypes() -> [String: Double] {
        return contentTypeWeights.filter { $0.value < 1.0 }
    }
    
    /**
     * 根据权重计算内容类型的分配数量
     * @param totalCount 总内容数量
     * @param types 要分配的内容类型数组
     * @return 每种类型应生成的内容数量
     */
    func calculateTypeDistribution(totalCount: Int, types: [ContentGeneratorService.ContentType]) -> [ContentGeneratorService.ContentType: Int] {
        var distribution: [ContentGeneratorService.ContentType: Int] = [:]
        
        // 首先过滤掉权重为0的类型
        let validTypes = types.filter { getWeight(for: $0) > 0 }
        
        // 如果没有有效类型，将所有类型权重临时设为1.0并继续
        if validTypes.isEmpty {
            print("⚠️ 警告：所有内容类型权重都为0，将临时使用默认权重进行内容分配")
            // 创建一个临时的有效类型数组，包含所有原始类型
            var tempTypes: [ContentGeneratorService.ContentType] = []
            var tempWeights: [ContentGeneratorService.ContentType: Double] = [:]
            
            // 为每个类型赋予临时权重1.0
            for type in types {
                tempTypes.append(type)
                tempWeights[type] = 1.0
            }
            
            // 使用临时权重计算分配
            var tempDistribution: [ContentGeneratorService.ContentType: Int] = [:]
            let _ = Double(tempTypes.count) // 用_替换totalWeight
            
            // 计算平均分配，确保总和为totalCount
            let baseCount = totalCount / tempTypes.count
            let remainder = totalCount % tempTypes.count
            
            for (index, type) in tempTypes.enumerated() {
                if index < remainder {
                    tempDistribution[type] = baseCount + 1
                } else {
                    tempDistribution[type] = baseCount
                }
            }
            
            return tempDistribution
        }
        
        // 计算总权重
        var totalWeight: Double = 0
        for type in validTypes {
            totalWeight += getWeight(for: type)
        }
        
        // 第一步：计算精确的小数分配
        var exactDistribution: [ContentGeneratorService.ContentType: Double] = [:]
        for type in validTypes {
            let typeWeight = getWeight(for: type)
            let weightRatio = typeWeight / totalWeight
            let exactCount = Double(totalCount) * weightRatio
            exactDistribution[type] = exactCount
        }
        
        // 定义最大分配数量 - 避免单个类型获得过多帖子
        // 总数12篇，4种类型，理想情况是每种3篇，所以最大分配数设为6篇
        let maxAllocationPerType: Int
        if validTypes.count == 1 {
            // 如果只有一种有效类型，允许分配所有数量
            maxAllocationPerType = totalCount
            print("⚠️ 警告：只有一种内容类型有权重，将分配所有\(totalCount)篇内容给该类型")
        } else {
            maxAllocationPerType = min(6, totalCount / validTypes.count + 3)
        }
        
        // 第二步：初始分配，限制单个类型最大值
        var allocatedCount = 0
        var fractionalParts: [(type: ContentGeneratorService.ContentType, fraction: Double)] = []
        
        for type in validTypes {
            guard let exactCount = exactDistribution[type] else { continue }
            
            // 限制最大分配数，即使权重很高
            let cappedExactCount = min(Double(maxAllocationPerType), exactCount)
            
            // 对于非常小的权重，可能会分配0篇
            let intCount = Int(cappedExactCount)
            let fraction = cappedExactCount - Double(intCount)
            
            distribution[type] = intCount
            allocatedCount += intCount
            
            // 记录小数部分和对应类型，用于后续分配
            fractionalParts.append((type, fraction))
        }
        
        // 第三步：根据小数部分大小，分配剩余的帖子，确保总和等于totalCount
        let remainingCount = totalCount - allocatedCount
        
        if remainingCount > 0 {
            // 按小数部分从大到小排序
            fractionalParts.sort { $0.fraction > $1.fraction }
            
            // 首先计算每个类型还可以分配多少
            var availableSpace: [(type: ContentGeneratorService.ContentType, space: Int)] = []
            for type in validTypes {
                let currentCount = distribution[type] ?? 0
                let availableCount = maxAllocationPerType - currentCount
                if availableCount > 0 {
                    availableSpace.append((type, availableCount))
                }
            }
            
            // 按小数部分分配，但考虑最大限制
            var remainingToDistribute = remainingCount
            var index = 0
            
            // 优先分配给小数部分大的类型，但尊重最大限制
            while remainingToDistribute > 0 && index < fractionalParts.count {
                let type = fractionalParts[index].type
                if let spaceIndex = availableSpace.firstIndex(where: { $0.type == type }),
                   availableSpace[spaceIndex].space > 0 {
                    // 分配一个帖子
                    distribution[type] = (distribution[type] ?? 0) + 1
                    remainingToDistribute -= 1
                    availableSpace[spaceIndex].space -= 1
                }
                index = (index + 1) % fractionalParts.count
            }
            
            // 如果还有剩余，则均匀分配
            if remainingToDistribute > 0 {
                // 按权重从低到高排序类型
                let sortedTypes = validTypes.sorted { getWeight(for: $0) > getWeight(for: $1) }
                for type in sortedTypes {
                    if remainingToDistribute <= 0 { break }
                    if let spaceIndex = availableSpace.firstIndex(where: { $0.type == type }),
                       availableSpace[spaceIndex].space > 0 {
                        let addCount = min(remainingToDistribute, availableSpace[spaceIndex].space)
                        distribution[type] = (distribution[type] ?? 0) + addCount
                        remainingToDistribute -= addCount
                    }
                }
            }
        }
        
        // 最后检查确保总数正确
        let finalTotal = distribution.values.reduce(0, +)
        if finalTotal != totalCount {
            // 创建类型数组，按权重从高到低排序
            let sortedTypes = validTypes.sorted { getWeight(for: $0) > getWeight(for: $1) }
            
            if finalTotal < totalCount {
                // 需要增加帖子数量，缺少(totalCount - finalTotal)篇
                var remainingToAdd = totalCount - finalTotal
                
                // 首先尝试按照权重顺序分配，但确保不超过最大限制
                while remainingToAdd > 0 {
                    var addedAny = false
                    
                    for type in sortedTypes {
                        let currentCount = distribution[type] ?? 0
                        // 确保不超过最大限制
                        if currentCount < maxAllocationPerType && remainingToAdd > 0 {
                            distribution[type] = currentCount + 1
                            remainingToAdd -= 1
                            addedAny = true
                            
                            // 如果已经没有剩余，跳出循环
                            if remainingToAdd == 0 {
                                break
                            }
                        }
                    }
                    
                    // 如果一轮中没有添加任何帖子，说明所有类型都已达到最大限制
                    // 这种情况下，我们需要放宽最大限制
                    if !addedAny {
                        print("⚠️ 警告：所有类型都已达到最大限制\(maxAllocationPerType)，无法满足总数\(totalCount)要求")
                        // 强制分配到权重最高的类型
                        if let highestType = sortedTypes.first {
                            distribution[highestType] = (distribution[highestType] ?? 0) + remainingToAdd
                            break
                        }
                    }
                }
            } else {
                // 需要减少帖子数量，超出(finalTotal - totalCount)篇
                var remainingToRemove = finalTotal - totalCount
                
                // 首先尝试从权重最低的类型开始减少
                for type in sortedTypes.reversed() {
                    if remainingToRemove <= 0 {
                        break
                    }
                    
                    let currentCount = distribution[type] ?? 0
                    // 确保至少保留1篇
                    if currentCount > 1 {
                        let canRemove = min(currentCount - 1, remainingToRemove)
                        distribution[type] = currentCount - canRemove
                        remainingToRemove -= canRemove
                    }
                }
                
                // 如果还需要继续减少，开始第二轮，允许减到0
                if remainingToRemove > 0 {
                    for type in sortedTypes.reversed() {
                        if remainingToRemove <= 0 {
                            break
                        }
                        
                        let currentCount = distribution[type] ?? 0
                        let canRemove = min(currentCount, remainingToRemove)
                        distribution[type] = currentCount - canRemove
                        remainingToRemove -= canRemove
                    }
                }
            }
            
            // 最终验证总数是否正确
            let verifiedTotal = distribution.values.reduce(0, +)
            if verifiedTotal != totalCount {
                print("⚠️ 警告：调整后总数仍不正确，预期\(totalCount)，实际\(verifiedTotal)")
            }
        }
        
        // 确保所有原始类型都有对应的条目，权重为0的类型显式设置为0篇
        for type in types {
            if getWeight(for: type) <= 0 && distribution[type] == nil {
                distribution[type] = 0
            }
        }
        
        return distribution
    }
    
    /**
     * 设置内容类型权重
     * @param weight 要设置的权重值
     * @param type 要设置权重的内容类型
     */
    func setWeight(_ weight: Double, for type: ContentGeneratorService.ContentType) {
        let typeKey = type.rawValue
        
        // 获取当前权重，默认为1.0
        let currentWeight = contentTypeWeights[typeKey] ?? 1.0
        
        // 设置新权重
        contentTypeWeights[typeKey] = weight
        
        // 记录设置时间
        lastReducedDate[typeKey] = Date()
        
        // 保存更新后的权重
        saveWeights()
        
        print("📊 已设置内容类型[\(typeKey)]的权重: \(currentWeight) -> \(weight)")
    }
    
    /**
     * 打印所有权重，用于调试
     */
    func printAllWeights() {
        print("📊 当前所有内容类型权重：")
        for type in ContentGeneratorService.ContentType.allCases {
            let weight = getWeight(for: type)
            print("  - \(type.rawValue): \(weight)")
        }
    }
} 