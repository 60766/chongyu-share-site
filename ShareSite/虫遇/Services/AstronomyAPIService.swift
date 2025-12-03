import Foundation
import SwiftUI

// MARK: - 天文数据模型
struct RealStar: Identifiable, Codable {
    let id: Int
    let name: String?
    let properName: String?
    let rightAscension: Double // 赤经
    let declination: Double    // 赤纬
    let distance: Double       // 距离（光年）
    let magnitude: Double      // 视星等
    let spectralType: String?  // 光谱类型
    let constellation: String? // 星座
    let x: Double             // 3D坐标
    let y: Double
    let z: Double
    
    var color: Color {
        // 根据光谱类型返回更真实的恒星颜色
        // 基于实际观测数据和黑体辐射理论
        guard let spectral = spectralType?.prefix(1) else { return Color.white }
        
        switch spectral {
        case "O": 
            // O型星：30,000-50,000K，极热蓝色
            return Color(red: 0.6, green: 0.7, blue: 1.0)  // 深蓝色
        case "B": 
            // B型星：10,000-30,000K，蓝白色
            return Color(red: 0.7, green: 0.8, blue: 1.0)  // 蓝白色
        case "A": 
            // A型星：7,500-10,000K，白色
            return Color.white                               // 纯白色
        case "F": 
            // F型星：6,000-7,500K，黄白色
            return Color(red: 1.0, green: 1.0, blue: 0.9)  // 微黄白色
        case "G": 
            // G型星：5,300-6,000K，黄色（太阳型）
            return Color(red: 1.0, green: 1.0, blue: 0.8)  // 淡黄色
        case "K": 
            // K型星：3,900-5,300K，橙色
            return Color(red: 1.0, green: 0.8, blue: 0.6)  // 橙色
        case "M": 
            // M型星：2,300-3,900K，红色
            return Color(red: 1.0, green: 0.6, blue: 0.4)  // 橙红色
        default: 
            return Color.white
        }
    }
    
    var brightness: Double {
        // 根据视星等计算亮度（星等越小越亮）
        return max(0.1, 1.0 - (magnitude - (-2.0)) / 15.0)
    }
}

struct Constellation: Identifiable, Codable {
    let id: String
    let name: String
    let chineseName: String
    let stars: [RealStar]
    let lines: [[Int]]  // 连线索引
}

struct AstronomyPictureOfDay: Codable {
    let date: String
    let explanation: String
    let title: String
    let url: String
    let mediaType: String
    
    enum CodingKeys: String, CodingKey {
        case date, explanation, title, url
        case mediaType = "media_type"
    }
}

// MARK: - 天文API服务
class AstronomyAPIService: ObservableObject {
    static let shared = AstronomyAPIService()
    
