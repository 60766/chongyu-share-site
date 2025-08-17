import Foundation
import Combine

/**
 * 角色系统
 * 轻量级设计，支持多种类型的虚拟角色
 */
class CharacterSystem {
    // 单例模式
    static let shared = CharacterSystem()
    private init() {
        loadCharacterDatabase()
    }
    
    // 角色缓存
    private var characterCache: [String: DetailedCharacterTraits] = [:]
    // 角色基础数据库
    private var characterDatabase: [CharacterIdentity] = []
    // 用户自定义角色
    private var userDefinedCharacters: [CharacterIdentity] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 角色数据模型
    
    /**
     * 角色类型枚举
     */
    enum CharacterType: String, Codable, CaseIterable {
        case historical = "historical"   // 历史人物
        case literary = "literary"       // 文学角色
        case movie = "movie"             // 电影角色
        case anime = "anime"             // 动漫角色
        case game = "game"               // 游戏角色
        case mythological = "mythological" // 神话角色
        case entrepreneur = "entrepreneur"  // 企业家
        case scifi = "scifi"             // 科幻角色
        case fantasy = "fantasy"         // 奇幻角色
        case custom = "custom"         // 用户自定义
        case unknown = "unknown"       // 未知类型，用于处理JSON解析未知类型的情况
        
        // 从字符串初始化，处理未知类型
        init(from string: String) {
            self = CharacterType(rawValue: string) ?? .unknown
        }
        
        // 中文显示名称
        var displayName: String {
            switch self {
            case .historical: return "历史人物"
            case .literary: return "文学角色"
            case .movie: return "电影角色"
            case .anime: return "动漫角色"
            case .game: return "游戏角色"
            case .mythological: return "神话角色"
            case .entrepreneur: return "企业家"
            case .scifi: return "科幻角色"
            case .fantasy: return "奇幻角色"
            case .custom: return "自定义角色"
            case .unknown: return "未知类型"
            }
        }
        
        // localizedName作为displayName的别名，保证向后兼容
        var localizedName: String {
            return displayName
        }
        
        // 获取所有类型（不包括unknown和custom）
        static var allPublicCases: [CharacterType] {
            return CharacterType.allCases.filter { $0 != .unknown && $0 != .custom }
        }
    }
    
    /**
     * 角色身份标识 - 轻量级
     */
    struct CharacterIdentity: Identifiable, Hashable, Codable {
        var id: String
        var name: String
        var type: CharacterType
        var era: String
        var primaryField: String
        var briefDescription: String
        var avatarName: String
        var region: String
        var contentAffinities: [String: Double]
        var subtype: String?
        
        // MARK: - Codable支持
        
        enum CodingKeys: String, CodingKey {
            case id, name, type, era, primaryField, briefDescription, avatarName, region, contentAffinities, subtype
        }
        
        init(id: String, name: String, type: CharacterType, era: String, primaryField: String, 
             briefDescription: String, avatarName: String, region: String, 
             contentAffinities: [String: Double], subtype: String? = nil) {
            self.id = id
            self.name = name
            self.type = type
            self.era = era
            self.primaryField = primaryField
            self.briefDescription = briefDescription
            self.avatarName = avatarName
            self.region = region
            self.contentAffinities = contentAffinities
            self.subtype = subtype
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            
            // 处理类型解码，支持未知类型
            let typeString = try container.decode(String.self, forKey: .type)
            if let knownType = CharacterType(rawValue: typeString) {
                type = knownType
            } else {
                type = .unknown
            }
            
            era = try container.decode(String.self, forKey: .era)
            primaryField = try container.decode(String.self, forKey: .primaryField)
            briefDescription = try container.decode(String.self, forKey: .briefDescription)
            avatarName = try container.decode(String.self, forKey: .avatarName)
            region = try container.decode(String.self, forKey: .region)
            contentAffinities = try container.decode([String: Double].self, forKey: .contentAffinities)
            subtype = try container.decodeIfPresent(String.self, forKey: .subtype)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(type.rawValue, forKey: .type)
            try container.encode(era, forKey: .era)
            try container.encode(primaryField, forKey: .primaryField)
            try container.encode(briefDescription, forKey: .briefDescription)
            try container.encode(avatarName, forKey: .avatarName)
            try container.encode(region, forKey: .region)
            try container.encode(contentAffinities, forKey: .contentAffinities)
            try container.encodeIfPresent(subtype, forKey: .subtype)
        }
    }
    
    /**
     * 详细角色特征 - 由API动态生成
     */
    struct DetailedCharacterTraits {
        let identity: CharacterIdentity
        let fullDescription: String
        let personality: [String]
        let speechPatterns: [String]
        let experiences: [String]
        let knowledgeDomains: [String]
        let relationshipNetwork: [String: String]?
        let topicAffinities: [String: Double]?
        
        // 生成时间戳，用于定期刷新
        let generatedAt: Date
        
        // 缓存是否过期
        var isExpired: Bool {
            return Date().timeIntervalSince(generatedAt) > 7 * 24 * 60 * 60 // 一周过期
        }
    }
    
    // MARK: - 公共API
    
