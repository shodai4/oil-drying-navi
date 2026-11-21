# 油絵・乾燥予測ナビ

油絵の具が乾くまでの目安を、4つの質問から見積もるiOSアプリ。

- 指触乾燥（表面に触れて絵の具が指につかない）
- 重ね塗りができるころ
- ワニスで保護できるころ

結果画面から、指触乾燥の日のリマインドを端末のローカル通知で予約できる。

## 構成

| パス | 内容 |
| --- | --- |
| `project.yml` | XcodeGen 定義（Bundle ID: `com.shodai4.oildryingnavi`、iOS 17.0+） |
| `Sources/OilDryingNaviApp.swift` | アプリのエントリポイント |
| `Sources/ContentView.swift` | 質問・計算・結果・通知予約 |
| `Resources/Info.plist` | アプリの設定 |
| `.github/workflows/ios-build.yml` | GitHub Actions でのビルド確認 |

## 計算

指触乾燥日数 = `max(1, round(3.0 × 各係数の積))` 日。

| 質問 | 選択肢と係数 |
| --- | --- |
| オイル・メディウム | リンシード 1.0 / ポピー 1.5 / 調合油・速乾 0.5 / 揮発性油のみ 0.2 / 油なし 0.8 |
| 主な絵の具 | アンバー・コバルト系 0.6 / 標準 1.0 / チタニウムホワイト・赤系 1.8 |
| 塗りの厚み | 薄塗り 0.6 / 標準 1.0 / 厚塗り・インパスト 2.5 |
| 部屋の環境 | 寒い・湿気あり 1.4 / 常温 1.0 / 暖かい・風通し良い 0.7 |

重ね塗りは指触乾燥の約2倍、ワニス保護は指触乾燥×10日を30〜180日の範囲に収めた目安。

## ビルド

```sh
xcodegen generate
xcodebuild build -project OilDryingNavi.xcodeproj -scheme OilDryingNavi \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```
