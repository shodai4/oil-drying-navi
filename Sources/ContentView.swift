import SwiftUI
import UIKit
import EventKit
import UserNotifications

// MARK: - 画面

struct ContentView: View {
    @State private var step = 0
    @State private var answers: [Int] = []
    @State private var result: DryingResult?
    @State private var catalogPicks: [HolbeinCatalog.Paint] = []
    @State private var showingCatalog = false

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
        .sheet(isPresented: $showingCatalog) {
            CatalogView(picks: catalogPicks) { picked in
                applyCatalog(picked)
            }
        }
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
                    if step == 2 {
                        catalogRow
                    }
                    ForEach(Array(question.options.enumerated()), id: \.element.id) { index, option in
                        OptionRow(
                            label: option.label,
                            selected: answers.indices.contains(step) && answers[step] == index && catalogPicks.isEmpty
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

    private var catalogRow: some View {
        Button {
            showingCatalog = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("絵具名から選ぶ")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.naviInk)
                    Text(catalogPicks.isEmpty
                         ? "公式カタログ 全\(HolbeinCatalog.all.count)色から、混色する色を選べる"
                         : catalogPicks.map { $0.name }.joined(separator: "、"))
                        .font(.system(size: 12))
                        .foregroundStyle(catalogPicks.isEmpty ? Color.naviSub : Color.naviAccent)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.naviSub)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.naviAccent.opacity(catalogPicks.isEmpty ? 0.04 : 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(catalogPicks.isEmpty ? Color.naviLine : Color.naviAccent, lineWidth: catalogPicks.isEmpty ? 1 : 1.4)
            )
        }
        .buttonStyle(.plain)
    }

    private func applyCatalog(_ picks: [HolbeinCatalog.Paint]) {
        catalogPicks = picks
        guard !picks.isEmpty else { return }
        if answers.indices.contains(2) {
            answers[2] = 1
        } else {
            while answers.count < 2 {
                answers.append(0)
            }
            answers.append(1)
        }
        if step == 2 {
            withAnimation(.easeInOut(duration: 0.15)) { step = 3 }
        }
    }

    private func choose(_ index: Int) {
        if step == 2 {
            catalogPicks = []
        }
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
            result = DryingResult(options: picked, catalogColors: catalogPicks)
        }
    }

    private func reset() {
        withAnimation(.easeInOut(duration: 0.2)) {
            result = nil
            step = 0
            answers = []
            catalogPicks = []
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

private enum ResultAlert: String, Identifiable {
    case notificationDenied
    case notificationFailed
    case calendarDenied
    case calendarFailed
    case reminderDenied
    case reminderFailed
    case googleFailed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notificationDenied:
            return "通知が許可されていません"
        case .notificationFailed:
            return "通知を予約できませんでした"
        case .calendarDenied:
            return "カレンダーが許可されていません"
        case .calendarFailed:
            return "カレンダーに登録できませんでした"
        case .reminderDenied:
            return "リマインダーが許可されていません"
        case .reminderFailed:
            return "リマインダーに追加できませんでした"
        case .googleFailed:
            return "Googleカレンダーを開けませんでした"
        }
    }

    var message: String {
        switch self {
        case .notificationDenied:
            return "設定アプリでこのアプリの通知をオンにすると、指触乾燥の日に知らせられます。"
        case .notificationFailed:
            return "時間をおいて、もう一度お試しください。"
        case .calendarDenied:
            return "設定アプリでこのアプリのカレンダーへのアクセスを許可すると、予定日を登録できます。"
        case .calendarFailed:
            return "書き込めるカレンダーが見つかりませんでした。設定アプリでカレンダーのアカウントをご確認ください。"
        case .reminderDenied:
            return "設定アプリでこのアプリのリマインダーへのアクセスを許可すると、予定日を追加できます。"
        case .reminderFailed:
            return "書き込めるリマインダーのリストが見つかりませんでした。設定アプリでリマインダーのアカウントをご確認ください。"
        case .googleFailed:
            return "ブラウザでカレンダーを開けませんでした。時間をおいて、もう一度お試しください。"
        }
    }

    var opensSettings: Bool {
        switch self {
        case .notificationDenied, .calendarDenied, .reminderDenied:
            return true
        default:
            return false
        }
    }
}

struct ResultView: View {
    let result: DryingResult
    let onReset: () -> Void

    @State private var status: String?
    @State private var alertKind: ResultAlert?
    @State private var workTitle = ""
    @State private var manufacturer: DryingManufacturer = .none
    @State private var eventStore = EKEventStore()
    @Environment(\.openURL) private var openURL

