import XCTest
@testable import DesklingCore

final class RemindersTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_000_000)

    private func at(minutes: Double) -> Date {
        start.addingTimeInterval(minutes * 60)
    }

    func testFocusThenBreakThenStop() {
        var reminders = Reminders()
        reminders.startFocus(at: start)
        XCTAssertEqual(reminders.phase, .focus)
        XCTAssertEqual(reminders.tick(at: at(minutes: 24.9)), [])
        XCTAssertEqual(reminders.tick(at: at(minutes: 25)), [.focusEnded])
        XCTAssertEqual(reminders.phase, .rest)
        XCTAssertEqual(reminders.phaseEnds, at(minutes: 30))
        XCTAssertEqual(reminders.tick(at: at(minutes: 30)), [.breakEnded])
        XCTAssertNil(reminders.phase)
        XCTAssertEqual(reminders.tick(at: at(minutes: 60)), [])
    }

    func testBreakStartsWhenTheEndIsNoticedAfterSleep() {
        var reminders = Reminders()
        reminders.startFocus(at: start)
        XCTAssertEqual(reminders.tick(at: at(minutes: 90)), [.focusEnded])
        XCTAssertEqual(reminders.phaseEnds, at(minutes: 95))
    }

    func testStopFocusCancelsBothPhases() {
        var reminders = Reminders()
        reminders.startFocus(at: start)
        reminders.stopFocus()
        XCTAssertEqual(reminders.tick(at: at(minutes: 30)), [])
    }

    func testStretchFiresEveryHour() {
        var reminders = Reminders()
        reminders.setStretch(enabled: true, at: start)
        XCTAssertTrue(reminders.stretchEnabled)
        XCTAssertEqual(reminders.tick(at: at(minutes: 59)), [])
        XCTAssertEqual(reminders.tick(at: at(minutes: 60)), [.stretch])
        XCTAssertEqual(reminders.tick(at: at(minutes: 119)), [])
        XCTAssertEqual(reminders.tick(at: at(minutes: 120)), [.stretch])
        reminders.setStretch(enabled: false, at: at(minutes: 121))
        XCTAssertEqual(reminders.tick(at: at(minutes: 500)), [])
    }

    func testStretchWaitsForFocusToFinish() {
        var reminders = Reminders()
        reminders.setStretch(enabled: true, at: start)
        reminders.startFocus(at: at(minutes: 50))
        XCTAssertEqual(reminders.tick(at: at(minutes: 70)), [])
        XCTAssertEqual(reminders.tick(at: at(minutes: 75)), [.focusEnded])
        XCTAssertEqual(reminders.tick(at: at(minutes: 80)), [.breakEnded])
        XCTAssertEqual(reminders.nextStretch, at(minutes: 140))
        XCTAssertEqual(reminders.tick(at: at(minutes: 140)), [.stretch])
    }

    func testTimerFiresOnce() {
        var reminders = Reminders()
        reminders.startTimer(minutes: 10, at: start)
        XCTAssertEqual(reminders.tick(at: at(minutes: 9)), [])
        XCTAssertEqual(reminders.tick(at: at(minutes: 10)), [.timerEnded])
        XCTAssertNil(reminders.timerEnds)
        XCTAssertEqual(reminders.tick(at: at(minutes: 20)), [])
    }

    func testCancelTimer() {
        var reminders = Reminders()
        reminders.startTimer(minutes: 5, at: start)
        reminders.cancelTimer()
        XCTAssertEqual(reminders.tick(at: at(minutes: 10)), [])
    }

    func testRemindersCanFireTogether() {
        var reminders = Reminders()
        reminders.startFocus(at: start)
        reminders.startTimer(minutes: 25, at: start)
        XCTAssertEqual(reminders.tick(at: at(minutes: 25)), [.focusEnded, .timerEnded])
    }

    func testMinutesLeftRoundsUp() {
        XCTAssertEqual(Reminders.minutesLeft(until: at(minutes: 25), at: start), 25)
        XCTAssertEqual(Reminders.minutesLeft(until: at(minutes: 24.1), at: start), 25)
        XCTAssertEqual(Reminders.minutesLeft(until: at(minutes: 0.2), at: start), 1)
        XCTAssertEqual(Reminders.minutesLeft(until: start, at: at(minutes: 1)), 1)
    }
}

final class TimerInputTests: XCTestCase {
    func testParseMinutes() {
        XCTAssertEqual(Reminders.parseMinutes("25"), 25)
        XCTAssertEqual(Reminders.parseMinutes(" 90 "), 90)
        XCTAssertEqual(Reminders.parseMinutes("1:30"), 90)
        XCTAssertEqual(Reminders.parseMinutes("0:05"), 5)
        XCTAssertEqual(Reminders.parseMinutes("1h 30m"), 90)
        XCTAssertEqual(Reminders.parseMinutes("2h"), 120)
        XCTAssertEqual(Reminders.parseMinutes("45 min"), 45)
        XCTAssertEqual(Reminders.parseMinutes("1시간 30분"), 90)
        XCTAssertEqual(Reminders.parseMinutes("45분"), 45)
        XCTAssertEqual(Reminders.parseMinutes("24:00"), 24 * 60)
    }

    func testRejectsBadLengths() {
        for text in ["", "0", "-5", "abc", "1:60", "24:01", "1441", "1.5", "분", "30 seconds", "1:"] {
            XCTAssertNil(Reminders.parseMinutes(text), text)
        }
    }

    func testClock() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(Reminders.clock(until: now.addingTimeInterval(245), at: now), "4:05")
        XCTAssertEqual(Reminders.clock(until: now.addingTimeInterval(244.2), at: now), "4:05")
        XCTAssertEqual(Reminders.clock(until: now.addingTimeInterval(3723), at: now), "1:02:03")
        XCTAssertEqual(Reminders.clock(until: now, at: now.addingTimeInterval(5)), "0:00")
    }

    func testBubbleShowsAlertBeforeCountdown() {
        let now = Date(timeIntervalSince1970: 0)
        var reminders = Reminders()
        XCTAssertNil(PetPresentation.bubble(alert: nil, reminders: reminders, showCountdown: true, now: now, language: .korean))
        reminders.startFocus(at: now)
        reminders.startTimer(minutes: 5, at: now)
        let countdown = PetPresentation.bubble(alert: nil, reminders: reminders, showCountdown: true, now: now, language: .korean)
        XCTAssertEqual(countdown?.text, "집중 25:00\n타이머 5:00")
        let later = PetPresentation.bubble(alert: nil, reminders: reminders, showCountdown: true, now: now.addingTimeInterval(1), language: .korean)
        XCTAssertEqual(later?.key, countdown?.key)
        XCTAssertNil(PetPresentation.bubble(alert: nil, reminders: reminders, showCountdown: false, now: now, language: .korean))
        let alert = PetPresentation.bubble(alert: .timerEnded, reminders: reminders, showCountdown: false, now: now, language: .english)
        XCTAssertEqual(alert?.text, "Your timer is up.")
        XCTAssertNotEqual(alert?.key, countdown?.key)
    }
}
