import 'dart:math' as math;

import 'package:flame/components.dart';

/// Viewport-relative layout for the side-scroller run (spec §3).
class RunLayout {
  RunLayout(this.viewportHeight);

  static const double referenceHeight = 720;

  /// Feet contact line — top of the live ground strip.
  static const double groundTopFraction = 0.72;

  /// Live ground tile visual height (fills contact line → bottom).
  static const double groundTileHeightFraction = 0.28;

  /// Backdrop source crop — sky/scenery only (excludes baked floor in art).
  static const double backdropSkyFraction = 0.72;

  static const double playerHeightFraction = 0.30;
  static const double mobHeightFraction = 0.21;
  static const double bossHeightFraction = 0.44;
  static const double chestHeightFraction = 0.14;

  final double viewportHeight;

  double get groundY => viewportHeight * groundTopFraction;

  double get groundTileHeight => viewportHeight * groundTileHeightFraction;

  /// Square ground tiles — no horizontal squash of 256×256 art.
  double get groundTileWidth => groundTileHeight;

  Vector2 get playerSize => _squareSize(playerHeightFraction);

  Vector2 mobSize({bool isBoss = false}) =>
      _squareSize(isBoss ? bossHeightFraction : mobHeightFraction);

  Vector2 get chestSize => _squareSize(chestHeightFraction);

  /// Horizontal spacing between mob spawns — scales with actor size.
  double get mobSpawnSpacing =>
      math.max(480, mobSize().x * 2.8).toDouble();

  /// Vertical tolerance for combat targeting vs scaled actors.
  double get verticalCombatReach => playerSize.y * 0.55;

  /// Cover-fit size for sky-only backdrop anchored at [groundY].
  Vector2 backdropCoverSize({
    required double regionWidth,
    required Vector2 srcSize,
  }) {
    final scale = math.max(
      regionWidth / srcSize.x,
      groundY / srcSize.y,
    );
    return Vector2(srcSize.x * scale, srcSize.y * scale);
  }

  Vector2 _squareSize(double heightFraction) {
    final height = viewportHeight * heightFraction;
    return Vector2(height, height);
  }
}
