import SwiftUI
import Combine
import Foundation

/**
 * 历史人物选择视图的ViewModel
 * 负责管理历史人物数据和选择状态
 */
class HistoricalFigureSelectionViewModel: ObservableObject {
    // 发布属性
    @Published var availableFigures: [CommentHistoricalFigure] = []
    @Published var selectedFigures: [CommentHistoricalFigure] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // 私有属性
    private let postId: String
    private let cognitionModel = HistoricalFigureCognitionModel.shared
    private var relevantFigures: Set<UUID> = []
    private var postContent: String = ""
    private var postAuthor: AppCharacter? = nil
    private var allCharacters: [AppCharacter] = []
    
    // 明确的角色关系映射
    private let characterRelations: [String: [String]] = [
        // 文学家关系 - 同一国家/时期的文学家
        "川端康成": ["三岛由纪夫", "芥川龙之介", "太宰治", "谷崎润一郎"],
        "莎士比亚": ["克里斯托弗·马洛", "本·琼森", "约翰·弥尔顿", "狄更斯", "奥斯卡·王尔德", "托尔斯泰", "陀思妥耶夫斯基", "马尔克斯", "鲁迅"],
        "大仲马": ["小仲马", "雨果", "巴尔扎克"],
        "鲁迅": ["莎士比亚", "果戈里", "陀思妥耶夫斯基", "托尔斯泰", "莫泊桑", "王小波"],

        "博尔赫斯": ["马尔克斯", "卡尔维诺", "科塔萨尔", "略萨", "莎士比亚"],
        "夏洛克·福尔摩斯": ["华生", "莫里亚蒂", "艾琳·艾德勒", "柯南·道尔", "博尔赫斯"],
        "三毛": ["张爱玲", "琼瑶", "席慕蓉", "余光中", "林清玄", "簡媜"],
        "张爱玲": ["三毛", "萧红", "琼瑶", "鲁迅", "胡兰成", "王安忆", "铁凝"],
        "马尔克斯": ["博尔赫斯", "略萨", "聂鲁达", "卡夫卡", "福克纳", "海明威", "莎士比亚"],
        "卡夫卡": ["陀思妥耶夫斯基", "托马斯·曼", "马尔克斯", "加缪", "博尔赫斯", "米兰·昆德拉"],
        "海明威": ["菲茨杰拉德", "福克纳", "马尔克斯", "村上春树", "托尔斯泰", "王小波"],
        "王小波": ["鲁迅", "卡夫卡", "加缪", "博尔赫斯", "海明威"],
        "伍尔夫": ["乔伊斯", "福克纳", "普鲁斯特", "伍迪·艾伦", "波伏娃", "张爱玲", "陀思妥耶夫斯基"],
        
        // 科学家关系 - 同领域或有合作/影响的科学家
        "爱因斯坦": ["玻尔", "普朗克", "海森堡", "费曼", "霍金", "奥本海默", "图灵", "牛顿", "哥德尔", "薛定谔"],
        "牛顿": ["莱布尼茨", "伽利略", "开普勒", "爱因斯坦", "霍金", "法拉第", "麦克斯韦"],
        "居里夫人": ["皮埃尔·居里", "卢瑟福", "贝克勒尔", "爱因斯坦", "玻尔"],
        "达尔文": ["华莱士", "赫胥黎", "门德尔", "牛顿", "林奈", "古尔德"],
        "霍金": ["爱因斯坦", "费曼", "彭罗斯", "卡拉比", "威滕"],
        "费曼": ["爱因斯坦", "霍金", "奥本海默", "玻尔", "狄拉克", "海森堡"],
        "图灵": ["冯·诺依曼", "香农", "丘奇", "哥德尔", "波斯特"],
        "奥本海默": ["爱因斯坦", "费曼", "费米", "玻尔", "泰勒", "拉比"],
        "凯库勒": ["门捷列夫", "玻尔", "拉瓦锡", "普朗克", "德贝谢"],
        "拉马努金": ["哈代", "李特尔伍德", "欧拉", "高斯", "拉格朗日", "希尔伯特"],
        "阿努比斯": ["奥西里斯", "伊西斯", "荷鲁斯", "塞特", "克莱奥帕特拉", "图特"],
        "爱迪生": ["特斯拉", "贝尔", "法拉第", "爱因斯坦", "费曼", "马可尼"],
        "特斯拉": ["爱迪生", "马可尼", "赫兹", "法拉第", "麦克斯韦", "爱因斯坦"],
        "玻尔": ["爱因斯坦", "海森堡", "普朗克", "薛定谔", "费曼", "狄拉克"],
        "普朗克": ["爱因斯坦", "玻尔", "海森堡", "薛定谔", "费曼", "狄拉克"],
        "海森堡": ["爱因斯坦", "玻尔", "普朗克", "薛定谔", "费曼", "狄拉克"],
        
        // 哲学家关系 - 师徒关系或同一学派
        "孔子": ["孟子", "荀子", "颜回", "子路", "庄子", "老子", "墨子", "韩非子"],
        "苏格拉底": ["柏拉图", "色诺芬", "欧几里得", "亚里士多德", "第欧根尼", "尼采", "康德"],
        "柏拉图": ["苏格拉底", "亚里士多德", "普罗提诺", "康德", "尼采", "黑格尔"],
        "康德": ["黑格尔", "叔本华", "费希特", "莱布尼茨", "尼采", "柏拉图", "亚里士多德"],
        "尼采": ["叔本华", "康德", "海德格尔", "萨特", "福柯", "柏拉图", "苏格拉底"],
        "庄子": ["老子", "惠施", "列子", "孔子", "墨子", "韩非子", "孟子"],
        "福柯": ["德里达", "德勒兹", "巴特", "尼采", "海德格尔", "萨特", "波伏娃"],
        "波伏娃": ["萨特", "加缪", "梅洛-庞蒂", "尼采", "福柯"],
        "萨特": ["加缪", "波伏娃", "梅洛-庞蒂", "海德格尔", "尼采", "福柯"],
        "老子": ["庄子", "惠施", "列子", "孔子", "墨子", "韩非子", "孟子"],
        "亚里士多德": ["柏拉图", "苏格拉底", "亚历山大大帝", "托马斯·阿奎那", "阿维罗伊", "康德"],
        "加缪": ["萨特", "波伏娃", "尼采", "海德格尔", "卡夫卡", "陀思妥耶夫斯基"],
        "叔本华": ["康德", "尼采", "维特根斯坦", "黑格尔", "歌德", "托尔斯泰"],
        "海德格尔": ["胡塞尔", "萨特", "加缪", "尼采", "维特根斯坦", "海德格尔"],
        "维特根斯坦": ["罗素", "弗雷格", "波普尔", "卡尔纳普", "海德格尔", "罗蒂"],
        "罗素": ["维特根斯坦", "怀特海", "弗雷格", "穆尔", "波普尔", "卡尔纳普"],
        "黑格尔": ["康德", "费希特", "谢林", "马克思", "叔本华", "克尔凯郭尔"],
        "马克思": ["恩格斯", "黑格尔", "费尔巴哈", "列宁", "葛兰西", "卢卡奇"],
        "王阳明": ["朱熹", "陆九渊", "刘伯温", "黄宗羲", "顾炎武", "孔子"],
        "帕斯卡": ["笛卡尔", "费马", "伽利略", "牛顿", "莱布尼茨", "亚里士多德"],
        
        // 历史人物关系 - 同一朝代/时期的重要人物
        "成吉思汗": ["忽必烈", "拖雷", "窝阔台", "术赤", "耶律楚材", "蒙哥", "旭烈兀"],
        "秦始皇": ["李斯", "蒙恬", "赵高", "扶苏", "胡亥", "吕不韦"],
        "凯撒大帝": ["屋大维", "安东尼", "克利奥帕特拉", "庞培", "布鲁图", "西塞罗", "苏拉"],
        "丘吉尔": ["罗斯福", "斯大林", "艾森豪威尔", "张伯伦", "艾德礼", "乔治六世", "麦克米伦"],
        "林肯": ["华盛顿", "杰斐逊", "格兰特", "李将军", "道格拉斯", "西沃德", "约翰逊"],
        "甘地": ["曼德拉", "金", "尼赫鲁", "丘吉尔", "萨达特", "德蕾莎修女", "博斯"],
        "拿破仑": ["亚历山大一世", "威灵顿", "约瑟芬", "梅特涅", "塔列朗", "路易十六", "路易十八"],
        "亚历山大大帝": ["亚里士多德", "菲利普二世", "大流士三世", "托勒密", "赫费斯提翁", "安提帕特", "尼阿库斯"],
        "屋大维": ["凯撒大帝", "安东尼", "克利奥帕特拉", "阿格里帕", "梅塞纳斯", "李维", "维吉尔"],
        "康熙皇帝": ["索额图", "明珠", "徐光启", "南怀仁", "张诚", "雍正", "乾隆", "孔子", "朱熹"],
        
        // 艺术家关系 - 同一艺术运动/流派
        "达芬奇": ["米开朗基罗", "拉斐尔", "波提切利", "多纳太罗", "布鲁内莱斯基", "丢勒", "鲁本斯"],
        "梵高": ["高更", "塞尚", "莫奈", "雷诺阿", "毕加索", "夏加尔", "马蒂斯"],
        "毕加索": ["马蒂斯", "布拉克", "夏加尔", "莫迪里阿尼", "达利", "莫奈", "康定斯基", "梵高"],
        "莫奈": ["雷诺阿", "梵高", "塞尚", "毕沙罗", "德加", "马奈", "高更"],
        "葛饰北斋": ["歌川广重", "喜多川歌麿", "歌川国芳", "月冈芳年", "东洲斋写乐", "俵屋宗达"],
        "康定斯基": ["克利", "蒙德里安", "马列维奇", "罗斯科", "波洛克", "毕加索", "夏加尔", "达利"],
        "夏加尔": ["毕加索", "马蒂斯", "康定斯基", "克利", "莫迪里阿尼", "布拉克", "达利", "梵高"],
        "达利": ["毕加索", "马格利特", "夏加尔", "米罗", "恩斯特", "布鲁东", "波洛克", "康定斯基"],
        
        // 音乐家关系 - 同时代或相互影响的音乐家
        "贝多芬": ["莫扎特", "海顿", "舒伯特", "李斯特", "舒曼", "巴赫", "肖邦"],
        "巴赫": ["亨德尔", "维瓦尔第", "泰勒曼", "贝多芬", "莫扎特", "海顿", "舒伯特"],
        "肖邦": ["李斯特", "舒曼", "门德尔松", "贝多芬", "巴赫", "瓦格纳", "勃拉姆斯"],
        "莫扎特": ["贝多芬", "海顿", "萨列里", "巴赫", "肖邦", "舒伯特", "舒曼"],
        "柴可夫斯基": ["肖邦", "拉赫玛尼诺夫", "格里格", "里姆斯基-科萨科夫", "穆索尔斯基", "舒曼", "贝多芬"],
        "约翰·列侬": ["保罗·麦卡特尼", "乔治·哈里森", "林戈·斯塔尔", "鲍勃·迪伦", "艾尔维斯·普雷斯利", "米克·贾格尔", "大卫·鲍伊", "迈克尔·杰克逊"],
        "迈克尔·杰克逊": ["普林斯", "玛丹娜", "惠特尼·休斯顿", "昆西·琼斯", "艾尔顿·约翰", "史蒂维·旺德", "詹姆斯·布朗", "约翰·列侬"],
        
        // 动漫角色关系 - 同一作品的主要角色
        "漩涡鸣人": ["宇智波佐助", "旗木卡卡西", "春野樱", "自来也", "日向雏田", "我爱罗"],
        "孙悟空": ["贝吉塔", "克林", "比克", "悟饭", "布尔玛", "弗利萨", "贝比"],
        "路飞": ["索隆", "娜美", "山治", "乔巴", "罗宾", "弗兰奇", "布鲁克"],
        "灰原哀": ["柯南", "工藤新一", "毛利兰", "阿笠博士", "赤井秀一", "安室透", "琴酒"],
        "莱因哈特": ["杨威利", "齐格飞", "米达麦亚", "罗严塔尔", "希尔德", "吉尔菲艾斯", "法伦海特"],
        "杨威利": ["莱因哈特", "尤里安", "亚典波罗", "先寇布", "卡介伦", "菲列特利加", "波布兰"],
        
        // 电影角色关系 - 同一系列电影的角色
        "钢铁侠": ["美国队长", "雷神", "绿巨人", "黑寡妇", "蜘蛛侠", "奇异博士", "幻视"],
        "哈利·波特": ["赫敏·格兰杰", "罗恩·韦斯莱", "邓布利多", "伏地魔", "斯内普", "小天狼星", "卢平"],
        "达斯·维达": ["卢克·天行者", "莱娅公主", "汉·索罗", "欧比旺", "帕尔帕廷", "阿纳金", "尤达"],
        "弗罗多": ["甘道夫", "山姆", "阿拉贡", "莱戈拉斯", "金雳", "波罗米尔", "咕噜"],
        "小丑": ["蝙蝠侠", "哈莉·奎因", "双面人", "企鹅人", "谜语人", "猫女", "罗宾"],
        "蝙蝠侠": ["小丑", "罗宾", "阿尔弗雷德", "猫女", "超人", "戈登局长", "谜语人"],
        
        // 诗人关系 - 同时代诗人
        "李白": ["杜甫", "王维", "孟浩然", "白居易", "高适", "贺知章", "岑参"],
        "杜甫": ["李白", "王维", "岑参", "高适", "白居易", "刘禹锡", "元稹"],
        "屈原": ["宋玉", "贾谊", "司马相如", "杜甫", "李白", "陶渊明", "李商隐"],
        "波德莱尔": ["兰波", "魏尔伦", "马拉美", "华兹华斯", "歌德", "雪莱", "徐志摩"],
        "徐志摩": ["泰戈尔", "叶芝", "朱自清", "胡适", "闻一多", "冰心", "郭沫若"],
        "聂鲁达": ["马尔克斯", "略萨", "博尔赫斯", "普希金", "米斯特拉尔", "勃朗宁", "惠特曼"],
        "华兹华斯": ["拜伦", "雪莱", "济慈", "柯尔律治", "泰戈尔", "徐志摩", "朱自清"],
        "李清照": ["辛弃疾", "陆游", "苏轼", "欧阳修", "晏殊", "柳永", "秦观"],
        
        // 心理学家关系 - 同学派或相互影响的心理学家
        "弗洛伊德": ["荣格", "阿德勒", "拉康", "弗洛姆", "霍妮", "安娜·弗洛伊德", "尼采", "萨特"],
        "荣格": ["弗洛伊德", "阿德勒", "尼采", "弗洛姆", "坎贝尔", "希利曼", "海德格尔", "萨特"],
        
        // 物理学家关系 - 同领域或相互影响的物理学家
        "波普尔": ["爱因斯坦", "维特根斯坦", "库恩", "费耶阿本德", "拉卡托斯", "罗素"],
        
        // 忍者角色关系 - 日本战国时代的忍者和武士
        "女忍者": ["服部半藏", "风魔小太郎", "望月千代女", "猿飞佐助", "霧隠才蔵", "百地三太夫", "上泉信纲"],
        "服部半藏": ["女忍者", "风魔小太郎", "猿飞佐助", "霧隠才蔵", "百地三太夫", "上泉信纲", "德川家康"],
        "风魔小太郎": ["服部半藏", "女忍者", "猿飞佐助", "霧隠才蔵", "百地三太夫", "北条氏政", "武田信玄"],
        "望月千代女": ["女忍者", "服部半藏", "霧隠才蔵", "百地三太夫", "猿飞佐助", "上泉信纲", "风魔小太郎"],
        "猿飞佐助": ["服部半藏", "风魔小太郎", "霧隠才蔵", "百地三太夫", "女忍者", "真田幸村", "望月千代女"],
        "霧隠才蔵": ["服部半藏", "百地三太夫", "猿飞佐助", "风魔小太郎", "女忍者", "望月千代女", "上泉信纲"],
        "百地三太夫": ["霧隠才蔵", "服部半藏", "猿飞佐助", "风魔小太郎", "女忍者", "望月千代女", "上泉信纲"],
        "上泉信纲": ["宫本武藏", "柳生宗矩", "服部半藏", "女忍者", "霧隠才蔵", "百地三太夫", "望月千代女"]
    ]
    
