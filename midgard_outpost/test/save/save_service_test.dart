import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/progress/hero_progress.dart';
import 'package:midgard_outpost/save/local_save_repository.dart';
import 'package:midgard_outpost/save/save_service.dart';
import 'package:midgard_outpost/save/cloud_save_port.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persist and load roundtrip', () async {
    SharedPreferences.setMockInitialValues({});
    final local = LocalSaveRepository();
    final save = SaveService(local: local, cloud: NoopCloudSavePort());
    final hero = HeroProgress.createNew(HeroClassId.mage).copyWith(gold: 42);
    await save.persist(hero);
    final loaded = await save.loadForLaunch();
    expect(loaded!.gold, 42);
    expect(loaded.classId, HeroClassId.mage);
  });
}
