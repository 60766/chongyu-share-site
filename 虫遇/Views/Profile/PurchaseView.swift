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
            
            if storeKitManager.products.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.cyan)
                    Text("加载充值选项中...")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(height: 100)
                
                #if DEBUG
                VStack(spacing: 12) {
                    Text("开发者调试充值（本地后端）")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                    HStack(spacing: 12) {
                        Button("+1200") { devTopup(productId: "credits.small") }
                            .buttonStyle(.borderedProminent)
                        Button("+3200") { devTopup(productId: "credits.medium") }
                            .buttonStyle(.borderedProminent)
                        Button("+7800") { devTopup(productId: "credits.large") }
                            .buttonStyle(.borderedProminent)
                        Button("+16000") { devTopup(productId: "credits.xlarge") }
                            .buttonStyle(.borderedProminent)
                    }
                }
                #endif
            } else {
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
                Text(product.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(product.displayPrice)
                    .foregroundColor(.white.opacity(0.8))
                Text("\(product.id)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
        }
        .disabled(isPurchasing)
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

#Preview {
    PurchaseView()
} 