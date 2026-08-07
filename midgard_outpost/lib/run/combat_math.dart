import '../core/ids.dart';
import '../progress/hero_progress.dart';

class CombatMath {
  CombatMath._();

  static int maxHp(HeroProgress hero) => 100 + (_stat(hero, StatId.vit) * 12);

  static int maxSp(HeroProgress hero) => 50 + (_stat(hero, StatId.intStat) * 8);

  static double moveSpeed(HeroProgress hero) =>
      190 + (_stat(hero, StatId.agi) * 18);

  static int basicAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    final baseDamage = _baseAttackDamage(hero);
    final expectedCritBonus =
        1 + (critChance(hero, ownedUpgradeIds: ownedUpgradeIds) * 0.5);
    return (baseDamage * expectedCritBonus).round();
  }

  static double critChance(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
  }) {
    var chance = 0.05 + (_stat(hero, StatId.luk) * 0.008);
    chance += (hero.skillRanks['eagle_eye'] ?? 0) * 0.025;
    chance += (hero.skillRanks['meditation'] ?? 0) * 0.015;
    if (ownedUpgradeIds.contains('crit_luck')) {
      chance += 0.08;
    }
    if (ownedUpgradeIds.contains('eagle_eye__hawk_focus')) {
      chance += 0.06;
    }
    if (ownedUpgradeIds.contains('meditation__clarity')) {
      chance += 0.05;
    }
    return chance.clamp(0, 0.6).toDouble();
  }

  static int _baseAttackDamage(HeroProgress hero) {
    if (hero.classId == HeroClassId.mage) {
      return 5 + (_stat(hero, StatId.intStat) * 3);
    }
    return 5 + (_stat(hero, StatId.str) * 2) + _stat(hero, StatId.dex);
  }

  static int _stat(HeroProgress hero, StatId stat) => hero.stats[stat] ?? 1;
}
