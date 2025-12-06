import Foundation
import SwiftUI

/**
 * 角色模型
 * 用于管理应用中的历史人物和虚构角色信息
 */
struct CharacterModel: Identifiable, Hashable {
    // 原来的第一个定义
    var id: String
    var name: String
    var avatar: String
    var era: String
    var profession: String
    var bio: String
    var category: CharacterCategory
    
    // 来自第二个定义的额外属性
    var universe: String?     // 所属宇宙/世界观(虚构角色)
    var famousQuotes: [String]? // 名言/经典台词
    var characterID: String?  // 角色ID，用于API调用和统一标识
    
    // 默认初始化方法，支持向后兼容
    init(id: String = UUID().uuidString, name: String, avatar: String, era: String, profession: String, bio: String, category: CharacterCategory,
         universe: String? = nil, famousQuotes: [String]? = nil, characterID: String? = nil) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.era = era
        self.profession = profession
        self.bio = bio
        self.category = category
        self.universe = universe
        self.famousQuotes = famousQuotes
        self.characterID = characterID
    }
    
    // 从AppCharacter创建CharacterModel
    init(from appCharacter: AppCharacter) {
        self.id = appCharacter.id
        self.name = appCharacter.name
        self.avatar = appCharacter.avatarName
        self.era = appCharacter.era
        self.profession = appCharacter.primaryField
        self.bio = appCharacter.briefDescription
        
        // 根据角色类型和子类型设置分类
        switch appCharacter.type {
        case "historical":
            switch appCharacter.subtype {
            case "scientist", "artist":
                // 科学家和艺术家合并到历史人物
                self.category = .historical
            case "philosopher":
                self.category = .philosopher
            case "writer":
                self.category = .writer
            default:
                self.category = .historical
            }
        case "literary":
            self.category = .writer
        case "movie", "tv":
            self.category = .filmCharacter  // 电影和电视剧都归为影视角色
        case "anime":
            self.category = .animeCharacter
        case "mythological":
            self.category = .mythCharacter
        case "game":
            self.category = .gameCharacter
        default:
            // 如果type未知，尝试通过subtype判断
            switch appCharacter.subtype {
            case "scientist", "artist":
                // 科学家和艺术家合并到历史人物
                self.category = .historical
            case "philosopher":
                self.category = .philosopher
            case "writer":
                self.category = .writer
            default:
                self.category = .historical
            }
        }
        
        self.universe = nil
        self.famousQuotes = nil
        self.characterID = appCharacter.id
    }
    
    // 判断是否为虚构角色
    var isVirtual: Bool {
        return category.isVirtual
    }
    
    // 获取角色标签
    var tags: [String] {
        var result = [category.rawValue]
        
        if let universe = universe, !universe.isEmpty {
            result.append(universe)
        }
        
        return result
    }
    
    // 示例历史人物数据
    static let sampleCharacters: [CharacterModel] = [
        Self(
            id: "einstein",
            name: "爱因斯坦",
            avatar: "avatar_einstein",
            era: "1879-1955",
            profession: "物理学家",
            bio: "相对论创始人，诺贝尔物理学奖获得者，20世纪最伟大的物理学家之一。",
            category: .historical,
            famousQuotes: ["想象力比知识更重要", "我们不能用制造问题的思维方式来解决问题"],
            characterID: "einstein"
        ),
        Self(
            id: "shakespeare",
            name: "莎士比亚",
            avatar: "avatar_shakespeare",
            era: "1564-1616",
            profession: "剧作家、诗人",
            bio: "英国文学史上最杰出的作家，被誉为\"人类文学史上的一座高峰\"。",
            category: .writer,
            famousQuotes: ["生存还是毁灭，这是一个问题", "我们由梦想构成，我们的小生命被睡眠包围"],
            characterID: "shakespeare"
        ),
        Self(
            id: "davinci",
            name: "达芬奇",
            avatar: "avatar_davinci",
            era: "1452-1519",
            profession: "艺术家、科学家",
            bio: "文艺复兴时期的天才，在绘画、雕塑、建筑、科学、音乐、数学等多个领域都有卓越成就。",
            category: .historical,
            famousQuotes: ["简单是最终的复杂", "艺术永远不会完成，只会被放弃"],
            characterID: "davinci"
        ),
        Self(
            id: "socrates",
            name: "苏格拉底",
            avatar: "avatar_socrates",
            era: "公元前469-前399",
            profession: "哲学家",
            bio: "古希腊哲学家，西方哲学的奠基人之一，以苏格拉底方法闻名。",
            category: .philosopher,
            famousQuotes: ["我只知道一件事，那就是我什么都不知道", "未经审视的生活不值得过"],
            characterID: "socrates"
        ),
        Self(
            id: "curie",
            name: "居里夫人",
            avatar: "avatar_curie",
            era: "1867-1934",
            profession: "物理学家、化学家",
            bio: "首位获得诺贝尔奖的女性，也是唯一一位在两个不同领域获得诺贝尔奖的女性科学家。",
            category: .historical,
            famousQuotes: ["我们不应该害怕任何事，只应该去理解", "你永远不会意识到自己的强大，直到强大成为唯一的选择"],
            characterID: "curie"
        )
    ]
    
    // 示例虚构角色数据
    static let virtualCharacters: [CharacterModel] = [
        // 动漫角色
        Self(
            id: "goku",
            name: "孙悟空",
            avatar: "avatar_goku",
            era: "1984-现在",
            profession: "武道家",
            bio: "《龙珠》系列主角，热爱战斗和变强，拥有不断突破自我极限的坚韧精神。",
            category: .animeCharacter,
            universe: "龙珠",
            famousQuotes: ["我要超越超级赛亚人！", "这还不是我的最终形态！"],
            characterID: "sunwukong"
        ),
        Self(
            id: "naruto",
            name: "漩涡鸣人",
            avatar: "avatar_naruto",
            era: "1999-2014",
            profession: "忍者",
            bio: "《火影忍者》主角，木叶村的第七代火影，拥有永不放弃的忍道精神。",
            category: .animeCharacter,
            universe: "火影忍者",
            famousQuotes: ["我绝对不会放弃，这就是我的忍道！", "相信自己，这就是成为强者的秘诀。"]
        ),
        
        // 游戏角色
        Self(
            id: "mario",
            name: "马里奥",
            avatar: "avatar_mario",
            era: "1981-现在",
            profession: "水管工/冒险家",
            bio: "任天堂标志性角色，蘑菇王国的英雄，一直在营救被库巴绑架的碧琪公主。",
            category: .gameCharacter,
            universe: "超级马里奥",
            famousQuotes: ["It's-a me, Mario!", "Let's-a go!"]
        ),
        Self(
            id: "link",
            name: "林克",
            avatar: "avatar_link",
            era: "1986-现在",
            profession: "勇者",
            bio: "《塞尔达传说》系列主角，海拉鲁王国的英雄，持有勇气三角力量。",
            category: .gameCharacter,
            universe: "塞尔达传说",
            famousQuotes: ["...", "Hyah!"]
        ),
        
        // 虚构人物
        Self(
            id: "holmes",
            name: "福尔摩斯",
            avatar: "avatar_holmes",
            era: "维多利亚时代",
            profession: "咨询侦探",
            bio: "世界上最著名的侦探，以敏锐的观察力和推理能力解决各种复杂案件。",
            category: .filmCharacter,
            universe: "福尔摩斯系列",
            famousQuotes: ["基本的，我亲爱的华生", "排除所有不可能的，剩下的无论多么难以置信，那就是真相"]
        ),
        Self(
            id: "ironman",
            name: "钢铁侠",
            avatar: "avatar_ironman",
            era: "现代",
            profession: "天才发明家/超级英雄",
            bio: "托尼·斯塔克，斯塔克工业的CEO，凭借自己的天才头脑和钢铁战衣成为超级英雄。",
            category: .filmCharacter,
            universe: "漫威电影宇宙",
            famousQuotes: ["我就是钢铁侠", "有时候，你得先跑起来，才知道自己要去哪"]
        )
    ]
    
    // 所有示例角色数据
    static var allCharacters: [CharacterModel] {
        return sampleCharacters + virtualCharacters
    }
    
    // 从JSON文件加载所有角色（应用分类过滤，用于帖子生成）
    static func getAllCharacters() -> [CharacterModel] {
        // 加载系统角色
        var allCharacters = loadAllCharactersFromJSON()
        
        // 🔒 加载用户创建的角色并合并
        let userCreatedCharacters = loadUserCreatedCharacters()
        allCharacters.append(contentsOf: userCreatedCharacters)
        
        // 应用分类过滤（如果用户屏蔽了某些分类）
        return BlockedCategoriesManager.shared.filterCharacters(allCharacters)
    }
    
    /**
     * 加载用户创建的角色（从UserDefaults）
     * @return 用户创建的角色列表
     */
    private static func loadUserCreatedCharacters() -> [CharacterModel] {
        guard let data = UserDefaults.standard.data(forKey: "CustomCharactersData") else {
            return []
        }
        
        do {
            if let customCharacters = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return customCharacters.compactMap { characterDict -> CharacterModel? in
                    guard let id = characterDict["id"] as? String,
                          let name = characterDict["name"] as? String else {
                        return nil
                    }
                    
                    // 解析分类
                    let categoryString = characterDict["category"] as? String ?? "历史人物"
                    let category = CharacterCategory(rawValue: categoryString) ?? .historical
                    
                    // 创建CharacterModel
                    return CharacterModel(
                        id: id,
                        name: name,
                        avatar: characterDict["avatar"] as? String ?? "person.circle.fill",
                        era: characterDict["era"] as? String ?? "",
                        profession: characterDict["profession"] as? String ?? "",
                        bio: characterDict["bio"] as? String ?? "",
                        category: category,
                        universe: characterDict["universe"] as? String,
                        famousQuotes: characterDict["famousQuotes"] as? [String],
                        characterID: id
                    )
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ 加载用户创建的角色失败: \(error)")
            #endif
        }
        
        return []
    }
    
    // 从JSON文件加载所有角色（不应用过滤，用于探索页面显示）
    static func loadAllCharactersWithoutFilter() -> [CharacterModel] {
        // 加载系统角色
        var allCharacters = loadAllCharactersFromJSON()
        
        // 🔒 加载用户创建的角色并合并（不应用过滤，用于统计显示）
        let userCreatedCharacters = loadUserCreatedCharacters()
        allCharacters.append(contentsOf: userCreatedCharacters)
        
        return allCharacters
    }
    
    // 从JSON文件加载所有角色（不应用过滤）
    private static func loadAllCharactersFromJSON() -> [CharacterModel] {

        
        // 尝试加载characters.json
        if let url = Bundle.main.url(forResource: "characters", withExtension: "json"),
           let data = try? Data(contentsOf: url) {

            
            do {
                // 解析JSON数据
                let decoder = JSONDecoder()
                let characterData = try decoder.decode(CharacterLibrary.self, from: data)

                
                // 将AppCharacter转换为CharacterModel
                let characters = characterData.characters.map { CharacterModel(from: $0) }

                

                
                return characters
            } catch {

            }
        } else {

        }
        
        // 如果加载失败，尝试加载备用文件
        for fileName in ["characters_fixed2", "characters_clean"] {
            if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                print("\(fileName).json文件大小: \(data.count) 字节")
                
                do {
                    // 解析JSON数据
                    let decoder = JSONDecoder()
                    let characterData = try decoder.decode(CharacterLibrary.self, from: data)
                    print("成功解析\(fileName).json，包含\(characterData.characters.count)个角色")
                    
                    // 将AppCharacter转换为CharacterModel
                    let characters = characterData.characters.map { CharacterModel(from: $0) }
                    print("成功转换为CharacterModel，共\(characters.count)个角色")
                    
                    return characters
                } catch {
                    print("解析\(fileName).json失败: \(error)")
                }
            }
        }
        
        // 如果所有文件都加载失败，返回示例数据
        print("所有JSON文件加载失败，返回示例数据")
        return allCharacters
    }
} 