    private var baseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "NASA_API_BASE_URL") as? String {
            return url
        }
        return "https://api.nasa.gov"
    }
    
    private var apiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return "DEMO_KEY" // 建议申请真实API密钥
    }
    
    @Published var realStars: [RealStar] = []
    @Published var constellations: [Constellation] = []
    @Published var astronomyPicture: AstronomyPictureOfDay?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 虫洞数据
    @Published var wormholes: [Wormhole] = []
    @Published var wormholeLinks: [WormholeLink] = []
    
    private init() {
        loadLocalStarData()
        loadWormholeData()
    }
    
    // MARK: - 获取每日天文图片
    func fetchAstronomyPictureOfDay() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let url = URL(string: "\(baseURL)/planetary/apod?api_key=\(apiKey)") else {
            await MainActor.run {
                errorMessage = "无效的API URL"
                isLoading = false
            }
            return
        }
        
        do {
            // Use longer timeouts for external API calls
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 300
            config.timeoutIntervalForResource = 300
            let session = URLSession(configuration: config)
            let (data, _) = try await session.data(from: url)
            let picture = try JSONDecoder().decode(AstronomyPictureOfDay.self, from: data)
            
            await MainActor.run {
                self.astronomyPicture = picture
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "获取天文图片失败: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - 加载本地星表数据
    private func loadLocalStarData() {
        // 使用内置的HYG星表子集数据
        realStars = generateMockStars()
        constellations = generateConstellations()
    }
    
    // MARK: - 生成模拟真实星表数据
    private func generateMockStars() -> [RealStar] {
        let starData: [(String, String?, Double, Double, Double, Double, String, String)] = [
            // === 0等星和-1等星（最亮的恒星）===
            ("HIP 32349", "Sirius", 101.29, -16.72, 8.6, -1.46, "A1V", "CMa"), // 天狼星
            ("HIP 30438", "Canopus", 95.99, -52.70, 310, -0.74, "A9II", "Car"), // 老人星
            ("HIP 69673", "Arcturus", 213.92, 19.18, 36.7, -0.05, "K1III", "Boo"), // 大角星
            ("HIP 91262", "Vega", 279.23, 38.78, 25.0, 0.03, "A0V", "Lyr"),    // 织女星
            ("HIP 24436", "Capella", 79.17, 45.99, 42.9, 0.08, "G5III", "Aur"), // 五车二
            
            // === 1等星 ===
            ("HIP 21421", "Rigel", 78.63, -8.20, 860, 0.13, "B8Ia", "Ori"),    // 参宿七
            ("HIP 37279", "Procyon", 114.83, 5.22, 11.5, 0.34, "F5IV", "CMi"), // 南河三
            ("HIP 25336", "Betelgeuse", 88.79, 7.41, 640, 0.50, "M1Ia", "Ori"), // 参宿四
            ("HIP 24608", "Achernar", 24.43, -57.24, 139, 0.46, "B3Ve", "Eri"), // 水委一
            ("HIP 80763", "Antares", 247.35, -26.43, 600, 0.6, "M1Ib", "Sco"), // 心宿二
            ("HIP 97649", "Altair", 297.70, 8.87, 16.7, 0.77, "A7V", "Aql"),   // 牛郎星
            ("HIP 60718", "Acrux", 186.65, -63.10, 320, 0.77, "B0IV", "Cru"),   // 十字架一
            ("HIP 27989", "Aldebaran", 68.98, 16.51, 65.3, 0.85, "K5III", "Tau"), // 毕宿五
            ("HIP 11767", "Polaris", 37.95, 89.26, 433, 1.98, "F7Ib", "UMi"),  // 北极星
            ("HIP 113881", "Fomalhaut", 344.41, -29.62, 25.1, 1.16, "A3V", "PsA"), // 北落师门
            
            // === 北斗七星 ===
            ("HIP 54061", "Dubhe", 165.93, 61.75, 124, 1.79, "K3III", "UMa"),    // 天枢
            ("HIP 53910", "Merak", 165.46, 56.38, 79.7, 2.37, "A1V", "UMa"),     // 天璇
            ("HIP 58001", "Phecda", 178.46, 53.69, 83.2, 2.44, "A0V", "UMa"),    // 天玑
            ("HIP 59774", "Megrez", 183.86, 57.03, 58.4, 3.31, "A3V", "UMa"),    // 天权
            ("HIP 62956", "Alioth", 193.51, 55.96, 81.2, 1.77, "A1III", "UMa"),  // 玉衡
            ("HIP 65378", "Mizar", 200.98, 54.93, 82.9, 2.27, "A2V", "UMa"),     // 开阳
            ("HIP 67301", "Alkaid", 206.89, 49.31, 103.9, 1.86, "B3V", "UMa"),   // 摇光
            
            // === 猎户座主要恒星 ===
            ("HIP 25930", "Alnitak", 85.19, -1.94, 1260, 1.70, "O9Ib", "Ori"),  // 参宿一
            ("HIP 26311", "Alnilam", 84.05, -1.20, 2000, 1.69, "B0Ia", "Ori"),  // 参宿二
            ("HIP 26727", "Mintaka", 83.00, -0.30, 915, 2.23, "O9II", "Ori"),   // 参宿三
            ("HIP 25281", "Bellatrix", 81.28, 6.35, 245, 1.64, "B2III", "Ori"), // 参宿五
            ("HIP 22449", "Saiph", 86.94, -9.67, 650, 2.09, "B0Ia", "Ori"),     // 参宿六
            
            // === 南十字座 ===
            ("HIP 62434", "Gacrux", 191.93, -57.11, 88.6, 1.63, "M3III", "Cru"), // 十字架三
            ("HIP 61084", "Mimosa", 191.93, -59.69, 280, 1.25, "B0III", "Cru"),  // 十字架二
            ("HIP 59747", "Imai", 181.31, -64.98, 370, 2.80, "B2IV", "Cru"),     // 十字架四
            
            // === 天蝎座 ===
            ("HIP 78401", "Shaula", 263.40, -37.10, 700, 1.63, "B1IV", "Sco"),   // 尾宿八
            ("HIP 78820", "Sargas", 264.33, -43.00, 272, 1.87, "F1II", "Sco"),   // 尾宿九
            ("HIP 81266", "Kappa Sco", 268.38, -39.03, 464, 2.41, "B2IV", "Sco"), // 尾宿四
            
            // === 射手座 ===
            ("HIP 85927", "Nunki", 283.82, -26.30, 228, 2.05, "B2IV", "Sgr"),    // 箕宿二
            ("HIP 90185", "Kaus Australis", 288.44, -34.38, 145, 1.85, "B9III", "Sgr"), // 箕宿三
            ("HIP 89931", "Ascella", 287.44, -29.88, 88, 2.60, "A2III", "Sgr"),  // 箕宿一
            
            // === 仙女座 ===
            ("HIP 677", "Alpheratz", 2.07, 29.09, 97, 2.06, "B8IV", "And"),      // 壁宿二
            ("HIP 9640", "Mirach", 35.62, 35.62, 199, 2.06, "M0III", "And"),     // 奎宿九
            ("HIP 5447", "Almach", 30.97, 42.33, 355, 2.26, "K3II", "And"),      // 天大将军一
            
            // === 英仙座 ===
            ("HIP 15863", "Mirfak", 51.08, 49.86, 510, 1.80, "F5Ib", "Per"),     // 天船三
            ("HIP 14576", "Algol", 47.04, 40.96, 90, 2.12, "B8V", "Per"),        // 大陵五
            
            // === 御夫座 ===
            ("HIP 23015", "Menkalinan", 89.93, 44.95, 81, 1.90, "A1IV", "Aur"),  // 五车三
            ("HIP 28360", "Mahasim", 93.72, 37.21, 173, 2.99, "A0IV", "Aur"),    // 五车七
            
            // === 金牛座 ===
            ("HIP 25428", "Elnath", 81.57, 28.61, 131, 1.68, "B7III", "Tau"),    // 五车五
            ("HIP 20889", "Zeta Tau", 84.41, 21.14, 417, 3.00, "B1IVe", "Tau"),  // 天关
            
            // === 双子座 ===
            ("HIP 37826", "Pollux", 116.33, 28.03, 33.8, 1.14, "K0III", "Gem"),  // 北河三
            ("HIP 36850", "Castor", 113.65, 31.89, 51.6, 1.57, "A1V", "Gem"),    // 北河二
            ("HIP 35550", "Alhena", 99.43, 16.40, 109, 1.93, "A0IV", "Gem"),     // 井宿三
            
            // === 巨蟹座 ===
            ("HIP 42911", "Acubens", 134.62, 11.86, 174, 4.25, "A5III", "Cnc"),  // 柳宿增一
            ("HIP 44066", "Al Tarf", 125.13, 9.19, 290, 3.53, "K4III", "Cnc"),   // 鬼宿四
            
            // === 狮子座 ===
            ("HIP 49669", "Regulus", 152.09, 11.97, 79.3, 1.35, "B7V", "Leo"),   // 轩辕十四
            ("HIP 57632", "Denebola", 177.26, 14.57, 35.9, 2.13, "A3V", "Leo"),  // 五帝座一
            ("HIP 50583", "Algieba", 154.99, 19.84, 126, 2.28, "K1III", "Leo"),  // 轩辕十二
            
            // === 室女座 ===
            ("HIP 65474", "Spica", 201.30, -11.16, 262, 0.97, "B1III", "Vir"),   // 角宿一
            ("HIP 69427", "Porrima", 190.42, -1.45, 38.1, 2.74, "F0V", "Vir"),   // 太微右垣二
            
            // === 天秤座 ===
            ("HIP 74785", "Zubeneschamali", 229.25, -9.38, 185, 2.61, "B8V", "Lib"), // 氐宿四
            ("HIP 72622", "Zubenelgenubi", 222.72, -16.04, 77, 2.75, "A3IV", "Lib"), // 氐宿一
            
            // === 牧夫座 ===
            ("HIP 71683", "Izar", 221.25, 27.07, 203, 2.37, "K0II", "Boo"),      // 梗河一
            ("HIP 67927", "Muphrid", 211.59, 18.40, 37, 2.68, "G0IV", "Boo"),    // 右摄提一
            
            // === 巨蛇座 ===
            ("HIP 77233", "Unukalhai", 236.07, 6.42, 74, 2.63, "K2III", "Ser"),  // 蛇首
            
            // === 武仙座 ===
            ("HIP 84345", "Kornephoros", 253.46, 21.49, 139, 2.78, "G7III", "Her"), // 帝座
            ("HIP 85693", "Zeta Her", 259.29, 31.60, 35, 2.81, "F9IV", "Her"),    // 何
            
            // === 天琴座 ===
            ("HIP 92420", "Sheliak", 284.74, 33.36, 960, 3.45, "B8II", "Lyr"),   // 渐台二
            ("HIP 91971", "Sulafat", 284.74, 32.69, 635, 3.24, "B9III", "Lyr"),  // 渐台三
            
            // === 天鹅座 ===
            ("HIP 100453", "Deneb", 310.36, 45.28, 2600, 1.25, "A2Ia", "Cyg"),   // 天津四
            ("HIP 104732", "Sadr", 305.56, 40.26, 1800, 2.20, "F8Ib", "Cyg"),    // 天津一
            ("HIP 102098", "Gienah", 293.18, 33.97, 72, 2.46, "K3III", "Cyg"),   // 右旗一
            
            // === 天鹰座 ===
            ("HIP 95947", "Tarazed", 296.57, 10.61, 395, 2.72, "K3II", "Aql"),   // 河鼓二
            ("HIP 98036", "Alschain", 302.28, 8.87, 44.7, 3.71, "A7IV", "Aql"),  // 河鼓一
            
            // === 海豚座 ===
            ("HIP 101958", "Sualocin", 309.39, 15.91, 241, 3.77, "B9IV", "Del"), // 瓠瓜四
            ("HIP 102281", "Rotanev", 309.39, 14.60, 97, 3.63, "F5IV", "Del"),   // 瓠瓜三
            
            // === 飞马座 ===
            ("HIP 113963", "Markab", 346.19, 15.21, 140, 2.49, "B9V", "Peg"),    // 室宿一
            ("HIP 112748", "Scheat", 345.94, 28.08, 196, 2.42, "M2III", "Peg"),  // 室宿二
            ("HIP 1067", "Algenib", 15.18, 15.18, 390, 2.83, "B2IV", "Peg"),     // 壁宿一
            
            // === 仙王座 ===
            ("HIP 109492", "Alderamin", 319.64, 62.59, 49, 2.44, "A7IV", "Cep"), // 天钩五
            ("HIP 105199", "Alfirk", 315.61, 70.56, 595, 3.23, "B1IV", "Cep"),   // 造父四
            
            // === 蝎虎座 ===
            ("HIP 111169", "Alpha Lac", 335.41, 50.28, 102, 3.77, "A1V", "Lac"), // 蝎虎座α
            
            // === 仙女座 ===
            ("HIP 116727", "Delta And", 8.20, 30.86, 105, 3.27, "K3III", "And"),  // 天大将军二
            
            // === 南鱼座 ===
            ("HIP 113368", "Fomalhaut", 344.41, -29.62, 25.1, 1.16, "A3V", "PsA"), // 北落师门
            
            // === 鲸鱼座 ===
            ("HIP 9884", "Menkar", 45.57, 4.09, 249, 2.53, "M1III", "Cet"),      // 天囷一
            ("HIP 18884", "Mira", 34.84, -2.98, 420, 3.04, "M7IIIe", "Cet"),     // 蒭藁增二
            
            // === 波江座 ===
            ("HIP 23875", "Cursa", 62.97, -5.09, 88.9, 2.78, "A3III", "Eri"),    // 玉井四
            
            // === 船底座 ===
            ("HIP 45238", "Miaplacidus", 138.30, -69.72, 111, 1.68, "A1III", "Car"), // 船底二
            ("HIP 52419", "Avior", 125.63, -59.51, 630, 1.86, "K3III", "Car"),   // 船底三
            
            // === 船帆座 ===
            ("HIP 39953", "Regor", 123.18, -47.34, 840, 1.75, "WC8", "Vel"),     // 船帆二
            ("HIP 50099", "Alsuhail", 136.04, -46.04, 570, 2.21, "K5Ib", "Vel"), // 船帆九
            
            // === 南十字座周边 ===
            ("HIP 68702", "Rigil Kent", 219.90, -60.84, 4.37, -0.01, "G2V", "Cen"), // 南门二
            ("HIP 71681", "Hadar", 210.96, -60.37, 390, 0.60, "B1III", "Cen"),   // 马腹一
            
            // === 半人马座 ===
            ("HIP 68933", "Menkent", 211.67, -36.37, 58.8, 2.06, "K0III", "Cen"), // 马腹二
            
            // === 天坛座 ===
            ("HIP 85792", "Alpha Ara", 262.96, -49.88, 242, 2.84, "B2Vne", "Ara"), // 天坛座α
            
            // === 孔雀座 ===
            ("HIP 100751", "Peacock", 306.41, -56.74, 183, 1.94, "B2IV", "Pav"), // 孔雀十一
            
            // === 南三角座 ===
            ("HIP 82273", "Atria", 252.17, -69.03, 415, 1.91, "K2IIIa", "TrA"),  // 南三角座α
            
            // === 天鹤座 ===
            ("HIP 112122", "Alnair", 332.06, -46.96, 101, 1.74, "B7IV", "Gru"),  // 鹤一
            
            // === 杜鹃座 ===
            ("HIP 1599", "Alpha Tuc", 22.31, -60.26, 200, 2.86, "K3III", "Tuc"),  // 杜鹃座α
            
            // === 凤凰座 ===
            ("HIP 2081", "Ankaa", 6.57, -42.31, 77, 2.40, "K0III", "Phe"),       // 火鸟六
        ]
        
        return starData.enumerated().map { index, data in
            let (hipID, properName, ra, dec, distance, magnitude, spectral, constellation) = data
            
            // 将赤经赤纬转换为3D坐标
            let raRad = ra * .pi / 180.0
            let decRad = dec * .pi / 180.0
            let distanceScale = distance / 100.0 // 缩放距离用于显示
            
            let x = distanceScale * cos(decRad) * cos(raRad)
            let y = distanceScale * cos(decRad) * sin(raRad)
            let z = distanceScale * sin(decRad)
            
            return RealStar(
                id: index,
                name: hipID,
                properName: properName,
                rightAscension: ra,
                declination: dec,
                distance: distance,
                magnitude: magnitude,
                spectralType: spectral,
                constellation: constellation,
                x: x,
                y: y,
                z: z
            )
        }
    }
    
    // MARK: - 生成星座数据
    private func generateConstellations() -> [Constellation] {
        // 大熊座（北斗七星）
        let ursaMajor = Constellation(
            id: "UMa",
            name: "Ursa Major",
            chineseName: "大熊座",
            stars: realStars.filter { $0.constellation == "UMa" },
            lines: [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6]] // 北斗七星连线
        )
        
        // 猎户座
        let orion = Constellation(
            id: "Ori",
            name: "Orion",
            chineseName: "猎户座",
            stars: realStars.filter { $0.constellation == "Ori" },
            lines: [
                // 腰带三星
                [0, 1], [1, 2], 
                // 肩膀到腰带
                [3, 0], [4, 2],
                // 四边形连线
                [3, 4]
            ]
        )
        
        // 南十字座
        let crux = Constellation(
            id: "Cru",
            name: "Crux",
            chineseName: "南十字座",
            stars: realStars.filter { $0.constellation == "Cru" },
            lines: [
                [0, 2], [1, 3] // 十字形连线
            ]
        )
        
        // 天蝎座
        let scorpius = Constellation(
            id: "Sco",
            name: "Scorpius",
            chineseName: "天蝎座",
            stars: realStars.filter { $0.constellation == "Sco" },
            lines: [
                [0, 1], [1, 2] // 心宿二到尾宿
            ]
        )
        
        // 射手座
        let sagittarius = Constellation(
            id: "Sgr",
            name: "Sagittarius",
            chineseName: "射手座",
            stars: realStars.filter { $0.constellation == "Sgr" },
            lines: [
                [0, 1], [1, 2] // 茶壶形状的部分连线
            ]
        )
        
        // 天鹅座
        let cygnus = Constellation(
            id: "Cyg",
            name: "Cygnus",
            chineseName: "天鹅座",
            stars: realStars.filter { $0.constellation == "Cyg" },
            lines: [
                [0, 1], [1, 2] // 十字形连线
            ]
        )
        
        // 天琴座
        let lyra = Constellation(
            id: "Lyr",
            name: "Lyra",
            chineseName: "天琴座",
            stars: realStars.filter { $0.constellation == "Lyr" },
            lines: [
                [0, 1], [0, 2] // 小平行四边形
            ]
        )
        
        // 天鹰座
        let aquila = Constellation(
            id: "Aql", 
            name: "Aquila",
            chineseName: "天鹰座",
            stars: realStars.filter { $0.constellation == "Aql" },
            lines: [
                [0, 1], [0, 2] // 牛郎星和两旁的星
            ]
        )
        
        // 双子座
        let gemini = Constellation(
            id: "Gem",
            name: "Gemini", 
            chineseName: "双子座",
            stars: realStars.filter { $0.constellation == "Gem" },
            lines: [
                [0, 1], [1, 2] // 北河二、北河三连线
            ]
        )
        
        // 狮子座
        let leo = Constellation(
            id: "Leo",
            name: "Leo",
            chineseName: "狮子座",
            stars: realStars.filter { $0.constellation == "Leo" },
            lines: [
                [0, 1], [0, 2] // 轩辕十四为中心的连线
            ]
        )
        
        // 半人马座
        let centaurus = Constellation(
            id: "Cen",
            name: "Centaurus",
            chineseName: "半人马座",
            stars: realStars.filter { $0.constellation == "Cen" },
            lines: [
                [0, 1], [1, 2] // 南门二系统连线
            ]
        )
        
        // 金牛座
        let taurus = Constellation(
            id: "Tau",
            name: "Taurus",
            chineseName: "金牛座",
            stars: realStars.filter { $0.constellation == "Tau" },
            lines: [
                [0, 1] // 毕宿五连线
            ]
        )
        
        // 御夫座
        let auriga = Constellation(
            id: "Aur",
            name: "Auriga",
            chineseName: "御夫座",
            stars: realStars.filter { $0.constellation == "Aur" },
            lines: [
                [0, 1], [1, 2] // 五车二为中心
            ]
        )
        
        // 仙女座
        let andromeda = Constellation(
            id: "And",
            name: "Andromeda",
            chineseName: "仙女座",
            stars: realStars.filter { $0.constellation == "And" },
            lines: [
                [0, 1], [1, 2] // 仙女座链
            ]
        )
        
        // 英仙座
        let perseus = Constellation(
            id: "Per",
            name: "Perseus",
            chineseName: "英仙座",
            stars: realStars.filter { $0.constellation == "Per" },
            lines: [
                [0, 1] // 天船三连线
            ]
        )
        
        // 巨蟹座
        let cancer = Constellation(
            id: "Cnc",
            name: "Cancer",
            chineseName: "巨蟹座",
            stars: realStars.filter { $0.constellation == "Cnc" },
            lines: [
                [0, 1] // 巨蟹座主要连线
            ]
        )
        
        // 室女座
        let virgo = Constellation(
            id: "Vir",
            name: "Virgo",
            chineseName: "室女座",
            stars: realStars.filter { $0.constellation == "Vir" },
            lines: [
                [0, 1] // 角宿一连线
            ]
        )
        
        // 天秤座
        let libra = Constellation(
            id: "Lib",
            name: "Libra",
            chineseName: "天秤座",
            stars: realStars.filter { $0.constellation == "Lib" },
            lines: [
                [0, 1] // 天秤连线
            ]
        )
        
        // 牧夫座
        let bootes = Constellation(
            id: "Boo",
            name: "Boötes",
            chineseName: "牧夫座",
            stars: realStars.filter { $0.constellation == "Boo" },
            lines: [
                [0, 1], [0, 2] // 大角星为中心
            ]
        )
        
        // 武仙座
        let hercules = Constellation(
            id: "Her",
            name: "Hercules",
            chineseName: "武仙座",
            stars: realStars.filter { $0.constellation == "Her" },
            lines: [
                [0, 1] // 武仙座连线
            ]
        )
        
        // 飞马座
        let pegasus = Constellation(
            id: "Peg",
            name: "Pegasus",
            chineseName: "飞马座",
            stars: realStars.filter { $0.constellation == "Peg" },
            lines: [
                [0, 1], [1, 2] // 飞马座四边形
            ]
        )
        
        // 仙王座
        let cepheus = Constellation(
            id: "Cep",
            name: "Cepheus",
            chineseName: "仙王座",
            stars: realStars.filter { $0.constellation == "Cep" },
            lines: [
                [0, 1] // 仙王座连线
            ]
        )
        
        // 大犬座
        let canisMajor = Constellation(
            id: "CMa",
            name: "Canis Major",
            chineseName: "大犬座",
            stars: realStars.filter { $0.constellation == "CMa" },
            lines: [
                [] // 天狼星独立显示
            ]
        )
        
        // 小犬座
        let canisMinor = Constellation(
            id: "CMi",
            name: "Canis Minor",
            chineseName: "小犬座",
            stars: realStars.filter { $0.constellation == "CMi" },
            lines: [
                [] // 南河三独立显示
            ]
        )
        
        // 船底座
        let carina = Constellation(
            id: "Car",
            name: "Carina",
            chineseName: "船底座",
            stars: realStars.filter { $0.constellation == "Car" },
            lines: [
                [0, 1] // 老人星连线
            ]
        )
        
        return [ursaMajor, orion, crux, scorpius, sagittarius, cygnus, lyra, aquila, gemini, leo, centaurus, taurus, auriga, andromeda, perseus, cancer, virgo, libra, bootes, hercules, pegasus, cepheus, canisMajor, canisMinor, carina]
    }
    
    // MARK: - 根据位置和时间计算可见星空
    func getVisibleStars(latitude: Double, longitude: Double, date: Date) -> [RealStar] {
        // 这里可以实现更复杂的天体力学计算
        // 暂时返回所有恒星，后续可以根据观测位置和时间过滤
        return realStars.filter { star in
            // 简单的地平线过滤（实际应该考虑地球自转、进动等）
            let hourAngle = calculateHourAngle(ra: star.rightAscension, longitude: longitude, date: date)
            let altitude = calculateAltitude(dec: star.declination, lat: latitude, ha: hourAngle)
            return altitude > 0 // 只返回地平线以上的恒星
        }
    }
    
    private func calculateHourAngle(ra: Double, longitude: Double, date: Date) -> Double {
        // 简化的时角计算
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        let hour = Double(formatter.string(from: date)) ?? 0
        return (hour * 15.0) + longitude - ra
    }
    
    private func calculateAltitude(dec: Double, lat: Double, ha: Double) -> Double {
        // 简化的高度角计算
        let decRad = dec * .pi / 180.0
        let latRad = lat * .pi / 180.0
        let haRad = ha * .pi / 180.0
        
        let altRad = asin(sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad))
        return altRad * 180.0 / .pi
    }
}

