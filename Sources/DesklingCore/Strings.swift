import Foundation

public enum Language: Equatable {
    case korean, english

    public static func current(preferred: [String] = Locale.preferredLanguages) -> Language {
        preferred.first?.hasPrefix("ko") == true ? .korean : .english
    }
}

public enum Text: CaseIterable {
    case skin, boySkin, girlSkin, openSkinsFolder
    case size, sizeSmall, sizeMedium, sizeLarge
    case hidePet, showPet, launchAtLogin, quit
    case startFocus, stopFocus, focusStatus, breakStatus
    case timer, timerMinutes, cancelTimer, stretchReminder
    case customTimer, customTimerTitle, customTimerBody, start, cancel, invalidDuration
    case countdownFocus, countdownBreak
    case focusEndedMessage, breakEndedMessage, stretchMessage, timerEndedMessage
    case close, loginItemFailed, missingResources

    public func string(_ language: Language) -> String {
        let pair = Self.table[self]!
        return language == .korean ? pair.0 : pair.1
    }

    /// Fills the `%d` in texts such as `.focusStatus`.
    public func string(_ language: Language, _ number: Int) -> String {
        string(language).replacingOccurrences(of: "%d", with: String(number))
    }

    private static let table: [Text: (String, String)] = [
        .skin: ("스킨", "Skin"),
        .boySkin: ("남자아이", "Boy"),
        .girlSkin: ("여자아이", "Girl"),
        .openSkinsFolder: ("스킨 폴더 열기", "Open Skins Folder"),
        .size: ("크기", "Size"),
        .sizeSmall: ("작게", "Small"),
        .sizeMedium: ("보통", "Medium"),
        .sizeLarge: ("크게", "Large"),
        .hidePet: ("펫 숨기기", "Hide Pet"),
        .showPet: ("펫 보이기", "Show Pet"),
        .launchAtLogin: ("로그인할 때 실행하기", "Launch at Login"),
        .quit: ("종료하기", "Quit Deskling Pet"),
        .startFocus: ("집중 시작하기 (25분)", "Start Focus (25 min)"),
        .stopFocus: ("집중 멈추기", "Stop Focus"),
        .focusStatus: ("집중하는 중: %d분 남음", "Focusing: %d min left"),
        .breakStatus: ("쉬는 중: %d분 남음", "On a break: %d min left"),
        .timer: ("타이머", "Timer"),
        .timerMinutes: ("%d분", "%d min"),
        .cancelTimer: ("타이머 취소하기 (%d분 남음)", "Cancel Timer (%d min left)"),
        .stretchReminder: ("한 시간마다 스트레칭 알림", "Stretch Reminder Every Hour"),
        .customTimer: ("직접 입력하기…", "Custom…"),
        .customTimerTitle: ("타이머 시간", "Timer Length"),
        .customTimerBody: (
            "몇 분 뒤에 알려 드릴지 입력합니다. 25처럼 분으로 쓰거나, 1:30처럼 시간과 분으로 씁니다.",
            "Enter how long to wait: minutes such as 25, or hours and minutes such as 1:30."
        ),
        .start: ("시작하기", "Start"),
        .cancel: ("취소", "Cancel"),
        .invalidDuration: ("1분에서 24시간 사이로 입력해야 합니다.", "Enter a length between 1 minute and 24 hours."),
        .countdownFocus: ("집중", "Focus"),
        .countdownBreak: ("휴식", "Break"),
        .focusEndedMessage: ("집중 시간이 끝났습니다. 이제 5분 동안 쉬는 시간입니다.", "Focus time is over. Take a 5-minute break."),
        .breakEndedMessage: ("쉬는 시간이 끝났습니다.", "Your break is over."),
        .stretchMessage: ("잠깐 일어나서 몸을 풀고 물을 마실 시간입니다.", "Stand up, stretch, and drink some water."),
        .timerEndedMessage: ("타이머가 끝났습니다.", "Your timer is up."),
        .close: ("닫기", "Close"),
        .loginItemFailed: ("로그인 항목을 바꾸지 못했습니다.", "Could not change the login item."),
        .missingResources: ("기본 펫 그림을 찾을 수 없습니다.", "The default pet images are missing."),
    ]
}

public enum PetPresentation {
    /// How long the pet stays happy after a click, in seconds.
    public static let happyDuration = 2.0

    public static func pose(
        isWalking: Bool, isHappy: Bool = false, isHeld: Bool = false, isFalling: Bool = false,
        isAlerting: Bool = false, isFocusing: Bool = false
    ) -> PetPose {
        if isHeld { return .drag }
        if isFalling { return .fall }
        if isHappy { return .happy }
        if isAlerting { return .waiting }
        if isFocusing { return .working }
        return isWalking ? .walk : .idle
    }

    /// What the speech bubble shows: a due reminder, or else the time left on the focus session and the timer,
    /// one per line. `key` stays the same while the same kind of bubble counts down, so a click on it can be
    /// told apart from a click on a new bubble. Returns `nil` when there is nothing to show.
    public static func bubble(
        alert: Reminder?, reminders: Reminders, showCountdown: Bool, now: Date, language: Language
    ) -> (key: String, text: String)? {
        if let alert {
            return ("alert-\(alert)", message(for: alert, language: language))
        }
        guard showCountdown else { return nil }
        var lines: [String] = []
        var key = "countdown"
        if let phase = reminders.phase, let ends = reminders.phaseEnds {
            let label = phase == .focus ? Text.countdownFocus : .countdownBreak
            lines.append("\(label.string(language)) \(Reminders.clock(until: ends, at: now))")
            key += "-\(phase)"
        }
        if let ends = reminders.timerEnds {
            lines.append("\(Text.timer.string(language)) \(Reminders.clock(until: ends, at: now))")
            key += "-timer"
        }
        return lines.isEmpty ? nil : (key, lines.joined(separator: "\n"))
    }

    public static func message(for reminder: Reminder, language: Language) -> String {
        switch reminder {
        case .focusEnded: return Text.focusEndedMessage.string(language)
        case .breakEnded: return Text.breakEndedMessage.string(language)
        case .stretch: return Text.stretchMessage.string(language)
        case .timerEnded: return Text.timerEndedMessage.string(language)
        }
    }
}
