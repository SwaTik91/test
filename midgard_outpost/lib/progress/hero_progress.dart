import '../core/ids.dart';
import 'stats.dart';

class HeroProgress {
  const HeroProgress({
    required this.classId,
    required this.baseLevel,
    required this.jobLevel,
    required this.baseXp,
    required this.jobXp,
    required this.unspentStatPoints,
    required this.unspentSkillPoints,
    required this.stats,
    required this.skillRanks,
    required this.gold,
    required this.crystals,
    this.activeBoosts = const {},
  });

  final HeroClassId classId;
  final int baseLevel;
  final int jobLevel;
  final int baseXp;
  final int jobXp;
  final int unspentStatPoints;
  final int unspentSkillPoints;
  final Map<StatId, int> stats;
  final Map<String, int> skillRanks;
  final int gold;
  final int crystals;
  final Map<String, int> activeBoosts;

  factory HeroProgress.createNew(HeroClassId classId) {
    return HeroProgress(
      classId: classId,
      baseLevel: 1,
      jobLevel: 1,
      baseXp: 0,
      jobXp: 0,
      unspentStatPoints: 0,
      unspentSkillPoints: 0,
      stats: Stats.defaultStats(),
      skillRanks: const {},
      gold: 0,
      crystals: 0,
    );
  }

  HeroProgress copyWith({
    HeroClassId? classId,
    int? baseLevel,
    int? jobLevel,
    int? baseXp,
    int? jobXp,
    int? unspentStatPoints,
    int? unspentSkillPoints,
    Map<StatId, int>? stats,
    Map<String, int>? skillRanks,
    int? gold,
    int? crystals,
    Map<String, int>? activeBoosts,
  }) {
    return HeroProgress(
      classId: classId ?? this.classId,
      baseLevel: baseLevel ?? this.baseLevel,
      jobLevel: jobLevel ?? this.jobLevel,
      baseXp: baseXp ?? this.baseXp,
      jobXp: jobXp ?? this.jobXp,
      unspentStatPoints: unspentStatPoints ?? this.unspentStatPoints,
      unspentSkillPoints: unspentSkillPoints ?? this.unspentSkillPoints,
      stats: stats ?? this.stats,
      skillRanks: skillRanks ?? this.skillRanks,
      gold: gold ?? this.gold,
      crystals: crystals ?? this.crystals,
      activeBoosts: activeBoosts ?? this.activeBoosts,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId.name,
        'baseLevel': baseLevel,
        'jobLevel': jobLevel,
        'baseXp': baseXp,
        'jobXp': jobXp,
        'unspentStatPoints': unspentStatPoints,
        'unspentSkillPoints': unspentSkillPoints,
        'stats': Stats.statsToJson(stats),
        'skillRanks': skillRanks,
        'gold': gold,
        'crystals': crystals,
        'activeBoosts': activeBoosts,
      };

  factory HeroProgress.fromJson(Map<String, dynamic> json) {
    final skillRanksRaw = json['skillRanks'] as Map<String, dynamic>? ?? {};
    final activeBoostsRaw = json['activeBoosts'] as Map<String, dynamic>? ?? {};
    return HeroProgress(
      classId: HeroClassId.values.byName(json['classId'] as String),
      baseLevel: (json['baseLevel'] as num).toInt(),
      jobLevel: (json['jobLevel'] as num).toInt(),
      baseXp: (json['baseXp'] as num).toInt(),
      jobXp: (json['jobXp'] as num).toInt(),
      unspentStatPoints: (json['unspentStatPoints'] as num).toInt(),
      unspentSkillPoints: (json['unspentSkillPoints'] as num).toInt(),
      stats: Stats.statsFromJson(
        Map<String, dynamic>.from(json['stats'] as Map),
      ),
      skillRanks: {
        for (final entry in skillRanksRaw.entries)
          entry.key: (entry.value as num).toInt(),
      },
      gold: (json['gold'] as num).toInt(),
      crystals: (json['crystals'] as num).toInt(),
      activeBoosts: {
        for (final entry in activeBoostsRaw.entries)
          entry.key: (entry.value as num).toInt(),
      },
    );
  }
}
