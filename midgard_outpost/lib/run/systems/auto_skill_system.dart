import '../../content/skills.dart';
import '../../core/ids.dart';
import '../run_upgrade_effects.dart';

enum SkillCastKind { auto, ultimate }

class SkillCastEvent {
  const SkillCastEvent({
    required this.skillId,
    required this.kind,
    required this.damage,
    required this.spCost,
    required this.range,
    required this.targetCount,
    required this.projectile,
  });

  final String skillId;
  final SkillCastKind kind;
  final int damage;
  final int spCost;
  final double range;
  final int targetCount;
  final bool projectile;
}

class AutoSkillSystem {
  AutoSkillSystem({
    required this.classId,
    required Map<String, int> ranks,
    required Set<String> upgrades,
    this.maxSp = 80,
  }) : ranks = Map.unmodifiable(ranks),
       upgrades = upgrades,
       sp = maxSp;

  final HeroClassId classId;
  final Map<String, int> ranks;
  final Set<String> upgrades;
  int maxSp;

  int sp;
  final Map<String, double> _cooldowns = {};
  double _ultimateCooldownRemaining = 0;
  double _spRegenAccumulator = 0;

  double get ultimateCooldownRemaining => _ultimateCooldownRemaining;

  /// Castable non-passive skills for HUD (auto + ultimate).
  List<SkillDef> get castableSkills => SkillsCatalog.forClass(classId)
      .where((skill) => skill.kind != SkillKind.passive)
      .toList(growable: false);

  void setMaxSp(int value) {
    maxSp = value;
    sp = sp.clamp(0, maxSp).toInt();
  }

  double cooldownRemaining(String skillId) {
    final skill = _skillById(skillId);
    if (skill == null) {
      return 0;
    }
    if (skill.kind == SkillKind.ultimate) {
      return _ultimateCooldownRemaining;
    }
    return _cooldowns[skillId] ?? 0;
  }

  SkillDef? _skillById(String skillId) {
    for (final skill in SkillsCatalog.forClass(classId)) {
      if (skill.id == skillId) {
        return skill;
      }
    }
    return null;
  }

  /// Ticks cooldowns + SP regen only. Does **not** auto-cast.
  List<SkillCastEvent> tick(
    double dt, {
    required int enemiesInRange,
    Iterable<double>? enemyDistances,
  }) {
    _tickCooldowns(dt);
    _regenerateSp(dt);
    return const [];
  }

  /// Manual cast for any ranked auto/ultimate skill.
  SkillCastEvent? tryCastSkill(
    String skillId, {
    int enemiesInRange = 1,
    Iterable<double>? enemyDistances,
  }) {
    final skill = _skillById(skillId);
    if (skill == null || skill.kind == SkillKind.passive) {
      return null;
    }
    if (_rank(skill.id) <= 0) {
      return null;
    }

    final kind = skill.kind == SkillKind.ultimate
        ? SkillCastKind.ultimate
        : SkillCastKind.auto;

    // Self-buff: no enemy required.
    if (skill.id == 'concentrate') {
      if (kind == SkillCastKind.ultimate) {
        return null;
      }
      return _tryCast(skill, kind, 1);
    }

    if (kind == SkillCastKind.ultimate) {
      if (_ultimateCooldownRemaining > 0) {
        return null;
      }
      final distances = enemyDistances?.toList(growable: false);
      final skillEnemiesInRange = _enemyCountForSkill(
        skill,
        kind,
        enemiesInRange,
        distances,
      );
      if (skillEnemiesInRange <= 0) {
        return null;
      }
      final event = _buildEvent(skill, kind, skillEnemiesInRange);
      if (event.spCost > sp) {
        return null;
      }
      sp -= event.spCost;
      _ultimateCooldownRemaining = _cooldownFor(skill.id, kind);
      return event;
    }

    final distances = enemyDistances?.toList(growable: false);
    final skillEnemiesInRange = _enemyCountForSkill(
      skill,
      kind,
      enemiesInRange,
      distances,
    );
    if (skillEnemiesInRange <= 0) {
      return null;
    }
    return _tryCast(skill, kind, skillEnemiesInRange);
  }

