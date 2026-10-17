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
