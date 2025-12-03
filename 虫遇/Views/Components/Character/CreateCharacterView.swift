import SwiftUI
import PhotosUI
import StoreKit

/**
 * 创建自定义角色视图
 * 允许用户创建自己的虚拟角色
 */
struct CreateCharacterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var characters: [CharacterModel]
    
    // 网络服务
    private let aiNetworkService = AINetworkService.shared
    private let apiConfigManager = APIConfigManager.shared
    
    // 快速创建相关
    @State private var quickCreateMode: Bool = false
    @State private var characterSearchText: String = ""
    @State private var isGeneratingInfo: Bool = false
    @State private var generationError: String? = nil
    
    // 基本信息
    @State private var name: String = ""
    @State private var introduction: String = ""
    @State private var field: String = ""
    @State private var region: String = ""
    @State private var birthYear: String = ""
    @State private var deathYear: String = ""
    @State private var selectedEraIndex: Int = 0
    
    // 角色特点
    @State private var achievements: String = ""
    @State private var mainWorks: String = ""
    @State private var keyThoughts: String = ""
    
    // 图像选择
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    
    // 错误处理
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingQuickCreateHelp = false
    
    // 分类选择
    @State private var selectedCategory: CharacterCategory = .animeCharacter
    
    // 可选择的角色分类
    private let selectableCategories: [CharacterCategory] = [
        // 历史人物分类
        .historical, .philosopher, .writer,
        // 虚构角色分类
        .animeCharacter, .gameCharacter, .filmCharacter, .mythCharacter
    ]
    
    // 时代选项
    private let eras = ["古代", "近代", "现代", "未来", "架空世界", "动漫世界"]
    
    // 验证状态
    private var isFormValid: Bool {
        !name.isEmpty && !introduction.isEmpty && !field.isEmpty && selectedImage != nil
    }
    
    // 提交按钮是否禁用
    private var isSubmitDisabled: Bool {
        isGeneratingInfo || !isFormValid
    }
    
    // 充值相关
    @State private var showRechargeSheet: Bool = false
    @State private var purchaseErrorMessage: String? = nil
    @ObservedObject private var storeKitManager = StoreKitManager.shared
    
    var body: some View {
        ZStack {
            // 背景色 - 使用与探索页面一致的温暖米白色背景
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
        Form {
            // 快速创建区域 - 优化布局和用户体验
            Section(header: Text("快速创建").font(.system(size: 15, weight: .medium)).foregroundColor(.gray)) {
                VStack(spacing: 8) {
                    // 开关和搜索框放在同一行，节省空间
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { quickCreateMode },
                            set: { 
                                quickCreateMode = $0
                                if !$0 {
                                    // 退出快速创建模式时清空搜索文本
                                    characterSearchText = ""
                                }
                            }
                        ))
                        .labelsHidden()
                        .frame(width: 50)
                        
                        if quickCreateMode {
                            // 搜索框和按钮
                            HStack(spacing: 2) {
                                TextField("航海王中的索隆", text: $characterSearchText)
                                    .font(.system(size: 15))
                                    .padding(.vertical, 2)
                                
                                Button(action: {
                                    generateCharacterInfo()
                                }) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color(hex: "6A7FDB"))
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .disabled(characterSearchText.isEmpty || isGeneratingInfo)
                                .padding(.horizontal, 6)
                            }
                            .padding(6)
                            .background(Color(hex: "F2F2F7"))
                            .cornerRadius(8)
                        } else {
                            Text("快速创建模式")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 只在快速创建模式下显示提示和状态
                    if quickCreateMode {
                        // 生成状态和错误信息
                        if isGeneratingInfo {
                                HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 4)
                                Text("正在生成角色信息...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                                Spacer()
                                }
                            .padding(.vertical, 4)
                            .background(Color(hex: "F2F2F7").opacity(0.5))
                            .cornerRadius(6)
                        } else if let error = generationError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.vertical, 2)
                        } else if !name.isEmpty && !characterSearchText.isEmpty {
                            // 显示填充成功的提示
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                Text("已自动填充角色信息")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        } else {
                            // 简化的提示，只占一行
                            HStack {
                                Text("提示: 输入如\"航海王中的索隆\"或\"爱因斯坦\"")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                Button(action: {
                                    showingQuickCreateHelp.toggle()
                                }) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .sheet(isPresented: $showingQuickCreateHelp) {
                                    QuickCreateHelpView()
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            
            // 形象 - 移到基本信息前面，优化设计
            Section(header: Text("形象").font(.system(size: 15, weight: .medium)).foregroundColor(.gray)) {
                VStack(alignment: .center, spacing: 10) {
                    // 头像预览 - 调整大小和样式
                    if selectedImage != nil {
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: "6A7FDB").opacity(0.6), lineWidth: 2))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .padding(.vertical, 5)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F2F2F7"))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        .padding(.vertical, 5)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "photo")
                                    Text("从相册选择")
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            .foregroundColor(Color(hex: "6A7FDB"))
                        }
                        .font(.system(size: 14, weight: .medium))
                    }
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    CharacterImagePicker(selectedImage: $selectedImage, isPresented: $isShowingImagePicker, avatarSelected: .constant(true))
                }
            }
            
            // 基本信息
            Section(header: Text("基本信息").font(.system(size: 15, weight: .medium)).foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("角色名称 (中文/英文)", text: $name)
                        .font(.system(size: 16))
                        .padding(.vertical, 4)
                    
                    TextField("职业/身份，如科学家、作家", text: $field)
                        .font(.system(size: 16))
                        .padding(.vertical, 4)
                    
                    TextField("地区/国家，如中国、美国", text: $region)
                        .font(.system(size: 16))
                        .padding(.vertical, 4)
                    
                    Text("角色简介")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                    TextEditor(text: $introduction)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color(hex: "F2F2F7").opacity(0.5))
                        .cornerRadius(8)
                }
            }
            
            // 特色信息
            Section(header: Text("主要成就、作品").font(.system(size: 15, weight: .medium)).foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("主要成就 (用逗号分隔)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    TextEditor(text: $achievements)
                        .frame(height: 70)
                        .padding(4)
                        .background(Color(hex: "F2F2F7").opacity(0.5))
                        .cornerRadius(8)
                    
                    Text("主要作品 (用逗号分隔)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.bottom, 2)
                    
                    TextEditor(text: $mainWorks)
                        .frame(height: 70)
                        .padding(4)
                        .background(Color(hex: "F2F2F7").opacity(0.5))
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)
            }
        }
        .scrollContentBackground(.hidden) // 隐藏Form的默认背景
        }
        .navigationTitle("创建自定义角色")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(hex: "9A8BB0"))
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if validateForm() {
                        createCharacter()
                    }
                } label: {
                    Text("创建")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSubmitDisabled ? .gray : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isSubmitDisabled ? Color.gray.opacity(0.2) : Color(hex: "8B7EC8"))
                        )
                }
                .disabled(isSubmitDisabled)
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("创建失败"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $showRechargeSheet, onDismiss: {
            purchaseErrorMessage = nil
        }) {
            NavigationView {
                VStack(alignment: .leading, spacing: 12) {
                    if storeKitManager.products.isEmpty {
                        VStack {
                            ProgressView()
                            Text("正在加载商品...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(storeKitManager.products, id: \.id) { product in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.displayName)
                                            .font(.system(size: 16, weight: .medium))
                                        Text(product.displayPrice)
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14))
                                    }
                                    Spacer()
                                    Button("购买") {
                                        Task {
                                            do {
                                                _ = try await storeKitManager.purchase(product)
                                                purchaseErrorMessage = nil
                                                showRechargeSheet = false
                                            } catch {
                                                purchaseErrorMessage = error.localizedDescription
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    if let msg = purchaseErrorMessage {
                        Text(msg)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }
                }
                .navigationTitle("充值")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("关闭") { showRechargeSheet = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("恢复") {
                            Task { await storeKitManager.loadProducts() }
                        }
                    }
                }
                .task {
                    if storeKitManager.products.isEmpty {
                        await storeKitManager.loadProducts()
                    }
                }
            }
        }
    }
    
    // 表单验证
    private func validateForm() -> Bool {
        if name.isEmpty {
            errorMessage = "请输入角色名称"
            showingError = true
            return false
        }
        
        if introduction.isEmpty {
            errorMessage = "请输入角色简介"
            showingError = true
            return false
        }
        
        if field.isEmpty {
            errorMessage = "请输入角色职业/身份"
            showingError = true
            return false
        }
        
        if selectedImage == nil {
            errorMessage = "请为角色添加头像"
            showingError = true
            return false
        }
        
        return true
    }
    
    /**
     * 创建自定义角色
     */
    private func createCharacter() {
        // 处理成就、作品和思想为数组
        let achievementsArray = achievements
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
            
        let mainWorksArray = mainWorks
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
            
        // 使用下划线替代未使用的变量
        _ = keyThoughts
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
        
        // 生成唯一ID
        let characterId = "custom_\(UUID().uuidString.prefix(8))"
        
        // 处理头像 - 使用默认头像
        let avatarName = "default_avatar"
        
        // 处理角色名称，优化显示效果
        let optimizedName = optimizeCharacterName(name)
        
        #if DEBUG
        print("尝试创建角色: \(optimizedName)")
        #endif
        
        // 创建新角色 - 确保所有必填字段都有值，减少可选参数
        let newCharacter = CharacterModel(
            id: characterId,
            name: optimizedName,  // 使用优化后的名称
            avatar: avatarName,
            era: eras[selectedEraIndex],
            profession: field,
            bio: introduction,
            category: selectedCategory
        )
        
        #if DEBUG
        print("角色创建成功，添加到列表")
        #endif
        
        // 添加到角色列表
        characters.append(newCharacter)
        
        // 保存到本地存储
        saveCharacterToUserDefaults(newCharacter, achievements: achievementsArray, mainWorks: mainWorksArray)
        
        // 如果用户选择了头像，安全地保存头像
        if let image = selectedImage {
            // 使用更可靠的方法保存图片
            #if DEBUG
            print("📸 CreateCharacterView - 开始保存用户选择的头像")
            #endif
            DispatchQueue.global(qos: .background).async {
                self.safelySaveImage(image, forCharacterId: characterId)
            }
        } else {
            #if DEBUG
            print("⚠️ CreateCharacterView - 用户未选择头像，使用默认头像")
            #endif
        }
        
        // 发送通知，通知其他视图更新
        NotificationCenter.default.post(
            name: Notification.Name("CharacterCreated"),
            object: nil,
            userInfo: ["characterId": characterId]
        )
        
        // 关闭表单
        presentationMode.wrappedValue.dismiss()
    }
    
    // 生成角色信息
    private func generateCharacterInfo() {
        guard !characterSearchText.isEmpty else { return }
        
        isGeneratingInfo = true
        generationError = nil
        
        // 构建提示词
        let prompt = """
        用户想要创建一个角色: \(characterSearchText)
        请提供这个角色的详细信息，包括：
        1. 全名（优先使用中文名称）
        2. 职业/身份
        3. 地区/国家
        4. 简短介绍（100字以内）
        5. 主要成就（用逗号分隔）
        6. 主要作品（用逗号分隔）
        7. 所属分类（必须是以下之一：历史人物、科学家、艺术家、哲学家、文学世界、虚构人物、动漫角色、游戏角色、电影角色、电视剧角色、神话角色、虚拟主播）
        8. 时代背景（古代、近代、现代、未来、架空世界、动漫世界）
        
        以JSON格式返回，格式如下：
        {
          "name": "角色全名（如有英文名称，请放在括号内）",
          "field": "职业/身份",
          "region": "地区/国家",
          "introduction": "简短介绍",
          "achievements": "主要成就1,主要成就2",
          "mainWorks": "主要作品1,主要作品2",
          "category": "所属分类",
          "era": "时代背景"
        }
        
        只返回JSON数据，不要有其他任何文字。
        """
        
        // 使用URLSession直接调用API，避免使用Combine
        Task {
            do {
                // 改为通过后端代理请求
                let messages: [[String: String]] = [
                    ["role": "system", "content": "你是一个角色信息生成助手，请根据用户的描述生成角色信息。只返回JSON。"],
                    ["role": "user", "content": prompt]
                ]
                let resp = try await WalletService.shared.proxyChat(messages: messages, params: [
                    "temperature": 0.7,
                    "max_tokens": 1000,
                    "top_p": 0.95,
                    "stream": false
                ])
                if let choices = resp["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let message = first["message"] as? [String: Any],
                   let content = extractMessageContent(from: message) {
                    let cleanedContent = sanitizeJSONContent(content)
                    if let data = cleanedContent.data(using: .utf8) {
                        if let info = try? JSONDecoder().decode(CharacterInfo.self, from: data) {
                            await fillFormWithCharacterInfo(info)
                        } else if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            await MainActor.run {
                                self.name = optimizeCharacterName(jsonObj["name"] as? String ?? "")
                                self.field = jsonObj["field"] as? String ?? ""
                                self.region = jsonObj["region"] as? String ?? ""
                                self.introduction = jsonObj["introduction"] as? String ?? ""
                                self.achievements = jsonObj["achievements"] as? String ?? ""
                                self.mainWorks = jsonObj["mainWorks"] as? String ?? ""
                                if let categoryStr = jsonObj["category"] as? String, let category = mapStringToCategory(categoryStr) {
                                    self.selectedCategory = category
                                }
                                if let eraStr = jsonObj["era"] as? String, let eraIndex = mapStringToEraIndex(eraStr) {
                                    self.selectedEraIndex = eraIndex
                                }
                                self.isGeneratingInfo = false
                            }
                        } else {
                            await MainActor.run {
                                generationError = "返回内容非JSON"
                                isGeneratingInfo = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            generationError = "返回内容非JSON"
                            isGeneratingInfo = false
                        }
                    }
                } else {
                    await MainActor.run {
                        generationError = "响应解析失败"
                        isGeneratingInfo = false
                    }
                }
            } catch {
                await MainActor.run {
                    let nsError = error as NSError
                    if nsError.domain == "wallet" && nsError.code == 402 {
                        generationError = "余额不足，请先充值。"
                        isGeneratingInfo = false
                        showRechargeSheet = true
                        Task { await storeKitManager.loadProducts() }
                    } else {
                        generationError = error.localizedDescription
                        isGeneratingInfo = false
                    }
                }
            }
        }
    }
    
    /// 兼容 OpenAI 新格式的 content（可能是字符串，也可能是数组）
    private func extractMessageContent(from message: [String: Any]) -> String? {
        if let str = message["content"] as? String {
            return str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let contentArray = message["content"] as? [[String: Any]] {
            let texts: [String] = contentArray.compactMap { item in
                guard let type = item["type"] as? String, type == "text" else { return nil }
                if let text = item["text"] as? String {
                    return text
                }
                if let textDict = item["text"] as? [String: Any],
                   let value = textDict["value"] as? String {
                    return value
                }
                return nil
            }
            let combined = texts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return combined.isEmpty ? nil : combined
        }
        
        return nil
    }
    
    /// 去掉模型返回的 ```json ``` 包裹或额外说明，只保留纯 JSON
    private func sanitizeJSONContent(_ content: String) -> String {
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.hasPrefix("```") {
            // 去掉代码块包裹
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}") {
            return String(cleaned[start...end])
        }
        return cleaned
    }
    
    // 将字符串映射到角色分类
    private func mapStringToCategory(_ categoryString: String) -> CharacterCategory? {
        switch categoryString.lowercased() {
        case "历史人物", "科学家", "艺术家": return .historical
        case "哲学家": return .philosopher
        case "文学世界": return .writer
        case "动漫角色": return .animeCharacter
        case "游戏角色": return .gameCharacter
        case "电影角色", "电视剧角色", "影视角色": return .filmCharacter
        case "神话角色": return .mythCharacter
        default: return .animeCharacter
        }
    }
    
    // 将字符串映射到时代索引
    private func mapStringToEraIndex(_ eraString: String) -> Int? {
        switch eraString {
        case "古代": return 0
        case "近代": return 1
        case "现代": return 2
        case "未来": return 3
        case "架空世界": return 4
        case "动漫世界": return 5
        default: return 2 // 默认为现代
        }
    }
    
    // 角色信息解码模型
    private struct CharacterInfo: Decodable {
        let name: String
        let field: String
        let region: String
        let introduction: String
        let achievements: String
        let mainWorks: String
        let category: String
        let era: String
    }
    
    // 安全地保存图像
    private func safelySaveImage(_ image: UIImage, forCharacterId: String) {
        // 先裁剪图片为正方形（居中裁剪）
        let croppedImage = cropImageToSquare(image)
        
        // 压缩并转换为JPEG数据（使用较高质量以保持清晰度）
        guard let data = croppedImage.jpegData(compressionQuality: 0.85) else { 
            #if DEBUG
            print("❌ CreateCharacterView - 无法将图像转换为JPEG数据")
            #endif
            return 
        }
        
        do {
            // 获取文档目录
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            // 确保目录存在
            if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
                try FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
            }
            
            // 创建保存路径
            let fileURL = documentsDirectory.appendingPathComponent("\(forCharacterId).jpg")
            
            // 写入数据
            try data.write(to: fileURL)
            #if DEBUG
            print("✅ CreateCharacterView - 头像已保存到: \(fileURL.path), 尺寸: \(Int(croppedImage.size.width))x\(Int(croppedImage.size.height))")
            #endif
        } catch {
            #if DEBUG
            print("❌ CreateCharacterView - 保存头像失败: \(error)")
            #endif
        }
    }
    
    /// 裁剪图片为正方形（居中裁剪）
    private func cropImageToSquare(_ image: UIImage) -> UIImage {
        let originalSize = image.size
        let minDimension = min(originalSize.width, originalSize.height)
        
        // 如果已经是正方形，检查是否需要缩放
        if originalSize.width == originalSize.height {
            // 如果图片太大，先缩放（限制最大尺寸为512x512）
            if minDimension > 512 {
                return resizeImage(image, to: CGSize(width: 512, height: 512))
            }
            return image
        }
        
        // 计算裁剪区域（居中裁剪）
        let cropRect = CGRect(
            x: (originalSize.width - minDimension) / 2,
            y: (originalSize.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        // 裁剪图片
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        var croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // 如果裁剪后的图片太大，缩放（限制最大尺寸为512x512）
        if minDimension > 512 {
            croppedImage = resizeImage(croppedImage, to: CGSize(width: 512, height: 512))
        }
        
        return croppedImage
    }
    
    /// 调整图片大小
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // 移除之前可能会导致问题的generateAvatarName方法
    // private func generateAvatarName() -> String {
    //    return "avatar_custom_\(UUID().uuidString.prefix(8))"
    // }
    
    // 保存角色到UserDefaults
    private func saveCharacterToUserDefaults(_ character: CharacterModel, achievements: [String], mainWorks: [String]) {
        // 从CustomCharactersData中获取现有的自定义角色列表
        var customCharacters: [[String: Any]] = []
        
        // 尝试加载现有数据
        if let data = UserDefaults.standard.data(forKey: "CustomCharactersData") {
            do {
                if let existingCharacters = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    customCharacters = existingCharacters
                    #if DEBUG
                    print("成功加载现有角色数据，共\(customCharacters.count)个角色")
                    #endif
                }
            } catch {
                #if DEBUG
                print("加载现有角色数据失败: \(error)")
                #endif
                // 如果加载失败，使用空数组
                customCharacters = []
            }
        }
        
        // 将新角色转换为字典 - 确保所有值都是属性列表兼容的
        var characterDict: [String: Any] = [
            "id": character.id,
            "name": character.name,
            "avatar": character.avatar,
            "era": character.era,
            "profession": character.profession,
            "bio": character.bio,
            "category": character.category.rawValue, // 保存原始值而不是枚举
            "achievements": achievements,
            "mainWorks": mainWorks,
            "region": region
        ]
        
        // 处理可选值，确保不传递nil给UserDefaults
        if let universe = character.universe {
            characterDict["universe"] = universe
        } else {
            characterDict["universe"] = "" // 使用空字符串代替nil
        }
        
        if let famousQuotes = character.famousQuotes, !famousQuotes.isEmpty {
            characterDict["famousQuotes"] = famousQuotes
        } else {
            characterDict["famousQuotes"] = [String]() // 使用空数组代替nil
        }
        
        // 添加到列表
        customCharacters.append(characterDict)
        #if DEBUG
        print("添加新角色后，共有\(customCharacters.count)个角色")
        #endif
        
        // 确保所有嵌套数据都是属性列表兼容的
        let propertyListCustomCharacters = convertToPropertyList(customCharacters)
        
        // 保存到UserDefaults
        do {
            // 使用Data方式保存复杂数据
            let data = try JSONSerialization.data(withJSONObject: propertyListCustomCharacters, options: [])
            UserDefaults.standard.set(data, forKey: "CustomCharactersData")
            #if DEBUG
            print("角色数据已成功保存到UserDefaults")
            #endif
        } catch {
            #if DEBUG
            print("保存角色数据失败: \(error)")
            #endif
            errorMessage = "保存角色数据失败: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // 确保数据是属性列表兼容的
    private func convertToPropertyList(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var result = [String: Any]()
            for (key, val) in dict {
                result[key] = convertToPropertyList(val)
            }
            return result
        } else if let array = value as? [Any] {
            return array.map { convertToPropertyList($0) }
        } else if let _ = value as? NSNull {
            return ""
        } else if value is String || value is Int || value is Double || value is Bool || value is Date || value is Data {
            return value
        } else {
            return String(describing: value) // 将其他类型转换为字符串
        }
    }

    // 从API响应填充表单
    private func fillFormWithCharacterInfo(_ characterInfo: CharacterInfo) async {
        await MainActor.run {
            // 优化名称显示
            let optimizedName = optimizeCharacterName(characterInfo.name)
            
            // 填充表单
            self.name = optimizedName
            self.field = characterInfo.field
            self.region = characterInfo.region
            self.introduction = characterInfo.introduction
            self.achievements = characterInfo.achievements
            self.mainWorks = characterInfo.mainWorks
            
            // 设置分类
            if let category = mapStringToCategory(characterInfo.category) {
                self.selectedCategory = category
            }
            
            // 设置时代
            if let eraIndex = mapStringToEraIndex(characterInfo.era) {
                self.selectedEraIndex = eraIndex
            }
            
            self.isGeneratingInfo = false
        }
    }

    // 优化角色名称显示效果
    private func optimizeCharacterName(_ originalName: String) -> String {
        // 1. 检查是否有括号，提取括号前的内容
        if let bracketRange = originalName.range(of: "（"), let startIndex = originalName.indices.first {
            let nameBeforeBracket = String(originalName[startIndex..<bracketRange.lowerBound])
            return nameBeforeBracket.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let bracketRange = originalName.range(of: "("), let startIndex = originalName.indices.first {
            let nameBeforeBracket = String(originalName[startIndex..<bracketRange.lowerBound])
            return nameBeforeBracket.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 2. 如果有中英文混合，优先提取中文部分
        let chineseRange = originalName.range(of: "[\\p{Han}]+", options: .regularExpression)
        if let range = chineseRange {
            // 提取中文部分并添加上下文
            let chineseStartIndex = originalName.startIndex
            
            // 如果中文部分在名字开头，则取到第一个非中文字符或结束
            if range.lowerBound == originalName.startIndex {
                // 找到第一个非中文字符的位置
                var endIndex = range.upperBound
                while endIndex < originalName.endIndex {
                    let currentChar = String(originalName[endIndex])
                    if !containsChineseCharacters(currentChar) {
                        break
                    }
                    endIndex = originalName.index(after: endIndex)
                }
                return String(originalName[chineseStartIndex..<endIndex])
            }
            
            // 如果中文在名字中间或结尾，取中文部分
            return String(originalName[range])
        }
        
        // 3. 处理名称长度，如果过长则截断
        if originalName.count > 12 {
            let endIndex = originalName.index(originalName.startIndex, offsetBy: 12)
            return String(originalName[..<endIndex]) + "..."
        }
        
        // 4. 默认直接返回原名称
        return originalName
    }
    
    // 检查字符串是否包含中文字符
    private func containsChineseCharacters(_ text: String) -> Bool {
        let pattern = "[\\p{Han}]"
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}

// 图像选择器 - 重命名为CharacterImagePicker避免命名冲突
struct CharacterImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    @Binding var avatarSelected: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: CharacterImagePicker
        
        init(_ parent: CharacterImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self?.parent.selectedImage = image
                            self?.parent.avatarSelected = true
                        }
                    }
                }
            }
        }
    }
} 

