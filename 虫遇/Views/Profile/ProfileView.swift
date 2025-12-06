import SwiftUI
import SwiftData
import UIKit
import Combine
import PhotosUI

// 通知名称扩展
extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
}

// 用户资料管理服务
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var username: String = "次元指挥官"
    @Published var personalSignature: String = "探索无限次元，寻找智慧宝藏 ✨"
    @Published var avatarImage: UIImage?
    @Published var avatarImageName: String = "default_avatar"
    
    // 等级系统相关属性
    @Published var userLevel: Int = 1
    @Published var userExperience: Int = 0
    @Published var levelTitle: String = "时空新手"
    @Published var lastLevelUpdateTime: Date = Date()
    @Published var showLevelUpNotification: Bool = false
    @Published var levelUpMessage: String = ""

    private let userDefaults = UserDefaults.standard
    private let usernameKey = "user_profile_username"
    private let personalSignatureKey = "user_profile_personal_signature"
    private let avatarImageNameKey = "user_profile_avatar_name"
    
    // 等级系统缓存键
    private let levelKey = "user_profile_level"
    private let experienceKey = "user_profile_experience"
    private let levelTitleKey = "user_profile_level_title"
    private let lastLevelUpdateKey = "user_profile_last_level_update"
    
    // 等级计算缓存
    private let levelCacheKey = "user_level_calculation_cache"
    private let levelCacheExpiration: TimeInterval = 300 // 5分钟缓存

    init() {
        loadUserProfile()
        loadLevelData()
    }
    
    func loadUserProfile() {
        username = userDefaults.string(forKey: usernameKey) ?? "次元指挥官"
        personalSignature = userDefaults.string(forKey: personalSignatureKey) ?? "探索无限次元，寻找智慧宝藏 ✨"
        avatarImageName = userDefaults.string(forKey: avatarImageNameKey) ?? "default_avatar"
    }
    
    func loadLevelData() {
        userLevel = userDefaults.integer(forKey: levelKey)
        if userLevel == 0 { userLevel = 1 } // 默认等级1
        
        userExperience = userDefaults.integer(forKey: experienceKey)
        levelTitle = userDefaults.string(forKey: levelTitleKey) ?? getLevelTitle(level: userLevel)
        lastLevelUpdateTime = userDefaults.object(forKey: lastLevelUpdateKey) as? Date ?? Date()
    }
    
    func updateUsername(_ newUsername: String) {
        username = newUsername
        userDefaults.set(newUsername, forKey: usernameKey)
        // 发送通知，通知其他组件用户信息已更新
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    func updatePersonalSignature(_ newSignature: String) {
        personalSignature = newSignature
        userDefaults.set(newSignature, forKey: personalSignatureKey)
    }
    
    func updateAvatar(_ image: UIImage, name: String) {
        avatarImage = image
        avatarImageName = name
        userDefaults.set(name, forKey: avatarImageNameKey)
        
        // 保存图片到本地
        saveImageToDocuments(image, name: name)
        // 发送通知，通知其他组件用户信息已更新
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    // MARK: - 等级系统核心方法
    
    /// 异步计算并更新用户等级（带缓存）
    func updateUserLevelAsync() {
        // 检查缓存是否有效
        if isLevelCacheValid() {
            return
        }
        
        // 在后台线程计算等级
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            let newLevelData = self.calculateUserLevelData()
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.updateLevelData(newLevelData)
                self.saveLevelCache(newLevelData)
            }
        }
    }
    
    /// 强制重新计算等级（清除缓存）
    func forceUpdateUserLevel() {
        clearLevelCache()
        updateUserLevelAsync()
    }
    
    /// 检查等级缓存是否有效
    private func isLevelCacheValid() -> Bool {
        guard let cacheData = userDefaults.object(forKey: levelCacheKey) as? [String: Any],
              let timestamp = cacheData["timestamp"] as? Date else {
            return false
        }
        
        return Date().timeIntervalSince(timestamp) < levelCacheExpiration
    }
    
    /// 保存等级缓存
    private func saveLevelCache(_ levelData: (level: Int, experience: Int, title: String)) {
        let cacheData: [String: Any] = [
            "level": levelData.level,
            "experience": levelData.experience,
            "title": levelData.title,
            "timestamp": Date()
        ]
        userDefaults.set(cacheData, forKey: levelCacheKey)
    }
    
    /// 清除等级缓存
    private func clearLevelCache() {
        userDefaults.removeObject(forKey: levelCacheKey)
    }
    
    /// 计算用户等级数据
    private func calculateUserLevelData() -> (level: Int, experience: Int, title: String) {
        // 获取统计数据（这里需要访问其他服务，暂时使用模拟数据）
        let stats = getCurrentUserStats()
        
        // 计算总经验值
        let totalExperience = calculateTotalExperience(stats: stats)
        
        // 计算等级
        let level = calculateLevelFromExperience(totalExperience)
        
        // 获取等级称号
        let title = getLevelTitle(level: level)
        
        return (level, totalExperience, title)
    }
    
    /// 获取当前用户统计数据
    private func getCurrentUserStats() -> [String: Int] {
        // 从DataCacheService获取缓存的统计数据
        if let stats: [String: Int] = DataCacheService.shared.retrieve(key: "profile.stats") {
            return stats
        }
        
        // 如果缓存不存在，返回默认值
        return [
            "dialogueCount": 0,
            "resonanceCount": 0,
            "cognitionCount": 0,
            "deepDialogueCount": 0,
            "myLikesCount": 0,
            "travelCount": 0
        ]
    }
    
    /// 更新统计数据到缓存（供外部调用）
    func updateStatsCache(_ stats: [String: Int]) {
        DataCacheService.shared.store(key: "profile.stats", value: stats, type: "profile_stats", expirationTime: 300)
    }
    
    /// 计算总经验值
    private func calculateTotalExperience(stats: [String: Int]) -> Int {
        let dialogueScore = stats["dialogueCount", default: 0] * 1
        let resonanceScore = stats["resonanceCount", default: 0] * 2
        let cognitionScore = stats["cognitionCount", default: 0] * 3
        let deepDialogueScore = stats["deepDialogueCount", default: 0] * 2
        let likeScore = stats["myLikesCount", default: 0] * 1
        let travelScore = stats["travelCount", default: 0] * 5

        
        return dialogueScore + resonanceScore + cognitionScore + 
               deepDialogueScore + likeScore + travelScore
    }
    
    /// 根据经验值计算等级
    private func calculateLevelFromExperience(_ experience: Int) -> Int {
        switch experience {
        case 0..<50: return 1
        case 50..<150: return 2
        case 150..<300: return 3
        case 300..<500: return 4
        case 500..<800: return 5
        case 800..<1200: return 6
        case 1200..<1800: return 7
        case 1800..<2500: return 8
        case 2500..<3500: return 9
        default: return 10
        }
    }
    
    /// 更新等级数据
    private func updateLevelData(_ levelData: (level: Int, experience: Int, title: String)) {
        let oldLevel = userLevel
        userLevel = levelData.level
        userExperience = levelData.experience
        levelTitle = levelData.title
        lastLevelUpdateTime = Date()
        
        // 保存到UserDefaults
        userDefaults.set(userLevel, forKey: levelKey)
        userDefaults.set(userExperience, forKey: experienceKey)
        userDefaults.set(levelTitle, forKey: levelTitleKey)
        userDefaults.set(lastLevelUpdateTime, forKey: lastLevelUpdateKey)
        
        // 检查是否升级
        if userLevel > oldLevel {
            #if DEBUG
            print("🎉 恭喜升级！从 Lv.\(oldLevel) 升级到 Lv.\(userLevel)")
            #endif
            
            // 显示升级通知
            levelUpMessage = "恭喜升级！从 \(getLevelTitle(level: oldLevel)) 升级到 \(levelTitle)"
            showLevelUpNotification = true
            
            // 3秒后自动隐藏通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showLevelUpNotification = false
            }
        }
    }
    
    /// 获取等级称号
    private func getLevelTitle(level: Int) -> String {
        switch level {
        case 1: return "时空新手"
        case 2: return "虫洞探险家"
        case 3: return "次元旅行者"
        case 4: return "时空冒险家"
        case 5: return "虫洞漫游者"
        case 6: return "次元守护者"
        case 7: return "时空大师"
        case 8: return "虫洞领主"
        case 9: return "次元王者"
        case 10: return "时空传奇"
        default: return "时空新手"
        }
    }
    
    /// 获取当前等级的经验值范围
    func getCurrentLevelExperienceRange() -> (current: Int, next: Int) {
        let levelRanges = [
            1: (0, 50), 2: (50, 150), 3: (150, 300), 4: (300, 500),
            5: (500, 800), 6: (800, 1200), 7: (1200, 1800),
            8: (1800, 2500), 9: (2500, 3500), 10: (3500, Int.max)
        ]
        
        let range = levelRanges[userLevel] ?? (0, 50)
        return (range.0, range.1)
    }
    
    /// 获取升级进度百分比
    func getLevelUpProgress() -> Double {
        let range = getCurrentLevelExperienceRange()
        let progress = Double(userExperience - range.current) / Double(range.next - range.current)
        return min(max(progress, 0), 1)
    }
    
    /// 调试方法：打印当前等级和经验值信息
    func debugLevelInfo() {
        let stats = getCurrentUserStats()
        let totalExp = calculateTotalExperience(stats: stats)
        let range = getCurrentLevelExperienceRange()
        let currentLevelExp = userExperience - range.current
        let maxLevelExp = range.next - range.current
        
        #if DEBUG
        print("🔍 UserProfileManager调试信息:")
        #endif
        #if DEBUG
        print("  - 当前等级: \(userLevel)")
        #endif
        #if DEBUG
        print("  - 总经验值: \(userExperience)")
        #endif
        #if DEBUG
        print("  - 计算得到的总经验值: \(totalExp)")
        #endif
        #if DEBUG
        print("  - 等级范围: \(range.current) - \(range.next)")
        #endif
        #if DEBUG
        print("  - 当前等级内经验值: \(currentLevelExp)/\(maxLevelExp)")
        #endif
        #if DEBUG
        print("  - 升级进度: \(getLevelUpProgress()) (\(Int(getLevelUpProgress() * 100))%)")
        #endif
        #if DEBUG
        print("  - 统计数据: \(stats)")
        #endif
    }
    
    /// 获取等级颜色
    func getLevelColor() -> Color {
        switch userLevel {
        case 1...2: return .blue
        case 3...4: return .green
        case 5...6: return .orange
        case 7...8: return .purple
        case 9...10: return .red
        default: return .blue
        }
    }
    
    /// 获取等级图标
    func getLevelIcon() -> String {
        switch userLevel {
        case 1: return "sparkles"
        case 2: return "location.circle"
        case 3: return "airplane"
        case 4: return "map"
        case 5: return "globe"
        case 6: return "shield"
        case 7: return "crown"
        case 8: return "building.columns"
        case 9: return "crown.fill"
        case 10: return "star.circle.fill"
        default: return "sparkles"
        }
    }

    private func saveImageToDocuments(_ image: UIImage, name: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            Logger.error("无法获取文档目录", log: Logger.data)
            #endif
            return
        }
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        
        do {
            try data.write(to: fileURL)
        } catch {
            #if DEBUG
            print("保存头像失败: \(error)")
            #endif
        }
    }
    
    private func loadImageFromDocuments(name: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            Logger.error("无法获取文档目录", log: Logger.data)
            #endif
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent("\(name).jpg")
        
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    func loadAvatarImage() -> UIImage? {
        if let image = avatarImage {
            return image
        }
        
        // 从本地文件加载
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            #if DEBUG
            Logger.error("无法获取文档目录", log: Logger.data)
            #endif
            return nil
        }
        let fileURL = documentsDirectory.appendingPathComponent("\(avatarImageName).jpg")
        
        if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
            // 使用DispatchQueue.main.async避免在视图更新期间发布更改
            DispatchQueue.main.async {
                self.avatarImage = image
            }
            return image
        }
        
        return UIImage(named: avatarImageName)
    }
    
    // MARK: - 公开的用户信息获取方法
    
    /// 获取当前用户名
    func getCurrentUsername() -> String {
        return username
    }
    
    /// 获取当前用户头像名称
    func getCurrentAvatarName() -> String {
        return avatarImageName
    }
    
    /// 获取当前用户头像图片
    func getCurrentAvatarImage() -> UIImage? {
        if let avatarImage = avatarImage {
            return avatarImage
        }
        
        // 尝试从文档目录加载
        if let image = loadImageFromDocuments(name: avatarImageName) {
            // 使用DispatchQueue.main.async避免在视图更新期间发布更改
            DispatchQueue.main.async {
                self.avatarImage = image
            }
            return image
        }
        
        // 尝试从Bundle加载
        if let bundleImage = UIImage(named: avatarImageName) {
            return bundleImage
        }
        
        return nil
    }
    
    /// 获取用户头像URL字符串（优先返回自定义头像路径，否则返回默认头像名称）
    func getCurrentAvatarURL() -> String {
        // 如果有自定义头像，返回文档路径
        if avatarImageName != "default_avatar", getCurrentAvatarImage() != nil {
            return avatarImageName
        }
        
        // 否则返回默认的系统图标
        return "person.crop.circle.fill"
    }
}

// 添加一个新的UIKit桥接组件来处理点击事件
struct TouchableView: UIViewRepresentable {
    var action: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func handleTap() {
            #if DEBUG
            print("UIKit按钮被点击")
            #endif
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            action()
        }
    }
}

