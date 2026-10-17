import 'package:deskling_pet/core/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

final start = DateTime.fromMillisecondsSinceEpoch(1000000 * 1000, isUtc: true);

DateTime at(double minutes) => start.add(Duration(microseconds: (minutes * Duration.microsecondsPerMinute).round()));

void main() {
  test('focus, then break, then stop', () {
    final reminders = Reminders()..startFocus(start);
    expect(reminders.phase, FocusPhase.focus);
    expect(reminders.tick(at(24.9)), isEmpty);
    expect(reminders.tick(at(25)), [Reminder.focusEnded]);
    expect(reminders.phase, FocusPhase.rest);
    expect(reminders.phaseEnds, at(30));
    expect(reminders.tick(at(30)), [Reminder.breakEnded]);
    expect(reminders.phase, isNull);
    expect(reminders.tick(at(60)), isEmpty);
  });

  test('the break starts when the end is noticed after sleep', () {
    final reminders = Reminders()..startFocus(start);
    expect(reminders.tick(at(90)), [Reminder.focusEnded]);
    expect(reminders.phaseEnds, at(95));
  });

  test('stop focus cancels both phases', () {
    final reminders = Reminders()
      ..startFocus(start)
      ..stopFocus();
    expect(reminders.tick(at(30)), isEmpty);
  });

  test('stretch fires every hour', () {
    final reminders = Reminders()..setStretch(enabled: true, now: start);
    expect(reminders.stretchEnabled, true);
    expect(reminders.tick(at(59)), isEmpty);
    expect(reminders.tick(at(60)), [Reminder.stretch]);
    expect(reminders.tick(at(119)), isEmpty);
    expect(reminders.tick(at(120)), [Reminder.stretch]);
    reminders.setStretch(enabled: false, now: at(121));
    expect(reminders.tick(at(500)), isEmpty);
  });

  test('stretch waits for focus to finish', () {
    final reminders = Reminders()
      ..setStretch(enabled: true, now: start)
      ..startFocus(at(50));
    expect(reminders.tick(at(70)), isEmpty);
    expect(reminders.tick(at(75)), [Reminder.focusEnded]);
    expect(reminders.tick(at(80)), [Reminder.breakEnded]);
    expect(reminders.nextStretch, at(140));
    expect(reminders.tick(at(140)), [Reminder.stretch]);
  });

  test('the timer fires once', () {
    final reminders = Reminders()..startTimer(10, start);
    expect(reminders.tick(at(9)), isEmpty);
    expect(reminders.tick(at(10)), [Reminder.timerEnded]);
    expect(reminders.timerEnds, isNull);
    expect(reminders.tick(at(20)), isEmpty);
  });

  test('cancel timer', () {
    final reminders = Reminders()
      ..startTimer(5, start)
      ..cancelTimer();
    expect(reminders.tick(at(10)), isEmpty);
  });

  test('reminders can fire together', () {
    final reminders = Reminders()
      ..startFocus(start)
      ..startTimer(25, start);
    expect(reminders.tick(at(25)), [Reminder.focusEnded, Reminder.timerEnded]);
  });

  test('minutes left rounds up', () {
    expect(Reminders.minutesLeft(at(25), start), 25);
    expect(Reminders.minutesLeft(at(24.1), start), 25);
    expect(Reminders.minutesLeft(at(0.2), start), 1);
    expect(Reminders.minutesLeft(start, at(1)), 1);
  });
}
