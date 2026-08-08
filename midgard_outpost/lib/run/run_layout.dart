import 'dart:math' as math;

import 'dart:ui';

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

  /// Extra viewport bleed so cover-fit backdrops never expose [Game.backgroundColor].
  static const double backdropBleedPx = 2;

  static const double playerHeightFraction = 0.30;
  static const double mobHeightFraction = 0.21;
  static const double bossHeightFraction = 0.44;
  static const double chestHeightFraction = 0.14;

  final double viewportHeight;

  double get groundY => viewportHeight * groundTopFraction;

  double get groundTileHeight => viewportHeight * groundTileHeightFraction;

  /// Square ground tiles — no horizontal squash of 256×256 art.
  double get groundTileWidth => groundTileHeight;

  /// World-space span the live ground strip must cover around the camera center.
  ({double left, double right}) groundWorldSpan({
    required double cameraCenterX,
    required double viewportWidth,
    double marginTiles = 2,
    double extraLeftMarginTiles = 0,
  }) {
    final width = viewportWidth > 0 ? viewportWidth : 1280;
    final margin = groundTileWidth * marginTiles;
    final extraLeft = groundTileWidth * extraLeftMarginTiles;
    return (
      left: cameraCenterX - width / 2 - margin - extraLeft,
      right: cameraCenterX + width / 2 + margin,
    );
  }

  /// World-space span from the camera's visible rect plus tile margins.
  ({double left, double right}) groundWorldSpanFromVisibleRect({
    required Rect visibleWorldRect,
    double marginTiles = 2,
    double extraLeftMarginTiles = 1,
  }) {
    final margin = groundTileWidth * marginTiles;
    final extraLeft = groundTileWidth * extraLeftMarginTiles;
    return (
      left: visibleWorldRect.left - margin - extraLeft,
      right: visibleWorldRect.right + margin,
    );
  }

  /// Left edge of the first ground tile for a world span.
  double groundTileStartX(double worldLeft) {
    final tileWidth = groundTileWidth;
    return (worldLeft / tileWidth).floor() * tileWidth;
  }

  /// Tile count to cover [worldLeft, worldRight] without gaps.
  int groundTileCountForSpan({
    required double worldLeft,
    required double worldRight,
  }) {
    final tileWidth = groundTileWidth;
    final startX = groundTileStartX(worldLeft);
    final endX = worldRight + tileWidth;
    return ((endX - startX) / tileWidth).ceil();
  }

  Vector2 get playerSize => _squareSize(playerHeightFraction);

  Vector2 mobSize({bool isBoss = false}) =>
      _squareSize(isBoss ? bossHeightFraction : mobHeightFraction);

  Vector2 get chestSize => _squareSize(chestHeightFraction);

  /// Horizontal spacing between mob spawns — scales with actor size.
  double get mobSpawnSpacing =>
      math.max(480, mobSize().x * 2.8).toDouble();

  /// Vertical tolerance for combat targeting vs scaled actors.
  double get verticalCombatReach => playerSize.y * 0.55;

  /// Cover-fit size for sky-only backdrop on the camera backdrop layer.
  ///
  /// Must cover the full viewport height so the scaled crop always reaches the
  /// viewport bottom; the live ground strip paints over the lower band in world
  /// space.
  Vector2 backdropCoverSize({
    required double regionWidth,
    required double regionHeight,
    required Vector2 srcSize,
    double bleedPx = backdropBleedPx,
  }) {
    final scale = math.max(
      regionWidth / srcSize.x,
      regionHeight / srcSize.y,
    );
    return Vector2(
      srcSize.x * scale + bleedPx * 2,
      srcSize.y * scale + bleedPx * 2,
    );
  }

  /// Viewport-space bounds for a bottom-left anchored backdrop.
  ({double left, double top, double right, double bottom}) backdropViewportBounds({
    required Vector2 size,
    required double viewportWidth,
    required double viewportHeight,
    double bleedPx = backdropBleedPx,
  }) {
    return (
      left: -bleedPx,
      top: viewportHeight - size.y,
      right: -bleedPx + size.x,
      bottom: viewportHeight + bleedPx,
    );
  }

  Vector2 _squareSize(double heightFraction) {
    final height = viewportHeight * heightFraction;
    return Vector2(height, height);
  }
}
