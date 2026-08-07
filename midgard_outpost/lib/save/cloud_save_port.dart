import '../progress/hero_progress.dart';

abstract class CloudSavePort {
  Future<HeroProgress?> pull();
  Future<void> push(HeroProgress hero);
}

class NoopCloudSavePort implements CloudSavePort {
  @override
  Future<HeroProgress?> pull() async => null;

  @override
  Future<void> push(HeroProgress hero) async {}
}