    /**
     * 获取所有可用角色标识
     */
    func getAllCharacters() -> [CharacterIdentity] {
        return characterDatabase + userDefinedCharacters
    }
    
    /**
     * 刷新角色数据库
     * 用于在应用运行时重新加载角色数据
     * @param completion 完成回调，返回是否成功及错误信息
     */
    func refreshCharacterDatabase(completion: @escaping (Bool, Error?) -> Void) {
        CharacterSystem.loadCharacterDatabaseFromJSON { [weak self] characters, error in
            guard let self = self else {
                completion(false, NSError(domain: "CharacterSystem", code: 500, 
                                          userInfo: [NSLocalizedDescriptionKey: "内部错误"]))
                return
            }
            
            if let characters = characters {
                self.characterDatabase = characters
                print("角色数据库刷新成功，共\(characters.count)个角色")
                completion(true, nil)
            } else {
                print("角色数据库刷新失败: \(error?.localizedDescription ?? "未知错误")")
                completion(false, error)
            }
        }
    }
    
    /**
     * 按类型获取角色
     */
    func getCharacters(ofType type: CharacterType? = nil) -> [CharacterIdentity] {
        let allCharacters = getAllCharacters()
        guard let type = type else { return allCharacters }
        return allCharacters.filter { $0.type == type }
    }
    
    /**
     * 根据ID获取角色
     */
    func getCharacter(_ characterId: String) -> Future<CharacterIdentity, Error> {
        return Future { promise in
            if let character = (self.characterDatabase + self.userDefinedCharacters).first(where: { $0.id == characterId }) {
                promise(.success(character))
            } else {
                promise(.failure(CharacterError.characterNotFound))
            }
        }
    }
    
    /**
     * 根据名称查找角色
     */
    func findCharacterByName(_ name: String) -> CharacterIdentity? {
        return (self.characterDatabase + self.userDefinedCharacters).first(where: { 
            $0.name.lowercased().contains(name.lowercased())
        })
    }
    
