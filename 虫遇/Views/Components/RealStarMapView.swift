import SwiftUI
import CoreLocation

// 星座和恒星中文名称翻译字典
private let starNameTranslations: [String: String] = [
    // === 0等星和-1等星（最亮的恒星）===
    "Sirius": "天狼星",
    "Canopus": "老人星", 
    "Arcturus": "大角星",
    "Vega": "织女星",
    "Capella": "五车二",
    
    // === 1等星 ===
    "Rigel": "参宿七",
    "Procyon": "南河三",
    "Betelgeuse": "参宿四",
    "Achernar": "水委一",
    "Antares": "心宿二",
    "Altair": "牛郎星",
    "Acrux": "十字架一",
    "Aldebaran": "毕宿五",
    "Polaris": "北极星",
    "Fomalhaut": "北落师门",
    
    // === 北斗七星 ===
    "Dubhe": "天枢",
    "Merak": "天璇",
    "Phecda": "天玑",
    "Megrez": "天权",
    "Alioth": "玉衡",
    "Mizar": "开阳",
    "Alkaid": "摇光",
    
    // === 猎户座主要恒星 ===
    "Alnitak": "参宿一",
    "Alnilam": "参宿二",
    "Mintaka": "参宿三",
    "Bellatrix": "参宿五",
    "Saiph": "参宿六",
    
    // === 南十字座 ===
    "Gacrux": "十字架三",
    "Mimosa": "十字架二",
    "Imai": "十字架四",
    
    // === 天蝎座 ===
    "Shaula": "尾宿八",
    "Sargas": "尾宿九",
    "Kappa Sco": "尾宿四",
    
    // === 射手座 ===
    "Nunki": "箕宿二",
    "Kaus Australis": "箕宿三",
    "Ascella": "箕宿一",
    
    // === 仙女座 ===
    "Alpheratz": "壁宿二",
    "Mirach": "奎宿九",
    "Almach": "天大将军一",
    "Delta And": "天大将军二",
    
    // === 英仙座 ===
    "Mirfak": "天船三",
    "Algol": "大陵五",
    
    // === 御夫座 ===
    "Menkalinan": "五车三",
    "Mahasim": "五车七",
    
    // === 金牛座 ===
    "Elnath": "五车五",
    "Zeta Tau": "天关",
    
    // === 双子座 ===
    "Pollux": "北河三",
    "Castor": "北河二",
    "Alhena": "井宿三",
    
    // === 巨蟹座 ===
    "Acubens": "柳宿增一",
    "Al Tarf": "鬼宿四",
    
    // === 狮子座 ===
    "Regulus": "轩辕十四",
    "Denebola": "五帝座一",
    "Algieba": "轩辕十二",
    
    // === 室女座 ===
    "Spica": "角宿一",
    "Porrima": "太微右垣二",
    
    // === 天秤座 ===
    "Zubeneschamali": "氐宿四",
    "Zubenelgenubi": "氐宿一",
    
    // === 牧夫座 ===
    "Izar": "梗河一",
    "Muphrid": "右摄提一",
    
    // === 巨蛇座 ===
    "Unukalhai": "蛇首",
    
    // === 武仙座 ===
    "Kornephoros": "帝座",
    "Zeta Her": "何",
    
    // === 天琴座 ===
    "Sheliak": "渐台二",
    "Sulafat": "渐台三",
    
    // === 天鹅座 ===
    "Deneb": "天津四",
    "Sadr": "天津一",
    "Gienah": "右旗一",
    
    // === 天鹰座 ===
    "Tarazed": "河鼓二",
    "Alschain": "河鼓一",
    
    // === 海豚座 ===
    "Sualocin": "瓠瓜四",
    "Rotanev": "瓠瓜三",
    
    // === 飞马座 ===
    "Markab": "室宿一",
    "Scheat": "室宿二",
    "Algenib": "壁宿一",
    
    // === 仙王座 ===
    "Alderamin": "天钩五",
    "Alfirk": "造父四",
    
    // === 蝎虎座 ===
    "Alpha Lac": "蝎虎座α",
    
    // === 鲸鱼座 ===
    "Menkar": "天囷一",
    "Mira": "蒭藁增二",
    
    // === 波江座 ===
    "Cursa": "玉井四",
    
    // === 船底座 ===
    "Miaplacidus": "船底二",
    "Avior": "船底三",
    
    // === 船帆座 ===
    "Regor": "船帆二",
    "Alsuhail": "船帆九",
    
    // === 南门二系统 ===
    "Rigil Kent": "南门二",
    "Hadar": "马腹一",
    
    // === 半人马座 ===
    "Menkent": "马腹二",
    
    // === 天坛座 ===
    "Alpha Ara": "天坛座α",
    
    // === 孔雀座 ===
    "Peacock": "孔雀十一",
    
    // === 南三角座 ===
    "Atria": "南三角座α",
    
    // === 天鹤座 ===
    "Alnair": "鹤一",
    
    // === 杜鹃座 ===
    "Alpha Tuc": "杜鹃座α",
    
    // === 凤凰座 ===
    "Ankaa": "火鸟六"
]

        // 虫遇星图视图
