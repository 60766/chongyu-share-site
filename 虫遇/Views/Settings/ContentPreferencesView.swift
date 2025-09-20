import SwiftUI

/**
 * 内容偏好设置视图
 * 用于管理内容类型权重及其恢复
 */
struct ContentPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 主题颜色
    private let primaryColor = Color(hex: "9A8BB0") // 使用统一的主紫色
    private let secondaryColor = Color.orange
    
    // 内容类型权重管理器
    let contentTypeManager = ContentTypeManager.shared
    let weightManager = ContentTypeWeightManager.shared
    
    // 移除强制刷新的refreshID，使用SwiftUI的自然更新机制
    // @State private var refreshID = UUID() // 已移除
    
    // 内容类型列表
    @State private var contentTypes: [ContentGeneratorService.ContentType] = []
    
    // 显示重置所有确认对话框
    @State private var showingResetAllConfirmation = false
    
    // 恢复单个类型的确认对话框
    @State private var showingResetConfirmation = false
    @State private var typeToReset: ContentGeneratorService.ContentType?
    
    // 成功提示
    @State private var showSuccessToast = false
    @State private var successMessage = ""
    
    var body: some View {
        List {
            Section(header: Text("内容类型权重").font(.headline)) {
                Text("权重越低，相应类型内容出现的概率越小。你可以通过点击\"减少此类内容\"降低某种内容类型的权重，或在此恢复默认设置。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
                
                ForEach(contentTypes, id: \.rawValue) { type in
                    contentTypeRow(for: type)
                }
            }
            
            Section {
                Button(action: {
                    showingResetAllConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("恢复所有内容类型权重")
                            .foregroundColor(primaryColor)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle("内容偏好", displayMode: .inline)
        .navigationBarTitleTextColor(.primary)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                // 触觉反馈
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .medium))
                    Text("设置")
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundColor(primaryColor)
            }
        )
        .onAppear {
            loadContentTypes()
        }
        // .id(refreshID) // 已移除，使用SwiftUI的自然更新机制
        .alert(isPresented: $showingResetAllConfirmation) {
            Alert(
                title: Text("恢复所有内容类型"),
                message: Text("将所有内容类型的权重恢复为默认值。确定要继续吗？"),
                primaryButton: .default(Text("确定"), action: resetAllWeights),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .overlay(
            ZStack {
                if showSuccessToast {
                    VStack {
                        Spacer()
                        Text(successMessage)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                            .padding(.bottom, 50)
                    }
                }
            }
        )
    }
    
    // 加载内容类型
    private func loadContentTypes() {
        contentTypes = ContentGeneratorService.ContentType.allCases
    }
    
    // 获取内容类型的描述
    private func getTypeDescription(_ type: ContentGeneratorService.ContentType) -> String {
        switch type {
        case .resonance: return "探索不同历史人物之间的跨时代对话"
        case .mood: return "历史人物对当代生活的感悟和思考"
        case .ancient2modern: return "古代视角看现代事物的有趣解读"
        case .creativeIdea: return "穿越时空的有趣吐槽和创意想法"
        case .timelineEvent: return "历史事件的现代记录和反思"
        }
    }
    
    // 单个内容类型行
    private func contentTypeRow(for type: ContentGeneratorService.ContentType) -> some View {
        let weight = weightManager.getWeight(for: type)
        let isReduced = weight < 1.0
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(isReduced ? secondaryColor : .primary)
                    
                    Text(getTypeDescription(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isReduced {
                    Button(action: {
                        typeToReset = type
                        showingResetConfirmation = true
                    }) {
                        Text("恢复")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    .alert(isPresented: $showingResetConfirmation) {
                        let typeString = typeToReset?.rawValue ?? ""
                        return Alert(
                            title: Text("恢复权重"),
                            message: Text("将\"\(typeString)\"的权重恢复为默认值。确定要继续吗？"),
                            primaryButton: .default(Text("确定"), action: {
                                if let type = typeToReset {
                                    resetWeight(for: type)
                                }
                            }),
                            secondaryButton: .cancel(Text("取消"))
                        )
                    }
                }
            }
            
            // 权重指示器
            HStack(spacing: 0) {
                ForEach(0..<10) { i in
                    Rectangle()
                        .fill(Double(i) / 10.0 < weight ? primaryColor : Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                }
            }
            
            Text("当前权重: \(String(format: "%.2f", weight))")
                .font(.caption)
                .foregroundColor(isReduced ? secondaryColor : .secondary)
        }
        .padding(.vertical, 8)
    }
    
    // 恢复单个类型权重
    private func resetWeight(for type: ContentGeneratorService.ContentType) {
        weightManager.resetWeight(for: type)
        let typeName = type.rawValue
        successMessage = "已恢复\"\(typeName)\"的权重"
        showSuccessToast = true
        // refreshID = UUID() // 已移除，使用SwiftUI的自然更新机制
        
        // 3秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessToast = false
        }
    }
    
    // 恢复所有权重
    private func resetAllWeights() {
        weightManager.resetWeight()
        successMessage = "已恢复所有内容类型的权重"
        showSuccessToast = true
        // refreshID = UUID() // 已移除，使用SwiftUI的自然更新机制
        
        // 3秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessToast = false
        }
    }
} 