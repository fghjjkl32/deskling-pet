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

  /// Whole minutes left until `end`, rounded up and never less than one.
  static int minutesLeft(DateTime end, DateTime now) =>
      max(1, (end.difference(now).inMicroseconds / Duration.microsecondsPerMinute).ceil());
}
