import '../progress/hero_progress.dart';
import 'cloud_save_port.dart';
import 'local_save_repository.dart';

class SaveService {
  SaveService({
    required LocalSaveRepository local,
    required CloudSavePort cloud,
  })  : _local = local,
        _cloud = cloud;

  final LocalSaveRepository _local;
  final CloudSavePort _cloud;

  Future<HeroProgress?> loadForLaunch() async {
    final local = await _local.load();
    if (local != null) {
      return local;
    }

    final cloud = await _cloud.pull();
    if (cloud != null) {
      await _local.save(cloud);
    }
    return cloud;
  }

  Future<void> persist(HeroProgress hero) async {
    await _local.save(hero);
    await _cloud.push(hero);
  }
}
