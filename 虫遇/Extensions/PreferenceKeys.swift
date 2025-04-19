import SwiftUI

/**
 * @description 滚动偏移量偏好键，用于跟踪ScrollView的滚动位置
 */
struct AppScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/**
 * @description 内容宽度偏好键，用于测量ScrollView内容的总宽度
 */
struct ContentWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/**
 * @description 可见宽度偏好键，用于测量ScrollView可见区域的宽度
 */
struct ViewportWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
} 