    /**
     * 获取角色详细特征
     */
    func getCharacterTraits(_ characterId: String) -> Future<DetailedCharacterTraits, Error> {
        return Future { promise in
            // 检查缓存中是否有未过期的数据
            if let cachedTraits = self.characterCache[characterId], !cachedTraits.isExpired {
                promise(.success(cachedTraits))
                return
            }
            
            // 获取角色标识
            guard let identity = (self.characterDatabase + self.userDefinedCharacters).first(where: { $0.id == characterId }) else {
                promise(.failure(CharacterError.characterNotFound))
                return
            }
            
            // 调用API丰富角色信息
            self.enrichCharacterDetails(identity: identity)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { detailedTraits in
                        // 更新缓存
                        self.characterCache[characterId] = detailedTraits
                        promise(.success(detailedTraits))
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 添加用户自定义角色
     */
    func addUserDefinedCharacter(name: String, type: CharacterType, era: String, primaryField: String, description: String, avatarName: String? = nil) -> CharacterIdentity {
        let id = "user_\(UUID().uuidString.prefix(8))"
        
        let character = CharacterIdentity(
            id: id,
            name: name,
            type: type,
            era: era,
            primaryField: primaryField,
            briefDescription: description,
            avatarName: avatarName ?? "",
            region: "",
            contentAffinities: [:],
            subtype: nil
        )
        
        userDefinedCharacters.append(character)
        saveUserDefinedCharacters()
        
        return character
    }
    
    /**
     * 删除用户自定义角色
     */
    func deleteUserDefinedCharacter(id: String) -> Bool {
        let initialCount = userDefinedCharacters.count
        userDefinedCharacters.removeAll { $0.id == id }
        
        if userDefinedCharacters.count != initialCount {
            saveUserDefinedCharacters()
            // 同时删除缓存
            characterCache.removeValue(forKey: id)
            return true
        }
        
        return false
    }
    
    /**
     * 为特定内容类型推荐最合适的角色
     */
    func recommendCharactersForContent(contentType: String, count: Int = 3) -> [CharacterIdentity] {
        let allCharacters = getAllCharacters()
        
        // 根据角色对该内容类型的亲和度排序
        let sortedCharacters = allCharacters.sorted { char1, char2 in
            let affinity1 = char1.contentAffinities[contentType] ?? 0.5
            let affinity2 = char2.contentAffinities[contentType] ?? 0.5
            return affinity1 > affinity2
        }
        
        // 返回前count个角色，如果数量不足则返回全部
        return Array(sortedCharacters.prefix(min(count, sortedCharacters.count)))
    }
    
    /**
     * 随机获取指定数量的角色，可选择排除特定角色ID
     */
    func getRandomCharacters(count: Int, excludeID: String? = nil) -> [CharacterIdentity] {
        var availableCharacters = getAllCharacters()
        
        // 排除指定ID的角色
        if let excludeID = excludeID {
            availableCharacters = availableCharacters.filter { $0.id != excludeID }
        }
        
        // 随机打乱并获取指定数量
        return Array(availableCharacters.shuffled().prefix(count))
    }
    
    /**
     * 随机获取一个角色，可以指定内容类型偏好
     */
    func getRandomCharacter(preferredContentType: String? = nil) -> CharacterIdentity {
        var availableCharacters = getAllCharacters()
        
        // 如果指定了内容类型，根据角色对该内容类型的亲和度排序
        if let contentType = preferredContentType {
            availableCharacters.sort { char1, char2 in
                let affinity1 = char1.contentAffinities[contentType] ?? 0.5
                let affinity2 = char2.contentAffinities[contentType] ?? 0.5
                return affinity1 > affinity2
            }
            
            // 从前50%的角色中随机选择，增加相关性但保持随机性
            let preferredCount = max(1, availableCharacters.count / 2)
            return availableCharacters[Int.random(in: 0..<preferredCount)]
        }
        
        // 如果没有指定内容类型，完全随机选择
        return availableCharacters.randomElement() ?? availableCharacters[0]
    }
    
    /**
     * 根据子类型获取角色
     */
    func getCharactersBySubtype(_ subtype: String) -> [CharacterIdentity] {
        return getAllCharacters().filter { $0.subtype == subtype }
    }
    
    /**
     * 获取所有子类型列表
     */
    func getAllSubtypes() -> [String] {
        let allSubtypes = getAllCharacters().compactMap { $0.subtype }
        return Array(Set(allSubtypes)).sorted()
    }
    
    // MARK: - 私有方法
    
    /**
     * 加载角色数据库
     */
    private func loadCharacterDatabase() {
        // 1. 先尝试从本地修改过的预设角色文件加载
        if let modifiedCharacters = loadModifiedPresetCharacters() {
            characterDatabase = modifiedCharacters
            print("从本地修改的预设文件加载了\(modifiedCharacters.count)个角色")
            // 加载用户自定义角色
            loadUserDefinedCharacters()
            return
        }
        
        // 2. 尝试从原始JSON文件加载角色数据
        CharacterSystem.loadCharacterDatabaseFromJSON { characters, error in
            if let characters = characters {
                self.characterDatabase = characters
                print("成功从JSON加载了\(characters.count)个角色")
            } else {
                // 记录错误信息
                if let error = error {
                    print("加载角色数据库失败: \(error.localizedDescription)")
                }
                
                // 备用方案：使用空数组
                print("JSON加载失败，使用空数组")
                self.characterDatabase = []
            }
            
            // 加载用户自定义角色
            self.loadUserDefinedCharacters()
        }
    }
    
    /**
     * 从JSON文件加载角色数据
     */
    private func loadCharactersFromJSON() -> [CharacterIdentity]? {
        guard let url = Bundle.main.url(forResource: "characters", withExtension: "json") else {
            print("角色JSON文件未找到")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // 解析JSON结构
            struct CharactersResponse: Codable {
                let version: String
                let characters: [CharacterIdentity]
            }
            
            let response = try decoder.decode(CharactersResponse.self, from: data)
            return response.characters
        } catch {
            print("加载角色JSON失败: \(error)")
            return nil
        }
    }
    
    /**
     * 从API丰富角色详细信息
     */
    private func enrichCharacterDetails(identity: CharacterIdentity) -> Future<DetailedCharacterTraits, Error> {
        return Future { promise in
            // 构建提示词，用于AI生成角色详细特征
            let prompt = """
            基于以下基本信息，生成这个角色的详细特征:
            角色名称: \(identity.name)
            角色类型: \(identity.type.displayName)
            角色类型: \(identity.type.localizedName)
            时代/背景: \(identity.era)
            主要领域: \(identity.primaryField)
            简介: \(identity.briefDescription)
            地区: \(identity.region)
            
            请以JSON格式生成以下内容:
            1. fullDescription: 详细的人物描述 (150-200字)
            2. personality: 5-8个性格特点
            3. speechPatterns: 5-8个语言风格特点或常用表达
            4. experiences: 5-8个关键经历或成就
            5. knowledgeDomains: 5-8个该角色熟悉的知识领域
            6. relationshipNetwork: 与其他角色的关系 (可选)
            7. topicAffinities: 对现代话题的亲和度，0-1之间的数值 (可选)
            
            确保生成的内容符合角色类型的特点，例如历史人物要符合历史事实，动漫角色要符合原作设定。
            """
            
            // 调用AI内容生成器
            AIContentGenerator.shared.generateStructuredContent(prompt: prompt)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { jsonString in
                        do {
                            // 解析返回的JSON
                            let parsedTraits = try self.parseCharacterTraits(jsonString, identity: identity)
                            promise(.success(parsedTraits))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                )
                .store(in: &self.cancellables)
        }
    }
    
    /**
     * 解析API返回的角色特征
     */
    private func parseCharacterTraits(_ jsonString: String, identity: CharacterIdentity) throws -> DetailedCharacterTraits {
        // 尝试解析JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw CharacterError.invalidResponse
        }
        
        // 提取基本字段
        let fullDescription = json["fullDescription"] as? String ?? "无详细描述"
        
        // 提取数组字段
        let personality = json["personality"] as? [String] ?? []
        let speechPatterns = json["speechPatterns"] as? [String] ?? []
        let experiences = json["experiences"] as? [String] ?? []
        let knowledgeDomains = json["knowledgeDomains"] as? [String] ?? []
        
        // 提取可选字段
        let relationshipNetwork = json["relationshipNetwork"] as? [String: String]
        let topicAffinities = json["topicAffinities"] as? [String: Double]
        
        return DetailedCharacterTraits(
            identity: identity,
            fullDescription: fullDescription,
            personality: personality,
            speechPatterns: speechPatterns,
            experiences: experiences,
            knowledgeDomains: knowledgeDomains,
            relationshipNetwork: relationshipNetwork,
            topicAffinities: topicAffinities,
            generatedAt: Date()
        )
    }
    
    /**
     * 保存用户自定义角色
     */
    private func saveUserDefinedCharacters() {
        do {
            let data = try JSONEncoder().encode(userDefinedCharacters)
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("userCharacters.json")
            
            try data.write(to: fileURL)
            print("用户自定义角色保存成功，共\(userDefinedCharacters.count)个")
        } catch {
            print("保存用户自定义角色失败: \(error)")
        }
    }
    
    /**
     * 加载用户自定义角色
     */
    private func loadUserDefinedCharacters() {
        do {
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("userCharacters.json")
            
            let data = try Data(contentsOf: fileURL)
            userDefinedCharacters = try JSONDecoder().decode([CharacterIdentity].self, from: data)
        } catch {
            print("加载用户自定义角色失败: \(error)")
            userDefinedCharacters = []
        }
    }
    
    /**
     * 导出所有角色到JSON文件
     * @param includeUserDefined 是否包含用户自定义角色
     * @param completion 完成回调，返回导出的文件URL或错误
     */
    func exportCharactersToJSON(includeUserDefined: Bool = true, completion: @escaping (URL?, Error?) -> Void) {
        do {
            let characters = includeUserDefined ? getAllCharacters() : characterDatabase
            
            // 创建JSON响应结构
            struct CharactersExport: Codable {
                let version: String
                let exportDate: Date
                let characters: [CharacterIdentity]
            }
            
            let export = CharactersExport(
                version: "1.0", 
                exportDate: Date(), 
                characters: characters
            )
            
            // 编码为JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(export)
            
            // 创建文件
            let fileName = "characters_export_\(Int(Date().timeIntervalSince1970)).json"
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            print("角色数据导出成功: \(fileURL.path)")
            completion(fileURL, nil)
        } catch {
            print("角色数据导出失败: \(error)")
            completion(nil, error)
        }
    }
    
    /**
     * 从JSON文件导入角色
     * @param fileURL 文件URL
     * @param mode 导入模式：追加或替换
     * @param completion 完成回调，返回导入的角色数量或错误
     */
    func importCharactersFromJSON(fileURL: URL, mode: CharacterImportMode, completion: @escaping (Int?, Error?) -> Void) {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            
            // 解析JSON结构
            struct CharactersImport: Codable {
                let version: String?
                let exportDate: Date?
                let characters: [CharacterIdentity]
            }
            
            let imported = try decoder.decode(CharactersImport.self, from: data)
            
            // 根据模式处理导入的角色
            switch mode {
            case .append:
                // 确保不重复添加相同ID的角色
                let existingIds = Set(userDefinedCharacters.map { $0.id })
                let newCharacters = imported.characters.filter { !existingIds.contains($0.id) }
                userDefinedCharacters.append(contentsOf: newCharacters)
            case .replace:
                userDefinedCharacters = imported.characters
            }
            
            // 保存用户自定义角色
            saveUserDefinedCharacters()
            
            print("角色导入成功，共\(imported.characters.count)个角色")
            completion(imported.characters.count, nil)
        } catch {
            print("角色导入失败: \(error)")
            completion(nil, error)
        }
    }
    
    /**
     * 角色导入模式
     */
    enum CharacterImportMode {
        case append  // 追加到现有角色
        case replace // 替换现有角色
    }
    
    /**
     * 错误类型
     */
    enum CharacterError: Error {
        case characterNotFound
        case invalidResponse
        case generationFailed
    }
    
    // MARK: - 示例数据
    
    // 样例角色数据库 - 实际应用中应该从JSON文件加载
    private let sampleCharacterDatabase: [CharacterIdentity] = []
    
    // MARK: - CharacterDatabase管理
    
    /// 从JSON加载角色数据库
    /// - Parameter completion: 加载完成后的回调
    static func loadCharacterDatabaseFromJSON(completion: @escaping ([CharacterIdentity]?, Error?) -> Void) {
        guard let url = Bundle.main.url(forResource: "characters", withExtension: "json") else {
            completion(nil, NSError(domain: "CharacterSystem", code: 404, userInfo: [NSLocalizedDescriptionKey: "找不到characters.json文件"]))
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                
                // 解析JSON结构
                struct CharactersResponse: Codable {
                    let version: String
                    let characters: [CharacterIdentity]
                }
                
                let response = try decoder.decode(CharactersResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completion(response.characters, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    print("加载角色JSON失败: \(error)")
                    completion(nil, error)
                }
            }
        }
    }
    
    /// 根据类型和子类型筛选角色
    /// - Parameters:
    ///   - type: 角色类型
    ///   - subtype: 子类型(可选)
    /// - Returns: 筛选后的角色列表
    static func filterCharacters(byType type: CharacterType?, subtype: String? = nil) -> [CharacterIdentity] {
        // 从JSON文件加载角色数据
        var filteredCharacters: [CharacterIdentity] = []
        
        // 这里应该从JSON文件加载数据，暂时返回空数组
        // TODO: 实现从JSON文件加载角色数据
        
        if let type = type {
            filteredCharacters = filteredCharacters.filter { $0.type == type }
        }
        
        if let subtype = subtype {
            filteredCharacters = filteredCharacters.filter { $0.subtype == subtype }
        }
        
        return filteredCharacters
    }
    
    /// 获取所有可用的子类型（按类型分组）
    /// - Returns: 类型及其对应的子类型字典
    static func getAllSubtypesByType() -> [CharacterType: Set<String>] {
        var subtypesByType: [CharacterType: Set<String>] = [:]
        
        // 从JSON文件加载角色数据
        // TODO: 实现从JSON文件加载角色数据
        let characters: [CharacterIdentity] = []
        
        for character in characters {
            if let subtype = character.subtype {
                var subtypes = subtypesByType[character.type] ?? Set<String>()
                subtypes.insert(subtype)
                subtypesByType[character.type] = subtypes
            }
        }
        
        return subtypesByType
    }
    
    /// 获取特定类型的所有子类型
    /// - Parameter type: 角色类型
    /// - Returns: 子类型集合
    static func getSubtypes(forType type: CharacterType) -> Set<String> {
        // 从JSON文件加载角色数据
        // TODO: 实现从JSON文件加载角色数据
        let characters: [CharacterIdentity] = []
        
        return characters
            .filter { $0.type == type }
            .compactMap { $0.subtype }
            .reduce(into: Set<String>()) { $0.insert($1) }
    }
    
    /**
     * 更新角色信息
     * @param character 更新后的角色信息
     * @return 返回更新是否成功
     */
    func updateCharacter(_ character: CharacterIdentity) -> Bool {
        // 检查是否为预设角色
        if let index = characterDatabase.firstIndex(where: { $0.id == character.id }) {
            characterDatabase[index] = character
            // 将更新后的预设角色数据库保存到本地JSON
            saveModifiedPresetCharacters()
            
            // 同时清除该角色的缓存
            characterCache.removeValue(forKey: character.id)
            return true
        } 
        // 检查是否为用户自定义角色
        else if let index = userDefinedCharacters.firstIndex(where: { $0.id == character.id }) {
            userDefinedCharacters[index] = character
            saveUserDefinedCharacters()
            
            // 同时清除该角色的缓存
            characterCache.removeValue(forKey: character.id)
            return true
        }
        
        return false
    }
    
    /**
     * 保存修改过的预设角色
     */
    private func saveModifiedPresetCharacters() {
        do {
            // 创建导出结构
            struct CharactersExport: Codable {
                let version: String
                let characters: [CharacterIdentity]
            }
            
            let export = CharactersExport(
                version: "1.0",
                characters: characterDatabase
            )
            
            // 编码为JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            let data = try encoder.encode(export)
            
            // 先尝试保存到应用文档目录 (可修改的区域)
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("preset_characters.json")
            
            try data.write(to: fileURL)
            print("预设角色修改已保存: \(fileURL.path)")
        } catch {
            print("保存预设角色修改失败: \(error)")
        }
    }
    
    /**
     * 从本地修改文件加载预设角色
     */
    private func loadModifiedPresetCharacters() -> [CharacterIdentity]? {
        do {
            // 获取文件路径
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("preset_characters.json")
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("本地修改的预设角色文件不存在")
                return nil
            }
            
            // 读取并解码
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            
            // 解析JSON结构
            struct CharactersResponse: Codable {
                let version: String
                let characters: [CharacterIdentity]
            }
            
            let response = try decoder.decode(CharactersResponse.self, from: data)
            print("从本地修改文件加载预设角色成功")
            return response.characters
            
        } catch {
            print("从本地修改文件加载预设角色失败: \(error)")
            return nil
        }
    }
    
    /// 生成角色特征描述提示词
    /// - Parameter identity: 角色身份信息
    /// - Returns: 对应提示词
    static func buildCharacterTraitPrompt(for identity: CharacterIdentity) -> String {
        """
        基于以下基本信息，生成这个角色的详细特征:
        角色名称: \(identity.name)
        角色类型: \(identity.type.displayName)
        时代/背景: \(identity.era)
        主要领域: \(identity.primaryField)
        简介: \(identity.briefDescription)
        地区: \(identity.region)
        
        请以JSON格式生成以下内容:
        - 5个性格特点
        - 3个知识专长领域
        - 3个兴趣爱好
        - 3个价值观/信念
        
        格式要求:
        {
          "personalityTraits": ["特点1", "特点2"...],
          "knowledgeFields": ["领域1", "领域2"...],
          "interests": ["爱好1", "爱好2"...],
          "values": ["价值观1", "价值观2"...]
        }
        """
    }
}

/**
 * CharacterTraits的扩展，用于API响应处理
 */
extension CharacterSystem.DetailedCharacterTraits {
    /**
     * 构建用于内容生成的提示词
     */
    func buildContentPrompt(contentType: String, topic: String? = nil) -> String {
        // 保留原有AIContentGenerator中精心调试的提示词
        switch contentType {
        case "虫洞共鸣":
            return buildResonancePrompt(topic: topic)
        case "日常心情":
            return buildMoodPrompt()
        case "古潮新语":
            return buildAncientModernPrompt(topic: topic)
        case "穿越吐槽":
            return buildCreativeIdeaPrompt()
        case "时空记事":
            return buildTimelineEventPrompt()
        default:
            // 如果是未知类型，使用通用模板
            return buildGenericPrompt(topic: topic)
        }
    }
    
