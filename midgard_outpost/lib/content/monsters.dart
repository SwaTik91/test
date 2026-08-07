import '../art/art_atlas.dart';
import 'balance.dart';

enum Biome { fields, forest }

enum MonsterKind {
  slime,
  lunatic,
  wolf,
  mushroom,
  bee,
  crab,
  ghost,
  plant,
  bossDemon,
  bossSpider,
  bossUndead,
  bossGolem,
}

extension MonsterKindSprites on MonsterKind {
  String get spritePath => switch (this) {
        MonsterKind.slime => ArtAtlas.mobSlime,
        MonsterKind.lunatic => ArtAtlas.mobLunatic,
        MonsterKind.wolf => ArtAtlas.mobWolf,
        MonsterKind.mushroom => ArtAtlas.mobMushroom,
        MonsterKind.bee => ArtAtlas.mobBee,
        MonsterKind.crab => ArtAtlas.mobCrab,
        MonsterKind.ghost => ArtAtlas.mobGhost,
        MonsterKind.plant => ArtAtlas.mobPlant,
        MonsterKind.bossDemon => ArtAtlas.bossDemon,
        MonsterKind.bossSpider => ArtAtlas.bossSpider,
        MonsterKind.bossUndead => ArtAtlas.bossUndead,
        MonsterKind.bossGolem => ArtAtlas.bossGolem,
      };

  bool get isBoss => switch (this) {
        MonsterKind.bossDemon ||
        MonsterKind.bossSpider ||
        MonsterKind.bossUndead ||
        MonsterKind.bossGolem =>
          true,
        _ => false,
      };
}

class MonsterSpec {
  const MonsterSpec({
    required this.kind,
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

  final MonsterKind kind;
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

  static const _mobRotation = [
    MonsterKind.slime,
    MonsterKind.lunatic,
    MonsterKind.wolf,
    MonsterKind.mushroom,
    MonsterKind.bee,
    MonsterKind.crab,
    MonsterKind.ghost,
    MonsterKind.plant,
  ];

  static const _bossRotation = [
    MonsterKind.bossDemon,
    MonsterKind.bossSpider,
    MonsterKind.bossUndead,
    MonsterKind.bossGolem,
  ];

  static MonsterKind bossKindAt(int index) {
    return _bossRotation[index % _bossRotation.length];
  }

  static MonsterKind kindForDistance({
    required double distancePx,
    required Biome biome,
    required bool isBoss,
  }) {
    if (isBoss) {
      final bossIndex = (distancePx / Balance.bossEveryDistancePx).floor() - 1;
      return bossKindAt(bossIndex < 0 ? 0 : bossIndex);
    }

    final wave = (distancePx / 500).floor();
    final biomeOffset = biome == Biome.forest ? 4 : 0;
    final spawnSlot = (distancePx / 430).floor();
    return _mobRotation[(wave + biomeOffset + spawnSlot) % _mobRotation.length];
  }

  static MonsterSpec forDistance({
    required double distancePx,
    required Biome biome,
    required bool isBoss,
  }) {
    final kind = kindForDistance(
      distancePx: distancePx,
      biome: biome,
      isBoss: isBoss,
    );
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
        kind: kind,
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
      kind: kind,
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