// MARK: - 扩展功能
extension AstronomyAPIService {
    
    // 搜索恒星
    func searchStar(name: String) -> RealStar? {
        return realStars.first { star in
            star.name?.lowercased().contains(name.lowercased()) == true ||
            star.properName?.lowercased().contains(name.lowercased()) == true
        }
    }
    
    // 获取最亮的恒星
    func getBrightestStars(count: Int = 10) -> [RealStar] {
        return realStars.sorted { $0.magnitude < $1.magnitude }.prefix(count).map { $0 }
    }
    
    // 获取最近的恒星
    func getNearestStars(count: Int = 10) -> [RealStar] {
        return realStars.sorted { $0.distance < $1.distance }.prefix(count).map { $0 }
    }
    
    // 获取指定星座的恒星
    func getStarsInConstellation(_ constellation: String) -> [RealStar] {
        return realStars.filter { $0.constellation == constellation }
    }
    
    // MARK: - 虫洞数据管理
    private func loadWormholeData() {
        // 预设虫洞数据 - 分布在天空的各个区域，营造层次感
        wormholes = [
            // === 核心区域虫洞（大型，近距离） ===
            
            // 银河中心虫洞 - 最大的门户
            Wormhole(
                name: "银河之门",
                rightAscension: 266.4, // 银河中心方向
                declination: -29.0,
                distance: 26000,
                type: .dimensional,
                era: "宇宙纪元",
                stability: 0.95,
                bandwidth: 0.9,
                isActive: true,
                connectedTo: nil
            ),
            
            // 织女星空间虫洞 - 近距离亮星
            Wormhole(
                name: "织女通道",
                rightAscension: 279.23, // 织女星
                declination: 38.78,
                distance: 25.04,
                type: .spatial,
                era: "星际联盟",
                stability: 0.9,
                bandwidth: 0.85,
                isActive: true,
                connectedTo: nil
            ),
            
            // 南门二空间跳跃点 - 最近的恒星系统
            Wormhole(
                name: "南门跳跃点",
                rightAscension: 219.90, // 南门二
                declination: -60.83,
                distance: 4.37,
                type: .spatial,
                era: "近邻文明",
                stability: 0.8,
                bandwidth: 0.7,
                isActive: true,
                connectedTo: nil
            ),
            
            // === 中距离虫洞（中等大小） ===
            
            // 北极星附近的时间虫洞
            Wormhole(
                name: "时光隧道",
                rightAscension: 37.95, // 北极星坐标
                declination: 89.26,
                distance: 433,
                type: .temporal,
                era: "古代文明",
                stability: 0.75,
                bandwidth: 0.6,
                isActive: true,
                connectedTo: nil
            ),
            
            // 昴宿星团量子虫洞
            Wormhole(
                name: "昴宿之眼",
                rightAscension: 56.75, // 昴宿星团
                declination: 24.12,
                distance: 444,
                type: .quantum,
                era: "现代科技",
                stability: 0.85,
                bandwidth: 0.8,
                isActive: true,
                connectedTo: nil
            ),
            
            // 猎户座星云虫洞
            Wormhole(
                name: "猎户之门",
                rightAscension: 83.82, // 猎户座大星云
                declination: -5.39,
                distance: 1344,
                type: .temporal,
                era: "星云文明",
                stability: 0.7,
                bandwidth: 0.75,
                isActive: true,
                connectedTo: nil
            ),
            
            // 仙女座α星虫洞
            Wormhole(
                name: "仙女座门户",
                rightAscension: 14.66, // 仙女座α星
                declination: 29.58,
                distance: 97,
                type: .spatial,
                era: "星座守护",
                stability: 0.82,
                bandwidth: 0.65,
                isActive: true,
                connectedTo: nil
            ),
            
            // 天狼星量子通道
            Wormhole(
                name: "天狼量子门",
                rightAscension: 101.287, // 天狼星
                declination: -16.716,
                distance: 8.6,
                type: .quantum,
                era: "古埃及文明",
                stability: 0.88,
                bandwidth: 0.8,
                isActive: true,
                connectedTo: nil
            ),
            
            // === 远距离虫洞（较小，分布广泛） ===
            
            // 天鹅座X-1黑洞附近的次元虫洞
            Wormhole(
                name: "黑洞之门",
                rightAscension: 299.59, // 天鹅座X-1
                declination: 35.20,
                distance: 6070,
                type: .dimensional,
                era: "暗物质时代",
                stability: 0.65,
                bandwidth: 0.4,
                isActive: true, // 改为激活状态
                connectedTo: nil
            ),
            
            // 麒麟座星云虫洞
            Wormhole(
                name: "麒麟星云门",
                rightAscension: 97.0, // 麒麟座区域
                declination: -9.0,
                distance: 2500,
                type: .dimensional,
                era: "星云古迹",
                stability: 0.6,
                bandwidth: 0.5,
                isActive: true,
                connectedTo: nil
            ),
            
            // 天鹅座星云虫洞
            Wormhole(
                name: "天鹅座通路",
                rightAscension: 312.0, // 天鹅座区域
                declination: 40.0,
                distance: 5000,
                type: .temporal,
                era: "时空折叠",
                stability: 0.55,
                bandwidth: 0.45,
                isActive: true,
                connectedTo: nil
            ),
            
            // 蝎子座虫洞
            Wormhole(
                name: "蝎尾虫洞",
                rightAscension: 244.0, // 蝎子座区域
                declination: -26.0,
                distance: 3200,
                type: .quantum,
                era: "蝎族文明",
                stability: 0.7,
                bandwidth: 0.6,
                isActive: true,
                connectedTo: nil
            ),
            
            // 室女座星系团虫洞
            Wormhole(
                name: "室女座通道",
                rightAscension: 187.0, // 室女座区域
                declination: 12.0,
                distance: 54000000, // 5400万光年 - 极远距离
                type: .dimensional,
                era: "星系际文明",
                stability: 0.4,
                bandwidth: 0.3,
                isActive: true,
                connectedTo: nil
            ),
            
            // 飞马座虫洞
            Wormhole(
                name: "飞马座跳跃点",
                rightAscension: 345.0, // 飞马座区域
                declination: 15.0,
                distance: 1800,
                type: .spatial,
                era: "飞马骑士",
                stability: 0.75,
                bandwidth: 0.65,
                isActive: true,
                connectedTo: nil
            ),
            
            // 天琴座虫洞
            Wormhole(
                name: "天琴之弦",
                rightAscension: 284.0, // 天琴座区域
                declination: 39.0,
                distance: 950,
                type: .temporal,
                era: "音律时空",
                stability: 0.8,
                bandwidth: 0.7,
                isActive: true,
                connectedTo: nil
            ),
            
            // 双子座虫洞
            Wormhole(
                name: "双子星门",
                rightAscension: 116.0, // 双子座区域
                declination: 24.0,
                distance: 650,
                type: .quantum,
                era: "双生文明",
                stability: 0.85,
                bandwidth: 0.75,
                isActive: true,
                connectedTo: nil
            ),
            
            // 鲸鱼座虫洞
            Wormhole(
                name: "深海之门",
                rightAscension: 43.0, // 鲸鱼座区域
                declination: -8.0,
                distance: 4800,
                type: .dimensional,
                era: "深渊文明",
                stability: 0.5,
                bandwidth: 0.4,
                isActive: true,
                connectedTo: nil
            )
        ]
        
        // 建立虫洞连接
        createWormholeLinks()
    }
    
