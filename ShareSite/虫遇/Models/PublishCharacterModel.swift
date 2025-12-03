import Foundation
import SwiftUI

/**
 * 发布页面使用的角色模型
 * 用于在发布页面和评论中展示历史人物
 */
struct PHCharacterModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let introduction: String
    let field: String
    let birthYear: String
    let deathYear: String?
    let avatarUrl: String
    let eraTag: String
    
    // 初始化方法
    init(name: String, introduction: String, field: String, birthYear: String, deathYear: String?, avatarUrl: String, eraTag: String) {
        self.name = name
        self.introduction = introduction
        self.field = field
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.avatarUrl = avatarUrl
        self.eraTag = eraTag
    }
    
    // 实现 Equatable 协议的 static func ==
    static func == (lhs: PHCharacterModel, rhs: PHCharacterModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 示例数据
    static var samples: [PHCharacterModel] {
        return [
            PHCharacterModel(
                name: "爱因斯坦",
                introduction: "现代物理学最重要的科学家之一",
                field: "物理学家",
                birthYear: "1879",
                deathYear: "1955",
                avatarUrl: "https://example.com/einstein.jpg",
                eraTag: "现代"
            ),
            PHCharacterModel(
                name: "莎士比亚",
                introduction: "英国剧作家、诗人",
                field: "文艺",
                birthYear: "1564",
                deathYear: "1616",
                avatarUrl: "https://example.com/shakespeare.jpg",
                eraTag: "文艺复兴"
            ),
            PHCharacterModel(
                name: "孔子",
                introduction: "中国古代思想家、教育家",
                field: "哲学",
                birthYear: "公元前551年",
                deathYear: "公元前479年",
                avatarUrl: "https://example.com/confucius.jpg",
                eraTag: "春秋时期"
            )
        ]
    }
}

// 扩展以兼容CharacterModel接口
extension PHCharacterModel {
    // 模拟CharacterModel的属性
    var avatar: String { return avatarUrl }
    var era: String { return "\(birthYear)-\(deathYear ?? "现在")" }
    var profession: String { return field }
    var bio: String { return introduction }
    var category: CharacterCategory {
        switch field.lowercased() {
        case "物理学家", "科学家", "艺术家":
            // 科学家和艺术家合并到历史人物
            return .historical
        case "哲学家":
            return .philosopher
        case "文艺", "剧作家", "诗人":
            return .writer
        default:
            return .all
        }
    }
    
    // 静态方法以支持CharacterModel的接口
    static func getDefaultCategory(name: String) -> CharacterCategory {
        return .all
    }
}