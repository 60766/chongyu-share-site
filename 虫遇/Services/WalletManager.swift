import Foundation
import SwiftUI

@MainActor
class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var balance: Int = 0
    @Published var currency: String = "虫洞币"
    @Published var isLoading: Bool = false
    @Published var showingPurchaseSheet: Bool = false
    
    private init() {
        loadBalance()
    }
    
    func loadBalance() {
        isLoading = true
        Task {
            do {
                let walletBalance = try await WalletService.shared.fetchBalance()
                await MainActor.run {
                    self.balance = walletBalance.balance
                    self.currency = walletBalance.currency
                    self.isLoading = false
                }
            } catch {
                print("加载余额失败: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshBalance() async {
        await MainActor.run { isLoading = true }
        do {
            let walletBalance = try await WalletService.shared.fetchBalance()
            await MainActor.run {
                self.balance = walletBalance.balance
                self.currency = walletBalance.currency
                self.isLoading = false
            }
        } catch {
            print("刷新余额失败: \(error)")
            await MainActor.run {
                self.isLoading = false
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
} 