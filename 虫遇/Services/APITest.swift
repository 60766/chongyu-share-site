import Foundation
import Combine

/**
 * API测试工具
 * 用于直接测试API调用
 */
class APITest {
    static let shared = APITest()
    private var cancellables = Set<AnyCancellable>()
    
    /**
     * 测试API调用
     * 直接打印结果到控制台
     */
    func testDeepSeekAPI() {
        print("开始测试DeepSeek API...")
        print("API密钥状态: \(APIConfigManager.shared.hasValidAPIKey ? "有效" : "无效")")
        
        if let apiKey = APIConfigManager.shared.apiKey {
            print("API密钥: \(String(apiKey.prefix(5)))...")
        } else {
            print("API密钥未设置")
        }
        
        let testPrompt = "你好，请以爱因斯坦的身份，简短回答什么是相对论"
        
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
                    print("API测试成功! 收到响应:")
                    print(response)
                }
            )
            .store(in: &cancellables)
        
        // 测试API端点有效性
        print("检查API端点: \(APIConfigManager.shared.deepSeekEndpoint)")
        if let url = URL(string: APIConfigManager.shared.deepSeekEndpoint) {
            let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
                if let error = error {
                    print("端点连接测试失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("端点连接测试结果: HTTP \(httpResponse.statusCode)")
                }
            }
            task.resume()
        } else {
            print("无效的API端点URL")
        }
    }
} 