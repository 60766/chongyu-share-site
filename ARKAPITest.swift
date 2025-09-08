#if DEBUG
import Foundation

// ARK API 测试脚本
// 使用方式: swift ARKAPITest.swift [API密钥]

// 获取命令行参数中的API密钥
let apiKey: String
if CommandLine.arguments.count > 1 {
    apiKey = CommandLine.arguments[1]
    print("🔑 使用提供的API密钥: \(apiKey.prefix(8))...")
} else {
    apiKey = "5ec25df2-f799-4fc0-8ee2-ac13d473131b" // 默认使用Info.plist中的密钥
    print("ℹ️ 使用默认API密钥: \(apiKey.prefix(8))...")
}

// ARK API 端点
let apiEndpoint = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
let modelName = "deepseek-r1-250120"

// 构建系统提示和用户问题
let systemPrompt = "你是爱因斯坦，请以物理学家的身份回答问题。保持回答简短、有趣且风格独特。"
let userQuestion = "请用通俗易懂的方式解释相对论的核心思想，尽量简短。"

func testAPI() {
    print("\n🧪 测试 ARK API...")
    print("🌐 端点: \(apiEndpoint)")
    print("🤖 模型: \(modelName)")
    
    // 创建URL和请求
    guard let url = URL(string: apiEndpoint) else {
        print("❌ 无效的API URL")
        return
    }
    
    // 构建请求体
    let requestBody: [String: Any] = [
        "model": modelName,
        "messages": [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userQuestion]
        ],
        "temperature": 0.7,
        "max_tokens": 300
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        print("📤 请求体内容:\n\(String(data: request.httpBody!, encoding: .utf8) ?? "")")
    } catch {
        print("❌ 请求体序列化失败: \(error)")
        return
    }
    
    print("📤 发送请求中...")
    
    // 使用信号量等待异步请求完成
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 请求失败: \(error)")
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
                    
                    // 检查回复质量
                    let templatePatterns = [
                        "作为", "我认为", "我的观点是", "在我看来", 
                        "这个问题很有趣", "这个话题很有深度",
                        "谢谢分享", "希望我的回答对你有所帮助"
                    ]
                    
                    let containsTemplateLanguage = templatePatterns.contains { pattern in
                        content.contains(pattern)
                    }
                    
                    if containsTemplateLanguage {
                        print("\n⚠️ 警告: 回复中包含模板化语言")
                    } else {
                        print("\n👍 回复质量良好，未检测到明显的模板语言")
                    }
                    
                } else {
                    print("❌ 无法解析JSON响应")
                    print("原始响应: \(String(data: data, encoding: .utf8) ?? "")")
                }
            } catch {
                print("❌ JSON解析失败: \(error)")
            }
        } else {
            print("❌ HTTP错误: \(httpResponse.statusCode)")
            print("错误响应: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }
    
    task.resume()
    
    // 等待请求完成
    _ = semaphore.wait(timeout: .now() + 30)
    
    print("\n🏁 测试完成")
}

// 执行测试
testAPI()
#endif 