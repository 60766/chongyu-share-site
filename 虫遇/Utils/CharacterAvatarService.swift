import SwiftUI

/**
 * 角色头像服务
 * 统一管理角色头像的获取和显示
 * 支持多种头像来源：本地图片、系统图标、字母头像
 * 遵循第一性原理：直接使用角色ID作为图片名称，不使用映射
 * 🔧 优化：添加缓存机制，避免重复加载
 */
class CharacterAvatarService {
    // 单例实例
    static let shared = CharacterAvatarService()
    
    // 头像类型枚举
    enum AvatarType {
        case image(String)      // 图片名称
        case systemIcon(String, Color) // 系统图标名称和颜色 - 保留但不再使用
        case letter(String, Color)     // 字母和颜色
    }
    
    // 🔧 优化：添加头像类型缓存，避免重复检查
    private var avatarTypeCache: [String: AvatarType] = [:]
    private var avatarViewCache: [String: AnyView] = [:]
    private let cacheQueue = DispatchQueue(label: "avatar.cache", attributes: .concurrent)
    
    // 私有初始化方法
    private init() {
        // 初始化时检查常用角色头像
        checkCommonAvatars()
    }
    
    /**
     * 检查常用角色头像是否存在
     * 用于诊断头像加载问题
     */
    private func checkCommonAvatars() {
        // 将孔子移到列表中间，防止其成为默认选择
        let commonCharacters = ["einstein", "shakespeare", "davinci", "newton", "sunwukong", "kongzi"]
        

    }
    
    /**
     * 检查图片是否存在
     * @param imageName 图片名称
     * @return 图片是否存在且有效
     */
    func checkImageExistence(imageName: String) -> Bool {
        // 检查直接路径
        if let image = UIImage(named: imageName), image.size.width > 0, image.cgImage != nil {
            return true
        }
        
        // 检查历史人物路径
        let historicalPath = "HistoricalFigures/\(imageName)"
        if let image = UIImage(named: historicalPath), image.size.width > 0, image.cgImage != nil {
            return true
        }
        
        return false
    }
    
    /**
     * 获取角色头像类型
     * @param characterId 角色ID
     * @param name 角色名称
     * @param category 角色类别
     * @return 头像类型
     */
    func getAvatarType(for characterId: String, name: String, category: String) -> AvatarType {
        // 🔧 优化：先检查缓存
        if let cachedType = cacheQueue.sync(execute: { avatarTypeCache[characterId] }) {
            return cachedType
        }
        
        let avatarType: AvatarType
        
        // 1. 尝试直接加载本地图片
        if let image = UIImage(named: characterId), image.size.width > 0, image.cgImage != nil {
            avatarType = .image(characterId)
        } else {
            // 2. 尝试加载HistoricalFigures目录下的图片
            let historicalPath = "HistoricalFigures/\(characterId)"
            if let image = UIImage(named: historicalPath), image.size.width > 0, image.cgImage != nil {
                avatarType = .image(historicalPath)
            } else {
                // 3. 没有图片资源，使用字母头像
                // 获取有效名称 (优先使用中文名称)
                let chineseName = getCharacterChineseName(for: characterId)
                let effectiveName = !chineseName.isEmpty ? chineseName : (!name.isEmpty ? name : characterId)
                
                // 生成字母头像
                let initialLetter = getInitialLetter(from: effectiveName)
                let color = generateConsistentColor(for: characterId)
                avatarType = .letter(initialLetter, color)
            }
        }
        
        // 🔧 优化：缓存结果
        cacheQueue.async(flags: .barrier) {
            self.avatarTypeCache[characterId] = avatarType
        }
        
        return avatarType
    }
    
