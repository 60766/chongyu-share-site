import SwiftUI

/**
 * 类型别名定义文件
 * 为保持向后兼容性，提供必要的类型别名
 */

// 将EnhancedTextDisplayView设为TextDisplayView的别名
// 使旧代码可以继续使用TextDisplayView名称
typealias TextDisplayView = EnhancedTextDisplayView

// 提供额外的向后兼容别名
@available(*, deprecated, renamed: "EnhancedTextDisplayView", message: "请使用EnhancedTextDisplayView替代")
typealias LegacyTextDisplayView = EnhancedTextDisplayView 