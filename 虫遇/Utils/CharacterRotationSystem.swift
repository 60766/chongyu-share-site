import Foundation

/**
 * 角色轮换系统
 * 确保各角色获得平均的曝光机会，并为未来的关注/不喜欢功能预留接口
 */
class CharacterRotationSystem {
    // 单例模式
    static let shared = CharacterRotationSystem()
    private var followStatusObserver: NSObjectProtocol?
    
    private init() {
        loadRotationState()
        observeFollowStatusChanges()
    }
    
    // 角色使用计数
    private var usageCount: [String: Int] = [:]
    // 上次使用时间
    private var lastUsedTime: [String: Date] = [:]
    // 类型使用计数（确保各类型角色均衡出现）
    private var typeUsageCount: [CharacterSystem.CharacterType: Int] = [:]
    // 最近使用的角色ID（用于冷却期判断）
    private var recentlyUsedCharacterIds: [String] = []
    // 最大冷却记录数量
    private let maxRecentlyUsedCount = 20
    // 每次生成中当前已选角色（防止单次生成中重复）
    private var currentSelectionIds: Set<String> = []
    
    // 严格轮换模式下的状态跟踪
    // 当前周期中已使用过的角色ID
    private var currentCycleUsedIds: Set<String> = []
    // 全部角色ID集合（缓存，避免重复获取）
    private var allCharacterIds: Set<String> = []
    // 当前周期编号
    private var currentCycleNumber: Int = 1
    // 关注优先模式的参数配置
    private let preferenceFavoriteRatio: Double = 0.7     // 关注角色目标占比
    private let preferenceMinimumExplorationCount = 1     // 至少探索1个角色（若有）
    
    // 系统模式枚举
    enum DistributionMode {
        case equal           // 均等分配模式（基于使用频率平衡）
        case strictRotation  // 严格轮换模式（确保所有角色都展示一遍后再重复）
        case preferenceBase  // 关注优先模式（关注的角色优先出现）
    }
    
    // 当前模式，默认为均等分配
    private(set) var currentMode: DistributionMode = .equal
    
    // 用户偏好（第二阶段使用）
    private var userFavorites: Set<String> = []
    private var userDislikes: Set<String> = []
    
    // MARK: - 状态管理
    
    /**
     * 从存储加载轮换状态
     */
    private func loadRotationState() {
        if let savedUsageCount = UserDefaults.standard.dictionary(forKey: "characterUsageCount") as? [String: Int] {
            usageCount = savedUsageCount
        }
        
        // 加载上次使用时间
        if let savedLastUsedTimeData = UserDefaults.standard.data(forKey: "characterLastUsedTime"),
           let savedLastUsedTime = try? JSONDecoder().decode([String: Date].self, from: savedLastUsedTimeData) {
            lastUsedTime = savedLastUsedTime
        }
        
        // 加载最近使用的角色列表
        if let recentlyUsed = UserDefaults.standard.array(forKey: "recentlyUsedCharacters") as? [String] {
            recentlyUsedCharacterIds = recentlyUsed
        }
        
        // 加载严格轮换模式的状态
        if let cycleUsed = UserDefaults.standard.array(forKey: "currentCycleUsedCharacters") as? [String] {
            currentCycleUsedIds = Set(cycleUsed)
        }
        
        if let cycleNumber = UserDefaults.standard.object(forKey: "characterCycleNumber") as? Int {
            currentCycleNumber = cycleNumber
        }
        
        // 加载系统运行模式
        if let modeRawValue = UserDefaults.standard.string(forKey: "characterDistributionMode") {
            switch modeRawValue {
            case "strictRotation":
                currentMode = .strictRotation
            case "preferenceBase":
                currentMode = .preferenceBase
            default:
                currentMode = .equal
            }
        }
        
        // 如果有需要，加载更多状态数据
        loadUserPreferences()
        
        // 初始化全部角色ID缓存
        refreshAllCharacterIds()
    }
    
