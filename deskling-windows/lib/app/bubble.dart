import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The speech bubble above the pet: a reminder, or the countdown of the focus session and the timer.
class Bubble {
  static const fontSize = 14.0;
  static const maxTextWidth = 260.0;
  static const padding = 12.0;
  static const cornerRadius = 10.0;

  static const _light = (background: Color(0xFFFFFFFF), border: Color(0x33000000), text: Color(0xFF1F1F1F));
  static const _dark = (background: Color(0xFF2B2B2B), border: Color(0x33FFFFFF), text: Color(0xFFF2F2F2));

  static bool get _isDark => ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  static TextSpan span(String text) => TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.3,
          color: (_isDark ? _dark : _light).text,
          // Fixed-width digits keep the countdown from jittering as it ticks.
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );

  /// The bubble's logical size, padding included.
  static Size measure(String text) {
    final painter = TextPainter(text: span(text), textDirection: TextDirection.ltr)..layout(maxWidth: maxTextWidth);
    final size = Size(painter.width.ceilToDouble() + padding * 2, painter.height.ceilToDouble() + padding * 2);
    painter.dispose();
    return size;
  }
}

class BubbleBox extends StatelessWidget {
  const BubbleBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Bubble._isDark ? Bubble._dark : Bubble._light;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(Bubble.cornerRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Bubble.padding),
        child: RichText(text: Bubble.span(text), textDirection: TextDirection.ltr),
      ),
    );
  }
}
