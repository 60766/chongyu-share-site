import Foundation
import SwiftUI

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var balance: Int = 0
    @Published var currency: String = "虫洞币"
    @Published var isLoading: Bool = false
    @Published var showingPurchaseSheet: Bool = false
    
    private var notificationObservers: [NSObjectProtocol] = []
    
    private init() {
        loadBalance()
        setupAccountObservers()
    }
    
    func loadBalance() {
        // 如果未登录 Apple ID，不加载余额（切换账号后的新 token 不应该自动加载余额）
        // 这样可以避免后端为新账号自动创建账户并赠送币
        if !AppleSignInManager.shared.isSignedIn {
            print("💰 [WalletManager] 未登录 Apple ID，不加载余额，保持为0")
            isLoading = false
            balance = 0
            return
        }
        
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
                }
            } catch {
                // 保留错误日志，对生产环境很重要
                print("❌ [WalletManager] 加载余额失败: \(error)")
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
    
    func showPurchaseSheet() {
        showingPurchaseSheet = true
    }
    
    func formatBalance() -> String {
        return "\(balance)"
    }
    
    func formatBalanceWithCurrency() -> String {
        return "\(balance) \(currency)"
    }
    
    /// 更新余额（内部方法，会检查测试模式和登录状态）
    /// 如果设置了测试余额，或未登录 Apple ID，则不会更新
    func updateBalance(_ newBalance: Int, currency: String? = nil) {
        // 如果未登录 Apple ID，不更新余额（切换账号后的新 token 不应该更新余额）
        if !AppleSignInManager.shared.isSignedIn {
            print("💰 [WalletManager] 未登录 Apple ID，忽略余额更新，保持为0")
            return
        }
        
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
        
        // 账号变更：刷新余额（但需要检查是否已登录）
        let activeNames: [Notification.Name] = [.userAccountRestored, .userAccountTokenReplaced]
        activeNames.forEach { name in
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                self?.loadBalance()
                }
            }
            notificationObservers.append(token)
        }
        
        // 新账号创建：只有在已登录 Apple ID 时才加载余额
        let accountCreated = center.addObserver(forName: .userAccountCreated, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                // 检查是否已登录 Apple ID，只有登录后才加载余额
                // 如果是切换账号后的新 token（未登录），不加载余额
                if AppleSignInManager.shared.isSignedIn {
                    self?.loadBalance()
                } else {
                    // 未登录，保持余额为0
                    self?.balance = 0
                    self?.isLoading = false
                    print("💰 [WalletManager] 新账号创建但未登录，余额保持为0")
                }
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
    }
    
    deinit {
        let center = NotificationCenter.default
        for obs in notificationObservers {
            center.removeObserver(obs)
        }
        notificationObservers.removeAll()
    }
} 