    private func createWormholeLinks() {
        guard wormholes.count >= 2 else { return }
        
        // === 主要虫洞网络连接 ===
        
        // 银河之门 <-> 织女通道 (核心连接)
        if let galaxy = wormholes.first(where: { $0.name == "银河之门" }),
           let vega = wormholes.first(where: { $0.name == "织女通道" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: galaxy,
                toWormhole: vega,
                isActive: true,
                dataFlow: .bidirectional
            ))
        }
        
        // 时光隧道 <-> 昴宿之眼 (时间量子网络)
        if let time = wormholes.first(where: { $0.name == "时光隧道" }),
           let pleiades = wormholes.first(where: { $0.name == "昴宿之眼" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: time,
                toWormhole: pleiades,
                isActive: true,
                dataFlow: .bidirectional
            ))
        }
        
        // 南门跳跃点 <-> 天狼量子门 (近邻星系网络)
        if let centauri = wormholes.first(where: { $0.name == "南门跳跃点" }),
           let sirius = wormholes.first(where: { $0.name == "天狼量子门" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: centauri,
                toWormhole: sirius,
                isActive: true,
                dataFlow: .bidirectional
            ))
        }
        
        // 猎户之门 <-> 仙女座门户 (星云星座网络)
        if let orion = wormholes.first(where: { $0.name == "猎户之门" }),
           let andromeda = wormholes.first(where: { $0.name == "仙女座门户" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: orion,
                toWormhole: andromeda,
                isActive: true,
                dataFlow: .fromFirst
            ))
        }
        
        // 黑洞之门 <-> 银河之门 (深空连接)
        if let blackhole = wormholes.first(where: { $0.name == "黑洞之门" }),
           let galaxy = wormholes.first(where: { $0.name == "银河之门" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: blackhole,
                toWormhole: galaxy,
                isActive: true,
                dataFlow: .fromSecond
            ))
        }
        
        // 双子星门 <-> 天琴之弦 (和谐共振网络)
        if let gemini = wormholes.first(where: { $0.name == "双子星门" }),
           let lyra = wormholes.first(where: { $0.name == "天琴之弦" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: gemini,
                toWormhole: lyra,
                isActive: true,
                dataFlow: .bidirectional
            ))
        }
        
        // 蝎尾虫洞 <-> 织女通道 (星座守护网络)
        if let scorpius = wormholes.first(where: { $0.name == "蝎尾虫洞" }),
           let vega = wormholes.first(where: { $0.name == "织女通道" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: scorpius,
                toWormhole: vega,
                isActive: true,
                dataFlow: .fromFirst
            ))
        }
        
        // 飞马座跳跃点 <-> 深海之门 (边缘网络)
        if let pegasus = wormholes.first(where: { $0.name == "飞马座跳跃点" }),
           let cetus = wormholes.first(where: { $0.name == "深海之门" }) {
            wormholeLinks.append(WormholeLink(
                fromWormhole: pegasus,
                toWormhole: cetus,
                isActive: true,
                dataFlow: .bidirectional
            ))
        }
    }
    
    // 获取活跃的虫洞
    func getActiveWormholes() -> [Wormhole] {
        return wormholes.filter { $0.isActive }
    }
    
    // 获取活跃的虫洞连接
    func getActiveWormholeLinks() -> [WormholeLink] {
        return wormholeLinks.filter { $0.isActive }
    }
    
    // 根据ID获取虫洞（用于布局判重）
    func getWormhole(by id: UUID) -> Wormhole? {
        return wormholes.first(where: { $0.id == id })
    }
    
    // 提供按“视觉尺寸”排序后的活跃虫洞（用于先放置更大门户避免遮挡）
    func getActiveWorkholesSortedByVisualSize() -> [Wormhole] {
        let active = getActiveWormholes()
        
        func visualScore(for w: Wormhole) -> Double {
            let base: Double
            if w.distance <= 100 {
                base = 1.8
            } else if w.distance <= 5000 {
                base = 1.2
            } else if w.distance <= 50000 {
                base = 0.8
            } else {
                base = 0.6
            }
            let typeMul: Double
            switch w.type {
            case .dimensional: typeMul = 1.2
            case .temporal: typeMul = 1.1
            case .quantum: typeMul = 1.0
            case .spatial: typeMul = 0.9
            }
            let stabilityMul = 0.8 + w.stability * 0.4
            return base * typeMul * stabilityMul
        }
        
        return active.sorted { visualScore(for: $0) > visualScore(for: $1) }
    }
}

