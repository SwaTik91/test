import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/progress/progress_service.dart';
import 'package:midgard_outpost/run/combat_math.dart';

void main() {
  test('vit increases max hp', () {
    final weak = HeroProgress.createNew(HeroClassId.paladin);
    final tank = _allocateStat(
      weak.copyWith(unspentStatPoints: 5),
      StatId.vit,
      5,
    );

    expect(CombatMath.maxHp(tank), greaterThan(CombatMath.maxHp(weak)));
    expect(CombatMath.maxHp(tank), 200);
  });

  test('int increases max sp', () {
    final novice = HeroProgress.createNew(HeroClassId.mage);
    final caster = _allocateStat(
      novice.copyWith(unspentStatPoints: 3),
      StatId.intStat,
      3,
    );

    expect(CombatMath.maxSp(caster), 82);
  });

  test('agi increases move speed', () {
    final slow = HeroProgress.createNew(HeroClassId.archer);
    final quick = _allocateStat(
      slow.copyWith(unspentStatPoints: 2),
      StatId.agi,
      2,
    );

    expect(
      CombatMath.moveSpeed(quick),
      greaterThan(CombatMath.moveSpeed(slow)),
    );
    // +5 px/s per AGI (was +18); keeps early-game pace, slows late scaling.
    expect(CombatMath.moveSpeed(slow), 195);
    expect(CombatMath.moveSpeed(quick), 205);
  });

  test('physical classes use str and dex for basic attack damage', () {
    final archer = HeroProgress.createNew(HeroClassId.archer).copyWith(
      stats: {
        ...HeroProgress.createNew(HeroClassId.archer).stats,
        StatId.str: 3,
        StatId.dex: 4,
      },
    );

    expect(CombatMath.basicAttackDamage(archer), 15);
  });

  test('mage uses int for basic attack damage', () {
    final mage = HeroProgress.createNew(HeroClassId.mage).copyWith(
      stats: {
        ...HeroProgress.createNew(HeroClassId.mage).stats,
        StatId.intStat: 4,
      },
    );

    expect(CombatMath.basicAttackDamage(mage), 17);
  });
}

HeroProgress _allocateStat(HeroProgress hero, StatId stat, int times) {
  var current = hero;
  for (var i = 0; i < times; i += 1) {
    current = ProgressService.allocateStat(current, stat);
  }
  return current;
}
