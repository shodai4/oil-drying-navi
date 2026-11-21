import SwiftUI
import UIKit
import UserNotifications

// MARK: - 係数と計算

struct DryingOption: Identifiable {
    let label: String
    let factor: Double

    var id: String { label }
}

enum DryingQuestion: CaseIterable {
    case medium
    case pigment
    case thickness
    case environment

    var title: String {
        switch self {
        case .medium:
            return "オイル・メディウムは？"
        case .pigment:
            return "主な絵の具は？"
        case .thickness:
            return "塗りの厚みは？"
        case .environment:
            return "部屋の環境は？"
        }
    }

    var caption: String {
        switch self {
        case .medium:
            return "下地に混ぜた油や、描きながら足したメディウム。"
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
        case .medium:
            return [
                DryingOption(label: "リンシードオイル", factor: 1.0),
                DryingOption(label: "ポピーオイル", factor: 1.5),
                DryingOption(label: "調合油・速乾タイプ", factor: 0.5),
                DryingOption(label: "揮発性油だけ", factor: 0.2),
                DryingOption(label: "油は使っていない", factor: 0.8)
            ]
        case .pigment:
            return [
                DryingOption(label: "アンバー・コバルト系", factor: 0.6),
                DryingOption(label: "標準的な色", factor: 1.0),
                DryingOption(label: "チタニウムホワイト・赤系", factor: 1.8)
            ]
        case .thickness:
            return [
                DryingOption(label: "薄塗り", factor: 0.6),
                DryingOption(label: "標準", factor: 1.0),
                DryingOption(label: "厚塗り・インパスト", factor: 2.5)
            ]
        case .environment:
            return [
                DryingOption(label: "寒い・湿気がある", factor: 1.4),
                DryingOption(label: "常温・ふつう", factor: 1.0),
                DryingOption(label: "暖かい・風通しがよい", factor: 0.7)
            ]
        }
    }
}

struct DryingResult {
    let touchDays: Int
    let overpaintDays: Int
    let varnishDays: Int
    let conditions: [String]

    init(options: [DryingOption]) {
        conditions = options.map { $0.label }

        let product = options.reduce(1.0) { $0 * $1.factor }
        let touch = max(1, Int((3.0 * product).rounded()))
        touchDays = touch
        overpaintDays = max(2, Int((Double(touch) * 2.0).rounded()))
        varnishDays = min(180, max(30, touch * 10))
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

// MARK: - 画面

struct ContentView: View {
    @State private var step = 0
    @State private var answers: [Int] = []
    @State private var result: DryingResult?

    var body: some View {
        ZStack {
            Color.naviBackground.ignoresSafeArea()

            Group {
                if let result {
                    ResultView(result: result, onReset: reset)
                } else {
                    questionView
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .tint(Color.naviAccent)
    }

    private var question: DryingQuestion {
        DryingQuestion.allCases[step]
    }

    private var questionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\(step + 1) / \(DryingQuestion.allCases.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.naviSub)
                    Spacer()
                    if !answers.isEmpty {
                        Button("やり直す") { reset() }
                            .font(.system(size: 13))
                            .foregroundStyle(Color.naviSub)
                    }
                }
                .padding(.bottom, 22)

                Text(question.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.naviInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(question.caption)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.naviSub)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)

                VStack(spacing: 8) {
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                        OptionRow(
                            label: option.label,
                            selected: answers.indices.contains(step) && answers[step] == index
                        ) {
                            choose(index)
                        }
                    }
                }
                .padding(.top, 20)

                if step > 0 {
                    Button(action: goBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text("戻る")
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(Color.naviSub)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func choose(_ index: Int) {
        if answers.indices.contains(step) {
            answers[step] = index
        } else {
            answers.append(index)
        }

        if step < DryingQuestion.allCases.count - 1 {
            withAnimation(.easeInOut(duration: 0.15)) { step += 1 }
        } else {
            finish()
        }
    }

    private func goBack() {
        guard step > 0 else { return }
        withAnimation(.easeInOut(duration: 0.15)) { step -= 1 }
        if answers.count > step {
            answers.removeSubrange(step...)
        }
    }

    private func finish() {
        let all = DryingQuestion.allCases
        var picked: [DryingOption] = []
        for (index, question) in all.enumerated() {
            guard answers.indices.contains(index) else { return }
            let optionIndex = answers[index]
            guard question.options.indices.contains(optionIndex) else { return }
            picked.append(question.options[optionIndex])
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            result = DryingResult(options: picked)
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            result = nil
            step = 0
            answers = []
        }
    }
}

private struct OptionRow: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.naviInk)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Color.naviAccent.opacity(0.12) : Color.white.opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(selected ? Color.naviAccent : Color.naviLine, lineWidth: selected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 結果

private enum ReminderAlert: String, Identifiable {
    case denied
    case failed

    var id: String { rawValue }
}

struct ResultView: View {
    let result: DryingResult
    let onReset: () -> Void

    @State private var scheduledLabel: String?
    @State private var alertKind: ReminderAlert?
    @Environment(\.openURL) private var openURL

    private var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: result.touchDays, to: Date()) ?? Date()
    }

    private var reminderDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）10:00"
        return formatter.string(from: reminderDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("指触乾燥の目安")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.naviSub)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("約\(result.touchDays)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.naviInk)
                    Text("日")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.naviSub)
                }
                .padding(.top, 2)

                Text("表面に触れて、絵の具が指につかないころ。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .padding(.bottom, 18)

                Divider().overlay(Color.naviLine)

                infoRow(title: "重ね塗りOK", value: "約\(result.overpaintDays)日後")
                Divider().overlay(Color.naviLine).opacity(0.6)
                infoRow(title: "ワニス保護OK", value: result.varnishText)

                Divider().overlay(Color.naviLine)

                Text(result.conditionSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                Button(action: scheduleReminder) {
                    Text("リマインドを予約")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.naviAccent)
                        )
                }
                .buttonStyle(.plain)

                if let scheduledLabel {
                    Text("\(scheduledLabel) に通知します")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.naviSub)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                }

