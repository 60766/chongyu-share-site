import Foundation

// 这个脚本将添加同地区角色推荐功能
// 请将这段代码手动添加到HistoricalFigureSelectionViewModel.swift文件中

/**
 * 获取同地区的角色
 */
private func getSameRegionCharacters(for author: AppCharacter, excluding: [AppCharacter]) -> [AppCharacter] {
    let excludedIds = excluding.map { $0.id } + [author.id]
    // 提取主要地区（处理多地区情况，如"德国/美国"）
    let mainRegion = author.region.split(separator: "/").first?.lowercased() ?? ""
    
    return allCharacters.filter { character in
        if excludedIds.contains(character.id) {
            return false
        }
        
        // 检查地区是否匹配（考虑多地区情况）
        let characterRegions = character.region.lowercased().split(separator: "/")
        for region in characterRegions {
            if region.contains(mainRegion) || mainRegion.contains(region) {
                return true
            }
        }
        return false
    }
}

// 修改getRecommendedCharacters方法，在同类型和同时代之间添加同地区优先级
// 在getSameTypeCharacters调用后添加：

if recommendedCharacters.count < 6 {
    let sameRegionCharacters = getSameRegionCharacters(for: author, excluding: recommendedCharacters)
    let neededCount = min(6 - recommendedCharacters.count, sameRegionCharacters.count)
    recommendedCharacters.append(contentsOf: sameRegionCharacters.prefix(neededCount))
}
