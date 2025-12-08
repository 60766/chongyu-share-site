import Foundation

/**
 * 角色显示完整性测试脚本
 * 用于验证所有169个角色是否都被正确加载和显示
 */
class CharacterDisplayTester {
    
    static func testAllCharactersLoaded() {
        #if DEBUG
        debugLog("🧪 开始测试角色显示完整性...")
        #endif
        
        let characterDataManager = CharacterDataManager.shared
        
        // 测试1：检查角色数据加载
        #if DEBUG
        debugLog("\n📊 测试1：角色数据加载检查")
        #endif
        let allCharacterIds = characterDataManager.getAllCharacterIds()
        #if DEBUG
        debugLog("📋 总角色数量：\(allCharacterIds.count)")
        #endif
        
        // 检查是否达到预期的169个角色
        if allCharacterIds.count == 169 {
            #if DEBUG
            debugLog("✅ 角色数量正确：169个")
            #endif
        } else {
            #if DEBUG
            debugLog("❌ 角色数量不正确：期望169个，实际\(allCharacterIds.count)个")
            #endif
        }
        
        // 测试2：检查角色信息完整性
        #if DEBUG
        debugLog("\n📋 测试2：角色信息完整性检查")
        #endif
        let allCharacterInfos = characterDataManager.getAllCharactersInfo()
        #if DEBUG
        debugLog("📊 角色信息数量：\(allCharacterInfos.count)")
        #endif
        
        // 检查是否有角色信息缺失
        if allCharacterInfos.count == allCharacterIds.count {
            #if DEBUG
            debugLog("✅ 所有角色都有完整信息")
            #endif
        } else {
            #if DEBUG
            debugLog("❌ 角色信息不完整：ID数量\(allCharacterIds.count)，信息数量\(allCharacterInfos.count)")
            #endif
        }
        
        // 测试3：检查关键角色是否存在
        #if DEBUG
        debugLog("\n🔍 测试3：关键角色存在性检查")
        #endif
        let keyCharacters = [
            "einstein", "shakespeare", "davinci", "kongzi", "newton",
            "sunwukong", "holmes", "ironman", "naruto", "gandalf"
        ]
        
        for characterId in keyCharacters {
            if let name = characterDataManager.getName(for: characterId) {
                #if DEBUG
                debugLog("✅ \(characterId) -> \(name)")
                #endif
            } else {
                #if DEBUG
                debugLog("❌ \(characterId) -> 未找到")
                #endif
            }
        }
        
        // 测试4：检查角色分类映射
        #if DEBUG
        debugLog("\n🏷️ 测试4：角色分类映射检查")
        #endif
        var categoryCounts: [String: Int] = [:]
        
        for characterInfo in allCharacterInfos {
            let category = mapToCharacterCategory(type: characterInfo.type, subtype: characterInfo.subtype)
            categoryCounts[category.rawValue, default: 0] += 1
        }
        
        #if DEBUG
        debugLog("📊 分类统计：")
        #endif
        for (category, count) in categoryCounts.sorted(by: { $0.value > $1.value }) {
            #if DEBUG
            debugLog("  \(category): \(count)个")
            #endif
        }
        
        // 测试5：检查头像信息
        #if DEBUG
        debugLog("\n🖼️ 测试5：头像信息检查")
        #endif
        var avatarIssues = 0
        var missingAvatars = 0
        
        for characterInfo in allCharacterInfos {
            if characterInfo.avatar.isEmpty {
                missingAvatars += 1
                #if DEBUG
                debugLog("⚠️ \(characterInfo.name) 缺少头像信息")
                #endif
            } else if characterInfo.avatar == characterInfo.id {
                avatarIssues += 1
                #if DEBUG
                debugLog("⚠️ \(characterInfo.name) 头像字段与ID相同，可能有问题")
                #endif
            }
        }
        
        if avatarIssues == 0 && missingAvatars == 0 {
            #if DEBUG
            debugLog("✅ 所有角色头像信息正常")
            #endif
        } else {
            #if DEBUG
            debugLog("❌ 发现 \(avatarIssues + missingAvatars) 个头像问题")
            #endif
        }
        
        // 测试6：检查时代和职业信息
        #if DEBUG
        debugLog("\n📅 测试6：时代和职业信息检查")
        #endif
        var missingEra = 0
        var missingProfession = 0
        
        for characterInfo in allCharacterInfos {
            if characterInfo.era.isEmpty || characterInfo.era == "未知" {
                missingEra += 1
            }
            if characterInfo.primaryField.isEmpty || characterInfo.primaryField == "未知" {
                missingProfession += 1
            }
        }
        
        #if DEBUG
        debugLog("📊 信息完整性：")
        #endif
        #if DEBUG
        debugLog("  时代信息完整：\(allCharacterInfos.count - missingEra)/\(allCharacterInfos.count)")
        #endif
        #if DEBUG
        debugLog("  职业信息完整：\(allCharacterInfos.count - missingProfession)/\(allCharacterInfos.count)")
        #endif
        
        // 测试7：检查数据一致性
        #if DEBUG
        debugLog("\n🔗 测试7：数据一致性检查")
        #endif
        let idSet = Set(allCharacterIds)
        let infoIdSet = Set(allCharacterInfos.map { $0.id })
        
        if idSet == infoIdSet {
            #if DEBUG
            debugLog("✅ 角色ID和角色信息完全一致")
            #endif
        } else {
            #if DEBUG
            debugLog("❌ 角色ID和角色信息不一致")
            #endif
            let missingInInfo = idSet.subtracting(infoIdSet)
            let extraInInfo = infoIdSet.subtracting(idSet)
            
            if !missingInInfo.isEmpty {
                #if DEBUG
                debugLog("  缺失的角色信息：\(missingInInfo.joined(separator: ", "))")
                #endif
            }
            if !extraInInfo.isEmpty {
                #if DEBUG
                debugLog("  多余的角色信息：\(extraInInfo.joined(separator: ", "))")
                #endif
            }
        }
        
        // 总结
        #if DEBUG
        debugLog("\n🎯 测试总结：")
        #endif
        #if DEBUG
        debugLog("📊 总角色数：\(allCharacterIds.count)")
        #endif
        #if DEBUG
        debugLog("📋 角色信息数：\(allCharacterInfos.count)")
        #endif
        #if DEBUG
        debugLog("🏷️ 分类数量：\(categoryCounts.count)")
        #endif
        #if DEBUG
        debugLog("🖼️ 头像问题：\(avatarIssues + missingAvatars)")
        #endif
        #if DEBUG
        debugLog("📅 信息缺失：时代\(missingEra)个，职业\(missingProfession)个")
        #endif
        
        if allCharacterIds.count == 169 && allCharacterInfos.count == 169 {
            #if DEBUG
            debugLog("🎉 所有169个角色都已正确加载！")
            #endif
        } else {
            #if DEBUG
            debugLog("⚠️ 存在角色加载问题，需要进一步检查")
            #endif
        }
    }
    
