import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/run/combat_math.dart';
import 'package:midgard_outpost/run/systems/auto_skill_system.dart';

void main() {
  test('tick never auto-casts skills', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    final initialSp = sys.sp;

    final events = sys.tick(1.0, enemiesInRange: 1);

    expect(events, isEmpty);
    expect(sys.sp, initialSp);
  });

  test('manual skill does not cast without enough SP', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    sys.sp = 0;

    expect(sys.tryCastSkill('fire_bolt', enemiesInRange: 1), isNull);
  });

  test('manual skill casts when SP and enemies are available', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.mage,
      ranks: {'fire_bolt': 1},
      upgrades: const {},
    );
    final initialSp = sys.sp;

    final event = sys.tryCastSkill('fire_bolt', enemiesInRange: 1);

    expect(event, isNotNull);
    expect(event!.skillId, 'fire_bolt');
    expect(event.kind, SkillCastKind.auto);
    expect(event.damage, greaterThan(0));
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

  test('manual skill does not spend SP when enemies are outside skill range', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.paladin,
      ranks: {'shield_bash': 1},
      upgrades: const {},
    );
    final initialSp = sys.sp;

    final event = sys.tryCastSkill(
      'shield_bash',
      enemiesInRange: 1,
      enemyDistances: const [120],
    );

    expect(event, isNull);
    expect(sys.sp, initialSp);
  });

  test('manual skill respects cooldown', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: {'double_strafe': 1},
      upgrades: const {},
    );

    expect(sys.tryCastSkill('double_strafe', enemiesInRange: 1), isNotNull);
    expect(sys.tryCastSkill('double_strafe', enemiesInRange: 1), isNull);
    sys.tick(10.0, enemiesInRange: 0);
    expect(sys.tryCastSkill('double_strafe', enemiesInRange: 1), isNotNull);
  });

  test('ultimate respects cooldown via tryCastSkill', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: {'arrow_shower': 1},
      upgrades: const {},
    );

    expect(sys.tryUltimate(), isTrue);
    expect(sys.tryUltimate(), isFalse);
    expect(sys.cooldownRemaining('arrow_shower'), greaterThan(0));
  });

  test('archer castable skills include all four combat skills', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: const {},
      upgrades: const {},
    );
    final ids = sys.castableSkills.map((s) => s.id).toList();
    expect(
      ids,
      containsAll(['double_strafe', 'wind_arrow', 'concentrate', 'arrow_shower']),
    );
    expect(ids, isNot(contains('eagle_eye')));
  });

  test('each ranked archer combat skill can be cast manually', () {
    const projectileSkills = [
      'double_strafe',
      'wind_arrow',
      'arrow_shower',
    ];
    for (final skillId in projectileSkills) {
      final sys = AutoSkillSystem(
        classId: HeroClassId.archer,
        ranks: {skillId: 1},
        upgrades: const {},
      );
      final event = sys.tryCastSkill(skillId, enemiesInRange: 3);
      expect(event, isNotNull, reason: skillId);
      expect(event!.skillId, skillId);
      expect(event.damage, greaterThan(0));
      expect(event.projectile, isTrue, reason: '$skillId should fly');
    }
  });

  test('concentrate casts without enemies and applies no projectile damage', () {
    final sys = AutoSkillSystem(
      classId: HeroClassId.archer,
      ranks: {'concentrate': 2},
      upgrades: const {},
    );

    final event = sys.tryCastSkill('concentrate', enemiesInRange: 0);

    expect(event, isNotNull);
    expect(event!.skillId, 'concentrate');
    expect(event.damage, 0);
    expect(event.projectile, isFalse);
    expect(AutoSkillSystem.concentrateStatBonus(2), 3);
  });

  test('trap is absent from archer skill catalog', () {
    final ids = SkillsCatalog.forClass(HeroClassId.archer).map((s) => s.id);
    expect(ids, isNot(contains('trap')));
    expect(ids, contains('concentrate'));
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

    final baseDamage = base.tryCastSkill('fire_bolt', enemiesInRange: 1)!.damage;
    final upgradedDamage =
        upgraded.tryCastSkill('fire_bolt', enemiesInRange: 1)!.damage;

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

    final baseDamage = base.tryCastSkill('fire_bolt', enemiesInRange: 1)!.damage;
    final dynamicDamage =
        dynamic.tryCastSkill('fire_bolt', enemiesInRange: 1)!.damage;

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

  test('damage roll can crit', () {
    final hero = HeroProgress.createNew(HeroClassId.archer)
        .copyWith(skillRanks: {'eagle_eye': 10});
    var sawCrit = false;
    for (var i = 0; i < 80; i++) {
      final roll = CombatMath.rollBasicAttackDamage(
        hero,
        rng: null,
      );
      if (roll.isCrit) {
        sawCrit = true;
        break;
      }
    }
    expect(sawCrit, isTrue);
  });
}
