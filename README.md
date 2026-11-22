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
| `Sources/ContentView.swift` | 質問・計算・結果・カレンダー／リマインダー／通知 |
| `Resources/Info.plist` | アプリの設定（暗号化の申告、カレンダー・リマインダーの利用目的） |
| `Resources/Assets.xcassets` | アプリアイコン（AppIcon 1024px） |
| `scripts/ci-testflight.sh` | アーカイブ・書き出し・TestFlight アップロードの本体 |
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

## 登録

| 登録先 | タイトル | メモ |
| --- | --- | --- |
| iOSカレンダー | `油絵 指触乾燥目安`（作品名を入れた場合は `作品名：指触乾燥目安`） | 重ね塗り・ワニス目安と選んだ条件 |
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

