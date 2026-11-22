# 油絵・乾燥予測ナビ

油絵の具が乾くまでの目安を、5つの質問から見積もるiOSアプリ。

- 指触乾燥（表面に触れて絵の具が指につかない）
- 重ね塗りができるころ
- ワニスで保護できるころ

結果画面から、指触乾燥の日を iOS カレンダー・リマインダー・Google カレンダーに登録できる。端末のローカル通知によるリマインドも予約できる。作品名（任意）を入れておくと、どの絵の予定かがタイトルで分かる。

## 構成

| パス | 内容 |
| --- | --- |
| `project.yml` | XcodeGen 定義（Bundle ID: `com.shodai4.oildryingnavi`、iOS 17.0+） |
| `Sources/OilDryingNaviApp.swift` | アプリのエントリポイント |
| `Sources/ContentView.swift` | 質問・結果・カレンダー／リマインダー／通知 |
| `Sources/DryingModel.swift` | 質問の係数と乾燥日数の計算 |
| `Sources/HolbeinCatalog.swift` | ホルベイン公式カタログ全107色のデータ（生成ファイル） |
| `Sources/CatalogView.swift` | 絵具名から選ぶ画面（検索・色の詳細） |
| `Resources/Info.plist` | アプリの設定（暗号化の申告、カレンダー・リマインダーの利用目的） |
| `Resources/Assets.xcassets` | アプリアイコン（AppIcon 1024px） |
| `scripts/ci-testflight.sh` | カタログ自己テスト・アーカイブ・書き出し・TestFlight アップロードの本体 |
| `scripts/selftest/main.swift` | カタログ全色と乾燥計算の自己テスト |
| `tools/extract_catalog.py` | 公式カタログPDFから全色データを抽出して `tools/catalog.json` を作る |
| `tools/generate_catalog_swift.py` | `tools/catalog.json` から `Sources/HolbeinCatalog.swift` を生成する |
| `tools/verify_catalog.py` | 抽出データとSwiftの全項目を突き合わせる検証 |
| `.github/workflows/ios-build.yml` | GitHub Actions（main への push で TestFlight へ自動配信） |

## 計算

指触乾燥日数 = `max(1, round(3.0 × 各係数の積))` 日。

| 質問 | 選択肢と係数 |
| --- | --- |
| 下地 | 吸収性（膠・石膏）0.7 / 標準（麻・綿）1.0 / 非吸収（油性）1.3 |
| 画用液 | アルキド樹脂 0.4 / リンシード 1.0 / ポピー・スタンド 1.6 / 揮発性のみ 0.3 |
| 主な顔料 | 速乾（土・コバルト）0.6 / 標準 1.0 / 遅乾（白・黒・紅）2.0 |
| 塗りの厚み | 薄塗り 0.6 / 標準 1.0 / 厚塗り 2.5 |
| 部屋の状態 | 寒い・湿気 1.4 / 標準 1.0 / 暖かい・乾燥 0.7 |

重ね塗りは指触乾燥の2倍、ワニス保護は指触乾燥×60日を30〜180日の範囲に収めた目安。吸収性の下地に揮発性の画用液だけを使った場合は、亀裂・剥離への注意を表示する。

「主な顔料」の質問では、色名・品番・顔料記号から公式カタログの色を選べる（後述）。選ぶとその色の実測日数を基準に計算し、結果画面の「メーカー（任意）」は公式値を使うため表示だけになる（係数は重ねない）。

結果画面の「メーカー（任意）」で、絵の具の乾きやすさを微調整できる（選ぶとその場で再計算）。

| メーカー | 係数 |
| --- | --- |
| 指定なし | 1.0 |
| ホルベイン（ややゆっくり） | 1.1 |
| クサカベ（標準〜やや早め） | 0.9 |
| マツダ（やや早め） | 0.85 |
| ウィンザー＆ニュートン（標準） | 1.0 |
| 水可溶性（DUOなど・やや早め） | 0.85 |

## 公式カタログ（ホルベイン 全107色）

ホルベイン画材の油絵具カタログ（HA-2611、2026年11月2日現在）の全色を収録している。数値は 0.15mm 厚・25℃・湿度55% の室内で測った指触乾燥時間にもとづく。

| 項目 | 内容 |
| --- | --- |
| 乾燥所要日数 | Ⅰ（2日前後かそれ以下）／Ⅱ（3日前後）／Ⅲ（4日前後）／Ⅳ（5日前後） |
| 透明性 | 透明／半透明／半不透明／不透明（ゴールド・シルバーはカタログに記載なし） |
| 耐光性 | ＊〜＊＊＊＊ |
| 混色記号 | N は硫化物を含むため、シルバーホワイトとの混色を避ける |
| 毒性注意 | (Co) は溶解性コバルトを含む |
| 使用顔料 | PR177 などの C.I. 名 |
| 品番・シリーズ | 10ml／20ml／40ml／110ml の品番と、価格のシリーズ記号 A〜L |
| 価格 | 2026年11月2日現在の税込価格（20ml は A 550円〜I 5,060円） |

選んだ色は `乾燥日数 ÷ 3` を「主な顔料」の係数として使う。ほかの4問が標準なら、公式の日数がそのまま出る。何色か選んだときは、いちばん乾きの遅い色に合わせる。

## テスト

```sh
python3 tools/verify_catalog.py

swiftc -O -o /tmp/catalog-selftest \
  Sources/HolbeinCatalog.swift Sources/DryingModel.swift scripts/selftest/main.swift
/tmp/catalog-selftest
```

`verify_catalog.py` は `tools/catalog.json` と `Sources/HolbeinCatalog.swift` の全項目（色名・乾燥区分・透明性・耐光性・混色記号・使用顔料・品番・価格）を突き合わせ、画面文言に絵文字がないことも確認する。自己テストは CI（`scripts/ci-testflight.sh`）がアーカイブ前に必ず実行する。

## 登録

| 登録先 | タイトル | メモ |
| --- | --- | --- |
| iOSカレンダー | `油絵 指触乾燥目安`（作品名を入れた場合は `作品名：指触乾燥目安`） | 重ね塗り・ワニス目安と選んだ条件（メーカーを選んだ場合はメーカー名も） |
| リマインダー | 同上（期日当日の10:00） | 同上 |
| Googleカレンダー | 同上（テンプレートをブラウザで開く） | 同上 |
| 通知 | `指触乾燥のころです`（作品名を入れた場合は `作品名：指触乾燥のころです`） | — |

## ビルド

```sh
xcodegen generate
xcodebuild build -project OilDryingNavi.xcodeproj -scheme OilDryingNavi \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

## TestFlight 配信

`main` へ push すると GitHub Actions が `scripts/ci-testflight.sh` を実行し、アーカイブ → 書き出し → TestFlight へのアップロードまで進む。ビルド番号には `github.run_number` を使う。

必要なリポジトリ Secrets:

| 名前 | 内容 |
| --- | --- |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect API キーの Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | AuthKey_*.p8 の中身 |
| `APPLE_TEAM_ID` | チーム ID |

App Store Connect: Apple ID `6837710186`／Bundle ID `com.shodai4.oildryingnavi`／TestFlight 内部グループ「開発テスト」。