// 快速创建帮助视图
struct QuickCreateHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                    // 标题
                Text("如何使用快速创建功能")
                    .font(.headline)
                    .padding(.top)
                
                    // 使用步骤
                    VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        Text("1.")
                                .font(.body.weight(.bold))
                                .frame(width: 22, alignment: .leading)
                        
                            Text("输入角色名称，例如“航海王中的索隆”或“爱因斯坦”。名称最重要，描述越具体越好。")
                    }
                    
                    HStack(alignment: .top) {
                        Text("2.")
                                .font(.body.weight(.bold))
                                .frame(width: 22, alignment: .leading)
                        
                            Text("点击搜索按钮，系统会自动生成角色资料。")
                    }
                    
                    HStack(alignment: .top) {
                        Text("3.")
                                .font(.body.weight(.bold))
                                .frame(width: 22, alignment: .leading)
                        
                            Text("检查生成的名称是否正确，其他信息可按需修改。")
                    }
                    
                    HStack(alignment: .top) {
                        Text("4.")
                                .font(.body.weight(.bold))
                                .frame(width: 22, alignment: .leading)
                        
                            Text("添加头像，然后点击“创建”完成。")
                    }
                }
                .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // 使用提示
                    VStack(alignment: .leading, spacing: 8) {
                        Text("使用小提示")
                    .font(.headline)
                            .padding(.bottom, 2)
                        
                        Text("""
                        • 角色名称最关键，请使用真实、准确的称呼  
                        • 支持历史人物、公众人物、知名动漫/影视/游戏角色  
                        • 生成的信息可以随时修改
                        """)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // 角色与内容说明
                    VStack(alignment: .leading, spacing: 8) {
                        Text("角色与内容说明")
                            .font(.headline)
                            .padding(.top, 12)
                            .padding(.bottom, 2)
                        
                        Text("仅支持互联网上已有公开信息的角色。所有对话内容均为 AI 虚构演绎，用于娱乐体验，不代表任何真实人物或机构立场。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                
                    Spacer(minLength: 16)
            }
            .padding()
            }
            .navigationBarTitle("使用帮助", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 