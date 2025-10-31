import SwiftUI
import StoreKit

struct PurchaseView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.05, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 标题区域
                        headerSection
                        
                        // 当前余额显示
                        balanceCard
                        
                        // 充值选项
                        purchaseOptionsSection
                        
                        // 说明文本
                        infoSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("虫洞币充值")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            await storeKitManager.loadProducts()
        }
        .alert("充值失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(purchaseError ?? "未知错误")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 钻石图标
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.3),
                                Color.purple.opacity(0.3)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "diamond.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyan)
            }
            
            Text("获取更多虫洞币")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("用于解锁更多次元对话功能")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var balanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("当前余额")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    if walletManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.cyan)
                    } else {
                        Text(walletManager.formatBalance())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        
                        Text("虫洞币")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await walletManager.refreshBalance()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .disabled(walletManager.isLoading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var purchaseOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("充值选项")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // 如果是模拟器备用模式，显示模拟充值选项
            if storeKitManager.isSimulatorFallback {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text("模拟器模式")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(["credits.small", "credits.medium", "credits.large", "credits.xlarge"], id: \.self) { productId in
                            if let productInfo = storeKitManager.getFallbackProductInfo(for: productId) {
                                FallbackPurchaseOptionCard(
                                    productId: productId,
                                    displayName: productInfo.displayName,
                                    price: productInfo.price,
                                    description: productInfo.description,
                                    isPurchasing: isPurchasing,
                                    onPurchase: {
                                        #if DEBUG
                                        devTopup(productId: productId)
                                        #endif
                                    }
                                )
                            }
                        }
                    }
                    
                    Text("⚠️ 模拟器环境下的测试充值")
                        .font(.caption2)
                        .foregroundColor(.yellow.opacity(0.8))
                }
            }
            // 如果有真实产品，显示真实充值选项
            else if !storeKitManager.products.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(storeKitManager.products.sorted(by: { $0.price < $1.price }), id: \.id) { product in
                        PurchaseOptionCard(
                            product: product,
                            isPurchasing: isPurchasing,
                            onPurchase: {
                                purchaseProduct(product)
                            }
                        )
                    }
                }
            }
            // 加载中状态
            else {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                    ProgressView()
                        .tint(.cyan)
                    Text("加载充值选项中...")
                        .foregroundColor(.white.opacity(0.7))
                }
                    
                    VStack(spacing: 8) {
                        Text("如果加载失败，可能是因为：")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("• App Store Connect未配置商品")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("• 需要真实设备测试")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("• StoreKit配置文件未正确应用")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Button("重新加载") {
                        Task {
                            print("[IAP] 用户点击重新加载，开始重新加载产品...")
                            await storeKitManager.loadProducts()
                            print("[IAP] 重新加载完成，产品数量: \(storeKitManager.products.count)")
                        }
                    }
                    .foregroundColor(.cyan)
                    .font(.caption)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.1))
                    )
                }
                .frame(height: 160)
                .padding()
                
                #if DEBUG
                VStack(spacing: 12) {
                    Text("开发者调试信息")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    
                    VStack(spacing: 4) {
                        Text("Bundle ID: \(Bundle.main.bundleIdentifier ?? "未知")")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("产品数量: \(storeKitManager.products.count)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("AppStore支持: \(AppStore.canMakePayments ? "是" : "否")")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        Text("模拟器备用模式: \(storeKitManager.isSimulatorFallback ? "是" : "否")")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        #if targetEnvironment(simulator)
                        Text("运行环境: 模拟器（需要.storekit配置或改用真机+Sandbox）")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.7))
                        #else
                        Text("运行环境: 真机")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                        #endif
                    }
                    
                    Text("开发者调试充值（本地后端）")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        DevPurchaseButton(title: "+1800", productId: "credits.small", isPurchasing: isPurchasing) {
                            devTopup(productId: "credits.small")
                        }
                        DevPurchaseButton(title: "+6000", productId: "credits.medium", isPurchasing: isPurchasing) {
                            devTopup(productId: "credits.medium")
                        }
                        DevPurchaseButton(title: "+13800", productId: "credits.large", isPurchasing: isPurchasing) {
                            devTopup(productId: "credits.large")
                        }
                        DevPurchaseButton(title: "+26800", productId: "credits.xlarge", isPurchasing: isPurchasing) {
                            devTopup(productId: "credits.xlarge")
                        }
                    }
                    
                    if isPurchasing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("充值中...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                #endif
            }
        }
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("充值说明")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(icon: "checkmark.circle", text: "虫洞币用于次元对话功能")
                InfoRow(icon: "checkmark.circle", text: "支持Apple Pay安全支付")
                InfoRow(icon: "checkmark.circle", text: "充值后立即到账")
                InfoRow(icon: "checkmark.circle", text: "永久有效，不会过期")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
    }
    
    private func purchaseProduct(_ product: Product) {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        purchaseError = nil
        
        Task {
            do {
                try await storeKitManager.purchase(product)
                await walletManager.refreshBalance()
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseError = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    #if DEBUG
    private func devTopup(productId: String) {
        guard !isPurchasing else { return }
        isPurchasing = true
        Task {
            do {
                let txId = "dev-" + UUID().uuidString
                _ = try await WalletService.shared.confirmPurchase(
                    appAccountToken: AppAccountManager.shared.appAccountToken,
                    productId: productId,
                    transactionId: txId,
                    receipt: nil
                )
                await walletManager.refreshBalance()
                await MainActor.run { isPurchasing = false }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseError = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    #endif
}

struct PurchaseOptionCard: View {
    let product: Product
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 12) {
                // 产品名称
                Text(product.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 价格
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cyan)
                
                // 产品描述
                Text(productDescription(for: product.id))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // 产品ID（调试用）
                #if DEBUG
                Text("\(product.id)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                #endif
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
            )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.3),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPurchasing ? 0.95 : 1.0)
            .opacity(isPurchasing ? 0.6 : 1.0)
        }
        .disabled(isPurchasing)
        .animation(.easeInOut(duration: 0.15), value: isPurchasing)
    }
    
    private func productDescription(for productId: String) -> String {
        switch productId {
        case "credits.small": return "新手体验\n1800 虫洞币"
        case "credits.medium": return "日常使用\n6000 虫洞币"
        case "credits.large": return "深度体验\n13800 虫洞币"
        case "credits.xlarge": return "畅享无忧\n26800 虫洞币"
        default: return "虫洞币充值包"
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct FallbackPurchaseOptionCard: View {
    let productId: String
    let displayName: String
    let price: String
    let description: String
    let isPurchasing: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            VStack(spacing: 12) {
                // 产品名称
                Text(displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 价格
                Text("¥\(price)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.cyan)
                
                // 产品描述
                Text(productDescription(for: productId))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // 模拟器标识
                HStack(spacing: 4) {
                    Image(systemName: "testtube.2")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("测试模式")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.08),
                                Color.orange.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPurchasing ? 0.95 : 1.0)
            .opacity(isPurchasing ? 0.6 : 1.0)
        }
        .disabled(isPurchasing)
        .animation(.easeInOut(duration: 0.15), value: isPurchasing)
    }
    
    private func productDescription(for productId: String) -> String {
        switch productId {
        case "credits.small": return "适合轻度使用\n1800 虫洞币"
        case "credits.medium": return "性价比之选\n6000 虫洞币"
        case "credits.large": return "深度体验\n13800 虫洞币"
        case "credits.xlarge": return "无限探索\n26800 虫洞币"
        default: return "虫洞币充值包"
        }
    }
}

struct DevPurchaseButton: View {
    let title: String
    let productId: String
    let isPurchasing: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(productName(for: productId))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPurchasing ? 0.95 : 1.0)
            .opacity(isPurchasing ? 0.6 : 1.0)
        }
        .disabled(isPurchasing)
        .animation(.easeInOut(duration: 0.15), value: isPurchasing)
    }
    
    private func productName(for productId: String) -> String {
        switch productId {
        case "credits.small": return "小包"
        case "credits.medium": return "中包"
        case "credits.large": return "大包"
        case "credits.xlarge": return "超值包"
        default: return ""
        }
    }
}

#Preview {
    PurchaseView()
} 