    /**
     * 刷新全部角色ID缓存
     * 当角色库更新或屏蔽设置改变时调用此方法
     * 注意：帖子生成应该应用分类过滤，所以使用CharacterModel.getAllCharacters()
     */
    func refreshAllCharacterIds() {
        // 使用CharacterModel以应用分类过滤（用于帖子生成）
        let allCharacters = CharacterModel.getAllCharacters()
        let newAllCharacterIds = Set(allCharacters.map { $0.id })
        
        // 清理 currentCycleUsedIds，移除已经被屏蔽的角色ID
        // 这样可以确保严格轮换模式只在过滤后的角色列表上工作
        currentCycleUsedIds = currentCycleUsedIds.filter { newAllCharacterIds.contains($0) }
        
        // 清理 currentSelectionIds，移除已经被屏蔽的角色ID
        currentSelectionIds = currentSelectionIds.filter { newAllCharacterIds.contains($0) }
        
        // 清理 recentlyUsedCharacterIds，移除已经被屏蔽的角色ID
        recentlyUsedCharacterIds = recentlyUsedCharacterIds.filter { newAllCharacterIds.contains($0) }
        
        // 更新缓存
        allCharacterIds = newAllCharacterIds
        
        // 如果发现之前未记录的角色，在严格轮换模式下需要重置周期
        // 或者如果当前周期已使用的角色数量超过了过滤后的角色总数，也需要重置
        if currentMode == .strictRotation {
            if !allCharacterIds.isSubset(of: currentCycleUsedIds) {
                // 有新角色加入，重置周期
                startNewCycle()
            } else if currentCycleUsedIds.count >= allCharacterIds.count {
                // 所有过滤后的角色都已使用过，重置周期
            startNewCycle()
            }
        }
    }
    
    /**
     * 将CharacterModel转换为CharacterIdentity
     */
    private func convertToCharacterIdentity(_ model: CharacterModel) -> CharacterSystem.CharacterIdentity {
        // 将CharacterCategory映射到CharacterType
        let characterType: CharacterSystem.CharacterType = {
            switch model.category {
            case .historical:
                return .historical
            case .philosopher:
                return .historical // CharacterType没有philosopher，使用historical
            case .writer:
                return .literary
            case .animeCharacter:
                return .anime
            case .gameCharacter:
                return .game
            case .filmCharacter:
                return .movie // CharacterType没有filmCharacter，使用movie
            case .mythCharacter:
                return .mythological
            case .myCreation:
                return .historical // 用户创建的角色默认使用历史人物类型
            case .all:
                return .historical
            }
        }()
        
        return CharacterSystem.CharacterIdentity(
            id: model.id,
            name: model.name,
            type: characterType,
            era: model.era,
            primaryField: model.profession,
            briefDescription: model.bio,
            avatarName: model.avatar,
            region: "",
            contentAffinities: [:],
            subtype: nil
        )
    }
    
    /**
     * 开始新的严格轮换周期
     */
    private func startNewCycle() {
        currentCycleUsedIds.removeAll()
        currentCycleNumber += 1
        #if DEBUG
        debugLog("🔄 开始角色新轮换周期 #\(currentCycleNumber)")
        #endif
        saveRotationState()
    }
    
    /**
     * 保存轮换状态
     */
    private func saveRotationState() {
        // 保存使用计数
        UserDefaults.standard.set(usageCount, forKey: "characterUsageCount")
        
        // 保存最后使用时间
        if let lastUsedTimeData = try? JSONEncoder().encode(lastUsedTime) {
            UserDefaults.standard.set(lastUsedTimeData, forKey: "characterLastUsedTime")
        }
        
        // 保存最近使用的角色
        UserDefaults.standard.set(recentlyUsedCharacterIds, forKey: "recentlyUsedCharacters")
        
        // 保存严格轮换状态
        UserDefaults.standard.set(Array(currentCycleUsedIds), forKey: "currentCycleUsedCharacters")
        UserDefaults.standard.set(currentCycleNumber, forKey: "characterCycleNumber")
        
        // 保存当前模式
        let modeString: String
        switch currentMode {
        case .equal:
            modeString = "equal"
        case .strictRotation:
            modeString = "strictRotation"
        case .preferenceBase:
            modeString = "preferenceBase"
        }
        UserDefaults.standard.set(modeString, forKey: "characterDistributionMode")
    }
    
    /**
     * 开始新一轮生成
     * 在每次批量生成内容前调用，清除当前选择缓存
     */
    func beginNewGenerationSession() {
        currentSelectionIds.removeAll()
        
        // 检查是否需要开始新的轮换周期
        if currentMode == .strictRotation && currentCycleUsedIds.count >= allCharacterIds.count {
            startNewCycle()
        }
    }
    
