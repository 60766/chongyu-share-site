import Foundation
import Combine
import UIKit

/**
 * 角色回复数据结构
 * 包含评论内容和点赞判断
 */
struct CharacterVisionResponse {
    let content: String
    let shouldLike: Bool
}

/**
 * 通义千问视觉服务
 * 专门用于调用通义千问视觉模型分析图片内容
 */
class DoubaoVisionService {
    // 单例实例
    static let shared = DoubaoVisionService()
    
    // 存储角色的点赞决策（角色ID -> 是否点赞）
    private var characterLikeDecisions: [String: Bool] = [:]
    
    // 用于存储Combine订阅
    private var cancellables = Set<AnyCancellable>()
    
    // 通义千问视觉API配置（通过后端代理）
    private var baseURL: URL {
        BackendURLProvider.resolvedURL()
    }
    
    private let model = "qwen3-vl-flash"
    
    // 通义千问3-VL-Flash支持单次最多约15张图片（258,048 tokens ÷ 16,384 tokens/张）
    // 我们的App最多上传9张图片，所以不需要分批处理
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 处理角色点赞（根据AI的点赞判断）
     * @param postId 帖子ID
     * @param postContent 帖子内容（用于通知）
     */
    func processCharacterLikes(for postId: String, postContent: String) {
        print("🎯 [通义千问视觉] 开始处理角色点赞，帖子ID: \(postId)")
        print("🎯 [通义千问视觉] 当前点赞决策: \(characterLikeDecisions)")
        
        // 遍历所有决定点赞的角色
        for (characterId, shouldLike) in characterLikeDecisions {
            if shouldLike {
                print("❤️ [通义千问视觉] 角色 \(characterId) 决定点赞")
                // 延迟2-8秒再进行点赞，模拟真实的点赞时机
                let likeDelay = Double.random(in: 2...8)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + likeDelay) {
                    print("🕐 [通义千问视觉] \(characterId)延迟\(String(format: "%.1f", likeDelay))秒后开始对帖子点赞")
                    // 调用虚拟角色点赞服务
                    VirtualCharacterLikeService.shared.processPostLike(
                        characterId: characterId,
                        postId: postId,
                        userPostContent: postContent
                    )
                }
            } else {
                print("💔 [通义千问视觉] 角色 \(characterId) 决定不点赞")
            }
        }
        