  /// Temporary all-stat bonus while Concentrate is active: rank + 1.
  static int concentrateStatBonus(int rank) => rank <= 0 ? 0 : rank + 1;

  bool tryUltimate({
    int enemiesInRange = 1,
    Iterable<double>? enemyDistances,
  }) =>
      tryCastUltimate(
        enemiesInRange: enemiesInRange,
        enemyDistances: enemyDistances,
      ) !=
      null;

  SkillCastEvent? tryCastUltimate({
    int enemiesInRange = 1,
    Iterable<double>? enemyDistances,
  }) {
    final skill = SkillsCatalog.forClass(
      classId,
    ).firstWhere((skill) => skill.kind == SkillKind.ultimate);
    return tryCastSkill(
      skill.id,
      enemiesInRange: enemiesInRange,
      enemyDistances: enemyDistances,
    );
  }

  SkillCastEvent? _tryCast(
    SkillDef skill,
    SkillCastKind kind,
    int enemiesInRange,
  ) {
    if ((_cooldowns[skill.id] ?? 0) > 0) {
      return null;
    }

    final event = _buildEvent(skill, kind, enemiesInRange);
    if (event.spCost > sp) {
      return null;
    }

    sp -= event.spCost;
    _cooldowns[skill.id] = _cooldownFor(skill.id, kind);
    return event;
  }

  SkillCastEvent _buildEvent(
    SkillDef skill,
    SkillCastKind kind,
    int enemiesInRange,
  ) {
    final tuning = _tuningFor(skill.id, kind);
    final rank = _rank(skill.id);
    final upgradedTargetCount =
        tuning.targetCount +
        RunUpgradeEffects.targetCountBonus(skill.id, upgrades);
    final targetCount = upgradedTargetCount.clamp(1, enemiesInRange).toInt();
    final damage = (tuning.baseDamage + (rank * tuning.rankDamage)).toDouble();

    return SkillCastEvent(
      skillId: skill.id,
      kind: kind,
      damage: (damage * _damageMultiplierFor(skill.id)).round(),
      spCost: _spCostFor(skill.id, tuning.spCost),
      range:
          tuning.range * RunUpgradeEffects.rangeMultiplier(skill.id, upgrades),
      targetCount: targetCount,
      projectile: tuning.projectile,
    );
  }

  void _tickCooldowns(double dt) {
    if (_ultimateCooldownRemaining > 0) {
      _ultimateCooldownRemaining = (_ultimateCooldownRemaining - dt)
          .clamp(0, double.infinity)
          .toDouble();
    }

    for (final entry in _cooldowns.entries.toList()) {
      final next = (entry.value - dt).clamp(0, double.infinity).toDouble();
      if (next <= 0) {
        _cooldowns.remove(entry.key);
      } else {
        _cooldowns[entry.key] = next;
      }
    }
  }

  void _regenerateSp(double dt) {
    if (sp >= maxSp) {
      _spRegenAccumulator = 0;
      return;
    }

    final regen =
        (2 + (_rank('meditation') * 0.8)) *
        RunUpgradeEffects.spRegenMultiplier(upgrades);
    _spRegenAccumulator += regen * dt;
    final wholeSp = _spRegenAccumulator.floor();
    if (wholeSp <= 0) {
      return;
    }

    sp = (sp + wholeSp).clamp(0, maxSp).toInt();
    _spRegenAccumulator -= wholeSp;
    if (sp >= maxSp) {
      _spRegenAccumulator = 0;
    }
  }

  int _enemyCountForSkill(
    SkillDef skill,
    SkillCastKind kind,
    int enemiesInRange,
    List<double>? enemyDistances,
  ) {
    if (enemyDistances == null) {
      return enemiesInRange;
    }

    final range =
        _tuningFor(skill.id, kind).range *
        RunUpgradeEffects.rangeMultiplier(skill.id, upgrades);
    return enemyDistances.where((distance) => distance <= range).length;
  }

  int _rank(String skillId) => ranks[skillId] ?? 0;

