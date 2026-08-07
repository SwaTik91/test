import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';

void main() {
  test('in-memory cloud roundtrip', () async {
    final cloud = InMemoryCloudSavePort();
    final hero =
        HeroProgress.createNew(HeroClassId.paladin).copyWith(crystals: 7);
    await cloud.push(hero);
    final pulled = await cloud.pull();
    expect(pulled!.crystals, 7);
  });
}
