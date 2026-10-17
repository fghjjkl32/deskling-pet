import Foundation

public enum Language: Equatable {
    case korean, english

    public static func current(preferred: [String] = Locale.preferredLanguages) -> Language {
        preferred.first?.hasPrefix("ko") == true ? .korean : .english
    }
}

public enum Text: CaseIterable {
    case skin, defaultSkin, openSkinsFolder
    case size, sizeSmall, sizeMedium, sizeLarge
    case hidePet, showPet, launchAtLogin, quit
    case startFocus, stopFocus, focusStatus, breakStatus
    case timer, timerMinutes, cancelTimer, stretchReminder
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
        .defaultSkin: ("기본 펫", "Default pet"),
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

    public static func message(for reminder: Reminder, language: Language) -> String {
        switch reminder {
        case .focusEnded: return Text.focusEndedMessage.string(language)
        case .breakEnded: return Text.breakEndedMessage.string(language)
        case .stretch: return Text.stretchMessage.string(language)
        case .timerEnded: return Text.timerEndedMessage.string(language)
        }
    }
}
