import SwiftUI
import PhotosUI

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
    @State private var selectedImageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingSourceOptions = false
    
    // 错误处理
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingQuickCreateHelp = false
    
    // 分类选择
    @State private var selectedCategory: CharacterCategory = .fictionCharacter
    
    // 可选择的角色分类
    private let selectableCategories: [CharacterCategory] = [
        // 历史人物分类
        .historical, .scientist, .artist, .philosopher, .writer,
        // 虚构角色分类
        .fictionCharacter, .animeCharacter, .gameCharacter, 
        .movieCharacter, .tvCharacter, .mythCharacter, .vtuber
    ]
    
    // 时代选项
    private let eras = ["古代", "近代", "现代", "未来", "架空世界", "动漫世界"]
    
    // 验证状态
    private var isFormValid: Bool {
        !name.isEmpty && !introduction.isEmpty && selectedImage != nil
    }
    
    // 提交按钮是否禁用
    private var isSubmitDisabled: Bool {
        isGeneratingInfo || !isFormValid
    }
    
    var body: some View {
        Form {
            // 快速创建区域
            Section(header: Text("快速创建")) {
                Toggle("快速创建模式", isOn: Binding(
                    get: { quickCreateMode },
                    set: { 
                        quickCreateMode = $0
                        if !$0 {
                            // 退出快速创建模式时清空搜索文本
                            characterSearchText = ""
                        }
                    }
                ))
                
                if quickCreateMode {
                    HStack {
                        TextField("输入角色名称和出处，如'航海王中的索隆'", text: $characterSearchText)
                        
                        Button(action: {
                            generateCharacterInfo()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                        }
                        .disabled(characterSearchText.isEmpty || isGeneratingInfo)
                    }
                    
                    if isGeneratingInfo {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 10)
                            Spacer()
                        }
                    } else if let error = generationError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.vertical, 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("提示：")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("输入角色名称和出处，例如：")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("• 航海王中的索隆")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("• 钢铁侠托尼·斯塔克")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("• 哈利·波特")
                            .font(.footnote)
                            .foregroundColor(.gray)
                        Text("• 科学家爱因斯坦")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                    
                    Button(action: {
                        showingQuickCreateHelp.toggle()
                    }) {
                        Label("如何使用快速创建", systemImage: "questionmark.circle")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .sheet(isPresented: $showingQuickCreateHelp) {
                        QuickCreateHelpView()
                    }
                }
            }
            
            // 基本信息区域
            Section(header: Text("基本信息")) {
                TextField("角色名称 *", text: $name)
                TextField("职业/身份 *", text: $field)
                TextField("地区/国家", text: $region)
                
                TextEditor(text: $introduction)
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            if introduction.isEmpty {
                                HStack {
                                    Text("角色简介 *")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    )
            }
            
            // 角色分类
            Section(header: Text("角色分类")) {
                Picker("角色类型", selection: $selectedCategory) {
                    ForEach(selectableCategories, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                HStack {
                    Text("选中类型")
                    Spacer()
                    Text(selectedCategory.displayName)
                        .foregroundColor(selectedCategory.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory.color.opacity(0.15))
                        )
                }
            }
            
            // 时间信息
            Section(header: Text("时间信息")) {
                TextField("出生年份", text: $birthYear)
                    .keyboardType(.numberPad)
                TextField("逝世年份（如适用）", text: $deathYear)
                    .keyboardType(.numberPad)
                
                Picker("时代/世界", selection: $selectedEraIndex) {
                    ForEach(0..<eras.count, id: \.self) { index in
                        Text(eras[index])
                    }
                }
            }
            
            // 形象
            Section(header: Text("形象")) {
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    HStack {
                        Text(selectedImage != nil ? "更换头像" : "选择角色头像")
                        Spacer()
                        if selectedImage != nil {
                            Image(uiImage: selectedImage!)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    CharacterImagePicker(selectedImage: $selectedImage, isPresented: $isShowingImagePicker, avatarSelected: .constant(false))
                }
            }
            
            // 角色特点
            Section(header: Text("角色特点（每项用逗号分隔多个内容）")) {
                TextEditor(text: $keyThoughts)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            if keyThoughts.isEmpty {
                                HStack {
                                    Text("名言/经典台词")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    )
                
                TextEditor(text: $achievements)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            if achievements.isEmpty {
                                HStack {
                                    Text("主要成就")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    )
                
                TextEditor(text: $mainWorks)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            if mainWorks.isEmpty {
                                HStack {
                                    Text("主要作品")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    )
            }
        }
        .navigationTitle("创建自定义角色")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("创建") {
                    if validateForm() {
                        createCharacter()
                    }
                }
                .disabled(isSubmitDisabled)
                .fontWeight(.bold)
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("创建失败"),
                message: Text(errorMessage),
                dismissButton: .default(Text("确定"))
            )
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
        
        // 处理头像 - 修复：使用默认头像而不是尝试生成自定义头像
        let avatarName: String
        if let _ = selectedImage {
            // 如果用户选择了头像，使用默认头像命名方式，但不尝试保存图片
            // 头像将会在后面的步骤中使用更安全的方法处理
            avatarName = "default_avatar"
        } else {
            // 如果没有选择头像，使用默认头像
            avatarName = "default_avatar"
        }
        
        print("尝试创建角色: \(name)")
        
        // 创建新角色 - 确保所有必填字段都有值，减少可选参数
        let newCharacter = CharacterModel(
            id: characterId,
            name: name,
            avatar: avatarName,
            era: eras[selectedEraIndex],
            profession: field,
            bio: introduction,
            category: selectedCategory
        )
        
        print("角色创建成功，添加到列表")
        
        // 添加到角色列表
        characters.append(newCharacter)
        
        // 保存到本地存储
        saveCharacterToUserDefaults(newCharacter, achievements: achievementsArray, mainWorks: mainWorksArray)
        
        // 如果用户选择了头像，安全地保存头像
        if let image = selectedImage {
            // 使用更可靠的方法保存图片
            DispatchQueue.global(qos: .background).async {
                self.safelySaveImage(image, forCharacterId: characterId)
            }
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
        1. 全名
        2. 职业/身份
        3. 地区/国家
        4. 简短介绍（100字以内）
        5. 主要成就（用逗号分隔）
        6. 主要作品（用逗号分隔）
        7. 所属分类（必须是以下之一：历史人物、科学家、艺术家、哲学家、文学家、虚构人物、动漫角色、游戏角色、电影角色、电视剧角色、神话角色、虚拟主播）
        8. 时代背景（古代、近代、现代、未来、架空世界、动漫世界）
        
        以JSON格式返回，格式如下：
        {
          "name": "角色全名",
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
        
        // 调用API获取角色信息
        Task {
            do {
                let response = try await aiNetworkService.fetchAIResponse(
                    prompt: prompt,
                    model: apiConfigManager.currentConfig.defaultModel,
                    temperature: 0.7,
                    maxTokens: 1000
                )
                
                // 解析JSON响应
                if let jsonData = response.data(using: .utf8) {
                    do {
                        let decoder = JSONDecoder()
                        let characterInfo = try decoder.decode(CharacterInfo.self, from: jsonData)
                        
                        // 更新UI - 必须在主线程
                        await MainActor.run {
                            // 填充表单
                            self.name = characterInfo.name
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
                    } catch {
                        await MainActor.run {
                            self.generationError = "无法解析角色信息: \(error.localizedDescription)"
                            self.isGeneratingInfo = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.generationError = "无法解析API响应"
                        self.isGeneratingInfo = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.generationError = "获取角色信息失败: \(error.localizedDescription)"
                    self.isGeneratingInfo = false
                }
            }
        }
    }
    
    // 将字符串映射到角色分类
    private func mapStringToCategory(_ categoryString: String) -> CharacterCategory? {
        switch categoryString.lowercased() {
        case "历史人物": return .historical
        case "科学家": return .scientist
        case "艺术家": return .artist
        case "哲学家": return .philosopher
        case "文学家": return .writer
        case "虚构人物": return .fictionCharacter
        case "动漫角色": return .animeCharacter
        case "游戏角色": return .gameCharacter
        case "电影角色": return .movieCharacter
        case "电视剧角色": return .tvCharacter
        case "神话角色": return .mythCharacter
        case "虚拟主播": return .vtuber
        default: return .fictionCharacter
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
        guard let data = image.jpegData(compressionQuality: 0.7) else { 
            print("无法将图像转换为JPEG数据")
            return 
        }
        
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(forCharacterId).jpg")
            try data.write(to: fileURL)
            print("图像安全保存成功: \(fileURL.path)")
        } catch {
            print("保存图像失败: \(error)")
        }
    }

    // 移除之前可能会导致问题的generateAvatarName方法
    // private func generateAvatarName() -> String {
    //    return "avatar_custom_\(UUID().uuidString.prefix(8))"
    // }
    
    // 保存角色到UserDefaults
    private func saveCharacterToUserDefaults(_ character: CharacterModel, achievements: [String], mainWorks: [String]) {
        // 获取现有的自定义角色列表
        var customCharacters = UserDefaults.standard.array(forKey: "CustomCharacters") as? [[String: Any]] ?? []
        
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
        
        // 确保所有嵌套数据都是属性列表兼容的
        let propertyListCustomCharacters = convertToPropertyList(customCharacters)
        
        // 保存到UserDefaults
        do {
            // 使用Data方式保存复杂数据
            let data = try JSONSerialization.data(withJSONObject: propertyListCustomCharacters, options: [])
            UserDefaults.standard.set(data, forKey: "CustomCharactersData")
            print("角色数据已成功保存到UserDefaults")
        } catch {
            print("保存角色数据失败: \(error)")
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
            VStack(alignment: .leading, spacing: 20) {
                Text("如何使用快速创建功能")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text("输入角色名称和出处，例如\"航海王中的索隆\"或\"物理学家爱因斯坦\"")
                    }
                    
                    HStack(alignment: .top) {
                        Text("2.")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text("点击搜索按钮，系统会自动生成角色信息")
                    }
                    
                    HStack(alignment: .top) {
                        Text("3.")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text("检查并调整生成的信息，确保准确性")
                    }
                    
                    HStack(alignment: .top) {
                        Text("4.")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text("添加角色头像（可选）")
                    }
                    
                    HStack(alignment: .top) {
                        Text("5.")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 25, alignment: .leading)
                        
                        Text("点击\"创建\"按钮完成")
                    }
                }
                .padding()
                
                Divider()
                
                Text("提示：")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("• 描述越详细，生成的信息越准确\n• 目前支持部分知名角色的自动识别\n• 所有生成的信息均可手动修改\n• 创建的角色仅供个人使用")
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("使用帮助", displayMode: .inline)
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 