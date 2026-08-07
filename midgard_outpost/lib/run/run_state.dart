class RunState {
  const RunState({
    required this.tempXp,
    required this.ownedUpgradeIds,
    required this.distancePx,
  });

  final int tempXp;
  final Set<String> ownedUpgradeIds;
  final int distancePx;

  factory RunState.initial() => const RunState(
        tempXp: 0,
        ownedUpgradeIds: {},
        distancePx: 0,
      );

  RunState copyWith({
    int? tempXp,
    Set<String>? ownedUpgradeIds,
    int? distancePx,
  }) {
    return RunState(
      tempXp: tempXp ?? this.tempXp,
      ownedUpgradeIds: ownedUpgradeIds ?? this.ownedUpgradeIds,
      distancePx: distancePx ?? this.distancePx,
    );
  }

  RunState addOwnedUpgrade(String id) =>
      copyWith(ownedUpgradeIds: {...ownedUpgradeIds, id});

  RunState addDistance(int px) => copyWith(distancePx: distancePx + px);
}
