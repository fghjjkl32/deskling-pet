import 'dart:math';

import 'package:deskling_pet/core/layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the window is the pet', () {
    final layout = PetLayout.compute(scale: 1.5, petOrigin: const Point(100, 896), petWidth: 96, petHeight: 96);
    expect(layout.window, const ScreenRect(100, 896, 244, 1040));
    expect(layout.pet, const LogicalRect(0, 0, 96, 96));
  });

  test('scale converts logical sizes to pixels', () {
    final layout = PetLayout.compute(scale: 1.25, petOrigin: const Point(-1000, 920), petWidth: 64, petHeight: 96);
    expect(layout.window, const ScreenRect(-1000, 920, -920, 1040));
    expect(layout.pet.bottom, closeTo(layout.window.height / 1.25, 0.001));
  });
}
