import Foundation
import os.log

/**
 * 统一的日志工具
 * 在DEBUG模式下输出日志，在RELEASE模式下不输出
 */
struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.chongyuai.app"
    
    // 网络相关日志
    static let network = OSLog(subsystem: subsystem, category: "Network")
    
    // UI相关日志
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    
    // 数据相关日志
    static let data = OSLog(subsystem: subsystem, category: "Data")
    
    // 业务逻辑日志
    static let business = OSLog(subsystem: subsystem, category: "Business")
    
    // 调试日志
    static let debug = OSLog(subsystem: subsystem, category: "Debug")
    
    /**
     * 调试日志（仅在DEBUG模式下输出）
     */
    static func debug(_ message: String, log: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: log, type: .debug, logMessage)
        #endif
    }
    
    /**
     * 信息日志（仅在DEBUG模式下输出）
     */
    static func info(_ message: String, log: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: log, type: .info, logMessage)
        #endif
    }
    
    /**
     * 警告日志（仅在DEBUG模式下输出）
     */
    static func warning(_ message: String, log: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: log, type: .default, logMessage)
        #endif
    }
    
    /**
     * 错误日志（始终输出，但只在DEBUG模式下包含详细信息）
     */
    static func error(_ message: String, error: Error? = nil, log: OSLog = .default, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        #if DEBUG
        if let error = error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        os_log("%{public}@", log: log, type: .error, logMessage)
        #else
        // 生产环境：只记录错误，不输出详细信息
        os_log("%{public}@", log: log, type: .error, message)
        #endif
    }
    
    /**
     * 简单的print替代（兼容现有代码）
     * 仅在DEBUG模式下输出
     */
    #if DEBUG
    static func debugLog(_ message: String, log: OSLog = .default) {
        os_log("%{public}@", log: log, type: .debug, message)
    }
    #endif
}

