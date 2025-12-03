import SwiftUI

// MARK: - 圆角扩展
extension View {
    func appCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(AppRoundedCorner(radius: radius, corners: corners))
    }
    
    // MARK: - onChange 兼容扩展
    /// 兼容不同版本 SwiftUI 的 onChange 方法
    @available(iOS 17.0, *)
    func onChangeCompat<Value: Equatable>(of value: Value, perform action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void) -> some View {
        return self.onChange(of: value) { oldValue, newValue in
            action(oldValue, newValue)
        }
    }
    
    // MARK: - onHover 兼容扩展
    /// 兼容不同平台的 onHover 方法
    func onHover(perform action: @escaping (Bool) -> Void) -> some View {
        #if os(macOS)
            return self.onHover(perform: action)
        #else
            // iOS不支持悬停，所以返回原始视图
            return self
        #endif
    }
}

// MARK: - 自定义圆角形状
struct AppRoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
        self.radius = radius
        self.corners = corners
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 