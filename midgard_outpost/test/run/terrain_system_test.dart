import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/balance.dart';
import 'package:midgard_outpost/run/components/player_component.dart';
import 'package:midgard_outpost/run/systems/terrain_system.dart';

void main() {
  test('no hazards in the safe start zone', () {
    final terrain = TerrainSystem()..ensureUntil(2000);
    expect(terrain.features, isNotEmpty);
    expect(
      terrain.features.every((f) => f.startX >= TerrainSystem.safeUntilX),
      isTrue,
    );
  });

  test('generates both pits and obstacles that a running jump can clear', () {
    final terrain = TerrainSystem()..ensureUntil(4000);
    expect(terrain.features.any((f) => f.isPit), isTrue);
    expect(terrain.features.any((f) => f.isObstacle), isTrue);

    final jumpDist = PlayerComponent.jumpDistance(190);
    final jumpH = PlayerComponent.jumpHeight;
    for (final feature in terrain.features) {
      if (feature.isPit) {
        expect(feature.width, lessThan(jumpDist * 0.85));
        expect(feature.width, greaterThan(jumpDist * 0.45));
      } else {
        expect(feature.height, lessThan(jumpH * 0.75));
        expect(feature.height, greaterThan(24));
      }
    }
  });

  test('hazards do not overlap chest or boss markers', () {
    final terrain = TerrainSystem()..ensureUntil(9000);
    for (final feature in terrain.features) {
      expect(TerrainSystem.isReserved(feature.startX, feature.width), isFalse);
    }
    expect(TerrainSystem.isReserved(Balance.chestEveryDistancePx.toDouble(), 40), isTrue);
    expect(TerrainSystem.isReserved(Balance.bossEveryDistancePx.toDouble(), 40), isTrue);
  });

  test('floor drops inside a pit and stays at ground on solid dirt', () {
    final terrain = TerrainSystem()..ensureUntil(2000);
    final pit = terrain.features.firstWhere((f) => f.isPit);
    const groundY = 500.0;
    expect(
      terrain.floorY(x: pit.centerX, y: groundY, groundY: groundY),
      closeTo(groundY + TerrainSystem.pitDepth, 0.01),
    );
    expect(terrain.floorY(x: 200, y: groundY, groundY: groundY), groundY);
  });

  test('pit damage is a noticeable fraction of max HP', () {
    expect(TerrainSystem.pitDamage(100), 16);
    expect(TerrainSystem.pitDamage(50), 12);
  });
}
