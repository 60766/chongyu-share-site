// 加载当前生成数量设置
private func loadCurrentCount() {
    // 打印临时帖子信息，帮助调试
    print("📊 加载帖子数量设置：帖子ID=\(post.id), 内容类型=\(post.contentType ?? "nil"), 来源=\(post.source ?? "nil")")
    
    guard let contentTypeString = post.contentType else {
        print("⚠️ 错误：帖子contentType为nil，使用默认数量6")
        currentCount = 6
        return
    }
    
    print("🔄 尝试加载[\(contentTypeString)]的数量设置")
    
    // 打印所有可用的ContentType枚举值，帮助调试
    print("📚 可用的ContentType枚举值：")
    for type in ContentGeneratorService.ContentType.allCases {
        print("  - \(type.rawValue)")
    }
    
    // 检查CreationTypeManager中的类型
    print("📚 CreationTypeManager中的类型：")
    for type in CreationTypeManager.shared.types {
        print("  - \(type)")
    }
    
    // 直接映射处理特殊类型
    let mappedType: ContentGeneratorService.ContentType
    
    // 根据内容类型字符串映射到对应的ContentType枚举
    switch contentTypeString {
    case "虫洞共鸣":
        mappedType = .resonance
        print("✅ 映射：虫洞共鸣 -> resonance")
    case "日常心情":
        mappedType = .mood
        print("✅ 映射：日常心情 -> mood")
    case "古潮新语":
        mappedType = .ancient2modern
        print("✅ 映射：古潮新语 -> ancient2modern")
    case "穿越吐槽":
        mappedType = .creativeIdea
        print("✅ 映射：穿越吐槽 -> creativeIdea")
    case "时空记事":
        mappedType = .timelineEvent
        print("✅ 映射：时空记事 -> timelineEvent")
    default:
        // 尝试直接转换
        if let type = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            mappedType = type
            print("✅ 直接转换成功：\(contentTypeString)")
        } else {
            print("⚠️ 错误：无法映射或转换[\(contentTypeString)]，使用默认数量6")
            currentCount = 6
            return
        }
    }
    
    // 从ExplorationCountManager获取当前设置的生成数量
    currentCount = ExplorationCountManager.shared.getCount(for: mappedType)
    print("✅ 成功加载[\(contentTypeString)]的数量设置：\(currentCount)")
}

// 增加生成数量
private func increaseCount() {
    guard let contentTypeString = post.contentType else {
        print("⚠️ 错误：增加数量失败，帖子contentType为nil")
        return
    }
    
    print("🔄 尝试增加[\(contentTypeString)]的数量")
    
    // 直接映射处理特殊类型
    let mappedType: ContentGeneratorService.ContentType
    
    // 根据内容类型字符串映射到对应的ContentType枚举
    switch contentTypeString {
    case "虫洞共鸣":
        mappedType = .resonance
        print("✅ 映射：虫洞共鸣 -> resonance")
    case "日常心情":
        mappedType = .mood
        print("✅ 映射：日常心情 -> mood")
    case "古潮新语":
        mappedType = .ancient2modern
        print("✅ 映射：古潮新语 -> ancient2modern")
    case "穿越吐槽":
        mappedType = .creativeIdea
        print("✅ 映射：穿越吐槽 -> creativeIdea")
    case "时空记事":
        mappedType = .timelineEvent
        print("✅ 映射：时空记事 -> timelineEvent")
    default:
        // 尝试直接转换
        if let type = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            mappedType = type
            print("✅ 直接转换成功：\(contentTypeString)")
        } else {
            print("⚠️ 错误：无法映射或转换[\(contentTypeString)]，无法增加数量")
            return
        }
    }
    
    // 触发触觉反馈
    HapticFeedbackManager.shared.lightImpact()
    
    // 增加数量并更新UI
    currentCount = ExplorationCountManager.shared.increaseCount(for: mappedType)
    print("✅ 成功增加[\(contentTypeString)]的数量为：\(currentCount)")
    
    // 显示提示
    ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「\(contentTypeString)」")
}

// 减少生成数量
private func decreaseCount() {
    guard let contentTypeString = post.contentType else {
        print("⚠️ 错误：减少数量失败，帖子contentType为nil")
        return
    }
    
    print("🔄 尝试减少[\(contentTypeString)]的数量")
    
    // 直接映射处理特殊类型
    let mappedType: ContentGeneratorService.ContentType
    
    // 根据内容类型字符串映射到对应的ContentType枚举
    switch contentTypeString {
    case "虫洞共鸣":
        mappedType = .resonance
        print("✅ 映射：虫洞共鸣 -> resonance")
    case "日常心情":
        mappedType = .mood
        print("✅ 映射：日常心情 -> mood")
    case "古潮新语":
        mappedType = .ancient2modern
        print("✅ 映射：古潮新语 -> ancient2modern")
    case "穿越吐槽":
        mappedType = .creativeIdea
        print("✅ 映射：穿越吐槽 -> creativeIdea")
    case "时空记事":
        mappedType = .timelineEvent
        print("✅ 映射：时空记事 -> timelineEvent")
    default:
        // 尝试直接转换
        if let type = ContentGeneratorService.ContentType(rawValue: contentTypeString) {
            mappedType = type
            print("✅ 直接转换成功：\(contentTypeString)")
        } else {
            print("⚠️ 错误：无法映射或转换[\(contentTypeString)]，无法减少数量")
            return
        }
    }
    
    // 触发触觉反馈
    HapticFeedbackManager.shared.lightImpact()
    
    // 减少数量并更新UI
    currentCount = ExplorationCountManager.shared.decreaseCount(for: mappedType)
    print("✅ 成功减少[\(contentTypeString)]的数量为：\(currentCount)")
    
    // 显示提示
    ToastManager.shared.showToast(message: "已设置生成\(currentCount)篇「\(contentTypeString)」")
} 