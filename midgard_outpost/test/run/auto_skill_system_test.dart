import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/run/combat_math.dart';
import 'package:midgard_outpost/run/systems/auto_skill_system.dart';

void main() {
  test('skill does not cast without enough SP', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    sys.sp = 0;

    final events = sys.tick(1.0, enemiesInRange: 1);

    expect(events, isEmpty);
  });

  test('auto skill casts when SP and enemies are available', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    final initialSp = sys.sp;

    final events = sys.tick(1.0, enemiesInRange: 1);

    expect(events, hasLength(1));
    expect(events.single.skillId, 'fire_bolt');
    expect(events.single.kind, SkillCastKind.auto);
    expect(events.single.damage, greaterThan(0));
    expect(sys.sp, lessThan(initialSp));
  });

  test('SP regeneration accumulates fractional frame deltas', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: const {},
      upgrades: const {},
    );
    sys.sp = 0;

    for (var i = 0; i < 60; i += 1) {
      sys.tick(0.016, enemiesInRange: 0);
    }

    expect(sys.sp, greaterThan(0));
  });

  test('auto skill does not spend SP when enemies are outside skill range', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.paladin,
      ranks: {'shield_bash': 1},
      upgrades: const {},
    );
    final initialSp = sys.sp;

    final events = sys.tick(0, enemiesInRange: 1, enemyDistances: const [120]);

    expect(events, isEmpty);
    expect(sys.sp, initialSp);
  });

  test('auto skill respects cooldown', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: {'double_strafe': 1},
      upgrades: const {},
    );

    expect(sys.tick(1.0, enemiesInRange: 1), hasLength(1));
    expect(sys.tick(0.1, enemiesInRange: 1), isEmpty);
    expect(sys.tick(10.0, enemiesInRange: 1), hasLength(1));
  });

  test('ultimate respects cooldown', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: {'arrow_shower': 1},
      upgrades: const {},
    );

    expect(sys.tryUltimate(), isTrue);
    expect(sys.tryUltimate(), isFalse);
  });

  test('owned skill upgrade increases matching skill damage', () {
    final base = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    final upgraded = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {'fire_bolt__white_heat'},
    );

    final baseDamage = base.tick(1.0, enemiesInRange: 1).single.damage;
    final upgradedDamage = upgraded.tick(1.0, enemiesInRange: 1).single.damage;

    expect(upgradedDamage, greaterThan(baseDamage));
  });

  test('owned skill upgrades added after construction affect damage', () {
    final upgrades = <String>{};
    final base = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    final dynamic = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: upgrades,
    );

    upgrades.add('fire_bolt__white_heat');

    final baseDamage = base.tick(1.0, enemiesInRange: 1).single.damage;
    final dynamicDamage = dynamic.tick(1.0, enemiesInRange: 1).single.damage;

    expect(dynamicDamage, greaterThan(baseDamage));
  });

  test('passive ranks increase combat crit chance', () {
    final base = HeroProgress.createNew(HeroClassId.archer);
    final withPassive = base.copyWith(skillRanks: {'eagle_eye': 2});

    expect(
      CombatMath.critChance(withPassive),
      greaterThan(CombatMath.critChance(base)),
    );
  });
}