    /**
     * 标记角色被使用
     */
    func markCharacterUsed(characterId: String, type: CharacterSystem.CharacterType) {
        usageCount[characterId] = (usageCount[characterId] ?? 0) + 1
        lastUsedTime[characterId] = Date()
        typeUsageCount[type] = (typeUsageCount[type] ?? 0) + 1
        
        // 添加到当前选择和最近使用列表
        currentSelectionIds.insert(characterId)
        
        // 将角色添加到当前周期已使用列表（用于严格轮换模式）
        currentCycleUsedIds.insert(characterId)
        
        // 将角色添加到最近使用列表的首位
        recentlyUsedCharacterIds.removeAll { $0 == characterId }
        recentlyUsedCharacterIds.insert(characterId, at: 0)
        
        // 保持最近使用列表在限定长度内
        if recentlyUsedCharacterIds.count > maxRecentlyUsedCount {
            recentlyUsedCharacterIds = Array(recentlyUsedCharacterIds.prefix(maxRecentlyUsedCount))
        }
        
        // 每次使用后都保存状态，确保不丢失记录
        saveRotationState()
    }
    
    /**
     * 重置系统状态（用于测试）
     */
    func resetRotationState() {
        usageCount.removeAll()
        lastUsedTime.removeAll()
        typeUsageCount.removeAll()
        recentlyUsedCharacterIds.removeAll()
        currentSelectionIds.removeAll()
        currentCycleUsedIds.removeAll()
        currentCycleNumber = 1
        saveRotationState()
    }
    
    // MARK: - 第一阶段：均等分配
    
    /**
     * 获取均衡分配的角色
     * 确保所有角色获得平等的曝光机会，同时考虑角色类型的均衡性
     */
    func getBalancedCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        // 使用CharacterModel以应用分类过滤（用于帖子生成）
        // 注意：CharacterModel.getAllCharacters() 已经应用了 BlockedCategoriesManager 的过滤
        var allCharacterModels = CharacterModel.getAllCharacters()
        
        // 🔒 双重保险：再次应用过滤，确保被屏蔽分类的角色被移除
        allCharacterModels = BlockedCategoriesManager.shared.filterCharacters(allCharacterModels)
        
        let allCharacters = allCharacterModels.map { convertToCharacterIdentity($0) }
        
        #if DEBUG
        // 调试：验证过滤是否正确工作
        let blockedCategories = BlockedCategoriesManager.shared.getBlockedCategories()
        if !blockedCategories.isEmpty {
            debugLog("🔒 当前屏蔽的分类: \(blockedCategories.map { $0.displayName }.joined(separator: ", "))")
            debugLog("📊 过滤后的角色数量: \(allCharacters.count)")
            
            // 按分类统计过滤后的角色
            let categoryCounts = Dictionary(grouping: allCharacterModels) { $0.category }
                .mapValues { $0.count }
            debugLog("📈 过滤后各分类角色数量: \(categoryCounts)")
            
            // 验证：确保被屏蔽分类的角色不在列表中
            for category in blockedCategories {
                let charactersInBlockedCategory = allCharacterModels.filter { $0.category == category }
                if !charactersInBlockedCategory.isEmpty {
                    debugLog("⚠️ 警告：发现被屏蔽分类「\(category.displayName)」的角色仍在列表中: \(charactersInBlockedCategory.map { $0.name }.joined(separator: ", "))")
                }
            }
        }
        #endif
        
        var result: [CharacterSystem.CharacterIdentity] = []
        
        // 如果是一个新的生成会话，清除当前选择
        // 降低阈值，使会话更频繁地重置，增加角色多样性
        if currentSelectionIds.count >= count + 2 {
            beginNewGenerationSession()
        }
        
        // 获取可用角色（排除当前会话已选角色和处于冷却期的角色）
        let availableCharacters = allCharacters.filter { character in
            // 排除本次生成已经选择过的角色
            if currentSelectionIds.contains(character.id) {
                return false
            }
            
            // 排除最近使用的前N个角色（实现冷却期）
            // 冷却角色数量根据总角色数量动态调整，但不要过于严格
            let coolingCount = min(recentlyUsedCharacterIds.count, max(5, allCharacters.count / 8))
            let coolingCharacterIds = coolingCount > 0 ? recentlyUsedCharacterIds.prefix(coolingCount) : []
            
            return !coolingCharacterIds.contains(character.id)
        }
        
        // 如果可用角色不足，则使用所有角色（优先排除当前已选）
        let candidateCharacters = availableCharacters.isEmpty ? 
            allCharacters.filter { !currentSelectionIds.contains($0.id) } : availableCharacters
        
