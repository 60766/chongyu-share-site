import Foundation
import SwiftUI

/// iCloud备份服务
/// 负责将用户数据备份到iCloud Drive
class iCloudBackupService: ObservableObject {
    static let shared = iCloudBackupService()
    
    private let backupDirectoryName = "虫遇备份"
    private let maxBackupCount = 2 // 保留最新2个备份（防止换设备时覆盖旧设备备份）
    
    private init() {}
    
    // MARK: - iCloud可用性检查
    
    /// 检查iCloud是否可用
    var isiCloudAvailable: Bool {
        // 检查是否在模拟器上
        #if targetEnvironment(simulator)
        // 模拟器上iCloud可能不可用，但仍然返回true让用户尝试
        return true
        #else
        if let _ = FileManager.default.ubiquityIdentityToken {
            return true
        }
        return false
        #endif
    }
    
    /// 获取iCloud Drive URL
    private func getiCloudDriveURL() -> URL? {
        // 首先检查iCloud是否可用
        guard FileManager.default.ubiquityIdentityToken != nil else {
            #if DEBUG
            print("⚠️ [iCloud] ubiquityIdentityToken 为 nil")
            print("   请检查：1. 是否登录iCloud  2. 是否开启iCloud Drive")
            #endif
            return nil
        }
        
        // 尝试获取iCloud容器URL（使用默认容器）
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            #if DEBUG
            print("❌ [iCloud] 无法获取iCloud容器URL")
            print("   请检查Xcode中iCloud容器配置")
            #endif
            return nil
        }
        
        // 确保Documents目录存在
        let documentsURL = iCloudURL.appendingPathComponent("Documents", isDirectory: true)
        