    /**
     * 将角色的type和subtype映射到CharacterCategory
     */
    private static func mapToCharacterCategory(type: String, subtype: String) -> CharacterCategory {
        switch (type, subtype) {
        case ("historical", "scientist"), ("literary", "scientist"), ("movie", "scientist"), ("anime", "scientist"),
             ("historical", "artist"), ("literary", "artist"), ("movie", "artist"), ("anime", "artist"):
            // 科学家和艺术家合并到历史人物
            return .historical
        case ("historical", "writer"), ("literary", "writer"), ("movie", "writer"), ("anime", "writer"):
            return .writer
        case ("historical", "philosopher"), ("literary", "philosopher"), ("movie", "philosopher"), ("anime", "philosopher"):
            return .philosopher
        case ("historical", "politician"), ("literary", "politician"), ("movie", "politician"), ("anime", "politician"):
            return .historical
        case ("historical", "military"), ("literary", "military"), ("movie", "military"), ("anime", "military"):
            return .historical
        case ("historical", "explorer"), ("literary", "explorer"), ("movie", "explorer"), ("anime", "explorer"):
            return .historical
        case ("historical", "inventor"), ("literary", "inventor"), ("movie", "inventor"), ("anime", "inventor"),
             ("historical", "musician"), ("literary", "musician"), ("movie", "musician"), ("anime", "musician"):
            // 发明家和音乐家合并到历史人物
            return .historical
        case ("historical", "athlete"), ("literary", "athlete"), ("movie", "athlete"), ("anime", "athlete"):
            return .historical
        case ("historical", "business"), ("literary", "business"), ("movie", "business"), ("anime", "business"):
            return .historical
        case ("historical", "religious"), ("literary", "religious"), ("movie", "religious"), ("anime", "religious"):
            return .historical
        case ("historical", "mythological"), ("literary", "mythological"), ("movie", "mythological"), ("anime", "mythological"):
            return .mythCharacter
        case ("historical", "fictional"), ("literary", "fictional"), ("movie", "fictional"), ("anime", "fictional"):
            return .animeCharacter  // 虚构角色归为动漫角色
        default:
            // 根据type进行默认分类
            switch type {
            case "historical":
                return .historical
            case "literary":
                return .writer
            case "movie", "tv":
                return .filmCharacter
            case "anime":
                return .animeCharacter
            case "game":
                return .gameCharacter
            default:
                return .historical
            }
        }
    }
}

// 测试入口点 - 可以在需要时调用
// CharacterDisplayTester.testAllCharactersLoaded() 