        // 如果候选角色仍然不足，则使用所有角色（作为最后的备选）
        // 这样可以确保即使角色数量很少（比如用户创建的角色很少），也能正常生成内容
        let finalCandidates = candidateCharacters.isEmpty ? allCharacters : candidateCharacters
        
        // 🔒 如果最终候选角色仍然不足所需数量，允许重复使用（但优先使用未使用的角色）
        // 这对于"我的创建"角色数量少的情况特别重要
        if finalCandidates.count < count {
            #if DEBUG
            debugLog("⚠️ 可用角色数量(\(finalCandidates.count))少于所需数量(\(count))，将允许重复使用角色")
            #endif
        }
        
        // 1. 按使用次数排序（使用较少的排前面）
        let sortedByUsage = finalCandidates.sorted { char1, char2 in
            let usage1 = usageCount[char1.id] ?? 0
            let usage2 = usageCount[char2.id] ?? 0
            if usage1 == usage2 {
                // 使用次数相同时，优先选择最久未使用的角色
                let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                return time1 < time2
            }
            return usage1 < usage2
        }
        
        // 2. 类型信息（用于调试，但不强制按类型配额选择）
        let typeCount = Dictionary(grouping: allCharacters) { $0.type }.mapValues { $0.count }
        
        #if DEBUG
        debugLog("📊 可用角色类型分布: \(typeCount)")
        debugLog("📊 将按照角色分配模式选择角色，不强制类型配额")
        #endif
        
        // 3. 选择角色 - 按照原来的角色分配模式（使用次数、轮换等），不强制类型配额
        // 首先优先考虑未使用过的角色
        let unusedCharacters = sortedByUsage.filter { usageCount[$0.id] == nil }
        for character in unusedCharacters {
            if result.count >= count { break }
                result.append(character)
        }
        
        // 然后是使用次数较少的角色
        if result.count < count {
            for character in sortedByUsage {
                if result.count >= count { break }
                if !result.contains(where: { $0.id == character.id }) {
                    result.append(character)
                }
            }
        }
        
        // 如果还不够，不考虑类型配额，直接添加使用次数最少的角色
        if result.count < count {
            let remainingCharacters = sortedByUsage.filter { character in !result.contains(where: { resultChar in resultChar.id == character.id }) }
            let additionalCount = min(count - result.count, remainingCharacters.count)
            result.append(contentsOf: remainingCharacters.prefix(additionalCount))
            
            #if DEBUG
            if result.count < count {
                debugLog("⚠️ 选择后角色数量仍不足: 需要 \(count) 个，但只有 \(result.count) 个（可用角色总数: \(finalCandidates.count)，剩余角色: \(remainingCharacters.count)）")
            } else {
                debugLog("✅ 通过最后补充阶段，成功选择 \(result.count) 个角色")
            }
            #endif
        }
        
        // 🔒 最终验证：确保所选角色都来自未被屏蔽的分类
        let finalResult = result.filter { characterIdentity in
            // 找到对应的 CharacterModel
            if let characterModel = allCharacterModels.first(where: { $0.id == characterIdentity.id }) {
                // 检查角色是否可用（未被屏蔽）
                let isAvailable = BlockedCategoriesManager.shared.isCharacterAvailable(characterModel)
                if !isAvailable {
        #if DEBUG
                    debugLog("⚠️ 过滤掉被屏蔽分类的角色: \(characterModel.name) (分类: \(characterModel.category.displayName))")
        #endif
                }
                return isAvailable
            }
            return true // 如果找不到对应的 CharacterModel，保留（可能是用户创建的角色）
        }
        
        #if DEBUG
        if finalResult.count < result.count {
            debugLog("🔒 从 \(result.count) 个角色中过滤掉 \(result.count - finalResult.count) 个被屏蔽分类的角色")
        }
        if finalResult.count < count {
            debugLog("⚠️ 过滤后角色数量不足: 需要 \(count) 个，但只有 \(finalResult.count) 个可用角色")
        }
        #endif
        
