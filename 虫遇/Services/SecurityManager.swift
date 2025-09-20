import Foundation
import LocalAuthentication
import Security
import UIKit

/// 安全管理服务
/// 负责处理设备安全、数据加密、生物识别等安全功能
class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    @Published var isBiometricEnabled = false
    @Published var securityStatus: SecurityStatus = .unknown
    
    private init() {
        checkSecurityStatus()
        loadBiometricSetting()
    }
    
    // MARK: - 安全状态
    
    enum SecurityStatus {
        case secure       // 安全
        case warning      // 警告
        case vulnerable   // 存在风险
        case unknown      // 未知
        
        var description: String {
            switch self {
            case .secure: return "安全"
            case .warning: return "一般"
            case .vulnerable: return "存在风险"
            case .unknown: return "检查中"
            }
        }
        
        var color: UIColor {
            switch self {
            case .secure: return .systemGreen
            case .warning: return .systemOrange
            case .vulnerable: return .systemRed
            case .unknown: return .systemGray
            }
        }
    }
    
    // MARK: - 设备安全检查
    
    /// 检查整体安全状态
    func checkSecurityStatus() {
        DispatchQueue.global(qos: .background).async {
            var riskCount = 0
            
            // 检查设备是否越狱
            if self.isDeviceJailbroken() {
                riskCount += 3
            }
            
            // 检查调试状态
            if self.isBeingDebugged() {
                riskCount += 2
            }
            
            // 检查钥匙串可用性
            if !self.isKeychainAccessible() {
                riskCount += 2
            }
            
            // 检查设备锁屏设置
            if !self.isDeviceLockEnabled() {
                riskCount += 1
            }
            
            DispatchQueue.main.async {
                switch riskCount {
                case 0:
                    self.securityStatus = .secure
                case 1...2:
                    self.securityStatus = .warning
                default:
                    self.securityStatus = .vulnerable
                }
            }
        }
    }
    
    /// 检查设备是否越狱
    private func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // 检查常见的越狱文件和路径
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/Applications/blackra1n.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/IntelliScreen.app",
            "/Applications/MxTube.app",
            "/Applications/RockApp.app",
            "/Applications/SBSettings.app",
            "/Applications/WinterBoard.app"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 检查是否可以写入系统目录
        do {
            let stringToWrite = "jailbreak test"
            try stringToWrite.write(toFile: "/private/test.txt", atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: "/private/test.txt")
            return true
        } catch {
            // 无法写入，设备可能未越狱
        }
        
        return false
        #endif
    }
    
    /// 检查是否正在被调试
    private func isBeingDebugged() -> Bool {
        #if DEBUG
        return true
        #else
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        return (info.kp_proc.p_flag & P_TRACED) != 0
        #endif
    }
    
    /// 检查钥匙串是否可访问
    private func isKeychainAccessible() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SecurityCheck",
            kSecAttrAccount as String: "test",
            kSecValueData as String: Data("test".utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            // 清理测试数据
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "SecurityCheck",
                kSecAttrAccount as String: "test"
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            return true
        }
        
        return false
    }
    
    /// 检查设备锁屏是否启用
    private func isDeviceLockEnabled() -> Bool {
        // 这个检查在真实设备上更准确
        let context = LAContext()
        var error: NSError?
        
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    // MARK: - 生物识别
    
    /// 检查生物识别可用性
    func checkBiometricAvailability() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        
        var description: String {
            switch self {
            case .none: return "不可用"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }
    }
    
    /// 启用/禁用生物识别
    func setBiometricEnabled(_ enabled: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard enabled else {
            // 禁用生物识别
            isBiometricEnabled = false
            UserDefaults.standard.set(false, forKey: "biometric_enabled")
            completion(true, nil)
            return
        }
        
        // 启用生物识别需要验证
        let context = LAContext()
        let reason = "启用生物识别以保护您的账号安全"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isBiometricEnabled = true
                    UserDefaults.standard.set(true, forKey: "biometric_enabled")
                    completion(true, nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "生物识别验证失败"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// 加载生物识别设置
    private func loadBiometricSetting() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
    }
    
    /// 验证生物识别
    func authenticateWithBiometric(reason: String, completion: @escaping (Bool, String?) -> Void) {
        guard isBiometricEnabled else {
            completion(false, "生物识别未启用")
            return
        }
        
        let context = LAContext()
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "验证失败"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - 数据加密
    
    /// 加密敏感数据
    func encryptData(_ data: Data, key: String) -> Data? {
        guard let keyData = key.data(using: .utf8) else { return nil }
        
        let keyBytes = keyData.withUnsafeBytes { bytes in
            return Array(bytes.bindMemory(to: UInt8.self))
        }
        
        var encryptedBytes = [UInt8]()
        let dataBytes = data.withUnsafeBytes { bytes in
            return Array(bytes.bindMemory(to: UInt8.self))
        }
        
        // 简单的XOR加密（实际应用中应使用更强的加密算法）
        for (index, byte) in dataBytes.enumerated() {
            let keyByte = keyBytes[index % keyBytes.count]
            encryptedBytes.append(byte ^ keyByte)
        }
        
        return Data(encryptedBytes)
    }
    
    /// 解密敏感数据
    func decryptData(_ encryptedData: Data, key: String) -> Data? {
        // XOR加密是对称的，解密和加密使用相同算法
        return encryptData(encryptedData, key: key)
    }
    
    // MARK: - 设备信息
    
    /// 获取设备安全信息
    func getDeviceSecurityInfo() -> [String: Any] {
        return [
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "isJailbroken": isDeviceJailbroken(),
            "isDebugging": isBeingDebugged(),
            "biometricType": checkBiometricAvailability().description,
            "securityStatus": securityStatus.description,
            "keychainAccessible": isKeychainAccessible(),
            "deviceLockEnabled": isDeviceLockEnabled()
        ]
    }
    
    /// 生成设备指纹
    func generateDeviceFingerprint() -> String {
        let info = getDeviceSecurityInfo()
        let fingerprint = "\(info["deviceModel"] ?? "")-\(info["systemVersion"] ?? "")-\(UIDevice.current.identifierForVendor?.uuidString ?? "")"
        return fingerprint.sha256()
    }
}

// MARK: - String 扩展

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// 导入CommonCrypto
import CommonCrypto 