#!/usr/bin/env python3
"""ホルベイン油絵具カタログPDF（2026年11月2日現在）から全色データを抽出して JSON にする。

使い方: python3 tools/extract_catalog.py [PDFパス] > tools/catalog.json

- P5〜P6: 全色一覧（品番・色名・シリーズ・耐光性・混色記号N・乾燥所要日数I〜IV・透明性・毒性(Co)・使用顔料）
- P6: アンティークカラー7色（岩絵具の伝統色名つき）
- P7: 2026/11/2現在の税込価格（サイズ×シリーズ）

文字は座標で列に振り分け、透明性は文字ではなくベクター描画（円）なので
パスの要素数で4段階を判別する。
"""
import json
import sys

import pymupdf

DEFAULT_PDF = "downloads/油絵具カタログ.pdf"

# 透明性記号は文字ではなくベクター描画。パスの要素数で4段階を判別する。
OPACITY_BY_ITEMS = {8: "透明", 10: "半透明", 7: "半不透明", 4: "不透明"}
DRYING_DAYS = {"Ⅰ": 2, "Ⅱ": 3, "Ⅲ": 4, "Ⅳ": 5}
SERIES_ASCII = {chr(0xFF21 + i): chr(0x41 + i) for i in range(26)}  # Ａ→A


def series_code(text):
    text = text.strip()
    if not text:
        return ""
    ch = text[0]
    if ch in SERIES_ASCII:
        return SERIES_ASCII[ch]
    return ch if ch.isascii() and ch.isalpha() else ""


def pigment_codes(text):
    """「PR177, 254」は PR177 と PR254 の2色。カンマ後の数字は直前の記号の頭文字を継ぐ。"""
    import re

    tokens = [t for t in re.split(r"[,\s]+", text) if t]
    codes = []
    prefix = ""
    for token in tokens:
        m = re.fullmatch(r"([A-Z]{1,2}[a-z]{0,2})(\d{1,3})", token)
        if m:
            prefix = m.group(1)
            codes.append(prefix + m.group(2))
        elif re.fullmatch(r"\d{1,3}", token) and prefix:
            codes.append(prefix + token)
    return codes

# ページごとの列境界（x0, x1, 列名）。表の組み方が P5 と P6 で少し違う。
COLUMNS = {
    5: (
        (0, 60, "ref10"),
        (60, 88, "ref20"),
        (88, 138, "ref40_110"),
        (138, 250, "ja"),
        (250, 345, "en"),
        (345, 362, "series"),
        (362, 388, "perm"),
        (388, 406, "admix"),
        (406, 445, "dry"),
        (445, 462, "opacity"),
        (462, 488, "tox"),
        (488, 600, "pigments"),
    ),
    6: (
        (0, 60, "ref10"),
        (60, 88, "ref20"),
        (88, 138, "ref40_110"),
        (138, 235, "ja"),
        (235, 328, "en"),
        (328, 350, "series"),
        (350, 377, "perm"),
        (377, 394, "admix"),
        (394, 428, "dry"),
        (428, 446, "opacity"),
        (446, 468, "tox"),
        (468, 600, "pigments"),
    ),
}


def column_of(pno, x):
    for x0, x1, name in COLUMNS[pno]:
        if x0 <= x < x1:
            return name
    return None


def row_texts(page, pno):
    """行ごとに {列名: 文字列} を作る。文字単位で列へ振り分けるので、列をまたぐ span も扱える。"""
    rows = []
    for block in page.get_text("rawdict")["blocks"]:
        for line in block.get("lines", []):
            for span in line["spans"]:
                for ch in span["chars"]:
                    c = ch["c"]
                    if c == "\u3000":
                        c = " "
                    # 空白も列の区切りとして残す（単語が連結しないように）
                    x0, y0, x1, _ = ch["bbox"]
                    cx = (x0 + x1) / 2
                    for row in rows:
                        if abs(row["y"] - y0) < 3.0:
                            break
                    else:
                        row = {"y": y0, "cols": {}}
                        rows.append(row)
                    name = column_of(pno, cx)
                    if name:
                        row["cols"][name] = row["cols"].get(name, "") + c
    return sorted(rows, key=lambda r: r["y"])


def clean(text):
    return " ".join(text.replace("\u3000", " ").replace("\u00a0", " ").split())


FAMILY_JA = {
    "RED": "赤",
    "ORANGE": "橙",
    "YELLOW": "黄",
    "GREEN": "緑",
    "BLUE": "青",
    "VIOLET": "紫",
    "BROWN & BLACK": "茶・黒",
    "GREY": "灰",
    "GOLD & SILVER": "金・銀",
}


