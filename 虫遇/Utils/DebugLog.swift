import Foundation

/// 统一的调试日志函数：仅在 DEBUG 编译下输出，Release 静默
func debugLog(_ message: @autoclosure () -> Any,
              file: String = #file,
              function: String = #function,
              line: Int = #line) {
    #if DEBUG
    let fileName = (file as NSString).lastPathComponent
    print("[\(fileName):\(line)] \(function) - \(message())")
    #endif
}

