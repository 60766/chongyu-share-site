#if DEBUG
import Foundation
import Combine

// 直接测试DeepSeek API连接
// 可以在命令行使用 swift DirectAPITest.swift 运行

// 从Info.plist读取API密钥
func loadAPIKeyFromInfoPlist() -> String? {
    // 获取Info.plist路径
    guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
        print("❌ 无法找到Info.plist文件")
        return nil
    }
    
    // 读取Info.plist文件
    guard let plistDict = NSDictionary(contentsOfFile: plistPath) else {
        print("❌ 无法读取Info.plist文件")
        return nil
    }
    
    // 获取API密钥
    if let apiKey = plistDict["DEEPSEEK_API_KEY"] as? String, !apiKey.isEmpty {
        print("✅ 成功从Info.plist读取API密钥")
        return apiKey
    } else {
        print("❌ Info.plist中未找到DEEPSEEK_API_KEY或为空")
        return nil
    }
}

// 直接定义API配置
let apiKey = loadAPIKeyFromInfoPlist() ?? "sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" // 如果无法从Info.plist读取，则使用默认值
let apiEndpoint = "https://api.deepseek.com/v1/chat/completions" // 主要API端点
let modelName = "deepseek-chat" // 模型名称

// 测试两个API端点
let endpoints = [
    "https://api.deepseek.com/v1/chat/completions",
    "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
]

let models = [
    "deepseek-chat",
    "deepseek-r1-250120"
]

func testAPI(endpointIndex: Int = 0) {
    let currentEndpoint = endpoints[endpointIndex]
    let currentModel = models[endpointIndex]
    
    print("🧪 开始直接测试DeepSeek API...")
    print("🔑 使用API密钥: \(String(apiKey.prefix(8)))...")
    print("🌐 使用API端点: \(currentEndpoint)")
    print("🤖 使用模型: \(currentModel)")
    
    // 创建URL
    guard let url = URL(string: currentEndpoint) else {
        print("❌ 无效的API URL")
        return
    }
    
    // 构建请求体
    let requestBody: [String: Any] = [
        "model": currentModel,
        "messages": [
            ["role": "system", "content": "你是爱因斯坦，请以物理学家的身份回答问题。"],
            ["role": "user", "content": "请简短介绍一下相对论的核心思想。"]
        ],
        "temperature": 0.7,
        "max_tokens": 500
    ]
    
    // 创建请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        print("📤 请求体内容: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
    } catch {
        print("❌ 请求体序列化失败: \(error)")
        return
    }
    
    print("📤 发送请求到: \(currentEndpoint)")
    
    // 创建信号量以等待异步请求完成
    let semaphore = DispatchSemaphore(value: 0)
    
    // 执行请求
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 请求失败: \(error)")
            
            // 如果是第一个端点失败，尝试第二个端点
            if endpointIndex == 0 {
                print("⚠️ 尝试使用备用端点...")
                testAPI(endpointIndex: 1)
            }
            
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的响应")
            return
        }
        
        print("📥 收到响应 - 状态码: \(httpResponse.statusCode)")
        
        guard let data = data else {
            print("❌ 没有响应数据")
            return
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 原始响应: \(responseString)")
        }
        
        if httpResponse.statusCode == 200 {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("\n✅ 成功获取回复:")
                    print("---开始---")
                    print(content)
                    print("---结束---")
                } else {
                    print("❌ 无法解析JSON响应")
                }
            } catch {
                print("❌ JSON解析失败: \(error)")
            }
        } else {
            print("❌ HTTP错误: \(httpResponse.statusCode)")
            
            // 如果是第一个端点返回错误，尝试第二个端点
            if endpointIndex == 0 {
                print("⚠️ 尝试使用备用端点...")
                testAPI(endpointIndex: 1)
            }
        }
    }
    
    task.resume()
    
    // 等待请求完成
    _ = semaphore.wait(timeout: .now() + 30)
    
    print("🏁 测试完成")
}

// 执行测试
testAPI()
#endif 