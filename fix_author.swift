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
    // 如果已经通过参数设置了作者，则不需要再次设置
    if postAuthor != nil {
        print("已设置帖子作者: \(postAuthor?.name ?? "未知"), 跳过自动设置")
        return
    }
    
    // 模拟帖子数据 - 在实际应用中应从数据库获取
    let postContents = [
        "蹲在庭院搅拌茶碗时，忽然发现裂纹里嵌着蝶翅鳞粉。十七岁时在伊豆山径迷路，那个舞女用三昧线琴弦为我系上和服带；三年前诺奖演说前夜，看到斯德哥尔摩港口浮冰折射出雪国火花的颜色。答案总在寻找之外闪现，像蝴蝶停在伤口结痂处，振翅时痂壳就成了时空褶皱里的虫洞。",
        "莎士比亚的戏剧作品中对人性的洞察让人叹为观止，特别是《哈姆雷特》中的经典独白。",
        "孔子的教育思想对现代教育仍有重要启示，'因材施教'的理念尤为重要。",
        "达芬奇不仅是艺术家，还是科学家和发明家，他的全能才华令人敬佩。",
        "牛顿的万有引力定律彻底改变了人类对宇宙的理解，为现代物理学奠定了基础。",
        "【1953年冬，普林斯顿】壁炉里的橡木噼啪作响，烟斗的苦味在舌尖停留了整整三小时。今天在《原子科学家公报》签下名字时，钢笔突然变得比中子还沉重——我们打开潘多拉盒子的速度，超过了人类建设道德防火墙的速度。窗外的白杨树在风中画出光的轨迹，像极了四十年前我在布拉格天文台看到的银河。此刻的时空褶皱里，少年时对统一场论的纯粹渴望，与此刻对文明存续的焦虑，正在发生量子纠缠。",
        "康熙六十一年，朕于紫禁城御花园中赏梅，忽见一梅枝傲雪独放，不禁想起少年时与南怀仁讨论天文历法，与徐光启探讨《几何原本》之情景。治国六十载，深感'天下一家'之理，文武之道，一张一弛。"
    ]
    
    // 模拟帖子作者
    let postAuthors = [
        AppCharacter(id: "kawabata", name: "川端康成", type: "historical", subtype: "writer", era: "现代", primaryField: "文学家", briefDescription: "日本文学家，诺贝尔文学奖得主，作品《雪国》《千只鹤》等", avatarName: "kawabata", region: "日本", contentAffinities: ["文学": 0.9, "自然": 0.8, "哲思": 0.7]),
        AppCharacter(id: "shakespeare", name: "莎士比亚", type: "historical", subtype: "writer", era: "文艺复兴", primaryField: "戏剧家、诗人", briefDescription: "英国最伟大的戏剧家，作品包括《罗密欧与朱丽叶》《哈姆雷特》等", avatarName: "shakespeare", region: "英国", contentAffinities: ["文学": 0.9, "戏剧": 0.95]),
        AppCharacter(id: "kongzi", name: "孔子", type: "historical", subtype: "philosopher", era: "春秋时期", primaryField: "哲学家、教育家", briefDescription: "儒家学派创始人，中国古代思想家、政治家和教育家", avatarName: "kongzi", region: "中国", contentAffinities: ["哲学": 0.95, "教育": 0.9]),
        AppCharacter(id: "davinci", name: "达芬奇", type: "historical", subtype: "artist", era: "文艺复兴", primaryField: "艺术家、科学家", briefDescription: "意大利文艺复兴时期的艺术家、科学家和发明家", avatarName: "davinci", region: "意大利", contentAffinities: ["艺术": 0.9, "科学": 0.85]),
        AppCharacter(id: "newton", name: "牛顿", type: "historical", subtype: "scientist", era: "近代", primaryField: "物理学家、数学家", briefDescription: "英国物理学家、数学家，发现万有引力定律", avatarName: "newton", region: "英国", contentAffinities: ["物理": 0.95, "数学": 0.9]),
        AppCharacter(id: "einstein", name: "爱因斯坦", type: "historical", subtype: "scientist", era: "近代", primaryField: "物理学家", briefDescription: "相对论创立者，20世纪最伟大的科学家之一", avatarName: "einstein", region: "德国/美国", contentAffinities: ["物理": 0.95, "科学": 0.9]),
        AppCharacter(id: "kangxi", name: "康熙皇帝", type: "historical", subtype: "emperor", era: "清朝", primaryField: "皇帝", briefDescription: "中国清朝第四位皇帝，在位61年，推动科学文化发展", avatarName: "kangxi", region: "中国", contentAffinities: ["政治": 0.95, "文化": 0.9, "科学": 0.85]),
        AppCharacter(id: "sherlock", name: "夏洛克·福尔摩斯", type: "literary", subtype: "detective", era: "维多利亚时代", primaryField: "侦探", briefDescription: "世界上最著名的虚构侦探，由阿瑟·柯南·道尔创造", avatarName: "sherlock", region: "英国伦敦", contentAffinities: ["推理": 0.95, "犯罪": 0.9, "观察": 0.85])
    ]
    
    // 检查postId是否包含特定角色名称，如果包含则直接使用该角色作为作者
    if postId.contains("孔子") {
        postAuthor = postAuthors[2] // 孔子在数组中的索引是2
        postContent = postContents[2]
    } else if postId.contains("康熙") {
        postAuthor = postAuthors[6] // 康熙皇帝在数组中的索引是6
        postContent = postContents[6]
    } else if postId.contains("夏洛克") || postId.contains("福尔摩斯") {
        postAuthor = postAuthors[7] // 夏洛克·福尔摩斯在数组的索引是7
        postContent = "【1895年，伦敦东区】煤油灯在潮湿的砖墙上投下摇晃的阴影，我蹲在排水沟旁，指尖捻起一撮混着铁锈味的泥土。三十七分钟前，那个裁缝的银顶针在泥泞中反光——现在它正躺在我的掌心，内侧刻着三年前巴黎世博会的标志。雨滴砸在皮革手套上的闷响掩盖了真相：死者根本不是被抢劫的流浪汉。我在他指甲缝里发现的靛蓝染料，和码头区那艘荷兰货轮登记的颜色完全一致。华生总说我该带伞，但他不懂，雨水冲走了最好的线索。"
    } else {
        // 根据postId选择一个示例内容和作者
        var index = abs(postId.hashValue) % postContents.count
        
        // 检查当前显示的内容是否包含爱因斯坦相关关键词
        let content = postContents[index]
        if content.contains("爱因斯坦") || content.contains("相对论") || content.contains("普林斯顿") || content.contains("统一场论") {
            // 如果内容与爱因斯坦相关，则确保作者也是爱因斯坦
            index = 5 // 爱因斯坦在数组的索引是5
        } else if content.contains("康熙") || content.contains("紫禁城") || content.contains("南怀仁") || content.contains("徐光启") {
            // 如果内容与康熙相关，则确保作者是康熙
            index = 6 // 康熙在数组的索引是6
        }
        
        postContent = postContents[index]
        postAuthor = postAuthors[index]
    }
    
    // 调试日志
    print("加载帖子数据 - 作者: \(postAuthor?.name ?? "未知"), 是否在关系字典中: \(postAuthor != nil && characterRelations[postAuthor!.name] != nil)")
    if let author = postAuthor, let relations = characterRelations[author.name] {
        print("作者 \(author.name) 的相关角色: \(relations.joined(separator: ", "))")
    }
}
