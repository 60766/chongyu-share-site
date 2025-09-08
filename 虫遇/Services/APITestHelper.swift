#if DEBUG
import Foundation
import SwiftUI

/**
 * API测试辅助类
 * 用于验证API连接和密钥可用性
 */
class APITestHelper {
    static func testAPIConnectivity(completion: @escaping (Bool, String) -> Void) {
        // 获取API配置
        let apiKey = APIConfigManager.shared.apiKey ?? ""
        let endpoint = APIConfigManager.shared.deepSeekEndpoint
        let modelName = APIConfigManager.shared.modelName
        
        print("🔍 开始测试API连接性")
        print("🌐 API端点: \(endpoint)")
        print("📱 模型: \(modelName)")
        print("🔑 API密钥: \(apiKey.prefix(8))...")
        
        // 构建简单请求
        let testPrompt = "简单回复'API测试成功'，不要添加任何其他内容"
        
        // 构建请求体
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": "你是一个简单的测试助手"],
                ["role": "user", "content": testPrompt]
            ],
            "temperature": 0.3,
            "max_tokens": 20,
            "top_p": 0.95,
            "stream": false
        ]
        
        guard let url = URL(string: endpoint) else {
            completion(false, "无效的API端点URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(false, "请求体序列化失败: \(error.localizedDescription)")
            return
        }
        
        // 设置超时
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "网络错误: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "无效的HTTP响应")
                return
            }
            
            print("📥 API响应状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    completion(false, "HTTP错误 \(httpResponse.statusCode): \(errorMessage)")
                } else {
                    completion(false, "HTTP错误 \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                completion(false, "无响应数据")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    print("✅ API响应内容: \(content)")
                    
                    // 检查响应是否包含"API测试成功"
                    if content.contains("API测试成功") {
                        completion(true, "API测试成功: \(content)")
                    } else {
                        completion(true, "API响应内容不符合预期: \(content)")
                    }
                } else {
                    completion(false, "无法解析API响应")
                }
            } catch {
                completion(false, "解析响应失败: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    static func testCommentGeneration(completion: @escaping (Bool, String) -> Void) {
        // 获取API配置
        let apiKey = APIConfigManager.shared.apiKey ?? ""
        let endpoint = APIConfigManager.shared.deepSeekEndpoint
        let modelName = APIConfigManager.shared.modelName
        
        print("🔍 开始测试评论生成能力")
        
        // 模拟帖子内容
        let postContent = "人工智能在未来会如何改变我们的日常生活？"
        
        // 构建请求体
        let promptTemplate = """
        你是爱因斯坦，正在回应一个关于未来科技的帖子。
        请以爱因斯坦的风格，对以下帖子发表一个简短的评论（不超过100字）：
        
        帖子内容："\(postContent)"
        
        请直接给出评论内容，不要添加任何前缀如"作为爱因斯坦"等。
        """
        
        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                ["role": "system", "content": "你是历史人物爱因斯坦"],
                ["role": "user", "content": promptTemplate]
            ],
            "temperature": 0.7,
            "max_tokens": 200,
            "top_p": 0.95,
            "stream": false
        ]
        
        guard let url = URL(string: endpoint) else {
            completion(false, "无效的API端点URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(false, "请求体序列化失败: \(error.localizedDescription)")
            return
        }
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "网络错误: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "无效的HTTP响应")
                return
            }
            
            print("📥 API响应状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                if let data = data, let errorMessage = String(data: data, encoding: .utf8) {
                    completion(false, "HTTP错误 \(httpResponse.statusCode): \(errorMessage)")
                } else {
                    completion(false, "HTTP错误 \(httpResponse.statusCode)")
                }
                return
            }
            
            guard let data = data else {
                completion(false, "无响应数据")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    print("✅ 生成的评论: \(content)")
                    
                    // 直接判定API评论生成成功，不检查模板语言
                    completion(true, "API评论生成成功: \(content)")
                } else {
                    completion(false, "无法解析API响应")
                }
            } catch {
                completion(false, "解析响应失败: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /**
     * 测试虚拟角色评论生成并添加到帖子
     * @param characterID 角色ID，如果为nil则随机选择一个角色
     * @param completion 完成回调，返回是否成功和消息
     */
    static func testVirtualCharacterComment(characterID: String? = nil, completion: @escaping (Bool, String) -> Void) {
        print("🔍 开始测试虚拟角色评论生成")
        
        // 使用传入的角色ID或默认使用莎士比亚
        let finalCharacterID = characterID ?? "shakespeare"
        print("👤 使用角色ID: \(finalCharacterID)")
        
        // 创建一个观察者来监听评论更新通知
        let notificationCenter = NotificationCenter.default
        
        // 先声明observer变量
        var observer: NSObjectProtocol?
        
        // 创建可取消的工作项
        let timeoutWorkItem = DispatchWorkItem {
            if let observer = observer {
                notificationCenter.removeObserver(observer)
            }
            completion(false, "测试超时，请检查控制台日志")
        }
        
        // 设置超时处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: timeoutWorkItem)
        
        // 然后再定义并赋值
        observer = notificationCenter.addObserver(
            forName: NSNotification.Name("RefreshPostComments"),
            object: nil,
            queue: .main
        ) { _ in
            print("📣 收到评论更新通知")
            
            // 取消超时
            timeoutWorkItem.cancel()
            
            // 延迟一秒后检查是否成功添加评论
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let postViewModel = PostViewModel.shared
                if !postViewModel.posts.isEmpty {
                    let postIndex = 0
                    let post = postViewModel.posts[postIndex]
                    let commentCount = post.comments.count
                    
                    if commentCount > 0 {
                        // 首先检查是否有匹配的回复
                        let foundReply = findCharacterReply(in: post.comments, characterID: finalCharacterID)
                        
                        if foundReply {
                            completion(true, "成功添加虚拟角色评论回复")
                        } else {
                            // 查找最新添加的评论
                            let latestComment = post.comments.last
                            
                            if let comment = latestComment, 
                               comment.isVirtualCharacter, 
                               comment.characterID == finalCharacterID {
                                completion(true, "成功添加虚拟角色评论: \(comment.username)")
                            } else {
                                completion(false, "找不到匹配的虚拟角色评论")
                            }
                        }
                    } else {
                        completion(false, "帖子没有评论")
                    }
                } else {
                    completion(false, "无法获取帖子数据或帖子列表为空")
                }
                
                // 移除观察者
                if let observer = observer {
                    notificationCenter.removeObserver(observer)
                }
            }
        }
        
        // 调用VirtualCharacterService的测试方法
        VirtualCharacterService.shared.testGenerateCharacterComment(characterID: finalCharacterID)
    }
    
    /**
     * 递归查找虚拟角色回复评论
     * @param comments 评论列表
     * @param characterID 角色ID
     * @return 是否找到匹配的回复
     */
    private static func findCharacterReply(in comments: [DetailedCommentModel], characterID: String) -> Bool {
        for comment in comments {
            // 检查当前评论的回复列表
            for reply in comment.replies {
                if reply.isVirtualCharacter && reply.characterID == characterID {
                    return true
                }
                
                // 递归检查回复的回复
                if !reply.replies.isEmpty && findCharacterReply(in: reply.replies, characterID: characterID) {
                    return true
                }
            }
            
            // 递归检查子评论
            if !comment.replies.isEmpty && findCharacterReply(in: comment.replies, characterID: characterID) {
                return true
            }
        }
        
        return false
    }
}
#endif 