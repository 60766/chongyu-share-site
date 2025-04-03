import SwiftUI

// 发布类型定义
struct PublishType: Identifiable {
    var id = UUID()
    var title: String
    var iconName: String
    var color: Color
    
    static let text = PublishType(title: "文字", iconName: "text.bubble.fill", color: .blue)
    static let image = PublishType(title: "图片", iconName: "photo.fill", color: .green)
    static let voice = PublishType(title: "语音", iconName: "mic.fill", color: .purple)
    static let story = PublishType(title: "故事", iconName: "book.fill", color: .orange)
}

/**
 * 发布页面视图
 * 用于用户发布与历史人物的对话内容
 */
struct PublishView: View {
    // 环境变量，用于关闭视图
    @Environment(\.dismiss) private var dismiss
    
    // 发布类型，从快捷菜单传递
    var publishType: PublishType?
    
    // 用户输入的文本
    @State private var postText: String = ""
    // 文本占位符
    private let textPlaceholder = "想..."
    // 是否显示文本占位符
    @State private var showPlaceholder = true
    // 选择的话题标签
    @State private var selectedTags: [String] = []
    // 可选话题标签
    private let availableTags = ["日常见闻", "思想碰撞", "美食探索", "旅途风景", "艺术鉴赏", "科技前沿"]
    // 是否已添加图片
    @State private var hasAddedImage = false
    // 推荐的历史人物
    @State private var recommendedCharacters: [PublishCharacterModel] = []
    // 选中的历史人物
    @State private var selectedCharacter: PublishCharacterModel? = nil
    // 当前活跃的输入字段
    @FocusState private var activeInput: InputField?
    
    // 输入字段枚举
    enum InputField {
        case postText
    }
    
    // 初始化方法
    init(publishType: PublishType? = nil) {
        self.publishType = publishType
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题和发送按钮
            HStack {
                Text("穿越时光")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // 发送帖子
                    publishPost()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                        Text("发送")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .disabled(postText.isEmpty && !hasAddedImage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    // 文本输入区域
                    ZStack(alignment: .topLeading) {
                        if showPlaceholder {
                            Text(textPlaceholder)
                                .font(.system(size: 17))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $postText)
                            .font(.system(size: 17))
                            .padding(0)
                            .frame(minHeight: 100)
                            .background(Color.clear)
                            .onChangeCompat(of: postText) { oldValue, newValue in
                                showPlaceholder = newValue.isEmpty
                            }
                    }
                    .padding(.horizontal, 16)
                    
                    // 添加图片区域
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .frame(height: 160)
                            .padding(.horizontal, 16)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.blue.opacity(0.6))
                            
                            Text("添加时空凭证")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("图片可以吸引更多时空旅者的目光")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            // 添加图片
                            hasAddedImage = true
                        }
                    }
                    
                    // 话题标签区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.blue)
                            
                            Text("添加话题")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        
                        // 话题标签
                        TagCollectionView(
                            tags: availableTags,
                            selectedTags: selectedTags,
                            onTagTap: { tag in
                                toggleTag(tag)
                            }
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // 推荐角色区域
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                            
                            Text("可能穿越时空的角色")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        
                        Text("根据话题，这些角色可能会穿越虫洞与你互动")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        // 角色推荐
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recommendedCharacters) { character in
                                    CharacterCircleButton(
                                        character: character,
                                        isSelected: selectedCharacter?.id == character.id,
                                        action: {
                                            selectedCharacter = character
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        if let selectedCharacter = selectedCharacter {
                            // 选中角色的详细信息
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: selectedCharacter.avatarUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedCharacter.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("\(selectedCharacter.field) · \(selectedCharacter.birthYear)-\(selectedCharacter.deathYear ?? "现在")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            loadRecommendedCharacters()
        }
    }
    
    /**
     * 切换标签选中状态
     */
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
        
        // 根据选择的标签更新推荐角色
        updateRecommendedCharacters()
    }
    
    /**
     * 根据标签更新推荐角色
     */
    private func updateRecommendedCharacters() {
        // 实际应用中可以根据标签进行智能推荐
        // 这里简化处理
    }
    
    /**
     * 加载推荐角色
     */
    private func loadRecommendedCharacters() {
        // 使用模型中定义的样本数据
        recommendedCharacters = PublishCharacterModel.samples
    }
    /**
     * 发布帖子
     */
    private func publishPost() {
        // 确保内容格式化处理
        let formattedContent = UserPostModel.formatContent(postText)
        
        // 此处应该实现实际的发布逻辑，如：
        // postViewModel.createNewPost(content: formattedContent, images: selectedImages)
        
        // TODO: 将格式化后的内容保存到数据模型
        print("发布帖子：\(formattedContent)")
        
        // 关闭发布视图
        dismiss()
    }
}

/**
 * 角色圆形按钮
 */
struct CharacterCircleButton: View {
    var character: PublishCharacterModel
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // 角色头像
                ZStack {
                    AsyncImage(url: URL(string: character.avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.primaryColor, lineWidth: 2)
                            .frame(width: 54, height: 54)
                    }
                }
                
                // 角色名称和领域
                VStack(spacing: 2) {
                    Text(character.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(character.field)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 90)
            .padding(.vertical, 8)
            .background(isSelected ? Color.primaryColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

/**
 * 发布页面预览
 */
struct PublishView_Previews: PreviewProvider {
    static var previews: some View {
        PublishView()
    }
}