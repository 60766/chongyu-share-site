import Foundation
import SwiftUI

/**
 * 角色模型
 * 用于管理应用中的历史人物和虚构角色信息
 */
struct CharacterModel: Identifiable {
    let id = UUID()
    let name: String          // 角色名称
    let avatar: String        // 角色头像
    let era: String           // 所属年代/时期
    let profession: String    // 职业身份
    let bio: String           // 简介
    let category: CharacterCategory  // 角色分类
    let universe: String?     // 所属宇宙/世界观(虚构角色)
    let famousQuotes: [String]? // 名言/经典台词
    let characterID: String?  // 角色ID，用于API调用和统一标识
    
    // 默认初始化方法，支持向后兼容
    init(name: String, avatar: String, era: String, profession: String, bio: String, category: CharacterCategory,
         universe: String? = nil, famousQuotes: [String]? = nil, characterID: String? = nil) {
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
            name: "爱因斯坦",
            avatar: "avatar_einstein",
            era: "1879-1955",
            profession: "物理学家",
            bio: "相对论创始人，诺贝尔物理学奖获得者，20世纪最伟大的物理学家之一。",
            category: .scientist,
            famousQuotes: ["想象力比知识更重要", "我们不能用制造问题的思维方式来解决问题"],
            characterID: "einstein"
        ),
        Self(
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
            name: "达芬奇",
            avatar: "avatar_davinci",
            era: "1452-1519",
            profession: "艺术家、科学家",
            bio: "文艺复兴时期的天才，在绘画、雕塑、建筑、科学、音乐、数学等多个领域都有卓越成就。",
            category: .artist,
            famousQuotes: ["简单是最终的复杂", "艺术永远不会完成，只会被放弃"],
            characterID: "davinci"
        ),
        Self(
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
            name: "居里夫人",
            avatar: "avatar_curie",
            era: "1867-1934",
            profession: "物理学家、化学家",
            bio: "首位获得诺贝尔奖的女性，也是唯一一位在两个不同领域获得诺贝尔奖的女性科学家。",
            category: .scientist,
            famousQuotes: ["我们不应该害怕任何事，只应该去理解", "你永远不会意识到自己的强大，直到强大成为唯一的选择"],
            characterID: "curie"
        )
    ]
    
    // 示例虚构角色数据
    static let virtualCharacters: [CharacterModel] = [
        // 动漫角色
        Self(
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
            name: "福尔摩斯",
            avatar: "avatar_holmes",
            era: "维多利亚时代",
            profession: "咨询侦探",
            bio: "世界上最著名的侦探，以敏锐的观察力和推理能力解决各种复杂案件。",
            category: .fictionCharacter,
            universe: "福尔摩斯系列",
            famousQuotes: ["基本的，我亲爱的华生", "排除所有不可能的，剩下的无论多么难以置信，那就是真相"]
        ),
        Self(
            name: "钢铁侠",
            avatar: "avatar_ironman",
            era: "现代",
            profession: "天才发明家/超级英雄",
            bio: "托尼·斯塔克，斯塔克工业的CEO，凭借自己的天才头脑和钢铁战衣成为超级英雄。",
            category: .fictionCharacter,
            universe: "漫威电影宇宙",
            famousQuotes: ["我就是钢铁侠", "有时候，你得先跑起来，才知道自己要去哪"]
        )
    ]
    
    // 所有角色数据
    static var allCharacters: [CharacterModel] {
        return sampleCharacters + virtualCharacters
    }
} 