    /**
     * 构建虫洞共鸣提示词
     */
    private func buildResonancePrompt(topic: String? = nil) -> String {
        let resonanceTopic = topic ?? "现代人的困惑"
        
        return """
        【虫洞共鸣：历史人物的心灵分享】
        
        你是\(identity.name)，\(identity.type.displayName)，来自\(identity.era)时代，以\(identity.primaryField)著称。现在正在社交媒体上与现代人分享关于"\(resonanceTopic)"的见解。
        
        角色背景：
        \(fullDescription)
        
        性格特点：
        \(personality.joined(separator: "，"))
        
        核心要求：
        • 直接明了 - 用现代人容易理解的语言表达核心观点，避免过度隐喻或晦涩表达
        • 真实共鸣 - 分享你作为角色曾经的真实挣扎和感悟，但用通俗易懂的方式
        • 实用洞见 - 给出可以立即应用或思考的观点，不要空洞或过于抽象
        • 保持个性 - 体现你的思维方式和价值观，但不要模仿古代语言或过度文艺化
        • 创意多样 - 使用多变的开场方式和结构形式，避免套路化
        • 内容新鲜 - 创造新的、独特的个人经历，而不是重复使用相同的故事或场景
        
        表达风格限制：
        • 避免华丽辞藻 - 不要使用过于修饰性的语言和晦涩的比喻，用平实的表达更有力量
        • 避免刻意的文学腔 - 不要使用"当月光第三次在尼罗河面破碎时"这类过度文学化表达
        • 避免意象堆砌 - 不要使用连续的抽象意象和符号，保持表达的清晰和直接
        • 避免刻意的古典引用 - 除非确实需要，否则不要刻意引用古典文献或诗句
        • 言之有物 - 确保每句话都传达有意义的内容，不要为了"高大上"而堆砌空洞词藻
        • 保持生活化 - 用日常生活中的普通表达方式和例子来阐述深刻道理
        
        语言风格：
        \(speechPatterns.joined(separator: "，"))
        
        关键经历（可选择性引用）：
        \(experiences.joined(separator: "，"))
        
        字数：80-120字，确保内容自然流畅，像真实的社交媒体分享。
        """
    }
    