// 扩展成就数据模型
struct ExtendedAchievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let isUnlocked: Bool
}

/**
 * 个人空间页
 * 展示用户个人信息、时空旅行记录和历史人物关系
 */
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    
    /// 当前选中的标签索引
    @State private var selectedTabIndex = 0
    /// 标签选项
    private let tabOptions = ["次元回放", "我的动态", "我的点赞"]
    /// 是否显示成就详情
    @State private var showAchievements = false
    /// 是否显示等级详情
    @State private var showLevelDetails = false
    /// 用于标签指示器动画的命名空间
    @Namespace private var namespace
    
    // 添加调试菜单状态
    @State private var isDebugMenuPresented = false
    @State private var debugTapCount = 0
    @State private var lastTapTime: Date? = nil
    
    // 设置页面显示状态
    @State private var showingSettings = false
    // 用户名点击计数
    @State private var usernameTapCount = 0

    
    // 添加PostViewModel依赖来获取用户帖子数据
    @ObservedObject private var postViewModel = PostViewModel.shared
    
    // 添加NotificationService依赖来获取点赞数据
    @ObservedObject private var notificationService = NotificationService.shared
    
    // 添加缓存服务依赖
    @ObservedObject private var cacheService = DataCacheService.shared
    
    // 添加用户点赞服务依赖
    @ObservedObject private var likeService = UserLikeService.shared
    
    // 添加用户资料管理服务依赖
    @ObservedObject private var userProfileManager = UserProfileManager.shared
    
    // 添加钱包管理服务依赖
    @ObservedObject private var walletManager = WalletManager.shared

    // 显示完整点赞视图的状态
    @State private var showAllLikes = false
    
    // 显示完整动态视图的状态
    @State private var showAllPosts = false
    
    // 用户资料编辑相关状态
    @State private var showingProfileEditor = false
    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    
    // 直接编辑状态
    @State private var isEditingUsername = false
    @State private var isEditingSignature = false
    @State private var tempUsername = ""
    @State private var tempSignature = ""
    @FocusState private var isUsernameFieldFocused: Bool
    @FocusState private var isSignatureFieldFocused: Bool
    
    // 自动折叠定时器
    @State private var autoCollapseTimer: Timer?
    
    // 添加取消令牌集合
    @State private var cancellables = Set<AnyCancellable>()
    
    // 缓存键前缀
    private let cacheKeyPrefix = "profile."
    
    // MARK: - 性能优化：缓存所有计算结果
    @State private var cachedDialogueCount: Int = 0
    @State private var cachedResonanceCount: Int = 0
    @State private var cachedCognitionCount: Int = 0
    @State private var cachedTravelCount: Int = 0
    @State private var cachedMyLikesCount: Int = 0

    @State private var cachedDeepDialogueCount: Int = 0
    @State private var lastCacheUpdate: Date = Date.distantPast
    @State private var isCalculating: Bool = false
    
    // 缓存有效期：5分钟
    private let cacheValidDuration: TimeInterval = 300
    
    /// 初始化缓存为默认值，提供即时反馈
    private func initializeCache() {
        // 如果是第一次打开，使用默认值
        if lastCacheUpdate == Date.distantPast {
            // 使用Task来避免在视图更新过程中修改状态
            Task { @MainActor in
                cachedDialogueCount = 0
                cachedResonanceCount = 0
                cachedCognitionCount = 0
                cachedTravelCount = 0
                cachedMyLikesCount = 0

                cachedDeepDialogueCount = 0
                #if DEBUG
                print("🎯 ProfileView: 初始化默认缓存值")
                #endif
            }
        }
    }
    
    // 模拟用户成就数据
    private let userAchievements = [
        Achievement(id: "1", name: "时空旅行者", icon: "clock.arrow.2.circlepath", description: "完成10次历史对话"),
        Achievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位不同时代的历史人物交流"),
        Achievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇进行3次深度交流")
    ]
    
    // 模拟数据 - 角色关系
    private var characterRelations: [SimpleCharacterRelation] {
        [] // 目前为空，未来可以添加实际数据
    }
    
    var body: some View {
    
        
        return mainContent
            .onAppear {
                // 运行图片诊断（调试用）
                ImageDebugHelper.shared.runFullDiagnostics()
                
                // 第一步：立即初始化默认值，确保界面能立即显示
                initializeCache()
                
                // 第二步：延迟加载真实数据，避免阻塞UI
                Task {
                    // 延迟500ms再开始计算，让界面先完全显示
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    
                    // 只有在缓存无效时才重新计算
                    if !isCacheValid {
                        await updateCacheAsync()
                    }
                    
                    // 设置数据更新监听（在主线程）
                    await MainActor.run {
                        setupDataUpdateListeners()
                        resetExpandedStates()
                        // 显式重新加载点赞数据，确保数据同步
                        likeService.reloadLikes()
                    }
                    
                    // 异步更新用户等级（不阻塞界面显示）
                        userProfileManager.updateUserLevelAsync()
                    }
                
                #if DEBUG
                print("🚀 ProfileView: 页面加载完成，缓存状态: \(isCacheValid ? "有效" : "需要更新")")
                
                // 🔍 调试：打印当前等级和经验值信息
                userProfileManager.debugLevelInfo()
                #endif
            }
            .onDisappear {
                // 性能优化：清理资源，避免内存泄漏
                // 已移除调试日志
                
                // 停止正在进行的计算任务
                isCalculating = false
                
                // 清理订阅
                cancellables.forEach { $0.cancel() }
                cancellables.removeAll()
                
                // 页面消失时重置展开状态
                resetExpandedStates()
                
                // 清理定时器
                autoCollapseTimer?.invalidate()
                autoCollapseTimer = nil
                
                #if DEBUG
                print("✅ ProfileView: 资源清理完成")
                #endif
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { _, newItem in
                Task {
                    #if DEBUG
                    print("📱 ProfileView: 图片选择器触发，开始加载图片")
                    #endif
                    if let newItem = newItem {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                #if DEBUG
                                print("📱 ProfileView: 图片加载成功，尺寸: \(image.size)")
                                #endif
                                #if DEBUG
                                print("📱 ProfileView: 图片CGImage存在: \(image.cgImage != nil)")
                                #endif
                                
                                // 确保图片有效
                                guard image.size.width > 0 && image.size.height > 0 && image.cgImage != nil else {
                                    #if DEBUG
                                    print("❌ ProfileView: 图片无效，尺寸为0或没有CGImage")
                                    #endif
                                    return
                                }
                                
                                await MainActor.run {
                                    selectedUIImage = image
                                    #if DEBUG
                                    print("📱 ProfileView: 已设置 selectedUIImage，尺寸: \(image.size)")
                                    #endif
                                    #if DEBUG
                                    print("📱 ProfileView: selectedUIImage 已设置，sheet 将自动显示")
                                    #endif
                                }
                            } else {
                                #if DEBUG
                                print("❌ ProfileView: 无法创建 UIImage")
                                #endif
                            }
                        } catch {
                            #if DEBUG
                            print("❌ ProfileView: 图片加载失败: \(error)")
                            #endif
                        }
                    } else {
                        #if DEBUG
                        print("❌ ProfileView: 没有选择图片")
                        #endif
                    }
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                ProfileEditorView(userProfileManager: userProfileManager)
            }
            .sheet(item: Binding<IdentifiableUIImage?>(
                get: { 
                    if let selectedUIImage = selectedUIImage {
                        return IdentifiableUIImage(image: selectedUIImage)
                    }
                    return nil
                },
                set: { _ in 
                    selectedUIImage = nil 
                }
            )) { identifiableImage in
                AvatarEditorView(
                    image: identifiableImage.image,
                    onSave: { croppedImage in
                        userProfileManager.updateAvatar(croppedImage, name: "user_avatar_\(Date().timeIntervalSince1970)")
                        selectedUIImage = nil // 这会自动关闭sheet
                    },
                    onCancel: {
                        selectedUIImage = nil // 这会自动关闭sheet
                    }
                )
                .onAppear {
                    #if DEBUG
                    print("📱 Sheet: 显示头像编辑器，图片尺寸: \(identifiableImage.image.size)")
                    #endif
                }
            }
    }
    
    // 将主要内容分离为单独的视图以避免编译器超时
    private var mainContent: some View {
        ZStack {
            // 主内容
            GeometryReader { geometry in
                contentScrollView(geometry: geometry)
            }
            
            // 升级通知
            if userProfileManager.showLevelUpNotification {
            VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text(userProfileManager.levelUpMessage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                    Spacer()
                }
                .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: userProfileManager.showLevelUpNotification)
            }
        }
        .onAppear {

        }
    }
    
    // 内容滚动视图
    private func contentScrollView(geometry: GeometryProxy) -> some View {
            ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // 极简导航栏 - 无标题
                HStack {
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                    
                // 个人信息卡片 - 恢复原来的梦幻设计
                profileInfoCard
                
                // 时空足迹总览卡片 - 新增功能聚合
                timeTravelOverviewCard
                
                // 成就展示网格
                achievementsGrid
                
                // 统一的Tab内容容器
                unifiedTabContentContainer
                
                // 底部间距，确保不被TabBar遮挡
                    Color.clear
                    .frame(height: 100)
                }
            .padding(.bottom, 20)
        }
        .background(
            // 背景层 - 与探索界面一致的温暖米白色背景
            DesignSystem.Colors.background
                .ignoresSafeArea(.all)
        )
    }
    
    // 统一的Tab内容容器 - 将Tab切换器与内容整合
    private var unifiedTabContentContainer: some View {
        VStack(spacing: 0) {
            // Apple风格的分段控制器
            appleStyleSegmentedControl
                .background(
                    // 只给标签栏添加背景
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 16
                    )
                    .fill(.regularMaterial)
                )
            
            // 内容区域
            tabContentArea
                .background(
                    // 根据选中的tab显示不同的背景
                    Group {
                        if selectedTabIndex == 0 {
                            // 次元回放tab - 带圆角的彩色渐变背景
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 0
                            )
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        DesignSystem.Colors.background.opacity(0.3),           // 顶部：几乎透明的背景色
                                        Color.blue.opacity(0.05),           // 渐变到淡蓝色
                                        Color.purple.opacity(0.08),         // 渐变到淡紫色
                                        Color.pink.opacity(0.12),           // 渐变到粉色
                                        Color.orange.opacity(0.15)          // 底部：较纯的橙色
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        } else {
                            // 其他tab - 保持毛玻璃效果
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 16,
                                bottomTrailingRadius: 16,
                                topTrailingRadius: 0
                            )
                            .fill(.regularMaterial)
                        }
                    }
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
    }
    
    // 扁平化标签切换器
    private var appleStyleSegmentedControl: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
            ForEach(0..<tabOptions.count, id: \.self) { index in
                Button(action: {
                        // 触觉反馈
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    
                        // 流畅的切换动画
                        withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTabIndex = index
                    }
                }) {
                        VStack(spacing: 6) {
                            // 图标
                            Image(systemName: tabIconName(for: index))
                                .font(.system(size: 18, weight: selectedTabIndex == index ? .semibold : .medium))
                                .foregroundColor(selectedTabIndex == index ? tabColor(for: index) : Color.secondary.opacity(0.6))
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.bounce, value: selectedTabIndex == index)
                            
                            // 文字
                        Text(tabOptions[index])
                                .font(.system(size: 13, weight: selectedTabIndex == index ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedTabIndex == index ? tabColor(for: index) : Color.secondary.opacity(0.7))
                        }
                    .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    .background(
                            ZStack {
                            if selectedTabIndex == index {
                                    // 选中状态背景（移除底部指示器）
                                    Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
            .padding(.horizontal, 8)
            
            // 底部分割线
            Rectangle()
                .fill(Color.gray.opacity(0.15))
                .frame(height: 0.5)
                .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
    
    // 优化的标签颜色 - 更加协调的配色方案
    private func tabColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.7, green: 0.5, blue: 0.9)  // 梦幻紫 - 次元回放，与个人卡片渐变呼应
        case 1: return Color(red: 0.2, green: 0.7, blue: 0.9)  // 天空蓝 - 我的动态，清新个人色彩
                        case 2: return Color(red: 1.0, green: 0.3, blue: 0.5)  // 粉红色 - 我的点赞，温暖喜爱感
        default: return Color.primary
        }
    }
    
    // 标签图标名称 - 优化为更具表现力的图标
    private func tabIconName(for index: Int) -> String {
        switch index {
        case 0: return "memories"                 // 次元回放 - 使用回忆图标，更贴合"回放"概念
        case 1: return "person.text.rectangle"   // 我的动态 - 个人动态内容图标
                        case 2: return "heart.fill"  // 我的点赞 - 心形图标，表达喜爱
        default: return "circle.fill"
        }
    }
    
    // 标签内容区域
    private var tabContentArea: some View {
        Group {
            switch selectedTabIndex {
            case 0:
                relationshipNetworkContent
            case 1:
                myPostsContent
            case 2:
                myLikesContent
            default:
                relationshipNetworkContent
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: selectedTabIndex) { _, _ in
            // 切换标签时重置展开状态
            resetExpandedStates()
        }
    }
    
    // 虫遇回忆内容（替换角色关系网络）
    private var relationshipNetworkContent: some View {
        ThoughtJourneyView()
    }
    
    // 我的动态内容（适配容器内部）  
    private var myPostsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                .frame(height: 200)
            } else {
                // 动态统计摘要（去除外层padding）
                compactDynamicsSummaryCard
                
                // 动态列表 - 苹果式宽适布局
                LazyVStack(spacing: 12) {
                    ForEach(showAllPosts ? userPosts : Array(userPosts.prefix(5))) { post in
                        UserPostCard(post: post)
                    }
                    
                    // 展开/收起按钮 - 苹果式设计
                    if userPosts.count > 5 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showAllPosts.toggle()
                                
                                // 如果展开，启动自动折叠定时器
                                if showAllPosts {
                                    startAutoCollapseTimer()
                                } else {
                                    // 如果收起，取消定时器
                                    autoCollapseTimer?.invalidate()
                                    autoCollapseTimer = nil
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showAllPosts ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.9))  // 天空蓝，与动态标签颜色一致
                                
                                Text(showAllPosts ? "收起" : "查看全部 \(userPosts.count) 条")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.9))  // 天空蓝，与动态标签颜色一致
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 0.2, green: 0.7, blue: 0.9).opacity(0.04))  // 天空蓝背景
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color(red: 0.2, green: 0.7, blue: 0.9).opacity(0.12), lineWidth: 0.5)  // 天空蓝边框
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
    
    // 我的点赞内容 - 苹果式简洁设计
    private var myLikesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if likeService.getUserLikes().isEmpty {
                // 空状态设计 - 苹果式极简
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.pink.opacity(0.08))
                            .frame(width: 88, height: 88)
                        
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink.opacity(0.8), .pink.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 6) {
                        Text("暂无点赞记录")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("去发现感兴趣的内容，给它们点个赞吧")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.quaternary, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, 0)
            } else {
                // 点赞记录列表 - 苹果式宽适布局
                LazyVStack(spacing: 12) {
                    ForEach(showAllLikes ? likeService.getUserLikes() : Array(likeService.getUserLikes().prefix(5))) { record in
                        AppleStyleLikeRecordCard(record: record) {
                            // 移除回调
                        }
                    }
                    
                    // 展开/收起按钮 - 苹果式设计
                    if likeService.getUserLikes().count > 5 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showAllLikes.toggle()
                                
                                // 如果展开，启动自动折叠定时器
                                if showAllLikes {
                                    startAutoCollapseTimer()
                                } else {
                                    // 如果收起，取消定时器
                                    autoCollapseTimer?.invalidate()
                                    autoCollapseTimer = nil
                                }
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showAllLikes ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.pink)
                                
                                Text(showAllLikes ? "收起" : "查看全部 \(likeService.getUserLikes().count) 条")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pink)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.pink.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(.pink.opacity(0.12), lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // 紧凑版动态统计摘要卡片（去除外层padding）
    private var compactDynamicsSummaryCard: some View {
        HStack(spacing: 24) {
                // 总帖子数
            HStack(spacing: 4) {
                    Text("\(userPosts.count)")
                    .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.9))  // 天空蓝，与动态标签颜色一致
                    Text("总动态")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                .frame(height: 20)
                
                // 总点赞数
            HStack(spacing: 4) {
                    Text("\(totalLikes)")
                    .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.5))  // 粉红色，与点赞标签颜色一致
                    Text("总点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                .frame(height: 20)
                
                // 总评论数
            HStack(spacing: 4) {
                    Text("\(totalComments)")
                    .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))  // 梦幻紫，与次元回放标签颜色一致
                    Text("总评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    

    

    
    // 我的动态详细视图
    private var myPostsDetailView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                .frame(height: 200)
            } else {
                // 动态统计摘要
                dynamicsSummaryCard
                
                // 动态列表
                LazyVStack(spacing: 12) {
                    ForEach(userPosts) { post in
                        UserPostRowView(post: post)
                            .onAppear {
                                #if DEBUG
                                print("🔵 [myPostsDetailView] UserPostRowView 出现，内容: \(post.content.prefix(20))...")
                                #endif
                            }
                    }
                }
                .padding(.horizontal, 20)
                .allowsHitTesting(true)
            }
        }
    }
    
    // 动态统计摘要卡片
    private var dynamicsSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("动态总结")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            Spacer()
            }
            
            HStack(spacing: 20) {
                // 总帖子数
                VStack(spacing: 4) {
                    Text("\(userPosts.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    Text("总动态")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总点赞数
                VStack(spacing: 4) {
                    Text("\(totalLikes)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.pink)
                    Text("总点赞")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                // 总评论数
                VStack(spacing: 4) {
                    Text("\(totalComments)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("总评论")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                }
            }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    // 已删除旧的互动记录视图，改为使用我的点赞视图
    
    // 已删除旧的互动统计卡片
    
    // 钱包按钮
    private var walletButton: some View {
        Button(action: {
            walletManager.showPurchaseSheet()
        }) {
            HStack(spacing: 4) {
                if walletManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white.opacity(0.7))
                } else {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                    
                    Text(walletManager.formatBalance())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .sheet(isPresented: $walletManager.showingPurchaseSheet) {
            PurchaseView()
        }
    }
    
    // 设置按钮
    private var settingsButton: some View {
                                Button(action: {
            showingSettings = true
                            }) {
                    Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - UI组件
    
    // 个人信息卡片 - 梦幻次元风格设计
    private var profileInfoCard: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.7, green: 0.5, blue: 0.9),   // 梦幻紫
                    Color(red: 0.5, green: 0.4, blue: 0.8)    // 深紫
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)
            
            // 粒子效果背景
            ForEach(0..<15, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...350),
                        y: CGFloat.random(in: 0...120)
                    )
                    .opacity(0.4)
            }
            
            // 设置按钮在卡片右上角
            VStack {
                HStack {
                    Spacer()
                    // 钱包按钮
                    walletButton
                    // 设置按钮
                    settingsButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                Spacer()
            }
            
            VStack(spacing: 0) {
                // 用户信息区域 - 垂直居中对齐
                HStack(alignment: .center, spacing: 16) {
                    // 头像容器 - 次元感设计
                    ZStack {
                        // 外层发光环
                        Circle()
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 76, height: 76)
                            .rotationEffect(.degrees(35))
            
                        // 头像背景光晕
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.white.opacity(0.5), radius: 15)
                        
                        // 头像图片
                        if let avatarImage = userProfileManager.loadAvatarImage() {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            Avatar(
                                url: "default_avatar",
                                name: userProfileManager.username,
                                size: 60,
                                borderColor: Color.white.opacity(0.2),
                                borderWidth: 1
                            )
                        }
                        

                    }
                    .onTapGesture {
                        showingImagePicker = true
                    }
                    
                                            // 用户信息 - 稍微向下偏移
                        VStack(alignment: .leading, spacing: 8) {
                            // 添加顶部间距，让内容向下偏移
                            Spacer()
                                .frame(height: 12)
                            // 第一行：用户名
                            HStack(spacing: 8) {
                                if isEditingUsername {
                                    // 编辑用户名输入框
                                    TextField("请输入用户名", text: $tempUsername)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .focused($isUsernameFieldFocused)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.2))
                                        )
                                        .onSubmit {
                                            saveUsername()
                                        }
                                } else {
                                    Text(userProfileManager.username)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                                        .onTapGesture {
                                            startEditingUsername()
                                        }
                                }
                        
                                Spacer()
                            }
                            
                            // 第二行：个性签名
                            if isEditingSignature {
                                // 编辑个性签名输入框
                                TextField("请输入个性签名", text: $tempSignature, axis: .vertical)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .focused($isSignatureFieldFocused)
                                    .lineLimit(2...3)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.2))
                                    )
                                    .onSubmit {
                                        saveSignature()
                                    }
                            } else {
                                Text(userProfileManager.personalSignature)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(2)
                                    .lineSpacing(2)
                                    .onTapGesture {
                                        startEditingSignature()
                                    }
                            }
                            
                            // 第三行：经验值信息和等级标签
                            VStack(alignment: .leading, spacing: 6) {
                                let experienceRange = userProfileManager.getCurrentLevelExperienceRange()
                                
                                                                // 经验值文本
                                HStack(spacing: 4) {
                                    Text("Lv.\(userProfileManager.userLevel)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("\(userProfileManager.userExperience - experienceRange.current)/\(experienceRange.next - experienceRange.current) EXP")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Spacer()
                                }
                                
                                // 经验进度条 - 充分利用右侧空间
                                HStack(spacing: 12) {
                                    // 进度条 - 占据大部分空间
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // 背景
                                            RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.2))
                                                .frame(height: 8)
                                        
                                        // 进度
                                            RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                        gradient: Gradient(colors: [userProfileManager.getLevelColor(), userProfileManager.getLevelColor().opacity(0.7)]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                                .frame(width: geometry.size.width * userProfileManager.getLevelUpProgress(), height: 8)
                                    }
                                }
                                    .frame(height: 8)
                                    
                                    // 等级标签 - 紧贴进度条右侧
                                    let currentLevelColorScheme = getLevelColorScheme(level: userProfileManager.userLevel)
                                    Text(userProfileManager.levelTitle)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: currentLevelColorScheme.backgroundColors),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: currentLevelColorScheme.borderColors),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                        .overlay(
                                            // 科幻科技感装饰线条
                                            Capsule()
                                                .stroke(
                                                    currentLevelColorScheme.accentColor.opacity(0.4),
                                                    lineWidth: 0.5
                                                )
                                                .padding(2)
                                        )
                                        .shadow(color: currentLevelColorScheme.shadowColor.opacity(0.3), radius: 3, x: 0, y: 2)
                                        .shadow(color: currentLevelColorScheme.accentColor.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                        }
                        .onTapGesture {
                            showLevelDetails = true
                        }
                        
                                                // 调试菜单触发区域
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 100, height: 12)
                            .onTapGesture {
                                handleUsernameTap()
                        }
                }
                                
                                Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16) // 减少垂直内边距，压缩多余空间
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
        .onTapGesture {
            // 点击卡片其他区域时自动保存编辑
            if isEditingUsername {
                saveUsername()
            }
            if isEditingSignature {
                saveSignature()
            }
        }
        .onChange(of: isUsernameFieldFocused) { _, isFocused in
            // 当用户名输入框失去焦点时，如果正在编辑则自动保存
            if !isFocused && isEditingUsername {
                saveUsername()
            }
        }
        .onChange(of: isSignatureFieldFocused) { _, isFocused in
            // 当个性签名输入框失去焦点时，如果正在编辑则自动保存
            if !isFocused && isEditingSignature {
                saveSignature()
            }
        }
    }
    
    // 时空足迹总览卡片 - 新增功能聚合卡片
    private var timeTravelOverviewCard: some View {
        VStack(spacing: 0) {
            timeTravelCardHeader
            timeTravelStatsGrid
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(timeTravelCardBackground)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
    
    // 时空足迹卡片标题 - 更新为次元概念
    private var timeTravelCardHeader: some View {
        HStack {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text("次元足迹总览")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                                
                                Spacer()
        }
        .padding(.bottom, 16)
    }
    
    // 时空足迹统计网格
    private var timeTravelStatsGrid: some View {
        VStack(spacing: 12) {
            timeTravelStatsFirstRow
            timeTravelStatsSecondRow
        }
    }
    
    // 第一行统计 - 互动成就
    private var timeTravelStatsFirstRow: some View {
        HStack(spacing: 12) {
            TimeStatItem(
                value: "\(dialogueCount)次",
                label: "次元对话",
                color: Color.blue.opacity(0.7),
                backgroundColor: Color.blue.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(resonanceCount)次",
                label: "获得点赞", 
                color: Color.pink.opacity(0.7),
                backgroundColor: Color.pink.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(cognitionCount)位",
                label: "互动好友",
                color: Color.green.opacity(0.7),
                backgroundColor: Color.green.opacity(0.08)
            )
        }
    }
    
    // 第二行统计 - 探索成就
    private var timeTravelStatsSecondRow: some View {
        HStack(spacing: 12) {
            TimeStatItem(
                value: "\(explorationDays)天",
                label: "探索天数",
                color: Color.orange.opacity(0.7),
                backgroundColor: Color.orange.opacity(0.08)
            )
            
            TimeStatItem(
                value: "\(myLikesCount)次",
                label: "我的点赞",
                color: Color.purple.opacity(0.7),
                backgroundColor: Color.purple.opacity(0.08)
                            )
            
            TimeStatItem(
                value: "\(userPosts.count)篇",
                label: "我的动态",
                color: Color.cyan.opacity(0.7),
                backgroundColor: Color.cyan.opacity(0.08)
            )
        }
    }
    
    // 卡片背景
    private var timeTravelCardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
                            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
    }
    
    // 关系网络可视化 - 增强版
    private var relationshipNetwork: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("次元关系网络")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 次元分类统计
                HStack(spacing: 8) {
                    dimensionCategoryBadge(icon: "building.columns.fill", name: "历史", count: 5, color: .brown)
                    dimensionCategoryBadge(icon: "gamecontroller.fill", name: "游戏", count: 3, color: .blue)
                    dimensionCategoryBadge(icon: "tv.fill", name: "动漫", count: 4, color: .purple)
                }
            }
            .padding(.horizontal, 20)
            
            if characterRelations.isEmpty {
                // 空状态展示 - 次元关系网络预览
                VStack(spacing: 16) {
                    ZStack {
                        // 网络节点模拟图
                        ForEach(0..<6, id: \.self) { index in
                                                Circle()
                                .fill(DesignSystem.Colors.primary.opacity(0.6))
                                .frame(width: 24, height: 24)
                                .position(
                                    x: [100, 200, 150, 80, 220, 150][index],
                                    y: [50, 50, 100, 120, 120, 150][index]
                                )
                        .overlay(
                                    Image(systemName: ["person.fill", "crown.fill", "gamecontroller.fill", "paintbrush.fill", "book.fill", "tv.fill"][index])
                                        .font(.system(size: 8))
                                .foregroundColor(.white)
                                        .position(
                                            x: [100, 200, 150, 80, 220, 150][index],
                                            y: [50, 50, 100, 120, 120, 150][index]
                                        )
                                )
                        }
                        
                        // 连接线
                        Path { path in
                            let points = [
                                CGPoint(x: 100, y: 50),
                                CGPoint(x: 150, y: 100),
                                CGPoint(x: 200, y: 50),
                                CGPoint(x: 150, y: 150),
                                CGPoint(x: 80, y: 120),
                                CGPoint(x: 220, y: 120)
                            ]
                            
                            for i in 0..<points.count {
                                for j in (i+1)..<points.count {
                                    if (i == 0 && j == 2) || (i == 1 && j == 3) || (i == 2 && j == 5) {
                                        path.move(to: points[i])
                                        path.addLine(to: points[j])
                                    }
                                }
                            }
                        }
                        .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 2)
                    }
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    VStack(spacing: 8) {
                        Text("构建您的次元关系网络")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("与不同次元的角色互动，建立独特的关系网络")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            // 跳转到探索页面
                        }) {
                            Text("开始探索")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(DesignSystem.Colors.primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            } else {
                // 角色关系列表
                LazyVStack(spacing: 8) {
                    ForEach(characterRelations, id: \.id) { relation in
                    HStack(spacing: 12) {
                        // 角色头像
                                        Circle()
                                .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                    Text(String(relation.characterName.prefix(1)))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(DesignSystem.Colors.primary)
                            )
                        
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relation.characterName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(relation.relationshipType)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                                
                                Spacer()
                                
                            Text("\(relation.interactionCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                            }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    // 次元分类徽章
    private func dimensionCategoryBadge(icon: String, name: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    // 最近互动列表
    private var recentInteractionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("最近互动")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
            
                         VStack(spacing: 0) {
                     if userPosts.count > 0 {
                         UserPostRowView(post: userPosts[0])
                         if userPosts.count > 1 {
                             Divider()
                                 .background(Color.gray.opacity(0.3))
                                 .padding(.leading, 56)
                             UserPostRowView(post: userPosts[1])
                             if userPosts.count > 2 {
                                 Divider()
                                     .background(Color.gray.opacity(0.3))
                                     .padding(.leading, 56)
                                 UserPostRowView(post: userPosts[2])
                             }
                         }
                     }
             }
            .background(Color.white)
                    .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // 成就展示网格 - 使用新的成就系统
    private var achievementsGrid: some View {
        NewAchievementView()
    }
    
    // 计算用户帖子 - 简化版本，避免复杂的缓存逻辑
    private var userPosts: [UserPostModel] {
        return postViewModel.posts.filter { $0.source == "user" }
    }
    
    // 计算总点赞数 - 简化版本
    private var totalLikes: Int {
        userPosts.reduce(0) { total, post in
            total + post.likes
        }
    }
    
    // 计算总评论数 - 简化版本
    private var totalComments: Int {
        userPosts.reduce(0) { total, post in
            total + post.comments.count
                        }
                    }
    
    // MARK: - 计算属性 - 优化版本
    
    // 计算关注角色数
    private var followingCount: Int {
        // 这里应该从实际的关注数据中计算，暂时返回模拟数据
        12
    }
    
    // MARK: - 性能优化：使用缓存的计算属性
    
    // 缓存是否有效
    private var isCacheValid: Bool {
        Date().timeIntervalSince(lastCacheUpdate) < cacheValidDuration
    }
    
    // 新增：次元对话数（使用缓存）
    private var dialogueCount: Int {
        return cachedDialogueCount
    }
    

    
    // 新增：穿越次数（使用缓存）
    private var travelCount: Int {
        return cachedTravelCount
    }
    
    // 新增：探索天数（基于实际的探索时间计算）
    private var explorationDays: Int {
        return calculateExplorationDays()
    }
    
    // 新增：认知升华次数（使用缓存）
    private var cognitionCount: Int {
        return cachedCognitionCount
    }
    
    // 新增：时空共鸣次数（使用缓存）
    private var resonanceCount: Int {
        return cachedResonanceCount
    }
    
    // 新增：深度对话次数（使用缓存）
    private var deepDialogueCount: Int {
        return cachedDeepDialogueCount
    }
    
    // 新增：我的点赞次数（使用缓存）
    private var myLikesCount: Int {
        return cachedMyLikesCount
    }
    
    // MARK: - 数据计算方法
    
    /// 计算总对话数：用户发布的评论数量 + 用户与虚拟角色的私聊消息数量 + 用户发布的帖子数量
    private func calculateTotalDialogues() -> Int {
        let posts = PostViewModel.shared.posts
        
        // 1. 计算用户发布的评论数量（在所有帖子中）
        let userComments = posts.flatMap { post -> [DetailedCommentModel] in
            post.comments.filter { comment in
                !comment.isVirtualCharacter // 非虚拟角色的评论即为用户评论
            }
        }.count
        
        // 2. 计算用户在私聊中发送的消息数量
        var userPrivateMessages = 0
        do {
            let messageDescriptor = FetchDescriptor<Message>(
                predicate: #Predicate<Message> { message in
                    message.isFromUser == true
                }
            )
            let messages = try modelContext.fetch(messageDescriptor)
            userPrivateMessages = messages.count
        } catch {

        }
        
        // 3. 计算用户发布的帖子数量
        let userPostsCount = userPosts.count
        
        return userComments + userPrivateMessages + userPostsCount
    }
    
    /// 计算总共鸣数：从通知数据中统计用户收到的实际点赞总数
    private func calculateTotalResonance() -> Int {
        // 从NotificationService的永久存储中获取所有点赞通知
        let likeNotifications = NotificationService.shared.notifications.filter { notification in
            notification.type == .like
        }
        
        #if DEBUG
        print("🔍 ProfileView: 发现 \(likeNotifications.count) 个点赞通知")
        #endif
        
        // 统计总点赞数
        let totalLikes = likeNotifications.count
        
        #if DEBUG
        print("❤️ ProfileView: 计算得到的总点赞数: \(totalLikes)")
        #endif
        
        return totalLikes
    }
    
    /// 计算总互动角色数：包括和用户点赞或者评论或者私聊的任意一项的角色的数量
    private func calculateTotalActiveCharacters() -> Int {
        let posts = PostViewModel.shared.posts
        var interactedCharacters: Set<String> = []
        
        // 1. 统计在帖子中与用户互动的角色（给用户帖子点赞或评论）
        for post in userPosts {
            // 检查给用户帖子点赞的角色（通过点赞通知）
            let postLikeNotifications = NotificationService.shared.notifications.filter { notification in
                notification.type == .like && notification.relatedPostId == post.id.uuidString
            }
            for notification in postLikeNotifications {
                if let character = notification.character {
                    // 通过角色名称查找角色ID
                    let characterInfoList = CharacterDataManager.shared.getAllCharactersInfo()
                    if let characterInfo = characterInfoList.first(where: { $0.name == character.name }) {
                        interactedCharacters.insert(characterInfo.id)
                    }
                }
            }
            
            // 检查给用户帖子评论的角色
            for comment in post.comments where comment.isVirtualCharacter {
                if let characterID = comment.characterID {
                    interactedCharacters.insert(characterID)
                }
            }
        }
        
        // 2. 统计在评论中与用户互动的角色（给用户评论点赞或回复）
        for post in posts {
            for comment in post.comments where !comment.isVirtualCharacter {
                // 这是用户的评论，检查哪些角色回复了
                for reply in comment.replies where reply.isVirtualCharacter {
                    if let characterID = reply.characterID {
                        interactedCharacters.insert(characterID)
                    }
                }
            }
        }
        
        // 3. 统计在私聊中与用户互动的角色
        do {
            let messageDescriptor = FetchDescriptor<Message>()
            let messages = try modelContext.fetch(messageDescriptor)
            
            for message in messages {
                if message.isFromUser {
                    // 用户发送的消息，receiverId是角色ID
                    interactedCharacters.insert(message.receiverId)
                                                } else {
                    // 角色发送的消息，senderId是角色ID
                    interactedCharacters.insert(message.senderId)
                }
            }
        } catch {

        }
        
        return interactedCharacters.count
    }
    
    /// 计算探索天数：从最早的帖子或消息时间计算到现在
    private func calculateExplorationDays() -> Int {
        let posts = PostViewModel.shared.posts
        var earliestDate: Date? = posts.map { $0.datePosted }.min()
        
        // 检查SwiftData中的最早消息时间
        do {
            let msgDescriptor = FetchDescriptor<Message>(sortBy: [SortDescriptor(\.timestamp)])
            let messages = try modelContext.fetch(msgDescriptor)
            if let firstMessage = messages.first {
                if let currentEarliest = earliestDate {
                    earliestDate = min(currentEarliest, firstMessage.timestamp)
                } else {
                    earliestDate = firstMessage.timestamp
                }
            }
        } catch {
            #if DEBUG
            print("获取消息失败: \(error)")
            #endif
        }
        
        // 如果没有任何数据，返回0天
        guard let startDate = earliestDate else {
            return 0
        }
        
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        return max(days, 1) // 至少返回1天（如果有数据的话）
    }
    
    /// 计算点赞收藏数：用户点赞的帖子数量
    private func calculateCollectedEssence() -> Int {
        return UserLikeService.shared.getUserLikes().count
    }
    
    /// 计算我的动态数：用户发布的帖子数量
    private func calculateTotalDynamics() -> Int {
        return userPosts.count
    }
    
    // 已删除旧的模拟互动记录数据，改为使用真实的点赞数据
    
    // 扩展成就数据 - 新增更多成就类型
    private var extendedUserAchievements: [ExtendedAchievement] {
        [
            ExtendedAchievement(id: "1", name: "次元旅行者", icon: "globe.americas.fill", description: "完成10次次元对话", isUnlocked: true),
            ExtendedAchievement(id: "2", name: "历史学者", icon: "book.fill", description: "与5位历史人物交流", isUnlocked: true),
            ExtendedAchievement(id: "3", name: "文艺复兴", icon: "paintpalette.fill", description: "与达芬奇深度交流", isUnlocked: true),
            ExtendedAchievement(id: "4", name: "游戏达人", icon: "gamecontroller.fill", description: "与3位游戏角色互动", isUnlocked: true),
            ExtendedAchievement(id: "5", name: "动漫专家", icon: "tv.fill", description: "收集5个动漫角色", isUnlocked: false),
            ExtendedAchievement(id: "6", name: "次元探索者", icon: "location.fill", description: "解锁所有次元类型", isUnlocked: false),
            ExtendedAchievement(id: "7", name: "社交达人", icon: "person.2.fill", description: "获得100次互动", isUnlocked: true),
            ExtendedAchievement(id: "8", name: "时间守护者", icon: "clock.fill", description: "连续活跃30天", isUnlocked: true),
            ExtendedAchievement(id: "9", name: "次元收藏家", icon: "star.fill", description: "收藏50个精彩对话", isUnlocked: false)
        ]
    }
    
    // 计算已解锁成就数量
    private var unlockedAchievementsCount: Int {
        extendedUserAchievements.filter { $0.isUnlocked }.count
    }
    
    // 处理用户名点击 - 七次点击触发调试菜单
    private func handleUsernameTap() {
        let now = Date()
        
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 2 {
            // 超过2秒，重置计数
            debugTapCount = 1
                                                } else {
            debugTapCount += 1
        }
        
        lastTapTime = now
        
        if debugTapCount >= 7 {
            debugTapCount = 0
            lastTapTime = nil
            isDebugMenuPresented = true
                                    }
                                }
    
    // 我的动态视图
    private func myPostsView() -> some View {
            Group {
            if userPosts.isEmpty {
                enhancedEmptyContentView(
                    icon: "square.text.square",
                    message: "暂无动态",
                    description: "您还没有发布过动态，与历史人物对话并分享您的见解吧！",
                    buttonTitle: "发布动态",
                    buttonAction: {
                        // 发布动态的代码
                    }
                )
                                } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(userPosts.prefix(3)) { post in
                            UserPostRowView(post: post)
                        }
                        
                        if userPosts.count > 3 {
                                        Button(action: {
                                // 查看全部动态
                            }) {
                                Text("查看全部 \(userPosts.count) 条动态")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primaryColor)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
            }
        }
    }
    
    // 角色关系视图
    private func characterRelationsView() -> some View {
        ScrollView {
        LazyVStack(spacing: 8) {
                ForEach(characterRelations, id: \.id) { relation in
                HStack(spacing: 12) {
                    // 角色头像
                    Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                        .overlay(
                                Text(String(relation.characterName.prefix(1)))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(DesignSystem.Colors.primary)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                            Text(relation.characterName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(relation.relationshipType)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(relation.interactionCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                }
            }
        }
    }
    
    // 增强的空内容视图
    private func enhancedEmptyContentView(
        icon: String,
        message: String,
        description: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
                Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.primaryColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryColor)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
         // 用户帖子行视图
     private func UserPostRowView(post: UserPostModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("次元指挥官")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                                 Text(formatTimeAgo(post.datePosted))
                     .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // 我的动态正文支持长按复制（完全按照私聊实现）
            Text(post.content.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 14))
                .lineSpacing(4)
                .padding(.horizontal, 0)
                .padding(.vertical, 8)
                .foregroundColor(.primary)
                .lineLimit(3)
                .onTapGesture {
                    #if DEBUG
                    print("🔵 [UserPostRowView private] Text 被点击")
                    #endif
                }
            
            HStack {
                                 HStack(spacing: 4) {
                     Image(systemName: "heart")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                     Text("\(post.likes)")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                 }
                 
                 HStack(spacing: 4) {
                     Image(systemName: "message")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                     Text("\(post.comments.count)")
                         .font(.system(size: 12))
                         .foregroundColor(.secondary)
                 }
                
                Spacer()
                }
            }
            .contextMenu {
                Button {
                    #if DEBUG
                    print("🔵 [UserPostRowView private] contextMenu 按钮被点击，内容: \(post.content.prefix(20))...")
                    #endif
                    UIPasteboard.general.string = post.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowToast"),
                        object: nil,
                        userInfo: ["message": "已复制动态内容"]
                    )
                } label: {
                    Label("复制动态内容", systemImage: "doc.on.doc")
                }
            }
            .onTapGesture {
                #if DEBUG
                print("🔵 [UserPostRowView private] VStack 被点击")
                #endif
            }
            .onLongPressGesture {
                #if DEBUG
                print("🔵 [UserPostRowView private] VStack 被长按")
                #endif
            }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // 时间格式化函数
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)小时前"
        } else {
            let days = Int(interval / 86400)
            return "\(days)天前"
        }
    }
    
    // 成就详情视图
    private func achievementDetailView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("成就展示")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(userAchievements) { achievement in
                        VStack(spacing: 8) {
                                    Image(systemName: achievement.icon)
                                .font(.system(size: 32))
                                .foregroundColor(.primaryColor)
                                
                                Text(achievement.name)
                                .font(.system(size: 14, weight: .medium))
                                    .multilineTextAlignment(.center)
                                
                                Text(achievement.description)
                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAchievements = false
                    }
                }
            }
        }
    }
    
    // 等级详情视图
    private func levelDetailView() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("等级详情")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                
                VStack(spacing: 16) {
                    // 等级图标和称号
                    HStack(spacing: 12) {
                        Image(systemName: userProfileManager.getLevelIcon())
                            .font(.system(size: 32))
                            .foregroundColor(userProfileManager.getLevelColor())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userProfileManager.levelTitle)
                        .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(userProfileManager.getLevelColor())
                
                            Text("Lv.\(userProfileManager.userLevel)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // 等级描述
                    Text(getLevelDescription(level: userProfileManager.userLevel))
                        .font(.system(size: 14))
                    .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // 经验值进度
                    VStack(spacing: 8) {
                        let experienceRange = userProfileManager.getCurrentLevelExperienceRange()
                        HStack {
                            Text("经验值")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(userProfileManager.userExperience - experienceRange.current)/\(experienceRange.next - experienceRange.current)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(userProfileManager.getLevelColor())
                        }
                        
                        // 进度条
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [userProfileManager.getLevelColor(), userProfileManager.getLevelColor().opacity(0.7)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * userProfileManager.getLevelUpProgress(), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                        .padding(.horizontal, 20)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                    showLevelDetails = false
                    }
                }
            }
                }
            }
            
    // 调试菜单视图
    private func debugMenuView() -> some View {
        NavigationView {
                VStack(spacing: 20) {
                Text("调试菜单")
                    .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                    
                VStack(spacing: 12) {
                    Text("开发者选项")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Button("清除所有数据") {
                        // 清除数据的代码
                    }
                    .foregroundColor(.red)
                    
                    Button("重新加载界面") {
                        // 重新加载的代码
                    }
                    
                    Button("导出日志") {
                        // 导出日志的代码
                    }
                    
                    // 颜色预览按钮
                    NavigationLink(destination: ColorPreviewView()) {
                        Text("🎨 颜色预览")
                            .foregroundColor(.blue)
                    }
                    
                    // 用户动态持久化调试工具
                    NavigationLink(destination: UserPostPersistenceDebugView()) {
                        Text("📝 用户动态调试")
                            .foregroundColor(.purple)
                    }
                            }
                .padding(20)
                    .background(
                    RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4)
                            )
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isDebugMenuPresented = false
                    }
        }
        }
    }
    }
    
    // MARK: - 数据加载与缓存
    
    /// 性能优化：异步更新缓存，避免阻塞UI
    private func loadOrCalculateStats() {
        // 如果正在计算，跳过
        guard !isCalculating else { 
            #if DEBUG
            print("🔄 ProfileView: 正在计算中，跳过重复请求")
            #endif
            return 
        }
        
        // 如果缓存仍然有效，跳过
        guard !isCacheValid else { 
            #if DEBUG
            print("✅ ProfileView: 缓存仍然有效，跳过更新")
            #endif
            return 
        }
        
        // 如果距离上次更新不到30秒，跳过（防止频繁更新）
        let timeSinceLastUpdate = Date().timeIntervalSince(lastCacheUpdate)
        guard timeSinceLastUpdate > 30 else {
            #if DEBUG
            print("⏰ ProfileView: 距离上次更新仅\(Int(timeSinceLastUpdate))秒，跳过更新")
            #endif
            return
        }
        
        isCalculating = true
        #if DEBUG
        print("🚀 ProfileView: 开始异步更新缓存")
        #endif
        
        // 在后台异步计算，避免阻塞UI
        Task {
            await updateCacheAsync()
        }
    }
    
    /// 异步更新所有缓存数据
    @MainActor
    private func updateCacheAsync() async {
        // 并行计算所有统计数据，提高效率
        async let dialogueCountResult = calculateTotalDialoguesOptimized()
        async let resonanceCountResult = calculateTotalResonancesOptimized()
        async let cognitionCountResult = calculateTotalCognitionsOptimized()
        async let travelCountResult = calculateTotalTravelsOptimized()
        async let myLikesCountResult = calculateMyLikesCountOptimized()

        async let deepDialogueCountResult = calculateTotalDeepDialoguesOptimized()
        
        // 等待所有计算完成
        let results = await (
            dialogueCount: dialogueCountResult,
            resonanceCount: resonanceCountResult,
            cognitionCount: cognitionCountResult,
            travelCount: travelCountResult,
            myLikesCount: myLikesCountResult,
            deepDialogueCount: deepDialogueCountResult
        )
        
        // 批量更新缓存状态，减少视图重绘次数
        cachedDialogueCount = results.dialogueCount
        cachedResonanceCount = results.resonanceCount
        cachedCognitionCount = results.cognitionCount
        cachedTravelCount = results.travelCount
        cachedMyLikesCount = results.myLikesCount

        cachedDeepDialogueCount = results.deepDialogueCount
        
        // 🔥 关键修复：将统计数据同步到UserProfileManager
        let stats = [
            "dialogueCount": results.dialogueCount,
            "resonanceCount": results.resonanceCount,
            "cognitionCount": results.cognitionCount,
            "deepDialogueCount": results.deepDialogueCount,
            "myLikesCount": results.myLikesCount,
            "travelCount": results.travelCount
        ]
        
        // 更新UserProfileManager的统计数据缓存
        userProfileManager.updateStatsCache(stats)
        
        // 温和更新用户等级（不强制清除缓存）
        userProfileManager.updateUserLevelAsync()
        
        lastCacheUpdate = Date()
        isCalculating = false
        
        #if DEBUG
        print("🚀 ProfileView: 缓存更新完成，数据刷新成功")
        print("📊 ProfileView: 统计数据已同步到UserProfileManager: \(stats)")
        #endif
    }
    
    /// 性能优化：精确的数据更新监听器
    private func setupDataUpdateListeners() {
        // 监听帖子数据的精确变化（防抖处理）
        let postSubscription = postViewModel.$posts
            .removeDuplicates { oldPosts, newPosts in
                // 只有帖子数量真正变化时才更新
                oldPosts.count == newPosts.count
            }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main) // 增加防抖时间到1秒
            .sink { _ in
                #if DEBUG
                print("📊 ProfileView: 检测到帖子数量变化，更新缓存")
                #endif
                self.loadOrCalculateStats()
            }
        cancellables.insert(postSubscription)
        
        // 监听通知数据的精确变化（防抖处理）
        let notificationSubscription = notificationService.$notifications
            .removeDuplicates { oldNotifications, newNotifications in
                // 只有通知数量真正变化时才更新
                oldNotifications.count == newNotifications.count
            }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main) // 增加防抖时间到1秒
            .sink { _ in
                #if DEBUG
                print("📊 ProfileView: 检测到通知数量变化，更新缓存")
                #endif
                self.loadOrCalculateStats()
            }
        cancellables.insert(notificationSubscription)
        
        // 监听点赞数据变化
        let likeSubscription = likeService.$userLikes
            .removeDuplicates { oldLikes, newLikes in
                oldLikes.count == newLikes.count
            }
            .debounce(for: .milliseconds(1000), scheduler: DispatchQueue.main) // 增加防抖时间到1秒
            .sink { _ in
                #if DEBUG
                print("📊 ProfileView: 检测到点赞数量变化，更新缓存")
                #endif
                self.loadOrCalculateStats()
            }
        cancellables.insert(likeSubscription)
    }
    
    /// 计算所有统计数据并返回
    private func calculateAllStats() -> [String: Int] {
        return [
            "dialogueCount": calculateTotalDialogues(),

            "travelCount": calculateTotalTravels(),
            "cognitionCount": calculateTotalCognitions(),
            "resonanceCount": calculateTotalResonances(),
            "deepDialogueCount": calculateTotalDeepDialogues(),
            "myLikesCount": calculateMyLikesCount(),
            "followingCount": followingCount
        ]
    }
    
    // MARK: - Missing Calculation Methods
    
    /// 计算穿越次数
    private func calculateTotalTravels() -> Int {
        // 基于多角色聊天会话数计算穿越次数
        do {
            let descriptor = FetchDescriptor<MultiPersonChatSession>()
            let sessions = try modelContext.fetch(descriptor)
            return sessions.count
        } catch {
            #if DEBUG
            print("获取聊天会话失败: \(error)")
            #endif
            return 0
        }
    }
    
    /// 计算认知升华次数
    private func calculateTotalCognitions() -> Int {
        // 基于深度对话和学习成果计算
        let posts = postViewModel.posts
        
        // 优化：只检查内容长度，避免字符串搜索
        let deepThoughtPosts = posts.filter { post in
            post.content.count > 200
        }.count
        
        return deepThoughtPosts
    }
    
    /// 计算时空共鸣次数
    private func calculateTotalResonances() -> Int {
        // 基于点赞和情感共鸣计算
        let totalLikes = notificationService.notifications.compactMap { notification in
            if case .like = notification.type {
                return 1
            }
            return 0
        }.reduce(0, +)
        
        // 共鸣次数基于获得的点赞数
        return totalLikes
    }
    
    /// 计算深度对话次数
    private func calculateTotalDeepDialogues() -> Int {
        // 基于多角色聊天中的消息长度和质量计算
        do {
            let descriptor = FetchDescriptor<MultiPersonChatMessage>()
            let messages = try modelContext.fetch(descriptor)
            
            // 深度对话：消息长度超过100字符
            let deepMessages = messages.filter { message in
                message.content.count > 100
            }.count
            
            return deepMessages
        } catch {
            #if DEBUG
            print("获取聊天消息失败: \(error)")
            #endif
            return 0
        }
    }
    
    /// 计算我的点赞次数
    private func calculateMyLikesCount() -> Int {
        // 计算用户主动点赞的数量
        return UserLikeService.shared.getUserLikes().count
    }
    
    // MARK: - 性能优化：高效的数据计算方法
    
    /// 优化版：计算总对话数（使用fetchCount，避免全量查询）
    private func calculateTotalDialoguesOptimized() async -> Int {
        do {
            // 1. 计算用户评论数（直接从PostViewModel获取）
            // 由于DetailedCommentModel不是PersistentModel，直接从PostViewModel获取评论数
            let userCommentsCount = postViewModel.posts.flatMap { $0.comments }.filter { comment in
                !comment.isVirtualCharacter
            }.count
            
            // 2. 计算用户私聊消息数（使用计数查询）
            let userMessagesPredicate = #Predicate<Message> { message in
                message.isFromUser == true
            }
            let messagesDescriptor = FetchDescriptor<Message>(predicate: userMessagesPredicate)
            let userMessagesCount = try modelContext.fetchCount(messagesDescriptor)
            
            // 3. 用户帖子数
            let userPostsCount = userPosts.count
            
            return userCommentsCount + userMessagesCount + userPostsCount
        } catch {
            #if DEBUG
            print("❌ 计算对话数失败: \(error)")
            #endif
            return 0
        }
    }
    
    /// 优化版：计算总共鸣数（使用缓存的通知数据）
    private func calculateTotalResonancesOptimized() async -> Int {
        // 直接从内存中的通知数据统计，无需数据库查询
        return NotificationService.shared.notifications.filter { $0.type == .like }.count
    }
    
    /// 优化版：计算认知升华次数（使用优化的查询）
    private func calculateTotalCognitionsOptimized() async -> Int {
        // 基于帖子数量的简化计算，避免复杂的内容分析
        let posts = PostViewModel.shared.posts
        return posts.filter { $0.content.count > 200 }.count
    }
    
    /// 优化版：计算穿越次数（使用fetchCount）
    private func calculateTotalTravelsOptimized() async -> Int {
        do {
            let descriptor = FetchDescriptor<MultiPersonChatSession>()
            return try modelContext.fetchCount(descriptor)
        } catch {
            #if DEBUG
            print("❌ 计算穿越次数失败: \(error)")
            #endif
            return 0
        }
    }
    
    /// 优化版：计算我的点赞次数（直接使用缓存）
    private func calculateMyLikesCountOptimized() async -> Int {
        // 直接使用服务层的缓存数据，无需额外计算
        return UserLikeService.shared.getUserLikes().count
    }
    

    
    /// 优化版：计算深度对话次数（使用fetchCount）
    private func calculateTotalDeepDialoguesOptimized() async -> Int {
        do {
            let descriptor = FetchDescriptor<MultiPersonChatMessage>()
            let messages = try modelContext.fetch(descriptor)
            return messages.filter { $0.content.count > 100 }.count
        } catch {
            #if DEBUG
            print("❌ 计算深度对话次数失败: \(error)")
            #endif
            return 0
        }
    }
    
    // MARK: - 等级标签预览
    
    /// 预览不同等级的标签样式
    private func levelTagPreview(level: Int) -> some View {
        let colorScheme = getLevelColorScheme(level: level)
        
        return Text(getLevelTitleForLevel(level))
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: colorScheme.backgroundColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme.borderColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
            )
            .overlay(
                // 科幻科技感装饰线条
                Capsule()
                    .stroke(
                        colorScheme.accentColor.opacity(0.4),
                        lineWidth: 0.3
                    )
                    .padding(1.5)
            )
            .shadow(color: colorScheme.shadowColor.opacity(0.3), radius: 2, x: 0, y: 1)
            .shadow(color: colorScheme.accentColor.opacity(0.2), radius: 1, x: 0, y: 0.5)
    }
    
    /// 获取等级对应的配色方案 - 苹果级设计，紫色背景和谐配色
    private func getLevelColorScheme(level: Int) -> LevelColorScheme {
        switch level {
        case 1: // 时空新手 - 薄荷青绿，清新不突兀
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.4, green: 0.8, blue: 0.7).opacity(0.85), // 薄荷青
                    Color(red: 0.3, green: 0.7, blue: 0.8).opacity(0.75)  // 浅青蓝
                ],
                borderColors: [
                    Color(red: 0.4, green: 0.8, blue: 0.7).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.4, green: 0.8, blue: 0.7),
                shadowColor: Color(red: 0.3, green: 0.7, blue: 0.8)
            )
        case 2: // 虫洞探险家 - 天空蓝，与紫色形成和谐对比
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.8),  // 天空蓝
                    Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.7)   // 浅天蓝
                ],
                borderColors: [
                    Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.4, green: 0.6, blue: 0.9),
                shadowColor: Color(red: 0.3, green: 0.7, blue: 0.9)
            )
        case 3: // 次元旅行者 - 蓝紫过渡，自然融入紫色背景
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.5, green: 0.6, blue: 0.9).opacity(0.8),  // 蓝紫
                    Color(red: 0.6, green: 0.5, blue: 0.9).opacity(0.7)   // 紫蓝
                ],
                borderColors: [
                    Color(red: 0.5, green: 0.6, blue: 0.9).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.5, green: 0.6, blue: 0.9),
                shadowColor: Color(red: 0.6, green: 0.5, blue: 0.9)
            )
        case 4: // 时空冒险家 - 优雅紫，与背景形成层次
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.8),  // 优雅紫
                    Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.7)   // 深优雅紫
                ],
                borderColors: [
                    Color(red: 0.7, green: 0.5, blue: 0.9).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.7, green: 0.5, blue: 0.9),
                shadowColor: Color(red: 0.6, green: 0.4, blue: 0.8)
            )
        case 5: // 虫洞漫游者 - 深紫蓝，深邃神秘
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.5, green: 0.4, blue: 0.8).opacity(0.85), // 深紫蓝
                    Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.75)  // 紫蓝
                ],
                borderColors: [
                    Color(red: 0.5, green: 0.4, blue: 0.8).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.5, green: 0.4, blue: 0.8),
                shadowColor: Color(red: 0.6, green: 0.3, blue: 0.9)
            )
        case 6: // 次元守护者 - 紫粉过渡，温暖优雅
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.8),  // 紫粉
                    Color(red: 0.9, green: 0.3, blue: 0.7).opacity(0.7)   // 粉紫
                ],
                borderColors: [
                    Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.8, green: 0.4, blue: 0.8),
                shadowColor: Color(red: 0.9, green: 0.3, blue: 0.7)
            )
        case 7: // 时空大师 - 玫瑰紫，高贵典雅
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.9, green: 0.3, blue: 0.6).opacity(0.8),  // 玫瑰紫
                    Color(red: 0.8, green: 0.2, blue: 0.7).opacity(0.7)   // 深玫瑰紫
                ],
                borderColors: [
                    Color(red: 0.9, green: 0.3, blue: 0.6).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.9, green: 0.3, blue: 0.6),
                shadowColor: Color(red: 0.8, green: 0.2, blue: 0.7)
            )
        case 8: // 虫洞领主 - 珊瑚橙，与紫色形成完美对比
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.95, green: 0.4, blue: 0.3).opacity(0.85), // 珊瑚橙
                    Color(red: 0.9, green: 0.3, blue: 0.4).opacity(0.75)   // 深珊瑚橙
                ],
                borderColors: [
                    Color(red: 0.95, green: 0.4, blue: 0.3).opacity(0.6),
                    Color.white.opacity(0.9)
                ],
                accentColor: Color(red: 0.95, green: 0.4, blue: 0.3),
                shadowColor: Color(red: 0.9, green: 0.3, blue: 0.4)
            )
        case 9: // 次元王者 - 琥珀金，王者风范
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 0.95, green: 0.6, blue: 0.2).opacity(0.9),  // 琥珀金
                    Color(red: 0.9, green: 0.5, blue: 0.1).opacity(0.8)    // 深琥珀金
                ],
                borderColors: [
                    Color(red: 0.95, green: 0.6, blue: 0.2).opacity(0.7),
                    Color.white.opacity(1.0)
                ],
                accentColor: Color(red: 0.95, green: 0.6, blue: 0.2),
                shadowColor: Color(red: 0.9, green: 0.5, blue: 0.1)
            )
        case 10: // 时空传奇 - 传奇金，最高荣耀
            return LevelColorScheme(
                backgroundColors: [
                    Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.95),  // 传奇金
                    Color(red: 0.95, green: 0.7, blue: 0.1).opacity(0.85), // 深传奇金
                    Color(red: 1.0, green: 0.9, blue: 0.4).opacity(0.75)   // 浅传奇金
                ],
                borderColors: [
                    Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.8),
                    Color.white.opacity(1.0)
                ],
                accentColor: Color(red: 1.0, green: 0.8, blue: 0.2),
                shadowColor: Color(red: 0.95, green: 0.7, blue: 0.1)
            )
        default:
            return getLevelColorScheme(level: 1)
        }
    }
    
    /// 获取指定等级的称号
    private func getLevelTitleForLevel(_ level: Int) -> String {
        switch level {
        case 1: return "时空新手"
        case 2: return "虫洞探险家"
        case 3: return "次元旅行者"
        case 4: return "时空冒险家"
        case 5: return "虫洞漫游者"
        case 6: return "次元守护者"
        case 7: return "时空大师"
        case 8: return "虫洞领主"
        case 9: return "次元王者"
        case 10: return "时空传奇"
        default: return "时空新手"
        }
    }
    
    // MARK: - 状态管理
    
    /// 重置所有展开状态
    private func resetExpandedStates() {
        // 取消自动折叠定时器
        autoCollapseTimer?.invalidate()
        autoCollapseTimer = nil
        
        withAnimation(.easeInOut(duration: 0.25)) {
            showAllPosts = false
            showAllLikes = false
        }
    }
    
    /// 启动自动折叠定时器
    private func startAutoCollapseTimer() {
        // 取消之前的定时器
        autoCollapseTimer?.invalidate()
        
        // 创建新的定时器，30秒后自动折叠
        autoCollapseTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showAllPosts = false
                    showAllLikes = false
                }
            }
        }
    }
    
    // MARK: - 直接编辑方法
    
    /// 开始编辑用户名
    private func startEditingUsername() {
        tempUsername = userProfileManager.username
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingUsername = true
        }
        // 延迟聚焦，确保动画完成后再弹出键盘
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isUsernameFieldFocused = true
        }
    }
    
    /// 保存用户名
    private func saveUsername() {
        let trimmedUsername = tempUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUsername.isEmpty {
            userProfileManager.updateUsername(trimmedUsername)
        }
        
        // 先收起键盘
        isUsernameFieldFocused = false
        
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingUsername = false
        }
    }
    
    /// 开始编辑个性签名
    private func startEditingSignature() {
        tempSignature = userProfileManager.personalSignature
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingSignature = true
        }
        // 延迟聚焦，确保动画完成后再弹出键盘
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSignatureFieldFocused = true
        }
    }
    
    /// 保存个性签名
    private func saveSignature() {
        let trimmedSignature = tempSignature.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSignature.isEmpty {
            userProfileManager.updatePersonalSignature(trimmedSignature)
        }
        
        // 先收起键盘
        isSignatureFieldFocused = false
        
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditingSignature = false
        }
    }
}

