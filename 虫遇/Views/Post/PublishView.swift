import SwiftUI
import PhotosUI

/**
 * 发布类型定义
 */
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
    // 环境变量
    @Environment(\.dismiss) private var dismiss
    
    // 状态变量
    @State private var postText: String = ""
    @FocusState private var isFocused: Bool
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker: Bool = false
    @State private var isPublishing: Bool = false
    
    // 发布类型
    var publishType: PublishType?
    
    // 初始化方法
    init(publishType: PublishType? = nil) {
        self.publishType = publishType
    }
    
    // 常量
    private let placeholder = "与角色对话或分享你的洞见..."
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部导航栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("穿越时光")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: publishPost) {
                        if isPublishing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("发布")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(postText.isEmpty || isPublishing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 0)  // 完全移除垂直内边距，让标题紧贴顶部
                .padding(.top, getSafeAreaTop())
                .background(
                    // 背景 - 统一样式
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .edgesIgnoringSafeArea(.top)
                )
                
                // 主要内容区域
                ScrollView {
                    VStack(spacing: 16) {
                        // 文本输入区域
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分享你的想法")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // 使用GeometryReader获取屏幕尺寸
                            GeometryReader { geometry in
                                // 使用简化设置，确保文本与光标对齐
                                EnhancedTextDisplayView(
                                    text: $postText,
                                    placeholder: placeholder,
                                    minHeight: 100,
                                    maxHeight: 200,
                                    cornerRadius: 16,
                                    borderColor: .purple,
                                    backgroundColor: .white,
                                    showDebugInfo: false
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            // 固定高度
                            .frame(height: UIScreen.main.bounds.height * 0.2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // 图片选择区域
                        VStack(alignment: .leading, spacing: 8) {
                            Text("添加图片")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if selectedImages.isEmpty {
                                Button(action: { showingImagePicker = true }) {
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.blue)
                                        Text("点击添加图片")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<selectedImages.count, id: \.self) { index in
                                            Image(uiImage: selectedImages[index])
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    Button(action: {
                                                        selectedImages.remove(at: index)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.white)
                                                            .background(Color.black.opacity(0.5))
                                                            .clipShape(Circle())
                                                    }
                                                    .padding(4),
                                                    alignment: .topTrailing
                                                )
                                        }
                                        
                                        if selectedImages.count < 3 {
                                            Button(action: { showingImagePicker = true }) {
                                                VStack {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.blue)
                                                }
                                                .frame(width: 120, height: 120)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 1)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .keyboardAdaptive(dismissOnTap: true) // 添加键盘适配，让发布页面内容在键盘上方显示
            .sheet(isPresented: $showingImagePicker) {
                PHImagePicker(selectedImages: $selectedImages, completion: { _ in }, maxSelectionCount: 3)
            }
        }
    }
    
    // 发布帖子
    private func publishPost() {
        guard !postText.isEmpty else { return }
        
        isPublishing = true
        
        // 立即收起键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // 模拟发布过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isPublishing = false
            dismiss()
        }
    }
    
    // 获取顶部安全区域高度
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 0
    }
}

// 预览
struct PublishView_Previews: PreviewProvider {
    static var previews: some View {
        PublishView()
    }
}