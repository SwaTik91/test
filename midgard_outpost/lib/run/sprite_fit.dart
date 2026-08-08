import 'package:flame/components.dart';

/// Aspect-preserving sprite sizing helpers for run actors and VFX.
abstract final class SpriteFit {
  /// Fits [srcSize] into a fixed [targetHeight] without horizontal squash.
  static Vector2 containHeight({
    required Vector2 srcSize,
    required double targetHeight,
  }) {
    if (srcSize.y <= 0) {
      return Vector2.all(targetHeight);
    }
    final aspect = srcSize.x / srcSize.y;
    return Vector2(targetHeight * aspect, targetHeight);
  }

  /// Fits [srcSize] into a square [targetExtent] box (contain).
  static Vector2 containSquare({
    required Vector2 srcSize,
    required double targetExtent,
  }) {
    if (srcSize.x <= 0 || srcSize.y <= 0) {
      return Vector2.all(targetExtent);
    }
    final scale = targetExtent / srcSize.y > targetExtent / srcSize.x
        ? targetExtent / srcSize.x
        : targetExtent / srcSize.y;
    return Vector2(srcSize.x * scale, srcSize.y * scale);
  }
}
