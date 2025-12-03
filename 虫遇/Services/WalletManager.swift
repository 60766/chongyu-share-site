import Foundation
import SwiftUI
import Combine

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var balance: Int = 0
    @Published var currency: String = "虫洞币"
    @Published var isLoading: Bool = false
    @Published var showingPurchaseSheet: Bool = false
    
    private var notificationObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()
    private var hasLoadedBalance = false // 标记是否已经加载过余额
    
    private init() {
        setupAccountObservers()
        setupAppleSignInObserver()
        // 延迟加载余额，等待AppleSignInManager初始化完成
        // 因为AppleSignInManager的checkAppleSignInStatus是异步的
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadBalanceIfNeeded()
        }
    }
    
    /// 设置Apple ID登录状态监听
    /// 当Apple ID登录时，刷新余额（确保显示最新数据）
    private func setupAppleSignInObserver() {
        // 使用Combine监听AppleSignInManager的isSignedIn变化
        // 当用户登录Apple ID时，刷新余额（确保显示最新数据）
        AppleSignInManager.shared.$isSignedIn
            .dropFirst() // 跳过初始值
            .sink { [weak self] isSignedIn in
                #if DEBUG
                print("💰 [WalletManager] Apple ID登录状态变化: \(isSignedIn)")
                #endif
                if isSignedIn {
                    // 如果登录了，刷新余额（确保显示最新数据）
                    #if DEBUG
                    print("💰 [WalletManager] Apple ID已登录，刷新余额")
                    #endif
                    self?.loadBalance()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 如果需要，加载余额（检查登录状态）
    private func loadBalanceIfNeeded() {
        // 如果已经加载过，不再重复加载
        if hasLoadedBalance {
            return
        }
        
        // 直接加载余额，不检查Apple ID登录状态
        // 因为后端不要求Apple ID登录，只要有appAccountToken就可以查询余额
        #if DEBUG
        print("💰 [WalletManager] 延迟检查：加载余额（不要求Apple ID登录）")
        #endif
        loadBalance()
    }
    
    func loadBalance() {
        // 允许未登录Apple ID的用户也能使用虫洞币
        // 后端不要求Apple ID登录，只要有appAccountToken就可以查询余额
        // Apple ID登录主要用于账号恢复功能，不是使用虫洞币的前提条件
        
        isLoading = true
        Task {
            do {
                #if DEBUG
                print("💰 [WalletManager] 开始加载余额...")
                // 测试模式：如果设置了测试余额，直接使用测试余额
                if let testBalance = UserDefaults.standard.object(forKey: "DEBUG_TEST_BALANCE") as? Int {
                    await MainActor.run {
                        self.balance = testBalance
                        self.currency = "虫洞币"
                        self.isLoading = false
                    }
                    print("🧪 [测试模式] 使用测试余额: \(testBalance)")
                    return
                }
                #endif
                let walletBalance = try await WalletService.shared.fetchBalance()
                await MainActor.run {
                    self.balance = walletBalance.balance
                    self.currency = walletBalance.currency
                    self.isLoading = false
                    self.hasLoadedBalance = true // 标记已加载
                    #if DEBUG
                    print("💰 [WalletManager] 余额加载成功: \(walletBalance.balance) 虫洞币")
                    #endif
                }
            } catch {
                // 错误日志：使用Logger记录，生产环境也会记录
                Logger.error("加载余额失败", error: error, log: Logger.business)
                #if DEBUG
                if let urlError = error as? URLError {
                    print("   URLError code: \(urlError.code.rawValue)")
                    print("   URLError: \(urlError.localizedDescription)")
                }
                #endif
                await MainActor.run {
                    self.isLoading = false
                    // 保持余额为 0，不更新
                }
            }
        }
    }
    
    func refreshBalance() async {
        loadBalance()
    }
    
    /// 强制加载余额（不检查Apple ID登录状态，用于账号恢复场景）
    private func forceLoadBalance() {
        isLoading = true
        Task {
            do {
                #if DEBUG
                print("💰 [WalletManager] 强制加载余额（账号恢复）...")
                // 测试模式：如果设置了测试余额，直接使用测试余额
                if let testBalance = UserDefaults.standard.object(forKey: "DEBUG_TEST_BALANCE") as? Int {
                    await MainActor.run {
                        self.balance = testBalance
                        self.currency = "虫洞币"
                        self.isLoading = false
                    }
                    print("🧪 [测试模式] 使用测试余额: \(testBalance)")
                    return
                }
                #endif
                let walletBalance = try await WalletService.shared.fetchBalance()
                await MainActor.run {
                    self.balance = walletBalance.balance
                    self.currency = walletBalance.currency
                    self.isLoading = false
                    self.hasLoadedBalance = true // 标记已加载
                }
                #if DEBUG
                print("💰 [WalletManager] 账号恢复后余额加载成功: \(walletBalance.balance) 虫洞币")
                #endif
            } catch {
                Logger.error("账号恢复后余额加载失败", error: error, log: Logger.business)
                await MainActor.run {
                    self.isLoading = false
                    // 保持余额为 0，不更新
                }
            }
        }
    }
    
    func showPurchaseSheet() {
        showingPurchaseSheet = true
    }
    
    func formatBalance() -> String {
        return "\(balance)"
    }
    
    func formatBalanceWithCurrency() -> String {
        return "\(balance) \(currency)"
    }
    
    /// 更新余额（内部方法，会检查测试模式）
    /// 如果设置了测试余额，则不会更新
    func updateBalance(_ newBalance: Int, currency: String? = nil) {
        #if DEBUG
        // 如果设置了测试余额，不更新
        if UserDefaults.standard.object(forKey: "DEBUG_TEST_BALANCE") as? Int != nil {
            print("🧪 [测试模式] 忽略余额更新，保持测试余额")
            return
        }
        #endif
        self.balance = newBalance
        if let currency = currency {
            self.currency = currency
        }
    }
    
    /// 测试方法：临时设置余额（仅用于调试）
    /// 设置后会立即生效，并在下次加载时使用测试余额
    #if DEBUG
    func setTestBalance(_ amount: Int) {
        UserDefaults.standard.set(amount, forKey: "DEBUG_TEST_BALANCE")
        balance = amount
        print("🧪 [测试] 余额已设置为: \(amount)")
    }
    
    /// 清除测试余额，恢复从服务器获取
    func clearTestBalance() {
        UserDefaults.standard.removeObject(forKey: "DEBUG_TEST_BALANCE")
        loadBalance() // 重新加载真实余额
        print("🧪 [测试] 已清除测试余额，恢复从服务器获取")
    }
    #endif
    
    private func setupAccountObservers() {
        let center = NotificationCenter.default
        
        // 账号恢复：恢复账号时应该加载余额（即使未登录Apple ID，因为这是用户主动恢复的账号）
        let accountRestored = center.addObserver(forName: .userAccountRestored, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                // 账号恢复时，强制加载余额（不检查Apple ID登录状态）
                // 因为这是用户主动恢复的账号，应该显示余额
                self?.forceLoadBalance()
            }
        }
        notificationObservers.append(accountRestored)
        
        // 账号切换：刷新余额（但需要检查是否已登录）
        let accountReplaced = center.addObserver(forName: .userAccountTokenReplaced, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                self?.loadBalance()
                }
            }
        notificationObservers.append(accountReplaced)
        
        // 新账号创建：加载余额（不要求Apple ID登录）
        let accountCreated = center.addObserver(forName: .userAccountCreated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                // 新账号创建时，加载余额（不要求Apple ID登录）
                // 后端会根据deviceId判断是否赠送新用户虫洞币
                #if DEBUG
                print("💰 [WalletManager] 新账号创建，加载余额")
                #endif
                    self?.loadBalance()
            }
        }
        notificationObservers.append(accountCreated)
        
        // 退出账号：重置展示状态
        let logout = center.addObserver(forName: .userAccountLogout, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
            guard let self = self else { return }
            self.isLoading = false
            self.balance = 0
            self.showingPurchaseSheet = false
            }
        }
        notificationObservers.append(logout)
        
        // 监听Apple ID登录状态变化（使用KVO或Combine）
        // 当Apple ID登录状态变为true时，自动刷新余额
        // 注意：由于AppleSignInManager的isSignedIn是@Published，我们需要通过其他方式监听
        // 这里我们监听应用进入前台时刷新余额
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            #if DEBUG
            print("💰 [WalletManager] 应用进入前台，刷新余额")
            #endif
            self?.loadBalance()
        }
    }
    
    deinit {
        let center = NotificationCenter.default
        for obs in notificationObservers {
            center.removeObserver(obs)
        }
        notificationObservers.removeAll()
    }
} 