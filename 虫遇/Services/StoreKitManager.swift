import Foundation
import StoreKit

final class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    @Published var products: [Product] = []
    private override init() {}
    
    // 你的商品ID
    private let productIds: Set<String> = [
        "credits.small",
        "credits.medium",
        "credits.large",
        "credits.xlarge"
    ]
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: Array(productIds))
            await MainActor.run { self.products = products }
        } catch {
            print("[IAP] 加载商品失败: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase(options: [.appAccountToken(UUID(uuidString: AppAccountManager.shared.appAccountToken) ?? UUID())])
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handle(transaction)
            await transaction.finish()
        case .userCancelled:
            throw NSError(domain: "iap", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户取消"])
        case .pending:
            throw NSError(domain: "iap", code: 2, userInfo: [NSLocalizedDescriptionKey: "待处理"])
        @unknown default:
            throw NSError(domain: "iap", code: 3, userInfo: [NSLocalizedDescriptionKey: "未知状态"])            
        }
    }
    
    private func handle(_ transaction: Transaction) async {
        let txId = String(transaction.id)
        let productId = transaction.productID
        do {
            _ = try await WalletService.shared.confirmPurchase(
                appAccountToken: AppAccountManager.shared.appAccountToken,
                productId: productId,
                transactionId: txId,
                receipt: nil
            )
        } catch {
            print("[IAP] 确认购买失败: \(error)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "iap", code: 4, userInfo: [NSLocalizedDescriptionKey: "交易未验证"])
        case .verified(let safe):
            return safe
        }
    }
} 