def family_headers(page, pno):
    """表の色群見出し（RED など）の y 位置を拾う。"""
    headers = []
    for block in page.get_text("rawdict")["blocks"]:
        for line in block.get("lines", []):
            for span in line["spans"]:
                text = "".join(c["c"] for c in span["chars"]).strip()
                if text in FAMILY_JA and span["bbox"][0] < 250:
                    headers.append((span["bbox"][1], FAMILY_JA[text]))
    return sorted(headers)


def parse_color_rows(page, pno, op_drawings):
    colors = []
    headers = family_headers(page, pno)
    for row in row_texts(page, pno):
        cols = {k: clean(v) for k, v in row["cols"].items()}
        dry = cols.get("dry", "")
        pigments = cols.get("pigments", "")
        ja = cols.get("ja", "")
        if "日前後" not in dry or not pigments or not ja:
            continue

        dry_class = ""
        for mark in DRYING_DAYS:
            if mark in dry:
                dry_class = mark
                break
        if not dry_class:
            raise SystemExit(f"乾燥区分が読めない行: {ja}")

        symbol = None
        for draw in op_drawings:
            # 記号は文字の上端から約2pt下に描かれている
            if abs(draw["rect"].y0 - (row["y"] + 2.0)) < 3.0:
                symbol = len(draw["items"])
                break

        family = "アンティーク" if pno == 6 else ""
        for y, name in headers:
            if y < row["y"]:
                family = name

        admix_text = cols.get("perm", "") + " " + cols.get("admix", "")
        admix = "N" if "N" in admix_text else ("S" if "S" in admix_text else "")

        traditional = ""
        if "アンティーク" in ja:
            parts = ja.split()
            if parts and all("\u4e00" <= ch <= "\u9fff" for ch in parts[-1]):
                traditional = parts[-1]
                ja = " ".join(parts[:-1])

        def refs(name):
            return [t for t in cols.get(name, "").split() if t and t != "ー"]

        colors.append(
            {
                "ja": ja,
                "family": family,
                "traditional": traditional,
                "en": cols.get("en", ""),
                        "series": series_code(cols.get("series", "")),
                "permanency": cols.get("perm", "").count("＊"),
                "admix": admix,
                "dryingClass": dry_class,
                "dryingDays": DRYING_DAYS[dry_class],
                "opacity": OPACITY_BY_ITEMS.get(symbol, "") if symbol is not None else "",
                "toxicity": "Co" if "(Co)" in cols.get("tox", "") else "",
                "pigments": ["岩絵具"] if pno == 6 else pigment_codes(pigments),
                "refs10": refs("ref10"),
                "refs20": refs("ref20"),
                "refs40_110": refs("ref40_110"),
                "antique": "アンティーク" in ja,
            }
        )
    return colors


def parse_prices(page):
    """P7 の価格表を (サイズ, シリーズ) → 税込価格 で返す。"""
    blocks = [
        ("10ml", (50, 300), (186, 231)),
        ("20ml", (50, 300), (231, 370)),
        ("40ml", (300, 560), (186, 301)),
        ("110ml", (300, 560), (301, 400)),
    ]
    words = [(w[0], w[1], w[4]) for w in page.get_text("words")]
    prices = {}
    for size, (x0, x1), (y0, y1) in blocks:
        series_y = None
        for x, y, t in words:
            if x0 <= x <= x1 and y0 <= y < y1 and t == "シリーズ":
                series_y = y
                break
        if series_y is None:
            raise SystemExit(f"価格表のシリーズ列が見つからない: {size}")
        for x, y, t in words:
            if y <= series_y or not (y0 <= y < y1) or not (x0 <= x <= x1):
                continue
            if len(t) == 1 and t in "ABCDEFGHIJKL":
                yen = [
                    t2
                    for x2, y2, t2 in words
                    if abs(y2 - y) < 3 and x0 <= x2 <= x1 and t2.startswith("¥")
                ]
                if yen:
                    # 同じ行の左側が税込、右側が本体価格
                    first = min(yen, key=lambda v: v[0])
                    prices.setdefault(size, {})[t] = int(first[1:].replace(",", ""))
    return prices


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PDF
    doc = pymupdf.open(path)

    colors = []
    for pno in (4, 5):
        page = doc[pno]
        ops = [
            d
            for d in page.get_drawings()
            if 425 < d["rect"].x0 < 465
            and d["rect"].width > 2
            and len(d["items"]) in OPACITY_BY_ITEMS
        ]
        colors.extend(parse_color_rows(page, pno + 1, ops))

    prices = parse_prices(doc[6])

    out = {
        "source": "ホルベイン画材 油絵具カタログ HA-2611",
        "version": "2026年11月2日現在",
        "prices": prices,
        "colors": colors,
    }
    json.dump(out, sys.stdout, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
