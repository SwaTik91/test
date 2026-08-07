enum Biome { fields, forest }

class MonsterSpec {
  const MonsterSpec({
    required this.biome,
    required this.isBoss,
    required this.maxHp,
    required this.touchDamage,
    required this.baseXp,
    required this.jobXp,
    required this.gold,
    required this.tempXp,
    required this.moveSpeed,
    required this.width,
    required this.height,
  });

  final Biome biome;
  final bool isBoss;
  final int maxHp;
  final int touchDamage;
  final int baseXp;
  final int jobXp;
  final int gold;
  final int tempXp;
  final double moveSpeed;
  final double width;
  final double height;
}

class MonstersCatalog {
  MonstersCatalog._();

  static MonsterSpec forDistance({
    required double distancePx,
    required Biome biome,
    required bool isBoss,
  }) {
    final wave = (distancePx / 500).floor();
    final biomeHp = biome == Biome.forest ? 16 : 0;
    final biomeDamage = biome == Biome.forest ? 3 : 0;
    final biomeReward = biome == Biome.forest ? 2 : 0;

    final baseHp = 18 + (wave * 3) + biomeHp;
    final baseDamage = 18 + wave + biomeDamage;
    final baseXp = 5 + wave + biomeReward;
    final jobXp = 3 + (wave ~/ 2) + biomeReward;
    final gold = 4 + (wave ~/ 3) + biomeReward;

    if (!isBoss) {
      return MonsterSpec(
        biome: biome,
        isBoss: false,
        maxHp: baseHp,
        touchDamage: baseDamage,
        baseXp: baseXp,
        jobXp: jobXp,
        gold: gold,
        tempXp: 20 + wave,
        moveSpeed: 50 + (wave * 2),
        width: 40,
        height: 44,
      );
    }

    return MonsterSpec(
      biome: biome,
      isBoss: true,
      maxHp: baseHp * 10,
      touchDamage: baseDamage * 2,
      baseXp: baseXp * 4,
      jobXp: jobXp * 4,
      gold: gold * 5,
      tempXp: 100,
      moveSpeed: 36 + wave.toDouble(),
      width: 72,
      height: 76,
    );
  }
}
