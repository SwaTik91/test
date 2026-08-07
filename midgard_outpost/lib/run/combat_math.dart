import '../core/ids.dart';
import '../progress/hero_progress.dart';

class CombatMath {
  CombatMath._();

  static int maxHp(HeroProgress hero) => 100 + (_stat(hero, StatId.vit) * 12);

  static int maxSp(HeroProgress hero) => 50 + (_stat(hero, StatId.intStat) * 8);

  static double moveSpeed(HeroProgress hero) =>
      190 + (_stat(hero, StatId.agi) * 18);

  static int basicAttackDamage(HeroProgress hero) {
    if (hero.classId == HeroClassId.mage) {
      return 5 + (_stat(hero, StatId.intStat) * 3);
    }
    return 5 + (_stat(hero, StatId.str) * 2) + _stat(hero, StatId.dex);
  }

  static int _stat(HeroProgress hero, StatId stat) => hero.stats[stat] ?? 1;
}
