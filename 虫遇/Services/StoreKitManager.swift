import Foundation
import StoreKit

final class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()
    @Published var products: [Product] = []
    @Published var isSimulatorFallback = false // 标识是否使用模拟器备用模式
    private override init() {}
    
    // 你的商品ID
    private let productIds: Set<String> = [
        "credits.small",
        "credits.medium",
        "credits.large",
        "credits.xlarge"
    ]
    
    // 备用产品数据 - 当StoreKit无法正常工作时使用
    private let fallbackProducts: [String: (displayName: String, price: String, description: String)] = [
        "credits.small": (
            displayName: "虫币入门包", 
            price: "6", 
            description: "新手体验"
        ),
        "credits.medium": (
            displayName: "虫币标准包", 
            price: "18", 
            description: "日常使用"
        ),
        "credits.large": (
            displayName: "虫币豪华包", 
            price: "38", 
            description: "深度体验"
        ),
        "credits.xlarge": (
            displayName: "虫币至尊包", 
            price: "68", 
            description: "畅享无忧"
        )
    ]
    
    func loadProducts() async {
        // 检查是否在模拟器中运行
        #if targetEnvironment(simulator)
        print("[IAP] ℹ️ 当前运行在模拟器。如未在Scheme的Run→Options绑定.storekit配置文件，将无法从App Store获取真实商品。可选择：1) 绑定.storekit 2) 使用真机+Sandbox账号测试")
        
        // 检查 StoreKit 配置文件是否存在
        if let storeKitPath = Bundle.main.path(forResource: "StoreKit", ofType: "storekit") {
            print("[IAP] ✅ 找到 StoreKit 配置文件: \(storeKitPath)")
            
            // 尝试读取配置文件内容
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: storeKitPath))
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                   let products = dict["products"] as? [[String: Any]] {
                    print("[IAP] 📋 配置文件中包含 \(products.count) 个产品:")
                    for product in products {
                        if let productID = product["productID"] as? String,
                           let displayName = product["referenceName"] as? String {
                            print("[IAP]   - \(productID): \(displayName)")
                        }
                    }
                }
                
                // 检查 Bundle ID 匹配
                if let dict = json as? [String: Any],
                   let configBundleID = dict["identifier"] as? String {
                    let appBundleID = Bundle.main.bundleIdentifier ?? "未知"
                    print("[IAP] 📦 配置文件 Bundle ID: \(configBundleID)")
                    print("[IAP] 📦 应用 Bundle ID: \(appBundleID)")
                    if configBundleID == appBundleID {
                        print("[IAP] ✅ Bundle ID 匹配")
                    } else {
                        print("[IAP] ❌ Bundle ID 不匹配！这可能是问题所在")
                    }
                }
            } catch {
                print("[IAP] ❌ 无法读取 StoreKit 配置文件: \(error)")
            }
        } else {
            print("[IAP] ❌ 未找到 StoreKit 配置文件")
        }
        #else
        print("[IAP] ℹ️ 当前运行在真机")
        #endif
        
        guard AppStore.canMakePayments else {
            print("[IAP] ❌ 设备不支持应用内购买")
            return
        }
        print("[IAP] ✅ 设备支持应用内购买")
        
        do {
            print("[IAP] 🔄 开始请求产品信息...")
            print("[IAP] 📋 请求的产品 IDs: \(Array(productIds).sorted())")
            
            let products = try await Product.products(for: Array(productIds))
            print("[IAP] 成功加载 \(products.count) 个商品")
            
            if products.isEmpty {
                print("[IAP] ⚠️ 没有找到任何商品，可能原因：")
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
                
                // 在模拟器中使用备用方案
                #if targetEnvironment(simulator)
                print("[IAP] 🔄 启用模拟器备用模式，创建本地模拟产品...")
                await createFallbackProducts()
                return
                #endif
            } else {
                for product in products {
                    print("[IAP] 商品: \(product.id) - \(product.displayName) - \(product.displayPrice)")
                }
            }
            
            await MainActor.run { 
                self.products = products
                self.isSimulatorFallback = false
            }
        } catch {
            print("[IAP] ❌ 加载商品失败: \(error)")
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
            
            // 在模拟器中遇到错误时使用备用方案
            #if targetEnvironment(simulator)
            print("[IAP] 🔄 由于错误，启用模拟器备用模式...")
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
        case .unverified(_, let verificationError):
            print("[IAP] ⚠️ 交易验证失败: \(verificationError)")
            throw verificationError
        case .verified(let signedType):
            print("[IAP] ✅ 交易验证成功")
            return signedType
        }
    }
} 