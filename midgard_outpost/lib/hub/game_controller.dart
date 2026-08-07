import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../iap/iap_purchase_applier.dart';
import '../iap/fake_iap_service.dart';
import '../iap/iap_service.dart';
import '../progress/hero_progress.dart';
import '../progress/progress_service.dart';
import '../run/run_rewards.dart';
import '../run/run_state.dart';
import '../save/save_service.dart';

class GameController extends ChangeNotifier {
  GameController({required SaveService save, IapService? iap})
    : _save = save,
      _iap = iap ?? FakeIapService();

  final SaveService _save;
  final IapService _iap;

  HeroProgress? _hero;
  RunState _runState = RunState.initial();
  bool _bootstrapped = false;

  HeroProgress? get hero => _hero;
  RunState get runState => _runState;
  bool get isBootstrapped => _bootstrapped;
  IapService get iap => _iap;

  Future<void> bootstrap() async {
    _hero = await _save.loadForLaunch();
    _bootstrapped = true;
    notifyListeners();
  }

  Future<void> createHero(HeroClassId classId) async {
    final hero = HeroProgress.createNew(classId);
    _hero = hero;
    _runState = RunState.initial();
    await _save.persist(hero);
    notifyListeners();
  }

  Future<void> allocateStat(StatId stat) async {
    final current = _hero;
    if (current == null) return;
    _hero = ProgressService.allocateStat(current, stat);
    await _save.persist(_hero!);
    notifyListeners();
  }

  Future<void> allocateSkill(String skillId) async {
    final current = _hero;
    if (current == null) return;
    _hero = ProgressService.allocateSkill(current, skillId);
    await _save.persist(_hero!);
    notifyListeners();
  }

  void updateRunState(RunState state) {
    _runState = state;
    notifyListeners();
  }

  Future<void> onRunFinished(RunRewards rewards) async {
    final current = _hero;
    if (current == null) return;
    _hero = ProgressService.applyRunRewards(current, rewards);
    _runState = RunState.initial();
    await _save.persist(_hero!);
    notifyListeners();
  }

  Future<bool> purchaseProduct(String productId) async {
    final current = _hero;
    if (current == null) {
      return false;
    }

    final ok = await _iap.purchase(productId);
    if (!ok) {
      return false;
    }

    _hero = IapPurchaseApplier.apply(current, productId);
    await _save.persist(_hero!);
    notifyListeners();
    return true;
  }
}