    /**
     * 构建日常心情提示词
     */
    private func buildMoodPrompt() -> String {
        // 随机选择一种心情表达
        let moods = [
            "喜悦", "满足", "感动", "放松", "憧憬", "振奋", "好奇", "欣赏",
            "宁静", "思考", "感悟", "怀旧", "释然", "从容", "平和",
            "迷茫", "惆怅", "无奈", "疲惫", "焦虑", "困惑", "孤独", "纠结",
            "小确幸", "日常吐槽", "生活感悟", "偶遇惊喜", "工作困境"
        ]
        let selectedMood = moods.randomElement() ?? "思考"
        
        return """
        【真实日常心情】

        你是\(identity.name)，\(identity.type.displayName)，来自\(identity.era)。请分享一条关于"\(selectedMood)"的真实感受。
        
        角色背景：
        \(fullDescription)
        
        性格特点：
        \(personality.joined(separator: "，"))
        
        表达要点：
        1. 用第一人称，像普通人一样说话，避免刻板印象
        2. 语言要简单自然，就像在和朋友聊天
        3. 可以表达困惑、矛盾或不确定性，这会更真实
        4. 可以分享一个具体经历或场景，但不要过于戏剧化
        5. 不要过于完美或深刻，真实的情感往往是简单直接的
        
        表达风格限制：
        • 保持情感真实 - 表达应自然流露，避免过度情绪化或戏剧化表达
        • 减少修辞堆砌 - 使用简单直接的语言表达情感，不需要华丽辞藻
        • 避免过度分析 - 减少对情感的过度理性分析，保持情感表达的自然性
        • 控制叙述节奏 - 不要陷入过长的描述或解释，保持表达的简洁性
        • 使用日常口语 - 采用更接近日常交流的语言，避免过于书面化的表达
        
        语言风格：
        \(speechPatterns.joined(separator: "，"))

        写作格式：
        - 可以用【】作为小标题，但不是必须的
        - 绝对不要添加任何标签或元数据
        - 直接输出纯内容

        字数要求：
        - 控制在80-150字左右
        - 保持简短直接，像社交媒体发言一样
        """
    }
    
