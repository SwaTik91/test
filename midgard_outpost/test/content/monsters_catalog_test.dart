import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/balance.dart';
import 'package:midgard_outpost/content/monsters.dart';

void main() {
  test('boss kinds rotate in canon order', () {
    expect(MonstersCatalog.bossKindAt(0), MonsterKind.bossDemon);
    expect(MonstersCatalog.bossKindAt(1), MonsterKind.bossSpider);
    expect(MonstersCatalog.bossKindAt(3), MonsterKind.bossGolem);
    expect(MonstersCatalog.bossKindAt(4), MonsterKind.bossDemon);
  });

  test('kindForDistance picks boss kind by boss index', () {
    expect(
      MonstersCatalog.kindForDistance(
        distancePx: Balance.bossEveryDistancePx.toDouble(),
        biome: Biome.fields,
        isBoss: true,
      ),
      MonsterKind.bossDemon,
    );
    expect(
      MonstersCatalog.kindForDistance(
        distancePx: (Balance.bossEveryDistancePx * 2).toDouble(),
        biome: Biome.forest,
        isBoss: true,
      ),
      MonsterKind.bossSpider,
    );
  });

  test('kindForDistance rotates non-boss mobs by wave and biome', () {
    final fieldsEarly = MonstersCatalog.kindForDistance(
      distancePx: 0,
      biome: Biome.fields,
      isBoss: false,
    );
    final forestEarly = MonstersCatalog.kindForDistance(
      distancePx: 0,
      biome: Biome.forest,
      isBoss: false,
    );
    expect(fieldsEarly, isNot(forestEarly));

    final spec = MonstersCatalog.forDistance(
      distancePx: 520,
      biome: Biome.fields,
      isBoss: false,
    );
    expect(spec.kind, isNot(MonsterKind.bossDemon));
    expect(spec.isBoss, isFalse);
  });

  test('ranged mobs expose attack range and interval', () {
    final bee = MonstersCatalog.forDistance(
      distancePx: 600,
      biome: Biome.fields,
      isBoss: false,
    );
    if (bee.kind == MonsterKind.bee) {
      expect(bee.attackRange, greaterThan(0));
      expect(bee.attackInterval, greaterThan(0));
    }

  final rangedKinds = MonsterKind.values.where((k) => k.isRanged);
    for (final kind in rangedKinds) {
      final spec = MonstersCatalog.forDistance(
        distancePx: 0,
        biome: Biome.fields,
        isBoss: false,
      );
      if (spec.kind == kind) {
        expect(spec.attackRange, greaterThan(0));
        expect(spec.attackInterval, greaterThan(0));
        break;
      }
    }
  });
}
