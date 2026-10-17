import 'package:deskling_pet/app/bubble.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('measure includes padding and wraps at the maximum width', () {
    final short = Bubble.measure('done');
    expect(short.width, greaterThan(Bubble.padding * 2));
    expect(short.width, lessThan(Bubble.maxTextWidth));
    final long = Bubble.measure('a ' * 400);
    expect(long.width, lessThanOrEqualTo(Bubble.maxTextWidth + Bubble.padding * 2));
    expect(long.height, greaterThan(short.height * 3));
  });

  testWidgets('the bubble box renders its text', (tester) async {
    await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: Center(child: BubbleBox(text: 'Your timer is up.'))));
    expect(find.byType(RichText), findsOneWidget);
    expect(find.text('Your timer is up.', findRichText: true), findsOneWidget);
  });
}
