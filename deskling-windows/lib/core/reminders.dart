import 'dart:math';

enum Reminder { focusEnded, breakEnded, stretch, timerEnded }

enum FocusPhase { focus, rest }

/// The focus timer, the hourly stretch reminder and a one-off timer.
/// The clock is passed in, so the app ticks it once a second and tests drive it directly.
class Reminders {
  static const focusLength = Duration(minutes: 25);
  static const breakLength = Duration(minutes: 5);
  static const stretchInterval = Duration(hours: 1);

  /// Minutes offered in the Timer menu.
  static const timerChoices = [5, 10, 15, 30, 60];

  /// The longest timer the user may type in.
  static const maxTimerMinutes = 24 * 60;

  FocusPhase? _phase;
  DateTime? _phaseEnds;
  DateTime? _timerEnds;
  DateTime? _nextStretch;

  FocusPhase? get phase => _phase;
  DateTime? get phaseEnds => _phaseEnds;
  DateTime? get timerEnds => _timerEnds;
  DateTime? get nextStretch => _nextStretch;

  bool get stretchEnabled => _nextStretch != null;

  void startFocus(DateTime now) {
    _phase = FocusPhase.focus;
    _phaseEnds = now.add(focusLength);
  }

  void stopFocus() {
    _phase = null;
    _phaseEnds = null;
  }

  void startTimer(int minutes, DateTime now) {
    _timerEnds = now.add(Duration(minutes: minutes));
  }

  void cancelTimer() {
    _timerEnds = null;
  }

  void setStretch({required bool enabled, required DateTime now}) {
    _nextStretch = enabled ? now.add(stretchInterval) : null;
  }

  /// Advances to `now` and returns the reminders that came due, in the order they fired.
  /// A phase that ended while the computer slept starts its break from `now`, not from when it ended.
  List<Reminder> tick(DateTime now) {
    final due = <Reminder>[];
    final wasBusy = _phase != null;
    final ends = _phaseEnds;
    if (ends != null && !now.isBefore(ends)) {
      if (_phase == FocusPhase.focus) {
        _phase = FocusPhase.rest;
        _phaseEnds = now.add(breakLength);
        due.add(Reminder.focusEnded);
      } else {
        stopFocus();
        due.add(Reminder.breakEnded);
      }
    }
    final next = _nextStretch;
    if (next != null) {
      // Focus sessions bring their own break, so the stretch reminder waits until they are over.
      if (wasBusy) {
        _nextStretch = now.add(stretchInterval);
      } else if (!now.isBefore(next)) {
        _nextStretch = now.add(stretchInterval);
        due.add(Reminder.stretch);
      }
    }
    final timer = _timerEnds;
    if (timer != null && !now.isBefore(timer)) {
      _timerEnds = null;
      due.add(Reminder.timerEnded);
    }
    return due;
  }

  /// Reads a timer length typed by the user: minutes ("25"), hours and minutes ("1:30"),
  /// or with units ("1h 30m", "1시간 30분", "45분"). Returns minutes, or null when the text
  /// is not a length between one minute and 24 hours.
  static int? parseMinutes(String text) {
    final trimmed = text.trim().toLowerCase();
    int? minutes;
    final number = _integer(trimmed);
    final colon = trimmed.indexOf(':');
    if (number != null) {
      minutes = number;
    } else if (colon >= 0) {
      final hours = _integer(trimmed.substring(0, colon));
      final rest = _integer(trimmed.substring(colon + 1));
      if (hours != null && rest != null && rest >= 0 && rest < 60) minutes = hours * 60 + rest;
    } else {
      minutes = _minutesWithUnits(trimmed);
    }
    if (minutes == null || minutes < 1 || minutes > maxTimerMinutes) return null;
    return minutes;
  }

  /// A whole number with an optional sign and nothing else, like Swift's `Int(String)`.
  static int? _integer(String text) => RegExp(r'^[+-]?[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;

  static const _units = [
    (names: ['시간', 'hours', 'hour', 'hrs', 'hr', 'h'], minutes: 60),
    (names: ['분', 'minutes', 'minute', 'mins', 'min', 'm'], minutes: 1),
  ];

  static int? _minutesWithUnits(String text) {
    var total = 0;
    var rest = text;
    var matched = false;
    while (rest.isNotEmpty) {
      rest = rest.replaceFirst(RegExp('^ +'), '');
      final digits = RegExp('^[0-9]*').firstMatch(rest)![0]!;
      final value = int.tryParse(digits);
      if (value == null) return null;
      rest = rest.substring(digits.length).replaceFirst(RegExp('^ +'), '');
      String? name;
      int? unitMinutes;
      for (final unit in _units) {
        for (final candidate in unit.names) {
          if (rest.startsWith(candidate)) {
            name = candidate;
            unitMinutes = unit.minutes;
            break;
          }
        }
        if (name != null) break;
      }
      if (name == null || unitMinutes == null) return null;
      total += value * unitMinutes;
      rest = rest.substring(name.length);
      matched = true;
    }
    return matched ? total : null;
  }

  /// Time left until `end` as a clock: "4:05", or "1:02:03" from an hour up.
  static String clock(DateTime end, DateTime now) {
    final seconds = max(0, (end.difference(now).inMicroseconds / Duration.microsecondsPerSecond).ceil());
    final (hours, minutes, rest) = (seconds ~/ 3600, seconds ~/ 60 % 60, seconds % 60);
    String two(int value) => value.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:${two(minutes)}:${two(rest)}' : '$minutes:${two(rest)}';
  }

  /// Whole minutes left until `end`, rounded up and never less than one.
  static int minutesLeft(DateTime end, DateTime now) =>
      max(1, (end.difference(now).inMicroseconds / Duration.microsecondsPerMinute).ceil());
}