    /**
     * 获取角色头像视图
     * @param characterId 角色ID
     * @param name 角色名称
     * @param category 角色类别
     * @param size 头像大小
     * @return 头像视图
     */
    func getAvatarView(for characterId: String, name: String = "", category: String = "", size: CGFloat = 40, useCaching: Bool = false) -> some View {
        // 先检查视图缓存
        let cacheKey = "\(characterId)_\(size)"
        if useCaching, let cachedView = cacheQueue.sync(execute: { avatarViewCache[cacheKey] }) {

            return cachedView
        }
        
        let avatarType = getAvatarType(for: characterId, name: name, category: category)
        

        
        let avatarView: AnyView
        
        // 标准头像处理逻辑
        switch avatarType {
        case .image(let imageName):
            avatarView = AnyView(
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .contentShape(Circle()) // 确保头像可点击
                    .allowsHitTesting(true) // 明确允许点击事件
            )
            
        case .systemIcon(let iconName, let color):
            avatarView = AnyView(
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: size, height: size)
                    
                    Image(systemName: iconName)
                        .font(.system(size: size * 0.5))
                        .foregroundColor(color)
                }
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .contentShape(Circle()) // 确保头像可点击
                .allowsHitTesting(true) // 明确允许点击事件
            )
            
        case .letter(let letter, let color):
            avatarView = AnyView(
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: size, height: size)
                    
                    Text(letter)
                        .font(.system(size: size * 0.45, weight: .medium))
                        .foregroundColor(color)
                    
