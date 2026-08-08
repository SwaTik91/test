import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

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

  /// Fits every frame in [animation] to [targetHeight] and returns the widest
  /// width so render size stays constant across ticker frames of one anim.
  static Vector2 stableContainHeight({
    required SpriteAnimation animation,
    required double targetHeight,
  }) {
    if (animation.frames.isEmpty) {
      return Vector2.all(targetHeight);
    }
    var maxWidth = 0.0;
    for (final frame in animation.frames) {
      final contained = containHeight(
        srcSize: frame.sprite.srcSize,
        targetHeight: targetHeight,
      );
      if (contained.x > maxWidth) {
        maxWidth = contained.x;
      }
    }
    return Vector2(maxWidth, targetHeight);
  }
}