    // 最大选择数量
    private let maxSelectionCount = 5
    
    // 初始化方法
    init(postId: String) {
        self.postId = postId
        // 加载所有角色
        loadAllCharacters()
        // 从postId中提取可能的作者名称
        extractAuthorFromPostId(postId: postId)
    }
    
    // 添加接收postAuthor参数的初始化方法
    init(postId: String, postAuthor: String) {
        self.postId = postId
        // 直接加载所有角色
        loadAllCharacters()
        // 根据传入的作者名称设置作者
        setPostAuthorByName(authorName: postAuthor)
    }
    
    /**
     * 从postId中提取可能的作者名称
     */
    private func extractAuthorFromPostId(postId: String) {
        print("从postId中提取作者: \(postId)")
        
        // 尝试从postId中提取作者名称
        // 检查是否包含已知角色名称
        for character in allCharacters {
            if postId.contains(character.name) {
                setPostAuthorByName(authorName: character.name)
                return
            }
        }
        
        // 如果没有找到匹配的作者，设置一个默认作者
        print("未从postId中找到匹配的作者，设置默认作者")
        if let defaultAuthor = allCharacters.first(where: { $0.name == "岳飞" }) {
            self.postAuthor = defaultAuthor
        } else if !allCharacters.isEmpty {
            self.postAuthor = allCharacters[0]
        }
    }
    
