import '../content/balance.dart';
import '../core/ids.dart';

class RunUpgradeEffects {
  RunUpgradeEffects._();

  static const Set<String> wiredIds = {
    'sharp_tips',
    'hot_magic',
    'lifesteal',
    'double_cast',
    'crit_luck',
    'armor_break',
    'second_wind',
    'stone_shell',
    'regen',
    'thorns',
    'jump_shield',
    'haste',
    'light_boots',
    'greed',
    'temp_xp_boost',
    'ult_charge',
    'totem_of_power',
    'boss_mark',
    'double_strafe__triple_string',
    'double_strafe__heavy_tips',
    'double_strafe__rapid_fire',
    'wind_arrow__gust',
    'wind_arrow__knockback_wave',
    'wind_arrow__cutting_wind',
    'eagle_eye__hawk_focus',
    'eagle_eye__sniper_eye',
    'eagle_eye__hunting_instinct',
    'arrow_shower__downpour',
    'arrow_shower__armor_piercing_hail',
    'arrow_shower__quick_quiver',
    'fire_bolt__explosive_ball',
    'fire_bolt__white_heat',
    'fire_bolt__chain_heat',
    'frost__eternal_frost',
    'frost__ice_shards',
    'frost__frost_wave',
    'lightning__storm_sight',
    'lightning__discharge',
    'lightning__overload',
    'meditation__deep_trance',
    'meditation__clarity',
    'meditation__mana_economy',
    'meteor__stone_rain',
    'meteor__melting_strike',
    'meteor__quick_ritual',
    'shield_bash__stunning_edge',
    'shield_bash__ram',
    'shield_bash__shield_series',
    'holy_strike__grace',
    'holy_strike__smite',
    'holy_strike__slashing_light',
    'protection_aura__fortress',
    'protection_aura__long_aura',
    'protection_aura__reflection',
    'endurance__iron_will',
    'endurance__indestructible',
    'endurance__second_skin',
    'heaven_wrath__expanded_wrath',
    'heaven_wrath__heavenly_shield',
    'heaven_wrath__swift_wrath',
  };

  static int statBonus(Set<String> upgrades) =>
      upgrades.contains('totem_of_power') ? Balance.totemStatBonus : 0;

  static double maxHpMultiplier(
    Set<String> upgrades, {
    bool runStartBoostActive = false,
  }) {
    var multiplier = runStartBoostActive
        ? Balance.iapRunStartResourceMultiplier
        : 1.0;
    if (upgrades.contains('stone_shell')) {
      multiplier *= 1.2;
    }
    if (upgrades.contains('endurance__iron_will')) {
      multiplier *= 1.18;
    }
    return multiplier;
  }

  static double maxSpMultiplier({bool runStartBoostActive = false}) =>
      runStartBoostActive ? Balance.iapRunStartResourceMultiplier : 1.0;

  static double moveSpeedMultiplier(Set<String> upgrades) {
    var multiplier = 1.0;
    if (upgrades.contains('haste')) {
      multiplier *= 1.15;
    }
    if (upgrades.contains('light_boots')) {
      multiplier *= 1.08;
    }
    if (upgrades.contains('eagle_eye__hunting_instinct')) {
      multiplier *= 1.05;
    }
    return multiplier;
  }

  static double critChanceBonus(Set<String> upgrades) {
    var bonus = 0.0;
    if (upgrades.contains('crit_luck')) {
      bonus += 0.08;
    }
    if (upgrades.contains('eagle_eye__hawk_focus')) {
      bonus += 0.06;
    }
    if (upgrades.contains('eagle_eye__sniper_eye')) {
      bonus += 0.04;
    }
    if (upgrades.contains('meditation__clarity')) {
      bonus += 0.05;
    }
    return bonus;
  }

