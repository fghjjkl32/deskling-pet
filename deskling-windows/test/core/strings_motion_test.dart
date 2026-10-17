import 'package:deskling_pet/core/motion.dart';
import 'package:deskling_pet/core/skin.dart';
import 'package:deskling_pet/core/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('strings', () {
    test('language follows the first preferred language', () {
      expect(Language.current(['ko-KR', 'en-US']), Language.korean);
      expect(Language.current(['ko_KR']), Language.korean);
      expect(Language.current(['en-US', 'ko-KR']), Language.english);
      expect(Language.current(['ja-JP']), Language.english);
      expect(Language.current([]), Language.english);
    });

    test('every text has both languages and Korean sentences end politely', () {
      for (final text in Txt.values) {
        expect(text.korean, isNotEmpty, reason: '$text');
        expect(text.english, isNotEmpty, reason: '$text');
        if (text.korean.endsWith('.')) expect(text.korean, endsWith('니다.'), reason: '$text');
      }
    });

    test('held beats falling, falling beats happy, happy beats walking', () {
      expect(PetPresentation.pose(isWalking: false), PetPose.idle);
      expect(PetPresentation.pose(isWalking: true), PetPose.walk);
      expect(PetPresentation.pose(isWalking: true, isHappy: true), PetPose.happy);
      expect(PetPresentation.pose(isWalking: false, isHeld: true, isFalling: true, isHappy: true), PetPose.drag);
      expect(PetPresentation.pose(isWalking: false, isFalling: true, isHappy: true), PetPose.fall);
    });
  });

  group('walk', () {
    const bounds = Span(0, 1000);

    test('rests, then walks toward the target', () {
      final model = WalkModel(100);
      model.step(0.5, bounds, random: (_) => 500);
      expect(model.isWalking, false);
      model.step(0.6, bounds, random: (_) => 500);
      expect(model.isWalking, true);
      expect(model.facingLeft, false);
      model.step(1, bounds, random: (_) => 500);
      expect(model.x, closeTo(100 + WalkModel.speed, 0.001));
    });

    test('face turns the pet', () {
      final model = WalkModel(100)..face(left: true);
      expect(model.facingLeft, true);
      model.face(left: false);
      expect(model.facingLeft, false);
    });

    test('faces left when the target is behind', () {
      final model = WalkModel(800);
      model.step(2, bounds, random: (_) => 200);
      model.step(1, bounds, random: (_) => 200);
      expect(model.facingLeft, true);
      expect(model.x, closeTo(800 - WalkModel.speed, 0.001));
    });

    test('arrives exactly and rests', () {
      final model = WalkModel(100);
      model.step(2, bounds, random: (_) => 110);
      model.step(1, bounds, random: (_) => 4);
      expect(model.x, 110);
      expect(model.isWalking, false);
      model.step(3.9, bounds, random: (_) => 900);
      expect(model.isWalking, false);
      model.step(0.2, bounds, random: (_) => 900);
      expect(model.isWalking, true);
    });

    test('never leaves the bounds', () {
      final model = WalkModel(500);
      for (var i = 0; i < 5000; i++) {
        model.step(1 / 30, bounds);
        expect(bounds.contains(model.x), true);
      }
    });

    test('a position outside the bounds is pulled back', () {
      final model = WalkModel(5000);
      model.step(0, bounds, random: (_) => 0);
      expect(model.x, 1000);
      model.clamp(const Span(0, 300));
      expect(model.x, 300);
    });

    test('a target outside shrunk bounds is pulled back', () {
      final model = WalkModel(100);
      model.step(2, bounds, random: (_) => 900);
      for (var i = 0; i < 600; i++) {
        model.step(0.1, const Span(0, 300), random: (_) => 5);
      }
      expect(model.x, lessThanOrEqualTo(300));
    });

    test('zero-width bounds stay still', () {
      final model = WalkModel(50);
      for (var i = 0; i < 100; i++) {
        model.step(1, const Span(50, 50), random: (_) => 50);
      }
      expect(model.x, 50);
      expect(model.isWalking, false);
    });

    test('place and stop cancel walking', () {
      final model = WalkModel(100);
      model.step(2, bounds, random: (_) => 900);
      expect(model.isWalking, true);
      model.stop();
      expect(model.isWalking, false);
      model.step(2, bounds, random: (_) => 900);
      model.place(400);
      expect(model.x, 400);
      expect(model.isWalking, false);
    });
  });

  group('fall', () {
    test('descends without exceeding the maximum speed', () {
      final model = FallModel(1000);
      var previous = model.height;
      for (var i = 0; i < 100 && !model.hasLanded; i++) {
        model.step(0.1);
        expect(model.height, lessThan(previous));
        expect(previous - model.height, lessThanOrEqualTo(FallModel.maxSpeed * 0.1 + 0.001));
        previous = model.height;
      }
    });

    test('starts slower than the maximum speed', () {
      final model = FallModel(1000)..step(0.1);
      expect(model.height, closeTo(1000 - FallModel.acceleration * 0.1 * 0.1, 0.001));
      expect(model.hasLanded, false);
    });

    test('lands exactly on the floor', () {
      final model = FallModel(5);
      for (var i = 0; i < 100 && !model.hasLanded; i++) {
        model.step(0.1);
      }
      expect(model.hasLanded, true);
      expect(model.height, 0);
    });

    test('lands at once when already on or below the floor', () {
      final model = FallModel(-60)..step(0);
      expect(model.hasLanded, true);
      expect(model.height, 0);
    });
  });
}
