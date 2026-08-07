import '../content/balance.dart';
import '../content/skills.dart';
import '../core/ids.dart';
import '../run/run_rewards.dart';
import 'hero_progress.dart';

class ProgressService {
  ProgressService._();

  static int xpToNextBase(int level) => 15 + (level * 12);

  static int xpToNextJob(int level) => 12 + (level * 10);

  static HeroProgress applyRunRewards(
    HeroProgress hero,
    RunRewards rewards, {
    DateTime? now,
  }) {
    final xpMultiplier = hero.hasActiveBoost('boost_base_job_xp', now: now)
        ? Balance.iapBaseJobXpBoostMultiplier
        : 1.0;
    var updated = hero.copyWith(
      gold: hero.gold + rewards.gold,
      baseXp: hero.baseXp + (rewards.baseXp * xpMultiplier).round(),
      jobXp: hero.jobXp + (rewards.jobXp * xpMultiplier).round(),
    );

    var unspentStatPoints = updated.unspentStatPoints;
    var baseLevel = updated.baseLevel;
    var baseXp = updated.baseXp;
    while (baseXp >= xpToNextBase(baseLevel)) {
      baseXp -= xpToNextBase(baseLevel);
      baseLevel += 1;
      unspentStatPoints += Balance.baseStatPointsPerLevel;
    }

    var unspentSkillPoints = updated.unspentSkillPoints;
    var jobLevel = updated.jobLevel;
    var jobXp = updated.jobXp;
    while (jobXp >= xpToNextJob(jobLevel)) {
      jobXp -= xpToNextJob(jobLevel);
      jobLevel += 1;
      unspentSkillPoints += Balance.jobSkillPointsPerLevel;
    }

    return updated.copyWith(
      baseLevel: baseLevel,
      baseXp: baseXp,
      jobLevel: jobLevel,
      jobXp: jobXp,
      unspentStatPoints: unspentStatPoints,
      unspentSkillPoints: unspentSkillPoints,
    );
  }

  static HeroProgress allocateStat(HeroProgress hero, StatId stat) {
    if (hero.unspentStatPoints <= 0) {
      throw StateError('No unspent stat points');
    }
    final stats = Map<StatId, int>.from(hero.stats);
    stats[stat] = (stats[stat] ?? 1) + 1;
    return hero.copyWith(
      unspentStatPoints: hero.unspentStatPoints - 1,
      stats: stats,
    );
  }

  static HeroProgress allocateSkill(HeroProgress hero, String skillId) {
    if (hero.unspentSkillPoints <= 0) {
      throw StateError('No unspent skill points');
    }

    final skill = SkillsCatalog.byId(skillId);
    if (skill.classId != hero.classId) {
      throw ArgumentError('Skill $skillId does not belong to ${hero.classId}');
    }

    final currentRank = hero.skillRanks[skillId] ?? 0;
    if (currentRank >= Balance.maxSkillRank) {
      throw StateError('Skill $skillId is already at max rank');
    }

    final skillRanks = Map<String, int>.from(hero.skillRanks);
    skillRanks[skillId] = currentRank + 1;
    return hero.copyWith(
      unspentSkillPoints: hero.unspentSkillPoints - 1,
      skillRanks: skillRanks,
    );
  }
}
