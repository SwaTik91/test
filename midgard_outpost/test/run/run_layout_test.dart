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

    test('ground tile fills lower 28% without squash', () {
      expect(
        layout.groundTileHeight,
        closeTo(720 * RunLayout.groundTileHeightFraction, 0.01),
      );
      expect(layout.groundTileWidth, layout.groundTileHeight);
      expect(layout.groundY + layout.groundTileHeight, closeTo(720, 0.01));
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

    test('backdrop cover size fills sky region', () {
      const srcW = 1536.0;
      const srcH = 1024.0 * RunLayout.backdropSkyFraction;
      final cover = layout.backdropCoverSize(
        regionWidth: 1280,
        srcSize: Vector2(srcW, srcH),
      );
      expect(cover.x, greaterThanOrEqualTo(1280));
      expect(cover.y, greaterThanOrEqualTo(layout.groundY));
    });
  });
}
