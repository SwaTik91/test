import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/balance.dart';
import 'package:midgard_outpost/run/systems/spawn_system.dart';

void main() {
  test('boss due at interval', () {
    expect(SpawnSystem.shouldSpawnBoss(0), isFalse);
    expect(
      SpawnSystem.shouldSpawnBoss(Balance.bossEveryDistancePx - 1),
      isFalse,
    );
    expect(SpawnSystem.shouldSpawnBoss(Balance.bossEveryDistancePx), isTrue);
  });

  test('chest due at interval', () {
    expect(SpawnSystem.shouldSpawnChest(0), isFalse);
    expect(
      SpawnSystem.shouldSpawnChest(Balance.chestEveryDistancePx - 1),
      isFalse,
    );
    expect(SpawnSystem.shouldSpawnChest(Balance.chestEveryDistancePx), isTrue);
    expect(
      SpawnSystem.shouldSpawnChest(Balance.chestEveryDistancePx * 2),
      isTrue,
    );
  });

  test('milestone helpers align with balance intervals', () {
    for (var i = 1; i <= 3; i += 1) {
      final chestDistance = Balance.chestEveryDistancePx * i;
      final bossDistance = Balance.bossEveryDistancePx * i;
      expect(SpawnSystem.shouldSpawnChest(chestDistance), isTrue);
      expect(SpawnSystem.shouldSpawnBoss(bossDistance), isTrue);
      expect(
        SpawnSystem.shouldSpawnChest(chestDistance + 1),
        isFalse,
      );
    }
  });

  test('biome switches to forest', () {
    expect(SpawnSystem.biomeAt(0), Biome.fields);
    expect(SpawnSystem.biomeAt(7999), Biome.fields);
    expect(SpawnSystem.biomeAt(8000), Biome.forest);
  });
}
