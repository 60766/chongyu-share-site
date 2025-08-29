import Foundation

/**
 * 角色轮换系统
 * 确保各角色获得平均的曝光机会，并为未来的关注/不喜欢功能预留接口
 */
class CharacterRotationSystem {
    // 单例模式
    static let shared = CharacterRotationSystem()
    private init() { loadRotationState() }
    
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
     * 当角色库更新时调用此方法
     */
    func refreshAllCharacterIds() {
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        allCharacterIds = Set(allCharacters.map { $0.id })
        
        // 如果发现之前未记录的角色，在严格轮换模式下需要重置周期
        if currentMode == .strictRotation && !allCharacterIds.isSubset(of: currentCycleUsedIds) {
            startNewCycle()
        }
    }
    
    /**
     * 开始新的严格轮换周期
     */
    private func startNewCycle() {
        currentCycleUsedIds.removeAll()
        currentCycleNumber += 1
        print("🔄 开始角色新轮换周期 #\(currentCycleNumber)")
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
        let allCharacters = CharacterSystem.shared.getAllCharacters()
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
        let finalCandidates = candidateCharacters.isEmpty ? allCharacters : candidateCharacters
        
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
        
        // 2. 确保类型平衡
        var typeQuota: [CharacterSystem.CharacterType: Int] = [:]
        let typeCount = Dictionary(grouping: allCharacters) { $0.type }.mapValues { $0.count }
        
        // 按比例分配类型配额
        for (type, charCount) in typeCount {
            let typeRatio = Double(charCount) / Double(allCharacters.count)
            typeQuota[type] = max(1, Int(Double(count) * typeRatio))
        }
        
        // 3. 选择角色
        // 首先优先考虑未使用过的角色
        let unusedCharacters = sortedByUsage.filter { usageCount[$0.id] == nil }
        for character in unusedCharacters {
            if result.count >= count { break }
            if (typeQuota[character.type] ?? 0) > 0 {
                result.append(character)
                typeQuota[character.type] = (typeQuota[character.type] ?? 1) - 1
            }
        }
        
        // 然后是使用次数较少的角色
        if result.count < count {
            for character in sortedByUsage {
                if result.count >= count { break }
                if !result.contains(where: { $0.id == character.id }) && (typeQuota[character.type] ?? 0) > 0 {
                    result.append(character)
                    typeQuota[character.type] = (typeQuota[character.type] ?? 1) - 1
                }
            }
        }
        
        // 如果还不够，不考虑类型配额，直接添加使用次数最少的角色
        if result.count < count {
            let remainingCharacters = sortedByUsage.filter { character in !result.contains(where: { resultChar in resultChar.id == character.id }) }
            let additionalCount = min(count - result.count, remainingCharacters.count)
            result.append(contentsOf: remainingCharacters.prefix(additionalCount))
        }
        
        // 4. 记录使用情况
        for character in result {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        // 添加详细的调试信息
        let coolingCount = min(recentlyUsedCharacterIds.count, max(5, allCharacters.count / 8))
        let selectedIds = result.map { $0.id }
        let uniqueTypes = Set(result.map { $0.type })
        
        print("🔄 角色轮换系统选择了\(result.count)个角色：\(selectedIds.joined(separator: ", "))")
        print("📊 角色类型分布：\(uniqueTypes.map { "\($0)" }.joined(separator: ", "))")
        print("❄️ 冷却期角色数量：\(coolingCount)/\(recentlyUsedCharacterIds.count)")
        print("📈 总角色库大小：\(allCharacters.count)，当前可用：\(allCharacters.count - coolingCount)")
        
        return result
    }
    
    // MARK: - 严格轮换模式
    
    /**
     * 获取严格轮换的角色
     * 确保所有角色都被展示一遍后，才开始新的周期
     */
    func getStrictRotationCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        
        // 如果是一个新的生成会话，清除当前选择
        // 降低阈值，使会话更频繁地重置，增加角色多样性
        if currentSelectionIds.count >= count + 2 {
            beginNewGenerationSession()
        }
        
        // 找出当前周期中未使用过的角色
        let unusedInCurrentCycle = allCharacters.filter { !currentCycleUsedIds.contains($0.id) }
        
        // 如果当前周期中未使用的角色已经不足，则开始新的周期
        if unusedInCurrentCycle.count < count && unusedInCurrentCycle.count < allCharacters.count / 3 {
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
            
            // 按最近使用时间排序，优先选择最久未使用的
            let sortedRemaining = remainingCharacters.sorted { char1, char2 in
                let time1 = lastUsedTime[char1.id] ?? Date.distantPast
                let time2 = lastUsedTime[char2.id] ?? Date.distantPast
                return time1 < time2
            }
            
            result.append(contentsOf: sortedRemaining.prefix(neededMore))
        }
        
        // 记录使用情况
        for character in result {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        let usedCount = currentCycleUsedIds.count
        let totalCount = allCharacterIds.count
        let remainingCount = totalCount - usedCount
        print("🔄 严格轮换模式：选择了\(result.count)个角色，当前周期#\(currentCycleNumber)已使用\(usedCount)/\(totalCount)个角色，剩余\(remainingCount)个")
        
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
            print("🔀 角色分配模式已切换为: \(getModeName(mode))")
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
        }
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
     */
    private func getPreferenceBasedCharacters(count: Int) -> [CharacterSystem.CharacterIdentity] {
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        var result: [CharacterSystem.CharacterIdentity] = []
        
        // 1. 优先选择用户关注的角色（50%的比例）
        let favoriteCount = min(count / 2, userFavorites.count)
        if favoriteCount > 0 {
            let favoriteCharacters = allCharacters.filter { userFavorites.contains($0.id) }.shuffled()
            result.append(contentsOf: favoriteCharacters.prefix(favoriteCount))
        }
        
        // 2. 其余位置按使用频率均衡分配
        if result.count < count {
            let remainingCount = count - result.count
            let selectedIds = Set(result.map { $0.id })
            let candidates = allCharacters.filter { 
                !selectedIds.contains($0.id) && !userDislikes.contains($0.id) 
            }
            
            // 使用轮换逻辑选择候选角色
            let sortedCandidates = candidates.sorted {
                let usage1 = usageCount[$0.id] ?? 0
                let usage2 = usageCount[$1.id] ?? 0
                return usage1 < usage2
            }
            
            result.append(contentsOf: sortedCandidates.prefix(remainingCount))
        }
        
        // 3. 记录使用情况
        for character in result {
            markCharacterUsed(characterId: character.id, type: character.type)
        }
        
        return result
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
        
        print("👎 用户已标记不喜欢角色: \(characterId)")
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
}
