import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/run_rewards.dart';

void main() {
  test('run rewards accumulate gold and xp counters', () {
    final rewards =
        (RunRewardsAccumulator()
              ..addKill(baseXp: 5, jobXp: 3, gold: 2)
              ..addKill(baseXp: 5, jobXp: 3, gold: 2))
            .toRewards();

    expect(rewards.baseXp, 10);
    expect(rewards.jobXp, 6);
    expect(rewards.gold, 4);
  });

  test('empty accumulator returns zero rewards', () {
    final rewards = RunRewardsAccumulator().toRewards();

    expect(rewards.baseXp, 0);
    expect(rewards.jobXp, 0);
    expect(rewards.gold, 0);
  });
}
