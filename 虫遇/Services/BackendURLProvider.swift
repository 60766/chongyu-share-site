import Foundation

/**
 * 统一管理应用的后端基础地址。
 *
 * 优先级（从高到低）：
 * 1. 运行时环境变量 `BACKEND_BASE_URL`
 * 2. `Info.plist` 中的 `BACKEND_BASE_URL`
 * 3. `UserDefaults` 保存的 `BackendBaseURL`
 *
 * - DEBUG 构建允许 HTTP 地址（用于内网/临时联调）
 * - RELEASE 构建仅接受 HTTPS，防止上线时意外配置到不安全地址
 * - 若未提供任何覆盖地址，统一回退到 `https://api.chongyuai.com`
 */
enum BackendURLProvider {
    private static var cachedURL: URL?
    
    /// 生产环境默认地址：通过 Caddy + HTTPS 反向代理的正式域名
    private static let fallbackURL = "https://api.chongyuai.com"
    
    static func resolvedURL() -> URL {
        if let cachedURL {
            return cachedURL
        }
        let url = computeResolvedURL()
        cachedURL = url
        return url
    }
    
    static func resolvedString() -> String {
        return resolvedURL().absoluteString
    }
    
    // MARK: - Private
    
    private static func computeResolvedURL() -> URL {
        let candidates: [String?] = [
            ProcessInfo.processInfo.environment["BACKEND_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String,
            UserDefaults.standard.string(forKey: "BackendBaseURL")
        ]
        
        for candidate in candidates {
            guard let raw = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty,
                  let url = URL(string: raw) else {
                continue
            }
            
            #if DEBUG
            print("🌐 [BackendURLProvider] 使用覆盖地址: \(url.absoluteString)")
            return url
            #else
            if url.scheme?.lowercased() == "https" {
                #if DEBUG
                print("🌐 [BackendURLProvider] 使用覆盖地址: \(url.absoluteString)")
                #endif
                return url
            } else {
                print("⚠️ [BackendURLProvider] 忽略非HTTPS地址: \(url.absoluteString)")
            }
            #endif
        }
        
        let fallback = URL(string: fallbackURL)!
        #if DEBUG
        print("🌐 [BackendURLProvider] 使用默认地址: \(fallback.absoluteString)")
        #endif
        return fallback
    }
}

