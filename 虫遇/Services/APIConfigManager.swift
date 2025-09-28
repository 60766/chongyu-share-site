import Foundation
import Security
import Combine

/**
 * API配置管理器 (安全版本)
 * 仅负责管理应用配置信息，所有API调用都通过后端代理
 * 不再存储或管理真实API密钥
 */
class APIConfigManager {
    static let shared = APIConfigManager()
    
    // 服务标识符，规范化命名
    private let serviceIdentifier = "com.shilong111234.chongyu.config"
    
    // 用于存储异步操作的订阅
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        print("🔧 APIConfigManager 初始化 - 安全模式")
        print("ℹ️ 所有AI功能通过后端代理，无需客户端API密钥")
    }
    
    // MARK: - 配置信息 (只读)
    
    /**
     * 获取后端代理地址
     * 这是唯一需要的配置，用于连接后端服务
     */
    var backendBaseURL: String? {
        // 优先级：环境变量 -> Info.plist -> UserDefaults
        if let override = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"] {
            return override
        }
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String {
            return plistURL
        }
        if let userDefault = UserDefaults.standard.string(forKey: "BackendBaseURL") {
            return userDefault
        }
        return nil
    }
    
    /**
     * 获取应用Bundle ID
     */
    var appBundleID: String {
        return Bundle.main.bundleIdentifier ?? "com.shilong111234.chongyu"
    }
    
    // MARK: - 已弃用的方法 (保持兼容性)
    
    /**
     * @deprecated 不再需要客户端API密钥，所有调用通过后端代理
     */
    @available(*, deprecated, message: "API调用已迁移到后端代理，无需客户端密钥")
    var hasValidAPIKey: Bool {
        print("⚠️ hasValidAPIKey已弃用 - 使用后端代理，无需客户端验证")
        return true // 返回true保持兼容性
    }
    
    /**
     * @deprecated 端点切换已迁移到后端服务器
     */
    @available(*, deprecated, message: "端点切换已迁移到后端服务器")
    func switchEndpoint() {
        print("⚠️ switchEndpoint已弃用 - 端点管理已迁移到后端")
    }
    
    /**
     * @deprecated 不再需要客户端管理API端点
     */
    @available(*, deprecated, message: "API端点管理已迁移到后端")
    var deepSeekEndpoint: String {
        print("⚠️ deepSeekEndpoint已弃用 - 请使用后端代理")
        return "DEPRECATED_USE_BACKEND_PROXY"
    }
    
    /**
     * @deprecated 不再需要客户端管理模型名称
     */
    @available(*, deprecated, message: "模型管理已迁移到后端")
    var modelName: String {
        print("⚠️ modelName已弃用 - 请使用后端代理")
        return "DEPRECATED_USE_BACKEND_PROXY"
    }
    
    /**
     * @deprecated 不再存储客户端API密钥
     */
    @available(*, deprecated, message: "API密钥管理已迁移到后端")
    var apiKey: String? {
        print("⚠️ apiKey已弃用 - API密钥现在安全存储在后端")
        return nil
    }
    
    // MARK: - 配置验证
    
    /**
     * 验证应用配置是否正确
     */
    func validateConfiguration() -> Bool {
        guard let backendURL = backendBaseURL, !backendURL.isEmpty else {
            print("❌ 后端服务地址未配置")
            return false
        }
        
        guard URL(string: backendURL) != nil else {
            print("❌ 后端服务地址格式无效: \(backendURL)")
            return false
        }
        
        print("✅ 应用配置验证通过")
        print("🌐 后端服务地址: \(backendURL)")
        print("📱 应用Bundle ID: \(appBundleID)")
        return true
    }
    
    // MARK: - 清理方法
    
    /**
     * 清理旧的钥匙串数据
     */
    func cleanupLegacyKeychain() {
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.虫遇.apikeys", // 旧的服务标识符
            kSecAttrAccount as String: "deepseek_api_key"
        ]
        
        let status = SecItemDelete(deleteQuery as CFDictionary)
        if status == errSecSuccess {
            print("🧹 已清理旧的API密钥数据")
        }
    }
} 