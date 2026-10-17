import 'dart:math';

/// A rectangle in logical pixels, relative to the pet window.
class LogicalRect {
  const LogicalRect(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  @override
  bool operator ==(Object other) =>
      other is LogicalRect && other.left == left && other.top == top && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'LogicalRect($left, $top, $width, $height)';
}

/// A rectangle in physical screen pixels: left, top, right, bottom.
class ScreenRect {
  const ScreenRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  bool contains(int x, int y) => x >= left && x < right && y >= top && y < bottom;

  @override
  bool operator ==(Object other) =>
      other is ScreenRect && other.left == left && other.top == top && other.right == right && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'ScreenRect($left, $top, $right, $bottom)';
}

/// Where the pet window goes and where the pet sits inside it.
class PetLayout {
  const PetLayout({required this.window, required this.pet});

  /// Physical frame of the window.
  final ScreenRect window;

  /// Logical rectangle inside the window.
  final LogicalRect pet;

  /// `petOrigin` is the pet's physical top-left corner. Sizes are logical; `scale` converts them for this monitor.
  static PetLayout compute({
    required double scale,
    required Point<int> petOrigin,
    required double petWidth,
    required double petHeight,
  }) {
    int px(double logical) => (logical * scale).round();
    return PetLayout(
      window: ScreenRect(petOrigin.x, petOrigin.y, petOrigin.x + px(petWidth), petOrigin.y + px(petHeight)),
      pet: LogicalRect(0, 0, petWidth, petHeight),
    );
  }
}
