class RunRewards {
  const RunRewards({
    required this.baseXp,
    required this.jobXp,
    required this.gold,
  });

  final int baseXp;
  final int jobXp;
  final int gold;
}

class RunRewardsAccumulator {
  int _baseXp = 0;
  int _jobXp = 0;
  int _gold = 0;

  void addKill({required int baseXp, required int jobXp, required int gold}) {
    _baseXp += baseXp;
    _jobXp += jobXp;
    _gold += gold;
  }

  RunRewards toRewards() =>
      RunRewards(baseXp: _baseXp, jobXp: _jobXp, gold: _gold);
}
