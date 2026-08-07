import 'package:flutter/foundation.dart';

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

/// In-process cloud save for debug builds and tests.
///
/// Replace with a real backend (Huawei Account / custom API) for production.
class InMemoryCloudSavePort implements CloudSavePort {
  HeroProgress? _stored;

  @override
  Future<HeroProgress?> pull() async => _stored;

  @override
  Future<void> push(HeroProgress hero) async {
    _stored = hero;
  }
}

/// Selects cloud save implementation from `--dart-define` or build mode.
///
/// `CLOUD_SAVE=memory|noop` overrides defaults.
/// Debug: [InMemoryCloudSavePort]; release: [NoopCloudSavePort].
CloudSavePort resolveCloudSavePort() {
  const env = String.fromEnvironment('CLOUD_SAVE', defaultValue: '');
  return switch (env) {
    'memory' => InMemoryCloudSavePort(),
    'noop' => NoopCloudSavePort(),
    _ => kDebugMode ? InMemoryCloudSavePort() : NoopCloudSavePort(),
  };
}
