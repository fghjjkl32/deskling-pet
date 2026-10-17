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

    /// The longest timer that can be typed in, in minutes.
    public static let maxTimerMinutes = 24 * 60

    /// Reads a timer length typed by the user: minutes ("25"), hours and minutes ("1:30"),
    /// or with units ("1h 30m", "1시간 30분", "45분"). Returns minutes, or `nil` when the text
    /// is not a length between one minute and 24 hours.
    public static func parseMinutes(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var minutes: Int?
        if let number = Int(trimmed) {
            minutes = number
        } else if let colon = trimmed.firstIndex(of: ":") {
            if let hours = Int(trimmed[..<colon]), let rest = Int(trimmed[trimmed.index(after: colon)...]), (0..<60).contains(rest) {
                minutes = hours * 60 + rest
            }
        } else {
            minutes = minutesWithUnits(trimmed)
        }
        guard let minutes, (1...maxTimerMinutes).contains(minutes) else { return nil }
        return minutes
    }

    private static func minutesWithUnits(_ text: String) -> Int? {
        let units: [(names: [String], minutes: Int)] = [(["시간", "hours", "hour", "hrs", "hr", "h"], 60), (["분", "minutes", "minute", "mins", "min", "m"], 1)]
        var total = 0
        var rest = Substring(text)
        var matched = false
        while !rest.isEmpty {
            rest = rest.drop { $0 == " " }
            let digits = rest.prefix { $0.isASCII && $0.isNumber }
            guard let value = Int(digits) else { return nil }
            rest = rest.dropFirst(digits.count).drop { $0 == " " }
            guard let unit = units.first(where: { unit in unit.names.contains { rest.hasPrefix($0) } }),
                  let name = unit.names.first(where: { rest.hasPrefix($0) })
            else { return nil }
            total += value * unit.minutes
            rest = rest.dropFirst(name.count)
            matched = true
        }
        return matched ? total : nil
    }

    /// Time left until `end` as a clock: "4:05", or "1:02:03" from an hour up.
    public static func clock(until end: Date, at now: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(now).rounded(.up)))
        let (hours, minutes, rest) = (seconds / 3600, seconds / 60 % 60, seconds % 60)
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }

    /// Whole minutes left until `end`, rounded up and never less than one.
    public static func minutesLeft(until end: Date, at now: Date) -> Int {
        max(1, Int((end.timeIntervalSince(now) / 60).rounded(.up)))
    }
}