    /**
     * 根据作者名称设置帖子作者
     */
    private func setPostAuthorByName(authorName: String) {
        print("根据名称设置帖子作者: \(authorName)")
        
        // 在allCharacters中查找匹配的角色
        if let author = allCharacters.first(where: { $0.name == authorName }) {
            self.postAuthor = author
            print("找到匹配的作者: \(author.name), 是否在关系字典中: \(characterRelations[author.name] != nil)")
            
            if let relations = characterRelations[author.name] {
                print("作者 \(author.name) 的相关角色: \(relations.joined(separator: ", "))")
            }
        } else {
            print("警告：未找到名为 \(authorName) 的角色，尝试设置默认作者")
            if let defaultAuthor = allCharacters.first(where: { $0.name == "岳飞" }) {
                self.postAuthor = defaultAuthor
            } else if !allCharacters.isEmpty {
                self.postAuthor = allCharacters[0]
            }
        }
    }
    
    /**
     * 加载帖子数据，包括内容和作者
     */
    private func loadPostData() {
        // 模拟帖子数据 - 在实际应用中应从数据库获取
        _ = [
            "蹲在庭院搅拌茶碗时，忽然发现裂纹里嵌着蝶翅鳞粉。十七岁时在伊豆山径迷路，那个舞女用三昧线琴弦为我系上和服带；三年前诺奖演说前夜，看到斯德哥尔摩港口浮冰折射出雪国火花的颜色。答案总在寻找之外闪现，像蝴蝶停在伤口结痂处，振翅时痂壳就成了时空褶皱里的虫洞。",
            "莎士比亚的戏剧作品中对人性的洞察让人叹为观止，特别是《哈姆雷特》中的经典独白。",
            "孔子的教育思想对现代教育仍有重要启示，'因材施教'的理念尤为重要。",
            "达芬奇不仅是艺术家，还是科学家和发明家，他的全能才华令人敬佩。",
            "牛顿的万有引力定律彻底改变了人类对宇宙的理解，为现代物理学奠定了基础。",
            "【1953年冬，普林斯顿】壁炉里的橡木噼啪作响，烟斗的苦味在舌尖停留了整整三小时。今天在《原子科学家公报》签下名字时，钢笔突然变得比中子还沉重——我们打开潘多拉盒子的速度，超过了人类建设道德防火墙的速度。窗外的白杨树在风中画出光的轨迹，像极了四十年前我在布拉格天文台看到的银河。此刻的时空褶皱里，少年时对统一场论的纯粹渴望，与此刻对文明存续的焦虑，正在发生量子纠缠。",
            "康熙六十一年，朕于紫禁城御花园中赏梅，忽见一梅枝傲雪独放，不禁想起少年时与南怀仁讨论天文历法，与徐光启探讨《几何原本》之情景。治国六十载，深感'天下一家'之理，文武之道，一张一弛。"
        ]
        
        // 模拟帖子作者
        _ = [
            AppCharacter(id: "kawabata", name: "川端康成", type: "historical", subtype: "writer", era: "现代", primaryField: "文学家", briefDescription: "日本文学家，诺贝尔文学奖得主，作品《雪国》《千只鹤》等", avatarName: "kawabata", region: "日本", contentAffinities: ["文学": 0.9, "自然": 0.8, "哲思": 0.7]),
            AppCharacter(id: "shakespeare", name: "莎士比亚", type: "historical", subtype: "writer", era: "文艺复兴", primaryField: "戏剧家、诗人", briefDescription: "英国最伟大的戏剧家，作品包括《罗密欧与朱丽叶》《哈姆雷特》等", avatarName: "shakespeare", region: "英国", contentAffinities: ["文学": 0.9, "戏剧": 0.95]),
            AppCharacter(id: "kongzi", name: "孔子", type: "historical", subtype: "philosopher", era: "春秋时期", primaryField: "哲学家、教育家", briefDescription: "儒家学派创始人，中国古代思想家、政治家和教育家", avatarName: "kongzi", region: "中国", contentAffinities: ["哲学": 0.95, "教育": 0.9]),
            AppCharacter(id: "davinci", name: "达芬奇", type: "historical", subtype: "artist", era: "文艺复兴", primaryField: "艺术家、科学家", briefDescription: "意大利文艺复兴时期的艺术家、科学家和发明家", avatarName: "davinci", region: "意大利", contentAffinities: ["艺术": 0.9, "科学": 0.85]),
            AppCharacter(id: "newton", name: "牛顿", type: "historical", subtype: "scientist", era: "近代", primaryField: "物理学家、数学家", briefDescription: "英国物理学家、数学家，发现万有引力定律", avatarName: "newton", region: "英国", contentAffinities: ["物理": 0.95, "数学": 0.9]),
            AppCharacter(id: "einstein", name: "爱因斯坦", type: "historical", subtype: "scientist", era: "近代", primaryField: "物理学家", briefDescription: "相对论创立者，20世纪最伟大的科学家之一", avatarName: "einstein", region: "德国/美国", contentAffinities: ["物理": 0.95, "科学": 0.9]),
            AppCharacter(id: "kangxi", name: "康熙皇帝", type: "historical", subtype: "emperor", era: "清朝", primaryField: "皇帝", briefDescription: "中国清朝第四位皇帝，在位61年，推动科学文化发展", avatarName: "kangxi", region: "中国", contentAffinities: ["政治": 0.95, "文化": 0.9, "科学": 0.85]),
            AppCharacter(id: "sherlock", name: "夏洛克·福尔摩斯", type: "literary", subtype: "detective", era: "维多利亚时代", primaryField: "侦探", briefDescription: "世界上最著名的虚构侦探，由阿瑟·柯南·道尔创造", avatarName: "sherlock", region: "英国伦敦", contentAffinities: ["推理": 0.95, "犯罪": 0.9, "观察": 0.85])
        ]
        
        // 重要修改：始终使用已设置的postAuthor，而不是从postId或内容推断
        // 如果postAuthor为nil，则尝试设置一个默认作者
        if postAuthor == nil {
            print("警告：postAuthor为nil，尝试设置默认作者")
            if let defaultAuthor = allCharacters.first(where: { $0.name == "夏洛克·福尔摩斯" }) {
                self.postAuthor = defaultAuthor
            } else if !allCharacters.isEmpty {
                self.postAuthor = allCharacters[0]
            }
        }
        
        // 调试日志
        print("加载帖子数据 - 作者: \(postAuthor?.name ?? "未知"), 是否在关系字典中: \(postAuthor != nil && characterRelations[postAuthor!.name] != nil)")
        if let author = postAuthor, let relations = characterRelations[author.name] {
            print("作者 \(author.name) 的相关角色: \(relations.joined(separator: ", "))")
        }
    }
    
