import SwiftUI

/**
 * 增强型搜索栏组件
 * 提供更多的自定义选项和改进的视觉效果
 */
struct SearchBar: View {
    /// 搜索文本
    @Binding var searchText: String
    /// 占位文本
    var placeholder: String
    /// 搜索动作
    var onSearch: () -> Void
    
    // 新增参数，用于跟踪搜索栏是否处于焦点状态
    @State private var isFocused: Bool = false
    
    // 新增参数，控制是否显示搜索提示和过滤选项
    @State private var showSearchOptions: Bool = false
    
    // 新增参数，处理键盘显示状态
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 主搜索栏
            HStack(spacing: 12) {
                // 搜索图标
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(isFocused ? .blue : .gray)
                
                // 搜索输入框
                TextField(placeholder, text: $searchText)
                    .font(.system(size: 16))
                    .disableAutocorrection(true)
                    .focused($isTextFieldFocused)
                    .onChange(of: isTextFieldFocused) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isFocused = newValue
                            showSearchOptions = newValue && !searchText.isEmpty
                        }
                    }
                    .onChange(of: searchText) { _, newValue in
                        // 当文本变化并且不为空时显示搜索选项
                        showSearchOptions = isTextFieldFocused && !newValue.isEmpty
                    }
                    .submitLabel(.search)
                    .onSubmit {
                        // 处理搜索提交事件
                        performSearch()
                    }
                
                // 清除按钮（仅当有文本输入时显示）
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        // 重置搜索选项显示状态
                        showSearchOptions = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                
                // 搜索按钮
                Button(action: performSearch) {
                    Text("搜索")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
            
            // 搜索提示和过滤选项区域（仅当搜索栏获得焦点且有文本输入时显示）
            if showSearchOptions {
                searchOptionsView
            }
        }
    }
    
    // 执行搜索方法
    private func performSearch() {
        // 隐藏键盘
        isTextFieldFocused = false
        // 隐藏搜索选项
        showSearchOptions = false
        // 执行搜索回调
        onSearch()
    }
    
    // 搜索选项和提示视图
    private var searchOptionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标签筛选区域
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["历史人物", "动漫角色", "科学家", "政治家", "艺术家", "动物视角"], id: \.self) { category in
                        Text(category)
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            
            Divider()
            
            // 搜索建议列表
            VStack(alignment: .leading, spacing: 14) {
                Text("热门搜索")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                
                ForEach(getSuggestedSearches(), id: \.self) { suggestion in
                    Button(action: {
                        searchText = suggestion
                        performSearch()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text(suggestion)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.bottom, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        )
        .offset(y: 5)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // 基于当前搜索文本获取建议搜索内容
    private func getSuggestedSearches() -> [String] {
        if searchText.isEmpty {
            return ["爱因斯坦", "孙悟空", "拿破仑", "达芬奇", "你认为如何看待战争"]
        }
        
        // 这里可以实现基于searchText的实时建议搜索
        // 例如过滤包含searchText的热门搜索
        let allSuggestions = [
            "爱因斯坦", "爱迪生", "爱丽丝",
            "莎士比亚", "孙悟空", "司马迁",
            "拿破仑", "牛顿", "尼采",
            "达芬奇", "迪伦·托马斯", "德川家康",
            "你认为如何看待战争", "你如何评价现代教育", "你是如何创作的"
        ]
        
        return allSuggestions.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
}

/**
 * 预览
 */
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // 空搜索状态
            SearchBar(
                searchText: .constant(""),
                placeholder: "搜索历史人物或话题...",
                onSearch: {}
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 有输入状态
            SearchBar(
                searchText: .constant("爱"),
                placeholder: "搜索历史人物或话题...",
                onSearch: {}
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
} 