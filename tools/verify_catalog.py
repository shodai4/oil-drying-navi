#!/usr/bin/env python3
"""公式カタログ全色データの整合性検証。

- tools/catalog.json（PDFから抽出した正本）と Sources/HolbeinCatalog.swift の全項目を突き合わせる
- 乾燥区分と日数、透明性、シリーズ、品番の形、価格表の整合性を確認する
- 画面に出す文言に絵文字が混ざっていないかを確認する

使い方: python3 tools/verify_catalog.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "tools" / "catalog.json"
SWIFT_PATH = ROOT / "Sources" / "HolbeinCatalog.swift"
SOURCES = ROOT / "Sources"

EMOJI = re.compile(
    "[\U0001F000-\U0001FAFF\U00002600-\U000027BF\U0001F1E6-\U0001F1FF\u2728\u2764]"
)

FIELDS = (
    "id",
    "name",
    "family",
    "series",
    "permanency",
    "admix",
    "dryingClass",
    "dryingDays",
    "opacity",
    "toxicity",
    "pigments",
    "refs10",
    "refs20",
    "refs40",
    "traditional",
)

DRYING_DAYS = {"Ⅰ": 2, "Ⅱ": 3, "Ⅲ": 4, "Ⅳ": 5}
OPACITIES = {"透明", "半透明", "半不透明", "不透明"}

errors = []


def fail(message):
    errors.append(message)


def parse_swift():
    text = SWIFT_PATH.read_text(encoding="utf-8")
    records = []
    for block in text.split("Paint(")[1:]:
        body = block.split("),")[0]
        record = {}
        for key, raw in re.findall(r'(\w+): ("(?:[^"\\]|\\.)*"|\[[^\]]*\]|\d+)', body):
            if raw.startswith('"'):
                record[key] = json.loads(raw)
            elif raw.startswith("["):
                record[key] = json.loads("[" + raw[1:-1].replace("\\", "\\\\").replace('\\"', '\\\\"') + "]") if False else [
                    json.loads(value) for value in re.findall(r'"(?:[^"\\]|\\.)*"', raw)
                ]
            else:
                record[key] = int(raw)
        if record:
            records.append(record)
    return text, records


def parse_swift_prices(text):
    prices = {}
    block = text.split("private static let prices")[1].split("static func price")[0]
    for size, pairs in re.findall(r'"(\d+ml)": \[([^\]]*)\]', block):
        prices[size] = {k: int(v) for k, v in re.findall(r'"([A-Z])": (\d+)', pairs)}
    return prices


def main():
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    colors = data["colors"]
    text, swift = parse_swift()

    if len(colors) != 107:
        fail(f"JSONの色数が107ではない: {len(colors)}")
    if len(swift) != len(colors):
        fail(f"Swiftの色数が合わない: Swift {len(swift)} / JSON {len(colors)}")

    ids = [c["refs20"][0] for c in colors]
    if len(set(ids)) != len(ids):
        fail("品番が重複している")
    if len(set(c["ja"] for c in colors)) != len(colors):
        fail("色名が重複している")

    for expected, actual in zip(colors, swift):
        for field in FIELDS:
            if field == "id":
                want = expected["refs20"][0] if expected["refs20"] else expected["ja"]
            elif field == "name":
                want = expected["ja"]
            elif field == "refs40":
                want = expected["refs40_110"]
            else:
                want = expected[field]
            if actual.get(field) != want:
                fail(f"{expected['ja']} の {field} が違う: JSON {want!r} / Swift {actual.get(field)!r}")

        if DRYING_DAYS.get(expected["dryingClass"]) != expected["dryingDays"]:
            fail(f"{expected['ja']} の乾燥区分と日数が食い違う")
        if expected["opacity"] and expected["opacity"] not in OPACITIES:
            fail(f"{expected['ja']} の透明性が不正: {expected['opacity']}")
        if not expected["opacity"] and expected["ja"] not in ("ゴールド", "シルバー"):
            fail(f"{expected['ja']} の透明性が空")
        if not expected["pigments"]:
            fail(f"{expected['ja']} の使用顔料が空")
        if not expected["refs20"]:
            fail(f"{expected['ja']} の20ml品番が空")
        if expected["series"] not in "ABCDEFGHIL":
            fail(f"{expected['ja']} のシリーズ記号が不正: {expected['series']}")
        if not expected["admix"] == "" and expected["admix"] not in ("N", "S"):
            fail(f"{expected['ja']} の混色記号が不正")

    # 価格表（2026年11月2日現在・税込）とSwiftの一致
    swift_prices = parse_swift_prices(text)
    if swift_prices != data["prices"]:
        fail(f"価格表が違う: Swift {swift_prices} / JSON {data['prices']}")

    for color in colors:
        if color["series"] not in data["prices"]["20ml"]:
            fail(f"{color['ja']} の20ml価格がない（シリーズ{color['series']}）")

    # 分類の内訳（公式カタログの構成）
    summary = {
        "赤": 15, "橙": 3, "黄": 17, "緑": 17, "青": 18,
        "紫": 7, "茶・黒": 13, "灰": 8, "金・銀": 2, "アンティーク": 7,
    }
    actual_summary = {}
    for color in colors:
        actual_summary[color["family"]] = actual_summary.get(color["family"], 0) + 1
    if actual_summary != summary:
        fail(f"色群の内訳が違う: {actual_summary}")

    if len([c for c in colors if c["admix"] == "N"]) != 6:
        fail("混色記号Nの色が6色ではない")
    if len([c for c in colors if c["toxicity"] == "Co"]) != 3:
        fail("コバルト注意の色が3色ではない")
    if len([c for c in colors if c["antique"]]) != 7:
        fail("アンティークカラーが7色ではない")

    # 画面文言に絵文字を出さない
    for path in sorted(SOURCES.glob("*.swift")):
        source = path.read_text(encoding="utf-8")
        for match in EMOJI.finditer(source):
            fail(f"絵文字が混ざっている: {path.name} {match.group(0)!r}")

    if errors:
        for error in errors:
            print("FAIL:", error)
        sys.exit(1)

    print(f"PASS: 公式カタログ {len(colors)} 色の全項目が Swift と一致しました")
    print(f"  乾燥区分 I〜IV / 透明性 4段階 / 使用顔料 / 混色記号N {len([c for c in colors if c['admix'] == 'N'])}色 / 価格表 4サイズ")


if __name__ == "__main__":
    main()