// MARK: - 虫洞数据模型
struct Wormhole: Identifiable, Codable {
    let id: UUID
    let name: String
    let rightAscension: Double // 赤经
    let declination: Double    // 赤纬
    let distance: Double       // 距离（光年）
    let type: WormholeType
    let era: String           // 时代/次元
    let stability: Double     // 稳定度 0.0-1.0
    let bandwidth: Double     // 信息传输带宽 0.0-1.0
    let isActive: Bool        // 是否当前激活
    let connectedTo: UUID?    // 连接到的另一个虫洞ID
    
    init(name: String, rightAscension: Double, declination: Double, distance: Double, type: WormholeType, era: String, stability: Double, bandwidth: Double, isActive: Bool, connectedTo: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.rightAscension = rightAscension
        self.declination = declination
        self.distance = distance
        self.type = type
        self.era = era
        self.stability = stability
        self.bandwidth = bandwidth
        self.isActive = isActive
        self.connectedTo = connectedTo
    }
    
    var x: Double {
        // 将赤经赤纬转换为3D坐标
        let ra = rightAscension * .pi / 180
        let dec = declination * .pi / 180
        return cos(dec) * cos(ra)
    }
    
    var y: Double {
        let ra = rightAscension * .pi / 180
        let dec = declination * .pi / 180
        return cos(dec) * sin(ra)
    }
    
