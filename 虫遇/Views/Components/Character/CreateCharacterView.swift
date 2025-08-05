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
    
    private let eras = ["现代", "未来", "古代", "中世纪", "文艺复兴", "动漫世界", "科幻宇宙", "奇幻大陆"]
    
    private var isFormValid: Bool {
        !name.isEmpty && !introduction.isEmpty && !field.isEmpty
    }
    
    // 可选择的角色分类
    private let selectableCategories: [CharacterCategory] = [
        .fictionCharacter, .animeCharacter, .gameCharacter, 
        .movieCharacter, .tvCharacter, .mythCharacter, .vtuber
    ]
    
    var body: some View {
        Form {
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