  static double basicAttackDamageMultiplier(
    HeroClassId classId,
    Set<String> upgrades,
  ) {
    var multiplier = _classDamageMultiplier(classId, upgrades);
    if (upgrades.contains('double_cast')) {
      multiplier *= 1.15;
    }
    if (upgrades.contains('armor_break')) {
      multiplier *= 1.1;
    }
    if (upgrades.contains('eagle_eye__sniper_eye')) {
      multiplier *= 1.08;
    }
    if (upgrades.contains('eagle_eye__hunting_instinct')) {
      multiplier *= 1.08;
    }
    return multiplier;
  }

  static double skillDamageMultiplier({
    required HeroClassId classId,
    required String skillId,
    required Set<String> upgrades,
  }) {
    var multiplier = _classDamageMultiplier(classId, upgrades);
    if (upgrades.contains('armor_break')) {
      multiplier *= 1.1;
    }
    if (upgrades.contains('totem_of_power')) {
      multiplier *= 1.06;
    }
    if (upgrades.contains('eagle_eye__sniper_eye') &&
        classId == HeroClassId.archer) {
      multiplier *= 1.08;
    }

    for (final entry in _skillDamageMultipliers.entries) {
      if (entry.key.startsWith('${skillId}__') &&
          upgrades.contains(entry.key)) {
        multiplier *= entry.value;
      }
    }
    if (skillId == 'lightning' && upgrades.contains('lightning__overload')) {
      multiplier *= 1.25;
    }
    return multiplier;
  }

  static double cooldownMultiplier({
    required String skillId,
    required bool isUltimate,
    required Set<String> upgrades,
  }) {
    var multiplier = 1.0;
    if (isUltimate && upgrades.contains('ult_charge')) {
      multiplier *= 0.85;
    }
    for (final entry in _cooldownMultipliers.entries) {
      if (entry.key.startsWith('${skillId}__') &&
          upgrades.contains(entry.key)) {
        multiplier *= entry.value;
      }
    }
    return multiplier;
  }

  static double rangeMultiplier(String skillId, Set<String> upgrades) {
    var multiplier = 1.0;
    for (final entry in _rangeMultipliers.entries) {
      if (entry.key.startsWith('${skillId}__') &&
          upgrades.contains(entry.key)) {
        multiplier *= entry.value;
      }
    }
    return multiplier;
  }

  static int targetCountBonus(String skillId, Set<String> upgrades) {
    var bonus = upgrades.contains('double_cast') ? 1 : 0;
    for (final entry in _targetCountBonuses.entries) {
      if (entry.key.startsWith('${skillId}__') &&
          upgrades.contains(entry.key)) {
        bonus += entry.value;
      }
    }
    return bonus;
  }

  static double spCostMultiplier(String skillId, Set<String> upgrades) {
    var multiplier = 1.0;
    if (upgrades.contains('meditation__mana_economy')) {
      multiplier *= 0.85;
    }
    if (upgrades.contains('lightning__overload') && skillId == 'lightning') {
      multiplier *= 1.2;
    }
    return multiplier;
  }

  static double spRegenMultiplier(Set<String> upgrades) =>
      upgrades.contains('meditation__deep_trance') ? 1.5 : 1.0;

  static double incomingDamageMultiplier(Set<String> upgrades) {
    var multiplier = 1.0;
    if (upgrades.contains('protection_aura__fortress')) {
      multiplier *= 0.9;
    }
    if (upgrades.contains('protection_aura__long_aura')) {
      multiplier *= 0.95;
    }
    if (upgrades.contains('endurance__indestructible')) {
      multiplier *= 0.88;
    }
    if (upgrades.contains('endurance__second_skin')) {
      multiplier *= 0.92;
    }
    if (upgrades.contains('heaven_wrath__heavenly_shield')) {
      multiplier *= 0.9;
    }
    return multiplier;
  }

  static double lifestealFraction(String? skillId, Set<String> upgrades) {
    var fraction = upgrades.contains('lifesteal') ? 0.06 : 0.0;
    if (skillId == 'holy_strike' && upgrades.contains('holy_strike__grace')) {
      fraction += 0.12;
    }
    return fraction;
  }

