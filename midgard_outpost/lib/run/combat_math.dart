import '../core/ids.dart';
import '../progress/hero_progress.dart';
import 'run_upgrade_effects.dart';

class CombatMath {
  CombatMath._();

  static int maxHp(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    final base = 128 + (_stat(hero, StatId.vit, ownedUpgradeIds) * 12);
    return (base *
            RunUpgradeEffects.maxHpMultiplier(
              ownedUpgradeIds,
              runStartBoostActive: hero.hasActiveBoost('boost_run_start'),
            ))
        .round();
  }

  static int maxSp(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    final base = 50 + (_stat(hero, StatId.intStat, ownedUpgradeIds) * 8);
    return (base *
            RunUpgradeEffects.maxSpMultiplier(
              runStartBoostActive: hero.hasActiveBoost('boost_run_start'),
            ))
        .round();
  }

  static double moveSpeed(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) =>
      (190 + (_stat(hero, StatId.agi, ownedUpgradeIds) * 18)) *
      RunUpgradeEffects.moveSpeedMultiplier(ownedUpgradeIds);

  static int basicAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    final baseDamage = _baseAttackDamage(
      hero,
      ownedUpgradeIds: ownedUpgradeIds,
    );
    final expectedCritBonus =
        1 + (critChance(hero, ownedUpgradeIds: ownedUpgradeIds) * 0.5);
    return (baseDamage *
            expectedCritBonus *
            RunUpgradeEffects.basicAttackDamageMultiplier(
              hero.classId,
              ownedUpgradeIds,
            ))
        .round();
  }

  static double critChance(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    var chance = 0.05 + (_stat(hero, StatId.luk, ownedUpgradeIds) * 0.008);
    chance += (hero.skillRanks['eagle_eye'] ?? 0) * 0.025;
    chance += (hero.skillRanks['meditation'] ?? 0) * 0.015;
    chance += RunUpgradeEffects.critChanceBonus(ownedUpgradeIds);
    return chance.clamp(0, 0.6).toDouble();
  }

  static int _baseAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    if (hero.classId == HeroClassId.mage) {
      return 5 + (_stat(hero, StatId.intStat, ownedUpgradeIds) * 3);
    }
    return 5 +
        (_stat(hero, StatId.str, ownedUpgradeIds) * 2) +
        _stat(hero, StatId.dex, ownedUpgradeIds);
  }

  static int _stat(
    HeroProgress hero,
    StatId stat,
    Set<String> ownedUpgradeIds,
  ) => (hero.stats[stat] ?? 1) + RunUpgradeEffects.statBonus(ownedUpgradeIds);
}
