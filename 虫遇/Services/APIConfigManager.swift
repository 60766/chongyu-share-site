import Foundation
import Security
import Combine

/**
 * API配置管理器
 * 负责管理和存储API密钥
 */
class APIConfigManager {
    static let shared = APIConfigManager()
    
    // DeepSeek API密钥
    private(set) var apiKey: String?
    
    // API端点选项
    private let primaryEndpoint = "https://api.deepseek.com/v1/chat/completions"
    private let fallbackEndpoint = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    
    // 当前使用的端点索引 (0:主要端点, 1:备用端点)
    private(set) var currentEndpointIndex = 0
    
    // 当前API端点
    var deepSeekEndpoint: String {
        return currentEndpointIndex == 0 ? primaryEndpoint : fallbackEndpoint
    }
    
    // API模型名称
    var modelName: String {
        return currentEndpointIndex == 0 ? "deepseek-chat" : "deepseek-r1-250120"
    }
    
    // 切换API端点
    func switchEndpoint() {
        currentEndpointIndex = (currentEndpointIndex + 1) % 2
        print("⚙️ 切换到API端点: \(deepSeekEndpoint)")
        print("⚙️ 使用模型: \(modelName)")
    }
    
    // 服务标识符，用于钥匙串存储
    private let serviceIdentifier = "com.虫遇.apikeys"
    
    // 默认API密钥 - 如果Info.plist中未设置，则使用此密钥
    // ARK格式API密钥，已设置为有效密钥
    private let defaultAPIKey = "5ec25df2-f799-4fc0-8ee2-ac13d473131b"
    
    // 用于存储异步操作的订阅
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 从钥匙串加载API密钥
        loadAPIKey()
        
        // 确保API配置有效
        validateAndSetupAPI()
    }
    
    // 验证并设置API配置
    private func validateAndSetupAPI() {
        // 如果API密钥为空或无效，使用默认密钥
        if !hasValidAPIKey || !isValidAPIKeyFormat(apiKey) {
            print("⚠️ API密钥无效或为空，使用默认密钥")
            setAPIKey(defaultAPIKey)
        }
        
        // 确保使用ARK端点（更稳定的选择）
        if currentEndpointIndex != 1 {
            currentEndpointIndex = 1
            print("⚙️ 强制使用ARK API端点: \(deepSeekEndpoint)")
        }
        
        print("🔧 API配置已验证并设置：")
        print("🔑 API密钥: \(apiKey?.prefix(8) ?? "nil")...")
        print("🌐 端点: \(deepSeekEndpoint)")
        print("🤖 模型: \(modelName)")
    }

    // 从钥匙串加载API密钥
    private func loadAPIKey() {
        print("🔑 尝试加载API密钥...")
        
        // 首先尝试从钥匙串加载
        if let savedKey = retrieveAPIKeyFromKeychain() {
            self.apiKey = savedKey
            print("✅ 从钥匙串加载API密钥成功")
            setupEndpointForAPIKey(savedKey)
            return
        }
        
        // 如果钥匙串中没有，使用ARK API密钥（优先级最高）
        let arkApiKey = defaultAPIKey
        self.apiKey = arkApiKey
        print("💯 使用默认ARK API密钥: \(String(arkApiKey.prefix(8)))...")
        
        // 设置为ARK端点
        currentEndpointIndex = 1
        print("⚙️ 设置为ARK API端点: \(deepSeekEndpoint)")
        print("⚙️ 使用模型: \(modelName)")
        
        // 保存到钥匙串以便下次使用
        saveAPIKeyToKeychain(arkApiKey)
        print("💾 已保存API密钥到钥匙串")
    }
    
    // 根据API密钥格式选择合适的端点
    private func setupEndpointForAPIKey(_ key: String) {
        if key.count == 36 && key.contains("-") {
            // ARK格式的API密钥，使用ARK端点
            currentEndpointIndex = 1
            print("🔄 检测到ARK格式API密钥，切换到ARK API端点")
        } else if key.hasPrefix("sk-") {
            // DeepSeek格式的API密钥，使用DeepSeek端点
            currentEndpointIndex = 0
            print("🔄 检测到DeepSeek格式API密钥，切换到DeepSeek API端点")
        }
        
        print("⚙️ 当前使用API端点: \(deepSeekEndpoint)")
        print("⚙️ 当前使用模型: \(modelName)")
    }
    
    // 手动设置API密钥
    func setAPIKey(_ key: String) {
        self.apiKey = key
        // 保存到钥匙串
        saveAPIKeyToKeychain(key)
        print("已设置新的API密钥")
    }
    
    // 检查是否有有效的API密钥
    var hasValidAPIKey: Bool {
        return apiKey != nil && !(apiKey?.isEmpty ?? true)
    }
    
    // 检查API密钥格式
    func isValidAPIKeyFormat(_ key: String?) -> Bool {
        guard let key = key, !key.isEmpty else {
            return false
        }
        
        // 支持两种API密钥格式:
        // 1. DeepSeek格式: 以sk-开头的长字符串
        // 2. ARK格式: UUID格式 (8-4-4-4-12格式)
        let isDeepSeekFormat = key.hasPrefix("sk-") && key.count > 30
        let isARKFormat = key.count == 36 && key.contains("-")
        
        return isDeepSeekFormat || isARKFormat
    }
    
    // 保存API密钥到钥匙串
    private func saveAPIKeyToKeychain(_ key: String) {
        // 删除旧的密钥
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: "deepseek_api_key"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // 保存新密钥
        let keyData = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: "deepseek_api_key",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("API密钥成功保存到钥匙串")
        } else {
            print("保存API密钥到钥匙串失败: \(status)")
        }
    }
    
    // 从钥匙串检索API密钥
    private func retrieveAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: "deepseek_api_key",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
} 