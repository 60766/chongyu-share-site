import Foundation

// API配置
let apiKey = "5ec25df2-f799-4fc0-8ee2-ac13d473131b"
let apiEndpoint = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
let modelName = "deepseek-r1-250120"

// 测试函数
func testDeepSeekAPI() {
    let prompt = "你好，请以爱因斯坦的身份，简短回答什么是相对论"
    
    print("使用curl命令测试DeepSeek API...")
    let curlCommand = """
    curl '\(apiEndpoint)' \\
      -H "Content-Type: application/json" \\
      -H "Authorization: Bearer \(apiKey)" \\
      -d '{
        "model": "\(modelName)",
        "messages": [
          {"role": "system", "content": "你是一个智能助手，能够以各种角色的身份回答问题。"},
          {"role": "user", "content": "\(prompt)"}
        ],
        "temperature": 0.7,
        "max_tokens": 800
      }'
    """
    
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", curlCommand]
    
    let outputPipe = Pipe()
    task.standardOutput = outputPipe
    
    task.launch()
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: outputData, encoding: .utf8) {
        print("API响应:")
        print(output)
        
        // 尝试解析JSON响应
        if let jsonData = output.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    print("\n解析后的回复内容:")
                    print(content)
                }
            } catch {
                print("JSON解析错误: \(error)")
            }
        }
    }
}

// 执行测试
print("开始测试DeepSeek API...")
testDeepSeekAPI()
print("测试完成") 