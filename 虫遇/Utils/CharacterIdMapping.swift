// 角色ID映射
// 自动生成，用于解决数据库ID与模型ID不匹配问题

extension CharacterModel {
    /// 角色ID映射表 - 将数据库中的ID映射到正确的角色
    static let characterIdMapping: [String: String] = [
        "einstein": "einstein",  // 爱因斯坦
        "shakespeare": "shakespeare",  // 莎士比亚
        "holmes": "holmes",  // 夏洛克·福尔摩斯
        "ironman": "ironman",  // 托尼·史塔克
        "naruto": "naruto",  // 漩涡鸣人
        "sunwukong": "sunwukong",  // 孙悟空
        "kongzi": "kongzi",  // 孔子
        "tesla": "tesla",  // 尼古拉·特斯拉
        "anubis": "anubis",  // 阿努比斯
        "elsa": "elsa",  // 艾莎女王
        "daenerys": "daenerys",  // 丹妮莉丝·坦格利安
        "geralt": "geralt",  // 杰洛特
        "link": "link",  // 林克
        "spiderman": "spiderman",  // 蜘蛛侠
        "drhouse": "drhouse",  // 豪斯医生
        "hermione": "hermione",  // 赫敏·格兰杰
        "mulan": "mulan",  // 花木兰
        "blackwidow": "blackwidow",  // 黑寡妇
        "sherlock": "sherlock",  // 福尔摩斯
        "kirk": "kirk",  // 詹姆斯·柯克
        "terminator": "terminator",  // T-800终结者
        "walle": "walle",  // 瓦力
        "lara": "lara",  // 劳拉·克罗夫特
        "neo": "neo",  // 尼奥
        "frodo": "frodo",  // 弗罗多·巴金斯
        "obiwan": "obiwan",  // 欧比旺·肯诺比
        "legolas": "legolas",  // 莱戈拉斯
        "hatsune": "hatsune",  // 初音未来
        "wuzetian": "wuzetian",  // 武则天
        "yanggufei": "yanggufei",  // 杨贵妃
        "caocao": "caocao",  // 曹操
        "yuefei": "yuefei",  // 岳飞
        "lindaiyu": "lindaiyu",  // 林黛玉
        "tangsanzang": "tangsanzang",  // 唐三藏
        "niexiaoqian": "niexiaoqian",  // 聂小倩
        "yangguo": "yangguo",  // 杨过
        "nuwa": "nuwa",  // 女娲
        "erlang": "erlang",  // 二郎神
        "nezha": "nezha",  // 哪吒
        "lixiaoyao": "lixiaoyao",  // 李逍遥
        "baishe": "baishe",  // 白素贞
        "deadpool": "deadpool",  // 死侍
        "doraemon": "doraemon",  // 哆啦A梦
        "thanos": "thanos",  // 灭霸
        "sanji": "sanji",  // 山治
        "doctor": "doctor",  // 博士
        "songjiang": "songjiang",  // 宋江
        "xuebaochai": "xuebaochai",  // 薛宝钗
        "wusong": "wusong",  // 武松
        "minions": "minions",  // 小黄人
        "drstrange": "drstrange",  // 奇异博士
        "guangtouqiang": "guangtouqiang",  // 光头强
        "gollum": "gollum",  // 咕噜
        "plato": "plato",  // 柏拉图
        "laozi": "laozi",  // 老子
        "kant": "kant",  // 康德
        "zhuangzi": "zhuangzi",  // 庄子
        "tolstoy": "tolstoy",  // 托尔斯泰
        "marquez": "marquez",  // 马尔克斯
        "luxun": "luxun",  // 鲁迅
        "kawabata": "kawabata",  // 川端康成
        "sanmao": "sanmao",  // 三毛
        "freud": "freud",  // 弗洛伊德
        "jung": "jung",  // 荣格
        "adler": "adler",  // 阿德勒
        "davinci": "davinci",  // 达芬奇
        "monet": "monet",  // 莫奈
        "zhangdaqian": "zhangdaqian",  // 张大千
        "picasso": "picasso",  // 毕加索
        "qinshihuang": "qinshihuang",  // 秦始皇
        "hanwudi": "hanwudi",  // 汉武帝
        "kangxi": "kangxi",  // 康熙皇帝
        "jingke": "jingke",  // 荆轲
        "wangzhaojun": "wangzhaojun",  // 王昭君
        "xishi": "xishi",  // 西施
        "cleopatra": "cleopatra",  // 埃及艳后
        "diaochan": "diaochan",  // 貂蝉
        "caesar": "caesar",  // 凯撒大帝
        "ayuwang": "ayuwang",  // 阿育王
        "cixi": "cixi",  // 慈禧太后
        "genghis": "genghis",  // 成吉思汗
        "luffy": "luffy",  // 蒙奇·D·路飞
        "edogawa_conan": "edogawa_conan",  // 江户川柯南
        "saber": "saber",  // 阿尔托莉雅
        "genshin_traveler": "genshin_traveler",  // 旅行者
        "nezuko": "nezuko",  // 竈门禰豆子
        "levi": "levi",  // 利威尔
        "jinx": "jinx",  // 金克丝
        "kirby": "kirby",  // 星之卡比
        "pikachu": "pikachu",  // 皮卡丘
        "zhongli": "zhongli",  // 钟离
        "eren": "eren",  // 艾伦·耶格尔
        "tanjiro": "tanjiro",  // 竈门炭治郎
        "marie_curie": "marie_curie",  // 玛丽·居里
        "darwin": "darwin",  // 查尔斯·达尔文
        "beethoven": "beethoven",  // 贝多芬
        "van_gogh": "van_gogh",  // 梵高
        "socrates": "socrates",  // 苏格拉底
        "cleopatra": "cleopatra",  // 克里奥帕特拉
        "nightingale": "nightingale",  // 南丁格尔
        "alexander": "alexander",  // 亚历山大大帝
        "zhenghe": "zhenghe",  // 郑和
        "joan_of_arc": "joan_of_arc",  // 圣女贞德
        "don_quixote": "don_quixote",  // 堂·吉诃德
        "hamlet": "hamlet",  // 哈姆雷特
        "jean_valjean": "jean_valjean",  // 冉·阿让
        "anna_karenina": "anna_karenina",  // 安娜·卡列尼娜
        "gatsby": "gatsby",  // 杰伊·盖茨比
        "ahq": "ahq",  // 阿Q
        "scarlett": "scarlett",  // 郝思嘉
        "raskolnikov": "raskolnikov",  // 拉斯科尔尼科夫
        "jia_baoyu": "jia_baoyu",  // 贾宝玉
        "macbeth": "macbeth",  // 麦克白
        "joker": "joker",  // 小丑
        "forrest_gump": "forrest_gump",  // 阿甘
        "darth_vader": "darth_vader",  // 达斯·维达
        "jack_sparrow": "jack_sparrow",  // 杰克·斯派洛
        "harry_potter": "harry_potter",  // 哈利·波特
        "maximus": "maximus",  // 马克西姆斯
        "amelie": "amelie",  // 艾米丽
        "ip_man": "ip_man",  // 叶问
        "ethan_hunt": "ethan_hunt",  // 伊森·亨特
        "chihiro": "chihiro",  // 荻野千寻
        "goku": "goku",  // 孙悟空
        "sailor_moon": "sailor_moon",  // 美少女战士
        "light_yagami": "light_yagami",  // 夜神月
        "spike_spiegel": "spike_spiegel",  // 斯派克·史匹格
        "totoro": "totoro",  // 龙猫
        "lelouch": "lelouch",  // 鲁路修
        "inuyasha": "inuyasha",  // 犬夜叉
        "edward_elric": "edward_elric",  // 爱德华·艾尔利克
        "saitama": "saitama",  // 埼玉
        "hatsune_miku": "hatsune_miku",  // 初音未来
        "mario": "mario",  // 马里奥
        "master_chief": "master_chief",  // 士官长
        "kratos": "kratos",  // 奎托斯
        "solid_snake": "solid_snake",  // 固蛇
        "cloud_strife": "cloud_strife",  // 克劳德
        "ezio_auditore": "ezio_auditore",  // 艾吉奥
        "aloy": "aloy",  // 艾洛伊
        "2b": "2b",  // 2B
        "agent_47": "agent_47",  // 47号特工
        "ellie": "ellie",  // 艾莉
        "zeus": "zeus",  // 宙斯
        "thor": "thor",  // 托尔
        "athena": "athena",  // 雅典娜
        "osiris": "osiris",  // 奥西里斯
        "chang_e": "chang_e",  // 嫦娥
        "loki": "loki",  // 洛基
        "ganesha": "ganesha",  // 象头神
        "hou_yi": "hou_yi",  // 后羿
        "quetzalcoatl": "quetzalcoatl",  // 羽蛇神
        "walter_white": "walter_white",  // 沃尔特·怀特
        "tyrion_lannister": "tyrion_lannister",  // 提利昂·兰尼斯特
        "eleven": "eleven",  // 十一
        "sheldon_cooper": "sheldon_cooper",  // 谢尔顿·库珀
        "sherlock_bbc": "sherlock_bbc",  // 夏洛克·福尔摩斯
        "michael_scott": "michael_scott",  // 迈克尔·斯科特
        "raymond_reddington": "raymond_reddington",  // 雷蒙德·雷丁顿
        "thomas_shelby": "thomas_shelby",  // 托马斯·谢尔比
        "zhen_huan": "zhen_huan",  // 甄嬛
        "saul_goodman": "saul_goodman",  // 索尔·古德曼
        "aristotle": "aristotle",  // 亚里士多德
        "curie": "curie",  // 居里夫人
        "hawking": "hawking",  // 霍金
        "libai": "libai",  // 李白
        "mozart": "mozart",  // 莫扎特
        "newton": "newton",  // 牛顿
        "spike": "spike",  // 斯派克
    ]
    
    /// 根据ID查找角色（支持映射）
    static func findCharacter(byId id: String) -> CharacterModel? {
        let allChars = getAllCharacters()
        
        // 直接匹配
        if let char = allChars.first(where: { $0.id == id }) {
            return char
        }
        
        // 通过映射查找
        if let mappedId = characterIdMapping[id],
           let char = allChars.first(where: { $0.id == mappedId }) {
            return char
        }
        
        // 通过名称匹配
        if let char = allChars.first(where: { $0.name.contains(id) || id.contains($0.name) }) {
            return char
        }
        
        return nil
    }
}
