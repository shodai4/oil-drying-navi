import Foundation

// このファイルは tools/generate_catalog_swift.py が tools/catalog.json から生成する。手で編集しない。
// 出典: ホルベイン画材 油絵具カタログ HA-2611（2026年11月2日現在）
// 乾燥所要日数は 0.15mm 厚・25℃・湿度55% の室内での指触乾燥時間。

enum HolbeinCatalog {
    static let version = "2026年11月2日現在"

    struct Paint: Identifiable, Hashable {
        let id: String
        let name: String
        let family: String
        let series: String
        let permanency: Int
        let admix: String
        let dryingClass: String
        let dryingDays: Int
        let opacity: String
        let toxicity: String
        let pigments: [String]
        let refs10: [String]
        let refs20: [String]
        let refs40: [String]
        let traditional: String

        /// 標準条件（下地・画用液・厚み・部屋がすべて標準）での公式日数が、そのまま出る係数。
        var dryingFactor: Double { Double(dryingDays) / 3.0 }

        var isAntique: Bool { family == "アンティーク" }

        /// 硫化物を含むため、シルバーホワイトとの混色を避ける色。
        var needsSulfideCaution: Bool { admix == "N" }

        var permanencyText: String { String(repeating: "＊", count: permanency) }

        var dryingText: String { "\(dryingClass)（\(dryingDays)日前後）" }
    }

    static let families = ["赤", "橙", "黄", "緑", "青", "紫", "茶・黒", "灰", "金・銀", "アンティーク"]

    /// 2026年11月2日現在の税込価格（単色）。
    private static let prices: [String: [String: Int]] = [
        "10ml": ["A": 330, "B": 374],
        "20ml": ["A": 550, "B": 605, "C": 770, "D": 1430, "E": 2310, "H": 2530, "I": 5060, "L": 3300],
        "40ml": ["A": 990, "B": 1100, "C": 1430, "D": 2530, "E": 4070, "H": 4620, "I": 8580],
        "110ml": ["A": 2310, "B": 2530, "C": 3300, "D": 5720, "E": 9350, "H": 10780]
    ]

    static func price(size: String, series: String) -> Int? {
        prices[size]?[series]
    }

    static func yenText(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ja_JP")
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return text + "円"
    }

