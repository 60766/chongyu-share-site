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
 * 豆包视觉服务
 * 专门用于调用豆包视觉模型分析图片内容
 */
class DoubaoVisionService {
    // 单例实例
    static let shared = DoubaoVisionService()
    
    // 存储角色的点赞决策（角色ID -> 是否点赞）
    private var characterLikeDecisions: [String: Bool] = [:]
    
    // 用于存储Combine订阅
    private var cancellables = Set<AnyCancellable>()
    
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
        // 统一使用阿里云生产服务器（发布版本）
        return URL(string: "http://121.40.184.29:3000")!
    }
    
    private let model = "doubao-seed-1-6-vision-250815"
    
    // 🆕 豆包Vision API每次请求的最大图片数量限制
    private let maxImagesPerRequest = 4
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 处理角色点赞（根据AI的点赞判断）
     * @param postId 帖子ID
     * @param postContent 帖子内容（用于通知）
     */
    func processCharacterLikes(for postId: String, postContent: String) {
        print("🎯 [豆包视觉] 开始处理角色点赞，帖子ID: \(postId)")
        print("🎯 [豆包视觉] 当前点赞决策: \(characterLikeDecisions)")
        
        // 遍历所有决定点赞的角色
        for (characterId, shouldLike) in characterLikeDecisions {
            if shouldLike {
                print("❤️ [豆包视觉] 角色 \(characterId) 决定点赞")
                // 延迟2-8秒再进行点赞，模拟真实的点赞时机
                let likeDelay = Double.random(in: 2...8)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + likeDelay) {
                    print("🕐 [豆包视觉] \(characterId)延迟\(String(format: "%.1f", likeDelay))秒后开始对帖子点赞")
                    // 调用虚拟角色点赞服务
                    VirtualCharacterLikeService.shared.processPostLike(
                        characterId: characterId,
                        postId: postId,
                        userPostContent: postContent
                    )
                }
            } else {
                print("💔 [豆包视觉] 角色 \(characterId) 决定不点赞")
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
        
        // 🆕 分批处理逻辑
        if images.count > maxImagesPerRequest {
            print("📦 图片数量(\(images.count))超过单次限制(\(maxImagesPerRequest))，启动分批处理...")
            return analyzeImagesInBatches(images, postContent: postContent, characters: characters)
        } else {
            // 图片数量在限制内，直接处理
            return analyzeImagesBatch(images, postContent: postContent, characters: characters, batchIndex: 0, totalBatches: 1)
        }
    }
    
    /**
     * 🆕 分批分析图片并生成评论
     * @param images 所有图片
     * @param postContent 帖子文本内容
     * @param characters 要生成评论的角色列表
     * @return 返回合并后的角色评论
     */
    private func analyzeImagesInBatches(
        _ images: [UIImage],
        postContent: String,
        characters: [String]
    ) -> AnyPublisher<[String: String], AINetworkError> {
        // 将图片分批
        var batches: [[UIImage]] = []
        var currentIndex = 0
        
        while currentIndex < images.count {
            let endIndex = min(currentIndex + maxImagesPerRequest, images.count)
            let batch = Array(images[currentIndex..<endIndex])
            batches.append(batch)
            currentIndex = endIndex
        }
        
        print("📦 将\(images.count)张图片分为\(batches.count)批处理（每批最多\(maxImagesPerRequest)张）")
        
        // 使用Combine依次处理每批图片
        let totalBatches = batches.count
        let publishers = batches.enumerated().map { (index, batch) -> AnyPublisher<[String: String], AINetworkError> in
            return analyzeImagesBatch(batch, postContent: postContent, characters: characters, batchIndex: index, totalBatches: totalBatches)
        }
        
        // 串行处理所有批次
        return publishers.reduce(
            Just([:]).setFailureType(to: AINetworkError.self).eraseToAnyPublisher()
        ) { combinedPublisher, batchPublisher in
            return combinedPublisher
                .flatMap { accumulatedComments -> AnyPublisher<[String: String], AINetworkError> in
                    return batchPublisher
                        .map { newComments -> [String: String] in
                            // 合并评论（新评论会覆盖旧评论）
                            var merged = accumulatedComments
                            merged.merge(newComments) { _, new in new }
                            return merged
                        }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /**
     * 🆕 处理单批图片
     * @param images 当前批次的图片（<=4张）
     * @param postContent 帖子文本内容
     * @param characters 要生成评论的角色列表
     * @param batchIndex 当前批次索引
     * @param totalBatches 总批次数
     * @return 返回角色评论的Publisher
     */
    private func analyzeImagesBatch(
        _ images: [UIImage],
        postContent: String,
        characters: [String],
        batchIndex: Int,
        totalBatches: Int
    ) -> AnyPublisher<[String: String], AINetworkError> {
        return Future<[String: String], AINetworkError> { promise in
            // 如果没有图片，直接返回空结果
            guard !images.isEmpty else {
                promise(.success([:]))
                return
            }
            
            // 🆕 打印批次信息
            if totalBatches > 1 {
                print("🔄 处理第\(batchIndex + 1)/\(totalBatches)批，包含\(images.count)张图片")
            }
            
            // 构建包含角色信息的提示词（传入图片数量以优化多图场景）
            let prompt = self.buildCharacterCommentPrompt(postContent: postContent, characters: characters, imageCount: images.count)
            
            // 构建请求体
            let requestBody = self.buildVisionRequestBody(images: images, prompt: prompt)
            
            // 创建请求（通过后端代理）
            let url = self.baseURL.appendingPathComponent("api/vision")
            
            print("🌐 豆包视觉API请求URL: \(url.absoluteString)")
            print("🔑 使用Token: \(AppAccountManager.shared.appAccountToken)")
            if totalBatches > 1 {
                print("📊 当前批次: \(batchIndex + 1)/\(totalBatches), 图片数量: \(images.count)")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            // ⚠️ 不设置request.timeoutInterval，使用URLSessionConfiguration的超时设置（300秒）
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
                        
                        if totalBatches > 1 {
                            print("✅ 第\(batchIndex + 1)/\(totalBatches)批分析成功")
                        } else {
                            print("✅ 豆包视觉分析成功")
                        }
                        print("📄 豆包AI原始响应（前500字符）:")
                        print("---")
                        print(String(content.prefix(500)))
                        print("---")
                        
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
    private func buildCharacterCommentPrompt(postContent: String, characters: [String], imageCount: Int = 1) -> String {
        // 获取角色详细信息
        let characterDataManager = CharacterDataManager.shared
        let characterInfo = characters.map { id -> String in
            let name = characterDataManager.getName(for: id) ?? id.capitalized
            let briefDesc = characterDataManager.getAttribute(id: id, attribute: "briefDescription") ?? ""
            let field = characterDataManager.getAttribute(id: id, attribute: "primaryField") ?? ""
            let era = characterDataManager.getAttribute(id: id, attribute: "era") ?? ""
            
            // 构建详细的角色信息
            var info = "- **\(name)** (ID: \(id))"
            if !era.isEmpty {
                info += "\n  时代：\(era)"
            }
            if !field.isEmpty {
                info += "\n  领域：\(field)"
            }
            if !briefDesc.isEmpty {
                info += "\n  简介：\(briefDesc)"
            }
            return info
        }.joined(separator: "\n\n")
        
        // 获取当前时间戳作为随机因子
        let currentTime = Date().timeIntervalSince1970
        
        // 生成随机情绪状态
        let emotions = ["积极", "平静", "专注", "好奇", "温和", "愉悦", "深思", "轻松"]
        let randomEmotion = emotions.randomElement() ?? "平静"
        
        // 生成互动深度
        let interactionLevels = ["初次相遇", "熟悉朋友", "知己", "老友"]
        let interactionDepth = interactionLevels.randomElement() ?? "熟悉朋友"
        
        // 🎯 根据图片数量动态调整提示词
        let imageDescription: String
        let multiImageStrategy: String
        
        if imageCount > 1 {
            imageDescription = "图片：本帖子包含\(imageCount)张不同的图片，请仔细观察每一张"
            multiImageStrategy = """
            
            【多图片评论策略】⚠️ 重要
            本帖子有\(imageCount)张不同的图片，每个角色必须：
            1. 选择不同的图片作为评论重点（比如第1张、第\(min(imageCount/2, imageCount))张、第\(imageCount)张等）
            2. 或者对同一张图片选择完全不同的细节和角度（一个看构图，一个看色彩，一个看情绪）
            3. 🚫 严禁所有角色都评论同一个元素或特征（比如都说某个符号、都说某个物体）
            4. 展现图片的多样性和丰富性，让用户感受到每张图片都被关注到
            5. 如果图片风格差异很大（比如有风景、人物、物品），每个角色应该选择符合自己专业领域的图片
            """
        } else {
            imageDescription = "图片：请仔细观察上传的图片"
            multiImageStrategy = ""
        }
        
        let prompt = """
        你需要为以下角色分别生成对这条带图帖子的评论：
        \(characterInfo)
        
        帖子内容："\(postContent)"
        \(imageDescription)\(multiImageStrategy)
        
        【评论任务】
        请为每个角色以其独特视角和个性评论这条帖子，创造让用户感到"这评论真有意思"的效果。
        
        1. 建立连接点：
           - 找到图片/帖子内容与角色的经历、知识或价值观的联系
           - 从角色的时代背景和专业角度提供独特见解
           - 与帖子作者建立思想上的对话
        
        2. 展现个性：
           - 使用符合角色身份的表达方式
           - 体现角色的思维特点和价值观
           - 避免刻板印象，展现真实个性
        
        3. 创造价值：
           - 提供用户没想到的角度或观点
           - 分享相关的个人经历或感悟
           - 引发用户进一步思考
        
        【表达要求】
        • 评论长度：25-50字，简短有力
        • 语言风格：自然流畅，像朋友间真诚交流
        • 避免固定句式，如"作为[角色]"、"看到这图"
        • 不要重复引用帖子内容
        • 可以在适当情况下直接称呼"你"
        • 使用通俗易懂的现代语言
        
        【风格指导】
        • 保持克制：避免过度情绪化或戏剧化表达
        • 真实自然：像真人评论一样，有个性但不刻意
        • 有温度：让用户感受到被理解和关注
        • 有惊喜：提供意想不到但又合理的观点
        
        【避免事项】
        • 不要使用模板化的礼貌用语
        • 避免空洞的赞美或泛泛而谈
        • 不要过度解释或说教
        • 严禁添加注释、括号说明、"注："、"PS："等
        • 严禁使用过于专业或学术的词汇
        • 严禁@其他角色
        
        【多角色差异化】
        如果有多个角色，确保：
        - 每个角色选择不同的切入点或图片
        - 展现完全不同的视角和情感基调
        - 避免所有人都评论同一个元素
        
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
        左下角那纹理，跟我在加拉帕戈斯观察到的惊人相似。
        点赞：是
        
        随机因子：\(currentTime)_\(randomEmotion)_\(interactionDepth)
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
                    print("📝 [豆包] 解析点赞判断: 原文='\(trimmedLine)', 结果=✅是")
                } else if lowerLine.contains("否") || lowerLine.contains("no") || lowerLine.contains("false") {
                    currentShouldLike = false
                    print("📝 [豆包] 解析点赞判断: 原文='\(trimmedLine)', 结果=❌否")
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
        
        print("🎭 解析到\(result.count)个角色评论: \(result.keys.joined(separator: ", "))")
        print("❤️ 点赞决策: \(characterLikeDecisions)")
        return result
    }
} 