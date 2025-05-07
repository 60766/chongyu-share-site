import Foundation

/**
 * 聊天角色模型
 * 用于ChatView中表示对话角色
 */
struct CYChatCharacter: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var introduction: String
    var field: String
    var birthYear: String
    var deathYear: String
    var avatarUrl: String
    var eraTag: String
    var achievements: [String]
    var mainWorks: [String]
    var keyThoughts: [String]
    var followerCount: Int
    var interactionCount: Int
    var rating: Double
    
    init(
        id: String = UUID().uuidString,
        name: String,
        introduction: String,
        field: String,
        birthYear: String,
        deathYear: String,
        avatarUrl: String,
        eraTag: String,
        achievements: [String],
        mainWorks: [String],
        keyThoughts: [String],
        followerCount: Int = 0,
        interactionCount: Int = 0,
        rating: Double = 4.5
    ) {
        self.id = id
        self.name = name
        self.introduction = introduction
        self.field = field
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.avatarUrl = avatarUrl
        self.eraTag = eraTag
        self.achievements = achievements
        self.mainWorks = mainWorks
        self.keyThoughts = keyThoughts
        self.followerCount = followerCount
        self.interactionCount = interactionCount
        self.rating = rating
    }
} 