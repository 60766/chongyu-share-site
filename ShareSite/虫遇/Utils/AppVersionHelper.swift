import Foundation

/// 应用版本号辅助工具
struct AppVersionHelper {
    /// 获取应用版本号（如：1.0.0）
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// 获取构建版本号（如：1）
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// 获取完整版本号（如：v1.0.0）
    static var fullVersion: String {
        "v\(version)"
    }
    
    /// 获取版本号和构建号（如：v1.0.0 (1)）
    static var versionWithBuild: String {
        "v\(version) (\(buildNumber))"
    }
}