        // 如果过滤后角色数量不足，尝试补充（但只从可用角色中选择）
        var finalResultWithSupplement = finalResult
        if finalResultWithSupplement.count < count {
            let usedIds = Set(finalResultWithSupplement.map { $0.id })
            let neededCount = count - finalResultWithSupplement.count
            
            // 从所有可用角色中选择（排除已使用的），按使用次数排序，优先选择使用较少的
            let availableForSupplement = allCharacters
                .filter { !usedIds.contains($0.id) }
                .filter { characterIdentity in
                    if let characterModel = allCharacterModels.first(where: { $0.id == characterIdentity.id }) {
                        return BlockedCategoriesManager.shared.isCharacterAvailable(characterModel)
                    }
                    return true
                }
                .sorted { char1, char2 in
                    // 按使用次数排序，使用较少的优先
                    let usage1 = usageCount[char1.id] ?? 0
                    let usage2 = usageCount[char2.id] ?? 0
                    if usage1 == usage2 {
                        // 使用次数相同时，优先选择最久未使用的
                        let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                        let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                        return time1 < time2
                    }
                    return usage1 < usage2
                }
            
            // 选择需要的数量
            let availableSupplement = Array(availableForSupplement.prefix(neededCount))
            finalResultWithSupplement.append(contentsOf: availableSupplement)
            
        #if DEBUG
            if finalResultWithSupplement.count < count {
                debugLog("⚠️ 补充后仍然不足: 需要 \(count) 个，补充后只有 \(finalResultWithSupplement.count) 个")
                debugLog("📊 可用角色总数: \(allCharacters.count)，已使用: \(usedIds.count)，可补充: \(availableForSupplement.count)，实际补充: \(availableSupplement.count)")
            } else {
                debugLog("✅ 成功补充到 \(finalResultWithSupplement.count) 个角色（目标: \(count) 个）")
            }
        #endif
        }
        
        // 4. 记录使用情况
        for character in finalResultWithSupplement {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        #if DEBUG
        // 调试信息：显示最终选择的角色
        let selectedIds = finalResultWithSupplement.map { $0.id }
        let uniqueTypes = Set(finalResultWithSupplement.map { $0.type })
        let coolingCount = min(recentlyUsedCharacterIds.count, max(5, allCharacters.count / 8))
        
        debugLog("🔄 角色轮换系统选择了\(finalResultWithSupplement.count)个角色：\(selectedIds.joined(separator: ", "))")
        debugLog("📊 角色类型分布：\(uniqueTypes.map { "\($0)" }.joined(separator: ", "))")
        debugLog("❄️ 冷却期角色数量：\(coolingCount)/\(recentlyUsedCharacterIds.count)")
        debugLog("📈 总角色库大小：\(allCharacters.count)，当前可用：\(allCharacters.count - coolingCount)")
        #endif
        
        return finalResultWithSupplement
    }
    
    // MARK: - 严格轮换模式
    
    /**
     * 获取严格轮换的角色
     * 确保所有角色都被展示一遍后，才开始新的周期
     * 注意：帖子生成应该应用分类过滤，所以使用CharacterModel.getAllCharacters()
     */
    func getStrictRotationCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        // 使用CharacterModel以应用分类过滤（用于帖子生成）
        let allCharacterModels = CharacterModel.getAllCharacters()
        let allCharacters = allCharacterModels.map { convertToCharacterIdentity($0) }
        
        // 🔒 如果过滤后没有可用角色，返回空数组并记录警告
        if allCharacters.isEmpty {
            #if DEBUG
            debugLog("⚠️ 严格轮换模式：过滤后没有可用角色，请检查屏蔽设置")
            #endif
            return []
        }
        
        // 如果是一个新的生成会话，清除当前选择
        // 降低阈值，使会话更频繁地重置，增加角色多样性
        if currentSelectionIds.count >= count + 2 {
            beginNewGenerationSession()
        }
        
        // 找出当前周期中未使用过的角色
        let unusedInCurrentCycle = allCharacters.filter { !currentCycleUsedIds.contains($0.id) }
        
        // 如果当前周期中未使用的角色已经不足，则开始新的周期
        // 🔒 特殊处理：如果角色总数很少（比如只有1-2个），允许重复使用
        if unusedInCurrentCycle.isEmpty && allCharacters.count <= count {
            // 角色数量很少，重置周期以允许重复使用
            startNewCycle()
            return getStrictRotationCharacters(count: count) // 递归调用，使用新周期的状态
        } else if unusedInCurrentCycle.count < count && unusedInCurrentCycle.count < max(1, allCharacters.count / 3) {
            startNewCycle()
            return getStrictRotationCharacters(count: count) // 递归调用，使用新周期的状态
        }
        
        var result: [CharacterSystem.CharacterIdentity] = []
        
