import Foundation
import SwiftUI

/**
 * 评论系统中使用的历史人物模型
 * 用于在评论功能中表示历史人物
 */
struct CommentHistoricalFigure: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let introduction: String
    let field: String
    let birthYear: String
    let deathYear: String
    let avatarUrl: String
    let eraTag: String
    
    /**
     * 初始化方法
     * @param name - 人物名称
     * @param introduction - 人物简介
     * @param field - 领域/职业
     * @param birthYear - 出生年份
     * @param deathYear - 逝世年份
     * @param avatarUrl - 头像URL
     * @param eraTag - 时代标签
     */
    init(name: String, introduction: String, field: String, birthYear: String, deathYear: String, avatarUrl: String, eraTag: String) {
        self.name = name
        self.introduction = introduction
        self.field = field
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.avatarUrl = avatarUrl
        self.eraTag = eraTag
    }
    
    /**
     * 从AppCharacter创建CommentHistoricalFigure
     * @param character - AppCharacter对象
     */
    init(from character: AppCharacter) {
        self.name = character.name
        self.introduction = character.briefDescription
        self.field = character.primaryField
        self.birthYear = character.era // 简化处理，直接使用era
        self.deathYear = "" // 大多数情况下没有死亡年份
        self.avatarUrl = character.avatarName
        self.eraTag = character.era
    }
    
    /**
     * 获取人物简短描述
     * @return String - 人物简短描述
     */
    var shortDescription: String {
        return "\(name) (\(birthYear)-\(deathYear))"
    }
    
    /**
     * 获取人物领域描述
     * @return String - 人物领域描述
     */
    var fieldDescription: String {
        return field
    }
    
    // Hashable协议实现
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CommentHistoricalFigure, rhs: CommentHistoricalFigure) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 示例数据 - 用于测试和UI预览
    static var samples: [CommentHistoricalFigure] {
        return [
            CommentHistoricalFigure(
                name: "爱因斯坦",
                introduction: "现代物理学最重要的科学家之一",
                field: "物理学家",
                birthYear: "1879",
                deathYear: "1955",
                avatarUrl: "einstein",
                eraTag: "现代"
            ),
            CommentHistoricalFigure(
                name: "莎士比亚",
                introduction: "英国剧作家、诗人",
                field: "文艺",
                birthYear: "1564",
                deathYear: "1616",
                avatarUrl: "shakespeare",
                eraTag: "文艺复兴"
            ),
            CommentHistoricalFigure(
                name: "孔子",
                introduction: "中国古代思想家、教育家",
                field: "哲学",
                birthYear: "公元前551年",
                deathYear: "公元前479年",
                avatarUrl: "kongzi",
                eraTag: "春秋时期"
            )
        ]
    }
}
 