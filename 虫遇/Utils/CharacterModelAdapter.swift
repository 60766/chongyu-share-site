import Foundation
import SwiftUI

/**
 * 角色模型适配器
 * 用于在不同的角色模型之间进行转换
 */
class CharacterModelAdapter {
    
    /**
     * 将PHCharacterModel转换为CharacterModel
     */
    static func toCharacterModel(_ publishModel: PHCharacterModel) -> CharacterModel {
        return CharacterModel(
            name: publishModel.name,
            avatar: "character_avatar", // 使用默认头像
            era: "\(publishModel.birthYear)-\(publishModel.deathYear ?? "现在")",
            profession: publishModel.field,
            bio: publishModel.introduction,
            category: CharacterCategory.getDefaultForName(publishModel.name)
        )
    }
    
    /**
     * 将CharacterModel转换为PHCharacterModel
     */
    static func toPublishCharacterModel(_ characterModel: CharacterModel) -> PHCharacterModel {
        let parts = characterModel.era.split(separator: "-")
        let birthYear = String(parts.first ?? "")
        let deathYear = parts.count > 1 ? String(parts[1]) : nil
        
        return PHCharacterModel(
            name: characterModel.name,
            introduction: characterModel.bio,
            field: characterModel.profession,
            birthYear: birthYear,
            deathYear: deathYear,
            avatarUrl: "https://example.com/\(characterModel.avatar).jpg",
            eraTag: characterModel.era
        )
    }
    
    /**
     * 将PHCharacterModel转换为CommentHistoricalFigure
     */
    static func toCommentHistoricalFigure(_ character: PHCharacterModel) -> CommentHistoricalFigure {
        return CommentHistoricalFigure(
            name: character.name,
            introduction: character.introduction,
            field: character.field,
            birthYear: character.birthYear,
            deathYear: character.deathYear ?? "现在",
            avatarUrl: character.avatarUrl,
            eraTag: character.eraTag
        )
    }
    
    /**
     * 将CommentHistoricalFigure转换为PHCharacterModel
     */
    static func toPublishCharacterModelFromComment(_ character: CommentHistoricalFigure) -> PHCharacterModel {
        return PHCharacterModel(
            name: character.name,
            introduction: character.introduction,
            field: character.field,
            birthYear: character.birthYear,
            deathYear: character.deathYear,
            avatarUrl: character.avatarUrl,
            eraTag: character.eraTag
        )
    }
}