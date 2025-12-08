import SwiftUI
import StoreKit

struct PurchaseView: View {
    @StateObject private var storeKitManager = StoreKitManager.shared
    @StateObject private var walletManager = WalletManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var lastPurchaseDetails: PurchaseSuccessDetails?
    @State private var purchaseStatusPhase: PurchaseStatusPhase = .idle
    @State private var purchaseStatusTask: Task<Void, Never>?
    @State private var showSandboxTip = false
    @State private var useSandboxMode = false  // 是否使用 Sandbox 模式（强制弹出登录）
    @State private var pendingProduct: Product?  // 待购买的产品（用于 Sandbox 模式）
    @State private var showSandboxLogin = false  // 显示 Sandbox 登录输入界面
    @State private var sandboxEmail = ""  // Sandbox 账号邮箱
    @State private var sandboxPassword = ""  // Sandbox 账号密码
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                    .ignoresSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        balanceCard
                        purchaseOptionsSection
                        infoSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.white.opacity(0.9))
                }
                ToolbarItem(placement: .principal) {
                    Text("虫洞币充值")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
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
        .alert("充值成功", isPresented: $showSuccess, presenting: lastPurchaseDetails) { _ in
            Button("好的") {
                dismiss()
            }
        } message: { details in
            Text("""
            已到账 \(details.coinAmount) 虫洞币
            订单号：\(details.confirmation.transactionId)
            时间：\(PurchaseView.successDateFormatter.string(from: details.confirmation.purchasedAt))
            """)
        }
        .onAppear {
            // 加载保存的 Sandbox 账号信息
            #if DEBUG
            sandboxEmail = UserDefaults.standard.string(forKey: "sandbox_test_email") ?? ""
            sandboxPassword = UserDefaults.standard.string(forKey: "sandbox_test_password") ?? ""
            #endif
        }
        .onDisappear {
            purchaseStatusTask?.cancel()
        }
        .sheet(isPresented: $showSandboxLogin) {
            sandboxLoginSheet
        }
        .alert("使用 Sandbox 账号购买", isPresented: $showSandboxTip) {
            Button("取消") { 
                #if DEBUG
                useSandboxMode = false
                pendingProduct = nil
                #endif
            }
            Button("打开设置退出 Apple ID") {
                // 打开设置应用
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("已退出，继续购买") {
                #if DEBUG
                // 用户已退出 Apple ID，继续购买流程
                useSandboxMode = false
                if let product = pendingProduct {
                    performPurchase(product: product)
                }
                #endif
            }
        } message: {
            Text("""
            要使用 Sandbox 账号购买，需要先退出设备上的 Apple ID：
            
            📱 操作步骤：
            1. 点击"打开设置退出 Apple ID"
            2. 在设置中：Apple ID → 退出登录
            3. 返回应用，点击"已退出，继续购买"
            4. 点击购买按钮，系统会弹出登录界面
            5. 输入 Sandbox 账号：\(sandboxEmail.isEmpty ? "shilong@tester.com" : sandboxEmail)
            6. 输入密码：\(sandboxPassword.isEmpty ? "（你设置的密码）" : "已保存")
            7. 完成购买
            
            ⚠️ 注意：
            - 退出 Apple ID 后，某些功能可能暂时不可用
            - Sandbox 账号不会扣费
            - 这是测试环境
            """)
        }
    }
    
    private var backgroundLayer: some View {
            ZStack {
            LinearGradient(
                colors: [
                    Color(red: 28/255, green: 18/255, blue: 46/255),
                    Color(red: 8/255, green: 6/255, blue: 18/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
                        RadialGradient(
                            gradient: Gradient(colors: [
                    Color(red: 128/255, green: 65/255, blue: 255/255).opacity(0.35),
                    Color.clear
                            ]),
                center: .topTrailing,
                startRadius: 60,
                endRadius: 420
                        )
            .blendMode(.screen)
            
                Circle()
                    .fill(Color(red: 90/255, green: 60/255, blue: 150/255).opacity(0.28))
                .blur(radius: 150)
                .frame(width: 360, height: 360)
                .offset(x: -140, y: -280)
            
                Circle()
                    .fill(Color(red: 60/255, green: 140/255, blue: 255/255).opacity(0.15))
                    .blur(radius: 150)
                    .frame(width: 320, height: 320)
                    .offset(x: 150, y: 40)
        }
    }
    
    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 18) {
        HStack {
                HStack(spacing: 12) {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("当前虫洞币")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                    if walletManager.isLoading {
                        ProgressView()
                                .tint(.cyan)
                            .scaleEffect(0.8)
                    } else {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(walletManager.formatBalance())
                                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                                    .foregroundColor(.white)
                                Text("枚")
                                    .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            Spacer()
            Button(action: {
                    Task { await walletManager.refreshBalance() }
            }) {
                    Label("刷新", systemImage: "arrow.clockwise")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
            }
            .disabled(walletManager.isLoading)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 92/255, green: 72/255, blue: 210/255).opacity(0.6),
                            Color(red: 52/255, green: 32/255, blue: 120/255).opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var purchaseOptionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("选择套餐")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            if purchaseStatusPhase != .idle {
                purchaseStatusBanner
            }
            
            // 如果有真实产品，显示真实充值选项
            if !storeKitManager.products.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 18),
                    GridItem(.flexible(), spacing: 18)
                ], spacing: 18) {
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
            // 模拟器测试模式：显示测试购买按钮
            else if storeKitManager.isSimulatorFallback {
                #if DEBUG
                #if targetEnvironment(simulator)
                simulatorTestPurchaseView
                #else
                loadingStateView
                #endif
                #else
                loadingStateView
                #endif
            }
            // 加载中状态
            else {
                loadingStateView
            }
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 18) {
                    ProgressView()
                        .tint(.cyan)
            Text("正在连接 App Store...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
                    
            VStack(alignment: .leading, spacing: 6) {
                Label("请确认网络稳定", systemImage: "wifi")
                Label("切换网络或稍后再试", systemImage: "clock")
                Label("如有问题请联系客服", systemImage: "person.crop.circle.badge.questionmark")
            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                Task { await storeKitManager.loadProducts() }
            } label: {
                Text("重试")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 42/255, green: 24/255, blue: 70/255).opacity(0.85),
                            Color(red: 18/255, green: 12/255, blue: 38/255).opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("购买须知")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "seal.fill", text: "Apple 内购安全加密，支付后立即到账")
                InfoRow(icon: "infinity", text: "虫洞币永久有效，支持设备间同步")
                InfoRow(icon: "checkmark.shield", text: "支付异常时，可随时联系客服")
                InfoRow(icon: "doc.text", text: "购买即表示同意《用户协议》与《隐私政策》")
                
                #if DEBUG
                // 测试模式提示
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showSandboxLogin = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.caption)
                            Text(sandboxEmail.isEmpty ? "输入 Sandbox 测试账号" : "Sandbox: \(sandboxEmail)")
                                .font(.caption)
                        }
                        .foregroundColor(sandboxEmail.isEmpty ? .cyan.opacity(0.8) : .green.opacity(0.9))
                    }
                    
                    if !sandboxEmail.isEmpty {
                        Toggle(isOn: $useSandboxMode) {
                            HStack(spacing: 8) {
                                Image(systemName: useSandboxMode ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                Text("使用 Sandbox 账号购买")
                                    .font(.caption)
                            }
                            .foregroundColor(useSandboxMode ? .green.opacity(0.9) : .cyan.opacity(0.8))
                        }
                        .toggleStyle(.button)
                    }
                }
                .padding(.top, 4)
                #endif
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 46/255, green: 28/255, blue: 80/255).opacity(0.88),
                            Color(red: 30/255, green: 18/255, blue: 48/255).opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            )
    }
    
    private func purchaseProduct(_ product: Product) {
        guard !isPurchasing else { return }
        
        #if DEBUG
        // 如果启用了 Sandbox 模式，先提示用户退出 Apple ID
        if useSandboxMode {
            pendingProduct = product  // 保存待购买的产品
            showSandboxTip = true
            return
        }
        #endif
        
        performPurchase(product: product)
    }
    
    private func performPurchase(product: Product? = nil) {
        // 使用待购买的产品，或者传入的产品，或者第一个可用产品
        guard let product = product ?? pendingProduct ?? storeKitManager.products.first else { return }
        guard !isPurchasing else { return }
        
        // 清除待购买的产品
        pendingProduct = nil
        
        isPurchasing = true
        purchaseError = nil
        purchaseStatusPhase = .requesting
        startPurchaseStatusEscalation()
        
        Task {
            do {
                let confirmation = try await storeKitManager.purchase(product)
                await walletManager.refreshBalance()
                await MainActor.run {
                    isPurchasing = false
                    stopPurchaseStatusEscalation()
                    lastPurchaseDetails = PurchaseSuccessDetails(
                        confirmation: confirmation,
                        coinAmount: coinQuantity(for: product.id)
                    )
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    stopPurchaseStatusEscalation()
                    purchaseError = friendlyErrorMessage(for: error)
                    showError = true
                }
            }
        }
    }
    
    #if DEBUG
    // 模拟器测试购买视图
    private var simulatorTestPurchaseView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "testtube.2")
                    .foregroundColor(.yellow.opacity(0.9))
                Text("模拟器测试模式")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            Text("在模拟器中可以直接测试购买，无需真实支付")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 18),
                GridItem(.flexible(), spacing: 18)
            ], spacing: 18) {
                ForEach(Array(storeKitManager.productIds).sorted(), id: \.self) { productId in
                    if let fallbackInfo = storeKitManager.getFallbackProductInfo(for: productId) {
                        FallbackPurchaseOptionCard(
                            productId: productId,
                            displayName: fallbackInfo.displayName,
                            price: fallbackInfo.price,
                            description: fallbackInfo.description,
                            isPurchasing: isPurchasing,
                            onPurchase: {
                                devTopup(productId: productId)
                            }
                        )
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 46/255, green: 28/255, blue: 80/255).opacity(0.88),
                            Color(red: 30/255, green: 18/255, blue: 48/255).opacity(0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    // 开发测试充值（模拟器专用）
    private func devTopup(productId: String) {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        purchaseStatusPhase = .requesting
        
        Task {
            do {
                // 生成模拟交易ID
                let txId = "simulator-test-\(UUID().uuidString)"
                
                // 直接调用后端API确认购买（绕过StoreKit）
                let walletBalance = try await WalletService.shared.confirmPurchase(
                    appAccountToken: AppAccountManager.shared.appAccountToken,
                    productId: productId,
                    transactionId: txId,
                    receipt: nil  // 模拟器测试不需要receipt
                )
                
                await walletManager.refreshBalance()
                
                await MainActor.run {
                    isPurchasing = false
                    purchaseStatusPhase = .idle
                    
                    // 创建模拟的购买确认信息
                    let mockConfirmation = PurchaseConfirmation(
                        transactionId: txId,
                        productId: productId,
                        purchasedAt: Date()
                    )
                    
                    lastPurchaseDetails = PurchaseSuccessDetails(
                        confirmation: mockConfirmation,
                        coinAmount: coinQuantity(for: productId)
                    )
                    showSuccess = true
                }
                
                #if DEBUG
                debugLog("[IAP] ✅ 模拟器测试购买成功: \(productId), 交易ID: \(txId)")
                debugLog("[IAP] 💰 余额更新: \(walletBalance.balance) 虫洞币")
                #endif
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    purchaseStatusPhase = .idle
                    purchaseError = "测试购买失败: \(error.localizedDescription)"
                    showError = true
                }
                #if DEBUG
                debugLog("[IAP] ❌ 模拟器测试购买失败: \(error)")
                #endif
            }
        }
    }
    #endif
    
    /**
     * ⚡️ 优化：生成友好的错误提示，覆盖所有错误类型
     */
    private func friendlyErrorMessage(for error: Error) -> String {
        // 1. StoreKit错误
        if let skError = error as? StoreKitError {
            switch skError {
            case .userCancelled:
                return "已取消支付，未扣款。"
            case .networkError:
                return "网络连接不稳定，请检查网络后重试。"
            case .systemError:
                return "Apple 支付系统暂时不可用，请稍后再试。"
            @unknown default:
                // ⚡️ 修复：StoreKitError可能没有notAvailable等case，使用default处理
                let errorDesc = skError.localizedDescription.lowercased()
                if errorDesc.contains("not available") || errorDesc.contains("不可用") {
                    return "商品暂时不可用，请稍后再试。"
                } else if errorDesc.contains("not entitled") || errorDesc.contains("权限") {
                    return "您没有购买此商品的权限。"
                }
                return "支付遇到未知错误，请稍后重试。"
            }
        }
        
        let nsError = error as NSError
        
        // 2. 自定义IAP错误
        if nsError.domain == "iap" {
            switch nsError.code {
            case 1:
                return "已取消支付，未扣款。"
            case 2:
                return "订单待处理，几分钟内会自动完成，请稍后刷新余额确认。"
            case 3:
                return "支付状态未知，请稍后刷新余额确认。"
            default:
                if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String, !message.isEmpty {
                    return message
                }
            }
        }
        
        // 3. 钱包/后端错误
        if nsError.domain == "wallet.purchase" {
            let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String
            if let message, !message.isEmpty {
                return message
            }
            // 根据HTTP状态码提供更具体的错误信息
            if nsError.code == 402 {
                return "余额不足，请先充值。"
            } else if nsError.code == 403 {
                return "服务暂时不可用，请稍后重试。"
            } else if nsError.code >= 500 {
                return "服务器错误，请稍后重试。如已扣款，请联系客服处理。"
            }
            return "支付已完成，但服务端记账失败，请稍后刷新余额或联系客服处理。"
        }
        
        // 4. 网络错误
        if nsError.domain == NSURLErrorDomain {
            // ⚡️ 修复：使用URLError.Code而不是直接使用Int
            let urlErrorCode = URLError.Code(rawValue: nsError.code)
            switch urlErrorCode {
            case .notConnectedToInternet:
                return "网络未连接，请检查网络后重试。"
            case .networkConnectionLost:
                return "网络连接中断，请检查网络后重试。"
            case .timedOut:
                return "网络请求超时，请确认网络后重试。"
            case .cannotFindHost, .cannotConnectToHost:
                return "无法连接到服务器，请检查网络后重试。"
            case .dnsLookupFailed:
                return "DNS查询失败，请检查网络设置。"
            default:
                return "网络错误，请检查网络后重试。"
            }
        }
        
        // 5. 默认错误
        // 尝试从错误信息中提取有用的信息
        let errorDesc = error.localizedDescription.lowercased()
        if errorDesc.contains("network") || errorDesc.contains("网络") {
            return "网络连接失败，请检查网络后重试。"
        } else if errorDesc.contains("timeout") || errorDesc.contains("超时") {
            return "请求超时，请稍后重试。"
        } else if errorDesc.contains("balance") || errorDesc.contains("余额") {
            return "余额不足，请先充值。"
        }
        
        return "支付未完成，请稍后再试。如已扣款，可联系支持处理。"
    }
    
    private func startPurchaseStatusEscalation() {
        purchaseStatusTask?.cancel()
        purchaseStatusTask = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            await MainActor.run {
                if isPurchasing && purchaseStatusPhase == .requesting {
                    purchaseStatusPhase = .waitingApple
                }
            }
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            await MainActor.run {
                if isPurchasing && purchaseStatusPhase == .waitingApple {
                    purchaseStatusPhase = .takingLong
                }
            }
        }
    }
    
    private func stopPurchaseStatusEscalation() {
        purchaseStatusTask?.cancel()
        purchaseStatusTask = nil
        purchaseStatusPhase = .idle
    }
    
    private var purchaseStatusBanner: some View {
        let config = purchaseStatusConfig
        return HStack(alignment: .top, spacing: 12) {
            if config.showSpinner {
                ProgressView()
                    .tint(.cyan)
            } else {
                Image(systemName: config.iconName)
                    .foregroundStyle(.cyan)
                    .font(.body)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(config.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
                if config.showRefreshButton {
                    Button("刷新余额") {
                        Task { await walletManager.refreshBalance() }
                    }
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white.opacity(0.08))
                    )
                }
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private var purchaseStatusConfig: (title: String, subtitle: String?, iconName: String, showSpinner: Bool, showRefreshButton: Bool) {
        switch purchaseStatusPhase {
        case .idle:
            return ("", nil, "hourglass", false, false)
        case .requesting:
            return ("正在向 Apple 请求支付...", "请在系统弹窗中完成 Face ID/密码确认。", "hourglass", true, false)
        case .waitingApple:
            return ("正在等待 Apple 确认订单", "通常几秒内完成，如已支付请勿关闭此页面。", "hourglass.circle", true, false)
        case .takingLong:
            return ("订单确认时间较长", "如果已看到 Apple 扣款，可点击下方刷新余额确认。", "exclamationmark.triangle", false, true)
        }
    }
    
    private func coinQuantity(for productId: String) -> Int {
        CoinProductInfo.info(for: productId)?.coinAmount ?? 0
    }
    
    private static let successDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    #if DEBUG
    // Sandbox 账号输入界面
    private var sandboxLoginSheet: some View {
        NavigationStack {
            ZStack {
                // 背景
                LinearGradient(
                    colors: [
                        Color(red: 28/255, green: 18/255, blue: 46/255),
                        Color(red: 8/255, green: 6/255, blue: 18/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 说明
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Sandbox 测试账号设置", systemImage: "person.badge.key.fill")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("输入 Sandbox 测试账号信息，购买时会提示使用此账号登录。")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        // 账号输入
                        VStack(alignment: .leading, spacing: 12) {
                            Text("邮箱")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("shilong@tester.com", text: $sandboxEmail)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        
                        // 密码输入
                        VStack(alignment: .leading, spacing: 12) {
                            Text("密码")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            SecureField("输入密码", text: $sandboxPassword)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .foregroundColor(.white)
                        }
                        
                        // 提示信息
                        VStack(alignment: .leading, spacing: 8) {
                            Label("使用说明", systemImage: "info.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("1. 输入 Sandbox 测试账号和密码")
                                Text("2. 开启\"使用 Sandbox 账号购买\"开关")
                                Text("3. 点击购买，系统会弹出登录界面")
                                Text("4. 在登录界面输入上述账号和密码")
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.2))
                        )
                        
                        // 保存按钮
                        Button {
                            // 保存账号信息（可以保存到 UserDefaults）
                            UserDefaults.standard.set(sandboxEmail, forKey: "sandbox_test_email")
                            UserDefaults.standard.set(sandboxPassword, forKey: "sandbox_test_password")
                            showSandboxLogin = false
                        } label: {
                            Text("保存")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(sandboxEmail.isEmpty || sandboxPassword.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                                )
                        }
                        .disabled(sandboxEmail.isEmpty || sandboxPassword.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Sandbox 测试账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showSandboxLogin = false
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                // 加载已保存的账号信息
                sandboxEmail = UserDefaults.standard.string(forKey: "sandbox_test_email") ?? ""
                sandboxPassword = UserDefaults.standard.string(forKey: "sandbox_test_password") ?? ""
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
        let package = CoinProductInfo.info(for: product.id)
        Button(action: onPurchase) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    // 虫洞币数量（主标题）
                    Text(package?.displayCoinText ?? "虫洞币")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // 价格
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    // 用途说明
                    Text(package?.usageDescription ?? "用于解锁更多次元对话功能")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // 用途估算
                    Text(package?.estimatedPostsText ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 120)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: package?.isRecommended == true ? [
                                    Color.orange.opacity(0.15),
                                    Color.purple.opacity(0.08)
                                ] : [
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
                                colors: package?.isRecommended == true ? [
                                    Color.orange.opacity(0.5),
                                    Color.purple.opacity(0.3)
                                ] : [
                                    Color.cyan.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: package?.isRecommended == true ? 1.5 : 1
                        )
                )
                .scaleEffect(isPurchasing ? 0.95 : 1.0)
                .opacity(isPurchasing ? 0.6 : 1.0)
                
                if package?.isRecommended == true {
                    Text("推荐")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: -10, y: -6)
                        .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 2)
                }
            }
        }
        .disabled(isPurchasing)
        .animation(.easeInOut(duration: 0.15), value: isPurchasing)
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
        let package = CoinProductInfo.info(for: productId)
        Button(action: onPurchase) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    // 虫洞币数量（主标题）
                    Text(package?.displayCoinText ?? "虫洞币")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // 价格
                    Text("¥\(price)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    // 产品描述（用途说明）
                    Text(package?.usageDescription ?? "用于解锁更多次元对话功能")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // API请求次数说明
                    Text(package?.estimatedPostsText ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
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
                                colors: package?.isRecommended == true ? [
                                    Color.orange.opacity(0.12),
                                    Color.purple.opacity(0.06)
                                ] : [
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
                                colors: package?.isRecommended == true ? [
                                    Color.orange.opacity(0.4),
                                    Color.purple.opacity(0.25)
                                ] : [
                                    Color.yellow.opacity(0.3),
                                    Color.orange.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: package?.isRecommended == true ? 1.5 : 1
                        )
                )
                .scaleEffect(isPurchasing ? 0.95 : 1.0)
                .opacity(isPurchasing ? 0.6 : 1.0)
                
                // 推荐标签 - 放在右上角外部
                if package?.isRecommended == true {
                    Text("推荐")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: -10, y: -6)
                        .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 2)
                }
            }
        }
        .disabled(isPurchasing)
        .animation(.easeInOut(duration: 0.15), value: isPurchasing)
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
        case "com.lishilong.chongyu.100energy": return "1800币"
        case "com.lishilong.chongyu.300energy": return "6000币"
        case "com.lishilong.chongyu.700energy": return "13800币"
        case "com.lishilong.chongyu.1400energy": return "24000币"
        default: return ""
        }
    }
}

private enum PurchaseStatusPhase {
    case idle
    case requesting
    case waitingApple
    case takingLong
}

private struct PurchaseSuccessDetails {
    let confirmation: PurchaseConfirmation
    let coinAmount: Int
}

private struct CoinProductInfo: Equatable {
    let productId: String
    let coinAmount: Int
    let usageDescription: String
    let estimatedPosts: Int
    let isRecommended: Bool
    
    var displayCoinText: String {
        let amount = CoinProductInfo.numberFormatter.string(from: NSNumber(value: coinAmount)) ?? "\(coinAmount)"
        return "\(amount) 虫洞币"
    }
    
    var estimatedPostsText: String {
        "可生成约\(estimatedPosts)篇动态"
    }
    
    static func info(for productId: String) -> CoinProductInfo? {
        all.first { $0.productId == productId }
    }
    
    private static let all: [CoinProductInfo] = [
        .init(
            productId: "com.lishilong.chongyu.100energy",
            coinAmount: 1800,
            usageDescription: "适合轻度使用",
            estimatedPosts: 70,
            isRecommended: false
        ),
        .init(
            productId: "com.lishilong.chongyu.300energy",
            coinAmount: 6000,
            usageDescription: "性价比之选",
            estimatedPosts: 240,
            isRecommended: true
        ),
        .init(
            productId: "com.lishilong.chongyu.700energy",
            coinAmount: 13800,
            usageDescription: "深度体验",
            estimatedPosts: 550,
            isRecommended: false
        ),
        .init(
            productId: "com.lishilong.chongyu.1400energy",
            coinAmount: 24000,
            usageDescription: "无限探索",
            estimatedPosts: 1000,
            isRecommended: false
        )
    ]
    
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter
    }()
}


#Preview {
    PurchaseView()
} 