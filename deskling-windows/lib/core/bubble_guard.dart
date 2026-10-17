/// Ignores clicks that arrive just after a new bubble appears, so one already on its way
/// cannot dismiss a bubble nobody has seen. A countdown that only changes its text keeps taking clicks.
class BubbleGuard {
  static const clickGuard = Duration(milliseconds: 500);

  String? _shownKey;
  DateTime _ignoreClicksUntil = DateTime.fromMillisecondsSinceEpoch(0);

  /// The kind of bubble on screen, or null when it is hidden.
  String? get shownKey => _shownKey;

  /// Called with the key of the bubble on screen, or null when the bubble is hidden.
  void update(String? key, DateTime now) {
    if (key != null && key != _shownKey) _ignoreClicksUntil = now.add(clickGuard);
    _shownKey = key;
  }

  bool acceptsClick(DateTime now) => _shownKey != null && !now.isBefore(_ignoreClicksUntil);
}
