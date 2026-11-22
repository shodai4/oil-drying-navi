import Foundation

// MARK: - 係数と計算

struct DryingOption: Identifiable {
    let label: String
    let factor: Double

    var id: String { label }
}

enum DryingQuestion: CaseIterable {
    case ground
    case medium
    case pigment
    case thickness
    case environment

    var title: String {
        switch self {
        case .ground:
            return "下地は？"
        case .medium:
            return "使った画用液は？"
        case .pigment:
            return "主な顔料は？"
        case .thickness:
            return "塗りの厚みは？"
        case .environment:
            return "部屋の状態は？"
        }
    }

    var caption: String {
        switch self {
        case .ground:
            return "下地の吸い込みで、乾く速さが変わる。"
        case .medium:
            return "描きながら足した油やメディウム。"
        case .pigment:
            return "画面の大部分を占める色で選ぶ。"
        case .thickness:
            return "厚いほど、表面が乾いても中が残る。"
        case .environment:
            return "気温と湿気、風通し。"
        }
    }

    var options: [DryingOption] {
        switch self {
        case .ground:
            return [
                DryingOption(label: "吸収性（膠・石膏）", factor: 0.7),
                DryingOption(label: "標準（麻・綿）", factor: 1.0),
                DryingOption(label: "非吸収（油性）", factor: 1.3)
            ]
        case .medium:
            return [
                DryingOption(label: "アルキド樹脂", factor: 0.4),
                DryingOption(label: "リンシード", factor: 1.0),
                DryingOption(label: "ポピー・スタンド", factor: 1.6),
                DryingOption(label: "揮発性のみ", factor: 0.3)
            ]
        case .pigment:
            return [
                DryingOption(label: "速乾（土・コバルト）", factor: 0.6),
                DryingOption(label: "標準", factor: 1.0),
                DryingOption(label: "遅乾（白・黒・紅）", factor: 2.0)
            ]
        case .thickness:
            return [
                DryingOption(label: "薄塗り", factor: 0.6),
                DryingOption(label: "標準", factor: 1.0),
                DryingOption(label: "厚塗り", factor: 2.5)
            ]
        case .environment:
            return [
                DryingOption(label: "寒い・湿気", factor: 1.4),
                DryingOption(label: "標準", factor: 1.0),
                DryingOption(label: "暖かい・乾燥", factor: 0.7)
            ]
        }
    }
}

enum DryingManufacturer: String, CaseIterable, Identifiable {
    case none
    case holbein
    case kusakabe
    case matsuda
    case winsorNewton
    case waterSoluble

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:
            return "指定なし"
        case .holbein:
            return "ホルベイン"
        case .kusakabe:
            return "クサカベ"
        case .matsuda:
            return "マツダ"
        case .winsorNewton:
            return "ウィンザー＆ニュートン"
        case .waterSoluble:
            return "水可溶性"
        }
    }

    var factor: Double {
        switch self {
        case .none:
            return 1.0
        case .holbein:
            return 1.1
        case .kusakabe:
            return 0.9
        case .matsuda:
            return 0.85
        case .winsorNewton:
            return 1.0
        case .waterSoluble:
            return 0.85
        }
    }
}

struct DryingResult {
    let conditions: [String]
    let baseProduct: Double
    let manufacturer: DryingManufacturer
    let hasCrackRisk: Bool
    /// 公式カタログから選んだ色。空なら質問の「主な顔料」だけで計算する。
    let catalogColors: [HolbeinCatalog.Paint]

    init(options: [DryingOption], manufacturer: DryingManufacturer = .none, catalogColors: [HolbeinCatalog.Paint] = []) {
        var labels = options.map { $0.label }
        var product = 1.0
        for (index, option) in options.enumerated() {
            // 3問目（主な顔料）は、公式カタログの色を選んだときだけ実測日数で置き換える。
            if index == 2, Self.slowest(in: catalogColors) != nil {
                continue
            }
            product *= option.factor
        }
        if let slowest = Self.slowest(in: catalogColors) {
            product *= slowest.dryingFactor
            if labels.indices.contains(2) {
                labels[2] = "\(slowest.name) \(slowest.dryingText)"
            }
        }

        let groundFactor = options.first?.factor ?? 1.0
        let mediumFactor = options.count > 1 ? options[1].factor : 1.0

        conditions = labels
        baseProduct = product
        self.manufacturer = manufacturer
        self.catalogColors = catalogColors
        hasCrackRisk = groundFactor < 1.0 && mediumFactor <= 0.3
    }

    private init(conditions: [String], baseProduct: Double, manufacturer: DryingManufacturer, hasCrackRisk: Bool, catalogColors: [HolbeinCatalog.Paint]) {
        self.conditions = conditions
        self.baseProduct = baseProduct
        self.manufacturer = manufacturer
        self.hasCrackRisk = hasCrackRisk
        self.catalogColors = catalogColors
    }

    func withManufacturer(_ manufacturer: DryingManufacturer) -> DryingResult {
        DryingResult(
            conditions: conditions,
            baseProduct: baseProduct,
            manufacturer: manufacturer,
            hasCrackRisk: hasCrackRisk,
            catalogColors: catalogColors
        )
    }

    /// 何色か選んだときは、いちばん乾きの遅い色が全体の目安になる。
    var slowestColor: HolbeinCatalog.Paint? {
        Self.slowest(in: catalogColors)
    }

    static func slowest(in colors: [HolbeinCatalog.Paint]) -> HolbeinCatalog.Paint? {
        guard var slowest = colors.first else { return nil }
        for color in colors where color.dryingDays > slowest.dryingDays {
            slowest = color
        }
        return slowest
    }

    /// 公式カタログの色を選んだときは、その色の実測値にメーカー係数を重ねない。
    var effectiveManufacturerFactor: Double {
        catalogColors.isEmpty ? manufacturer.factor : 1.0
    }

    var touchDays: Int {
        max(1, Int((3.0 * baseProduct * effectiveManufacturerFactor).rounded()))
    }

    var overpaintDays: Int {
        touchDays * 2
    }

    var varnishDays: Int {
        min(180, max(30, touchDays * 60))
    }

    var varnishText: String {
        let months = (Double(varnishDays) / 30.0 * 2).rounded() / 2
        let monthText = months == months.rounded()
            ? "\(Int(months))か月"
            : "\(Int(months))か月半"
        return "約\(monthText)（\(varnishDays)日後）"
    }

    var conditionSummary: String {
        conditions.joined(separator: " ・ ")
    }
}