struct RealStarMapView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var astronomyService = AstronomyAPIService.shared
    @StateObject private var locationManager = LocationManager()
    
    @State private var selectedStar: RealStar?
    @State private var selectedWormhole: Wormhole?
    @State private var showConstellationLines = true
    @State private var showStarNames = false
    @State private var showWormholes = true
    @State private var showWormholeLinks = true
    @State private var currentTime = Date()
    @State private var rotationAngle: Double = 0
    @State private var zoomLevel: Double = 1.0
    @State private var lastZoomLevel: Double = 1.0
    @State private var panOffset = CGSize.zero
    @State private var lastPanOffset = CGSize.zero
    @State private var gestureScale: CGFloat = 1.0
    
    // 过滤选项
    @State private var magnitudeFilter: Double = 5.0 // 显示5等星以上

    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 深空背景
                enhancedBackground
                
                // 星座连线 - 移到星星下方
                if showConstellationLines {
                    constellationLines(geometry: geometry)
                }
                
                // 虫遇星图 - 现在在连线上方
                realStarField(geometry: geometry)
                
                // 虫洞连接线 - 在星星之后，虫洞之前
                if showWormholeLinks {
                    wormholeLinks(geometry: geometry)
                }
                
                // 虫洞门户 - 在最上层
                if showWormholes {
                    wormholeField(geometry: geometry)
                }
                
                // UI控制层
                controlsOverlay
                
                // 星星详情弹窗
                if let star = selectedStar {
                    starDetailPopup(star: star)
                }
                
                // 虫洞详情弹窗
                if let wormhole = selectedWormhole {
                    wormholeDetailPopup(wormhole: wormhole)
                }
            }
        }
        .ignoresSafeArea(.all)
        .preferredColorScheme(.dark)
        .onAppear {
            setupView()
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            withAnimation(.linear(duration: 60)) {
                rotationAngle += 0.25 // 模拟地球自转
            }
        }
        .gesture(
            SimultaneousGesture(
                // 增强拖拽手势 - 支持累积偏移
                DragGesture()
                    .onChanged { value in
                        panOffset = CGSize(
                            width: lastPanOffset.width + value.translation.width,
                            height: lastPanOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastPanOffset = panOffset
                    },
                
                // 增强缩放手势 - 更平滑的缩放，支持更大倍数
                MagnificationGesture()
                    .onChanged { value in
                        let baseZoom = lastZoomLevel > 0 ? lastZoomLevel : 1.0
                        let newZoom = max(0.3, min(10.0, baseZoom * value))
                        withAnimation(.easeInOut(duration: 0.05)) {
                            zoomLevel = newZoom
                        }
                    }
                    .onEnded { _ in
                        lastZoomLevel = zoomLevel
                    }
            )
        )
        .onTapGesture(count: 2) {
            // 双击放大/缩小
            withAnimation(.easeInOut(duration: 0.3)) {
                if zoomLevel < 2.0 {
                    zoomLevel = min(10.0, zoomLevel * 2.0)
                } else {
                    zoomLevel = 1.0
                }
            }
        }
    }
    
    // MARK: - 单个恒星视图
    private func starView(star: RealStar, geometry: GeometryProxy) -> some View {
        let position = calculateStarPosition(star: star, geometry: geometry)
        let baseSize = calculateStarSize(star: star)
        
        return ZStack {
            // 远景光晕效果 - 为亮星添加大范围柔和光晕
            if baseSize > 5 {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                star.color.opacity(0.05),
                                star.color.opacity(0.02),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: baseSize * 4
                        )
                    )
                    .frame(width: baseSize * 8, height: baseSize * 8)
            }
            
            // 中景光晕 - 营造层次感
            if baseSize > 3 {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                star.color.opacity(0.15),
                                star.color.opacity(0.08),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: baseSize * 2
                        )
                    )
                    .frame(width: baseSize * 4, height: baseSize * 4)
                    .blur(radius: 1)
            }
            
            // 恒星核心 - 增强对比度和色彩饱和度
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9),
                            star.color.opacity(0.95),
                            star.color.opacity(0.7)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize * 0.5
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .opacity(star.brightness)
                .shadow(color: star.color.opacity(0.6), radius: baseSize > 4 ? 2 : 1, x: 0, y: 0)
            
            // 十字光芒效果 - 为较亮的恒星添加
            if baseSize > 4 {
                CrossSpikes(size: baseSize, color: star.color, brightness: star.brightness)
            }
            
            // 微妙的闪烁效果
            Circle()
                .fill(star.color.opacity(0.3))
                .frame(width: baseSize * 0.8, height: baseSize * 0.8)
                .opacity(star.brightness)
                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(star.id.hashValue) * 0.1) * 0.1)
                .animation(
                    Animation.easeInOut(duration: 2.0 + Double(star.id.hashValue % 3))
                        .repeatForever(autoreverses: true),
                    value: star.brightness
                )
            
            // 恒星名称（中文翻译，字体大小自适应缩放）
            if showStarNames && star.properName != nil {
                let starName = starNameTranslations[star.properName!] ?? star.properName!
                let fontSize = max(8, min(14, 12 / max(1.0, zoomLevel * 0.8))) // 字体大小反比例缩放
                Text(starName)
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 0) // 添加阴影增强可读性
                    .offset(x: 0, y: -baseSize - 8)
                    .scaleEffect(1.0 / max(1.0, zoomLevel * 0.6)) // 额外的缩放补偿
            }
        }
        .position(position)
        .scaleEffect(zoomLevel)
        .offset(panOffset)
        .onTapGesture {
            selectedStar = star
        }
    }
    
    // MARK: - 十字光芒效果组件
    private struct CrossSpikes: View {
        let size: Double
        let color: Color
        let brightness: Double
        
        var body: some View {
            ZStack {
                // 垂直光芒
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                color.opacity(brightness * 0.8),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 0.5, height: size * 3)
                    .blur(radius: 0.5)
                
                // 水平光芒
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                color.opacity(brightness * 0.8),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 3, height: 0.5)
                    .blur(radius: 0.5)
                
                // 对角光芒
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                color.opacity(brightness * 0.4),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 2, height: 0.3)
                    .rotationEffect(.degrees(45))
                    .blur(radius: 0.5)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                color.opacity(brightness * 0.4),
                                Color.clear
                            ]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    .frame(width: size * 2, height: 0.3)
                    .rotationEffect(.degrees(-45))
                    .blur(radius: 0.5)
            }
        }
    }
    
    // MARK: - 增强的星空背景
    private var enhancedBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // 深空渐变背景 - 基础层，不随手势移动
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.02, green: 0.02, blue: 0.08),
                        Color.black
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height)
                )
                
                // 动态星云层 - 跟随手势移动
                ZStack {
                    // 远景星云 - 移动速度较慢，营造深度感
                    createNebulaLayer(indices: [0, 1, 2, 3, 4, 5], geometry: geometry, depth: 0.3, 
                                     colors: [Color.blue.opacity(0.02), Color.purple.opacity(0.015), Color.clear],
                                     size: CGSize(width: 160, height: 160), blurRadius: 40, endRadius: 80,
                                     scaleEffect: zoomLevel * 0.5 + 0.5, offsetFactor: 0.3)
                    
                    // 中景星云 - 中等移动速度
                    createNebulaLayer(indices: [6, 7, 8, 9, 10, 11], geometry: geometry, depth: 0.6,
                                     colors: [Color.cyan.opacity(0.025), Color.blue.opacity(0.02), Color.clear],
                                     size: CGSize(width: 120, height: 120), blurRadius: 25, endRadius: 60,
                                     scaleEffect: zoomLevel * 0.7 + 0.3, offsetFactor: 0.6)
                    
                    // 近景星云 - 跟随手势完全移动
                    createNebulaLayer(indices: [12, 13, 14, 15], geometry: geometry, depth: 1.0,
                                     colors: [Color.pink.opacity(0.03), Color.purple.opacity(0.025), Color.clear],
                                     size: CGSize(width: 80, height: 80), blurRadius: 15, endRadius: 40,
                                     scaleEffect: zoomLevel, offsetFactor: 1.0)
                    
                    // 微妙的粒子效果
                    createParticleLayer(indices: [16, 17, 18, 19, 20, 21, 22, 23], geometry: geometry, depth: 0.8,
                                       size: CGSize(width: 20, height: 20), blurRadius: 8,
                                       scaleEffect: zoomLevel * 0.8 + 0.2, offsetFactor: 0.8)
                }
            }
        }
    }
    
    // MARK: - 星云位置计算
    private func nebulaPosition(index: Int, geometry: GeometryProxy, depth: Double) -> CGPoint {
        // 使用固定的种子生成稳定的随机位置
        let seed = Double(index * 12345)
        let x = (sin(seed) * 0.5 + 0.5) * geometry.size.width
        let y = (cos(seed * 1.618) * 0.5 + 0.5) * geometry.size.height
        
        // 根据深度调整分布范围
        let expandedWidth = geometry.size.width * (1.0 + depth)
        let expandedHeight = geometry.size.height * (1.0 + depth)
        
        return CGPoint(
            x: min(max(x, -expandedWidth * 0.2), expandedWidth * 1.2),
            y: min(max(y, -expandedHeight * 0.2), expandedHeight * 1.2)
        )
    }
    
    // MARK: - 星云层创建
    @ViewBuilder
    private func createNebulaLayer(indices: [Int], geometry: GeometryProxy, depth: Double,
                                  colors: [Color], size: CGSize, blurRadius: CGFloat, endRadius: CGFloat,
                                  scaleEffect: CGFloat, offsetFactor: CGFloat) -> some View {
        Group {
            if indices.count > 0 {
                let basePosition0 = nebulaPosition(index: indices[0], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition0)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 1 {
                let basePosition1 = nebulaPosition(index: indices[1], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition1)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 2 {
                let basePosition2 = nebulaPosition(index: indices[2], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition2)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 3 {
                let basePosition3 = nebulaPosition(index: indices[3], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition3)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 4 {
                let basePosition4 = nebulaPosition(index: indices[4], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition4)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 5 {
                let basePosition5 = nebulaPosition(index: indices[5], geometry: geometry, depth: depth)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: colors), center: .center, startRadius: 0, endRadius: endRadius))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition5)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
        }
    }
    
    // MARK: - 粒子层创建
    @ViewBuilder
    private func createParticleLayer(indices: [Int], geometry: GeometryProxy, depth: Double,
                                    size: CGSize, blurRadius: CGFloat,
                                    scaleEffect: CGFloat, offsetFactor: CGFloat) -> some View {
        Group {
            if indices.count > 0 {
                let basePosition0 = nebulaPosition(index: indices[0], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition0)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 1 {
                let basePosition1 = nebulaPosition(index: indices[1], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition1)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 2 {
                let basePosition2 = nebulaPosition(index: indices[2], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition2)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 3 {
                let basePosition3 = nebulaPosition(index: indices[3], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition3)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 4 {
                let basePosition4 = nebulaPosition(index: indices[4], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition4)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 5 {
                let basePosition5 = nebulaPosition(index: indices[5], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition5)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 6 {
                let basePosition6 = nebulaPosition(index: indices[6], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition6)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
            if indices.count > 7 {
                let basePosition7 = nebulaPosition(index: indices[7], geometry: geometry, depth: depth)
                Circle()
                    .fill(Color.white.opacity(0.008))
                    .frame(width: size.width, height: size.height)
                    .position(basePosition7)
                    .blur(radius: blurRadius)
                    .scaleEffect(scaleEffect)
                    .offset(x: panOffset.width * offsetFactor, y: panOffset.height * offsetFactor)
            }
        }
    }
    
    // MARK: - 真实星场
    private func realStarField(geometry: GeometryProxy) -> some View {
        let visibleStars = getVisibleStars()
        
        // 按星星大小排序，大星星先渲染，小星星后渲染（获得更高点击优先级）
        let sortedStars = visibleStars.sorted { star1, star2 in
            let size1 = calculateStarSize(star: star1)
            let size2 = calculateStarSize(star: star2)
            return size1 > size2 // 大星星先渲染，在下层
        }
        
        return ForEach(sortedStars) { star in
            starView(star: star, geometry: geometry)
        }
    }
    
    // MARK: - 星座连线
    private func constellationLines(geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(astronomyService.constellations) { constellation in
                ZStack {
                    // 星座连线
                    ForEach(constellation.lines.indices, id: \.self) { lineIndex in
                        let line = constellation.lines[lineIndex]
                        if line.count >= 2 && 
                           line[0] < constellation.stars.count && 
                           line[1] < constellation.stars.count {
                            
                            let star1 = constellation.stars[line[0]]
                            let star2 = constellation.stars[line[1]]
                            let pos1 = calculateStarPosition(star: star1, geometry: geometry)
                            let pos2 = calculateStarPosition(star: star2, geometry: geometry)
                            
                            Path { path in
                                path.move(to: pos1)
                                path.addLine(to: pos2)
                            }
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            .scaleEffect(zoomLevel)
                            .offset(panOffset)
                        }
                    }
                    
                    // 星座名称标签
                    if !constellation.stars.isEmpty {
                        let centerStar = constellation.stars[constellation.stars.count / 2] // 使用中间的星作为标签位置
                        let centerPosition = calculateStarPosition(star: centerStar, geometry: geometry)
                        let fontSize = max(7, min(12, 10 / max(1.0, zoomLevel * 0.7))) // 字体大小调小，范围从7-12
                        
                        Text(constellation.chineseName)
                            .font(.system(size: fontSize, weight: .medium, design: .rounded)) // 字重从semibold改为medium
                            .foregroundColor(.cyan.opacity(0.8)) // 透明度稍微调低
                            .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 0) // 阴影半径调小
                            .position(x: centerPosition.x, y: centerPosition.y - 20) // 位置稍微靠近星星
                            .scaleEffect(1.0 / max(1.0, zoomLevel * 0.5)) // 额外的缩放补偿，让文字不会过小
                            .scaleEffect(zoomLevel)
                            .offset(panOffset)
                    }
                }
            }
        }
    }
    
    // MARK: - 控制界面
    private var controlsOverlay: some View {
        VStack {
            // 顶部控制栏 - 调整位置到状态栏下方
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("虫遇星图")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("时间: \(timeFormatter.string(from: currentTime))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50) // 增加顶部间距，避开状态栏
            
            Spacer()
            
            // 底部控制面板 - 重新设计
            VStack(spacing: 16) {
                // 控制面板容器
                VStack(spacing: 12) {
                    // 过滤控制 - 优化设计
                    HStack {
                        Text("星等限制: \(magnitudeFilter, specifier: "%.1f")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan.opacity(0.9))
                        
                        Spacer()
                        
                        Slider(value: $magnitudeFilter, in: 1...6, step: 0.5)
                            .accentColor(.cyan)
                            .frame(width: 100)
                    }
                    
                    // 缩放控制滑动条和重置按钮
                    VStack(spacing: 4) {
                        HStack {
                            Text("缩放倍数: \(zoomLevel, specifier: "%.1f")x")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange.opacity(0.9))
                            
                            Spacer()
                            
                            // 重置按钮 - 移到缩放控制区域
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    zoomLevel = 1.0
                                    lastZoomLevel = 1.0
                                    panOffset = .zero
                                    lastPanOffset = .zero
                                    rotationAngle = 0
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 10, weight: .medium))
                                    Text("重置")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cyan.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cyan.opacity(0.3), lineWidth: 0.5)
                                        )
                                )
                            }
                            
                            // 快速缩放按钮
                            HStack(spacing: 6) {
                                Button("1x") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        zoomLevel = 1.0
                                    }
                                }
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(abs(zoomLevel - 1.0) < 0.1 ? .orange : .white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(abs(zoomLevel - 1.0) < 0.1 ? Color.orange.opacity(0.2) : Color.clear)
                                )
                                
                                Button("5x") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        zoomLevel = 5.0
                                    }
                                }
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(abs(zoomLevel - 5.0) < 0.1 ? .orange : .white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(abs(zoomLevel - 5.0) < 0.1 ? Color.orange.opacity(0.2) : Color.clear)
                                )
                                
                                Button("10x") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        zoomLevel = 10.0
                                    }
                                }
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(abs(zoomLevel - 10.0) < 0.1 ? .orange : .white.opacity(0.6))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(abs(zoomLevel - 10.0) < 0.1 ? Color.orange.opacity(0.2) : Color.clear)
                                )
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text("0.3x")
                                .font(.system(size: 8, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Slider(
                                value: Binding(
                                    get: { zoomLevel },
                                    set: { newValue in
                                        withAnimation(.easeInOut(duration: 0.1)) {
                                            zoomLevel = newValue
                                        }
                                    }
                                ),
                                in: 0.3...10.0,
                                step: 0.1
                            )
                            .accentColor(.orange)
                            
                            Text("10x")
                                .font(.system(size: 8, weight: .regular))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                    
                    // 显示选项 - 紧凑单行布局
                    HStack(spacing: 12) {
                        CompactToggle(title: "星座连线", isOn: $showConstellationLines)
                        CompactToggle(title: "星名", isOn: $showStarNames)
                        CompactToggle(title: "虫洞", isOn: $showWormholes)
                        CompactToggle(title: "虫洞连接", isOn: $showWormholeLinks)
                    }
                    .padding(.horizontal, 8)
                    
                    // 底部信息行
                    HStack {
                        Text("可见恒星: \(getVisibleStars().count)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        if showWormholes {
                            Text("活跃虫洞: \(astronomyService.getActiveWormholes().count)")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.cyan.opacity(0.8))
                            
                            Spacer()
                        }
                        
                        Text("位置: \(locationManager.location?.coordinate.latitude ?? 39.9, specifier: "%.1f")°, \(locationManager.location?.coordinate.longitude ?? 116.4, specifier: "%.1f")°")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 0) // 确保与外层容器对齐
                    
                    // 浪漫标语 - 移到底部
                    Text("凝视星空时，或许另一个灵魂也在同一瞬间仰望同一颗星星")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.3))
                        .background(
                            // 毛玻璃效果
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .opacity(0.2)
                        )
                )
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40) // 增加底部间距，让控制面板更靠下
        }
    }
    
    // MARK: - 现代化紧凑开关组件
    private struct CompactToggle: View {
        let title: String
        @Binding var isOn: Bool
        
        var body: some View {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isOn.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    // 图标指示器
                    Circle()
                        .fill(isOn ? Color.cyan : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .scaleEffect(isOn ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
                    
                    Text(title)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(isOn ? .cyan : .white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn ? Color.cyan.opacity(0.15) : Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isOn ? Color.cyan.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 恒星详情弹窗
    private func starDetailPopup(star: RealStar) -> some View {
        VStack(spacing: 15) {
            HStack {
                let displayName = star.properName.map { starNameTranslations[$0] ?? $0 } ?? star.name ?? "未知恒星"
                Text(displayName)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("×") {
                    selectedStar = nil
                }
                .font(.title2)
                .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    starInfoRow(title: "距离", value: String(format: "%.1f 光年", star.distance))
                    Spacer()
                    starInfoRow(title: "视星等", value: String(format: "%.2f", star.magnitude))
                }
                
                HStack {
                    starInfoRow(title: "光谱型", value: star.spectralType ?? "未知")
                    Spacer()
                    starInfoRow(title: "星座", value: star.constellation ?? "未知")
                }
                
                starInfoRow(title: "坐标", value: String(format: "RA %.2f° / Dec %.2f°", star.rightAscension, star.declination))
            }
            
            // 恒星颜色预览
            HStack {
                Text("恒星颜色:")
                    .foregroundColor(.gray)
                
                Circle()
                    .fill(star.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Spacer()
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(star.color.opacity(0.5), lineWidth: 2)
        )
        .padding()
        .transition(.scale.combined(with: .opacity))
    }
    
    private func starInfoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 辅助方法
    
    private func setupView() {
        locationManager.requestLocation()
        Task {
            await astronomyService.fetchAstronomyPictureOfDay()
        }
    }
    
    private func getVisibleStars() -> [RealStar] {
        var stars = astronomyService.realStars
        
        // 星等过滤
        stars = stars.filter { $0.magnitude <= magnitudeFilter }
        
        // 可见性过滤（默认启用）
        if let location = locationManager.location {
            stars = astronomyService.getVisibleStars(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                date: currentTime
            )
        }
        
        return stars
    }
    
    private func calculateStarPosition(star: RealStar, geometry: GeometryProxy) -> CGPoint {
        // 简化的天球投影到屏幕坐标
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // 使用3D坐标投影（忽略z轴深度）
        let x = centerX + star.x * 50 + sin(rotationAngle * 0.01) * 10
        let y = centerY + star.y * 50 + cos(rotationAngle * 0.01) * 10
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateStarSize(star: RealStar) -> CGFloat {
        // 根据视星等计算恒星大小（星等越小越亮越大）
        let baseSizeFromMagnitude = max(2, 8 - star.magnitude)
        let brightnessSize = baseSizeFromMagnitude * star.brightness
        return CGFloat(max(1, min(12, brightnessSize)))
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
    
    // MARK: - 虫洞可视化
    
    private func wormholeField(geometry: GeometryProxy) -> some View {
        let wormholes = astronomyService.getActiveWormholes()
        let layout = computeWormholeLayout(geometry: geometry)
        
        return ForEach(wormholes) { wormhole in
            if let position = layout[wormhole.id] {
                wormholePortalView(wormhole: wormhole, position: position, geometry: geometry)
            } else {
                wormholePortalView(wormhole: wormhole, geometry: geometry)
            }
        }
    }
    
    private func wormholePortalView(wormhole: Wormhole, geometry: GeometryProxy) -> some View {
        let position = calculateWormholePosition(wormhole: wormhole, geometry: geometry)
        let portalSize = calculateWormholeSize(wormhole: wormhole)  // 根据距离计算大小
        
        return ZStack {
            // 外层光晕 - 减小范围
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            wormhole.portalColor.opacity(0.08),
                            wormhole.portalColor.opacity(0.03),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: portalSize * 1.5  // 减小光晕范围
                    )
                )
                .frame(width: portalSize * 3, height: portalSize * 3)  // 减小整体光晕大小
                .blur(radius: 2)
            
            // 主门户环 - 更细的线条
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            wormhole.portalColor,
                            wormhole.portalColor.opacity(0.6),
                            wormhole.portalColor
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2  // 从3减少到2
                )
                .frame(width: portalSize, height: portalSize)
                .overlay(
                    // 内层能量环 - 更精细
                    Circle()
                        .stroke(
                            wormhole.portalColor.opacity(0.3),
                            lineWidth: 0.8  // 更细的内环
                        )
                        .frame(width: portalSize * 0.65, height: portalSize * 0.65)
                        .rotationEffect(.degrees(rotationAngle * 2))
                )
                .overlay(
                    // 脉冲环 - 减小尺寸和强度
                    Circle()
                        .stroke(
                            wormhole.portalColor.opacity(0.6),
                            lineWidth: 1.5  // 更细的脉冲环
                        )
                        .frame(width: portalSize * 1.15, height: portalSize * 1.15)  // 减小脉冲范围
                        .scaleEffect(1 + sin(currentTime.timeIntervalSince1970 * 2) * 0.08)  // 减小脉冲幅度
                        .opacity(0.4 + sin(currentTime.timeIntervalSince1970 * 3) * 0.2)  // 降低不透明度
                )
                .rotationEffect(.degrees(-rotationAngle))
            
            // 中心图标 - 调整大小
            Image(systemName: wormhole.type.icon)
                .font(.system(size: 8, weight: .medium))  // 从12减小到8
                .foregroundColor(wormhole.portalColor)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 14, height: 14)  // 从20减小到14
                )
            
            // 稳定度指示器 - 更精细
            Circle()
                .trim(from: 0, to: wormhole.stability)
                .stroke(
                    wormhole.stabilityColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)  // 从2减小到1.5
                )
                .frame(width: portalSize + 6, height: portalSize + 6)  // 从+8减小到+6
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 2), value: wormhole.stability)
        }
        .position(position)
        .scaleEffect(gestureScale * zoomLevel)
        .offset(x: panOffset.width, y: panOffset.height)
        .onTapGesture {
            withAnimation(.spring()) {
                selectedWormhole = wormhole
                selectedStar = nil // 关闭星星详情
            }
        }
    }
    
    // 重载：使用预计算位置，保证无重叠布局
    private func wormholePortalView(wormhole: Wormhole, position: CGPoint, geometry: GeometryProxy) -> some View {
        let portalSize = calculateWormholeSize(wormhole: wormhole)
        
        return ZStack {
            // 外层光晕 - 减小范围
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            wormhole.portalColor.opacity(0.08),
                            wormhole.portalColor.opacity(0.03),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: portalSize * 1.5
                    )
                )
                .frame(width: portalSize * 3, height: portalSize * 3)
                .blur(radius: 2)
            
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            wormhole.portalColor,
                            wormhole.portalColor.opacity(0.6),
                            wormhole.portalColor
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: portalSize, height: portalSize)
                .overlay(
                    Circle()
                        .stroke(
                            wormhole.portalColor.opacity(0.3),
                            lineWidth: 0.8
                        )
                        .frame(width: portalSize * 0.65, height: portalSize * 0.65)
                        .rotationEffect(.degrees(rotationAngle * 2))
                )
                .overlay(
                    Circle()
                        .stroke(
                            wormhole.portalColor.opacity(0.6),
                            lineWidth: 1.5
                        )
                        .frame(width: portalSize * 1.15, height: portalSize * 1.15)
                        .scaleEffect(1 + sin(currentTime.timeIntervalSince1970 * 2) * 0.08)
                        .opacity(0.4 + sin(currentTime.timeIntervalSince1970 * 3) * 0.2)
                )
                .rotationEffect(.degrees(-rotationAngle))
            
            Image(systemName: wormhole.type.icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(wormhole.portalColor)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 14, height: 14)
                )
            
            Circle()
                .trim(from: 0, to: wormhole.stability)
                .stroke(
                    wormhole.stabilityColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: portalSize + 6, height: portalSize + 6)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 2), value: wormhole.stability)
        }
        .position(position)
        .scaleEffect(gestureScale * zoomLevel)
        .offset(x: panOffset.width, y: panOffset.height)
        .onTapGesture {
            withAnimation(.spring()) {
                selectedWormhole = wormhole
                selectedStar = nil
            }
        }
    }
    
    private func wormholeLinks(geometry: GeometryProxy) -> some View {
        let links = astronomyService.getActiveWormholeLinks()
        let layout = computeWormholeLayout(geometry: geometry)
        
        return ForEach(links) { link in
            wormholeLinkView(link: link, geometry: geometry, layout: layout)
        }
    }
    
    private func wormholeLinkView(link: WormholeLink, geometry: GeometryProxy) -> some View {
        let fromPos = calculateWormholePosition(wormhole: link.fromWormhole, geometry: geometry)
        let toPos = calculateWormholePosition(wormhole: link.toWormhole, geometry: geometry)
        
        return ZStack {
            // 连接线
            Path { path in
                path.move(to: fromPos)
                
                // 计算控制点创建弯曲的连接线
                let midX = (fromPos.x + toPos.x) / 2
                let midY = (fromPos.y + toPos.y) / 2
                let distance = sqrt(pow(toPos.x - fromPos.x, 2) + pow(toPos.y - fromPos.y, 2))
                let curvature = min(distance * 0.3, 100)
                
                let controlPoint = CGPoint(
                    x: midX + sin(atan2(toPos.y - fromPos.y, toPos.x - fromPos.x) + .pi/2) * curvature,
                    y: midY - cos(atan2(toPos.y - fromPos.y, toPos.x - fromPos.x) + .pi/2) * curvature
                )
                
                path.addQuadCurve(to: toPos, control: controlPoint)
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        link.linkColor,
                        link.linkColor.opacity(0.3),
                        link.linkColor
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 2])  // 更细的连接线
            )
            .opacity(link.averageStability)
            
            // 数据流动画粒子
            if link.isActive {
                dataFlowParticles(from: fromPos, to: toPos, link: link)
            }
        }
        .scaleEffect(gestureScale * zoomLevel)
        .offset(x: panOffset.width, y: panOffset.height)
    }
    
    // 新增：使用统一布局渲染连接线（避免门户位置不一致）
    private func wormholeLinkView(link: WormholeLink, geometry: GeometryProxy, layout: [UUID: CGPoint]) -> some View {
        let fromPos = layout[link.fromWormhole.id] ?? calculateWormholePosition(wormhole: link.fromWormhole, geometry: geometry)
        let toPos = layout[link.toWormhole.id] ?? calculateWormholePosition(wormhole: link.toWormhole, geometry: geometry)
        
        return ZStack {
            Path { path in
                path.move(to: fromPos)
                let midX = (fromPos.x + toPos.x) / 2
                let midY = (fromPos.y + toPos.y) / 2
                let distance = sqrt(pow(toPos.x - fromPos.x, 2) + pow(toPos.y - fromPos.y, 2))
                let curvature = min(distance * 0.3, 100)
                let controlPoint = CGPoint(
                    x: midX + sin(atan2(toPos.y - fromPos.y, toPos.x - fromPos.x) + .pi/2) * curvature,
                    y: midY - cos(atan2(toPos.y - fromPos.y, toPos.x - fromPos.x) + .pi/2) * curvature
                )
                path.addQuadCurve(to: toPos, control: controlPoint)
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        link.linkColor,
                        link.linkColor.opacity(0.3),
                        link.linkColor
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 2])
            )
            .opacity(link.averageStability)
            
            if link.isActive {
                dataFlowParticles(from: fromPos, to: toPos, link: link)
            }
        }
        .scaleEffect(gestureScale * zoomLevel)
        .offset(x: panOffset.width, y: panOffset.height)
    }
    
    private func dataFlowParticles(from: CGPoint, to: CGPoint, link: WormholeLink) -> some View {
        ForEach(0..<5, id: \.self) { index in
            let progress = (sin(currentTime.timeIntervalSince1970 * 1.5 + Double(index) * 0.6) + 1) / 2
            let currentPos = CGPoint(
                x: from.x + (to.x - from.x) * progress,
                y: from.y + (to.y - from.y) * progress
            )
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            link.linkColor,
                            link.linkColor.opacity(0.5),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 2  // 从3减小到2
                    )
                )
                .frame(width: 4, height: 4)  // 从6x6减小到4x4
                .position(currentPos)
                .opacity(0.7)  // 稍微降低不透明度
                .blur(radius: 0.3)  // 减小模糊半径
        }
    }
    
    private func calculateWormholePosition(wormhole: Wormhole, geometry: GeometryProxy) -> CGPoint {
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height / 2
        
        // 使用虫洞的3D坐标投影到屏幕，添加缩放因子
        let scaleFactor = min(geometry.size.width, geometry.size.height) * 0.3
        let x = centerX + wormhole.x * scaleFactor + sin(rotationAngle * 0.01 + wormhole.y) * 3
        let y = centerY + wormhole.y * scaleFactor + cos(rotationAngle * 0.01 + wormhole.x) * 3
        
        return CGPoint(x: x, y: y)
    }
    
    private func calculateWormholeSize(wormhole: Wormhole) -> CGFloat {
        // 根据距离计算虫洞大小，营造深度感
        let distance = wormhole.distance
        
        // 距离分级：近距离(0-100)、中距离(100-5000)、远距离(5000+)
        let baseSize: CGFloat
        
        if distance <= 100 {
            // 近距离虫洞 - 大型门户
            baseSize = 28 + (100 - distance) / 100 * 12  // 28-40之间
        } else if distance <= 5000 {
            // 中距离虫洞 - 中等门户
            baseSize = 16 + (5000 - distance) / 4900 * 12  // 16-28之间
        } else if distance <= 50000 {
            // 远距离虫洞 - 小型门户
            baseSize = 8 + (50000 - distance) / 45000 * 8   // 8-16之间
        } else {
            // 极远距离虫洞 - 微型门户
            baseSize = 6
        }
        
        // 根据虫洞类型微调大小
        let typeMultiplier: CGFloat
        switch wormhole.type {
        case .dimensional:
            typeMultiplier = 1.2  // 次元虫洞稍大
        case .temporal:
            typeMultiplier = 1.1  // 时间虫洞稍大
        case .quantum:
            typeMultiplier = 1.0  // 量子虫洞标准
        case .spatial:
            typeMultiplier = 0.9  // 空间虫洞稍小
        }
        
        // 根据稳定度微调大小
        let stabilityMultiplier = 0.8 + wormhole.stability * 0.4  // 0.8-1.2之间
        
        return baseSize * typeMultiplier * stabilityMultiplier
    }
    
    // MARK: - 虫洞详情弹窗
    private func wormholeDetailPopup(wormhole: Wormhole) -> some View {
        VStack(spacing: 15) {
            HStack {
                Text(wormhole.name)
                    .font(.title2.bold())
                    .foregroundColor(wormhole.portalColor)
                
                Spacer()
                
                Button("×") {
                    selectedWormhole = nil
                }
                .font(.title2)
                .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    wormholeInfoRow(title: "类型", value: wormhole.type.rawValue, icon: wormhole.type.icon)
                    Spacer()
                    wormholeInfoRow(title: "时代", value: wormhole.era, icon: "calendar")
                }
                
                HStack {
                    wormholeInfoRow(title: "距离", value: String(format: "%.1f 光年", wormhole.distance), icon: "ruler")
                    Spacer()
                    wormholeInfoRow(title: "状态", value: wormhole.isActive ? "激活" : "休眠", icon: wormhole.isActive ? "circle.fill" : "circle")
                }
                
                // 稳定度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.gray)
                        Text("稳定度")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(wormhole.stability * 100))%")
                            .foregroundColor(wormhole.stabilityColor)
                            .font(.caption.bold())
                    }
                    
                    ProgressView(value: wormhole.stability)
                        .progressViewStyle(LinearProgressViewStyle(tint: wormhole.stabilityColor))
                        .scaleEffect(y: 0.5)
                }
                
                // 带宽条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.gray)
                        Text("传输带宽")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("\(Int(wormhole.bandwidth * 100))%")
                            .foregroundColor(.cyan)
                            .font(.caption.bold())
                    }
                    
                    ProgressView(value: wormhole.bandwidth)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .scaleEffect(y: 0.5)
                }
            }
            
            // 门户颜色预览
            HStack {
                Text("门户光谱:")
                    .foregroundColor(.gray)
                
                Circle()
                    .fill(wormhole.portalColor)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Spacer()
                
                if wormhole.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1 + sin(currentTime.timeIntervalSince1970 * 3) * 0.3)
                        Text("活跃")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(wormhole.portalColor.opacity(0.5), lineWidth: 2)
        )
        .padding()
        .transition(.scale.combined(with: .opacity))
    }
    
    private func wormholeInfoRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    // 计算虫洞布局：更分散且避免重叠（UI设计导向）
    private func computeWormholeLayout(geometry: GeometryProxy) -> [UUID: CGPoint] {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let minSide = min(geometry.size.width, geometry.size.height)
        let baseScale = minSide * 0.58  // 更广泛分布（原0.42）
        let margin: CGFloat = 12        // 更小的边缘安全区，让布局可以靠近边界
        
        // 按门户视觉尺寸从大到小放置，优先保证大门户不被遮挡
        let wormholes = astronomyService.getActiveWorkholesSortedByVisualSize()
        var placed: [UUID: CGPoint] = [:]
        
        for wormhole in wormholes {
            // 基础方向：根据赤经/赤纬投影的单位向量
            let dir = CGPoint(x: wormhole.x, y: wormhole.y)
            let dirLen = max(0.001, sqrt(dir.x * dir.x + dir.y * dir.y))
            let unit = CGPoint(x: dir.x / dirLen, y: dir.y / dirLen)
            
            // 距离影响半径：远的更靠外（更激进）
            let d = CGFloat(min(max(wormhole.distance, 0), 10000))
            let distanceFactor = 0.8 + (d / 10000.0) * 1.1  // 0.8 - 1.9（原 0.75 - 1.4）
            
            // 角度偏移：增加扰动幅度，避免同向聚簇
            let goldenAngle: CGFloat = 137.5 * .pi / 180
            let seed = CGFloat((wormhole.rightAscension.truncatingRemainder(dividingBy: 360)))
            let angleJitter = sin(seed) * goldenAngle * 0.2  // 原0.12
            let cosJ = cos(angleJitter)
            let sinJ = sin(angleJitter)
            let rotated = CGPoint(
                x: unit.x * cosJ - unit.y * sinJ,
                y: unit.x * sinJ + unit.y * cosJ
            )
            
            // 期望位置：在径向上再增加一个轻微的“外推”随机（可重复）
            let radialJitter = (sin(seed * 0.7) + cos(seed * 1.3)) * 0.06 + 1.0
            var pos = CGPoint(
                x: center.x + rotated.x * baseScale * distanceFactor * radialJitter,
                y: center.y + rotated.y * baseScale * distanceFactor * radialJitter
            )
            
            // 非重叠调整
            let portalRadius = calculateWormholeSize(wormhole: wormhole) / 2
            let step: CGFloat = 7
            var attempts = 0
            
            func isOverlapping(_ p: CGPoint) -> Bool {
                for (id, otherPos) in placed {
                    if let other = astronomyService.getWormhole(by: id) {
                        let otherR = calculateWormholeSize(wormhole: other) / 2
                        let minDist = portalRadius + otherR + 10
                        let dx = p.x - otherPos.x
                        let dy = p.y - otherPos.y
                        if (dx * dx + dy * dy) < (minDist * minDist) {
                            return true
                        }
                    }
                }
                return false
            }
            
            while isOverlapping(pos) && attempts < 90 {
                // 向外沿径向移动，直到不重叠
                let vec = CGPoint(x: pos.x - center.x, y: pos.y - center.y)
                let vLen = max(0.001, sqrt(vec.x * vec.x + vec.y * vec.y))
                let out = CGPoint(x: vec.x / vLen, y: vec.y / vLen)
                let next = CGPoint(x: pos.x + out.x * step, y: pos.y + out.y * step)
                
                // 边界保护：如果触边则小幅顺时针绕中心旋转
                if next.x < margin || next.y < margin || next.x > geometry.size.width - margin || next.y > geometry.size.height - margin {
                    let rot: CGFloat = .pi / 28
                    let cosR = cos(rot)
                    let sinR = sin(rot)
                    let vx = vec.x * cosR - vec.y * sinR
                    let vy = vec.x * sinR + vec.y * cosR
                    pos = CGPoint(x: center.x + vx, y: center.y + vy)
                } else {
                    pos = next
                }
                attempts += 1
            }
            
            // 最终位置存储
            placed[wormhole.id] = pos
        }
        
        return placed
    }
}

// MARK: - 位置管理器
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            // 使用默认位置（北京）
            location = CLLocation(latitude: 39.9042, longitude: 116.4074)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置获取失败: \(error)")
        // 使用默认位置
        location = CLLocation(latitude: 39.9042, longitude: 116.4074)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

#Preview {
    RealStarMapView()
} 