    private var shown: DryingResult {
        result.withManufacturer(manufacturer)
    }

    private var trimmedWorkTitle: String {
        workTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var notesText: String {
        var text = "重ね塗りは約\(shown.overpaintDays)日後、ワニス保護は\(shown.varnishText)。\n条件：\(shown.conditionSummary)"
        if !shown.catalogColors.isEmpty {
            let names = shown.catalogColors.map { "\($0.name)（\($0.dryingText)）" }.joined(separator: "、")
            text += "\n公式カタログ：\(names)"
        } else if manufacturer != .none {
            text += "\nメーカー：\(manufacturer.label)"
        }
        return text
    }

    private var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: shown.touchDays, to: Date()) ?? Date()
    }

    private var dayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: reminderDate)
    }

    private var reminderDateText: String {
        "\(dayText)10:00"
    }

    private var eventTitle: String {
        trimmedWorkTitle.isEmpty ? "油絵 指触乾燥目安" : "\(trimmedWorkTitle)：指触乾燥目安"
    }

    private var notificationTitle: String {
        trimmedWorkTitle.isEmpty ? "指触乾燥のころです" : "\(trimmedWorkTitle)：指触乾燥のころです"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("指触乾燥の目安")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.naviSub)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("約\(shown.touchDays)")
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

                infoRow(title: "重ね塗りOK", value: "約\(shown.overpaintDays)日後")
                Divider().overlay(Color.naviLine).opacity(0.6)
                infoRow(title: "ワニス保護OK", value: shown.varnishText)

                Divider().overlay(Color.naviLine)

                manufacturerRow

                Divider().overlay(Color.naviLine)

                if !shown.catalogColors.isEmpty {
                    catalogCard
                    Divider().overlay(Color.naviLine)
                }

                Text(shown.conditionSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                if shown.hasCrackRisk {
                    Text("注意：吸収性の下地に揮発性の画用液だけを使うと、油分が吸われてもろくなり、亀裂や剥離の原因になります。")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.naviWarn)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.naviWarn.opacity(0.08))
                        )
                        .padding(.top, 12)
                }

                TextField("作品名（任意）", text: $workTitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.naviInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.65))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.naviLine, lineWidth: 1)
                    )
                    .padding(.top, 18)

                VStack(spacing: 0) {
                    ActionRow(text: "iOSカレンダーに登録", emphasized: true, action: addToCalendar)
                    rowDivider
                    ActionRow(text: "リマインダーに追加", emphasized: false, action: addToReminder)
                    rowDivider
                    ActionRow(text: "Googleカレンダーで開く", emphasized: false, action: openGoogleCalendar)
                    rowDivider
                    ActionRow(text: "通知を予約", emphasized: false, action: scheduleReminder)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.7))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.naviLine, lineWidth: 1)
                )
                .padding(.top, 10)

                if let status {
                    Text(status)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.naviSub)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
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
        .alert(alertKind?.title ?? "", isPresented: isShowingAlert) {
            if alertKind?.opensSettings == true {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text(alertKind?.message ?? "")
        }
    }

    private var manufacturerRow: some View {
        HStack(spacing: 12) {
            Text("メーカー")
                .font(.system(size: 13))
                .foregroundStyle(Color.naviSub)
            Spacer(minLength: 8)
            if shown.catalogColors.isEmpty {
                Picker("メーカー", selection: $manufacturer) {
                    ForEach(DryingManufacturer.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .font(.system(size: 14))
            } else {
                Text("ホルベイン（公式カタログ値）")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.naviInk)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: 公式カタログ

    private var catalogCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("公式カタログ")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.naviSub)
                Spacer(minLength: 8)
                Text(HolbeinCatalog.version)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.naviSub)
            }

            if shown.catalogColors.count > 1, let slowest = shown.slowestColor {
                Text("いちばん遅い\(slowest.name)（\(slowest.dryingText)）に合わせています。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(shown.catalogColors) { color in
                catalogColorBlock(color)
            }
        }
        .padding(.vertical, 12)
    }

    private func catalogColorBlock(_ color: HolbeinCatalog.Paint) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(color.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.naviInk)
                Text(color.dryingText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviSub)
                Spacer(minLength: 0)
            }

            Text(catalogDetailText(color))
                .font(.system(size: 12))
                .foregroundStyle(Color.naviSub)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if color.needsSulfideCaution {
                Text("硫化物を含むため、シルバーホワイトとの混色は避けてください。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.naviWarn)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }

    private func catalogDetailText(_ color: HolbeinCatalog.Paint) -> String {
        var parts: [String] = []
        if !color.opacity.isEmpty {
            parts.append(color.opacity)
        }
        if !color.traditional.isEmpty {
            parts.append(color.traditional)
        }
        parts.append("耐光性\(color.permanencyText)")
        if !color.pigments.isEmpty {
            parts.append("使用顔料 \(color.pigments.joined(separator: " "))")
        }
        if let yen = HolbeinCatalog.price(size: "20ml", series: color.series) {
            parts.append("20ml \(HolbeinCatalog.yenText(yen))")
        }
        if let ref = color.refs20.first {
            parts.append(ref)
        }
        return parts.joined(separator: " ・ ")
    }

    private var rowDivider: some View {
        Divider()
            .overlay(Color.naviLine)
            .padding(.leading, 16)
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

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { alertKind != nil },
            set: { if !$0 { alertKind = nil } }
        )
    }

    // MARK: カレンダー

    private func addToCalendar() {
        let store = eventStore
        store.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    alertKind = .calendarDenied
                    return
                }
                guard let calendar = store.defaultCalendarForNewEvents else {
                    alertKind = .calendarFailed
                    return
                }
                let day = Calendar.current.startOfDay(for: reminderDate)
                let event = EKEvent(eventStore: store)
                event.calendar = calendar
                event.title = eventTitle
                event.isAllDay = true
                event.startDate = day
                event.endDate = day
                event.notes = notesText
                do {
                    try store.save(event, span: .thisEvent, commit: true)
                    status = "カレンダーに登録しました（\(dayText)）"
                } catch {
                    alertKind = .calendarFailed
                }
            }
        }
    }

    // MARK: リマインダー

    private func addToReminder() {
        let store = eventStore
        store.requestFullAccessToReminders { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    alertKind = .reminderDenied
                    return
                }
                guard let calendar = store.defaultCalendarForNewReminders() else {
                    alertKind = .reminderFailed
                    return
                }
                var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
                components.hour = 10
                components.minute = 0
                components.second = 0

                let reminder = EKReminder(eventStore: store)
                reminder.calendar = calendar
                reminder.title = eventTitle
                reminder.notes = notesText
                reminder.dueDateComponents = components
                if let fireDate = Calendar.current.date(from: components) {
                    reminder.addAlarm(EKAlarm(absoluteDate: fireDate))
                }
                do {
                    try store.save(reminder, commit: true)
                    status = "リマインダーに追加しました（\(reminderDateText)）"
                } catch {
                    alertKind = .reminderFailed
                }
            }
        }
    }

    // MARK: Googleカレンダー

    private func openGoogleCalendar() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let start = formatter.string(from: reminderDate)
        let endDay = Calendar.current.date(byAdding: .day, value: 1, to: reminderDate) ?? reminderDate
        let end = formatter.string(from: endDay)

        var components = URLComponents(string: "https://calendar.google.com/calendar/render")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: eventTitle),
            URLQueryItem(name: "dates", value: "\(start)/\(end)"),
            URLQueryItem(name: "details", value: notesText)
        ]
        guard let url = components?.url else {
            alertKind = .googleFailed
            return
        }
        openURL(url) { accepted in
            if !accepted {
                alertKind = .googleFailed
            }
        }
    }

    // MARK: 通知

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
                            alertKind = .notificationDenied
                        }
                    }
                }
            default:
                DispatchQueue.main.async { alertKind = .notificationDenied }
            }
        }
    }

    private func enqueue() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = notificationTitle
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

        let id = "touch-dry-\(shown.touchDays)-\(Int(reminderDate.timeIntervalSince1970))"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            DispatchQueue.main.async {
                if error == nil {
                    status = "通知を予約しました（\(label)）"
                } else {
                    alertKind = .notificationFailed
                }
            }
        }
    }
}

private struct ActionRow: View {
    let text: String
    let emphasized: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 15, weight: emphasized ? .semibold : .regular))
                    .foregroundStyle(Color.naviInk)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(ActionRowStyle())
    }
}

private struct ActionRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.naviAccent.opacity(configuration.isPressed ? 0.08 : 0))
    }
}

// MARK: - 色

extension Color {
    static let naviBackground = Color(red: 0.972, green: 0.960, blue: 0.941)
    static let naviInk = Color(red: 0.145, green: 0.133, blue: 0.118)
    static let naviSub = Color(red: 0.420, green: 0.400, blue: 0.370)
    static let naviLine = Color(red: 0.860, green: 0.840, blue: 0.800)
    static let naviAccent = Color(red: 0.480, green: 0.290, blue: 0.180)
    static let naviWarn = Color(red: 0.620, green: 0.330, blue: 0.160)
}

#Preview {
    ContentView()
}