// 简化的角色关系数据模型
struct SimpleCharacterRelation {
    let id = UUID()
    let characterName: String
    let relationshipType: String
    let interactionCount: Int
}

// 可识别的UIImage包装器，用于sheet显示
struct IdentifiableUIImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// 等级配色方案数据模型
struct LevelColorScheme {
    let backgroundColors: [Color]
    let borderColors: [Color]
    let accentColor: Color
    let shadowColor: Color
}

// MARK: - 支持组件

// 成就数据模型
struct Achievement: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
}

// 扩展成就数据模型已在上方定义，这里删除重复定义

// 时空统计项组件
struct TimeStatItem: View {
    let value: String
    let label: String
    let color: Color
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
    }
}


// 用户帖子行视图
struct UserPostRowView: View {
    let post: UserPostModel
    
    // 图片查看器状态
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        HStack(spacing: 12) {
            // 用户头像
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Text("用")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                )
                .onTapGesture {
                    #if DEBUG
                    print("🔵 [UserPostRowView struct] 头像被点击")
                    #endif
                }
                .allowsHitTesting(true)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(UserProfileManager.shared.getCurrentUsername())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: post.datePosted))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // 文本内容区域 - 支持长按复制（完全按照私聊实现）
                Text(post.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 13))
                    .lineSpacing(4)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 8)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .onTapGesture {
                        #if DEBUG
                        print("🔵 [UserPostRowView struct] Text 被点击")
                        #endif
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .allowsHitTesting(true)
            .contextMenu {
                Button {
                    #if DEBUG
                    print("🔵 [UserPostRowView struct] contextMenu 按钮被点击，内容: \(post.content.prefix(20))...")
                    #endif
                    UIPasteboard.general.string = post.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowToast"),
                        object: nil,
                        userInfo: ["message": "已复制动态内容"]
                    )
                } label: {
                    Label("复制动态内容", systemImage: "doc.on.doc")
                }
            }
            .onTapGesture {
                #if DEBUG
                print("🔵 [UserPostRowView struct] VStack 被点击")
                #endif
            }
            .onLongPressGesture {
                #if DEBUG
                print("🔵 [UserPostRowView struct] VStack 被长按")
                #endif
            }
            
            // 显示图片缩略图（如果有图片）
            if !post.images.isEmpty {
                postThumbnailView
                    .onAppear {
                        #if DEBUG
                        print("🖼️ 显示图片缩略图: 数量 = \(post.images.count), IDs = \(post.images)")
                        #endif
                    }
                    .onTapGesture {
                        #if DEBUG
                        print("🔵 [UserPostRowView struct] 图片缩略图被点击")
                        #endif
                    }
                    .allowsHitTesting(true) // 图片可以点击，但不应该拦截文本区域
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
        .onTapGesture {
            #if DEBUG
            print("🔵 [UserPostRowView struct] HStack 被点击")
            #endif
        }
        .onLongPressGesture {
            #if DEBUG
            print("🔵 [UserPostRowView struct] HStack 被长按")
            #endif
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            if !post.images.isEmpty {
                WeChatStyleImageViewer(
                    images: post.images,
                    initialIndex: selectedImageIndex,
                    isPresented: $showImageViewer
                )
            }
        }
    }
    
    // 图片缩略图视图 - 小缩略图
    private var postThumbnailView: some View {
        let imageCount = post.images.count
        let thumbnailSize: CGFloat = 50  // 缩略图尺寸
        let spacing: CGFloat = 3  // 间距
        
        return Group {
            if imageCount == 1 {
                // 单张图片：小缩略图
                imageView(at: 0, size: thumbnailSize)
            } else if imageCount == 2 {
                // 两张图片：横向排列
                HStack(spacing: spacing) {
                    imageView(at: 0, size: thumbnailSize)
                    imageView(at: 1, size: thumbnailSize)
                }
            } else if imageCount == 3 {
                // 三张图片：横向排列
                HStack(spacing: spacing) {
                    imageView(at: 0, size: thumbnailSize)
                    imageView(at: 1, size: thumbnailSize)
                    imageView(at: 2, size: thumbnailSize)
                }
            } else {
                // 四张及以上：2x2 网格
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        imageView(at: 0, size: thumbnailSize)
                        imageView(at: 1, size: thumbnailSize)
                    }
                    HStack(spacing: spacing) {
                        imageView(at: 2, size: thumbnailSize)
                        if imageCount > 4 {
                            // 显示 +N
                            ZStack {
                                imageView(at: 3, size: thumbnailSize)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.65))
                                Text("+\(imageCount - 4)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: thumbnailSize, height: thumbnailSize)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .onTapGesture {
                                selectedImageIndex = 3
                                showImageViewer = true
                            }
                        } else {
                            imageView(at: 3, size: thumbnailSize)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: thumbnailSize * 2 + spacing)  // 限制最大宽度
    }
    
    // 单个图片视图 - 小缩略图
    private func imageView(at index: Int, size: CGFloat) -> some View {
        Group {
            if index < post.images.count {
                let imageId = post.images[index]
                if imageId.contains("_image_") {
                    // 用户上传的图片
                    PostImageView(
                        imageId: imageId,
                        contentMode: .fill,
                        width: size,
                        height: size,
                        cornerRadius: 4
                    )
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else if let uiImage = UIImage(named: imageId) {
                    // 内置图片资源
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    // 占位图
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: size * 0.3))
                                .foregroundColor(.gray.opacity(0.5))
                        )
                }
            }
        }
        .frame(width: size, height: size)  // 强制限制尺寸
        .onTapGesture {
            selectedImageIndex = index
            showImageViewer = true
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days)天前"
        } else if hours > 0 {
            return "\(hours)小时前"
        } else if minutes > 0 {
            return "\(minutes)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// 网络节点视图（简化版）
struct NetworkNodeView: View {
    let node: MockCharacterNode
    let size: CGFloat
    
    var body: some View {
            ZStack {
                Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.1))
                .frame(width: size, height: size)
                
            Text(String(node.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(DesignSystem.Colors.primary)
        }
    }
            }
            
// 模拟角色节点
struct MockCharacterNode {
    let id: String
    let name: String
}

// 紧凑的点赞记录视图 - 苹果设计风格
// MARK: - 现代化点赞记录卡片
// 苹果式点赞卡片 - 参考通知页面的舒适设计
struct AppleStyleLikeRecordCard: View {
    let record: LikeRecord
    @State private var isExpanded = false
    @State private var showingCancelAlert = false
    var onRemove: (() -> Void)?
    
    private let collapsedContentLength = 150 // 与 UserPostCard 保持一致
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部信息区域 - 苹果式布局
            HStack(alignment: .center, spacing: 12) {
                // 作者头像 - 更大更清晰
                authorAvatar
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(record.authorName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        
                        // 类型标签 - 更精致
                        typeLabel
                        
                        Spacer()
                    }
                    
                    Text(timeAgo(from: record.timestamp))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.48, blue: 0.45))
                }
                
                // 点赞按钮 - 苹果式
                likeButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 内容区域 - 更好的可读性
            VStack(alignment: .leading, spacing: 14) {
                Text(displayContent)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(isExpanded ? nil : 3)
                    .lineSpacing(3)
                    .animation(.easeInOut(duration: 0.25), value: isExpanded)
                
                // 展开/收起按钮 - 苹果式（右侧对齐，紫色，与次元回放一致）
                if shouldShowExpandButton {
                    HStack {
                        Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "收起" : "展开")
                            .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9)) // 梦幻紫，与次元回放一致
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FFD6E8").opacity(0.50),  // 淡玫瑰粉（左侧更纯）
                            Color(hex: "FFE5EC").opacity(0.35),  // 非常淡的玫瑰粉
                            Color(hex: "FFF0F5").opacity(0.22),  // 薰衣草腮红
                            Color.white.opacity(0.12)            // 纯白（右侧更淡）
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FFB6D9").opacity(0.35),  // 玫瑰粉（增强）
                                    Color(hex: "FFD6E8").opacity(0.30),  // 淡玫瑰粉（增强）
                                    Color(hex: "FFE5EC").opacity(0.25),  // 更淡的玫瑰粉（增强）
                                    Color(hex: "FFF0F5").opacity(0.20)   // 薰衣草腮红（增强）
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: Color(hex: "FFB6D9").opacity(0.18), radius: 6, x: 0, y: 2)
        .shadow(color: Color(hex: "FFA3C7").opacity(0.12), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                UIPasteboard.general.string = record.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": "已复制文字"]
                )
            } label: {
                Label("复制文字", systemImage: "doc.on.doc")
            }
        }
        .alert("取消点赞", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                UserLikeService.shared.removeLikeRecord(record)
                onRemove?()
            }
        } message: {
            Text("确定要取消对这条内容的点赞吗？")
        }
    }
    
    // 苹果式头像 - 更大更清晰
    private var authorAvatar: some View {
        // 使用统一的Avatar组件来显示头像
        // 判断是否是用户自己的帖子：如果authorName等于当前用户名，则使用UserProfileManager的头像
        let isUserOwnPost = record.authorName == UserProfileManager.shared.getCurrentUsername()
        
        return Avatar(
            url: isUserOwnPost ? UserProfileManager.shared.getCurrentAvatarURL() : record.authorAvatar,
            name: record.authorName,
            category: isUserOwnPost ? "" : (record.characterName ?? ""),
            size: 44.0
        )
        .overlay(
            Circle()
                .stroke(.quaternary, lineWidth: 0.5)
        )
    }
    
    // 苹果式类型标签
    private var typeLabel: some View {
        Text(record.type == .post ? "动态" : "评论")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(.quaternary.opacity(0.6))
            )
    }
    
    // 苹果式点赞按钮
    private var likeButton: some View {
        Button(action: {
            showingCancelAlert = true
        }) {
            ZStack {
                Circle()
                    .fill(.pink.opacity(0.06))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.pink)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 显示内容（参考 UserPostCard 的智能截断逻辑）
    private var displayContent: String {
        if record.content.count > collapsedContentLength && !isExpanded {
            // 智能截断 - 找到最后一个完整句子或词语
            let truncated = String(record.content.prefix(collapsedContentLength))
            if let lastPunctuation = truncated.lastIndex(where: { "。！？.!?".contains($0) }) {
                return String(truncated[...lastPunctuation])
            } else if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "…"
            }
            return truncated + "…"
        }
        return record.content
    }
    
    // 是否显示展开按钮
    private var shouldShowExpandButton: Bool {
        record.content.count > collapsedContentLength
    }
    
    // 时间格式化函数
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 5 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// 保留原有的ModernLikeRecordCard作为备用
struct ModernLikeRecordCard: View {
    let record: LikeRecord
    @State private var isExpanded = false
    @State private var showingCancelAlert = false
    var onRemove: (() -> Void)?
    
    private let collapsedContentLength = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部信息区域
            HStack(alignment: .center, spacing: 10) {
                // 作者头像
                authorAvatar
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(record.authorName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // 类型标签
                        typeLabel
                        
                        Spacer()
                    }
                    
                    Text(formatChineseTime(record.timestamp))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // 点赞按钮
                likeButton
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // 内容区域
            VStack(alignment: .leading, spacing: 12) {
                Text(displayContent)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 4)
                    .lineSpacing(2)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                
                // 展开/收起按钮
                if shouldShowExpandButton {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "收起" : "展开")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.08), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        .padding(.horizontal, 2)
        .alert("取消点赞", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                UserLikeService.shared.removeLikeRecord(record)
                onRemove?()
            }
        } message: {
            Text("确定要取消对这条内容的点赞吗？")
        }
    }
    
    // 作者头像
    private var authorAvatar: some View {
        // 使用统一的Avatar组件来显示头像
        let isUserOwnPost = record.authorName == UserProfileManager.shared.getCurrentUsername()
        
        return Avatar(
            url: isUserOwnPost ? UserProfileManager.shared.getCurrentAvatarURL() : record.authorAvatar,
            name: record.authorName,
            category: isUserOwnPost ? "" : (record.characterName ?? ""),
            size: 36.0
        )
        .overlay(
            Circle()
                .stroke(.quaternary, lineWidth: 1)
        )
    }
    
    // 类型标签
    private var typeLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: record.type.iconName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(record.type.color)
            
            Text(record.type.displayName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(record.type.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(record.type.color.opacity(0.1))
        )
    }
    
    // 点赞按钮
    private var likeButton: some View {
        Button(action: {
            showingCancelAlert = true
        }) {
            HStack(spacing: 5) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.pink)
                Text("\(record.likeCount)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.5, green: 0.48, blue: 0.45))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.pink.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(.pink.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 计算属性
    private var displayContent: String {
        let contentToDisplay = record.content
        
        if isExpanded {
            return contentToDisplay
        }
        
        if contentToDisplay.count <= collapsedContentLength {
            return contentToDisplay
        }
        
        let truncated = String(contentToDisplay.prefix(collapsedContentLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }
    
    private var shouldShowExpandButton: Bool {
        return record.content.count > collapsedContentLength
    }
    
    // 格式化中文时间
    private func formatChineseTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 5 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// MARK: - 原有的紧凑式点赞记录视图（保留作为备用）
struct CompactLikeRecordView: View {
    let record: LikeRecord
    @State private var isExpanded = false
    @State private var showingCancelAlert = false
    var onRemove: (() -> Void)?
    
    // 内容截断长度
    private let collapsedContentLength = 150
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 作者头像 - 优化设计
            authorAvatar
            
            VStack(alignment: .leading, spacing: 8) {
                // 头部信息行
                HStack(alignment: .center, spacing: 8) {
                    Text(record.authorName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    // 类型标签 - 重新设计
                    typeLabel
                    
                    Spacer()
                    
                    Text(formatChineseTime(record.timestamp))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // 内容 - 更好的排版
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayContent)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 3)
                        .lineSpacing(1)
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    
                    // 展开/收起按钮
                    if shouldShowExpandButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "收起" : "展开")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9))
                        }
                    }
                }
                
                // 底部信息行
                HStack(alignment: .center, spacing: 12) {
                    Spacer()
                    
                    // 取消点赞按钮 - 重新设计
                    Button(action: {
                        showingCancelAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.pink)
                            Text("\(record.likeCount)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.pink.opacity(0.08))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .alert("取消点赞", isPresented: $showingCancelAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                // 执行取消点赞
                UserLikeService.shared.removeLikeRecord(record)
                onRemove?()
            }
        } message: {
            Text("确定要取消对这条内容的点赞吗？")
        }
    }
    
    // 作者头像
    private var authorAvatar: some View {
        Group {
            if UIImage(named: record.authorAvatar) != nil {
                Image(record.authorAvatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.quaternary, lineWidth: 1)
                    )
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(record.authorName.prefix(1)))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // 类型标签
    private var typeLabel: some View {
        HStack(spacing: 3) {
            Image(systemName: record.type.iconName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(record.type.color)
            
            Text(record.type.displayName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(record.type.color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(record.type.color.opacity(0.1))
        )
    }
    
    // 计算属性
    private var displayContent: String {
        // 始终显示内容正文，而不是标题，这样更能体现用户具体点赞了什么
        let contentToDisplay = record.content
        
        if isExpanded {
            return contentToDisplay
        }
        
        if contentToDisplay.count <= collapsedContentLength {
            return contentToDisplay
        }
        
        // 找到最后一个完整的词来截断，避免截断到单词中间
        let truncated = String(contentToDisplay.prefix(collapsedContentLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }
    
    private var shouldShowExpandButton: Bool {
        return record.content.count > collapsedContentLength
    }
    
    // 格式化中文时间
    private func formatChineseTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 5 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// MARK: - 用户动态卡片 - 极简苹果风格设计
struct UserPostCard: View {
    let post: UserPostModel
    @State private var isExpanded = false
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    
    private let collapsedContentLength = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 头部信息区域 - 苹果式极简布局
            HStack(alignment: .top, spacing: 0) {
                // 左上角用户名 - 很小的字体，动态显示当前用户名
                Text(UserProfileManager.shared.getCurrentUsername())
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.8))
                
                Spacer()
                
                // 右上角时间 - 精致的苹果式时间显示
                Text(timeAgo(from: post.datePosted))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 主要内容区域 - 文字是绝对主角
            VStack(alignment: .leading, spacing: 14) {
                Text(displayContent)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .lineLimit(isExpanded ? nil : 3)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .animation(.easeInOut(duration: 0.25), value: isExpanded)
                    .padding(.vertical, 4)
                
                // 图片网格显示
                if !post.images.isEmpty {
                    GeometryReader { geometry in
                        postImagesGrid(availableWidth: geometry.size.width)
                    }
                    .frame(height: calculateGridHeight())
                    .padding(.top, 4)
                }
                
                                 // 展开/收起按钮 - 苹果式（右侧对齐，紫色）
                 if shouldShowExpandButton {
                     HStack {
                         Spacer()
                     Button(action: {
                         withAnimation(.easeInOut(duration: 0.25)) {
                             isExpanded.toggle()
                         }
                     }) {
                         Text(isExpanded ? "收起" : "展开")
                             .font(.system(size: 13, weight: .medium))
                                 .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.9)) // 梦幻紫，与次元回放一致
                         }
                     }
                 }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)  // 保持磨砂玻璃底层
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.systemBackground))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.08),
                            Color.purple.opacity(0.06),
                            Color.pink.opacity(0.05),
                            Color.orange.opacity(0.04)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.15),
                            Color.purple.opacity(0.12),
                            Color.pink.opacity(0.10),
                            Color.orange.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
                .allowsHitTesting(false)
        )
        .shadow(color: Color.blue.opacity(0.08), radius: 3, x: 0, y: 2)
        .shadow(color: Color.purple.opacity(0.05), radius: 1, x: 0, y: 0.5)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                #if DEBUG
                print("🔵 [UserPostCard] contextMenu 按钮被点击，内容: \(post.content.prefix(20))...")
                #endif
                UIPasteboard.general.string = post.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowToast"),
                    object: nil,
                    userInfo: ["message": "已复制文字"]
                )
            } label: {
                Label("复制文字", systemImage: "doc.on.doc")
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            WeChatStyleImageViewer(
                images: post.images,
                initialIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
    }
    
    // 显示内容
    private var displayContent: String {
        if post.content.count > collapsedContentLength && !isExpanded {
            // 智能截断 - 找到最后一个完整句子或词语
            let truncated = String(post.content.prefix(collapsedContentLength))
            if let lastPunctuation = truncated.lastIndex(where: { "。！？.!?".contains($0) }) {
                return String(truncated[...lastPunctuation])
            } else if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "…"
            }
            return truncated + "…"
        }
        return post.content
    }
    
    // 是否显示展开按钮
    private var shouldShowExpandButton: Bool {
        post.content.count > collapsedContentLength
    }
    
    // 图片网格视图 - 微信朋友圈风格
    private func postImagesGrid(availableWidth: CGFloat) -> some View {
        let imageCount = post.images.count
        let spacing: CGFloat = 4
        
        return Group {
            if imageCount == 1 {
                // 单张图片 - 使用3列网格的尺寸
                HStack(spacing: spacing) {
                    squareImageView(imageId: post.images[0], index: 0, size: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing))
                    Spacer()
                }
            } else if imageCount == 2 {
                // 两张图片 - 使用3列网格的尺寸
                HStack(spacing: spacing) {
                    ForEach(0..<2, id: \.self) { index in
                        squareImageView(imageId: post.images[index], index: index, size: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing))
                    }
                    Spacer()
                }
            } else if imageCount == 3 {
                // 三张图片 - 横向排列，正方形
                HStack(spacing: spacing) {
                    ForEach(0..<3, id: \.self) { index in
                        squareImageView(imageId: post.images[index], index: index, size: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing))
                    }
                }
            } else if imageCount == 4 {
                // 四张图片 - 2x2网格
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        squareImageView(imageId: post.images[0], index: 0, size: calculateGridImageSize(availableWidth: availableWidth, columns: 2, spacing: spacing))
                        squareImageView(imageId: post.images[1], index: 1, size: calculateGridImageSize(availableWidth: availableWidth, columns: 2, spacing: spacing))
                    }
                    HStack(spacing: spacing) {
                        squareImageView(imageId: post.images[2], index: 2, size: calculateGridImageSize(availableWidth: availableWidth, columns: 2, spacing: spacing))
                        squareImageView(imageId: post.images[3], index: 3, size: calculateGridImageSize(availableWidth: availableWidth, columns: 2, spacing: spacing))
                    }
                }
            } else if imageCount >= 5 {
                // 五张及以上 - 3列网格，最多显示9张
                let rows = min(Int(ceil(Double(min(imageCount, 9)) / 3.0)), 3)
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<3, id: \.self) { col in
                                let index = row * 3 + col
                                if index < min(imageCount, 9) {
                                    ZStack(alignment: .bottomTrailing) {
                                        squareImageView(imageId: post.images[index], index: index, size: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing))
                                        
                                        // 如果是第9张图片且还有更多图片，显示"+N"标记
                                        if index == 8 && imageCount > 9 {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.black.opacity(0.6))
                                                .overlay(
                                                    Text("+\(imageCount - 9)")
                                                        .font(.system(size: 14, weight: .semibold))
                                                        .foregroundColor(.white)
                                                )
                                                .frame(width: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing), height: calculateGridImageSize(availableWidth: availableWidth, columns: 3, spacing: spacing))
                                        }
                                    }
                                }
                            }
                            // 添加 Spacer 确保左对齐
                            Spacer(minLength: 0)
                        }
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    // 计算网格图片尺寸
    private func calculateGridImageSize(availableWidth: CGFloat, columns: Int, spacing: CGFloat) -> CGFloat {
        // 可用宽度已经通过 GeometryReader 获取，无需再计算
        let totalSpacing = spacing * CGFloat(columns - 1)
        return (availableWidth - totalSpacing) / CGFloat(columns)
    }
    
    // 计算网格高度
    private func calculateGridHeight() -> CGFloat {
        let imageCount = post.images.count
        let spacing: CGFloat = 4
        // 使用屏幕宽度来估算（临时），实际尺寸由 GeometryReader 决定
        let estimatedWidth = UIScreen.main.bounds.width - 24 - 40
        
        if imageCount == 1 || imageCount == 2 || imageCount == 3 {
            return calculateGridImageSize(availableWidth: estimatedWidth, columns: 3, spacing: spacing)
        } else if imageCount == 4 {
            return calculateGridImageSize(availableWidth: estimatedWidth, columns: 2, spacing: spacing) * 2 + spacing
        } else if imageCount >= 5 {
            let rows = min(Int(ceil(Double(min(imageCount, 9)) / 3.0)), 3)
            let imageSize = calculateGridImageSize(availableWidth: estimatedWidth, columns: 3, spacing: spacing)
            return CGFloat(rows) * imageSize + CGFloat(rows - 1) * spacing
        }
        return 0
    }
    
    // 正方形图片视图
    private func squareImageView(imageId: String, index: Int, size: CGFloat) -> some View {
        PostImageView(
            imageId: imageId,
            contentMode: .fill,
            width: size,
            height: size,
            cornerRadius: 3
        )
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(.systemGray6), lineWidth: 0.5)
        )
        .onTapGesture {
            selectedImageIndex = index
            showImageViewer = true
        }
    }
    
    // 单张图片视图
    private func singleImageView(imageId: String, index: Int) -> some View {
        GeometryReader { geometry in
            PostImageView(
                imageId: imageId,
                contentMode: .fit,
                width: geometry.size.width,
                height: min(calculateSingleImageHeight(imageId: imageId, maxWidth: geometry.size.width), 400),
                cornerRadius: 8
            )
        }
        .frame(height: 240)
        .clipped()
        .onTapGesture {
            selectedImageIndex = index
            showImageViewer = true
        }
    }
    
    // 计算单张图片高度
    private func calculateSingleImageHeight(imageId: String, maxWidth: CGFloat) -> CGFloat {
        guard let image = ImageManager.shared.getImage(withId: imageId) else {
            return 240
        }
        let aspectRatio = image.size.height / image.size.width
        let calculatedHeight = maxWidth * aspectRatio
        return min(max(calculatedHeight, 120), 400)
    }
    
    // 苹果式时间格式化函数
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year)年前"
        } else if let month = components.month, month > 0 {
            return "\(month)个月前"
        } else if let week = components.weekOfYear, week > 0 {
            return "\(week)周前"
        } else if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 5 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }
}

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - 用户资料编辑器
struct ProfileEditorView: View {
    @ObservedObject var userProfileManager: UserProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempUsername: String = ""
    @State private var tempPersonalSignature: String = ""

