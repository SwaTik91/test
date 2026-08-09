import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/run_layout.dart';

void main() {
  group('RunLayout at 720p reference', () {
    late RunLayout layout;

    setUp(() {
      layout = RunLayout(RunLayout.referenceHeight);
    });

    test('ground line at 72% height', () {
      expect(layout.groundY, closeTo(720 * RunLayout.groundTopFraction, 0.01));
      expect(layout.groundY, 518.4);
    });

    test('ground tile fills lower band to viewport bottom with bleed', () {
      expect(
        layout.groundStripHeight,
        closeTo(720 * (1 - RunLayout.groundTopFraction), 0.01),
      );
      expect(
        layout.groundTileHeight,
        closeTo(layout.groundStripHeight + RunLayout.groundBottomBleedPx, 0.01),
      );
      expect(layout.groundTileWidth, layout.groundTileHeight);
      expect(layout.groundY + layout.groundStripHeight, closeTo(720, 0.01));
    });

    test('actor heights match spec bands', () {
      expect(layout.playerSize.y / 720, closeTo(0.30, 0.001));
      expect(layout.mobSize().y / 720, closeTo(0.21, 0.001));
      expect(layout.mobSize(isBoss: true).y / 720, closeTo(0.44, 0.001));
      expect(layout.chestSize.y / 720, closeTo(0.14, 0.001));
    });

    test('mob spawn spacing scales with actor width', () {
      expect(layout.mobSpawnSpacing, greaterThanOrEqualTo(480));
      expect(layout.mobSpawnSpacing, greaterThan(layout.mobSize().x * 2));
    });

    test('backdrop cover size fills viewport height', () {
      const srcW = 1536.0;
      const srcH = 1024.0 * RunLayout.backdropSkyFraction;
      final cover = layout.backdropCoverSize(
        regionWidth: 1280,
        regionHeight: layout.viewportHeight,
        srcSize: Vector2(srcW, srcH),
      );
      expect(cover.x, greaterThanOrEqualTo(1280));
      expect(cover.y, greaterThanOrEqualTo(layout.viewportHeight));
    });

    test('backdrop viewport bounds cover full region with bleed', () {
      const srcW = 1536.0;
      const srcH = 1024.0 * RunLayout.backdropSkyFraction;
      const width = 1280.0;
      final cover = layout.backdropCoverSize(
        regionWidth: width,
        regionHeight: layout.viewportHeight,
        srcSize: Vector2(srcW, srcH),
      );
      final bounds = layout.backdropViewportBounds(
        size: cover,
        viewportWidth: width,
        viewportHeight: layout.viewportHeight,
      );
      expect(bounds.left, lessThanOrEqualTo(0));
      expect(bounds.top, lessThanOrEqualTo(0));
      expect(bounds.right, greaterThanOrEqualTo(width));
      expect(bounds.bottom, greaterThanOrEqualTo(layout.viewportHeight));
    });

    test('backdrop cover size fills viewport on narrow landscape widths', () {
      const srcW = 1536.0;
      const srcH = 1024.0 * RunLayout.backdropSkyFraction;
      for (final height in [500.0, 800.0]) {
        final layout = RunLayout(height);
        final cover = layout.backdropCoverSize(
          regionWidth: 414,
          regionHeight: layout.viewportHeight,
          srcSize: Vector2(srcW, srcH),
        );
        expect(cover.x, greaterThanOrEqualTo(414));
        expect(cover.y, greaterThanOrEqualTo(layout.viewportHeight));
      }
    });

    test('ground top fraction matches camera anchor target', () {
      expect(RunLayout.groundTopFraction, 0.72);
      expect(layout.groundY / layout.viewportHeight, closeTo(0.72, 0.001));
    });

    test('ground world span extends left of player start for centered camera', () {
      const viewportWidth = 1280.0;
      const playerX = 120.0;
      final span = layout.groundWorldSpan(
        cameraCenterX: playerX,
        viewportWidth: viewportWidth,
      );
      expect(span.left, lessThan(0));
      expect(span.right, greaterThan(playerX));
      expect(span.left, lessThan(playerX - viewportWidth / 2));
    });

    test('ground tile count covers viewport at player start', () {
      const viewportWidth = 1280.0;
      const playerX = 120.0;
      final span = layout.groundWorldSpan(
        cameraCenterX: playerX,
        viewportWidth: viewportWidth,
      );
      final startX = layout.groundTileStartX(span.left);
      final count = layout.groundTileCountForSpan(
        worldLeft: span.left,
        worldRight: span.right,
      );
      final endX = startX + count * layout.groundTileWidth;
      expect(startX, lessThanOrEqualTo(playerX - viewportWidth / 2));
      expect(endX, greaterThanOrEqualTo(playerX + viewportWidth / 2));
    });
  });

  group('RunLayout across viewport heights', () {
    test('ground line stays at 72% for 500px and 800px', () {
      for (final height in [500.0, 800.0]) {
        final layout = RunLayout(height);
        expect(layout.groundY, closeTo(height * RunLayout.groundTopFraction, 0.01));
        expect(
          layout.groundY + layout.groundStripHeight,
          closeTo(height, 0.01),
        );
      }
    });

    test('ground tile span covers viewport at 500px and 800px heights', () {
      const viewportWidth = 1280.0;
      const playerX = 120.0;
      for (final height in [500.0, 800.0]) {
        final layout = RunLayout(height);
        final span = layout.groundWorldSpan(
          cameraCenterX: playerX,
          viewportWidth: viewportWidth,
          extraLeftMarginTiles: 1,
        );
        final startX = layout.groundTileStartX(span.left);
        final count = layout.groundTileCountForSpan(
          worldLeft: span.left,
          worldRight: span.right,
        );
        final endX = startX + count * layout.groundTileWidth;
        expect(startX, lessThan(playerX - viewportWidth / 2));
        expect(endX, greaterThan(playerX + viewportWidth / 2));
      }
    });

    test('ground span from visible rect extends extra margin on the left', () {
      final layout = RunLayout(720);
      final span = layout.groundWorldSpanFromVisibleRect(
        visibleWorldRect: const Rect.fromLTWH(0, 0, 1280, 720),
      );
      expect(span.left, lessThan(-layout.groundTileWidth));
      expect(span.right, greaterThan(1280));
    });
  });
}