                    Circle()
                        .stroke(color.opacity(0.7), lineWidth: 1.5)
                        .frame(width: size, height: size)
                }
                .contentShape(Circle()) // 确保头像可点击
                .allowsHitTesting(true) // 明确允许点击事件
            )
        }
        
        // 🔧 优化：缓存视图结果
        cacheQueue.async(flags: .barrier) {
            self.avatarViewCache[cacheKey] = avatarView
        }
        
        return avatarView
    }
    
    /**
     * 获取角色头像名称
     * @param characterId 角色ID
     * @return 头像名称
     */
    func getAvatarName(for characterId: String) -> String {
        // 标准化ID
        let normalizedId = characterId.lowercased()
        
        // 对于Assets.xcassets中的图片，直接使用图片集名称
        // 不需要路径前缀，因为iOS会自动在Asset Catalog中查找
        return normalizedId
    }
    
    /**
     * 判断是否为已知角色
     * @param id 角色ID
     * @return 是否为已知角色
     */
    func isKnownCharacter(id: String) -> Bool {
        // 使用与getAvatarName相同的knownCharacters数组，避免重复定义
        let normalizedId = id.lowercased()
        let result = _knownCharacters.contains(normalizedId)
        
        if result {
            // 即使图片不存在也返回true，因为已知角色需要显示字母头像
            return true
        } else {
            return false
        }
    }
    
    // 历史人物和已知角色列表 - 与characters.json保持一致
    var knownCharacters: [String] {
        get {
            return _knownCharacters
        }
    }
    
    private let _knownCharacters = [
        // 已有的历史人物和科学家 - 将孔子移到列表中间位置，避免作为默认头像
        "einstein", "shakespeare", "davinci", "newton", "libai",
        "holmes", "curie", "socrates", "plato", "aristotle", "tesla",
        "hawking", "mozart", "beethoven", "freud", "darwin", "kongzi", "sunwukong", "sherlock",
        
        // 神话和传说人物
        "anubis", "nuwa", "erlang", "nezha", "zeus", "thor", "athena", "osiris", "chang_e", "loki", "ganesha", "hou_yi", "quetzalcoatl",
        
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
        "naruto", "hatsune", "walle", "doraemon", "sanji", "chihiro", "goku", "sailor_moon", "light_yagami", "spike_spiegel", "totoro",
        "lelouch", "inuyasha", "edward_elric", "saitama", "hatsune_miku", "luffy",
        "conan", "saber", "nezuko", "levi", "jinx", "kirby", "pikachu", "eren", "tanjiro",
        
        // 文学角色
        "hermione", "daenerys", "don_quixote", "hamlet", "jean_valjean", "anna_karenina",
        "gatsby", "ahq", "scarlett", "raskolnikov", "jia_baoyu", "macbeth", "joker",
        
        // 中国历史和文学人物
        "wuzetian", "yanggufei", "caocao", "yuefei", "lindaiyu", 
        "tangsanzang", "niexiaoqian", "yangguo", "baishe",
        "qinshihuang", "hanwudi", "kangxi", "jingke", "wangzhaojun", "xishi",
        "diaochan", "ayuwang", "cixi", "genghis", "songjiang", "xuebaochai",
        "wusong", "guangtouqiang", "laozi", "zhuangzi", "luxun", "kawabata", "sanmao",
        "zhangdaqian",
        
        // 西方历史人物
        "cleopatra", "caesar", "alexander", "nightingale", "zhenghe", "joan_of_arc",
        "marie_curie", "van_gogh", "jung", "adler", "monet", "picasso", "tolstoy", "marquez",
        "kant",
        
        // 其他角色
        "elsa", "mulan", "spike", "minions", "gollum"
    ]
    
    /**
     * 获取已知角色列表
     * @return 已知角色ID列表
     */
    func getKnownCharacters() -> [String] {
        return _knownCharacters
    }
    
    /**
     * 根据角色ID和类别获取图标和颜色
     * @param characterId 角色ID
     * @param category 角色类别
     * @return (图标名称, 颜色)
     */
    private func getIconAndColor(for characterId: String, category: String = "") -> (String, Color) {
        // 特定角色的图标映射
        let characterIdLowercase = characterId.lowercased()
        
        switch characterIdLowercase {
        case "einstein": return ("atom", .blue)
        case "shakespeare": return ("book.fill", .purple)
        case "davinci": return ("paintpalette.fill", .orange)
        case "kongzi": return ("scroll.fill", .red)
        case "newton": return ("arrow.down.circle.fill", .green)
        case "libai": return ("text.book.closed.fill", .teal)
        case "holmes": return ("magnifyingglass", .gray)
        case "frodo": return ("ring.circle.fill", .yellow) // 新增
        case "spike": return ("airplane", .blue) // 新增
        case "naruto": return ("tornado", .orange)
        case "ironman": return ("bolt.fill", .red)
        case "socrates": return ("brain.head.profile", .indigo)
        case "plato": return ("brain", .indigo)
        case "aristotle": return ("books.vertical.fill", .brown)
        case "tesla": return ("bolt.horizontal.circle.fill", .blue)
        case "hawking": return ("star.fill", .purple)
        case "mozart": return ("music.note", .pink)
        case "beethoven": return ("music.quarternote.3", .pink)
        case "curie": return ("atom", .green)
        case "freud": return ("brain.head.profile", .gray)
        case "darwin": return ("leaf.fill", .green)
        case "goku", "sunwukong": return ("figure.martial.arts", .orange)
        case "sherlock": return ("magnifyingglass.circle.fill", .blue)
        case "daenerys": return ("flame.fill", .red) // 丹妮莉丝·坦格利安 - 龙之母
        case "hermione": return ("book.closed.fill", .brown) // 赫敏 - 学霸
        case "don_quixote": return ("shield.fill", .gray) // 堂吉诃德 - 骑士
        case "hamlet": return ("theatermasks.fill", .purple) // 哈姆雷特 - 戏剧
        case "jean_valjean": return ("person.2.fill", .blue) // 冉阿让 - 救赎
        case "anna_karenina": return ("heart.fill", .pink) // 安娜·卡列尼娜 - 爱情
        case "gatsby": return ("building.2.fill", .yellow) // 盖茨比 - 财富
        case "scarlett": return ("leaf.fill", .green) // 斯嘉丽 - 南方
        case "macbeth": return ("crown.fill", .orange) // 麦克白 - 野心
        case "joker": return ("face.smiling.fill", .purple) // 小丑 - 疯狂
        case "gollum": return ("ring.fill", .brown) // 咕噜 - 魔戒
        case "ahq": return ("person.fill", .gray) // 阿Q - 鲁迅小说
        case "jia_baoyu": return ("leaf.fill", .red) // 贾宝玉 - 红楼梦
        case "yuefei": return ("shield.fill", .blue) // 岳飞 - 南宋军事家        
        case "ayuwang": return ("crown.fill", .purple) // 阿育王 - 古印度君主        
        case "conan": return ("magnifyingglass.fill", .blue) // 柯南 - 名侦探
        // 删除default_avatar的特殊处理，让系统使用字母头像
        default:
            // 根据类别分配默认图标
            return getCategoryIconAndColor(category)
        }
    }
    
    /**
     * 根据角色类别获取默认图标和颜色
     * @param category 角色类别
     * @return (图标名称, 颜色)
     */
    private func getCategoryIconAndColor(_ category: String) -> (String, Color) {
        // 确保类别是字符串且转为小写
        let categoryLowercase = category.lowercased()
        
        // 使用小写的类别字符串进行匹配
        switch categoryLowercase {
        case "scientist", "science": 
            return ("graduationcap.fill", .blue)
        case "writer", "literature", "poet": 
            return ("book.fill", .purple)
        case "philosopher", "philosophy": 
            return ("brain.head.profile", .indigo)
        case "artist", "art": 
            return ("paintbrush.fill", .orange)
        case "political", "politics", "leader": 
            return ("building.columns.fill", .gray)
        case "anime", "fictional", "fiction": 
            return ("sparkles", .yellow)
        case "superhero", "hero": 
            return ("bolt.fill", .red)
        case "musician", "music", "composer": 
            return ("music.note", .pink)
        case "mythological", "myth", "legend": 
            return ("cloud.sun.fill", .orange)
        case "historical", "history": 
            return ("clock.fill", .brown)
        default: 
            return ("person.circle.fill", .secondary)
        }
    }
    
    /**
     * 获取角色首字母（用于字母头像）
     * @param name 角色名称
     * @return 首字母
     */
    func getInitialLetter(from name: String) -> String {
        guard !name.isEmpty else { return "?" }
        
        // 提取第一个字符（支持中文、英文等Unicode字符）
        let firstChar = String(name.prefix(1))
        
        // 如果是英文，转为大写
        if firstChar.rangeOfCharacter(from: .letters) != nil && 
           firstChar.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return firstChar.uppercased()
        }
        
        // 否则直接返回（中文等其他字符）
        return firstChar
    }
    
    /**
     * 获取角色的中文名称（用于字母头像）
     * @param characterId 角色ID
     * @return 角色中文名称
     */
    func getCharacterChineseName(for characterId: String) -> String {
        // 角色ID到中文名称的映射
        let nameMap: [String: String] = [
            // 删除default_avatar映射，使用文字头像
            "ahq": "阿Q",
            "macbeth": "麦克白",
            "ayuwang": "阿育王",
            "hermione": "赫敏",
            "jean_valjean": "冉阿让",
            "gollum": "咕噜",
            "raskolnikov": "拉斯科尔尼科夫",
            "scarlett": "斯嘉丽",
            "anna_karenina": "安娜·卡列尼娜",
            "gatsby": "盖茨比",
            "hamlet": "哈姆雷特",
            "don_quixote": "堂吉诃德",
            "daenerys": "丹妮莉丝",
            "jia_baoyu": "贾宝玉",
            "yuefei": "岳飞",
            "joker": "小丑",
            "doctor": "神秘博士"
        ]
        
        return nameMap[characterId] ?? characterId
    }
    
    /**
     * 获取角色类别
     * @param characterId 角色ID
     * @return 角色类别
     */
    private func getCategory(for characterId: String) -> String {
        // 首先尝试从角色库中直接获取数据
        let allCharacters = CharacterSystem.shared.getAllCharacters()
        if let character = allCharacters.first(where: { $0.id.lowercased() == characterId.lowercased() }) {
            // 根据角色类型返回对应的分类
            switch character.type {
            case .historical:
                // 历史人物按subtype细分
                if let subtype = character.subtype {
                    switch subtype.lowercased() {
                    case "scientist": return "scientist"
                    case "philosopher": return "philosopher"
                    case "writer", "author": return "writer"
                    case "artist", "painter", "musician": return "artist"
                    default: return "historical"
                    }
                }
                return "historical"
            case .literary, .movie, .tv, .scifi, .fantasy:
                return "fiction"
            case .anime, .game:
                return "acg"
            case .mythological:
                return "mythology"
            case .entrepreneur:
                return "entrepreneur"
            case .custom:
                return "custom"
            case .unknown:
                // 对于未知类型，尝试从subtype判断
                if let subtype = character.subtype {
                    switch subtype.lowercased() {
                    case "scientist": return "scientist"
                    case "philosopher": return "philosopher"
                    case "writer", "author": return "writer"
                    case "artist", "painter", "musician": return "artist"
                    case "fiction", "character": return "fiction"
                    case "anime", "manga", "game": return "acg"
                    default: return "historical"
                    }
                }
                return "historical"
            }
        }
        
        // 如果无法从角色库获取，使用备用映射（仅保留少量关键角色）
        let fallbackCategoryMap: [String: String] = [
            // 备用映射，只保留一些重要的角色
            "einstein": "scientist", "kongzi": "philosopher", "shakespeare": "writer", 
            "davinci": "artist", "sherlock": "fiction", "naruto": "acg"
        ]
        
        // 确保ID为小写，以便正确匹配
        let normalizedId = characterId.lowercased()
        return fallbackCategoryMap[normalizedId] ?? "historical"
    }
    
    /**
     * 检查角色是否有自定义头像
     * @param characterId 角色ID
     * @return 是否有自定义头像
     */
    func hasCustomAvatar(for characterId: String) -> Bool {
        return UIImage(named: characterId) != nil || 
               UIImage(named: "HistoricalFigures/\(characterId)") != nil
    }
    
    /**
     * 预加载角色头像
     * @param characterId 角色ID
     * @param priority 优先级 (0.0-1.0)
     */
    func preloadAvatar(for characterId: String, priority: Float = 0.5) {
        // 创建一个低优先级的后台任务来预加载头像
        DispatchQueue.global(qos: .utility).async {
            // 获取头像类型但不创建视图
            let avatarType = self.getAvatarType(for: characterId, name: "", category: "")
            
            // 对于图片类型，预加载图片
            if case .image(let imageName) = avatarType {
                // 尝试加载图片以确保它在内存中
                let _ = UIImage(named: imageName)
                
                // 缓存头像类型
                self.cacheQueue.async(flags: .barrier) {
                    self.avatarTypeCache[characterId] = avatarType
                }
            }
        }
    }
    
    // MARK: - 缓存管理
    
    /**
     * 清理头像类型缓存
     * 用于释放内存或强制刷新
     */
    func clearAvatarTypeCache() {
        cacheQueue.async(flags: .barrier) {
            self.avatarTypeCache.removeAll()
        }
    }
    
    /**
     * 清理头像视图缓存
     * 用于释放内存或强制刷新
     */
    func clearAvatarViewCache() {
        cacheQueue.async(flags: .barrier) {
            self.avatarViewCache.removeAll()
        }
    }
    
    /**
     * 清理所有缓存
     * 用于释放内存或强制刷新
     */
    func clearAllCaches() {
        cacheQueue.async(flags: .barrier) {
            self.avatarTypeCache.removeAll()
            self.avatarViewCache.removeAll()
        }
    }
    
    /**
     * 获取缓存统计信息
     * 用于调试和监控
     */
    func getCacheStats() -> (typeCacheCount: Int, viewCacheCount: Int) {
        return cacheQueue.sync {
            (avatarTypeCache.count, avatarViewCache.count)
        }
    }
    
    /**
     * 生成角色的颜色（基于ID的一致性哈希）
     * @param characterId 角色ID
     * @return 颜色
     */
    func generateConsistentColor(for characterId: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .teal, .indigo]
        
        // 使用角色ID的哈希值选择颜色，确保同一角色总是得到相同的颜色
        var hash = 0
        for char in characterId {
            hash = ((hash << 5) &- hash) &+ Int(char.asciiValue ?? 0)
        }
        
        let index = abs(hash) % colors.count
        return colors[index]
    }
    
    /**
     * 获取角色类别标签
     */
    func getCharacterCategoryTag(for characterId: String) -> String {
        let characterMap: [String: String] = [
            "philosopher": "哲学家",
            "scientist": "科学家",
            "artist": "艺术家",
            "writer": "作家",
            "historical": "历史人物",
            "mythology": "神话",
            "fiction": "虚构人物",
            "acg": "动漫游戏",
            "film": "影视角色",
            "entrepreneur": "企业家",
            "custom": "自定义角色"
        ]
        
        let category = getCategory(for: characterId)
        return characterMap[category] ?? "历史人物"
    }
    
    /**
     * 获取角色标签颜色
     */
    func getCharacterTagColor(for characterId: String) -> Color {
        let colorMap: [String: Color] = [
            "philosopher": .green,
            "scientist": .blue,
            "artist": .purple,
            "writer": .orange,
            "historical": .red,
            "mythology": .yellow,
            "fiction": .cyan,
            "acg": .pink,
            "film": .indigo,
            "entrepreneur": .teal,
            "custom": .gray
        ]
        
        let category = getCategory(for: characterId)
        return colorMap[category] ?? .gray
    }
} 