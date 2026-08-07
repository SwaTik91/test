import '../../content/balance.dart';
import '../../content/monsters.dart';

export '../../content/monsters.dart' show Biome;

extension BiomeLabel on Biome {
  String get label {
    return switch (this) {
      Biome.fields => 'Поля',
      Biome.forest => 'Лес',
    };
  }
}

class SpawnSystem {
  SpawnSystem._();

  static const int forestStartsAtDistancePx = 8000;

  static bool shouldSpawnBoss(num distancePx) =>
      _isDue(distancePx, Balance.bossEveryDistancePx);

  static bool shouldSpawnChest(num distancePx) =>
      _isDue(distancePx, Balance.chestEveryDistancePx);

  static Biome biomeAt(num distancePx) {
    if (distancePx >= forestStartsAtDistancePx) {
      return Biome.forest;
    }
    return Biome.fields;
  }

  static bool _isDue(num distancePx, int intervalPx) {
    if (distancePx <= 0) {
      return false;
    }
    return distancePx % intervalPx == 0;
  }
}
