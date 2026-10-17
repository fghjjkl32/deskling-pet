import 'package:deskling_pet/core/reminders.dart';
import 'package:deskling_pet/core/strings.dart';
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

  group('timer input', () {
    test('parse minutes', () {
      expect(Reminders.parseMinutes('25'), 25);
      expect(Reminders.parseMinutes(' 90 '), 90);
      expect(Reminders.parseMinutes('1:30'), 90);
      expect(Reminders.parseMinutes('0:05'), 5);
      expect(Reminders.parseMinutes('1h 30m'), 90);
      expect(Reminders.parseMinutes('2h'), 120);
      expect(Reminders.parseMinutes('45 min'), 45);
      expect(Reminders.parseMinutes('1시간 30분'), 90);
      expect(Reminders.parseMinutes('45분'), 45);
      expect(Reminders.parseMinutes('24:00'), 24 * 60);
    });

    test('rejects bad lengths', () {
      for (final text in ['', '0', '-5', 'abc', '1:60', '24:01', '1441', '1.5', '분', '30 seconds', '1:', '0x10']) {
        expect(Reminders.parseMinutes(text), isNull, reason: text);
      }
    });

    test('clock', () {
      final now = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      expect(Reminders.clock(now.add(const Duration(seconds: 245)), now), '4:05');
      expect(Reminders.clock(now.add(const Duration(milliseconds: 244200)), now), '4:05');
      expect(Reminders.clock(now.add(const Duration(seconds: 3723)), now), '1:02:03');
      expect(Reminders.clock(now, now.add(const Duration(seconds: 5))), '0:00');
    });

    test('the bubble shows the alert before the countdown', () {
      final now = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final reminders = Reminders();
      ({String key, String text})? bubble(Reminder? alert, {bool showCountdown = true, DateTime? at, Language language = Language.korean}) =>
          PetPresentation.bubble(
              alert: alert, reminders: reminders, showCountdown: showCountdown, now: at ?? now, language: language);
      expect(bubble(null), isNull);
      reminders
        ..startFocus(now)
        ..startTimer(5, now);
      final countdown = bubble(null);
      expect(countdown?.text, '집중 25:00\n타이머 5:00');
      expect(countdown?.key, 'countdown-focus-timer');
      expect(bubble(null, at: now.add(const Duration(seconds: 1)))?.key, countdown?.key);
      expect(bubble(null, showCountdown: false), isNull);
      final alert = bubble(Reminder.timerEnded, showCountdown: false, language: Language.english);
      expect(alert?.text, 'Your timer is up.');
      expect(alert?.key, 'alert-timerEnded');
      reminders.tick(now.add(const Duration(minutes: 25)));
      expect(bubble(null, at: now.add(const Duration(minutes: 25)), language: Language.english),
          (key: 'countdown-rest', text: 'Break 5:00'));
    });
  });
}
