import Foundation

/**
 * AppCharacter模型
 * 用于解析characters.json文件中的角色数据
 */
struct AppCharacter: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let type: String
    let subtype: String
    let era: String
    let primaryField: String
    let briefDescription: String
    let avatarName: String
    let region: String
    let contentAffinities: [String: Double]
    let relatedCharacterIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, type, subtype, era, primaryField, briefDescription, avatarName, region, contentAffinities, relatedCharacterIds
    }

    init(id: String, name: String, type: String, subtype: String, era: String, primaryField: String, briefDescription: String, avatarName: String, region: String, contentAffinities: [String: Double], relatedCharacterIds: [String]? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.subtype = subtype
        self.era = era
        self.primaryField = primaryField
        self.briefDescription = briefDescription
        self.avatarName = avatarName
        self.region = region
        self.contentAffinities = contentAffinities
        self.relatedCharacterIds = relatedCharacterIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 必需字段
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        // 可选字段，提供默认值
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "historical"
        subtype = try container.decodeIfPresent(String.self, forKey: .subtype) ?? "other"
        era = try container.decodeIfPresent(String.self, forKey: .era) ?? "未知"
        primaryField = try container.decodeIfPresent(String.self, forKey: .primaryField) ?? "未知"
        briefDescription = try container.decodeIfPresent(String.self, forKey: .briefDescription) ?? ""
        avatarName = try container.decodeIfPresent(String.self, forKey: .avatarName) ?? id
        region = try container.decodeIfPresent(String.self, forKey: .region) ?? "未知"

        // 处理contentAffinities，如果解析失败则提供空字典
        do {
            contentAffinities = try container.decodeIfPresent([String: Double].self, forKey: .contentAffinities) ?? [:]
        } catch {
            print("解析角色 \(name) 的contentAffinities失败: \(error)")
            contentAffinities = [:]
        }

        // 可选的关联角色ID
        relatedCharacterIds = try container.decodeIfPresent([String].self, forKey: .relatedCharacterIds)
    }

    // 实现Equatable协议
    static func == (lhs: AppCharacter, rhs: AppCharacter) -> Bool {
        return lhs.id == rhs.id
    }

    // 实现Hashable协议
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/**
 * CharacterLibrary结构体
 * 用于解析characters.json文件
 */
struct CharacterLibrary: Codable {
    let version: String
    let characters: [AppCharacter]

    enum CodingKeys: String, CodingKey {
        case version, characters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0"

        // 尝试解析角色数组，如果失败则提供空数组
        do {
            characters = try container.decode([AppCharacter].self, forKey: .characters)
            // 已移除调试日志
        } catch {
            #if DEBUG
            print("⚠️ 解析角色数组失败: \(error)")
            #endif
            characters = []
        }
    }
}
