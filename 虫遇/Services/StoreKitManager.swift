import Foundation
import StoreKit

struct PurchaseConfirmation {
    let transactionId: String
    let productId: String
    let purchasedAt: Date
}

final class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    @Published var products: [Product] = []
    @Published var isSimulatorFallback = false // 标识是否使用模拟器备用模式
    private var transactionListenerTask: Task<Void, Never>?
    private override init() {
        super.init()
        transactionListenerTask = Task { [weak self] in
            await self?.listenForTransactions()
        }
    }
    
    // 商品ID - 生产环境配置
    // Bundle ID: com.lishilong.chongyu
    private let productIds: Set<String> = [
        "com.lishilong.chongyu.100energy",   // ¥6 = 1800虫洞币
        "com.lishilong.chongyu.300energy",   // ¥18 = 6000虫洞币
        "com.lishilong.chongyu.700energy",   // ¥38 = 13800虫洞币
        "com.lishilong.chongyu.1400energy"   // ¥68 = 24000虫洞币
    ]
    
    // 备用产品数据 - 当StoreKit无法正常工作时使用
    private let fallbackProducts: [String: (displayName: String, price: String, description: String)] = [
        "com.lishilong.chongyu.100energy": (
            displayName: "1800虫洞币", 
            price: "6", 
            description: "适合轻度使用"
        ),
        "com.lishilong.chongyu.300energy": (
            displayName: "6000虫洞币", 
            price: "18", 
            description: "性价比之选"
        ),
        "com.lishilong.chongyu.700energy": (
            displayName: "13800虫洞币", 
            price: "38", 
            description: "深度体验"
        ),
        "com.lishilong.chongyu.1400energy": (
            displayName: "24000虫洞币", 
            price: "68", 
            description: "无限探索"
        )
    ]
    
    func loadProducts() async {
        // 检查是否在模拟器中运行
        #if targetEnvironment(simulator)
        #if DEBUG
        print("[IAP] ℹ️ 当前运行在模拟器。如未在Scheme的Run→Options绑定.storekit配置文件，将无法从App Store获取真实商品。可选择：1) 绑定.storekit 2) 使用真机+Sandbox账号测试")
        #endif
        
        // 检查 StoreKit 配置文件是否存在
        if let storeKitPath = Bundle.main.path(forResource: "StoreKit", ofType: "storekit") {
            #if DEBUG
            print("[IAP] ✅ 找到 StoreKit 配置文件: \(storeKitPath)")
            #endif
            
            // 尝试读取配置文件内容
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: storeKitPath))
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                   let products = dict["products"] as? [[String: Any]] {
                    #if DEBUG
                    print("[IAP] 📋 配置文件中包含 \(products.count) 个产品:")
                    for product in products {
                        if let productID = product["productID"] as? String,
                           let displayName = product["referenceName"] as? String {
                            print("[IAP]   - \(productID): \(displayName)")
                        }
                    }
                    #endif
                }
                
                // 检查 Bundle ID 匹配
                if let dict = json as? [String: Any],
                   let configBundleID = dict["identifier"] as? String {
                    let appBundleID = Bundle.main.bundleIdentifier ?? "未知"
                    #if DEBUG
                    print("[IAP] 📦 配置文件 Bundle ID: \(configBundleID)")
                    print("[IAP] 📦 应用 Bundle ID: \(appBundleID)")
                    #endif
                    if configBundleID != appBundleID {
                        print("[IAP] ❌ Bundle ID 不匹配！这可能是问题所在")
                    }
                }
            } catch {
                print("[IAP] ❌ 无法读取 StoreKit 配置文件: \(error)")
            }
        } else {
            #if DEBUG
            print("[IAP] ❌ 未找到 StoreKit 配置文件")
            #endif
        }
        #endif
        
        guard AppStore.canMakePayments else {
            print("[IAP] ❌ 设备不支持应用内购买")
            return
        }
        #if DEBUG
        print("[IAP] ✅ 设备支持应用内购买")
        #endif
        
        do {
            #if DEBUG
            print("[IAP] 🔄 开始请求产品信息...")
            print("[IAP] 📋 请求的产品 IDs: \(Array(productIds).sorted())")
            #endif
            
            let products = try await Product.products(for: Array(productIds))
            #if DEBUG
            print("[IAP] 成功加载 \(products.count) 个商品")
            #endif
            
            if products.isEmpty {
                print("[IAP] ⚠️ 没有找到任何商品")
                #if DEBUG
                print("[IAP] 可能原因：")
                print("[IAP] 1. App Store Connect中未配置这些Product ID")
                print("[IAP] 2. Bundle ID不匹配")
                print("[IAP] 3. 开发者账号Team ID不正确")
                print("[IAP] 4. 商品状态未设置为'Ready for Sale'")
                print("[IAP] 5. StoreKit 配置文件未正确加载")
                print("[IAP] 当前Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
                print("[IAP] 期望的Product IDs: \(Array(productIds).sorted())")
                
                // 额外的调试信息
                print("[IAP] 📊 StoreKit 环境检查:")
                print("[IAP] - AppStore.canMakePayments: \(AppStore.canMakePayments)")
                print("[IAP] - 产品请求是否成功: 是（但返回空数组）")
                
                // 尝试单个产品请求
                print("[IAP] 🔍 尝试单个产品请求测试:")
                for productId in productIds.prefix(2) {
                    do {
                        let singleProducts = try await Product.products(for: [productId])
                        print("[IAP]   - \(productId): 找到 \(singleProducts.count) 个产品")
                    } catch {
                        print("[IAP]   - \(productId): 请求失败 - \(error)")
                    }
                }
                #endif
                
                // 在模拟器中使用备用方案
                #if targetEnvironment(simulator)
                print("[IAP] 🔄 启用模拟器备用模式，创建本地模拟产品...")
                await createFallbackProducts()
                return
                #endif
            } else {
                #if DEBUG
                for product in products {
                    print("[IAP] 商品: \(product.id) - \(product.displayName) - \(product.displayPrice)")
                }
                #endif
            }
            
            await MainActor.run { 
                self.products = products
                self.isSimulatorFallback = false
            }
        } catch {
            print("[IAP] ❌ 加载商品失败: \(error)")
            #if DEBUG
            print("[IAP] 错误详情: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("[IAP] 错误域: \(nsError.domain), 错误代码: \(nsError.code)")
                print("[IAP] 用户信息: \(nsError.userInfo)")
            }
            
            // 分析常见错误
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .networkError:
                    print("[IAP] 💡 可能解决方案: 检查网络连接")
                case .systemError:
                    print("[IAP] 💡 可能解决方案: 重启模拟器或设备")
                case .userCancelled:
                    print("[IAP] 💡 用户取消了操作")
                default:
                    print("[IAP] 💡 未知的StoreKit错误: \(storeKitError)")
                }
            } else if let nsError = error as NSError? {
                if nsError.domain == "SKErrorDomain" {
                    switch nsError.code {
                    case 0:
                        print("[IAP] 💡 SKError: 未知错误")
                    case 1:
                        print("[IAP] 💡 SKError: 客户端无效")
                    case 2:
                        print("[IAP] 💡 SKError: 支付被取消")
                    case 3:
                        print("[IAP] 💡 SKError: 支付无效")
                    case 4:
                        print("[IAP] 💡 SKError: 支付未授权")
                    case 5:
                        print("[IAP] 💡 SKError: 产品不可用")
                    default:
                        print("[IAP] 💡 SKError 代码: \(nsError.code)")
                    }
                }
            }
            #endif
            
            // 在模拟器中遇到错误时使用备用方案
            #if targetEnvironment(simulator)
            #if DEBUG
            print("[IAP] 🔄 由于错误，启用模拟器备用模式...")
            #endif
            await createFallbackProducts()
            #endif
        }
    }
    
    // 创建备用的模拟产品（仅用于模拟器测试）
    @MainActor
    private func createFallbackProducts() async {
        print("[IAP] 📱 创建模拟器备用产品...")
        
        // 注意：这里我们不能创建真实的Product对象，因为它们是系统创建的
        // 我们需要修改UI来处理这种情况
        isSimulatorFallback = true
        products = [] // 保持空数组，但设置fallback标志
        
        print("[IAP] ✅ 模拟器备用模式已启用，UI将显示测试充值按钮")
    }
    
    // 获取备用产品信息
    func getFallbackProductInfo(for productId: String) -> (displayName: String, price: String, description: String)? {
        return fallbackProducts[productId]
    }
    
    func purchase(_ product: Product) async throws -> PurchaseConfirmation {
        // 使用 .suppressSystemSuccessCompletion 选项来避免系统自动显示成功提示
        let result = try await product.purchase(options: [
            .appAccountToken(UUID(uuidString: AppAccountManager.shared.appAccountToken) ?? UUID())
        ])
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // 先处理交易，确保服务端确认成功再结束交易，避免损失
            try await handle(transaction)
            await transaction.finish()
            return PurchaseConfirmation(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                purchasedAt: transaction.purchaseDate
            )
        case .userCancelled:
            throw NSError(domain: "iap", code: 1, userInfo: [NSLocalizedDescriptionKey: "用户取消"])
        case .pending:
            throw NSError(domain: "iap", code: 2, userInfo: [NSLocalizedDescriptionKey: "待处理"])
        @unknown default:
            throw NSError(domain: "iap", code: 3, userInfo: [NSLocalizedDescriptionKey: "未知状态"])            
        }
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction: Transaction = try checkVerified(result)
                try await handle(transaction)
                await transaction.finish()
            } catch {
                print("[IAP] 交易监听处理失败: \(error)")
            }
        }
    }
    
    private func handle(_ transaction: Transaction) async throws {
        let txId = String(transaction.id)
        let productId = transaction.productID
        let receiptJSON: String? = String(data: transaction.jsonRepresentation, encoding: .utf8)
        do {
            _ = try await WalletService.shared.confirmPurchase(
                appAccountToken: AppAccountManager.shared.appAccountToken,
                productId: productId,
                transactionId: txId,
                receipt: receiptJSON
            )
        } catch {
            print("[IAP] 确认购买失败: \(error)")
            throw error
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let verificationError):
            print("[IAP] ⚠️ 交易验证失败: \(verificationError)")
            throw verificationError
        case .verified(let signedType):
            #if DEBUG
            print("[IAP] ✅ 交易验证成功")
            #endif
            return signedType
        }
    }
} 