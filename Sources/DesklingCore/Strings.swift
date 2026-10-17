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
    case close, loginItemFailed, missingResources

    public func string(_ language: Language) -> String {
        let pair = Self.table[self]!
        return language == .korean ? pair.0 : pair.1
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
        .close: ("닫기", "Close"),
        .loginItemFailed: ("로그인 항목을 바꾸지 못했습니다.", "Could not change the login item."),
        .missingResources: ("기본 펫 그림을 찾을 수 없습니다.", "The default pet images are missing."),
    ]
}

public enum PetPresentation {
    /// How long the pet stays happy after a click, in seconds.
    public static let happyDuration = 2.0

    public static func pose(isWalking: Bool, isHappy: Bool = false, isHeld: Bool = false, isFalling: Bool = false) -> PetPose {
        if isHeld { return .drag }
        if isFalling { return .fall }
        if isHappy { return .happy }
        return isWalking ? .walk : .idle
    }
}
