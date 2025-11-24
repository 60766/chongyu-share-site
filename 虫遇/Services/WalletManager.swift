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
        isLoading = true
        Task {
            do {
                #if DEBUG
                print("💰 [WalletManager] 开始加载余额...")
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
    
    private func setupAccountObservers() {
        let center = NotificationCenter.default
        
        // 账号变更：刷新余额
        let activeNames: [Notification.Name] = [.userAccountRestored, .userAccountCreated, .userAccountTokenReplaced]
        activeNames.forEach { name in
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                self?.loadBalance()
                }
            }
            notificationObservers.append(token)
        }
        
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