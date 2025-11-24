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
    
    // 内容类型颜色映射
    private func getTypeColor(for type: ContentGeneratorService.ContentType) -> Color {
        switch type {
        case .mood:
            return Color(hex: "3498DB") // 蓝色 - 日常心情
        case .ancient2modern:
            return Color(hex: "27AE60") // 绿色 - 古潮新语
        case .creativeIdea:
            return Color(hex: "E91E63") // 粉红色 - 穿越吐槽（区别于警告色）
        case .timelineEvent:
            return Color(hex: "8B7EC8") // 紫色 - 时空记事
        case .resonance:
            return primaryColor
        }
    }
    
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
    
    // 用于触发视图更新的ID
    @State private var refreshID = UUID()
    
    // 存储每个类型的临时权重值（用于滑块）
    @State private var tempWeights: [String: Double] = [:]
    
    var body: some View {
        List {
            // 说明和预期分配
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text("调整「一键生成」时各类型内容的分配比例")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    // 预期分配卡片
                    expectedDistributionCard
                }
                .padding(.vertical, 4)
            }
            
            // 各类型设置
            Section(header: Text("内容类型设置").font(.caption)) {
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
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(primaryColor)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(DesignSystem.Colors.background)
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
        .id(refreshID) // 用于在权重改变时刷新预期分配显示
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
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.green)
                            
                        Text(successMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSuccessToast)
        )
    }
    
    // 加载内容类型（排除虫洞共鸣，因为一键生成时不使用）
    private func loadContentTypes() {
        // 只显示一键生成时实际使用的4种类型
        contentTypes = [
            .mood,            // 日常心情
            .ancient2modern,  // 古潮新语
            .creativeIdea,    // 穿越吐槽
            .timelineEvent    // 时空记事
        ]
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
    
    // 预期分配卡片
    private var expectedDistributionCard: some View {
        let totalCount = 12
        let generatingTypes: [ContentGeneratorService.ContentType] = [
            .mood, .ancient2modern, .creativeIdea, .timelineEvent
        ]
        
        let distribution = weightManager.calculateTypeDistribution(
            totalCount: totalCount,
            types: generatingTypes
        )
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("预期分配")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("共12篇")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(generatingTypes, id: \.rawValue) { type in
                    let count = distribution[type] ?? 0
                    let weight = weightManager.getWeight(for: type)
                    let typeColor = getTypeColor(for: type)
                    
                    VStack(spacing: 6) {
                        Text("\(count)")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(typeColor)
                        
                        Text(type.rawValue)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(typeColor.opacity(weight < 1.0 ? 0.08 : 0.12))
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // 单个内容类型行（优化后的简洁样式）
    private func contentTypeRow(for type: ContentGeneratorService.ContentType) -> some View {
        let typeKey = type.rawValue
        let currentWeight = weightManager.getWeight(for: type)
        let localWeight = Binding(
            get: { tempWeights[typeKey] ?? currentWeight },
            set: { newValue in
                tempWeights[typeKey] = newValue
                weightManager.setWeight(newValue, for: type)
                refreshID = UUID()
            }
        )
        
        let percentage = localWeight.wrappedValue * 100
        let typeColor = getTypeColor(for: type)
        
        // 计算当前占比和调整后预计
        let generatingTypes: [ContentGeneratorService.ContentType] = [
            .mood, .ancient2modern, .creativeIdea, .timelineEvent
        ]
        let currentDistribution = weightManager.calculateTypeDistribution(
            totalCount: 12,
            types: generatingTypes
        )
        let currentCount = currentDistribution[type] ?? 0
        
        // 计算调整后的预计
        let adjustedDistribution = calculateAdjustedDistribution(for: type, newWeight: localWeight.wrappedValue)
        let adjustedCount = adjustedDistribution[type] ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            // 标题和描述
            VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    
                    Text(getTypeDescription(type))
                        .font(.caption)
                        .foregroundColor(.secondary)
            }
            
            // 滑块和占比信息
            VStack(spacing: 10) {
                // 滑块行
                HStack(spacing: 12) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(typeColor)
                        .frame(width: 45, alignment: .leading)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Slider(value: localWeight, in: 0...1, step: 0.05)
                        .tint(typeColor)
                }
                
                // 占比信息
                HStack {
                    Text("当前 \(currentCount)篇")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.4))
                
                Spacer()
                
                    Text("调整后 \(adjustedCount)篇")
                        .font(.caption)
                        .foregroundColor(adjustedCount != currentCount ? secondaryColor : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if tempWeights[typeKey] == nil {
                tempWeights[typeKey] = currentWeight
            }
        }
    }
    
    // 计算调整后的分配（不实际修改权重，仅用于预览）
    private func calculateAdjustedDistribution(for adjustedType: ContentGeneratorService.ContentType, newWeight: Double) -> [ContentGeneratorService.ContentType: Int] {
        let generatingTypes: [ContentGeneratorService.ContentType] = [
            .mood, .ancient2modern, .creativeIdea, .timelineEvent
        ]
        
        // 创建临时权重映射
        var tempWeights: [ContentGeneratorService.ContentType: Double] = [:]
        for type in generatingTypes {
            if type == adjustedType {
                tempWeights[type] = newWeight
            } else {
                tempWeights[type] = weightManager.getWeight(for: type)
                                }
        }
        
        // 过滤掉权重为0的类型
        let validTypes = generatingTypes.filter { (tempWeights[$0] ?? 0) > 0 }
        
        if validTypes.isEmpty {
            return [:]
            }
            
        // 计算总权重
        let totalWeight = validTypes.reduce(0.0) { $0 + (tempWeights[$1] ?? 0) }
        
        // 计算分配
        var distribution: [ContentGeneratorService.ContentType: Int] = [:]
        var allocatedCount = 0
        
        // 第一步：按权重比例分配
        var exactDistribution: [ContentGeneratorService.ContentType: Double] = [:]
        for type in validTypes {
            let weight = tempWeights[type] ?? 0
            let ratio = weight / totalWeight
            let exactCount = Double(12) * ratio
            exactDistribution[type] = exactCount
            let intCount = Int(exactCount)
            distribution[type] = intCount
            allocatedCount += intCount
        }
        
        // 第二步：分配剩余数量
        let remaining = 12 - allocatedCount
        if remaining > 0 {
            let sortedTypes = validTypes.sorted { (exactDistribution[$0] ?? 0) > (exactDistribution[$1] ?? 0) }
            for (index, type) in sortedTypes.enumerated() {
                if index < remaining {
                    distribution[type] = (distribution[type] ?? 0) + 1
                }
            }
        }
        
        // 确保所有类型都有条目
        for type in generatingTypes {
            if distribution[type] == nil {
                distribution[type] = 0
            }
        }
        
        return distribution
    }
    
    // 恢复单个类型权重
    private func resetWeight(for type: ContentGeneratorService.ContentType) {
        weightManager.resetWeight(for: type)
        let typeName = type.rawValue
        let typeKey = type.rawValue
        
        // 更新临时权重为默认值1.0
        tempWeights[typeKey] = 1.0
        
        successMessage = "已恢复\"\(typeName)\"的权重"
        showSuccessToast = true
        refreshID = UUID() // 刷新视图以更新预期分配
        
        // 3秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessToast = false
        }
    }
    
    // 恢复所有权重
    private func resetAllWeights() {
        weightManager.resetWeight()
        
        // 将所有临时权重重置为默认值1.0
        for type in contentTypes {
            tempWeights[type.rawValue] = 1.0
        }
        
        successMessage = "已恢复所有内容类型的权重"
        showSuccessToast = true
        refreshID = UUID() // 刷新视图以更新预期分配
        
        // 3秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessToast = false
        }
    }
} 