        // 检查Documents目录是否存在，如果不存在则创建
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
                print("✅ [iCloud] 创建Documents目录成功")
            } catch {
                print("❌ [iCloud] 创建Documents目录失败: \(error.localizedDescription)")
                return nil
            }
        }
        
        return documentsURL
    }
    
    /// 获取备份目录URL
    private func getBackupDirectoryURL() -> URL? {
        guard let documentsURL = getiCloudDriveURL() else {
            return nil
        }
        return documentsURL.appendingPathComponent(backupDirectoryName, isDirectory: true)
    }
    
    // MARK: - 备份操作
    
    /// 保存备份到iCloud Drive
    /// - Parameters:
    ///   - data: 要备份的数据字典
    ///   - completion: 完成回调，返回成功/失败和文件路径
    func saveBackupToiCloud(data: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        // 检查iCloud可用性
        guard isiCloudAvailable else {
            print("❌ [iCloud] iCloud不可用")
            completion(.failure(iCloudBackupError.iCloudNotAvailable))
            return
        }
        
        // 在后台线程执行，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            // 获取备份目录URL
            guard let backupDirURL = self.getBackupDirectoryURL() else {
                print("❌ [iCloud] 无法获取备份目录URL")
                DispatchQueue.main.async {
                    completion(.failure(iCloudBackupError.cannotCreateDirectory))
                }
                return
            }
            
            print("📁 [iCloud] 备份目录路径: \(backupDirURL.path)")
            
            // 确保目录存在
            let fileManager = FileManager.default
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: backupDirURL.path, isDirectory: &isDirectory)
            
            if !exists || !isDirectory.boolValue {
                do {
                    try fileManager.createDirectory(at: backupDirURL, withIntermediateDirectories: true, attributes: nil)
                    print("✅ [iCloud] 创建备份目录成功: \(backupDirURL.path)")
                } catch {
                    print("❌ [iCloud] 创建备份目录失败: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
            } else {
                print("✅ [iCloud] 备份目录已存在")
            }
            
            // 生成文件名（带时间戳）
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let fileName = "虫遇备份_\(timestamp).json"
            var fileURL = backupDirURL.appendingPathComponent(fileName)
            
            print("💾 [iCloud] 准备保存文件: \(fileName)")
            
            // 将数据转换为JSON
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                
                // 写入文件，使用.atomic确保原子性
                try jsonData.write(to: fileURL, options: [.atomic, .completeFileProtection])
                
                // 设置文件属性，标记为不备份到iCloud（避免重复）
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = false
                try? fileURL.setResourceValues(resourceValues)
                
                print("✅ [iCloud] 文件保存成功: \(fileURL.path)")
                
                // ⚠️ 重要：备份成功后再清理旧备份（确保只保留1个）
                // 这样即使新备份失败，旧备份还在，更安全
                self.cleanupOldBackups(in: backupDirURL)
                
                DispatchQueue.main.async {
                    completion(.success(fileURL.path))
                }
            } catch {
                print("❌ [iCloud] 保存文件失败: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// 异步保存备份到iCloud Drive
    func saveBackupToiCloudAsync(data: [String: Any]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            saveBackupToiCloud(data: data) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - 备份管理
    
    /// 读取备份文件内容
    func loadBackup(from file: BackupFile) -> [String: Any]? {
        let fileManager = FileManager.default
        
        // 检查文件是否存在
        guard fileManager.fileExists(atPath: file.url.path) else {
            print("❌ [恢复] 备份文件不存在: \(file.url.path)")
            return nil
        }
        
        // 读取文件内容
        guard let data = try? Data(contentsOf: file.url) else {
            print("❌ [恢复] 无法读取备份文件: \(file.url.path)")
            return nil
        }
        
        // 解析JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [恢复] 备份文件格式无效: \(file.url.path)")
            return nil
        }
        
        print("✅ [恢复] 成功读取备份文件: \(file.fileName)")
        return json
    }
    
    /// 获取所有备份文件
    func getAllBackups() -> [BackupFile] {
        guard let backupDirURL = getBackupDirectoryURL() else {
            return []
        }
        
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: backupDirURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: []) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> BackupFile? in
                guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                      let fileSize = attributes[.size] as? Int64,
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }
                
                return BackupFile(
                    url: url,
                    fileName: url.lastPathComponent,
                    fileSize: fileSize,
                    creationDate: creationDate
                )
            }
            .sorted { $0.creationDate > $1.creationDate } // 最新的在前
    }
    
    /// 删除指定备份
    func deleteBackup(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
    
    /// 清理旧备份，只保留最新的2个
    /// 保留2个的原因：防止换设备时，新设备创建备份会覆盖旧设备备份
    /// 这样用户可以在新设备上恢复旧设备的数据
    /// 
    /// ⚠️ 注意：由于 iCloud Drive 是同步存储，删除操作会同步到云端
    /// 这意味着删除的备份会从所有设备中移除，无法恢复
    /// 建议用户定期手动检查备份，避免自动清理删除重要备份
    private func cleanupOldBackups(in directory: URL) {
        let backups = getAllBackups()
        
        // 如果已有备份超过2个，删除多余的旧备份（只保留最新的2个）
        if backups.count > maxBackupCount {
            // 跳过最新的2个，删除其他的
            let backupsToDelete = backups.dropFirst(maxBackupCount)
            for backup in backupsToDelete {
                do {
                    // ⚠️ 警告：此操作会从本地和云端同时删除
                    // 由于 iCloud Drive 的同步特性，无法实现"只删本地不删云端"
                    try FileManager.default.removeItem(at: backup.url)
                    print("🗑️ [iCloud] 已删除旧备份: \(backup.fileName)（本地和云端都已删除）")
                } catch {
                    print("⚠️ [iCloud] 删除旧备份失败: \(backup.fileName), 错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 自动备份
    
    /// 获取备份频率（天数）
    var backupFrequencyDays: Int {
        let frequency = UserDefaults.standard.integer(forKey: "iCloudBackupFrequencyDays")
        if frequency > 0 {
            // 如果之前设置的是旧的默认值7天，自动迁移到新的默认值3天
            if frequency == 7 && !UserDefaults.standard.bool(forKey: "iCloudBackupFrequencyMigrated") {
                UserDefaults.standard.set(3, forKey: "iCloudBackupFrequencyDays")
                UserDefaults.standard.set(true, forKey: "iCloudBackupFrequencyMigrated")
                return 3
            }
            return frequency
        }
        return 3 // 默认3天（平衡安全性和性能）
    }
    
    /// 设置备份频率（天数）
    func setBackupFrequency(days: Int) {
        UserDefaults.standard.set(days, forKey: "iCloudBackupFrequencyDays")
    }
    
    /// 获取上次备份时间
    var lastBackupDate: Date? {
        return UserDefaults.standard.object(forKey: "lastiCloudBackupDate") as? Date
    }
    
    /// 获取下次备份时间
    var nextBackupDate: Date? {
        guard let lastBackup = lastBackupDate else {
            return nil
        }
        return Calendar.current.date(byAdding: .day, value: backupFrequencyDays, to: lastBackup)
    }
    
    /// 获取备份状态
    enum BackupStatus {
        case notEnabled
        case neverBackedUp
        case upToDate
        case needsBackup
        case backupFailed
    }
    
    var backupStatus: BackupStatus {
        guard UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") else {
            return .notEnabled
        }
        
        // 检查是否有备份失败标记
        if UserDefaults.standard.bool(forKey: "iCloudBackupLastFailed") {
            return .backupFailed
        }
        
        guard let lastBackupDate = lastBackupDate else {
            return .neverBackedUp
        }
        
        let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 0
        if daysSinceBackup >= backupFrequencyDays {
            return .needsBackup
        }
        
        return .upToDate
    }
    
    /// 检查是否需要自动备份
    /// - Returns: 是否需要备份
    func shouldAutoBackup() -> Bool {
        guard UserDefaults.standard.bool(forKey: "iCloudAutoBackupEnabled") else {
            return false
        }
        
        // 检查上次备份时间
        if let lastBackupDate = lastBackupDate {
            let daysSinceBackup = Calendar.current.dateComponents([.day], from: lastBackupDate, to: Date()).day ?? 0
            // 如果距离上次备份超过设定天数，需要备份
            return daysSinceBackup >= backupFrequencyDays
        }
        
        // 如果从未备份过，需要备份
        return true
    }
    
    /// 执行自动备份
    func performAutoBackup(data: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        guard shouldAutoBackup() else {
            completion(.failure(iCloudBackupError.backupNotNeeded))
            return
        }
        
        saveBackupToiCloud(data: data) { result in
            if case .success = result {
                // 更新上次备份时间
                UserDefaults.standard.set(Date(), forKey: "lastiCloudBackupDate")
                // 清除失败标记
                UserDefaults.standard.set(false, forKey: "iCloudBackupLastFailed")
                // 发送备份成功通知
                NotificationCenter.default.post(name: NSNotification.Name("iCloudBackupSucceeded"), object: nil)
            } else {
                // 标记备份失败
                UserDefaults.standard.set(true, forKey: "iCloudBackupLastFailed")
                // 发送备份失败通知
                NotificationCenter.default.post(name: NSNotification.Name("iCloudBackupFailed"), object: nil, userInfo: ["error": result])
            }
            completion(result)
        }
    }
}

// MARK: - 备份文件模型

struct BackupFile {
    let url: URL
    let fileName: String
    let fileSize: Int64
    let creationDate: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: creationDate)
    }
}

// MARK: - 错误类型

enum iCloudBackupError: LocalizedError {
    case iCloudNotAvailable
    case cannotCreateDirectory
    case backupNotNeeded
    case fileWriteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud不可用，请确保已登录iCloud并开启iCloud Drive"
        case .cannotCreateDirectory:
            return "无法创建备份目录。请检查：\n1. 是否已登录iCloud\n2. 是否开启iCloud Drive\n3. iCloud存储空间是否充足"
        case .backupNotNeeded:
            return "当前不需要备份"
        case .fileWriteFailed(let message):
            return "保存文件失败：\(message)"
        }
    }
}

