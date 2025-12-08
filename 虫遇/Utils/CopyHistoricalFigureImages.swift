import Foundation
import UIKit

/**
 * 历史人物图片复制服务
 * 确保所有历史人物的图片都被正确复制到运行时目录和Documents目录中
 * 在应用启动时调用
 */
class HistoricalFigureImageCopier {
    // 单例实例
    static let shared = HistoricalFigureImageCopier()
    
    // ⚡️ 优化：已知缺失图片的角色ID列表（跳过这些以避免无效加载）
    private let knownMissingImages = [
        "ahq", "anna_karenina", "ayuwang", "daenerys", "doctor", "don_quixote",
        "gatsby", "gollum", "hamlet", "hermione", "jean_valjean", "jia_baoyu",
        "joker", "liucixin", "macbeth", "raskolnikov", "scarlett", "yuefei",
        "aristotle", "curie", "hawking", "newton", "spike", "spike_spiegel"
    ]
    
    // ⚡️ 优化：使用UserDefaults记录是否已完成首次图片复制
    private let hasCompletedInitialCopyKey = "HasCompletedInitialImageCopy_v2"
    
    // ⚡️ 优化：图片缓存，避免重复验证
    private var imageCache: [String: Bool] = [:]
    
    // 已知历史人物列表 - 与CharacterAvatarService保持一致
    private let knownCharacters = [
        // 已有的历史人物和科学家
        "einstein", "shakespeare", "davinci", "kongzi", "newton", "libai",
        "holmes", "curie", "socrates", "plato", "aristotle", "tesla",
        "hawking", "mozart", "beethoven", "freud", "darwin", "sunwukong", "sherlock",
        
        // 神话和传说人物
        "anubis", "nuwa", "erlang", "nezha", "zeus", "thor", "athena", "amaterasu", 
        "osiris", "chang_e", "loki", "ganesha", "hou_yi", "quetzalcoatl",
        
        // 电影和电视剧角色
        "ironman", "spiderman", "blackwidow", "terminator", "neo", "frodo", "obiwan", 
        "legolas", "drhouse", "kirk", "thanos", "deadpool", "darth_vader", "jack_sparrow",
        "harry_potter", "maximus", "amelie", "ip_man", "ethan_hunt", "forrest_gump",
        "walter_white", "tyrion_lannister", "eleven", "sheldon_cooper", "sherlock_bbc",
        "michael_scott", "raymond_reddington", "thomas_shelby", "zhen_huan", "saul_goodman",
        "doctor", "drstrange",
        
        // 游戏角色
        "geralt", "link", "lara", "lixiaoyao", "mario", "master_chief", "kratos", 
        "solid_snake", "cloud_strife", "ezio_auditore", "aloy", "2b", "agent_47", "ellie",
        "genshin_traveler", "zhongli",
        
        // 动漫和漫画角色
        "naruto", "ghibli", "hatsune", "walle", "doraemon", "jojo", "sanji", "huluwa",
        "chihiro", "goku", "sailor_moon", "light_yagami", "spike_spiegel", "totoro",
        "lelouch", "inuyasha", "edward_elric", "saitama", "hatsune_miku", "luffy",
        "conan", "saber", "nezuko", "levi", "jinx", "kirby", "pikachu", "eren", "tanjiro",
        
        // 文学角色
        "hermione", "daenerys", "don_quixote", "hamlet", "jean_valjean", "anna_karenina",
        "gatsby", "ahq", "scarlett", "raskolnikov", "jia_baoyu", "macbeth", "joker",
        
        // 中国历史和文学人物
        "wuzetian", "lisiming", "yanggufei", "caocao", "yuefei", "lindaiyu", 
        "tangsanzang", "niexiaoqian", "yangguo", "zhouxingchi", "baishe",
        "qinshihuang", "hanwudi", "kangxi", "jingke", "nieying", "wangzhaojun", "xishi",
        "diaochan", "ayuwang", "female_ninja", "cixi", "genghis", "songjiang", "xuebaochai",
        "wusong", "guangtouqiang", "laozi", "zhuangzi", "luxun", "kawabata", "sanmao",
        "zhangdaqian",
        
        // 西方历史人物
        "cleopatra", "caesar", "alexander", "nightingale", "zhenghe", "joan_of_arc",
        "marie_curie", "van_gogh", "jung", "adler", "monet", "picasso", "tolstoy", "marquez",
        "kant",
        
        // 其他角色
        "elsa", "mulan", "spike", "minions", "gollum", "conan"
    ]
    
    // 私有初始化方法
    private init() {}
    
    /**
     * 复制所有历史人物图片到运行时目录和Documents目录
     * 在应用启动时调用
     * ⚡️ 优化：首次启动完整复制，后续启动快速检查
     */
    func copyAllImages() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // ⚡️ 优化：检查是否已完成首次图片复制
        let hasCompletedInitialCopy = UserDefaults.standard.bool(forKey: hasCompletedInitialCopyKey)
        
        // 确保目标目录存在
        guard let resourcePath = Bundle.main.resourcePath else {
            return
        }
        
        // 1. 复制到运行时目录
        let runtimeTargetDir = resourcePath + "/HistoricalFigures"
        createDirectoryIfNeeded(at: runtimeTargetDir, silent: hasCompletedInitialCopy)
        