        // 优先选择当前周期未使用过的角色
        let availableUnusedCount = min(count, unusedInCurrentCycle.count)
        if availableUnusedCount > 0 {
            // 随机打乱未使用角色的顺序，增加随机性
            let shuffledUnused = unusedInCurrentCycle.shuffled()
            result.append(contentsOf: shuffledUnused.prefix(availableUnusedCount))
        }
        
        // 如果未使用角色不够，则从已使用角色中选择（但排除本次已选）
        if result.count < count {
            let neededMore = count - result.count
            
            // 排除当前已选角色
            let selectedIds = Set(result.map { $0.id })
            let remainingCharacters = allCharacters.filter { !selectedIds.contains($0.id) }
            
            // 🔒 如果剩余角色仍然不足，允许重复使用已选角色（对于角色数量很少的情况）
            if remainingCharacters.count < neededMore {
                #if DEBUG
                debugLog("⚠️ 角色数量不足(需要\(neededMore)个，可用\(remainingCharacters.count)个)，允许重复使用角色")
                #endif
                // 从所有角色中选择（包括已选角色），优先选择使用次数最少的
                let allAvailable = allCharacters.sorted { char1, char2 in
                    let usage1 = usageCount[char1.id] ?? 0
                    let usage2 = usageCount[char2.id] ?? 0
                    if usage1 == usage2 {
                        let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                        let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                        return time1 < time2
                    }
                    return usage1 < usage2
                }
                result.append(contentsOf: allAvailable.prefix(neededMore))
            } else {
            // 按最近使用时间排序，优先选择最久未使用的
            let sortedRemaining = remainingCharacters.sorted { char1, char2 in
                let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                return time1 < time2
            }
            
            result.append(contentsOf: sortedRemaining.prefix(neededMore))
            }
        }
        
        // 记录使用情况
        for character in result {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        // 使用当前过滤后的角色数量（而不是缓存的allCharacterIds）
        // 这样可以确保在用户改变屏蔽设置后，统计信息是准确的
        let usedCount = currentCycleUsedIds.count
        let totalCount = allCharacters.count
        let remainingCount = totalCount - usedCount
        #if DEBUG
        debugLog("🔄 严格轮换模式：选择了\(result.count)个角色，当前周期#\(currentCycleNumber)已使用\(usedCount)/\(totalCount)个角色（过滤后），剩余\(remainingCount)个")
        #endif
        
        return result
    }
    
    // MARK: - 系统模式切换
    
    /**
     * 切换分配模式
     */
    func switchToMode(_ mode: DistributionMode) {
        if currentMode != mode {
            currentMode = mode
            
            // 模式切换时可能需要一些初始化工作
            if mode == .preferenceBase {
                loadUserPreferences()
            } else if mode == .strictRotation {
                refreshAllCharacterIds()
                if currentCycleUsedIds.isEmpty {
                    // 初始化严格轮换模式时，如果没有记录，则开始新周期
                    startNewCycle()
                }
            }
            
            saveRotationState()
            #if DEBUG
            debugLog("🔀 角色分配模式已切换为: \(getModeName(mode))")
            #endif
        }
    }
    
    /**
     * 获取模式名称（用于显示）
     */
    func getModeName(_ mode: DistributionMode) -> String {
        switch mode {
        case .equal:
            return "均衡分配"
        case .strictRotation:
            return "严格轮换"
        case .preferenceBase:
            return "关注优先"
        }
    }
    
    /**
     * 加载用户偏好
     */
    private func loadUserPreferences() {
        if let favorites = UserDefaults.standard.array(forKey: "userFavoriteCharacters") as? [String] {
            userFavorites = Set(favorites)
        } else {
            userFavorites.removeAll()
        }
        
        // 与 FollowManager 同步，确保关注优先模式使用最新关注列表
        mergeFollowManagerFavorites()
        if let dislikes = UserDefaults.standard.array(forKey: "userDislikeCharacters") as? [String] {
            userDislikes = Set(dislikes)
        }
    }
    
    /**
     * 保存用户偏好
     */
    private func saveUserPreferences() {
        UserDefaults.standard.set(Array(userFavorites), forKey: "userFavoriteCharacters")
        UserDefaults.standard.set(Array(userDislikes), forKey: "userDislikeCharacters")
    }
    
    /**
     * 用户添加/移除关注
     */
    func toggleFavorite(characterId: String) {
        if userFavorites.contains(characterId) {
            userFavorites.remove(characterId)
        } else {
            userFavorites.insert(characterId)
            // 从不喜欢中移除
            userDislikes.remove(characterId)
        }
        saveUserPreferences()
    }
    
