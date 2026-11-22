import Foundation

// 公式カタログ全色データと乾燥計算の自己テスト。
// CI（scripts/ci-testflight.sh）がアーカイブ前に swiftc でコンパイルして実行する。

var failures: [String] = []

func check(_ condition: Bool, _ message: String) {
    if !condition {
        failures.append(message)
    }
}

let allowedOpacity: Set<String> = ["透明", "半透明", "半不透明", "不透明"]
let allowedSeries: Set<String> = ["A", "B", "C", "D", "E", "H", "I", "L"]
let dryingDaysByClass: [String: Int] = ["Ⅰ": 2, "Ⅱ": 3, "Ⅲ": 4, "Ⅳ": 5]

let colors = HolbeinCatalog.all

check(colors.count == 107, "色数が107ではない: \(colors.count)")
check(Set(colors.map(\.id)).count == colors.count, "品番が重複している")
check(Set(colors.map(\.name)).count == colors.count, "色名が重複している")

for color in colors {
    check(dryingDaysByClass[color.dryingClass] == color.dryingDays, "乾燥区分と日数が食い違う: \(color.name)")
    check(allowedOpacity.contains(color.opacity) || color.opacity.isEmpty, "透明性が不正: \(color.name) \(color.opacity)")
    if color.opacity.isEmpty {
        check(color.name == "ゴールド" || color.name == "シルバー", "透明性が空の色: \(color.name)")
    }
    check(allowedSeries.contains(color.series), "シリーズ記号が不正: \(color.name) \(color.series)")
    check((1...4).contains(color.permanency), "耐光性の段階が不正: \(color.name)")
    check(!color.pigments.isEmpty, "使用顔料が空: \(color.name)")
    check(!color.refs20.isEmpty, "20ml の品番が空: \(color.name)")
    check(color.refs20.allSatisfy { $0.hasPrefix("H") }, "20ml の品番の形が違う: \(color.name)")
    check(HolbeinCatalog.price(size: "20ml", series: color.series) != nil, "20ml の価格がない: \(color.name)")
    check(color.traditional.isEmpty || color.isAntique, "岩絵具名が通常色についている: \(color.name)")
    check(!color.isAntique || !color.traditional.isEmpty, "アンティークカラーに岩絵具名がない: \(color.name)")
}

// 特徴的な色の中身が公式カタログと一致するか
func paint(_ name: String) -> HolbeinCatalog.Paint? {
    colors.first { $0.name == name }
}

if let red = paint("カドミウム レッド") {
    check(red.dryingClass == "Ⅳ" && red.dryingDays == 5, "カドミウム レッドの乾燥区分")
    check(red.opacity == "不透明", "カドミウム レッドの透明性")
    check(red.series == "H", "カドミウム レッドのシリーズ")
    check(red.pigments == ["PR108"], "カドミウム レッドの使用顔料")
} else {
    failures.append("カドミウム レッドがない")
}

if let vermilion = paint("バーミリオン") {
    check(vermilion.dryingDays == 4, "バーミリオンの乾燥日数")
    check(vermilion.series == "I", "バーミリオンのシリーズ")
    check(vermilion.pigments == ["PR106"], "バーミリオンの使用顔料")
}

if let crimson = paint("クリムソン レーキ") {
    check(crimson.pigments == ["PR177", "PR254"], "クリムソン レーキの使用顔料")
    check(crimson.refs10 == ["HH001"], "クリムソン レーキの10ml品番")
}

if let blue = paint("コバルト ブルー ヒュー") {
    check(blue.dryingDays == 5, "コバルト ブルー ヒューの乾燥日数")
    check(blue.needsSulfideCaution, "コバルト ブルー ヒューの混色記号N")
    check(blue.opacity == "半不透明", "コバルト ブルー ヒューの透明性")
}

if let misty = paint("ミスティ ブルー") {
    check(misty.needsSulfideCaution, "ミスティ ブルーの混色記号N")
    check(misty.pigments == ["PB29", "PW6"], "ミスティ ブルーの使用顔料")
}

let sulfideColors = colors.filter(\.needsSulfideCaution)
check(sulfideColors.count == 6, "混色記号Nの色数が6ではない: \(sulfideColors.count)")

