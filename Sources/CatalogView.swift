import SwiftUI

// MARK: - 絵具を選ぶ

struct CatalogView: View {
    let onApply: ([HolbeinCatalog.Paint]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selection: [HolbeinCatalog.Paint]

    init(picks: [HolbeinCatalog.Paint], onApply: @escaping ([HolbeinCatalog.Paint]) -> Void) {
        self.onApply = onApply
        _selection = State(initialValue: picks)
    }

    private var results: [HolbeinCatalog.Paint] {
        HolbeinCatalog.search(query)
    }

    var body: some View {
        ZStack {
            Color.naviBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchField

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if results.isEmpty {
                            Text("この色名は見つかりませんでした。")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.naviSub)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 28)
                        } else if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            ForEach(HolbeinCatalog.families, id: \.self) { family in
                                let colors = HolbeinCatalog.of(family: family)
                                if !colors.isEmpty {
                                    familyHeader(family)
                                    ForEach(colors) { color in
                                        row(color)
                                    }
                                }
                            }
                        } else {
                            ForEach(results) { color in
                                row(color)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.immediately)

                footer
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .tint(Color.naviAccent)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("絵具を選ぶ")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.naviInk)
                Spacer()
                Button("閉じる") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.naviSub)
            }
            Text("ホルベイン公式カタログ \(HolbeinCatalog.version)・全\(HolbeinCatalog.all.count)色")
                .font(.system(size: 12))
                .foregroundStyle(Color.naviSub)
        }
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Color.naviSub)
            TextField("色名・品番・顔料記号で探す", text: $query)
                .font(.system(size: 15))
                .foregroundStyle(Color.naviInk)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.naviLine)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.naviLine, lineWidth: 1)
        )
        .padding(.bottom, 6)
    }

    private func familyHeader(_ family: String) -> some View {
        Text(family)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.naviSub)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }

    private func row(_ color: HolbeinCatalog.Paint) -> some View {
        let selected = selection.contains(color)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                toggle(color)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundStyle(selected ? Color.naviAccent : Color.naviLine)
                    Text(color.name)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.naviInk)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 6)
                    Text("\(color.dryingClass)（\(color.dryingDays)日）")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.naviSub)
                }

                Text(shortLine(color))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .padding(.leading, 25)
                    .multilineTextAlignment(.leading)

                if selected {
                    VStack(alignment: .leading, spacing: 4) {
                        if !color.opacity.isEmpty {
                            infoLine("透明性", color.opacity)
                        }
                        infoLine("耐光性", color.permanencyText)
                        infoLine("使用顔料", color.pigments.joined(separator: " "))
                        infoLine("品番", refsText(color))
                        infoLine("価格", priceText(color))
                        if !color.traditional.isEmpty {
                            infoLine("岩絵具", color.traditional)
                        }
                        if color.needsSulfideCaution {
                            Text("硫化物を含むため、シルバーホワイトとの混色は避けてください。")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.naviWarn)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.leading, 25)
                    .padding(.bottom, 4)
                }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.naviLine.opacity(0.6))
                    .frame(height: 0.6)
            }
        }
        .buttonStyle(.plain)
    }

    private func shortLine(_ color: HolbeinCatalog.Paint) -> String {
        var parts: [String] = []
        if !color.pigments.isEmpty {
            parts.append(color.pigments.joined(separator: " "))
        }
        if !color.opacity.isEmpty {
            parts.append(color.opacity)
        }
        if !color.traditional.isEmpty {
            parts.append(color.traditional)
        }
        return parts.joined(separator: " ・ ")
    }

    private func infoLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.naviSub)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(Color.naviInk)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func refsText(_ color: HolbeinCatalog.Paint) -> String {
        var parts: [String] = []
        if !color.refs10.isEmpty {
            parts.append("10ml " + color.refs10.joined(separator: " "))
        }
        if !color.refs20.isEmpty {
            parts.append("20ml " + color.refs20.joined(separator: " "))
        }
        if !color.refs40.isEmpty {
            parts.append("40ml・110ml " + color.refs40.joined(separator: " "))
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " ・ ")
    }

    private func priceText(_ color: HolbeinCatalog.Paint) -> String {
        var parts: [String] = []
        if let yen = HolbeinCatalog.price(size: "10ml", series: color.series) {
            parts.append("10ml " + HolbeinCatalog.yenText(yen))
        }
        if let yen = HolbeinCatalog.price(size: "20ml", series: color.series) {
            parts.append("20ml " + HolbeinCatalog.yenText(yen))
        }
        if let yen = HolbeinCatalog.price(size: "40ml", series: color.series) {
            parts.append("40ml " + HolbeinCatalog.yenText(yen))
        }
        guard !parts.isEmpty else { return "—" }
        return parts.joined(separator: " ・ ") + "（シリーズ\(color.series)）"
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selection.isEmpty {
                Text("混色や重ね塗りにする色を選ぶと、いちばん乾きの遅い色で計算します。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(selection.map { $0.name }.joined(separator: "、"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                onApply(selection)
                dismiss()
            } label: {
                Text(selection.isEmpty ? "色を選んでください" : "この\(selection.count)色で計算")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(selection.isEmpty ? Color.naviSub : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(selection.isEmpty ? Color.naviLine.opacity(0.5) : Color.naviAccent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selection.isEmpty)
        }
        .padding(.top, 10)
    }

    private func toggle(_ color: HolbeinCatalog.Paint) {
        if let index = selection.firstIndex(of: color) {
            selection.remove(at: index)
        } else {
            selection.append(color)
        }
    }
}