    @State private var showingImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedUIImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 头像编辑区域
                VStack(spacing: 16) {
                    Text("头像")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ZStack {
                        // 头像显示
                        if let avatarImage = userProfileManager.loadAvatarImage() {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // 编辑按钮
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                    .onTapGesture {
                        showingImagePicker = true
                    }
                }
                
                // 用户名编辑区域
                VStack(spacing: 16) {
                    Text("用户名")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("请输入用户名", text: $tempUsername)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // 个性签名编辑区域
                VStack(spacing: 16) {
                    Text("个性签名")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("请输入个性签名", text: $tempPersonalSignature, axis: .vertical)
                        .font(.system(size: 16))
                        .lineLimit(3...6)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                

                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if !tempUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            userProfileManager.updateUsername(tempUsername.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        
                        if !tempPersonalSignature.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            userProfileManager.updatePersonalSignature(tempPersonalSignature.trimmingCharacters(in: .whitespacesAndNewlines))
                        }

                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedImage, matching: .images)
            .onChange(of: selectedImage) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedUIImage = image
                        }
                    }
                }
            }
            .sheet(item: Binding<IdentifiableUIImage?>(
                get: { 
                    if let selectedUIImage = selectedUIImage {
                        return IdentifiableUIImage(image: selectedUIImage)
                    }
                    return nil
                },
                set: { _ in 
                    selectedUIImage = nil 
                }
            )) { identifiableImage in
                AvatarEditorView(
                    image: identifiableImage.image,
                    onSave: { croppedImage in
                        userProfileManager.updateAvatar(croppedImage, name: "user_avatar_\(Date().timeIntervalSince1970)")
                        selectedUIImage = nil
                    },
                    onCancel: {
                        selectedUIImage = nil
                    }
                )
            }
            .onAppear {
                tempUsername = userProfileManager.username
                tempPersonalSignature = userProfileManager.personalSignature
            }
        }
    }
}