        // 清空点赞决策（避免重复使用）
        characterLikeDecisions.removeAll()
    }
    
    /**
     * 分析图片内容并生成评论（支持分批处理）
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
        // 如果没有图片，直接返回空结果
        guard !images.isEmpty else {
            return Just([:])
                .setFailureType(to: AINetworkError.self)
                .eraseToAnyPublisher()
        }
        
        // 直接处理所有图片（通义千问支持最多约15张，我们的App最多9张，不需要分批）
        print("📸 处理\(images.count)张图片，一次性发送到视觉API")
        return analyzeImagesBatch(
            images,
            postContent: postContent,
            characters: characters
        )
    }
    
    /**
     * 处理图片并生成评论
     * @param images 所有图片（最多9张，一次性处理）
     * @param postContent 帖子文本内容
     * @param characters 要生成评论的角色列表
     * @return 返回角色评论的Publisher
     */
    private func analyzeImagesBatch(
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
            let prompt = self.buildCharacterCommentPrompt(
                postContent: postContent,
                characters: characters,
                imageCount: images.count
            )
            
            // 构建请求体
            let requestBody = self.buildVisionRequestBody(images: images, prompt: prompt)
            
            // 创建请求（通过后端代理）
            let url = self.baseURL.appendingPathComponent("api/vision")
            
#if DEBUG
            print("🌐 通义千问视觉API请求URL: \(url.absoluteString)")
            print("🔑 使用Token: \(AppAccountManager.shared.appAccountToken)")
            print("📊 图片数量: \(images.count)张")
#endif
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // ⚠️ 不设置request.timeoutInterval，使用URLSessionConfiguration的超时设置（300秒）
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 使用应用Token而不是直接的API Key
            let token = AppAccountManager.shared.appAccountToken
            request.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
            request.addValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
            
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
                    print("❌ 通义千问视觉API网络错误详情: \(error)")
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
                    print("❌ 通义千问视觉API HTTP错误: \(httpResponse.statusCode)")
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
                        
                        print("✅ 通义千问视觉分析成功")
#if DEBUG
                        print("📄 通义千问AI原始响应（前500字符）:")
                        print("---")
                        print(String(content.prefix(500)))
                        print("---")
#endif
                        
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
            // ⚠️ 不设置request.timeoutInterval，使用URLSessionConfiguration的超时设置（300秒）
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // 使用应用Token而不是直接的API Key
            let token = AppAccountManager.shared.appAccountToken
            request.addValue(token, forHTTPHeaderField: "X-App-Account-Token")
            request.addValue(AppAccountManager.shared.deviceIdentifier, forHTTPHeaderField: "X-Device-Id")
            
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
                        
                        print("✅ 通义千问视觉分析成功: \(content.prefix(100))...")
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
        
        // 根据图片数量动态调整压缩质量
        let compressionQuality: CGFloat = images.count > 6 ? 0.6 : 0.8
        
        // ⚡️ 关键优化：使用自动释放池，避免内存峰值
        // 在处理多张图片时，每张图片的临时对象会立即释放
        for image in images {
            autoreleasepool {
                if let base64String = convertImageToBase64(image, compressionQuality: compressionQuality) {
                    let imageContent: [String: Any] = [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64String)"
                        ]
                    ]
                    contentArray.append(imageContent)
                }
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
     * @param compressionQuality JPEG压缩质量（0.0-1.0），默认0.8
     * @return Base64字符串
     */
    private func convertImageToBase64(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        // ⚡️ 关键优化：直接使用原图，避免二次resize
        // ImageManager已经将图片resize到1080px，这里不需要再次resize
        // 只需要压缩成JPEG即可
        
        let maxSize: CGFloat = 1024
        let imageSize = max(image.size.width, image.size.height)
        
        // 只有当图片确实大于1024时才resize，否则直接使用
        let processedImage: UIImage
        if imageSize > maxSize {
            processedImage = resizeImage(image, maxSize: maxSize)
        } else {
            processedImage = image
        }
        
        // 转换为JPEG格式，使用指定的压缩质量
        guard let imageData = processedImage.jpegData(compressionQuality: compressionQuality) else {
            print("❌ 无法将图片转换为JPEG数据")
            return nil
        }
        
        print("📦 图片压缩质量: \(compressionQuality), 数据大小: \(imageData.count / 1024)KB")
        
        // ⚡️ 关键优化：base64编码后立即释放imageData引用
        let base64String = imageData.base64EncodedString()
        return base64String
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
        
        // ⚡️ 关键优化：使用UIGraphicsImageRenderer替代UIGraphicsBeginImageContextWithOptions
        // UIGraphicsImageRenderer在iOS 10+性能更好，内存管理更优
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /**
     * 构建角色评论提示词（优化版：参考DeepSeek风格）
     * @param postContent 帖子文本内容
     * @param characters 角色列表
     * @param imageCount 图片数量
     * @return 提示词字符串
     */
    private func buildCharacterCommentPrompt(
        postContent: String,
        characters: [String],
        imageCount: Int = 1
    ) -> String {
        // 获取角色详细信息
        let characterDataManager = CharacterDataManager.shared
        let characterInfo = characters.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            let briefDesc = characterDataManager.getAttribute(id: id, attribute: "briefDescription") ?? ""
            let field = characterDataManager.getAttribute(id: id, attribute: "primaryField") ?? ""
            let era = characterDataManager.getAttribute(id: id, attribute: "era") ?? ""
            
            // 构建角色描述（与纯文字提示词格式一致）
            var description = "\(name)"
            if !era.isEmpty && !field.isEmpty {
                description += "，\(era)的\(field)专家"
            } else if !field.isEmpty {
                description += "，专长领域是\(field)"
            }
            if !briefDesc.isEmpty {
                description += "。\(briefDesc)"
            }
            
            return "- **\(name)** (ID: \(id))\n  特点：\(description)"
        }.joined(separator: "\n\n")
        
        // 🎯 根据图片数量动态调整提示词
        let imageDescription: String
        let multiImageStrategy: String
        
        if imageCount > 1 {
            imageDescription = "本帖子包含\(imageCount)张不同的图片，请仔细观察每一张图片的内容、细节和风格。"
            multiImageStrategy = """
            
            【多图片评论策略】
            本帖子有\(imageCount)张不同的图片，每个角色应该：
            - 自然地关注不同的图片或不同的细节（不要明确说"第几张"，直接评论图片内容）
            - 或者对同一张图片从不同角度观察（构图、色彩、情绪、内容等）
            - 避免所有角色都评论同一个元素或特征
            - 让每张图片都能得到关注，展现图片的多样性
            """
        } else {
            imageDescription = "本帖子包含一张图片，请仔细观察图片的内容、细节、构图、色彩和情绪。"
            multiImageStrategy = ""
        }
        
        let prompt = """
        你需要为以下角色分别生成对这条带图帖子的评论：
        \(characterInfo)
        
        帖子内容："\(postContent)"
        \(imageDescription)\(multiImageStrategy)
        
        重要任务：以你的身份和经历，感同身受地理解图片和文字，然后自然地表达你的真实感受。
        
        1. 感同身受地理解：
           - 图片中的内容、情绪、细节让你想到了什么？
           - 这与你的经历、知识或价值观有什么共鸣？
           - 如果你处在类似情境，会有什么感受或反应？
           - 图片和文字触发了你什么样的真实感受？
        
        2. 自然地表达你的感受：
           - 以你的身份和视角，真实地表达对图片和文字的感受
           - 可以是你看到图片后的第一反应、联想、回忆或思考
           - 结合图片的具体细节（你注意到的构图、色彩、情绪、内容等）
           - 让评论像真人看到图片后的自然反应，不要刻意表现
           - 可以是简单的观察、联想、感受，不一定要"深刻"或"有趣"
           - 可以在适当情况下直接称呼作者，增加真实感
        
        表达要求：
        1. 保持自然真实，像真人看到图片后的第一反应
        2. 不要用固定句式开头，如"作为[角色]"、"看到这图"、"这张图片"
        3. 不要重复引用帖子内容，直接表达你的感受
        4. 以你的身份感同身受，但不要刻意"表现"角色身份
        5. 评论长度控制在25-50字之间，简短自然
        6. 可以是简单的观察、联想、感受，不一定要"深刻"或"有趣"
        7. 使用通俗易懂的现代语言，像朋友间的自然交流
        8. 不要使用专业术语或高深理论
        9. 严格禁止添加任何形式的注释、解释或分析
        10. 绝对禁止使用括号中的内容，如"(微笑)"、"(思考中)"等
        11. 禁止添加"注："、"PS："等补充说明
        12. 不要明确说"第几张图片"，直接评论图片内容即可
        
        【多角色差异化】
        如果有多个角色，确保：
        - 每个角色自然地关注不同的图片或不同的细节（多图时）
        - 展现不同的视角和感受，避免所有人都说同一个东西
        - 让每个角色的评论都有独特性，但保持自然真实
        
        【输出格式】
        [角色英文ID]
        评论内容
        点赞：是/否
        
        【示例】
        [einstein]
        这光影角度让我想起普林斯顿实验室的某个下午，简单却深刻。
        点赞：是
        
        [libai]
        好景配好酒，你这构图有几分当年黄鹤楼的豪气。
        点赞：是
        
        [darwin]
        这纹理跟我在加拉帕戈斯观察到的惊人相似。
        点赞：是
        
        注意：示例中的评论都是角色基于图片内容的真实感受和联想，自然地流露了角色身份，而不是刻意表现。
        
        额外重要提示：
        1. 以你的身份感同身受，但用通俗易懂的现代语言表达
        2. 像真人看到图片后的第一反应，自然真实，不要刻意
        3. 可以是简单的观察、联想、感受，不一定要"深刻"或"有趣"
        4. 像在与朋友日常对话一样自然，但要有你的身份视角
        5. 严格禁止添加任何形式的注释、解释或分析
        6. 评论必须是纯粹的、自然的表达，不包含任何元解释
        7. 绝对不要使用括号内的内容，如"(思考中)"、"(引用某理论)"等
        8. 不要明确说"第几张图片"，直接评论图片内容即可
        9. 禁止添加"注："、"PS："等补充说明
        """
        
        return prompt
    }
    
    /**
     * 解析角色评论（包含点赞信息）
     * @param content API返回的内容
     * @param characters 角色列表
     * @return 角色ID到评论内容的映射
     */
    private func parseCharacterComments(from content: String, characters: [String]) -> [String: String] {
        var result = [String: String]()
        var currentCharacterId: String? = nil
        var currentComment = ""
        var currentShouldLike = false
        
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
        
        // 保存当前角色的评论和点赞信息
        func saveCurrentCharacter() {
            guard let charId = currentCharacterId, !currentComment.isEmpty else { return }
            result[charId] = currentComment.trimmingCharacters(in: .whitespacesAndNewlines)
            characterLikeDecisions[charId] = currentShouldLike
            print("💬 [\(charId)] 评论: \(currentComment.prefix(30))... | 点赞: \(currentShouldLike ? "是" : "否")")
        }
        
        // 将响应按行分割
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行
            if trimmedLine.isEmpty {
                continue
            }
            
            // 检查是否为角色标记行（支持：[id]、id、id:、id： 等形式）
            let candidate = normalizeLabel(trimmedLine)
            if normalizedCharacterIDs.contains(candidate) {
                // 保存之前的角色评论
                saveCurrentCharacter()
                
                // 使用原始大小写的ID作为键
                let originalId = characters.first { $0.lowercased() == candidate } ?? candidate
                currentCharacterId = originalId
                currentComment = ""
                currentShouldLike = false
                continue
            }
            
            // 检查是否为点赞标记行（支持：点赞：是/否、Like: Yes/No等）
            let lowerLine = trimmedLine.lowercased()
            if lowerLine.hasPrefix("点赞") || lowerLine.hasPrefix("like") {
                // 提取点赞判断
                if lowerLine.contains("是") || lowerLine.contains("yes") || lowerLine.contains("true") {
                    currentShouldLike = true
                    print("📝 [通义千问] 解析点赞判断: 原文='\(trimmedLine)', 结果=✅是")
                } else if lowerLine.contains("否") || lowerLine.contains("no") || lowerLine.contains("false") {
                    currentShouldLike = false
                    print("📝 [通义千问] 解析点赞判断: 原文='\(trimmedLine)', 结果=❌否")
                }
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
        saveCurrentCharacter()
        
#if DEBUG
        print("🎭 解析到\(result.count)个角色评论: \(result.keys.joined(separator: ", "))")
        print("❤️ 点赞决策: \(characterLikeDecisions)")
#endif
        return result
    }
} 