import Foundation

public enum Reminder: Equatable {
    case focusEnded, breakEnded, stretch, timerEnded
}

/// The focus timer, the hourly stretch reminder and a one-off timer.
/// The clock is passed in, so the app ticks it once a second and tests drive it directly.
public struct Reminders {
    public static let focusLength: TimeInterval = 25 * 60
    public static let breakLength: TimeInterval = 5 * 60
    public static let stretchInterval: TimeInterval = 60 * 60
    /// Minutes offered in the Timer menu.
    public static let timerChoices = [5, 10, 15, 30, 60]

    public enum Phase: Equatable {
        case focus, rest
    }

    public private(set) var phase: Phase?
    public private(set) var phaseEnds: Date?
    public private(set) var timerEnds: Date?
    public private(set) var nextStretch: Date?

    public init() {}

    public var stretchEnabled: Bool { nextStretch != nil }

    public mutating func startFocus(at now: Date) {
        phase = .focus
        phaseEnds = now.addingTimeInterval(Self.focusLength)
    }

    public mutating func stopFocus() {
        phase = nil
        phaseEnds = nil
    }

    public mutating func startTimer(minutes: Int, at now: Date) {
        timerEnds = now.addingTimeInterval(TimeInterval(minutes * 60))
    }

    public mutating func cancelTimer() {
        timerEnds = nil
    }

    public mutating func setStretch(enabled: Bool, at now: Date) {
        nextStretch = enabled ? now.addingTimeInterval(Self.stretchInterval) : nil
    }

    /// Advances to `now` and returns the reminders that came due, in the order they fired.
    /// A phase that ended while the computer slept starts its break from `now`, not from when it ended.
    public mutating func tick(at now: Date) -> [Reminder] {
        var due: [Reminder] = []
        let wasBusy = phase != nil
        if let ends = phaseEnds, now >= ends {
            switch phase {
            case .focus:
                phase = .rest
                phaseEnds = now.addingTimeInterval(Self.breakLength)
                due.append(.focusEnded)
            case .rest, nil:
                stopFocus()
                due.append(.breakEnded)
            }
        }
        if nextStretch != nil {
            // Focus sessions bring their own break, so the stretch reminder waits until they are over.
            if wasBusy {
                nextStretch = now.addingTimeInterval(Self.stretchInterval)
            } else if let next = nextStretch, now >= next {
                nextStretch = now.addingTimeInterval(Self.stretchInterval)
                due.append(.stretch)
            }
        }
        if let ends = timerEnds, now >= ends {
            timerEnds = nil
            due.append(.timerEnded)
        }
        return due
    }

    /// Whole minutes left until `end`, rounded up and never less than one.
    public static func minutesLeft(until end: Date, at now: Date) -> Int {
        max(1, Int((end.timeIntervalSince(now) / 60).rounded(.up)))
    }
}