    /**
     * 用户添加/移除不喜欢
     */
    func toggleDislike(characterId: String) {
        if userDislikes.contains(characterId) {
            userDislikes.remove(characterId)
        } else {
            userDislikes.insert(characterId)
            // 从喜欢中移除
            userFavorites.remove(characterId)
        }
        saveUserPreferences()
    }
    
    /**
     * 获取推荐角色（根据当前模式选择算法）
     */
    func getRecommendedCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        switch currentMode {
        case .equal:
            return getBalancedCharacters(count: count)
        case .strictRotation:
            return getStrictRotationCharacters(count: count)
        case .preferenceBase:
            return getPreferenceBasedCharacters(count: count)
        }
    }
    
    /**
     * 基于用户偏好的推荐算法（第二阶段实现）
     * 注意：帖子生成应该应用分类过滤，所以使用CharacterModel.getAllCharacters()
     */
    private func getPreferenceBasedCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        guard count > 0 else { return [] }
        
        if currentSelectionIds.count >= count + 2 {
            beginNewGenerationSession()
        }
        
        // 使用CharacterModel以应用分类过滤（用于帖子生成）
        let allCharacterModels = CharacterModel.getAllCharacters()
        let allCharacters = allCharacterModels.map { convertToCharacterIdentity($0) }
        let availableFavorites = allCharacters.filter { userFavorites.contains($0.id) && !userDislikes.contains($0.id) }
        let availableOthers = allCharacters.filter { !userFavorites.contains($0.id) && !userDislikes.contains($0.id) }
        
        // 如果没有关注角色，则退回均衡策略
        if availableFavorites.isEmpty {
            return getBalancedCharacters(count: count)
        }
        
        var targetFavoriteCount = min(
            availableFavorites.count,
            Int(round(Double(count) * preferenceFavoriteRatio))
        )
        var targetExplorationCount = max(0, count - targetFavoriteCount)
        
        // 确保探索池至少有机会出现
        if !availableOthers.isEmpty {
            if targetExplorationCount == 0 && count > 1 {
                targetExplorationCount = min(preferenceMinimumExplorationCount, count)
                targetFavoriteCount = max(0, count - targetExplorationCount)
            }
        } else {
            // 没有探索角色时全部来自关注池
            targetFavoriteCount = min(count, availableFavorites.count)
            targetExplorationCount = 0
        }
        
        var result: [CharacterSystem.CharacterIdentity] = []
        var excludedIds = Set<String>()
        
        let favoriteSelection = selectCharacters(
            from: availableFavorites,
            count: targetFavoriteCount,
            allCharacters: allCharacters,
            excluding: excludedIds
        )
        result.append(contentsOf: favoriteSelection)
        excludedIds.formUnion(favoriteSelection.map { $0.id })
        
        let explorationSelection = selectCharacters(
            from: availableOthers,
            count: targetExplorationCount,
            allCharacters: allCharacters,
            excluding: excludedIds
        )
        result.append(contentsOf: explorationSelection)
        excludedIds.formUnion(explorationSelection.map { $0.id })
        
        // 如果仍未满足数量，使用剩余角色补齐
        if result.count < count {
            let remainingCount = count - result.count
            let fallbackPool = allCharacters.filter {
                !excludedIds.contains($0.id) && !userDislikes.contains($0.id)
            }
            let fallbackSelection = selectCharacters(
                from: fallbackPool,
                count: remainingCount,
                allCharacters: allCharacters,
                excluding: excludedIds
            )
            result.append(contentsOf: fallbackSelection)
        }
        
        for character in result {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        return result
    }

    /**
     * 根据使用频率、冷却期等规则从候选池中选择角色
     */
    private func selectCharacters(
        from pool: [CharacterSystem.CharacterIdentity],
        count: Int,
        allCharacters: [CharacterSystem.CharacterIdentity],
        excluding excludedIds: Set<String>
    ) -> [CharacterSystem.CharacterIdentity] {
        guard count > 0 else { return [] }
        
        let coolingCount = min(recentlyUsedCharacterIds.count, max(5, allCharacters.count / 8))
        let coolingSet = Set(recentlyUsedCharacterIds.prefix(coolingCount))
        
        let primaryFiltered = pool.filter {
            !excludedIds.contains($0.id) &&
            !currentSelectionIds.contains($0.id)
        }
        
        let cooledFiltered = primaryFiltered.filter { !coolingSet.contains($0.id) }
        let finalPool = cooledFiltered.isEmpty ? primaryFiltered : cooledFiltered
        
        let sorted = finalPool.sorted { char1, char2 in
            let usage1 = usageCount[char1.id] ?? 0
            let usage2 = usageCount[char2.id] ?? 0
            if usage1 == usage2 {
                let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                return time1 < time2
            }
            return usage1 < usage2
        }
        
        return Array(sorted.prefix(count))
    }
    
    /**
     * 用户直接标记不喜欢角色（不需要切换）
     */
    func dislikeCharacter(_ characterId: String) {
        // 添加到不喜欢列表
        userDislikes.insert(characterId)
        
        // 从喜欢列表中移除（如果存在）
        userFavorites.remove(characterId)
        
        // 保存用户偏好
        saveUserPreferences()
        
        #if DEBUG
        debugLog("👎 用户已标记不喜欢角色: \(characterId)")
        #endif
    }
    
    /**
     * 检查角色是否被用户不喜欢
     */
    func isCharacterDisliked(_ characterId: String) -> Bool {
        return userDislikes.contains(characterId)
    }
    
    /**
     * 获取所有被用户不喜欢的角色ID
     */
    func getAllDislikedCharacters() -> [String] {
        return Array(userDislikes)
    }
    
    // MARK: - 测试和调试方法
    
    /**
     * 获取最近使用的角色ID列表（用于测试）
     */
    func getRecentlyUsedCharacters() -> [String] {
        return recentlyUsedCharacterIds
    }
    
    /**
     * 获取当前选择中的角色ID集合（用于测试）
     */
    func getCurrentSelectionIds() -> Set<String> {
        return currentSelectionIds
    }
    
    /**
     * 获取当前周期中已使用的角色ID集合（用于测试）
     */
    func getCurrentCycleUsedIds() -> Set<String> {
        return currentCycleUsedIds
    }
    
    /**
     * 获取当前周期编号（用于测试）
     */
    func getCurrentCycleNumber() -> Int {
        return currentCycleNumber
    }
    
    /**
     * 获取角色使用计数（用于测试）
     */
    func getUsageCount() -> [String: Int] {
        return usageCount
    }
    
    /**
     * 获取类型使用计数（用于测试）
     */
    func getTypeUsageCount() -> [CharacterSystem.CharacterType: Int] {
        return typeUsageCount
    }
    
    /**
     * 获取系统状态摘要（用于测试和调试）
     */
    func getSystemStatus() -> String {
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        let coolingCount = min(recentlyUsedCharacterIds.count, max(5, allCharacters.count / 8))
        
        return """
        系统状态摘要：
        - 总角色数量：\(allCharacters.count)
        - 当前模式：\(currentMode)
        - 冷却期角色数量：\(coolingCount)/\(recentlyUsedCharacterIds.count)
        - 当前选择中角色数量：\(currentSelectionIds.count)
        - 当前周期编号：\(currentCycleNumber)
        - 当前周期已使用角色数量：\(currentCycleUsedIds.count)
        - 用户关注角色数量：\(userFavorites.count)
        - 用户不喜欢角色数量：\(userDislikes.count)
        """
    }
    
    // MARK: - 关注状态同步
    
    private func observeFollowStatusChanges() {
        followStatusObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("FollowStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let username = notification.userInfo?["username"] as? String,
                  let characterId = self.characterId(for: username) else {
                return
            }
            
            if let isFollowed = notification.userInfo?["isFollowed"] as? Bool {
                if isFollowed {
                    self.userFavorites.insert(characterId)
                } else {
                    self.userFavorites.remove(characterId)
                }
                self.saveUserPreferences()
            } else {
                // 未提供状态时，根据FollowManager重新同步
                self.mergeFollowManagerFavorites()
                self.saveUserPreferences()
            }
        }
    }
    
    private func mergeFollowManagerFavorites() {
        let followedNames = FollowManager.shared.getFollowedUsers()
        let matchedIds = followedNames.compactMap { characterId(for: $0) }
        userFavorites.formUnion(matchedIds)
    }
    
    private func characterId(for nameOrId: String) -> String? {
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        if let match = allCharacters.first(where: { $0.name == nameOrId }) {
            return match.id
        }
        // 如果传入的本身就是ID
        if allCharacters.contains(where: { $0.id == nameOrId }) {
            return nameOrId
        }
        return nil
    }
}
