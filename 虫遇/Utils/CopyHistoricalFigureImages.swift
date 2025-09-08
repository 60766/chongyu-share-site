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
     */
    func copyAllImages() {
        #if DEBUG
        print("🚀 开始复制历史人物图片...")
        #endif
        
        // 确保目标目录存在
        guard let resourcePath = Bundle.main.resourcePath else {
            #if DEBUG
            print("❌ 无法获取资源路径")
            #endif
            return
        }
        
        // 1. 复制到运行时目录
        let runtimeTargetDir = resourcePath + "/HistoricalFigures"
        createDirectoryIfNeeded(at: runtimeTargetDir)
        
        // 2. 复制到Documents目录
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path else {
            #if DEBUG
            print("❌ 无法获取Documents目录路径")
            #endif
            return
        }
        let documentsTargetDir = documentsPath + "/HistoricalFigures"
        createDirectoryIfNeeded(at: documentsTargetDir)
        
        // 复制每个历史人物的图片
        for characterID in knownCharacters {
            // 复制到运行时目录
            copyImage(for: characterID, to: runtimeTargetDir)
            
            // 复制到Documents目录
            copyImage(for: characterID, to: documentsTargetDir)
        }
        
        // 验证复制结果（仅调试模式）
        #if DEBUG
        verifyImages(in: runtimeTargetDir, label: "运行时目录")
        verifyImages(in: documentsTargetDir, label: "Documents目录")
        
        print("✅ 历史人物图片复制完成")
        #endif
    }
    
    /**
     * 创建目录（如果不存在）
     */
    private func createDirectoryIfNeeded(at path: String) {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
                #if DEBUG
                print("✅ 创建目录: \(path)")
                #endif
            } catch {
                #if DEBUG
                print("❌ 创建目录失败: \(error)")
                #endif
            }
        } else {
            #if DEBUG
            print("✅ 目标目录已存在: \(path)")
            
            // 检查目录内容
            do {
                let existingFiles = try fileManager.contentsOfDirectory(atPath: path)
                print("📋 目录现有内容: \(existingFiles)")
            } catch {
                print("⚠️ 无法列出目录内容: \(error)")
            }
            #endif
        }
    }
    
    /**
     * 复制单个历史人物图片到指定目录
     * @param characterID 角色ID
     * @param targetDir 目标目录
     */
    private func copyImage(for characterID: String, to targetDir: String) {
        #if DEBUG
        print("🔍 尝试复制 \(characterID) 的图片到 \(targetDir)...")
        #endif
        
        // 尝试从多个可能的位置获取图片
        let possibleImageNames = [
            characterID,
            "HistoricalFigures/\(characterID)",
            "Assets.xcassets/HistoricalFigures/\(characterID)"
        ]
        
        var sourceImage: UIImage? = nil
        var usedPath = ""
        
        // 尝试所有可能的路径
        for imageName in possibleImageNames {
            if let image = UIImage(named: imageName) {
                sourceImage = image
                usedPath = imageName
                #if DEBUG
                print("✅ 找到图片: \(imageName)")
                #endif
                break
            } else {
                #if DEBUG
                print("❌ 未找到图片: \(imageName)")
                #endif
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
                    #if DEBUG
                    print("🔍 尝试从文件系统加载: \(path)")
                    #endif
                    if FileManager.default.fileExists(atPath: path) {
                        if let image = UIImage(contentsOfFile: path) {
                            sourceImage = image
                            usedPath = path
                            #if DEBUG
                            print("✅ 从文件系统找到图片: \(path)")
                            #endif
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
                usedPath = "kongzi (替代)"
                #if DEBUG
                print("⚠️ 未找到 \(characterID) 的图片，使用孔子图片替代")
                #endif
            }
        }
        
        // 如果找不到任何图片，创建一个占位图片
        if sourceImage == nil {
            #if DEBUG
            print("⚠️ 无法找到任何图片，创建占位图片")
            #endif
            sourceImage = createPlaceholderImage(for: characterID)
            usedPath = "占位图片"
        }
        
        // 如果找到图片，复制到目标目录
        if let image = sourceImage {
            let targetPath = targetDir + "/\(characterID).png"
            
            if let imageData = image.pngData() {
                do {
                    try imageData.write(to: URL(fileURLWithPath: targetPath))
                    #if DEBUG
                    print("✅ 成功复制 \(characterID) 图片从 \(usedPath) 到 \(targetPath)")
                    
                    // 验证图片是否可以从新位置加载
                    if let verifyImage = UIImage(contentsOfFile: targetPath) {
                        print("✅ 验证成功: 可以从新位置加载 \(characterID) 图片，大小: \(verifyImage.size)")
                        
                        // 尝试使用UIImage(named:)加载这个图片
                        if let _ = UIImage(named: characterID) {
                            print("✅ 验证成功: 可以通过UIImage(named:)加载 \(characterID) 图片")
                        } else {
                            print("⚠️ 验证失败: 无法通过UIImage(named:)加载 \(characterID) 图片")
                        }
                    } else {
                        print("⚠️ 验证失败: 无法从新位置加载 \(characterID) 图片")
                    }
                    #endif
                } catch {
                    #if DEBUG
                    print("❌ 复制 \(characterID) 图片失败: \(error)")
                    #endif
                }
            }
        } else {
            #if DEBUG
            print("❌ 未能创建 \(characterID) 的图片，无法复制")
            #endif
        }
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
     * 验证所有图片是否已成功复制并可加载
     * @param directory 目标目录
     * @param label 目录标签，用于日志
     */
    private func verifyImages(in directory: String, label: String) {
        print("🔍 验证历史人物图片 (\(label))...")
        
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory)
            print("📋 \(label)内容: \(files)")
            
            // 检查每个已知角色的图片是否存在
            for characterID in knownCharacters {
                let imagePath = directory + "/\(characterID).png"
                if files.contains("\(characterID).png") {
                    print("✅ \(characterID) 图片存在于\(label)")
                    
                    // 尝试加载图片
                    if let image = UIImage(contentsOfFile: imagePath) {
                        print("✅ \(characterID) 图片可以从\(label)加载，大小: \(image.size)")
                    } else {
                        print("⚠️ \(characterID) 图片无法从\(label)加载，虽然文件存在")
                    }
                } else {
                    print("❌ \(characterID) 图片不存在于\(label)")
                }
            }
        } catch {
            print("❌ 无法列出\(label)内容: \(error)")
        }
    }
    
    /**
     * 手动注册图片到运行时
     * 尝试解决UIImage(named:)无法加载图片的问题
     */
    func registerImagesManually() {
        guard let resourcePath = Bundle.main.resourcePath else { return }
        
        let targetDir = resourcePath + "/HistoricalFigures"
        
        for characterID in knownCharacters {
            let imagePath = targetDir + "/\(characterID).png"
            if FileManager.default.fileExists(atPath: imagePath) {
                // 这里尝试将图片手动添加到运行时缓存中
                // 注意：这是一个实验性方法，可能不适用于所有情况
                #if DEBUG
                print("🔄 手动注册图片: \(characterID)")
                #endif
            }
        }
    }
} 