    /// 色名・品番・使用顔料記号のどれでも引ける。
    static func search(_ query: String) -> [Paint] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        let needle = trimmed.replacingOccurrences(of: " ", with: "").uppercased()
        return all.filter { paint in
            if paint.name.replacingOccurrences(of: " ", with: "").uppercased().contains(needle) {
                return true
            }
            if paint.traditional.contains(trimmed) {
                return true
            }
            let refs = paint.refs10 + paint.refs20 + paint.refs40
            if refs.contains(where: { $0.uppercased().contains(needle) }) {
                return true
            }
            return paint.pigments.contains(where: { $0.uppercased().contains(needle) })
        }
    }

    static func of(family: String) -> [Paint] {
        all.filter { $0.family == family }
    }

    static let all: [Paint] = [
        Paint(id: "H001", name: "クリムソン レーキ", family: "赤", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR177", "PR254"], refs10: ["HH001"], refs20: ["H001"], refs40: ["H201", "HH201"], traditional: ""),
        Paint(id: "H002", name: "カーマイン", family: "赤", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR177", "PR254"], refs10: [], refs20: ["H002"], refs40: ["H202", "HH202"], traditional: ""),
        Paint(id: "H004", name: "ローズ マダー", family: "赤", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR177", "PR254"], refs10: [], refs20: ["H004"], refs40: ["H204", "HH204"], traditional: ""),
        Paint(id: "H028", name: "ピロール レッド", family: "赤", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PR254"], refs10: [], refs20: ["H028"], refs40: ["H228", "HH228"], traditional: ""),
        Paint(id: "H029", name: "ピロール レッド トランスペアレント", family: "赤", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR254"], refs10: [], refs20: ["H029"], refs40: ["H229"], traditional: ""),
        Paint(id: "H007", name: "カドミウム レッド", family: "赤", series: "H", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PR108"], refs10: [], refs20: ["H007"], refs40: ["H207", "HH207"], traditional: ""),
        Paint(id: "H009", name: "カドミウム レッド ディープ", family: "赤", series: "H", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PR108"], refs10: [], refs20: ["H009"], refs40: ["H209"], traditional: ""),
        Paint(id: "H011", name: "カドミウム レッド パープル", family: "赤", series: "H", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PR108"], refs10: [], refs20: ["H011"], refs40: ["H211"], traditional: ""),
        Paint(id: "H015", name: "バーミリオン", family: "赤", series: "I", permanency: 1, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "不透明", toxicity: "", pigments: ["PR106"], refs10: [], refs20: ["H015"], refs40: ["H215"], traditional: ""),
        Paint(id: "H018", name: "バーミリオン ヒュー", family: "赤", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY139", "PO73", "PR254"], refs10: ["HH018"], refs20: ["H018"], refs40: ["H218", "HH218"], traditional: ""),
        Paint(id: "H022", name: "ブライト レッド", family: "赤", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PR254"], refs10: ["HH022"], refs20: ["H022"], refs40: ["H222", "HH222"], traditional: ""),
        Paint(id: "H020", name: "キナクリドン レッド", family: "赤", series: "D", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PV19"], refs10: [], refs20: ["H020"], refs40: ["H220", "HH220"], traditional: ""),
        Paint(id: "H127", name: "キナクリドン オペラ", family: "赤", series: "C", permanency: 1, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["BV10", "PR122"], refs10: [], refs20: ["H127"], refs40: ["H327"], traditional: ""),
        Paint(id: "H021", name: "ブリリアント ピンク", family: "赤", series: "B", permanency: 1, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PR188", "PW6"], refs10: [], refs20: ["H021"], refs40: ["H221", "HH221"], traditional: ""),
        Paint(id: "H026", name: "シェル ピンク", family: "赤", series: "B", permanency: 1, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PR188", "PW6"], refs10: [], refs20: ["H026"], refs40: ["H226", "HH226"], traditional: ""),
        Paint(id: "H057", name: "カドミウム オレンジ", family: "橙", series: "E", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PO20"], refs10: [], refs20: ["H057"], refs40: ["H257", "HH257"], traditional: ""),
        Paint(id: "H046", name: "パーマネント オレンジ", family: "橙", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY139", "PR254"], refs10: ["HH046"], refs20: ["H046"], refs40: ["H246", "HH246"], traditional: ""),
        Paint(id: "H062", name: "ピロール オレンジ", family: "橙", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PO73"], refs10: [], refs20: ["H062"], refs40: ["H262", "HH262"], traditional: ""),
        Paint(id: "H030", name: "ネイプルス イエロー", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PY35", "PY42", "PW6"], refs10: [], refs20: ["H030"], refs40: ["H230", "HH230"], traditional: ""),
        Paint(id: "H061", name: "アイボリ ホワイト", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PY42", "PY53", "PW6"], refs10: [], refs20: ["H061"], refs40: ["H261", "HH261"], traditional: ""),
        Paint(id: "H034", name: "ジョーン ブリヤン No.2", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PO20", "PW6"], refs10: [], refs20: ["H034"], refs40: ["H234", "HH234"], traditional: ""),
        Paint(id: "H035", name: "ジョーン ブリヤン No.3", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PO20", "PW6"], refs10: ["HH035"], refs20: ["H035"], refs40: ["H235", "HH235"], traditional: ""),
        Paint(id: "H037", name: "レモン イエロー", family: "黄", series: "B", permanency: 2, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PY184", "PW6"], refs10: ["HH037"], refs20: ["H037"], refs40: ["H237", "HH237"], traditional: ""),
        Paint(id: "H040", name: "イエロー オーカー", family: "黄", series: "A", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "不透明", toxicity: "", pigments: ["PY42"], refs10: ["HH040"], refs20: ["H040"], refs40: ["H240", "HH240"], traditional: ""),
        Paint(id: "H066", name: "ポリアゾ イエロー", family: "黄", series: "C", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PY128"], refs10: [], refs20: ["H066"], refs40: ["H266"], traditional: ""),
        Paint(id: "H067", name: "イミダゾロン イエロー", family: "黄", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PY154"], refs10: [], refs20: ["H067"], refs40: ["H267", "HH267"], traditional: ""),
        Paint(id: "H043", name: "パーマネント イエロー レモン", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY138", "PY184"], refs10: [], refs20: ["H043"], refs40: ["H243", "HH243"], traditional: ""),
        Paint(id: "H044", name: "パーマネント イエロー ライト", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY151", "PY139"], refs10: ["HH044"], refs20: ["H044"], refs40: ["H244", "HH244"], traditional: ""),
        Paint(id: "H058", name: "パーマネント イエロー", family: "黄", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY151", "PY139"], refs10: ["HH058"], refs20: ["H058"], refs40: ["H258", "HH258"], traditional: ""),
        Paint(id: "H048", name: "オーレオリン", family: "黄", series: "E", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半透明", toxicity: "Co", pigments: ["PY40"], refs10: [], refs20: ["H048"], refs40: ["H248"], traditional: ""),
        Paint(id: "H049", name: "カドミウム イエロー レモン", family: "黄", series: "E", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PY35"], refs10: [], refs20: ["H049"], refs40: ["H249"], traditional: ""),
        Paint(id: "H052", name: "カドミウム イエロー", family: "黄", series: "E", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PO20", "PY35"], refs10: [], refs20: ["H052"], refs40: ["H252", "HH252"], traditional: ""),
        Paint(id: "H068", name: "ニッケル アゾ イエロー", family: "黄", series: "C", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PY150"], refs10: [], refs20: ["H068"], refs40: ["H268"], traditional: ""),
        Paint(id: "H069", name: "イソインドリノン イエロー", family: "黄", series: "C", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PY110"], refs10: [], refs20: ["H069"], refs40: ["H269"], traditional: ""),
        Paint(id: "H047", name: "グリニッシュ イエロー", family: "黄", series: "C", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PY17", "PG7", "PR83"], refs10: [], refs20: ["H047"], refs40: ["H247", "HH247"], traditional: ""),
        Paint(id: "H070", name: "ビリジャン", family: "緑", series: "H", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PG18"], refs10: [], refs20: ["H070"], refs40: ["H270", "HH270"], traditional: ""),
        Paint(id: "H071", name: "ビリジャン ヒュー", family: "緑", series: "A", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["PG7"], refs10: ["HH071"], refs20: ["H071"], refs40: ["H271", "HH271"], traditional: ""),
        Paint(id: "H094", name: "フタロ グリーン", family: "緑", series: "B", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "透明", toxicity: "", pigments: ["PG7"], refs10: [], refs20: ["H094"], refs40: ["H294", "HH294"], traditional: ""),
        Paint(id: "H074", name: "エメラルド グリーン ノーバ", family: "緑", series: "B", permanency: 2, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PY184", "PG7", "PW6"], refs10: ["HH074"], refs20: ["H074"], refs40: ["H274", "HH274"], traditional: ""),
        Paint(id: "H075", name: "テール ベルト", family: "緑", series: "A", permanency: 4, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PG23"], refs10: ["HH075"], refs20: ["H075"], refs40: ["H275", "HH275"], traditional: ""),
        Paint(id: "H076", name: "サップ グリーン", family: "緑", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PY150", "PG7", "PR177"], refs10: [], refs20: ["H076"], refs40: ["H276", "HH276"], traditional: ""),
        Paint(id: "H077", name: "パーマネント グリーン ライト", family: "緑", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY151", "PG7"], refs10: [], refs20: ["H077"], refs40: ["H277", "HH277"], traditional: ""),
        Paint(id: "H078", name: "パーマネント グリーン ペール", family: "緑", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY151", "PG7"], refs10: ["HH078"], refs20: ["H078"], refs40: ["H278", "HH278"], traditional: ""),
        Paint(id: "H079", name: "パーマネント グリーン", family: "緑", series: "A", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PY151", "PY110", "PB15"], refs10: [], refs20: ["H079"], refs40: ["H279", "HH279"], traditional: ""),
        Paint(id: "H080", name: "パーマネント グリーン ディープ", family: "緑", series: "A", permanency: 2, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PY151", "PY110", "PB15"], refs10: ["HH080"], refs20: ["H080"], refs40: ["H280", "HH280"], traditional: ""),
        Paint(id: "H096", name: "カドミウム グリーン ライト", family: "緑", series: "D", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY35", "PG18"], refs10: [], refs20: ["H096"], refs40: ["H296"], traditional: ""),
        Paint(id: "H082", name: "カドミウム グリーン", family: "緑", series: "E", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "不透明", toxicity: "", pigments: ["PY35", "PG18"], refs10: [], refs20: ["H082"], refs40: ["H282", "HH282"], traditional: ""),
        Paint(id: "H100", name: "ペリレン グリーン", family: "緑", series: "D", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PBk31"], refs10: [], refs20: ["H100"], refs40: ["H300"], traditional: ""),
        Paint(id: "H088", name: "オキサイド オブ クロミウム", family: "緑", series: "B", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "不透明", toxicity: "", pigments: ["PG17"], refs10: [], refs20: ["H088"], refs40: ["H288", "HH288"], traditional: ""),
        Paint(id: "H092", name: "シナバー グリーン", family: "緑", series: "B", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PY154", "PY42", "PY53", "PB15"], refs10: [], refs20: ["H092"], refs40: ["H292", "HH292"], traditional: ""),
        Paint(id: "H091", name: "シナバー グリーン ライト", family: "緑", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PY154", "PY119", "PG7", "PW6"], refs10: [], refs20: ["H091"], refs40: ["H291", "HH291"], traditional: ""),
        Paint(id: "H084", name: "コンポーズ グリーン", family: "緑", series: "C", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PY35", "PG18", "PW6"], refs10: [], refs20: ["H084"], refs40: ["H284"], traditional: ""),
        Paint(id: "H101", name: "コバルト ブルー", family: "青", series: "H", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PB28"], refs10: [], refs20: ["H101"], refs40: ["H301", "HH301"], traditional: ""),
        Paint(id: "H104", name: "コバルト ブルー ヒュー", family: "青", series: "A", permanency: 3, admix: "N", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PB15", "PB29", "PW6"], refs10: ["HH104"], refs20: ["H104"], refs40: ["H304", "HH304"], traditional: ""),
        Paint(id: "H105", name: "セルリアン ブルー", family: "青", series: "H", permanency: 4, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PB35"], refs10: [], refs20: ["H105"], refs40: ["H305", "HH305"], traditional: ""),
        Paint(id: "H106", name: "セルリアン ブルー ヒュー", family: "青", series: "A", permanency: 2, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PB15", "PW6"], refs10: ["HH106"], refs20: ["H106"], refs40: ["H306", "HH306"], traditional: ""),
        Paint(id: "H107", name: "ウルトラマリン ライト", family: "青", series: "A", permanency: 3, admix: "N", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半透明", toxicity: "", pigments: ["PB29"], refs10: [], refs20: ["H107"], refs40: ["H307", "HH307"], traditional: ""),
        Paint(id: "H122", name: "ウルトラマリン ブルー", family: "青", series: "A", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PB29"], refs10: ["HH122"], refs20: ["H122"], refs40: ["H322", "HH322"], traditional: ""),
        Paint(id: "H108", name: "ウルトラマリン ディープ", family: "青", series: "A", permanency: 3, admix: "N", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半透明", toxicity: "", pigments: ["PB29"], refs10: [], refs20: ["H108"], refs40: ["H308", "HH308"], traditional: ""),
        Paint(id: "H123", name: "マンガニーズ ブルー ノーバ", family: "青", series: "B", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半透明", toxicity: "", pigments: ["PB28", "PB15"], refs10: [], refs20: ["H123"], refs40: ["H323", "HH323"], traditional: ""),
        Paint(id: "H110", name: "バヂター ブルー", family: "青", series: "D", permanency: 4, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PB28", "PW6"], refs10: [], refs20: ["H110"], refs40: ["H310"], traditional: ""),
        Paint(id: "H111", name: "コンポーズ ブルー", family: "青", series: "A", permanency: 2, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PB15", "PW6"], refs10: [], refs20: ["H111"], refs40: ["H311", "HH311"], traditional: ""),
        Paint(id: "H112", name: "プルシャン ブルー", family: "青", series: "A", permanency: 2, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PB27"], refs10: ["HH112"], refs20: ["H112"], refs40: ["H312", "HH312"], traditional: ""),
        Paint(id: "H124", name: "フタロ ブルー", family: "青", series: "B", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PB15"], refs10: [], refs20: ["H124"], refs40: ["H324", "HH324"], traditional: ""),
        Paint(id: "H125", name: "インダンスレン ブルー", family: "青", series: "D", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PB60"], refs10: [], refs20: ["H125"], refs40: ["H325"], traditional: ""),
        Paint(id: "H114", name: "インジゴ", family: "青", series: "B", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半透明", toxicity: "", pigments: ["PB15", "PBk7", "PR122"], refs10: [], refs20: ["H114"], refs40: ["H314", "HH314"], traditional: ""),
        Paint(id: "H116", name: "コバルト ターコイズ", family: "青", series: "E", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PG50"], refs10: [], refs20: ["H116"], refs40: ["H316"], traditional: ""),
        Paint(id: "H115", name: "ターコイズ ブルー", family: "青", series: "B", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PB28", "PG7", "PW6"], refs10: [], refs20: ["H115"], refs40: ["H315", "HH315"], traditional: ""),
        Paint(id: "H117", name: "ホリゾン ブルー", family: "青", series: "A", permanency: 2, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "不透明", toxicity: "", pigments: ["PB15", "PW6"], refs10: [], refs20: ["H117"], refs40: ["H317", "HH317"], traditional: ""),
        Paint(id: "H118", name: "ミスティ ブルー", family: "青", series: "A", permanency: 2, admix: "N", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PB29", "PW6"], refs10: [], refs20: ["H118"], refs40: ["H318", "HH318"], traditional: ""),
        Paint(id: "H129", name: "コバルト バイオレット", family: "紫", series: "H", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "Co", pigments: ["PV47"], refs10: [], refs20: ["H129"], refs40: ["H329"], traditional: ""),
        Paint(id: "H132", name: "コバルト バイオレット ライト ヒュー", family: "紫", series: "B", permanency: 1, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PR122", "PB29", "PW6"], refs10: ["HH132"], refs20: ["H132"], refs40: ["H332", "HH332"], traditional: ""),
        Paint(id: "H135", name: "モーブ", family: "紫", series: "B", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "透明", toxicity: "", pigments: ["PB29", "PR122"], refs10: [], refs20: ["H135"], refs40: ["H335", "HH335"], traditional: ""),
        Paint(id: "H138", name: "ジオキサジン バイオレット", family: "紫", series: "C", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PV23"], refs10: [], refs20: ["H138"], refs40: ["H338", "HH338"], traditional: ""),
        Paint(id: "H137", name: "キナクリドン マゼンタ", family: "紫", series: "C", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR122"], refs10: [], refs20: ["H137"], refs40: ["H337", "HH337"], traditional: ""),
        Paint(id: "H136", name: "ローズ バイオレット", family: "紫", series: "B", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半透明", toxicity: "", pigments: ["PR122", "PW6"], refs10: [], refs20: ["H136"], refs40: ["H336"], traditional: ""),
        Paint(id: "H139", name: "ライト マゼンタ", family: "紫", series: "B", permanency: 2, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PV19", "PW6"], refs10: [], refs20: ["H139"], refs40: ["H339", "HH339"], traditional: ""),
        Paint(id: "H140", name: "ライト レッド", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "不透明", toxicity: "", pigments: ["PR101"], refs10: ["HH140"], refs20: ["H140"], refs40: ["H340", "HH340"], traditional: ""),
        Paint(id: "H142", name: "ロー アンバー", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PBr7"], refs10: [], refs20: ["H142"], refs40: ["H342", "HH342"], traditional: ""),
        Paint(id: "H143", name: "ロー シェンナ", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["PY42", "PBr7"], refs10: [], refs20: ["H143"], refs40: ["H343", "HH343"], traditional: ""),
        Paint(id: "H144", name: "バーント アンバー", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半不透明", toxicity: "", pigments: ["PBr7", "PR101"], refs10: ["HH144"], refs20: ["H144"], refs40: ["H344", "HH344"], traditional: ""),
        Paint(id: "H145", name: "バーント シェンナ", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PBr7"], refs10: ["HH145"], refs20: ["H145"], refs40: ["H345", "HH345"], traditional: ""),
        Paint(id: "H146", name: "インデアン レッド", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "不透明", toxicity: "", pigments: ["PR101"], refs10: [], refs20: ["H146"], refs40: ["H346"], traditional: ""),
        Paint(id: "H161", name: "トランスペアレント ブラウン オキサイド", family: "茶・黒", series: "B", permanency: 4, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "透明", toxicity: "", pigments: ["PR101"], refs10: [], refs20: ["H161"], refs40: ["H361"], traditional: ""),
        Paint(id: "H151", name: "セピア", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PBr25", "PBk7"], refs10: [], refs20: ["H151"], refs40: ["H351", "HH351"], traditional: ""),
        Paint(id: "H152", name: "バンダイキ ブラウン", family: "茶・黒", series: "A", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半透明", toxicity: "", pigments: ["PBr7", "PBr25", "PBk7"], refs10: [], refs20: ["H152"], refs40: ["H352", "HH352"], traditional: ""),
        Paint(id: "H157", name: "ブルー ブラック", family: "茶・黒", series: "A", permanency: 3, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PB29", "PBk7"], refs10: [], refs20: ["H157"], refs40: ["H357"], traditional: ""),
        Paint(id: "H153", name: "ピーチ ブラック", family: "茶・黒", series: "A", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PBk1"], refs10: [], refs20: ["H153"], refs40: ["H353", "HH353"], traditional: ""),
        Paint(id: "H154", name: "アイボリ ブラック", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "不透明", toxicity: "", pigments: ["PBk9", "PBk7"], refs10: ["HH154"], refs20: ["H154"], refs40: ["H354", "HH354"], traditional: ""),
        Paint(id: "H156", name: "ランプ ブラック", family: "茶・黒", series: "A", permanency: 4, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PBk6"], refs10: [], refs20: ["H156"], refs40: ["H356"], traditional: ""),
        Paint(id: "H170", name: "ブルー グレイ", family: "灰", series: "A", permanency: 2, admix: "N", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PB29", "PW6"], refs10: [], refs20: ["H170"], refs40: ["H370", "HH370"], traditional: ""),
        Paint(id: "H174", name: "バイオレット グレイ", family: "灰", series: "A", permanency: 2, admix: "N", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PV15", "PW6"], refs10: [], refs20: ["H174"], refs40: ["H374", "HH374"], traditional: ""),
        Paint(id: "H176", name: "ローズ グレイ", family: "灰", series: "A", permanency: 4, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "", pigments: ["PR101", "PW6"], refs10: [], refs20: ["H176"], refs40: ["H376", "HH376"], traditional: ""),
        Paint(id: "H178", name: "モノクローム チント ウォーム", family: "灰", series: "A", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PY119", "PW6"], refs10: [], refs20: ["H178"], refs40: ["H378", "HH378"], traditional: ""),
        Paint(id: "H179", name: "モノクローム チント クール", family: "灰", series: "A", permanency: 3, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PBk11", "PW6"], refs10: [], refs20: ["H179"], refs40: ["H379", "HH379"], traditional: ""),
        Paint(id: "H169", name: "ニュートラル グレイ", family: "灰", series: "A", permanency: 2, admix: "", dryingClass: "Ⅲ", dryingDays: 4, opacity: "半不透明", toxicity: "", pigments: ["PY42", "PBk9", "PW6"], refs10: [], refs20: ["H169"], refs40: ["H369", "HH369"], traditional: ""),
        Paint(id: "H173", name: "グレイ オブ グレイ", family: "灰", series: "A", permanency: 2, admix: "", dryingClass: "Ⅳ", dryingDays: 5, opacity: "半不透明", toxicity: "Co", pigments: ["PV47", "PBk1", "PW6"], refs10: [], refs20: ["H173"], refs40: ["H373", "HH373"], traditional: ""),
        Paint(id: "H180", name: "ペインズ グレイ", family: "灰", series: "A", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半不透明", toxicity: "", pigments: ["PB29", "PBk11"], refs10: [], refs20: ["H180"], refs40: ["H380"], traditional: ""),
        Paint(id: "H190", name: "ゴールド", family: "金・銀", series: "E", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "", toxicity: "", pigments: ["PW20", "PM1"], refs10: [], refs20: ["H190"], refs40: ["H390"], traditional: ""),
        Paint(id: "H191", name: "シルバー", family: "金・銀", series: "E", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "", toxicity: "", pigments: ["PM1"], refs10: [], refs20: ["H191"], refs40: ["H391"], traditional: ""),
        Paint(id: "H181", name: "アンティーク レッド", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H181"], refs40: [], traditional: "紅辰砂"),
        Paint(id: "H183", name: "アンティーク イエロー No.1", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H183"], refs40: [], traditional: "樺茶"),
        Paint(id: "H184", name: "アンティーク イエロー No.2", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H184"], refs40: [], traditional: "黄茶緑"),
        Paint(id: "H185", name: "アンティーク グリーン", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H185"], refs40: [], traditional: "裏葉緑青"),
        Paint(id: "H187", name: "アンティーク ブルー No.1", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H187"], refs40: [], traditional: "白群"),
        Paint(id: "H188", name: "アンティーク ブルー No.2", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅱ", dryingDays: 3, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H188"], refs40: [], traditional: "浅黄群青"),
        Paint(id: "H189", name: "アンティーク ブルー No.3", family: "アンティーク", series: "L", permanency: 3, admix: "", dryingClass: "Ⅰ", dryingDays: 2, opacity: "半透明", toxicity: "", pigments: ["岩絵具"], refs10: [], refs20: ["H189"], refs40: [], traditional: "藍群青"),
    ]
}