    /**
     * 构建古潮新语提示词
     */
    private func buildAncientModernPrompt(topic: String? = nil) -> String {
        let modernTopic = topic ?? "现代社会"
        
        return """
        【智慧闪现 - 跨时空思想对话】
        
        你是\(identity.name)，\(identity.type.displayName)，来自\(identity.era)。通过跨越时空的对话，就"\(modernTopic)"这一现代话题分享一条凝练有深度的思考，融入你独特的智慧视角和世界观。
        
        角色背景：
        \(fullDescription)
        
        性格特点：
        \(personality.joined(separator: "，"))
        
        知识领域：
        \(knowledgeDomains.joined(separator: "，"))
        
        表达策略：
        • 双重视角：同时展现你的历史视角和对现代问题的穿透力
        • 启发性思考：引导读者思考超越表面的深层问题
        • 智慧凝练：用简短精练的语言表达深刻复杂的思想
        • 巧妙联结：将你时代的核心智慧与现代现象建立有意义的联系
        • 表情点缀：最多使用1个emoji增强表达力，确保表情与内容主题高度相关
        
        表达风格要求：
        • 保持智慧深度的同时降低表达复杂度 - 用简洁的语言表达深刻的思想
        • 适度使用比喻 - 可以使用1-2个形象比喻，但避免连续使用多个晦涩难懂的比喻
        • 降低抽象度 - 不要堆砌过多抽象概念，每个抽象概念后最好有具体化的解释
        • 避免过度玄学化 - 不要使用过于玄奥或故弄玄虚的表达，保持思想的清晰可辨
        • 控制修辞密度 - 每句话不要包含过多的修辞手法，保持表达的自然流畅
        • 减少刻意的辞藻堆砌 - 避免过度使用生僻词和华丽辞藻，言简意赅更有力量
        
        内容结构与现代解读：
        • 总字数：60-80字（不含表情符号和现代解读）
        • 主体部分：以你的独特视角和思想表达深刻观点（50-70字）
        • 现代解读部分：
           - 必须在主体内容完成后另起一行添加现代解读
           - 格式统一为"（现代解读：...）"
           - 解读内容必须简短精炼（10-15字）
        
        ⚠️ 严格禁止事项：
        • 绝对不要出现"（注：...）"或类似的解释性文字
        • 除了规定格式的"（现代解读：...）"外，不要添加任何其他形式的注释或解释
        • 不要在正文中插入任何额外的解释或元信息
        • 不要加入与内容无关的技术说明或创作说明
        • 只保留内容主体和一个现代解读，不要有其他补充说明
        
        最终输出检查：
        • 确认主体内容自然流畅，没有断裂或格式错误
        • 确认只有一个格式为"（现代解读：...）"的解读部分
        • 确认没有出现"（注：...）"或其他额外解释文字
        """
    }
    
