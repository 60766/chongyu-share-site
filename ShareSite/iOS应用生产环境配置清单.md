# iOS应用生产环境配置清单

## 🎯 总览

**后端状态**: ✅ 已就绪  
**Bundle ID**: `com.lishilong.chongyu`  
**服务器**: `http://121.40.184.29:3000`

---

## ✅ 后端已完成

### 1. Product ID配置
所有Product ID已在后端配置并测试通过：

| Product ID | 能量值 | 价格 | 状态 |
|------------|--------|------|------|
| `com.lishilong.chongyu.100energy` | 1800 | ¥6 | ✅ |
| `com.lishilong.chongyu.300energy` | 6000 | ¥18 | ✅ |
| `com.lishilong.chongyu.700energy` | 13800 | ¥38 | ✅ |
| `com.lishilong.chongyu.1400energy` | 26800 | ¥68 | ✅ |

### 2. API端点
| 端点 | 状态 | 说明 |
|------|------|------|
| `/health` | ✅ | 健康检查 |
| `/balance` | ✅ | 余额查询 |
| `/purchase/confirm` | ✅ | 购买确认 |
| `/account/link-apple` | ✅ | Apple ID关联 |

---

## 📱 iOS应用端需要检查的配置

### 1. Info.plist 配置

检查 `虫遇/Info.plist` 中的Bundle ID：
```xml
<key>CFBundleIdentifier</key>
<string>com.lishilong.chongyu</string>
```

或在Xcode中：
1. 选择项目 → 虫遇 target
2. General → Identity
3. Bundle Identifier: `com.lishilong.chongyu`

### 2. Product ID配置检查

在 `StoreManager.swift` 或相关文件中，确认Product ID：

```swift
// ✅ 正确的格式（与后端一致）
let productIds = [
    "com.lishilong.chongyu.100energy",   // ¥6 = 100能量
    "com.lishilong.chongyu.300energy",   // ¥18 = 300能量
    "com.lishilong.chongyu.700energy",   // ¥38 = 700能量
    "com.lishilong.chongyu.1400energy"   // ¥68 = 1400能量
]

// ❌ 错误的格式（如果存在，需要修改）
// "credits.small", "credits.medium", 等
```

### 3. 后端URL配置

检查 `NetworkManager.swift` 或API配置文件：

```swift
// 生产环境
let baseURL = "http://121.40.184.29:3000"

// 或者使用环境变量
#if PRODUCTION
let baseURL = "http://121.40.184.29:3000"
#else
let baseURL = "http://localhost:3000" // 开发环境
#endif
```

### 4. Signing & Capabilities

1. 在Xcode中选择项目 → Signing & Capabilities
2. 确认Team: `李世龙 (个人团队)`
3. 确认Signing Certificate已配置
4. 确认 **In-App Purchase** capability已添加

### 5. Scheme配置

确认Release配置用于生产环境：
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration → Release（用于生产）
3. Archive → Build Configuration → Release

---

## 🔍 iOS代码检查点

### 购买流程相关文件

需要检查的关键文件（如果存在）：

1. **StoreManager.swift** / **IAPManager.swift**
   - [ ] Product ID列表
   - [ ] 购买确认API调用
   - [ ] Receipt验证逻辑

2. **NetworkManager.swift** / **APIService.swift**
   - [ ] 后端URL配置
   - [ ] `/purchase/confirm` 端点
   - [ ] 请求参数格式

3. **Models/Product.swift** 或类似
   - [ ] Product数据模型
   - [ ] Price显示逻辑

### 典型的购买确认API调用

应该是这样的格式：

```swift
func confirmPurchase(
    appAccountToken: String,
    productId: String,
    transactionId: String,
    receipt: String?
) async throws -> BalanceResponse {
    let endpoint = "/purchase/confirm"
    let body: [String: Any] = [
        "appAccountToken": appAccountToken,
        "productId": productId,           // ← 这里应该是 com.lishilong.chongyu.XXXenergy
        "transactionId": transactionId,
        "receipt": receipt ?? ""
    ]
    
    return try await post(endpoint, body: body)
}
```

---

## 🚀 App Store Connect配置

### 1. 创建IAP产品