// MARK: - 等级系统扩展方法
extension ProfileView {
    
    /// 获取等级描述（用于等级详情页面）
    func getLevelDescription(level: Int) -> String {
        switch level {
        case 1:
            return "刚开始时空冒险的新手，准备探索无限可能"
        case 2:
            return "勇敢的虫洞探险家，开始探索神秘的时空隧道"
        case 3:
            return "熟练的次元旅行者，在不同时空自由穿梭"
        case 4:
            return "真正的时空冒险家，在虫洞中寻找智慧宝藏"
        case 5:
            return "自由的虫洞漫游者，在时空长河中自由探索"
        case 6:
            return "守护次元的守护者，保护时空的和平与秩序"
        case 7:
            return "时空大师，掌握穿越时空的奥秘"
        case 8:
            return "虫洞领主，统治着神秘的虫洞领域"
        case 9:
            return "次元王者，在多元宇宙中称王称霸"
        case 10:
            return "时空传奇，成为跨越时空的永恒传说"
        default:
            return "刚开始时空冒险的新手"
        }
    }
}

// MARK: - 头像编辑器
struct AvatarEditorView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    // 裁切框大小
    private var cropSize: CGFloat {
        UIScreen.main.bounds.width * 0.85
    }
    
    // 计算基础缩放比例，让图片正好填满圆形
    private var baseScale: CGFloat {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return 1.0 }
        let scaleX = cropSize / imageSize.width
        let scaleY = cropSize / imageSize.height
        return max(scaleX, scaleY)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        // 头像预览区域
                        ZStack {
                            // 创建一个将被操作的图片视图
                            let imageView = Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: image.size.width, height: image.size.height)
                            
                            // 背景图片 (半透明)
                            imageView
                                .scaleEffect(baseScale * zoomScale)
                                .offset(offset)
                                .opacity(0.3)
                            
                            // 前景图片 (圆形遮罩内)
                            imageView
                                .scaleEffect(baseScale * zoomScale)
                                .offset(offset)
                                .mask(Circle())
                            
                            // 简单的白色圆形边框
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        }
                        .frame(width: cropSize, height: cropSize)
                        .clipped()
                        .gesture(
                            SimultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    },
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = lastZoomScale * value
                                        zoomScale = max(0.5, min(10.0, newScale))
                                    }
                                    .onEnded { _ in
                                        lastZoomScale = zoomScale
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if zoomScale > 1.0 {
                                    zoomScale = 1.0
                                    offset = .zero
                                } else {
                                    zoomScale = 2.0
                                }
                                lastZoomScale = zoomScale
                                lastOffset = offset
                            }
                        }
                        
                        Spacer()
                        
                        // 操作提示和控制
                        VStack(spacing: 16) {
                            Text("拖动调整位置，双指缩放，双击快速缩放")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            // 缩放滑块
                            VStack(spacing: 8) {
                                HStack {
                                    Text("图片大小")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Spacer()
                                    
                                    Text("\(Int(zoomScale * 100))%")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                
                                // 自定义滑块
                                HStack(spacing: 12) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.6))
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                let newScale = max(0.5, zoomScale - 0.5)
                                                zoomScale = newScale
                                                lastZoomScale = newScale
                                            }
                                        }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geo.size.width * (zoomScale - 0.5) / 9.5, height: 8)
                                            
                                            Circle()
                                                .fill(.blue)
                                                .frame(width: 20, height: 20)
                                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                                                .position(x: geo.size.width * (zoomScale - 0.5) / 9.5, y: 10)
                                                .gesture(
                                                    DragGesture()
                                                        .onChanged { value in
                                                            let percentage = value.location.x / geo.size.width
                                                            let newScale = 0.5 + (percentage * 9.5)
                                                            zoomScale = max(0.5, min(10.0, newScale))
                                                            lastZoomScale = zoomScale
                                                        }
                                                )
                                        }
                                    }
                                    .frame(height: 20)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white.opacity(0.6))
                                        .onTapGesture {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                let newScale = min(10.0, zoomScale + 0.5)
                                                zoomScale = newScale
                                                lastZoomScale = newScale
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )
                            )
                            
                            // 重置按钮
                            Button("重置") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    zoomScale = 1.0
                                    lastZoomScale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("编辑头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        if let croppedImage = cropImage() {
                            onSave(croppedImage)
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                zoomScale = 1.0
                lastZoomScale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
    }
    
    // 裁切图片 - 匹配新的显示逻辑
    private func cropImage() -> UIImage? {
        let finalScale = baseScale * zoomScale
        let imageSize = image.size
        let scaledSize = CGSize(width: imageSize.width * finalScale, height: imageSize.height * finalScale)
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        
        return renderer.image { context in
            // 设置裁切路径为圆形
            let path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: cropSize, height: cropSize))
            path.addClip()
            
            // 计算图片绘制的原点
            let drawOrigin = CGPoint(
                x: (cropSize - scaledSize.width) / 2 + offset.width,
                y: (cropSize - scaledSize.height) / 2 + offset.height
            )
            
            // 绘制图片
            image.draw(in: CGRect(origin: drawOrigin, size: scaledSize))
        }
    }
}

#Preview {
    ProfileView()
} 