    var z: Double {
        let dec = declination * .pi / 180
        return sin(dec)
    }
    
    var portalColor: Color {
        switch type {
        case .temporal:
            return Color.purple
        case .spatial:
            return Color.cyan
        case .dimensional:
            return Color.orange
        case .quantum:
            return Color.green
        }
    }
    
    var stabilityColor: Color {
        if stability > 0.8 {
            return .green
        } else if stability > 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

enum WormholeType: String, CaseIterable, Codable {
    case temporal = "时间虫洞"
    case spatial = "空间虫洞"
    case dimensional = "次元虫洞"
    case quantum = "量子虫洞"
    
    var icon: String {
        switch self {
        case .temporal: return "clock.circle.fill"
        case .spatial: return "location.circle.fill"
        case .dimensional: return "cube.transparent.fill"
        case .quantum: return "atom"
        }
    }
}

// 虫洞连接链路
struct WormholeLink: Identifiable {
    let id = UUID()
    let fromWormhole: Wormhole
    let toWormhole: Wormhole
    let isActive: Bool
    let dataFlow: DataFlowDirection
    
    var averageStability: Double {
        (fromWormhole.stability + toWormhole.stability) / 2.0
    }
    
    var linkColor: Color {
        let alpha = isActive ? 0.8 : 0.3
        return fromWormhole.portalColor.opacity(alpha)
    }
}

enum DataFlowDirection: String, CaseIterable {
    case bidirectional = "双向"
    case fromFirst = "单向→"
    case fromSecond = "单向←"
    case none = "无传输"
} 