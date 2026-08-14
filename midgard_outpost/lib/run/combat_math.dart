import 'dart:math' as math;

import '../core/ids.dart';
import '../progress/hero_progress.dart';
import 'run_upgrade_effects.dart';

class DamageRoll {
  const DamageRoll({required this.amount, required this.isCrit});

  final int amount;
  final bool isCrit;
}

class CombatMath {
  CombatMath._();

  static int maxHp(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
  }) {
    final base = 128 +
        (_stat(
              hero,
              StatId.vit,
              ownedUpgradeIds,
              temporaryAllStatsBonus: temporaryAllStatsBonus,
            ) *
            12);
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
    int temporaryAllStatsBonus = 0,
  }) {
    final base = 50 +
        (_stat(
              hero,
              StatId.intStat,
              ownedUpgradeIds,
              temporaryAllStatsBonus: temporaryAllStatsBonus,
            ) *
            8);
    return (base *
            RunUpgradeEffects.maxSpMultiplier(
              runStartBoostActive: hero.hasActiveBoost('boost_run_start'),
            ))
        .round();
  }

  static double moveSpeed(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
  }) =>
      (190 +
          (_stat(
                hero,
                StatId.agi,
                ownedUpgradeIds,
                temporaryAllStatsBonus: temporaryAllStatsBonus,
              ) *
              5)) *
      RunUpgradeEffects.moveSpeedMultiplier(ownedUpgradeIds);

  static int basicAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
  }) {
    final baseDamage = _baseAttackDamage(
      hero,
      ownedUpgradeIds: ownedUpgradeIds,
      temporaryAllStatsBonus: temporaryAllStatsBonus,
    );
    final expectedCritBonus = 1 +
        (critChance(
              hero,
              ownedUpgradeIds: ownedUpgradeIds,
              temporaryAllStatsBonus: temporaryAllStatsBonus,
            ) *
            0.5);
    return (baseDamage *
            expectedCritBonus *
            RunUpgradeEffects.basicAttackDamageMultiplier(
              hero.classId,
              ownedUpgradeIds,
            ))
        .round();
  }

  /// Discrete RO-style roll (crit = 1.5×), used for floating numbers.
  static DamageRoll rollBasicAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();
    final base =
        _baseAttackDamage(
          hero,
          ownedUpgradeIds: ownedUpgradeIds,
          temporaryAllStatsBonus: temporaryAllStatsBonus,
        ) *
        RunUpgradeEffects.basicAttackDamageMultiplier(
          hero.classId,
          ownedUpgradeIds,
        );
    final isCrit = random.nextDouble() <
        critChance(
          hero,
          ownedUpgradeIds: ownedUpgradeIds,
          temporaryAllStatsBonus: temporaryAllStatsBonus,
        );
    final amount = (base * (isCrit ? 1.5 : 1.0)).round().clamp(1, 99999);
    return DamageRoll(amount: amount, isCrit: isCrit);
  }

  static DamageRoll rollSkillDamage(
    int baseDamage, {
    required double critChanceValue,
    math.Random? rng,
  }) {
    final random = rng ?? math.Random();
    final isCrit = random.nextDouble() < critChanceValue.clamp(0, 1);
    final amount = (baseDamage * (isCrit ? 1.5 : 1.0)).round().clamp(1, 99999);
    return DamageRoll(amount: amount, isCrit: isCrit);
  }

  static double critChance(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
  }) {
    var chance = 0.05 +
        (_stat(
              hero,
              StatId.luk,
              ownedUpgradeIds,
              temporaryAllStatsBonus: temporaryAllStatsBonus,
            ) *
            0.008);
    chance += (hero.skillRanks['eagle_eye'] ?? 0) * 0.025;
    chance += (hero.skillRanks['meditation'] ?? 0) * 0.015;
    chance += RunUpgradeEffects.critChanceBonus(ownedUpgradeIds);
    return chance.clamp(0, 0.6).toDouble();
  }

  static int _baseAttackDamage(
    HeroProgress hero, {
    Set<String> ownedUpgradeIds = const {},
    int temporaryAllStatsBonus = 0,
  }) {
    if (hero.classId == HeroClassId.mage) {
      return 5 +
          (_stat(
                hero,
                StatId.intStat,
                ownedUpgradeIds,
                temporaryAllStatsBonus: temporaryAllStatsBonus,
              ) *
              3);
    }
    return 5 +
        (_stat(
              hero,
              StatId.str,
              ownedUpgradeIds,
              temporaryAllStatsBonus: temporaryAllStatsBonus,
            ) *
            2) +
        _stat(
          hero,
          StatId.dex,
          ownedUpgradeIds,
          temporaryAllStatsBonus: temporaryAllStatsBonus,
        );
  }

  static int _stat(
    HeroProgress hero,
    StatId stat,
    Set<String> ownedUpgradeIds, {
    int temporaryAllStatsBonus = 0,
  }) =>
      (hero.stats[stat] ?? 1) +
      RunUpgradeEffects.statBonus(ownedUpgradeIds) +
      temporaryAllStatsBonus;
}