在 [App Store Connect](https://appstoreconnect.apple.com) 中：

1. 进入 **App 内购买项目**
2. 创建4个 **消耗型项目**：

| Reference Name | Product ID | Price |
|----------------|------------|-------|
| 100能量包 | `com.lishilong.chongyu.100energy` | ¥6 |
| 300能量包 | `com.lishilong.chongyu.300energy` | ¥18 |
| 700能量包 | `com.lishilong.chongyu.700energy` | ¥38 |
| 1400能量包 | `com.lishilong.chongyu.1400energy` | ¥68 |

### 2. 产品描述示例

**100能量包**：
- 显示名称：100能量包
- 描述：获得100点穿越能量，开启奇妙的时空对话

**300能量包**：
- 显示名称：300能量包（推荐）
- 描述：获得300点穿越能量，畅享更多精彩对话

**700能量包**：
- 显示名称：700能量包（超值）
- 描述：获得700点穿越能量，深度体验时空穿越

**1400能量包**：
- 显示名称：1400能量包（至尊）
- 描述：获得1400点穿越能量，尽享无限可能

### 3. 税务和银行信息

确保已配置：
- [ ] 付款和财务报告（银行账户）
- [ ] 税务表单
- [ ] 合同、税务和银行业务

---

## 🧪 测试流程

### 1. 本地测试（模拟器/真机）

```bash
# 1. 启动后端（如果需要本地测试）
cd backend
npm start

# 2. 在Xcode中运行应用
# 3. 尝试购买流程
```

### 2. StoreKit测试

在Xcode中：
1. Product → Scheme → Edit Scheme
2. Run → Options
3. StoreKit Configuration → 选择或创建 .storekit 文件

### 3. TestFlight测试

1. Archive应用
2. 上传到App Store Connect
3. 创建TestFlight测试组
4. 使用沙盒账号测试IAP

---

## 📋 上线前检查清单

### 代码层面
- [ ] Bundle ID: `com.lishilong.chongyu`
- [ ] Product IDs: `com.lishilong.chongyu.XXXenergy`
- [ ] 后端URL: `http://121.40.184.29:3000`
- [ ] Build Configuration: Release
- [ ] Code Signing配置正确

### App Store Connect
- [ ] 创建所有4个IAP产品
- [ ] 配置产品价格和描述
- [ ] 税务和银行信息完整
- [ ] 应用元数据和截图

### 后端
- [x] 生产环境配置部署 ✅
- [x] Product ID支持 ✅
- [x] API测试通过 ✅
- [x] 服务器稳定运行 ✅

### 测试
- [ ] StoreKit本地测试通过
- [ ] TestFlight沙盒测试通过
- [ ] 端到端购买流程验证
- [ ] Receipt验证（如需要）

---

## 🔧 快速测试命令

### 测试后端API
```bash
cd "/Users/lishilong/IOS开发/虫遇/虫遇"
./test_production_api.sh
```

### 查看服务器状态
```bash
./check_server_status.exp
```

### 部署后端更新
```bash
# 部署server.js
./deploy_server.exp

# 部署配置文件
./deploy_production_auto.exp
```

---

## 📞 问题排查

### Product ID不匹配
**症状**: 购买失败，返回 "unknown productId"  
**解决**: 
1. 检查iOS代码中的Product ID
2. 运行 `./test_production_api.sh` 查看后端支持的Product ID
3. 确保格式完全一致（包含Bundle ID前缀）

### 网络请求失败
**症状**: 无法连接到后端  
**解决**:
1. 检查后端URL配置
2. 运行 `curl http://121.40.184.29:3000/health` 测试连接
3. 查看服务器日志: `./check_server_status.exp`

### Receipt验证失败
**症状**: 购买成功但能量未到账  
**解决**:
1. 当前为MVP模式，不验证receipt
2. 检查 `appAccountToken` 是否正确传递
3. 查看服务器日志中的 `[IAP]` 标签

---

## 🎯 下一步行动

1. **立即**: 检查iOS代码中的Product ID配置
2. **今天**: 在App Store Connect中创建IAP产品
3. **本周**: 完成StoreKit测试和TestFlight测试
4. **提交前**: 完成所有检查清单项目

---

**文档版本**: 1.0  
**最后更新**: 2025-10-31  
**维护者**: 开发团队