  static double thornsFraction(Set<String> upgrades) {
    var fraction = upgrades.contains('thorns') ? 0.15 : 0.0;
    if (upgrades.contains('protection_aura__reflection')) {
      fraction += 0.1;
    }
    return fraction;
  }

  static double hpRegenPerSecond(Set<String> upgrades) =>
      upgrades.contains('regen') ? 2.0 : 0.0;

  static double jumpShieldSeconds(Set<String> upgrades) =>
      upgrades.contains('jump_shield') ? 1.1 : 0.0;

  static double goldMultiplier(Set<String> upgrades, {required bool isBoss}) {
    var multiplier = upgrades.contains('greed') ? 1.25 : 1.0;
    if (isBoss && upgrades.contains('boss_mark')) {
      multiplier *= 1.25;
    }
    return multiplier;
  }

  static double tempXpMultiplier(Set<String> upgrades) =>
      upgrades.contains('temp_xp_boost') ? 1.25 : 1.0;

  static double monsterDropChanceMultiplier(Set<String> upgrades) =>
      upgrades.contains('greed') ? 1.2 : 1.0;

  static double chestDistanceMultiplier(Set<String> upgrades) =>
      upgrades.contains('greed') ? 0.8 : 1.0;

  static double bossMaxHpMultiplier(Set<String> upgrades) =>
      upgrades.contains('boss_mark') ? 0.85 : 1.0;

  static double bossTouchDamageMultiplier(Set<String> upgrades) =>
      upgrades.contains('boss_mark') ? 0.9 : 1.0;

  static bool hasSecondWind(Set<String> upgrades) =>
      upgrades.contains('second_wind');

  static double _classDamageMultiplier(
    HeroClassId classId,
    Set<String> upgrades,
  ) {
    var multiplier = 1.0;
    if (upgrades.contains('sharp_tips') && classId != HeroClassId.mage) {
      multiplier *= 1.12;
    }
    if (upgrades.contains('hot_magic') && classId == HeroClassId.mage) {
      multiplier *= 1.12;
    }
    return multiplier;
  }

  static const Map<String, double> _skillDamageMultipliers = {
    'double_strafe__heavy_tips': 1.25,
    'wind_arrow__knockback_wave': 1.12,
    'wind_arrow__cutting_wind': 1.25,
    'fire_bolt__white_heat': 1.25,
    'frost__ice_shards': 1.25,
    'lightning__storm_sight': 1.12,
    'shield_bash__ram': 1.25,
    'holy_strike__smite': 1.25,
    'holy_strike__slashing_light': 1.15,
    'arrow_shower__armor_piercing_hail': 1.25,
    'meteor__melting_strike': 1.25,
  };

  static const Map<String, double> _cooldownMultipliers = {
    'double_strafe__rapid_fire': 0.8,
    'frost__eternal_frost': 0.85,
    'shield_bash__stunning_edge': 0.85,
    'shield_bash__shield_series': 0.8,
    'protection_aura__long_aura': 0.9,
    'arrow_shower__quick_quiver': 0.8,
    'meteor__quick_ritual': 0.8,
    'heaven_wrath__swift_wrath': 0.8,
  };

  static const Map<String, double> _rangeMultipliers = {
    'wind_arrow__gust': 1.18,
    'frost__frost_wave': 1.15,
    'heaven_wrath__expanded_wrath': 1.2,
  };

  static const Map<String, int> _targetCountBonuses = {
    'double_strafe__triple_string': 1,
    'arrow_shower__downpour': 2,
    'fire_bolt__explosive_ball': 1,
    'fire_bolt__chain_heat': 1,
    'frost__frost_wave': 1,
    'lightning__discharge': 1,
    'meteor__stone_rain': 2,
    'heaven_wrath__expanded_wrath': 1,
  };
}