check(colors.filter { $0.toxicity == "Co" }.count == 3, "コバルト注意（Co）の色数が3ではない")
check(colors.filter(\.isAntique).count == 7, "アンティークカラーの色数が7ではない")

// 価格（2026年11月2日現在・税込）
check(HolbeinCatalog.price(size: "20ml", series: "A") == 550, "20ml Aの価格")
check(HolbeinCatalog.price(size: "20ml", series: "B") == 605, "20ml Bの価格")
check(HolbeinCatalog.price(size: "20ml", series: "H") == 2530, "20ml Hの価格")
check(HolbeinCatalog.price(size: "20ml", series: "L") == 3300, "20ml Lの価格")
check(HolbeinCatalog.price(size: "110ml", series: "H") == 10780, "110ml Hの価格")

// 検索
check(HolbeinCatalog.search("ピロール").contains { $0.name == "ピロール レッド" }, "色名で引けない")
check(HolbeinCatalog.search("H007").contains { $0.name == "カドミウム レッド" }, "品番で引けない")
check(!HolbeinCatalog.search("PR108").isEmpty, "顔料記号で引けない")
check(HolbeinCatalog.search("存在しない色").isEmpty, "見つからない検索の結果が空でない")
check(HolbeinCatalog.search("カドミウム").count >= 8, "カドミウム系の検索結果が少ない")

// 標準条件なら公式の日数がそのまま出る
let standard = DryingQuestion.allCases.map { $0.options[1] }
let plain = DryingResult(options: standard)
check(plain.touchDays == 3, "標準条件の目安が3日ではない: \(plain.touchDays)")

if let cadmium = paint("カドミウム レッド"), let phthalo = paint("フタロ ブルー"), let crimson = paint("クリムソン レーキ") {
    // フタロ ブルーは公式Ⅰ（2日前後）、カドミウム レッドは公式Ⅳ（5日前後）
    let holbein = DryingResult(options: standard, catalogColors: [cadmium])
    check(holbein.touchDays == 5, "公式IVの色が5日にならない: \(holbein.touchDays)")
    check(holbein.conditions[2].contains("カドミウム レッド"), "条件の表示に色名がない")

    let fast = DryingResult(options: standard, catalogColors: [crimson])
    check(fast.touchDays == 2, "公式Iの色が2日にならない: \(fast.touchDays)")
    check(fast.catalogColors.count == 1, "選んだ色が残っていない")

    // 複数色は遅い色に合わせる
    let mixed = DryingResult(options: standard, catalogColors: [crimson, cadmium])
    check(mixed.touchDays == 5, "複数色で遅い色に合わない: \(mixed.touchDays)")
    check(mixed.slowestColor?.name == "カドミウム レッド", "遅い色の判定")

    // 公式値を使うときはメーカー係数を重ねない
    let adjusted = DryingResult(options: standard, catalogColors: [cadmium]).withManufacturer(.holbein)
    check(adjusted.touchDays == 5, "公式値にメーカー係数が重なっている: \(adjusted.touchDays)")

    // 厚塗りは公式値の2.5倍
    var thickOptions = standard
    thickOptions[3] = DryingQuestion.thickness.options[2]
    let thick = DryingResult(options: thickOptions, catalogColors: [phthalo])
    check(thick.touchDays == 5, "公式Iの色を厚塗りにした計算: \(thick.touchDays)")

    let thickSlow = DryingResult(options: thickOptions, catalogColors: [cadmium])
    check(thickSlow.touchDays == 13, "公式IVの色を厚塗りにした計算: \(thickSlow.touchDays)")

    // メーカー係数はカタログ色を選ばないときだけ効く
    let kusakabe = DryingResult(options: standard).withManufacturer(.kusakabe)
    check(kusakabe.touchDays == 3, "メーカー係数の計算: \(kusakabe.touchDays)")
}

if failures.isEmpty {
    print("カタログ自己テスト PASS（\(colors.count)色）")
} else {
    for failure in failures {
        print("FAIL: \(failure)")
    }
    exit(1)
}
