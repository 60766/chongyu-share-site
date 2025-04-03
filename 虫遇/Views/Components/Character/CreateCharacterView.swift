import SwiftUI

/**
 * 创建自定义角色视图
 * 允许用户创建自己的虚拟角色
 */
struct CreateCharacterView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var characters: [CharacterModel]
    
    @State private var name: String = ""
    @State private var introduction: String = ""
    @State private var field: String = ""
    @State private var birthYear: String = ""
    @State private var deathYear: String = ""
    @State private var avatarSelected: Bool = false
    @State private var selectedEraIndex: Int = 0
    @State private var achievements: String = ""
    @State private var mainWorks: String = ""
    @State private var keyThoughts: String = ""
    
    private let eras = ["现代", "未来", "古代", "中世纪", "文艺复兴", "动漫世界", "科幻宇宙", "奇幻大陆"]
    
    private var isFormValid: Bool {
        !name.isEmpty && !introduction.isEmpty && !field.isEmpty
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("角色名称 *", text: $name)
                TextField("职业/身份 *", text: $field)
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
                    // 实现选择头像的逻辑
                    avatarSelected = true
                }) {
                    HStack {
                        Text(avatarSelected ? "已选择头像" : "选择角色头像")
                        Spacer()
                        if avatarSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "photo")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Section(header: Text("角色特点（每项用逗号分隔多个内容）")) {
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
                
                TextEditor(text: $keyThoughts)
                    .frame(height: 80)
                    .overlay(
                        VStack {
                            if keyThoughts.isEmpty {
                                HStack {
                                    Text("关键思想/特点")
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
                    createCharacter()
                }
                .disabled(!isFormValid)
                .fontWeight(.bold)
            }
        }
    }
    
    /**
     * 创建自定义角色
     */
    private func createCharacter() {
        // 处理成就、作品和思想为数组
        // 使用下划线避免未使用变量的警告
        let _ = achievements
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
            
        let _ = mainWorks
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
            
        let keyThoughtsArray = keyThoughts
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            .filter { !$0.isEmpty }
        
        // 创建角色类别
        let category: CharacterCategory
        if selectedEraIndex == 1 { // 未来
            category = .fictionCharacter
        } else if selectedEraIndex >= 5 { // 动漫世界、科幻宇宙、奇幻大陆
            category = .animeCharacter
        } else {
            category = .fictionCharacter
        }
        
        // 创建新角色
        let newCharacter = CharacterModel(
            name: name,
            avatar: "avatar_custom_\(UUID().uuidString.prefix(8))", // 使用占位图像
            era: selectedEraIndex == 1 ? "未来" : eras[selectedEraIndex],
            profession: field,
            bio: introduction,
            category: category,
            universe: selectedEraIndex >= 5 ? eras[selectedEraIndex] : nil,
            famousQuotes: keyThoughtsArray
        )
        
        // 添加到角色列表
        characters.append(newCharacter)
        
        // 关闭表单
        presentationMode.wrappedValue.dismiss()
        
        // TODO: 未来可以扩展CharacterModel以支持achievements和mainWorks
    }
} 