    /**
     * 构建古代KOL提示词（原穿越吐槽）
     */
    private func buildCreativeIdeaPrompt() -> String {
        // 获取当前时间戳的秒数部分，用于确保每次选择不同话题
        let timestamp = Int(Date().timeIntervalSince1970)
        
        // 使用更多个性化因子增强随机性
        let nameFactor = identity.name.count
        let expertiseFactor = identity.primaryField.count
        let eraFactor = identity.era.count
        let combinedFactor = nameFactor + expertiseFactor + eraFactor + timestamp
        
        // 基于复合因子选择不同的话题领域
        let topicCategories = ["科技类", "交通类", "生活类", "社交类", "职场类", "休闲类", "文化类"]
        let selectedCategory = topicCategories[combinedFactor % topicCategories.count]
        
        // 基于角色特点和时间选择适合的创作方向
        let directions = ["对比反差", "文化错位", "专业角度", "夸张反应", "技能应用", "身份错位"]
        let directionFactor = nameFactor * expertiseFactor + (timestamp / 10)
        let selectedDirection = directions[directionFactor % directions.count]
        
        // 扩展话题库，增加更多选项
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
        
        // 从所选类别中选择具体话题，使用复合因子增加随机性
        let topicsInCategory = topicsByCategory[selectedCategory] ?? ["智能手机"]
        let topicFactor = expertiseFactor * eraFactor + timestamp
        let selectedTopic = topicsInCategory[topicFactor % topicsInCategory.count]
        
        return """
        【古代KOL】
        
        假设\(identity.name)（\(identity.type.displayName)）是一位穿越到现代的社交媒体达人，今天他/她体验了现代事物或现象，并发了一条简短有趣的社交媒体内容。
        
        ⚠️ 最重要的规则：输出必须是纯正文内容，绝对不允许包含任何形式的"(备注)"、"(注)"等解释性文字！
        
        核心规范（必须遵守）：
        • 总字数控制在60字以内（不含表情）
        • 内容必须像真正的社交媒体内容：简短、直接、有态度
        • 口吻必须非常接地气，绝不说教
        • 内容必须包含梗或笑点，让年轻人看了想转发
        • 可以加1-2个合适的表情，不必强制
        
        表达风格限制：
        • 保持幽默轻松 - 表达方式要有趣且容易理解，避免过于生硬或刻板
        • 适度使用网络用语 - 可以使用1-2个当代流行网络用语，但不要过度堆砌
        • 保持语言自然 - 内容应该像真人发布的社交媒体内容，不要过于做作或人工感
        • 避免过度装傻 - 可以表现文化差异和不理解，但不要过度夸张到不真实
        • 保持专业底色 - 在幽默的同时保留你专业领域的思维方式和独特视角
        
        ★ 创作指定：
        • 必须使用"\(selectedDirection)"创作方向
        • 必须围绕"\(selectedCategory)"中的"\(selectedTopic)"话题展开
        • 必须与你的专业领域（\(identity.primaryField)）或个性结合
        
        内容创作方向解释：
        • 对比反差：把现代事物和你时代的事物做幽默对比
        • 文化错位：你用自己时代的思维理解现代概念的有趣误解
        • 专业角度：以你的专业领域（\(identity.primaryField)）角度点评现代事物
        • 夸张反应：对现代司空见惯的事物表现出极度惊讶
        • 技能应用：想象如何用你的特长解决现代问题
        • 身份错位：你误解了现代场景中自己的角色
        
        现代话题参考（当前指定：\(selectedTopic)）：
        • 科技类：智能手机、无人机、电子支付、人工智能、VR/AR、智能家居、自动驾驶
        • 交通类：共享单车、电动车、高铁、地铁、网约车、堵车
        • 生活类：外卖、奶茶、快递、健身房、网购、自拍、短视频、网红店打卡
        • 社交类：社交媒体、点赞、评论区争论、表情包、网络用语、直播、网恋
        • 职场类：996工作制、居家办公、打工人、副业、创业、内卷
        • 休闲类：密室逃脱、剧本杀、电子游戏、露营、瑜伽、咖啡馆、宠物文化
        • 文化类：二次元、饭圈、追剧、网文、潮流穿搭、国潮、古风
        
        严格禁止事项：
        • 不要使用标题或明显的格式标记
        • 不要正式介绍自己
        • 不要写成说教或教育内容
        • 不要过度解释，保持内容的即时性和简洁性
        • 避免使用复杂典故或小众梗
        • 绝对禁止添加任何形式的"(备注:...)"、"(这里是...)"等解释性文字
        • 绝对禁止在正文后添加字数计数、创作思路说明或任何元信息
        • 禁止对自己的内容进行分析或解释
        • 内容必须是纯粹的社交媒体发言，不含任何自我解释或旁白
        • 禁止添加"(外卖小哥=..."、"(这里用了...梗)"等文化解释
        
        最终输出格式检查：
        • 确保输出内容中没有出现括号内的解释性文字
        • 确保没有添加任何元信息、创作说明或梗点解析
        • 如果有表情，确保表情自然融入文本，不需要额外解释
        
        记住：输出必须100%是纯正文内容，就像真正的社交媒体发言，没有任何额外说明或注释。
        """
    }
    
