import 'package:deskling_pet/core/bubble_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);
  DateTime at(int ms) => start.add(Duration(milliseconds: ms));

  test('clicks within half a second of the bubble appearing are ignored', () {
    final guard = BubbleGuard()..update('alert-stretch', start);
    expect(guard.shownKey, 'alert-stretch');
    expect(guard.acceptsClick(at(499)), false);
    expect(guard.acceptsClick(at(500)), true);
  });

  test('a new key restarts the guard, the same key counting down does not', () {
    final guard = BubbleGuard()..update('countdown-focus', start);
    guard.update('countdown-focus', at(400));
    expect(guard.acceptsClick(at(500)), true);
    guard.update('alert-focusEnded', at(1000));
    expect(guard.acceptsClick(at(1499)), false);
    expect(guard.acceptsClick(at(1500)), true);
  });

  test('a bubble shown again after hiding is guarded again, and a hidden one takes no clicks', () {
    final guard = BubbleGuard()..update('countdown-timer', start);
    guard.update(null, at(1000));
    expect(guard.shownKey, isNull);
    expect(guard.acceptsClick(at(2000)), false);
    guard.update('countdown-timer', at(3000));
    expect(guard.acceptsClick(at(3200)), false);
    expect(guard.acceptsClick(at(3500)), true);
  });
}