  int _spCostFor(String skillId, int baseCost) {
    var cost =
        baseCost.toDouble() *
        RunUpgradeEffects.spCostMultiplier(skillId, upgrades);
    return cost.round().clamp(0, maxSp).toInt();
  }

  double _cooldownFor(String skillId, SkillCastKind kind) {
    return _tuningFor(skillId, kind).cooldown *
        RunUpgradeEffects.cooldownMultiplier(
          skillId: skillId,
          isUltimate: kind == SkillCastKind.ultimate,
          upgrades: upgrades,
        );
  }

  double _damageMultiplierFor(String skillId) =>
      RunUpgradeEffects.skillDamageMultiplier(
        classId: classId,
        skillId: skillId,
        upgrades: upgrades,
      );

  _SkillTuning _tuningFor(String skillId, SkillCastKind kind) {
    if (kind == SkillCastKind.ultimate) {
      return switch (skillId) {
        'arrow_shower' => const _SkillTuning(
          cooldown: 9,
          spCost: 20,
          baseDamage: 24,
          rankDamage: 8,
          range: 360,
          targetCount: 5,
          projectile: true,
        ),
        'meteor' => const _SkillTuning(
          cooldown: 10,
          spCost: 24,
          baseDamage: 34,
          rankDamage: 10,
          range: 320,
          targetCount: 4,
          projectile: false,
        ),
        'heaven_wrath' => const _SkillTuning(
          cooldown: 9,
          spCost: 18,
          baseDamage: 28,
          rankDamage: 8,
          range: 150,
          targetCount: 4,
          projectile: false,
        ),
        _ => const _SkillTuning(
          cooldown: 10,
          spCost: 20,
          baseDamage: 25,
          rankDamage: 8,
          range: 260,
          targetCount: 3,
          projectile: false,
        ),
      };
    }

    return switch (skillId) {
      'double_strafe' => const _SkillTuning(
        cooldown: 2.2,
        spCost: 8,
        baseDamage: 12,
        rankDamage: 4,
        range: 340,
      ),
      'wind_arrow' => const _SkillTuning(
        cooldown: 3,
        spCost: 10,
        baseDamage: 18,
        rankDamage: 5,
        range: 380,
      ),
      'concentrate' => const _SkillTuning(
        cooldown: 8,
        spCost: 14,
        baseDamage: 0,
        rankDamage: 0,
        range: 0,
        projectile: false,
      ),
      'fire_bolt' => const _SkillTuning(
        cooldown: 2.4,
        spCost: 9,
        baseDamage: 15,
        rankDamage: 5,
        range: 300,
      ),
      'frost' => const _SkillTuning(
        cooldown: 4,
        spCost: 12,
        baseDamage: 13,
        rankDamage: 4,
        range: 260,
        targetCount: 2,
        projectile: false,
      ),
      'lightning' => const _SkillTuning(
        cooldown: 3.4,
        spCost: 14,
        baseDamage: 24,
        rankDamage: 6,
        range: 340,
        projectile: false,
      ),
      'shield_bash' => const _SkillTuning(
        cooldown: 2.8,
        spCost: 8,
        baseDamage: 14,
        rankDamage: 4,
        range: 90,
        projectile: false,
      ),
      'holy_strike' => const _SkillTuning(
        cooldown: 3.2,
        spCost: 10,
        baseDamage: 18,
        rankDamage: 5,
        range: 110,
        projectile: false,
      ),
      'protection_aura' => const _SkillTuning(
        cooldown: 6,
        spCost: 14,
        baseDamage: 6,
        rankDamage: 2,
        range: 140,
        targetCount: 3,
        projectile: false,
      ),
      _ => const _SkillTuning(
        cooldown: 3,
        spCost: 10,
        baseDamage: 12,
        rankDamage: 4,
        range: 240,
      ),
    };
  }
}

class _SkillTuning {
  const _SkillTuning({
    required this.cooldown,
    required this.spCost,
    required this.baseDamage,
    required this.rankDamage,
    required this.range,
    this.targetCount = 1,
    this.projectile = true,
  });

  final double cooldown;
  final int spCost;
  final int baseDamage;
  final int rankDamage;
  final double range;
  final int targetCount;
  final bool projectile;
}
