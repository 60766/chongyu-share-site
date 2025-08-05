import SwiftUI
import PhotosUI

/**
 * 创建自定义角色视图
 * 允许用户创建自己的虚拟角色
 */
struct CreateCharacterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var characters: [CharacterModel]
    
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
    @State private var isImagePickerPresented: Bool = false
    @State private var avatarSelected: Bool = false
    
    // 分类选择
    @State private var selectedCategory: CharacterCategory = .fictionCharacter
    
    // 错误处理
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // 快速创建相关状态
    @State private var quickCreateMode: Bool = false
    @State private var characterSearchText: String = ""
    @State private var isGeneratingInfo: Bool = false
    @State private var showingQuickCreateHelp: Bool = false
    
    private let eras = ["现代", "未来", "古代", "中世纪", "文艺复兴", "动漫世界", "科幻宇宙", "奇幻大陆"]
    
    private var isFormValid: Bool {
        !name.isEmpty && !introduction.isEmpty && !field.isEmpty
    }
    
    // 可选择的角色分类
    private let selectableCategories: [CharacterCategory] = [
        // 历史人物分类
        .historical, .scientist, .artist, .philosopher, .writer,
        // 虚构角色分类
        .fictionCharacter, .animeCharacter, .gameCharacter, 
        .movieCharacter, .tvCharacter, .mythCharacter, .vtuber
    ]
    
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
                    }
                    
                    // 示例角色提示
                    Text("试试这些: 索隆、爱因斯坦、哈利·波特、钢铁侠、孙悟空、孔子")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
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
                    isImagePickerPresented = true
                }) {
                    HStack {
                        Text(avatarSelected ? "更换头像" : "选择角色头像")
                        Spacer()
                        if avatarSelected {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    CharacterImagePicker(selectedImage: $selectedImage, isPresented: $isImagePickerPresented, avatarSelected: $avatarSelected)
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
                .disabled(!isFormValid)
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
        
        // 模拟网络请求或AI生成过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 根据输入识别角色
            if characterSearchText.contains("索隆") || characterSearchText.contains("卓洛") {
                // 航海王索隆
                self.name = "罗罗诺亚·索隆"
                self.field = "剑士"
                self.region = "东海"
                self.introduction = "草帽海贼团战斗员，梦想是成为世界第一大剑豪。使用三刀流剑术，右眼有疤痕。性格忠诚但方向感极差。"
                self.selectedCategory = .animeCharacter
                self.selectedEraIndex = 5 // 动漫世界
                self.achievements = "悬赏金：3亿2千万贝利,打败过Mr.1,击败过CP9成员"
                self.mainWorks = "和之国篇,德雷斯罗萨篇,司法岛篇"
                self.keyThoughts = "什么都不知道的人比什么都不能做的人更可怕,我不会再输了！"
            } else if characterSearchText.contains("爱因斯坦") {
                // 爱因斯坦
                self.name = "阿尔伯特·爱因斯坦"
                self.field = "物理学家"
                self.region = "德国"
                self.birthYear = "1879"
                self.deathYear = "1955"
                self.introduction = "20世纪最伟大的物理学家，相对论的创立者，获得过诺贝尔物理学奖。他的质能方程E=mc²彻底改变了人类对宇宙的认识。"
                self.selectedCategory = .scientist
                self.selectedEraIndex = 0 // 现代
                self.achievements = "相对论,光电效应,布朗运动理论,诺贝尔物理学奖"
                self.mainWorks = "狭义相对论,广义相对论,《论动体的电动力学》"
                self.keyThoughts = "想象力比知识更重要,我们不能用制造问题的思维方式来解决问题"
            } else if characterSearchText.contains("哈利") || characterSearchText.contains("波特") {
                // 哈利·波特
                self.name = "哈利·波特"
                self.field = "巫师"
                self.region = "英国"
                self.introduction = "霍格沃茨魔法学校的学生，额头上有闪电形状的疤痕。父母被伏地魔杀害，自己却奇迹般地生存下来，被称为'大难不死的男孩'。"
                self.selectedCategory = .fictionCharacter
                self.selectedEraIndex = 7 // 奇幻大陆
                self.achievements = "三强争霸赛冠军,邓布利多军团创始人,打败伏地魔"
                self.mainWorks = "哈利·波特系列"
                self.keyThoughts = "不是我们的能力决定我们是谁，而是我们的选择,幸福可以在最黑暗的日子里找到，只要记得开灯"
            } else if characterSearchText.contains("钢铁侠") || characterSearchText.contains("托尼") || characterSearchText.contains("斯塔克") {
                // 钢铁侠
                self.name = "托尼·斯塔克"
                self.field = "天才发明家/超级英雄"
                self.region = "美国"
                self.introduction = "斯塔克工业的CEO，天才发明家，凭借自己设计的钢铁战衣成为超级英雄钢铁侠。复仇者联盟的创始成员之一。"
                self.selectedCategory = .movieCharacter
                self.selectedEraIndex = 0 // 现代
                self.achievements = "开发方舟反应堆,创造奥创,打败灭霸"
                self.mainWorks = "钢铁侠三部曲,复仇者联盟系列"
                self.keyThoughts = "有时候，你得先跑起来，才知道自己要去哪,我就是钢铁侠"
            } else if characterSearchText.contains("孙悟空") || characterSearchText.contains("龙珠") {
                // 龙珠孙悟空
                self.name = "孙悟空"
                self.field = "武道家"
                self.region = "地球"
                self.introduction = "来自地球的赛亚人，拥有超强的战斗天赋和纯净的心灵。一生追求变强，保护地球免受各种威胁。能变身超级赛亚人。"
                self.selectedCategory = .animeCharacter
                self.selectedEraIndex = 5 // 动漫世界
                self.achievements = "打败弗利萨,击败魔人布欧,掌握超级赛亚人形态"
                self.mainWorks = "龙珠,龙珠Z,龙珠超"
                self.keyThoughts = "我要超越超级赛亚人！,这还不是我的最终形态！"
            } else if characterSearchText.contains("孔子") {
                // 孔子
                self.name = "孔子"
                self.field = "思想家/教育家"
                self.region = "中国"
                self.birthYear = "前551"
                self.deathYear = "前479"
                self.introduction = "中国古代伟大的思想家、教育家，儒家学派创始人。其思想对中国和东亚文化圈影响深远。著有《论语》等经典著作。"
                self.selectedCategory = .philosopher
                self.selectedEraIndex = 2 // 古代
                self.achievements = "创立儒家思想,周游列国,私人讲学"
                self.mainWorks = "论语,诗经(编订),春秋(修订)"
                self.keyThoughts = "己所不欲，勿施于人,学而不思则罔，思而不学则殆,三人行，必有我师焉"
            } else {
                // 未能识别的角色，给出提示
                self.errorMessage = "无法识别该角色，请尝试提供更详细的描述或手动填写信息。"
                self.showingError = true
            }
            
            isGeneratingInfo = false
        }
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