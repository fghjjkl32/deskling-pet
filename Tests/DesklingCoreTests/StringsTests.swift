import XCTest
@testable import DesklingCore

final class StringsTests: XCTestCase {
    func testLanguageFollowsFirstPreferredLanguage() {
        XCTAssertEqual(Language.current(preferred: ["ko-KR", "en-US"]), .korean)
        XCTAssertEqual(Language.current(preferred: ["en-US", "ko-KR"]), .english)
        XCTAssertEqual(Language.current(preferred: ["ja-JP"]), .english)
        XCTAssertEqual(Language.current(preferred: []), .english)
    }

    func testEveryTextHasBothLanguages() {
        for text in Text.allCases {
            XCTAssertFalse(text.string(.korean).isEmpty, "\(text)")
            XCTAssertFalse(text.string(.english).isEmpty, "\(text)")
        }
    }

    func testKoreanSentencesUseFormalPolite() {
        for text in Text.allCases {
            let korean = text.string(.korean)
            guard korean.hasSuffix(".") else { continue }
            XCTAssertTrue(korean.hasSuffix("니다."), "\(text): \(korean)")
        }
    }

    func testPose() {
        XCTAssertEqual(PetPresentation.pose(isWalking: false), .idle)
        XCTAssertEqual(PetPresentation.pose(isWalking: true), .walk)
        XCTAssertEqual(PetPresentation.pose(isWalking: true, isHappy: true), .happy)
        XCTAssertEqual(PetPresentation.pose(isWalking: false, isHappy: true, isHeld: true, isFalling: true), .drag)
        XCTAssertEqual(PetPresentation.pose(isWalking: false, isHappy: true, isFalling: true), .fall)
        XCTAssertEqual(PetPresentation.pose(isWalking: true, isAlerting: true, isFocusing: true), .waiting)
        XCTAssertEqual(PetPresentation.pose(isWalking: true, isFocusing: true), .working)
        XCTAssertEqual(PetPresentation.pose(isWalking: false, isHappy: true, isAlerting: true), .happy)
    }

    func testNumberIsFilledIn() {
        XCTAssertEqual(Text.focusStatus.string(.korean, 23), "집중하는 중: 23분 남음")
        XCTAssertEqual(Text.cancelTimer.string(.english, 4), "Cancel Timer (4 min left)")
    }

    func testEveryReminderHasAMessage() {
        for reminder in [Reminder.focusEnded, .breakEnded, .stretch, .timerEnded] {
            XCTAssertFalse(PetPresentation.message(for: reminder, language: .korean).isEmpty)
        }
    }
}
