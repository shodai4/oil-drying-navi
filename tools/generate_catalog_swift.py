#!/usr/bin/env python3
"""tools/catalog.json から Sources/HolbeinCatalog.swift を生成する。

使い方: python3 tools/generate_catalog_swift.py
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "tools" / "catalog.json"
TARGET = ROOT / "Sources" / "HolbeinCatalog.swift"

HEADER = '''import Foundation

// このファイルは tools/generate_catalog_swift.py が tools/catalog.json から生成する。手で編集しない。
// 出典: ホルベイン画材 油絵具カタログ HA-2611（{version}）
// 乾燥所要日数は 0.15mm 厚・25℃・湿度55% の室内での指触乾燥時間。

enum HolbeinCatalog {{
    static let version = "{version}"

    struct Paint: Identifiable, Hashable {{
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
        var dryingFactor: Double {{ Double(dryingDays) / 3.0 }}

        var isAntique: Bool {{ family == "アンティーク" }}

        /// 硫化物を含むため、シルバーホワイトとの混色を避ける色。
        var needsSulfideCaution: Bool {{ admix == "N" }}

        var permanencyText: String {{ String(repeating: "＊", count: permanency) }}

        var dryingText: String {{ "\\(dryingClass)（\\(dryingDays)日前後）" }}
    }}

    static let families = ["赤", "橙", "黄", "緑", "青", "紫", "茶・黒", "灰", "金・銀", "アンティーク"]

    /// 2026年11月2日現在の税込価格（単色）。
    private static let prices: [String: [String: Int]] = [
{prices}
    ]

    static func price(size: String, series: String) -> Int? {{
        prices[size]?[series]
    }}

    static func yenText(_ value: Int) -> String {{
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ja_JP")
        let text = formatter.string(from: NSNumber(value: value)) ?? "\\(value)"
        return text + "円"
    }}

    /// 色名・品番・使用顔料記号のどれでも引ける。
    static func search(_ query: String) -> [Paint] {{
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {{ return all }}
        let needle = trimmed.replacingOccurrences(of: " ", with: "").uppercased()
        return all.filter {{ paint in
            if paint.name.replacingOccurrences(of: " ", with: "").uppercased().contains(needle) {{
                return true
            }}
            if paint.traditional.contains(trimmed) {{
                return true
            }}
            let refs = paint.refs10 + paint.refs20 + paint.refs40
            if refs.contains(where: {{ $0.uppercased().contains(needle) }}) {{
                return true
            }}
            return paint.pigments.contains(where: {{ $0.uppercased().contains(needle) }})
        }}
    }}

    static func of(family: String) -> [Paint] {{
        all.filter {{ $0.family == family }}
    }}

    static let all: [Paint] = [
'''

FOOTER = '''    ]
}
'''


def swift_string(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def swift_list(items):
    return "[" + ", ".join(swift_string(i) for i in items) + "]"


def main():
    data = json.loads(SOURCE.read_text(encoding="utf-8"))
    colors = data["colors"]
    prices = data["prices"]

    price_lines = []
    for size in ("10ml", "20ml", "40ml", "110ml"):
        entries = prices.get(size, {})
        pairs = ", ".join(f'"{k}": {v}' for k, v in sorted(entries.items()))
        price_lines.append(f'        "{size}": [{pairs}],')
    prices_block = "\n".join(price_lines).rstrip(",")

    rows = []
    for c in colors:
        ref20 = c["refs20"][0] if c["refs20"] else c["ja"]
        rows.append(
            "        Paint("
            f'id: {swift_string(ref20)}, '
            f'name: {swift_string(c["ja"])}, '
            f'family: {swift_string(c["family"])}, '
            f'series: {swift_string(c["series"])}, '
            f'permanency: {c["permanency"]}, '
            f'admix: {swift_string(c["admix"])}, '
            f'dryingClass: {swift_string(c["dryingClass"])}, '
            f'dryingDays: {c["dryingDays"]}, '
            f'opacity: {swift_string(c["opacity"])}, '
            f'toxicity: {swift_string(c["toxicity"])}, '
            f'pigments: {swift_list(c["pigments"])}, '
            f'refs10: {swift_list(c["refs10"])}, '
            f'refs20: {swift_list(c["refs20"])}, '
            f'refs40: {swift_list(c["refs40_110"])}, '
            f'traditional: {swift_string(c["traditional"])}'
            "),"
        )

    text = HEADER.format(version=data["version"], prices=prices_block) + "\n".join(rows) + "\n" + FOOTER
    TARGET.write_text(text, encoding="utf-8")
    print(f"{TARGET} に {len(colors)} 色を書き出しました")


if __name__ == "__main__":
    main()