    /**
     * 加载所有可用角色
     */
    private func loadAllCharacters() {
        print("开始加载角色数据...")
        
        // 首先尝试直接加载characters.json
        if let url = Bundle.main.url(forResource: "characters", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            print("characters.json文件大小: \(data.count) 字节")
            
            // 尝试使用JSONSerialization先验证JSON格式
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any],
                   let characters = dict["characters"] as? [[String: Any]] {
                    print("characters.json包含\(characters.count)个角色 (JSONSerialization验证)")
                    
                    // JSON格式正确，现在尝试解码
                let decoder = JSONDecoder()
                    
                    // 设置解码策略，处理不同的键名格式
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    
                    do {
                let characterData = try decoder.decode(CharacterLibrary.self, from: data)
                allCharacters = characterData.characters
                        print("成功从characters.json加载了\(allCharacters.count)个角色")
                        
                        // 打印一些角色名称作为验证
                        if !allCharacters.isEmpty {
                            let sampleNames = allCharacters.prefix(5).map { $0.name }.joined(separator: ", ")
                            print("加载的角色示例: \(sampleNames)")
                            return
                        }
                    } catch let decoderError {
                        print("使用JSONDecoder解析characters.json失败: \(decoderError)")
                        
                        // 尝试逐个解析角色
                        print("尝试手动解析角色...")
                        var parsedCharacters: [AppCharacter] = []
                        
                        for (index, characterDict) in characters.enumerated() {
                            do {
                                let characterData = try JSONSerialization.data(withJSONObject: characterDict)
                                let character = try decoder.decode(AppCharacter.self, from: characterData)
                                parsedCharacters.append(character)
            } catch {
                                print("解析第\(index)个角色失败: \(error)")
                                // 继续解析下一个角色
                            }
                        }
                        
                        if !parsedCharacters.isEmpty {
                            print("成功手动解析了\(parsedCharacters.count)个角色")
                            allCharacters = parsedCharacters
                            return
                        }
                    }
                }
            } catch let jsonError {
                print("使用JSONSerialization验证characters.json失败: \(jsonError)")
            }
        }
        
        // 如果characters.json加载失败，尝试其他备用文件
        let backupFileNames = ["characters_fixed2", "characters_clean"]
        var charactersLoaded = false
        
        for fileName in backupFileNames {
            print("尝试加载备用文件\(fileName).json...")
            if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
               let data = try? Data(contentsOf: url) {
                print("\(fileName).json文件大小: \(data.count) 字节")
                
                do {
                    // 解析JSON数据
                    let decoder = JSONDecoder()
                    let characterData = try decoder.decode(CharacterLibrary.self, from: data)
                    allCharacters = characterData.characters
                    print("成功从\(fileName).json加载了\(allCharacters.count)个角色")
                    
                    // 打印一些角色名称作为验证
                    let sampleNames = allCharacters.prefix(5).map { $0.name }.joined(separator: ", ")
                    print("加载的角色示例: \(sampleNames)")
                    
                    charactersLoaded = true
                    break
                } catch let error {
                    print("解析\(fileName).json失败: \(error)")
            }
        } else {
                print("无法找到或读取\(fileName).json文件")
            }
        }
        
        // 如果所有文件都加载失败，使用硬编码的备用数据
        if !charactersLoaded {
            print("所有角色JSON文件加载失败，使用硬编码的备用数据")
            loadFallbackCharacters()
        }
    }
    
    /**
     * 加载备用角色数据
     */
    private func loadFallbackCharacters() {
        // 创建基本的历史人物库，首先保留现有的角色
        let existingCharacters = [
            // 已有基础角色
            AppCharacter(id: "einstein", name: "爱因斯坦", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "相对论创立者，20世纪最伟大的科学家之一", avatarName: "einstein", region: "德国/美国", contentAffinities: ["物理": 0.95, "科学": 0.9]),
            
            AppCharacter(id: "shakespeare", name: "莎士比亚", type: "historical", subtype: "writer", era: "文艺复兴", primaryField: "戏剧家、诗人", briefDescription: "英国最伟大的戏剧家，作品包括《罗密欧与朱丽叶》《哈姆雷特》等", avatarName: "shakespeare", region: "英国", contentAffinities: ["文学": 0.9, "戏剧": 0.95]),
            
            AppCharacter(id: "kongzi", name: "孔子", type: "historical", subtype: "philosopher", era: "春秋时期", primaryField: "哲学家、教育家", briefDescription: "儒家学派创始人，中国古代思想家、政治家和教育家", avatarName: "kongzi", region: "中国", contentAffinities: ["哲学": 0.95, "教育": 0.9]),
            
            AppCharacter(id: "davinci", name: "达芬奇", type: "historical", subtype: "artist", era: "文艺复兴", primaryField: "艺术家、科学家", briefDescription: "意大利文艺复兴时期的艺术家、科学家和发明家", avatarName: "davinci", region: "意大利", contentAffinities: ["艺术": 0.9, "科学": 0.85]),
            
            AppCharacter(id: "newton", name: "牛顿", type: "historical", subtype: "scientist", era: "近代", primaryField: "物理学家、数学家", briefDescription: "英国物理学家、数学家，发现万有引力定律", avatarName: "newton", region: "英国", contentAffinities: ["物理": 0.95, "数学": 0.9]),
            
            AppCharacter(id: "kawabata", name: "川端康成", type: "historical", subtype: "writer", era: "现代", primaryField: "文学家", briefDescription: "日本文学家，诺贝尔文学奖得主，作品《雪国》《千只鹤》等", avatarName: "kawabata", region: "日本", contentAffinities: ["文学": 0.9, "自然": 0.8, "哲思": 0.7]),
            
            // 添加女忍者和相关角色
            AppCharacter(id: "kunoichi", name: "女忍者", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代的女性忍者，擅长情报收集和伪装", avatarName: "kunoichi", region: "日本", contentAffinities: ["武术": 0.9, "情报": 0.95, "伪装": 0.9]),
            
            AppCharacter(id: "hattori", name: "服部半藏", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代著名忍者，伊贺流忍术大师", avatarName: "hattori", region: "日本", contentAffinities: ["武术": 0.95, "战略": 0.9]),
            
            AppCharacter(id: "fuma", name: "风魔小太郎", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代著名忍者，风魔一族首领", avatarName: "fuma", region: "日本", contentAffinities: ["武术": 0.95, "暗杀": 0.9]),
            
            AppCharacter(id: "mochizuki", name: "望月千代女", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代女忍者，擅长伪装和医术", avatarName: "mochizuki", region: "日本", contentAffinities: ["医术": 0.9, "伪装": 0.95]),
            
            AppCharacter(id: "kamiizumi", name: "上泉信纲", type: "historical", subtype: "samurai", era: "战国时代", primaryField: "剑术家", briefDescription: "日本战国时代剑术家，新阴流创始人", avatarName: "kamiizumi", region: "日本", contentAffinities: ["武术": 0.95, "剑道": 0.9]),
            
            AppCharacter(id: "sarutobi", name: "猿飞佐助", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代传说中的忍者，甲贺流忍术大师", avatarName: "sarutobi", region: "日本", contentAffinities: ["武术": 0.95, "隐身": 0.9]),
            
            AppCharacter(id: "kirigakure", name: "霧隠才蔵", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代著名忍者，伊贺十人众之一", avatarName: "kirigakure", region: "日本", contentAffinities: ["武术": 0.9, "潜行": 0.95]),
            
            AppCharacter(id: "momochi", name: "百地三太夫", type: "historical", subtype: "ninja", era: "战国时代", primaryField: "忍者", briefDescription: "日本战国时代伊贺忍者首领之一", avatarName: "momochi", region: "日本", contentAffinities: ["武术": 0.95, "领导": 0.9])
        ]
        
        // 添加更多角色
        let additionalCharacters = [
            // 科学家
            AppCharacter(id: "bohr", name: "玻尔", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "丹麦物理学家，量子力学的重要奠基人", avatarName: "bohr", region: "丹麦", contentAffinities: ["物理": 0.95, "量子力学": 0.9]),
            
            AppCharacter(id: "planck", name: "普朗克", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "德国物理学家，量子论创始人", avatarName: "planck", region: "德国", contentAffinities: ["物理": 0.95, "量子物理": 0.9]),
            
            AppCharacter(id: "heisenberg", name: "海森堡", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "德国物理学家，量子力学奠基人之一，提出不确定性原理", avatarName: "heisenberg", region: "德国", contentAffinities: ["物理": 0.95, "量子力学": 0.9]),
            
            AppCharacter(id: "feynman", name: "费曼", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "美国物理学家，量子电动力学的主要贡献者", avatarName: "feynman", region: "美国", contentAffinities: ["物理": 0.95, "科普": 0.85]),
            
            AppCharacter(id: "hawking", name: "霍金", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "英国物理学家，黑洞理论的重要贡献者", avatarName: "hawking", region: "英国", contentAffinities: ["物理": 0.95, "宇宙学": 0.9]),
            
            AppCharacter(id: "oppenheimer", name: "奥本海默", type: "historical", subtype: "scientist", era: "现代", primaryField: "物理学家", briefDescription: "美国物理学家，曼哈顿计划负责人", avatarName: "oppenheimer", region: "美国", contentAffinities: ["物理": 0.95, "核物理": 0.9]),
            
            AppCharacter(id: "turing", name: "图灵", type: "historical", subtype: "scientist", era: "现代", primaryField: "数学家、计算机科学家", briefDescription: "英国数学家，计算机科学之父", avatarName: "turing", region: "英国", contentAffinities: ["计算机": 0.95, "数学": 0.9]),
            
            AppCharacter(id: "kekule", name: "凯库勒", type: "historical", subtype: "scientist", era: "近代", primaryField: "化学家", briefDescription: "德国化学家，发现苯环结构", avatarName: "kekule", region: "德国", contentAffinities: ["化学": 0.95, "有机化学": 0.9]),
            
            AppCharacter(id: "ramanujan", name: "拉马努金", type: "historical", subtype: "scientist", era: "现代", primaryField: "数学家", briefDescription: "印度数学家，数论天才", avatarName: "ramanujan", region: "印度", contentAffinities: ["数学": 0.95, "数论": 0.9]),
            
            // 哲学家
            AppCharacter(id: "kant", name: "康德", type: "historical", subtype: "philosopher", era: "启蒙时代", primaryField: "哲学家", briefDescription: "德国哲学家，批判哲学创始人", avatarName: "kant", region: "德国", contentAffinities: ["哲学": 0.95, "伦理学": 0.9]),
            
            AppCharacter(id: "nietzsche", name: "尼采", type: "historical", subtype: "philosopher", era: "近代", primaryField: "哲学家", briefDescription: "德国哲学家，著有《查拉图斯特拉如是说》", avatarName: "nietzsche", region: "德国", contentAffinities: ["哲学": 0.95, "存在主义": 0.9]),
            
            AppCharacter(id: "foucault", name: "福柯", type: "historical", subtype: "philosopher", era: "现代", primaryField: "哲学家", briefDescription: "法国哲学家，后结构主义代表人物", avatarName: "foucault", region: "法国", contentAffinities: ["哲学": 0.95, "社会理论": 0.9]),
            
            AppCharacter(id: "sartre", name: "萨特", type: "historical", subtype: "philosopher", era: "现代", primaryField: "哲学家", briefDescription: "法国存在主义哲学家", avatarName: "sartre", region: "法国", contentAffinities: ["哲学": 0.95, "存在主义": 0.9]),
            
            AppCharacter(id: "beauvoir", name: "波伏娃", type: "historical", subtype: "philosopher", era: "现代", primaryField: "哲学家", briefDescription: "法国女性主义哲学家", avatarName: "beauvoir", region: "法国", contentAffinities: ["哲学": 0.95, "女性主义": 0.9]),
            
            AppCharacter(id: "camus", name: "加缪", type: "historical", subtype: "philosopher", era: "现代", primaryField: "哲学家", briefDescription: "法国作家、哲学家，荒诞哲学代表", avatarName: "camus", region: "法国", contentAffinities: ["哲学": 0.95, "文学": 0.9]),
            
            // 作家
            AppCharacter(id: "tolstoy", name: "托尔斯泰", type: "historical", subtype: "writer", era: "近代", primaryField: "作家", briefDescription: "俄国文学家，作品《战争与和平》", avatarName: "tolstoy", region: "俄国", contentAffinities: ["文学": 0.95, "哲学": 0.8]),
            
            AppCharacter(id: "dostoevsky", name: "陀思妥耶夫斯基", type: "historical", subtype: "writer", era: "近代", primaryField: "作家", briefDescription: "俄国作家，作品《罪与罚》", avatarName: "dostoevsky", region: "俄国", contentAffinities: ["文学": 0.95, "心理": 0.9]),
            
            AppCharacter(id: "kafka", name: "卡夫卡", type: "historical", subtype: "writer", era: "现代", primaryField: "作家", briefDescription: "捷克作家，作品《变形记》", avatarName: "kafka", region: "捷克", contentAffinities: ["文学": 0.95, "荒诞": 0.9]),
            
            AppCharacter(id: "borges", name: "博尔赫斯", type: "historical", subtype: "writer", era: "现代", primaryField: "作家", briefDescription: "阿根廷作家，魔幻现实主义先驱", avatarName: "borges", region: "阿根廷", contentAffinities: ["文学": 0.95, "哲学": 0.9]),
            
            AppCharacter(id: "marquez", name: "马尔克斯", type: "historical", subtype: "writer", era: "现代", primaryField: "作家", briefDescription: "哥伦比亚作家，作品《百年孤独》", avatarName: "marquez", region: "哥伦比亚", contentAffinities: ["文学": 0.95, "魔幻现实主义": 0.9]),
            
            AppCharacter(id: "woolf", name: "伍尔夫", type: "historical", subtype: "writer", era: "现代", primaryField: "作家", briefDescription: "英国女作家，现代主义代表人物", avatarName: "woolf", region: "英国", contentAffinities: ["文学": 0.95, "女性主义": 0.9]),
            
            // 艺术家
            AppCharacter(id: "picasso", name: "毕加索", type: "historical", subtype: "artist", era: "现代", primaryField: "画家", briefDescription: "西班牙画家，立体主义创始人", avatarName: "picasso", region: "西班牙", contentAffinities: ["艺术": 0.95, "绘画": 0.9]),
            
            AppCharacter(id: "chagall", name: "夏加尔", type: "historical", subtype: "artist", era: "现代", primaryField: "画家", briefDescription: "俄籍法国画家，超现实主义先驱", avatarName: "chagall", region: "法国", contentAffinities: ["艺术": 0.95, "绘画": 0.9]),
            
            AppCharacter(id: "dali", name: "达利", type: "historical", subtype: "artist", era: "现代", primaryField: "画家", briefDescription: "西班牙超现实主义画家", avatarName: "dali", region: "西班牙", contentAffinities: ["艺术": 0.95, "超现实主义": 0.9]),
            
            AppCharacter(id: "monet", name: "莫奈", type: "historical", subtype: "artist", era: "印象派", primaryField: "画家", briefDescription: "法国印象派画家，作品《睡莲》系列", avatarName: "monet", region: "法国", contentAffinities: ["艺术": 0.95, "风景": 0.9]),
            
            AppCharacter(id: "hokusai", name: "葛饰北斋", type: "historical", subtype: "artist", era: "江户时期", primaryField: "浮世绘画家", briefDescription: "日本浮世绘画家，作品《富岳三十六景》", avatarName: "hokusai", region: "日本", contentAffinities: ["艺术": 0.95, "浮世绘": 0.9]),
            
            AppCharacter(id: "kandinsky", name: "康定斯基", type: "historical", subtype: "artist", era: "现代", primaryField: "画家", briefDescription: "俄籍德国画家，抽象艺术先驱", avatarName: "kandinsky", region: "德国", contentAffinities: ["艺术": 0.95, "抽象": 0.9]),
            
            // 音乐家
            AppCharacter(id: "beethoven", name: "贝多芬", type: "historical", subtype: "musician", era: "古典主义", primaryField: "作曲家", briefDescription: "德国作曲家，古典主义音乐大师", avatarName: "beethoven", region: "德国", contentAffinities: ["音乐": 0.95, "交响乐": 0.9]),
            
            AppCharacter(id: "bach", name: "巴赫", type: "historical", subtype: "musician", era: "巴洛克", primaryField: "作曲家", briefDescription: "德国作曲家，巴洛克音乐代表人物", avatarName: "bach", region: "德国", contentAffinities: ["音乐": 0.95, "宗教音乐": 0.9]),
            
            AppCharacter(id: "chopin", name: "肖邦", type: "historical", subtype: "musician", era: "浪漫主义", primaryField: "作曲家", briefDescription: "波兰作曲家，钢琴诗人", avatarName: "chopin", region: "波兰", contentAffinities: ["音乐": 0.95, "钢琴": 0.9]),
            
            AppCharacter(id: "lennon", name: "约翰·列侬", type: "historical", subtype: "musician", era: "现代", primaryField: "音乐家", briefDescription: "英国音乐家，披头士乐队成员", avatarName: "lennon", region: "英国", contentAffinities: ["音乐": 0.95, "摇滚": 0.9]),
            
            AppCharacter(id: "jackson", name: "迈克尔·杰克逊", type: "historical", subtype: "musician", era: "现代", primaryField: "音乐家", briefDescription: "美国流行音乐巨星，流行乐之王", avatarName: "jackson", region: "美国", contentAffinities: ["音乐": 0.95, "流行": 0.9]),
            
            // 政治家和历史人物
            AppCharacter(id: "churchill", name: "丘吉尔", type: "historical", subtype: "politician", era: "现代", primaryField: "政治家", briefDescription: "英国首相，二战期间领导英国", avatarName: "churchill", region: "英国", contentAffinities: ["政治": 0.95, "战争": 0.9]),
            
            AppCharacter(id: "lincoln", name: "林肯", type: "historical", subtype: "politician", era: "近代", primaryField: "政治家", briefDescription: "美国第16任总统，废除奴隶制", avatarName: "lincoln", region: "美国", contentAffinities: ["政治": 0.95, "人权": 0.9]),
            
            AppCharacter(id: "gandhi", name: "甘地", type: "historical", subtype: "politician", era: "现代", primaryField: "政治家", briefDescription: "印度独立运动领袖，非暴力抵抗倡导者", avatarName: "gandhi", region: "印度", contentAffinities: ["政治": 0.95, "和平": 0.9]),
            
            AppCharacter(id: "napoleon", name: "拿破仑", type: "historical", subtype: "military", era: "近代", primaryField: "军事家、政治家", briefDescription: "法国军事家和政治家，欧洲大陆征服者", avatarName: "napoleon", region: "法国", contentAffinities: ["军事": 0.95, "政治": 0.9]),
            
            AppCharacter(id: "alexander", name: "亚历山大大帝", type: "historical", subtype: "military", era: "古代", primaryField: "军事家、国王", briefDescription: "马其顿国王，征服者", avatarName: "alexander", region: "马其顿", contentAffinities: ["军事": 0.95, "政治": 0.9])
        ]
        
        // 合并所有角色
        allCharacters = existingCharacters + additionalCharacters
    }
    
    /**
     * 加载历史人物数据
     */
    func loadHistoricalFigures() {
        print("开始加载历史人物数据...")
        isLoading = true
        
        // 加载所有角色
        loadAllCharacters()
        
        // 检查是否成功加载了角色
        print("从JSON加载的角色数量: \(allCharacters.count)")
        
        // 如果角色数量太少，可能是加载失败，尝试使用备用数据
        if allCharacters.count < 50 {
            print("警告：从JSON加载的角色数量太少，可能是加载失败，尝试使用备用数据")
            loadFallbackCharacters()
            print("使用备用数据后的角色数量: \(allCharacters.count)")
        }
        
        // 加载帖子数据
        loadPostData()
        print("当前帖子作者: \(postAuthor?.name ?? "未设置")")
        
        // 获取所有可用的历史人物
        var allFigures: [CommentHistoricalFigure] = []
        
        // 遍历allCharacters并创建CommentHistoricalFigure对象
        for character in allCharacters {
            // 使用新的初始化方法
            let figure = CommentHistoricalFigure(from: character)
            allFigures.append(figure)
        }
        
        // 设置可用的历史人物
        availableFigures = allFigures
        
        // 构建相关角色网络
        buildRelevantFiguresNetwork()
        
        // 添加调试日志
        print("历史人物数据加载完成 - 总角色数: \(availableFigures.count), 相关角色数: \(relevantFigures.count)")
        
        // 检查是否成功加载了角色
        if availableFigures.isEmpty {
            print("警告：没有加载到任何角色！")
        } else {
            // 打印一些角色名称作为验证
            let sampleNames = availableFigures.prefix(10).map { $0.name }.joined(separator: ", ")
            print("加载的角色示例: \(sampleNames)")
        }
        
        // 检查特定角色是否在可用列表中
        for name in ["庄子", "老子", "孟子", "爱因斯坦", "莎士比亚"] {
            if let figure = availableFigures.first(where: { $0.name == name }) {
                let isMarkedAsRelevant = relevantFigures.contains(figure.id)
                print("角色 \(name) 是否在可用角色列表中: \(true), 是否被标记为相关: \(isMarkedAsRelevant)")
            } else {
                print("角色 \(name) 是否在可用角色列表中: \(false)")
            }
        }
        
        // 输出当前作者信息
        if let author = postAuthor {
            print("当前作者: \(author.name), 是否在关系字典中: \(characterRelations[author.name] != nil)")
        } else {
            print("当前没有作者")
        }
        
        isLoading = false
    }
    
    /**
     * 从时代字符串获取年份
     */
    private func getYearFromEra(_ era: String) -> String {
        switch era {
        case "古希腊":
            return "公元前400年"
        case "古罗马":
            return "公元前100年"
        case "中国古代":
            return "公元前500年"
        case "中国近代":
            return "1900年"
        case "文艺复兴":
            return "1500年"
        case "启蒙运动":
            return "1700年"
        case "工业革命":
            return "1800年"
        case "现代":
            return "1900年"
        case "当代":
            return "2000年"
        case "中世纪":
            return "1000年"
        case "春秋战国":
            return "公元前500年"
        case "汉朝":
            return "公元前200年"
        case "唐朝":
            return "700年"
        case "宋朝":
            return "1000年"
        case "明朝":
            return "1500年"
        case "清朝":
            return "1700年"
        case "民国":
            return "1920年"
        default:
            return "未知"
        }
    }
    
    /**
     * 构建并标记相关角色网络
     * 这个方法通过全面分析角色关系网络来标记相关角色
     */
    private func buildRelevantFiguresNetwork() {
        // 清空之前的相关角色标记
        relevantFigures.removeAll()
        
        guard let currentAuthor = postAuthor else { 
            print("构建关系网络失败：没有当前作者")
            return 
        }
        
        print("开始构建关系网络 - 当前作者: \(currentAuthor.name)")
        
        // 检查当前作者是否在characterRelations中有定义
        let authorHasDefinedRelations = characterRelations[currentAuthor.name] != nil
        
        if let authorRelations = characterRelations[currentAuthor.name] {
            print("作者 \(currentAuthor.name) 在 characterRelations 中定义的关系: \(authorRelations.joined(separator: ", "))")
        } else {
            print("警告：作者 \(currentAuthor.name) 在 characterRelations 中没有定义关系")
        }
        
        // 已标记相关的角色ID集合
        var processedRelevantIds = Set<UUID>()
        var processedNames = Set<String>()
        
        // 1. 首先标记与当前作者直接相关的角色
        let directlyRelatedCharacters = getDirectlyRelatedCharacters(for: currentAuthor)
        print("直接相关角色数量: \(directlyRelatedCharacters.count)")
        
        for character in directlyRelatedCharacters {
            if let figure = availableFigures.first(where: { $0.name == character.name }) {
                relevantFigures.insert(figure.id)
                processedRelevantIds.insert(figure.id)
                processedNames.insert(character.name)
            } else {
                print("警告：未找到相关角色 \(character.name) 对应的 CommentHistoricalFigure")
            }
        }
        
        // 2. 标记与当前作者有二级关系的角色(相关角色的相关角色)
        if authorHasDefinedRelations {
            let secondaryRelations = getSecondaryRelatedCharacters(for: currentAuthor)
            print("二级相关角色数量: \(secondaryRelations.count)")
            
            for character in secondaryRelations {
                if let figure = availableFigures.first(where: { $0.name == character.name }) {
                    relevantFigures.insert(figure.id)
                    processedRelevantIds.insert(figure.id)
                    processedNames.insert(character.name)
                }
            }
        }
        
        // 3. 确保双向关系正确标记
        for figure in availableFigures {
            // 如果角色尚未被标记为相关
            if !processedRelevantIds.contains(figure.id) {
                // 查找完整的角色信息
                if let character = allCharacters.first(where: { $0.name == figure.name }) {
                    // 检查这个角色是否与当前作者相关
                    let isRelated = checkRelationship(between: character, and: currentAuthor)
                    if isRelated {
                        relevantFigures.insert(figure.id)
                        processedRelevantIds.insert(figure.id)
                        processedNames.insert(character.name)
                        print("通过双向关系检查，标记 \(character.name) 为相关角色")
                    }
                }
            }
        }
        
        // 4. 特殊处理：检查当前作者是否在其他角色的关系列表中
        for (characterName, relatedNames) in characterRelations {
            if relatedNames.contains(currentAuthor.name) {
                // 如果某个角色的关系列表中包含当前作者，则该角色应被标记为相关
                if let figure = availableFigures.first(where: { $0.name == characterName }),
                   !processedRelevantIds.contains(figure.id) {
                    relevantFigures.insert(figure.id)
                    processedRelevantIds.insert(figure.id)
                    processedNames.insert(characterName)
                    print("通过反向关系检查，标记 \(characterName) 为相关角色")
                }
            }
        }
        
        print("关系网络构建完成 - 相关角色数量: \(relevantFigures.count)")
        print("已处理的相关角色名称: \(processedNames.joined(separator: ", "))")
        
        // 检查特定角色是否被标记为相关
        for name in ["庄子", "老子", "孟子", "康熙皇帝"] {
            if let figure = availableFigures.first(where: { $0.name == name }) {
                let isMarkedAsRelevant = relevantFigures.contains(figure.id)
                print("角色 \(name) 是否被标记为相关: \(isMarkedAsRelevant)")
            } else {
                print("警告：未找到角色 \(name) 对应的 CommentHistoricalFigure")
            }
        }
    }
    
    /**
     * 检查两个角色之间是否存在关系（双向检查）
     */
    private func checkRelationship(between character1: AppCharacter, and character2: AppCharacter) -> Bool {
        // 检查characterRelations字典中的关系
        if let relatedNames = characterRelations[character1.name], relatedNames.contains(character2.name) {
            print("发现关系: \(character1.name) 与 \(character2.name) 相关")
            return true
        }
        
        if let relatedNames = characterRelations[character2.name], relatedNames.contains(character1.name) {
            print("发现关系: \(character2.name) 与 \(character1.name) 相关")
            return true
        }
        
        return false
    }
    
    /**
     * 检查某角色是否与目标角色相关
     */
    private func isCharacterRelatedTo(_ character: AppCharacter, targetCharacter: AppCharacter) -> Bool {
        // 检查characterRelations字典
        if let relatedNames = characterRelations[character.name], relatedNames.contains(targetCharacter.name) {
            return true
        }
        
        return false
    }
    
    /**
     * 获取与角色有二级关系的其他角色
     * 即"相关角色的相关角色"
     */
    private func getSecondaryRelatedCharacters(for character: AppCharacter) -> [AppCharacter] {
        var secondaryRelatedCharacters = [AppCharacter]()
        let directlyRelated = getDirectlyRelatedCharacters(for: character)
        
        // 对于每个直接相关角色，获取它们的直接相关角色
        for relatedCharacter in directlyRelated {
            let secondaryRelated = getDirectlyRelatedCharacters(for: relatedCharacter)
            
            // 过滤掉原始角色和已经在直接相关列表中的角色
            for secondary in secondaryRelated {
                if secondary.id != character.id && !directlyRelated.contains(where: { $0.id == secondary.id }) {
                    if !secondaryRelatedCharacters.contains(where: { $0.id == secondary.id }) {
                        secondaryRelatedCharacters.append(secondary)
                    }
                }
            }
        }
        
        return secondaryRelatedCharacters
    }
    
    /**
     * 获取直接关联的角色（根据角色对象）
     * 统一使用名称查找相关角色
     */
    private func getDirectlyRelatedCharacters(for character: AppCharacter) -> [AppCharacter] {
        var relatedCharacters: [AppCharacter] = []
        
        // 从字典中获取相关角色
        if let relatedNames = characterRelations[character.name] {
            print("获取 \(character.name) 的相关角色 - 在字典中定义的关系: \(relatedNames.joined(separator: ", "))")
            
            // 查找这些名称对应的角色对象
            for name in relatedNames {
                if let relatedCharacter = allCharacters.first(where: { $0.name == name }) {
                    relatedCharacters.append(relatedCharacter)
                } else {
                    print("警告：未找到相关角色 \(name) 对应的 AppCharacter")
                }
            }
        } else {
            print("警告：\(character.name) 在 characterRelations 中没有定义关系")
            
            // 如果在字典中没有找到关系，尝试查找反向关系
            for (characterName, relatedNames) in characterRelations {
                if relatedNames.contains(character.name) {
                    if let relatedCharacter = allCharacters.first(where: { $0.name == characterName }) {
                        relatedCharacters.append(relatedCharacter)
                        print("通过反向关系找到相关角色: \(characterName)")
                    }
                }
            }
            
            // 删除根据类型和时代查找的逻辑
        }
        
        print("获取到 \(character.name) 的相关角色数量: \(relatedCharacters.count)")
        return relatedCharacters
    }
    
    /**
     * 获取推荐角色
     */
    private func getRecommendedCharacters() -> [AppCharacter] {
        guard let author = postAuthor else {
            // 如果没有设置作者，返回空数组
            return []
        }
        
        // 只返回直接关联的角色
        return getDirectlyRelatedCharacters(for: author)
    }
    
    /**
     * 获取其他非推荐角色
     */
    private func getOtherCharacters(excluding recommendedCharacters: [AppCharacter]) -> [AppCharacter] {
        let recommendedIds = Set(recommendedCharacters.map { $0.id })
        return allCharacters.filter { !recommendedIds.contains($0.id) }
    }
    
    /**
     * 根据搜索文本和分类筛选历史人物
     */
    func filteredFigures(searchText: String, category: String) -> [CommentHistoricalFigure] {
        // 确保有可用角色
        if availableFigures.isEmpty {
            print("警告：availableFigures为空，无法进行筛选")
            return []
        }
        
        // 打印当前可用角色总数，帮助调试
        print("当前可用角色总数: \(availableFigures.count)")
        
        var filtered = availableFigures
        
        // 应用搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { figure in
                figure.name.localizedCaseInsensitiveContains(searchText) ||
                figure.field.localizedCaseInsensitiveContains(searchText) ||
                figure.introduction.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 应用分类过滤
        if category != "全部" {
            if category == "最近" {
                // 获取最近使用的历史人物
                filtered = getRecentlyUsedFigures()
            } else if category == "关注" {
                // 获取用户关注的历史人物
                filtered = getFollowedFigures()
            } else {
                // 根据角色类型筛选
                let typeMapping = [
                    "历史人物": "historical",
                    "文学角色": "literary",
                    "电影角色": "movie",
                    "动漫角色": "anime",
                    "神话角色": "mythological",
                    "电视剧角色": "tv",
                    "游戏角色": "game",
                    "虚拟主播": "vtuber"
                ]
                
                if let typeFilter = typeMapping[category] {
                    filtered = filtered.filter { figure in
                        // 查找对应的AppCharacter以获取type
                        if let character = allCharacters.first(where: { $0.name == figure.name }) {
                            return character.type == typeFilter
                        }
                        return false
                    }
                }
            }
        } else {
            // "全部"分类 - 确保不进行任何过滤，显示所有角色
            filtered = availableFigures
            print("选择了'全部'分类，显示所有\(filtered.count)个角色")
        }
        
        // 打印过滤后的角色数量
        print("过滤后的角色数量: \(filtered.count)，类别: \(category)，搜索文本: \(searchText)")
        
        // 将相关角色排在最前面
        let relevantFigures = filtered.filter { isRelevant($0) }
        let nonRelevantFigures = filtered.filter { !isRelevant($0) }
        
        let result = relevantFigures + nonRelevantFigures
        print("最终返回角色数量: \(result.count)")
        
        return result
    }
    
    /**
     * 获取最近使用的历史人物
     */
    private func getRecentlyUsedFigures() -> [CommentHistoricalFigure] {
        // 这里应该从UserDefaults或其他存储中获取最近使用的历史人物
        // 简化实现，返回前3个人物
        return Array(availableFigures.prefix(3))
    }
    
    /**
     * 获取用户关注的历史人物
     */
    private func getFollowedFigures() -> [CommentHistoricalFigure] {
        // 这里应该从用户数据中获取关注的历史人物
        // 简化实现，返回一些示例人物
        let followedNames = ["爱因斯坦", "孔子", "莎士比亚"]
        return availableFigures.filter { followedNames.contains($0.name) }
    }
    
    /**
     * 检查历史人物是否与帖子相关
     */
    func isRelevant(_ figure: CommentHistoricalFigure) -> Bool {
        // 只有当 relevantFigures 非空且包含该角色 ID 时才返回 true
        return !relevantFigures.isEmpty && relevantFigures.contains(figure.id)
    }
    
    /**
     * 检查历史人物是否已被选择
     */
    func isSelected(_ figure: CommentHistoricalFigure) -> Bool {
        return selectedFigures.contains { $0.id == figure.id }
    }
    
    /**
     * 选择或取消选择历史人物
     */
    func toggleSelection(_ figure: CommentHistoricalFigure) {
        if let index = selectedFigures.firstIndex(where: { $0.id == figure.id }) {
            // 已选择，取消选择
            selectedFigures.remove(at: index)
        } else {
            // 未选择，添加到选择列表
            if selectedFigures.count < maxSelectionCount {
                selectedFigures.append(figure)
            } else {
                // 超出最大选择数量，显示提示
                errorMessage = "最多可选择\(maxSelectionCount)位历史人物"
            }
        }
    }
    
    /**
     * 一键邀请功能
     */
    func oneClickInvite() {
        // 清空当前选择
        selectedFigures.removeAll()
        
        // 选择最相关的3个历史人物
        let relevantFigures = availableFigures.filter { isRelevant($0) }
        let figureCount = min(3, relevantFigures.count)
        
        if figureCount > 0 {
            // 有相关角色时，选择相关角色
            selectedFigures = Array(relevantFigures.prefix(figureCount))
            print("一键邀请：选择了\(figureCount)个相关角色")
        } else {
            // 如果没有相关人物，尝试选择关注的角色
            let followedFigures = getFollowedFigures()
            if !followedFigures.isEmpty {
                // 有关注角色时，选择关注角色
                let followCount = min(3, followedFigures.count)
                selectedFigures = Array(followedFigures.prefix(followCount))
                print("一键邀请：选择了\(followCount)个关注角色")
            } else {
                // 如果没有关注角色，使用帖子ID作为随机种子，确保相同帖子推荐相同角色，不同帖子推荐不同角色
                var generator = SeededRandomNumberGenerator(seed: postId.hashValue)
                let shuffledFigures = availableFigures.shuffled(using: &generator)
                let randomCount = min(3, shuffledFigures.count)
                selectedFigures = Array(shuffledFigures.prefix(randomCount))
                print("一键邀请：随机选择了\(randomCount)个角色，使用帖子ID作为种子")
            }
        }
    }
    
    /**
     * 基于种子的随机数生成器
     * 用于确保相同种子产生相同的随机序列
     */
    private struct SeededRandomNumberGenerator: RandomNumberGenerator {
        private var seed: Int
        
        init(seed: Int) {
            self.seed = seed
            // 使用种子初始化随机数序列
            srand48(seed)
        }
        
        mutating func next() -> UInt64 {
            // 使用drand48()生成一个0到1之间的随机数，然后转换为UInt64
            return UInt64(drand48() * Double(UInt64.max))
        }
    }
    
    /**
     * 获取同区域的角色
     */
    private func getSameRegionCharacters(for author: AppCharacter) -> [AppCharacter] {
        return allCharacters.filter { character in
            character.id != author.id &&
            !character.region.isEmpty &&
            character.region == author.region
        }
    }
    
    /**
     * 邀请选中的历史人物参与讨论
     */
    func inviteSelectedFigures() {
        guard !selectedFigures.isEmpty else {
            print("⚠️ 没有选择历史人物，取消邀请")
            return
        }
        
        // 保存最近使用的历史人物
        saveRecentlyUsedFigures()
        
        print("🚀 邀请历史人物参与讨论: \(selectedFigures.map { $0.name }.joined(separator: ", "))")
        
        // 获取帖子内容并检查是否有效
        if let content = getPostContent() {
            print("📝 帖子内容长度: \(content.count)字")
        } else {
            print("⚠️ 无法获取帖子内容")
            return
        }
        
        // 获取所有选中角色的ID并确保ID有效
        var characterIDs = [String]()
        var invalidCharacterNames = [String]()
        
        for figure in selectedFigures {
            let characterID = getCharacterID(for: figure.name)
            if !characterID.isEmpty {
                characterIDs.append(characterID)
            } else {
                invalidCharacterNames.append(figure.name)
            }
        }
        
        if !invalidCharacterNames.isEmpty {
            print("⚠️ 无法获取以下人物的有效ID: \(invalidCharacterNames.joined(separator: ", "))")
        }
        
        guard !characterIDs.isEmpty else {
            print("⚠️ 没有有效的角色ID，取消邀请")
            return
        }
        
        print("📣 邀请角色: \(characterIDs.joined(separator: ", ")), 帖子ID: \(postId)")
        
        // 获取帖子作者信息
        let postAuthorName = postAuthor?.name
        
        // 使用VirtualCharacterService的邀请方法，传递帖子作者
        let virtualCharacterService = VirtualCharacterService.shared
        virtualCharacterService.inviteCharactersToComment(characterIDs: characterIDs, postId: postId, postAuthor: postAuthorName)
        
        // 发送通知，通知其他组件历史人物已被邀请
        NotificationCenter.default.post(
            name: Notification.Name("HistoricalFiguresInvited"),
            object: nil,
            userInfo: ["postId": postId, "figures": selectedFigures]
        )
        
        // 添加额外的通知，确保帖子详情页面立即刷新评论列表
        let finalPostId = postId // 捕获局部变量，避免在闭包中使用self
        
        // 立即触发一次刷新，确保UI准备好
        DispatchQueue.main.async {
            // 尝试直接触发帖子的 objectWillChange
            let viewModel = PostViewModel.shared
            if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == finalPostId }) {
                // 强制触发 objectWillChange 通知
                viewModel.posts[postIndex].objectWillChange.send()
                
                // 发送预备通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("PrepareForNewComments"),
                    object: nil,
                    userInfo: ["postID": finalPostId]
                )
            }
        }
        
        // 延迟一段时间后再次刷新，确保评论已经生成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 发送刷新通知
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshPostComments"),
                object: nil,
                userInfo: [
                    "postID": finalPostId,
                    "immediateDisplay": true,
                    "preventScroll": true
                ]
            )
            
            // 确保详情页面的评论列表立即刷新
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceRefreshComments"),
                object: nil,
                userInfo: [
                    "keepExpandState": true,
                    "preventScroll": true,
                    "immediateDisplay": true
                ]
            )
            
            // 再次尝试触发帖子的 objectWillChange
            let viewModel = PostViewModel.shared
            if let postIndex = viewModel.posts.firstIndex(where: { $0.id.uuidString == finalPostId }) {
                // 强制触发 objectWillChange 通知
                viewModel.posts[postIndex].objectWillChange.send()
                
                // 创建一个临时副本并重新赋值，强制 SwiftUI 刷新
                let tempPost = viewModel.posts[postIndex]
                viewModel.posts[postIndex] = tempPost
            }
        }
    }
    
    /**
     * 保存最近使用的历史人物
     */
    private func saveRecentlyUsedFigures() {
        // 这里应该将选择的历史人物保存到UserDefaults或其他存储中
    }
    
    /**
     * 显示历史人物预览
     */
    func showPreview(for figure: CommentHistoricalFigure) {
        // 这里应该显示历史人物的详细信息预览
        print("显示历史人物预览: \(figure.name)")
    }
    
    /**
     * 获取历史人物头像图标
     */
    func getAvatarSymbol(for name: String) -> String {
        return cognitionModel.getAvatarSymbol(for: name)
    }
    
    /**
     * 获取角色头像名称
     * @param name 角色名称
     * @return 头像图片名称，如果不存在则返回nil
     */
    func getCharacterAvatar(for name: String) -> String? {
        // 查找对应的AppCharacter以获取avatarName
        if let character = allCharacters.first(where: { $0.name == name }) {
            let avatarName = character.avatarName
            
            // 检查是否为有效的图片名称
            if !avatarName.isEmpty && avatarName != "person.circle.fill" {
                return avatarName
            }
        }
        return nil
    }
    
    /**
     * 创建一个新角色示例
     * 这个方法展示了如何创建一个新角色
     * 
     * 添加新角色时注意事项：
     * 1. 为每个角色分配唯一的id，通常使用英文名或拼音
     * 2. 在characterRelations字典中定义角色关系
     * 3. 确保关联的角色也存在于角色库中
     * 4. 相关角色应当有明确的关联关系（同一作品、同一领域、历史关联等）
     * 5. 关联应该是双向的，如果A关联B，理想情况下B也应该关联A
     */
    private func createExampleCharacter() -> AppCharacter {
        return AppCharacter(
            id: "sherlock",               // 唯一标识符
            name: "夏洛克·福尔摩斯",       // 显示名称
            type: "literary",             // 角色类型
            subtype: "detective",         // 子类型
            era: "维多利亚时代",           // 时代
            primaryField: "侦探",         // 主要领域
            briefDescription: "世界上最著名的虚构侦探，由阿瑟·柯南·道尔创造", // 简介
            avatarName: "sherlock",       // 头像名称
            region: "英国伦敦",           // 地区
            contentAffinities: [          // 内容亲和度
                "推理": 0.95,
                "犯罪": 0.9,
                "观察": 0.85
            ]
        )
    }
    
    /**
     * 获取直接关联的角色（根据角色名称）
     */
    private func getDirectlyRelatedCharacters(for characterName: String) -> [AppCharacter] {
        // 查找角色对象
        guard let character = allCharacters.first(where: { $0.name == characterName }) else {
            return []
        }
        
        return getDirectlyRelatedCharacters(for: character)
    }

    /**
     * 获取当前作者直接关联的角色
     */
    private func getDirectlyRelatedCharactersForCurrentAuthor() -> [AppCharacter] {
        guard let author = postAuthor else {
            return []
        }
        
        return getDirectlyRelatedCharacters(for: author)
    }
    
    /**
     * 获取帖子内容
     * 从帖子ID或其他来源获取帖子内容
     */
    private func getPostContent() -> String? {
        // 尝试从PostViewModel获取帖子内容
        let viewModel = PostViewModel.shared
        if let post = viewModel.posts.first(where: { $0.id.uuidString == postId }) {
            return post.content
        }
        
        // 如果无法从PostViewModel获取，返回一些模拟内容
        return "这是一篇关于历史、科学和文化的讨论帖子，欢迎各位历史人物参与讨论。"
    }
    
    /**
     * 获取角色ID
     * @param name 角色名称
     * @return 角色ID（英文标识符）
     */
    private func getCharacterID(for name: String) -> String {
        // 首先检查名称是否为空
        guard !name.isEmpty else {
            return ""
        }
        
        // 常用角色ID映射
        let commonIdMappings: [String: String] = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "kongzi",
            "居里夫人": "curie",
            "李白": "libai",
            "牛顿": "newton",
            "孙悟空": "sunwukong",
            "夏洛克·福尔摩斯": "holmes",
            "福尔摩斯": "holmes",
            "漩涡鸣人": "naruto",
            "托尔斯泰": "tolstoy",
            "川端康成": "kawabata",
            "毕加索": "picasso",
            "霍金": "hawking",
            "拿破仑": "napoleon",
            "甘地": "gandhi"
        ]
        
        // 查找常用角色ID
        if let id = commonIdMappings[name] {
            return id
        }
        
        // 尝试从角色数据管理器中获取ID
        for character in allCharacters {
            if character.name == name {
                return character.id
            }
        }
        
        // 如果找不到匹配的ID，使用名称的拼音或英文作为ID
        let pinyin = name.lowercased()
            .replacingOccurrences(of: "·", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        
        return pinyin
    }
    
    /**
     * 根据角色名称获取角色ID
     * @param name 角色名称
     * @return 角色ID
     */
    func getCharacterIdByName(_ name: String) -> String? {
        print("🔍 HistoricalFigureSelectionViewModel.getCharacterIdByName - 名称: \(name)")
        
        // 中文名称到ID的映射
        let nameToId: [String: String] = [
            "爱因斯坦": "einstein",
            "莎士比亚": "shakespeare",
            "达芬奇": "davinci",
            "孔子": "kongzi",  // 确保使用kongzi而不是confucius
            "居里夫人": "curie",
            "李白": "libai",
            "牛顿": "newton",
            "福尔摩斯": "holmes",
            "孙悟空": "sunwukong"
        ]
        
        // 检查是否有直接映射
        if let id = nameToId[name] {
            print("✅ 找到名称映射: \(name) -> \(id)")
            return id
        }
        
        // 如果没有直接映射，尝试在角色列表中查找
        for character in allCharacters {
            if character.name == name {
                print("✅ 在角色列表中找到: \(name) -> \(character.id)")
                return character.id
            }
        }
        
        print("⚠️ 未找到名称映射: \(name)")
        return nil
    }
} 