                Button("条件を選び直す", action: onReset)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.naviSub)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 18)
                    .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .alert(alertTitle, isPresented: isShowingAlert) {
            if alertKind == .denied {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(Color.naviInk)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.naviInk)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
    }

    // MARK: 通知

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { alertKind != nil },
            set: { if !$0 { alertKind = nil } }
        )
    }

    private var alertTitle: String {
        alertKind == .denied ? "通知が許可されていません" : "通知を予約できませんでした"
    }

    private var alertMessage: String {
        if alertKind == .denied {
            return "設定アプリでこのアプリの通知をオンにすると、指触乾燥の日に知らせられます。"
        }
        return "時間をおいて、もう一度お試しください。"
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                enqueue()
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            enqueue()
                        } else {
                            alertKind = .denied
                        }
                    }
                }
            default:
                DispatchQueue.main.async { alertKind = .denied }
            }
        }
    }

    private func enqueue() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "指触乾燥のころです"
        content.body = "塗面にそっと触れて、乾きを確かめてみましょう。"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 10
        components.minute = 0
        components.second = 0

        let trigger: UNNotificationTrigger
        let label: String

        if let fireDate = Calendar.current.date(from: components),
           fireDate > Date().addingTimeInterval(60) {
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            label = reminderDateText
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            label = "1分後"
        }

        let id = "touch-dry-\(result.touchDays)-\(Int(reminderDate.timeIntervalSince1970))"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    scheduledLabel = label
                } else {
                    scheduledLabel = nil
                    alertKind = .failed
                }
            }
        }
    }
}

// MARK: - 色

extension Color {
    static let naviBackground = Color(red: 0.972, green: 0.960, blue: 0.941)
    static let naviInk = Color(red: 0.145, green: 0.133, blue: 0.118)
    static let naviSub = Color(red: 0.420, green: 0.400, blue: 0.370)
    static let naviLine = Color(red: 0.860, green: 0.840, blue: 0.800)
    static let naviAccent = Color(red: 0.480, green: 0.290, blue: 0.180)
}

#Preview {
    ContentView()
}
