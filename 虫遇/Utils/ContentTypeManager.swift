import Foundation

/**
 * 内容类型管理器
 * 管理应用中的内容类型
 */
class ContentTypeManager {
    // 单例实例
    static let shared = ContentTypeManager()
    private init() {}
    
    // 内容类型数组，基于 ContentGeneratorService 中定义的 ContentType 枚举
    let contentTypes: [ContentGeneratorService.ContentType] = ContentGeneratorService.ContentType.allCases
    
    /**
     * 获取类型名称
     */
    func getTypeName(for index: Int) -> String {
        guard index >= 0 && index < contentTypes.count else {
            return "未知类型"
        }
        return contentTypes[index].rawValue
    }
    
    /**
     * 根据索引获取内容类型
     */
    func getContentType(for index: Int) -> ContentGeneratorService.ContentType? {
        guard index >= 0 && index < contentTypes.count else {
            return nil
        }
        return contentTypes[index]
    }
} 