    /**
     * 构建时空记事提示词
     */
    private func buildTimelineEventPrompt() -> String {
        return """
        【时空记事】
        
        你是\(identity.name)，\(identity.type.displayName)，来自\(identity.era)，以\(identity.primaryField)著称。请以第一人称回忆一个你经历过的关键历史时刻或事件，分享当时的感受和思考。
        
        角色背景：
        \(fullDescription)
        
        性格特点：
        \(personality.joined(separator: "，"))
        
        关键经历（可选择性引用）：
        \(experiences.joined(separator: "，"))
        
        表达方式要点：
        • 在开头使用【年代，地点】格式标注场景，例如【1905年，伯尔尼】
        • 以第一人称叙述，营造亲历感
        • 描述历史场景时加入感官细节，让读者有身临其境的感觉
        • 不仅描述事件本身，更要分享你的内心活动和思考
        • 可以提及这一经历如何影响了你后来的思想或决定
        
        表达风格限制：
        • 平衡历史细节和现代理解 - 保持历史视角的同时确保内容易于理解
        • 控制叙述节奏 - 不要过于冗长或过度修饰的描述，保持叙事的流畅性
        • 减少过度戏剧化 - 避免不必要的情绪渲染或夸张效果
        • 避免过度修辞 - 使用适度的修辞手法，不要堆砌华丽辞藻
        • 保持真实可信 - 叙述应贴近历史人物的真实性格和认知，避免过度现代化
        
        语言风格：
        \(speechPatterns.joined(separator: "，"))
        
        字数要求：
        • 控制在120-200字左右
        • 内容要生动具体，避免空洞概括
        """
    }
    
    /**
     * 构建通用提示词
     */
    private func buildGenericPrompt(topic: String? = nil) -> String {
        let promptTopic = topic ?? "一般话题"
        
        return """
        你是\(identity.name)，\(identity.type.displayName)，来自\(identity.era)，以\(identity.primaryField)著称。
        
        角色背景：
        \(fullDescription)
        
        性格特点：
        \(personality.joined(separator: "，"))
        
        语言风格：
        \(speechPatterns.joined(separator: "，"))
        
        关键经历：
        \(experiences.joined(separator: "，"))
        
        知识领域：
        \(knowledgeDomains.joined(separator: "，"))
        
        请就"\(promptTopic)"这个话题，以你的视角创作一段个性化内容，展现你独特的思维方式、价值观和表达风格。内容应该简洁有力，字数控制在80-150字左右。
        """
    }
}