import Foundation
import Combine

/**
 * API测试辅助类
 * 提供详细的API测试和诊断功能
 */
class APITester {
    static let shared = APITester()
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 执行完整的API诊断测试
     */
    func runCompleteDiagnostics() {
        print("\n========== API 完整诊断开始 ==========")
        // 1. 检查API密钥
        diagnosticAPIKey()
        
        // 2. 测试API端点连接
        testEndpointConnection()
        
        // 3. 执行简单API调用测试
        testARKApiCall()
    }
    
    /**
     * 诊断API密钥状态
     */
    func diagnosticAPIKey() {
        print("\n----- API密钥诊断 -----")
        
        // 检查当前API密钥
        let apiKey = APIConfigManager.shared.apiKey ?? "未设置"
        
        print("• 当前API密钥: \(apiKey)")
        print("• 密钥格式有效: \(APIConfigManager.shared.isValidAPIKeyFormat(apiKey) ? "是" : "否")")
        print("• 密钥类型: \(getAPIKeyType(apiKey))")
        print("• 当前端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        print("• 当前模型: \(APIConfigManager.shared.modelName)")
        
        // 强制设置ARK API密钥
        print("\n强制设置为ARK API密钥...")
        APIConfigManager.shared.setAPIKey("5ec25df2-f799-4fc0-8ee2-ac13d473131b")
        
        // 重新检查
        let updatedApiKey = APIConfigManager.shared.apiKey ?? "未设置"
        print("• 更新后API密钥: \(updatedApiKey)")
        print("• 更新后密钥格式有效: \(APIConfigManager.shared.isValidAPIKeyFormat(updatedApiKey) ? "是" : "否")")
        print("• 更新后密钥类型: \(getAPIKeyType(updatedApiKey))")
        print("• 更新后端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        print("• 更新后模型: \(APIConfigManager.shared.modelName)")
    }
    
    /**
     * 获取API密钥类型
     */
    private func getAPIKeyType(_ apiKey: String) -> String {
        if apiKey.isEmpty {
            return "空"
        }
        
        if apiKey.hasPrefix("sk-") {
            return "DeepSeek格式"
        }
        
        if apiKey.count == 36 && apiKey.contains("-") {
            return "ARK格式"
        }
        
        return "未知格式"
    }
    
    /**
     * 测试API端点连接
     */
    func testEndpointConnection() {
        print("\n----- API端点连接测试 -----")
        
        print("正在测试与 \(APIConfigManager.shared.deepSeekEndpoint) 的连接...")
        
        // 创建一个简单的ping请求
        let url = URL(string: APIConfigManager.shared.deepSeekEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ 连接失败: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✓ 收到响应，状态码: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    /**
     * 测试ARK API调用
     */
    func testARKApiCall() {
        print("\n----- ARK API调用测试 -----")
        
        // 强制设置ARK API密钥
        APIConfigManager.shared.setAPIKey("5ec25df2-f799-4fc0-8ee2-ac13d473131b")
        
        // 确保使用ARK端点
        if APIConfigManager.shared.currentEndpointIndex != 1 {
            APIConfigManager.shared.switchEndpoint()
            print("已切换到ARK端点")
        }
        
        print("• 当前API密钥: \(APIConfigManager.shared.apiKey ?? "未设置")")
        print("• 当前端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        print("• 当前模型: \(APIConfigManager.shared.modelName)")
        
        let testPrompt = "请以爱因斯坦的身份，用50字简短回答什么是相对论"
        
        print("发送请求: \"\(testPrompt)\"")
        
        AINetworkService.shared.sendRequest(prompt: testPrompt)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("API测试请求完成")
                    case .failure(let error):
                        print("API测试失败: \(error.localizedDescription)")
                        
                        // 打印更详细的错误信息
                        switch error {
                        case .httpError(let code):
                            print("HTTP错误码: \(code)")
                        case .invalidResponse:
                            print("无效的响应数据")
                        case .decodingError(let decodingError):
                            print("解码错误: \(decodingError)")
                        case .invalidURL:
                            print("无效的URL: \(APIConfigManager.shared.deepSeekEndpoint)")
                        case .requestFailed(let reqError):
                            print("请求失败: \(reqError)")
                        case .noAPIKey:
                            print("没有API密钥")
                        }
                    }
                },
                receiveValue: { response in
                    print("✅ API测试成功! 收到响应:")
                    print("\"\(response)\"")
                }
            )
            .store(in: &cancellables)
    }
    
    /**
     * 在虚拟角色服务中应用API设置
     */
    func verifyVirtualCharacterService() {
        print("\n----- 虚拟角色服务API验证 -----")
        
        // 强制测试生成评论
        VirtualCharacterService.shared.testGenerateCharacterComment(characterID: "einstein")
    }
}
