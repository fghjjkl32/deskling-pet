/// Ignores clicks that arrive just after the bubble appears or changes, so one already on its way
/// cannot dismiss a bubble nobody has seen.
class BubbleGuard {
  static const clickGuard = Duration(milliseconds: 500);

  String? _shown;
  DateTime _ignoreClicksUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// Called with the text on screen, or null when the bubble is hidden.
  void update(String? text, DateTime now) {
    if (text != null && text != _shown) _ignoreClicksUntil = now.add(clickGuard);
    _shown = text;
  }

  bool acceptsClick(DateTime now) => _shown != null && !now.isBefore(_ignoreClicksUntil);
}
