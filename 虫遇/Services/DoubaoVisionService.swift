import Foundation
import Combine
import UIKit

/**
 * 豆包视觉服务
 * 专门用于调用豆包视觉模型分析图片内容
 */
class DoubaoVisionService {
    // 单例实例
    static let shared = DoubaoVisionService()
    
    // 豆包视觉API配置（通过后端代理）
    private var baseURL: URL {
        // 使用与AINetworkService相同的baseURL逻辑
        if let override = ProcessInfo.processInfo.environment["BACKEND_BASE_URL"], let url = URL(string: override) {
            return url
        }
        if let plistURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String, let url = URL(string: plistURL) {
            return url
        }
        if let userDefault = UserDefaults.standard.string(forKey: "BackendBaseURL"), let url = URL(string: userDefault) {
            return url
        }
        #if DEBUG
        return URL(string: "http://localhost:3000")!
        #else
        return URL(string: "http://121.40.184.29:3000")!
        #endif
    }
    
    private let model = "doubao-seed-1-6-vision-250815"
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 分析图片内容并生成评论
     * @param images 要分析的图片数组
     * @param postContent 帖子文本内容
     * @param characters 要生成评论的角色列表
     * @return 返回角色评论的Publisher
     */
    func analyzeImagesAndGenerateComments(
        _ images: [UIImage], 
        postContent: String,
        characters: [String]
    ) -> AnyPublisher<[String: String], AINetworkError> {
        return Future<[String: String], AINetworkError> { promise in
            // 如果没有图片，直接返回空结果
            guard !images.isEmpty else {
                promise(.success([:]))
                return
            }
            
            // 构建包含角色信息的提示词
            let prompt = self.buildCharacterCommentPrompt(postContent: postContent, characters: characters)
            
            // 构建请求体
            let requestBody = self.buildVisionRequestBody(images: images, prompt: prompt)
            
            // 创建请求（通过后端代理）
            let url = self.baseURL.appendingPathComponent("api/vision")
            
            print("🌐 豆包视觉API请求URL: \(url.absoluteString)")
            print("🔑 使用Token: \(AppAccountManager.shared.appAccountToken)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 60.0  // 增加超时时间到60秒
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 使用应用Token而不是直接的API Key
            let token = AppAccountManager.shared.appAccountToken
            request.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                promise(.failure(.requestFailed(error)))
                return
            }
            
            // 发送请求（使用与AINetworkService相同的配置）
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 300
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.waitsForConnectivity = true
            
            let session = URLSession(configuration: sessionConfig)
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ 豆包视觉API网络错误详情: \(error)")
                    print("❌ 错误类型: \(type(of: error))")
                    if let urlError = error as? URLError {
                        print("❌ URLError代码: \(urlError.code.rawValue)")
                        print("❌ URLError描述: \(urlError.localizedDescription)")
                    }
                    promise(.failure(.requestFailed(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    print("❌ 豆包视觉API HTTP错误: \(httpResponse.statusCode)")
                    promise(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                // 解析响应
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        print("✅ 豆包视觉分析成功: \(content.prefix(100))...")
                        
                        // 解析角色评论
                        let commentsMap = self.parseCharacterComments(from: content, characters: characters)
                        promise(.success(commentsMap))
                    } else {
                        promise(.failure(.decodingError(NSError(domain: "DoubaoVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析响应数据"]))))
                    }
                } catch {
                    promise(.failure(.decodingError(error)))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 分析图片内容（仅获取描述）
     * @param images 要分析的图片数组
     * @param prompt 分析提示词，默认为"请详细描述这张图片的内容"
     * @return 返回图片描述的Publisher
     */
    func analyzeImages(_ images: [UIImage], prompt: String = "请详细描述这张图片的内容，包括主要物体、场景、文字等信息") -> AnyPublisher<String, AINetworkError> {
        return Future<String, AINetworkError> { promise in
            // 如果没有图片，直接返回空描述
            guard !images.isEmpty else {
                promise(.success(""))
                return
            }
            
            // 构建请求体
            let requestBody = self.buildVisionRequestBody(images: images, prompt: prompt)
            
            // 创建请求（通过后端代理）
            let url = self.baseURL.appendingPathComponent("api/vision")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 60.0  // 增加超时时间到60秒
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 使用应用Token而不是直接的API Key
            let token = AppAccountManager.shared.appAccountToken
            request.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            } catch {
                promise(.failure(.requestFailed(error)))
                return
            }
            
            // 发送请求（使用与AINetworkService相同的配置）
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 300
            sessionConfig.timeoutIntervalForResource = 300
            sessionConfig.waitsForConnectivity = true
            
            let session = URLSession(configuration: sessionConfig)
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    promise(.failure(.requestFailed(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    promise(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                // 解析响应
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        print("✅ 豆包视觉分析成功: \(content.prefix(100))...")
                        promise(.success(content))
                    } else {
                        promise(.failure(.decodingError(NSError(domain: "DoubaoVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析响应数据"]))))
                    }
                } catch {
                    promise(.failure(.decodingError(error)))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 构建视觉API请求体
     * @param images 图片数组
     * @param prompt 分析提示词
     * @return 请求体字典
     */
    private func buildVisionRequestBody(images: [UIImage], prompt: String) -> [String: Any] {
        var contentArray: [[String: Any]] = []
        
        // 添加图片
        for image in images {
            if let base64String = convertImageToBase64(image) {
                let imageContent: [String: Any] = [
                    "type": "image_url",
                    "image_url": [
                        "url": "data:image/jpeg;base64,\(base64String)"
                    ]
                ]
                contentArray.append(imageContent)
            }
        }
        
        // 添加文本提示
        let textContent: [String: Any] = [
            "type": "text",
            "text": prompt
        ]
        contentArray.append(textContent)
        
        // 构建完整请求体
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": contentArray
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.3
        ]
        
        return requestBody
    }
    
    /**
     * 将UIImage转换为Base64字符串
     * @param image 要转换的图片
     * @return Base64字符串
     */
    private func convertImageToBase64(_ image: UIImage) -> String? {
        // 压缩图片以减少数据大小
        let maxSize: CGFloat = 1024
        let resizedImage = resizeImage(image, maxSize: maxSize)
        
        // 转换为JPEG格式，压缩质量0.8
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ 无法将图片转换为JPEG数据")
            return nil
        }
        
        return imageData.base64EncodedString()
    }
    
    /**
     * 调整图片大小
     * @param image 原始图片
     * @param maxSize 最大边长
     * @return 调整后的图片
     */
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        // 如果图片已经足够小，直接返回
        if max(size.width, size.height) <= maxSize {
            return image
        }
        
        // 计算新的尺寸
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // 创建新的图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /**
     * 构建角色评论提示词
     * @param postContent 帖子文本内容
     * @param characters 角色列表
     * @return 提示词字符串
     */
    private func buildCharacterCommentPrompt(postContent: String, characters: [String]) -> String {
        // 获取角色信息
        let characterDataManager = CharacterDataManager.shared
        let characterInfo = characters.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            return "- \(name) (ID: \(id))"
        }.joined(separator: "\n")
        
        let prompt = """
        请仔细观察这些图片，并结合帖子内容："\(postContent)"。
        
        你的目标：为下列角色分别生成对该“图片+帖子”的评论，以提升真实互动感与可读性。
        
        参与角色：
        \(characterInfo)
        
        生成要求（务必严格遵守）：
        1. 每个角色必须基于图片所见进行评论，体现出他们“看到了”图片；同时与帖子文本建立联系点（经历/知识/价值观/观点）。
        2. 评论必须符合角色的性格、时代背景与专业领域，展现独特视角。
        3. 语气自然，像真人对话；直接对用户说话，使用“你”；避免模板化开头（如“作为[角色]”）。
        4. 内容简短有力，控制在20-40字；不要重复引用帖子原文。
        5. 禁止加入解释性文字、元信息或括号内说明（例如“(思考中)”）；不要@其他角色或加入额外的段落标题。
        6. 仅输出评论内容本身，不要添加任何分析、注释或额外说明。
        
        输出格式（严格按此结构，便于解析）：
        [角色ID]
        这里是该角色基于“图片+帖子”的评论...
        
        [下一个角色ID]
        这里是下一个角色的评论...
        """
        
        return prompt
    }
    
    /**
     * 解析角色评论
     * @param content API返回的内容
     * @param characters 角色列表
     * @return 角色ID到评论内容的映射
     */
    private func parseCharacterComments(from content: String, characters: [String]) -> [String: String] {
        var result = [String: String]()
        var currentCharacterId: String? = nil
        var currentComment = ""
        
        // 规范化角色ID列表（全部转为小写）以便于比较
        let normalizedCharacterIDs = characters.map { $0.lowercased() }
        
        func normalizeLabel(_ raw: String) -> String {
            var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            // 去除方括号
            if t.hasPrefix("[") && t.hasSuffix("]") {
                t = String(t.dropFirst().dropLast())
            }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
            // 去除末尾标点（冒号/破折号等）
            while let last = t.last, ":：-—–。．··,，;； ".contains(last) {
                t = String(t.dropLast())
            }
            return t.lowercased()
        }
        
        // 将响应按行分割
        let lines = content.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                if currentCharacterId != nil && !currentComment.isEmpty {
                    currentComment += "\n"
                }
                continue
            }
            
            // 检查是否为角色标记行（支持：[id]、id、id:、id： 等形式）
            let candidate = normalizeLabel(trimmedLine)
            if normalizedCharacterIDs.contains(candidate) {
                // 保存之前的角色评论
                if let prevCharacterId = currentCharacterId, !currentComment.isEmpty {
                    result[prevCharacterId] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // 使用原始大小写的ID作为键
                let originalId = characters.first { $0.lowercased() == candidate } ?? candidate
                currentCharacterId = originalId
                currentComment = ""
                continue
            }
            
            // 若不是标记行，且有当前角色ID，则累积评论内容
            if currentCharacterId != nil {
                if !currentComment.isEmpty {
                    currentComment += " "
                }
                currentComment += trimmedLine
            }
        }
        
        // 保存最后一个角色的评论
        if let lastCharacterId = currentCharacterId, !currentComment.isEmpty {
            result[lastCharacterId] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        print("🎭 解析到\(result.count)个角色评论: \(result.keys.joined(separator: ", "))")
        return result
    }
} 