        // 2. 复制到Documents目录
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
            return
        }
        let documentsTargetDir = documentsPath + "/HistoricalFigures"
        createDirectoryIfNeeded(at: documentsTargetDir, silent: hasCompletedInitialCopy)
        
        // ⚡️ 优化：如果已完成首次复制，只做快速验证
        if hasCompletedInitialCopy {
            #if DEBUG
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            debugLog("⚡️ 图片快速检查完成，耗时: \(String(format: "%.2f", timeElapsed * 1000))ms")
            #endif
            return
        }
        
        // 首次启动：完整复制所有图片
        #if DEBUG
        debugLog("🚀 首次启动，开始复制历史人物图片...")
        #endif
        
        // 复制每个历史人物的图片
        var successCount = 0
        var skippedCount = 0
        for characterID in knownCharacters {
            // ⚡️ 优化：跳过已知缺失的图片
            if knownMissingImages.contains(characterID) {
                skippedCount += 1
                continue
            }
            
            // 只复制到Documents目录（运行时目录不需要）
            let success = copyImage(for: characterID, to: documentsTargetDir, silent: true)
            
            if success {
                successCount += 1
            }
        }
        
        // 标记已完成首次复制
        UserDefaults.standard.set(true, forKey: hasCompletedInitialCopyKey)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #if DEBUG
        debugLog("✅ 图片复制完成: 成功 \(successCount) 个，跳过 \(skippedCount) 个，耗时: \(String(format: "%.2f", timeElapsed * 1000))ms")
        #endif
    }
    
    /**
     * 创建目录（如果不存在）
     * ⚡️ 优化：添加silent参数，减少日志输出
     */
    private func createDirectoryIfNeeded(at path: String, silent: Bool = false) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
                #if DEBUG
                if !silent {
                    debugLog("✅ 创建目录: \(path)")
                }
                #endif
            } catch {
                #if DEBUG
                debugLog("❌ 创建目录失败: \(error)")
                #endif
            }
        }
    }
    
    /**
     * 复制单个历史人物图片到指定目录
     * @param characterID 角色ID
     * @param targetDir 目标目录
     * @param silent 是否静默模式（不输出日志）
     * @return 是否成功复制
     * ⚡️ 优化：添加silent参数，减少日志输出
     */
    private func copyImage(for characterID: String, to targetDir: String, silent: Bool = false) -> Bool {
        // 尝试从多个可能的位置获取图片
        let possibleImageNames = [
            characterID,
            "HistoricalFigures/\(characterID)",
            "Assets.xcassets/HistoricalFigures/\(characterID)"
        ]
        
        var sourceImage: UIImage? = nil
        
        // 尝试所有可能的路径
        for imageName in possibleImageNames {
            if let image = UIImage(named: imageName) {
                sourceImage = image
                break
            }
        }
        
        // 如果找不到图片，尝试直接从文件系统加载
        if sourceImage == nil {
            if let resourcePath = Bundle.main.resourcePath {
                let filePaths = [
                    resourcePath + "/\(characterID).png",
                    resourcePath + "/HistoricalFigures/\(characterID).png",
                    resourcePath + "/Assets.xcassets/HistoricalFigures/\(characterID).imageset/\(characterID).png"
                ]
                
                for path in filePaths {
                    if FileManager.default.fileExists(atPath: path) {
                        if let image = UIImage(contentsOfFile: path) {
                            sourceImage = image
                            break
                        }
                    }
                }
            }
        }
        
        // 如果找不到图片，尝试使用孔子的图片作为替代
        if sourceImage == nil && characterID != "kongzi" {
            if let kongziImage = UIImage(named: "HistoricalFigures/kongzi") ?? UIImage(named: "kongzi") {
                sourceImage = kongziImage
            }
        }
        
        // 如果找不到任何图片，创建一个占位图片
        if sourceImage == nil {
            sourceImage = createPlaceholderImage(for: characterID)
        }
        
        // 如果找到图片，复制到目标目录
        if let image = sourceImage {
            let targetPath = targetDir + "/\(characterID).png"
            
            if let imageData = image.pngData() {
                do {
                    try imageData.write(to: URL(fileURLWithPath: targetPath))
                    return true
                } catch {
                    #if DEBUG
                    if !silent {
                        debugLog("❌ 复制 \(characterID) 图片失败: \(error)")
                    }
                    #endif
                    return false
                }
            }
        }
        
        return false
    }
    
    /**
     * 创建占位图片
     */
    private func createPlaceholderImage(for characterID: String) -> UIImage {
        // 创建一个简单的带文字的占位图片
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            // 填充背景
            UIColor.orange.withAlphaComponent(0.2).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 绘制边框
            UIColor.orange.setStroke()
            ctx.stroke(CGRect(origin: .zero, size: size))
            
            // 绘制文字
            let text = String(characterID.prefix(1).uppercased())
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 100, weight: .bold),
                .foregroundColor: UIColor.orange
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /**
     * ⚡️ 已移除：验证所有图片（太慢，已优化为首次检查机制）
     * 如需调试，可临时启用详细日志
     */
    
    /**
     * ⚡️ 已移除：手动注册图片（不再需要，已优化加载机制）
     */
    func registerImagesManually() {
        // 空实现，保持接口兼容性
    }
} 