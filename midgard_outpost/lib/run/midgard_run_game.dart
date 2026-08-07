import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/balance.dart';
import '../content/monsters.dart';
import '../content/run_upgrades.dart';
import '../content/skills.dart';
import '../core/ids.dart';
import '../progress/hero_progress.dart';
import 'combat_math.dart';
import 'components/chest_component.dart';
import 'components/monster_component.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';
import 'run_rewards.dart';
import 'run_state.dart';
import 'upgrade_offer_service.dart';
import 'systems/auto_skill_system.dart';
import 'systems/spawn_system.dart' hide Biome;

class MidgardRunGame extends FlameGame with KeyboardEvents {
  MidgardRunGame({
    required this.hero,
    required this.onDeath,
    required RunState initialRunState,
    this.onRunStateChanged,
    Random? rng,
  }) : _runState = initialRunState,
       ownedRunUpgradeIds = {...initialRunState.ownedUpgradeIds},
       _rng = rng ?? Random();

  static const String hudOverlayKey = 'hud';
  static const String upgradePickerOverlayKey = 'upgradePicker';
  static const double _groundY = 330;
  static const double _tileWidth = 360;
  static const double _attackInterval = 0.75;
  static const double _collisionInterval = 0.65;

  final HeroProgress hero;
  final void Function(RunRewards rewards) onDeath;
  final ValueChanged<RunState>? onRunStateChanged;
  final Set<String> ownedRunUpgradeIds;
  final RunRewardsAccumulator rewards = RunRewardsAccumulator();
  final ValueNotifier<int> hudRevision = ValueNotifier<int>(0);
  final Random _rng;

  late final PlayerComponent player;
  late final AutoSkillSystem autoSkillSystem;
  late final String autoSkillName;

  final List<RectangleComponent> _groundTiles = [];
  final List<MonsterComponent> _monsters = [];
  final List<ChestComponent> _chests = [];

  RunState _runState;
  List<RunUpgradeDef> _pendingUpgradeOffers = const [];
  final List<_PendingOfferRequest> _queuedOfferRequests = [];
  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _finished = false;
  double _attackTimer = 0;
  double _collisionTimer = 0;
  double _hudTimer = 0;
  double _nextSpawnX = 520;
  double _nextChestX = Balance.chestEveryDistancePx.toDouble();
  double _nextBossX = Balance.bossEveryDistancePx.toDouble();

  double get distance => player.position.x;

  Biome get biome => SpawnSystem.biomeAt(distance);

  String get biomeLabel => biome.label;

  double get hpFraction => player.currentHp / player.maxHp;

  double get spFraction => player.currentSp / player.maxSp;

  double get ultimateCooldownRemaining =>
      autoSkillSystem.ultimateCooldownRemaining;

  RunRewards get currentRewards => rewards.toRewards();

  RunState get runState => _runState;

  List<RunUpgradeDef> get pendingUpgradeOffers => _pendingUpgradeOffers;

  @override
  Color backgroundColor() => const Color(0xFF101826);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    autoSkillName = _autoSkillNameForHero();

    player = PlayerComponent(
      maxHp: CombatMath.maxHp(hero),
      maxSp: CombatMath.maxSp(hero),
      moveSpeed: CombatMath.moveSpeed(hero),
      groundY: _groundY,
    );
    autoSkillSystem = AutoSkillSystem(
      classId: hero.classId,
      ranks: hero.skillRanks,
      upgrades: ownedRunUpgradeIds,
      maxSp: player.maxSp,
    );

    _addGroundTiles();
    world.add(player);
    _spawnMonster();
    _spawnMonster();
    camera.follow(player, horizontalOnly: true, snap: true);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) {
      return;
    }

    _attackTimer += dt;
    _collisionTimer += dt;
    _hudTimer += dt;

    _recycleGroundTiles();
    _spawnAheadIfNeeded();
    _spawnMilestonesIfNeeded();
    _handleAutoSkills(dt);
    _handleAutoAttack();
    _handleChestContact();
    _handleMonsterContact();
    _publishHudIfNeeded();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _leftPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    _rightPressed =
        keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);
    _syncMovement();

    if (keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      player.jump();
    }

    return KeyEventResult.handled;
  }

  void setLeftPressed(bool pressed) {
    _leftPressed = pressed;
    _syncMovement();
  }

  void setRightPressed(bool pressed) {
    _rightPressed = pressed;
    _syncMovement();
  }

  void jump() {
    player.jump();
  }

  void tryCastUltimate() {
    autoSkillSystem.sp = player.currentSp;
    final enemyDistances = _targetDistances();
    final event = autoSkillSystem.tryCastUltimate(
      enemiesInRange: enemyDistances.length,
      enemyDistances: enemyDistances,
    );
    player.setSp(autoSkillSystem.sp);
    if (event != null) {
      _applySkillEvent(event);
    }
    _publishHud();
  }

  String _autoSkillNameForHero() {
    final autoSkills = SkillsCatalog.forClass(
      hero.classId,
    ).where((skill) => skill.kind == SkillKind.auto);
    return autoSkills
        .firstWhere(
          (skill) => (hero.skillRanks[skill.id] ?? 0) > 0,
          orElse: () => autoSkills.first,
        )
        .name;
  }

  void _syncMovement() {
    final axis = (_rightPressed ? 1 : 0) - (_leftPressed ? 1 : 0);
    player.setHorizontal(axis.toDouble());
  }

  void _addGroundTiles() {
    for (var i = 0; i < 8; i += 1) {
      final tile = RectangleComponent(
        position: Vector2(i * _tileWidth, _groundY),
        size: Vector2(_tileWidth, 72),
        paint: Paint()
          ..color = i.isEven
              ? const Color(0xFF2E5E3E)
              : const Color(0xFF294F36),
      );
      _groundTiles.add(tile);
      world.add(tile);
    }
  }

  void _recycleGroundTiles() {
    for (final tile in _groundTiles) {
      if (tile.position.x + tile.size.x < player.position.x - 900) {
        tile.position.x += _groundTiles.length * _tileWidth;
      }
    }
  }

  void _spawnAheadIfNeeded() {
    while (player.position.x + 920 > _nextSpawnX) {
      _spawnMonster();
    }
  }

  void _spawnMilestonesIfNeeded() {
    final aheadDistance = player.position.x + 920;
    while (_nextChestX <= aheadDistance) {
      if (SpawnSystem.shouldSpawnChest(_nextChestX.round())) {
        _spawnChest(_nextChestX);
      }
      _nextChestX += Balance.chestEveryDistancePx;
    }
    while (_nextBossX <= aheadDistance) {
      if (SpawnSystem.shouldSpawnBoss(_nextBossX.round())) {
        _spawnMonster(spawnX: _nextBossX, isBoss: true);
      }
      _nextBossX += Balance.bossEveryDistancePx;
    }
  }

  void _spawnChest(double x) {
    final chest = ChestComponent(position: Vector2(x, _groundY - 34));
    _chests.add(chest);
    world.add(chest);
  }

  void _spawnMonster({double? spawnX, bool isBoss = false}) {
    final x = spawnX ?? _nextSpawnX;
    final monsterBiome = SpawnSystem.biomeAt(x);
    final spec = MonstersCatalog.forDistance(
      distancePx: x,
      biome: monsterBiome,
      isBoss: isBoss,
    );
    final monster = MonsterComponent(
      target: player,
      position: Vector2(x, _groundY - spec.height),
      maxHp: spec.maxHp,
      touchDamage: spec.touchDamage,
      baseXp: spec.baseXp,
      jobXp: spec.jobXp,
      gold: spec.gold,
      tempXp: spec.tempXp,
      upgradeDropChance: spec.isBoss
          ? Balance.bossUpgradeDropChance
          : Balance.monsterUpgradeDropChance,
      isBoss: spec.isBoss,
      moveSpeed: spec.moveSpeed,
      size: Vector2(spec.width, spec.height),
      color: _monsterColor(spec),
    );
    if (!isBoss) {
      _nextSpawnX += 430;
    }
    _monsters.add(monster);
    world.add(monster);
  }

  Color _monsterColor(MonsterSpec spec) {
    if (spec.isBoss) {
      return Colors.purpleAccent;
    }
    return switch (spec.biome) {
      Biome.fields => Colors.deepOrangeAccent,
      Biome.forest => Colors.greenAccent,
    };
  }

  void _handleAutoAttack() {
    if (_attackTimer < _attackInterval) {
      return;
    }
    _attackTimer = 0;

    final target = _nearestTargetInRange();
    if (target == null) {
      return;
    }

    target.takeDamage(
      CombatMath.basicAttackDamage(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    if (!target.isAlive) {
      _collectKill(target);
    }
  }

  void _handleAutoSkills(double dt) {
    autoSkillSystem.sp = player.currentSp;
    final enemyDistances = _targetDistances();
    final events = autoSkillSystem.tick(
      dt,
      enemiesInRange: enemyDistances.length,
      enemyDistances: enemyDistances,
    );
    player.setSp(autoSkillSystem.sp);

    if (events.isEmpty) {
      return;
    }

    for (final event in events) {
      _applySkillEvent(event);
    }
    _publishHud();
  }

  void _applySkillEvent(SkillCastEvent event) {
    final targets = _targetsInRange(
      event.range,
    ).take(event.targetCount).toList(growable: false);
    for (final target in targets) {
      _spawnSkillVisual(event, target);
      target.takeDamage(event.damage);
      if (!target.isAlive) {
        _collectKill(target);
      }
    }
  }

  MonsterComponent? _nearestTargetInRange() {
    final range = _attackRangeForClass(hero.classId);
    final targets = _targetsInRange(range);
    return targets.isEmpty ? null : targets.first;
  }

  double _attackRangeForClass(HeroClassId classId) {
    return switch (classId) {
      HeroClassId.archer => 320,
      HeroClassId.mage => 280,
      HeroClassId.paladin => 72,
    };
  }

  List<MonsterComponent> _targetsInRange(double range) {
    final targets = _monsters.where((monster) {
      if (!monster.isAlive) {
        return false;
      }
      final dx = (monster.position.x - player.position.x).abs();
      final dy = (monster.position.y - player.position.y).abs();
      return dx <= range && dy < 130;
    }).toList();
    targets.sort(
      (a, b) => (a.position.x - player.position.x).abs().compareTo(
        (b.position.x - player.position.x).abs(),
      ),
    );
    return targets;
  }

  List<double> _targetDistances() {
    final distances = _monsters
        .where((monster) {
          if (!monster.isAlive) {
            return false;
          }
          final dy = (monster.position.y - player.position.y).abs();
          return dy < 130;
        })
        .map((monster) => (monster.position.x - player.position.x).abs())
        .toList();
    distances.sort();
    return distances;
  }

  void _spawnSkillVisual(SkillCastEvent event, MonsterComponent target) {
    final start = player.center;
    final end = target.center;
    world.add(
      ProjectileComponent(
        start: event.projectile ? start : end,
        end: end,
        duration: event.projectile ? 0.18 : 0.14,
        radiusSize: event.kind == SkillCastKind.ultimate ? 14 : 7,
        color: _skillColor(event),
      ),
    );
  }

  Color _skillColor(SkillCastEvent event) {
    if (event.kind == SkillCastKind.ultimate) {
      return Colors.amberAccent;
    }
    return switch (hero.classId) {
      HeroClassId.archer => Colors.lightGreenAccent,
      HeroClassId.mage => Colors.deepPurpleAccent,
      HeroClassId.paladin => Colors.white,
    };
  }

  void _handleMonsterContact() {
    if (_collisionTimer < _collisionInterval) {
      return;
    }

    final touching = _monsters.where(
      (monster) => monster.isAlive && monster.bounds.overlaps(player.bounds),
    );
    if (touching.isEmpty) {
      return;
    }

    _collisionTimer = 0;
    player.takeDamage(
      touching.fold<int>(0, (sum, monster) => sum + monster.touchDamage),
    );
    _publishHud();
    if (player.isDead) {
      _finishRun();
    }
  }

  void _handleChestContact() {
    if (_isUpgradePickerActive) {
      return;
    }

    for (final chest in _chests.toList(growable: false)) {
      if (!chest.isCollected && chest.bounds.overlaps(player.bounds)) {
        _requestUpgradeOffer(_PendingOfferRequest.chest(chest));
        break;
      }
    }
  }

  void _collectKill(MonsterComponent monster) {
    rewards.addKill(
      baseXp: monster.baseXp,
      jobXp: monster.jobXp,
      gold: monster.gold,
    );
    monster.removeFromParent();
    _monsters.remove(monster);

    final xpResult = UpgradeOfferService.addTempXp(
      _runState,
      _tempXpFor(monster),
    );
    final shouldOffer = UpgradeOfferService.shouldTriggerOfferFromKill(
      isBoss: monster.isBoss,
      tempXpThresholdReached: xpResult.thresholdReached,
      rng: _rng,
    );
    if (shouldOffer) {
      _setRunState(xpResult.state);
      _requestUpgradeOffer(
        _PendingOfferRequest.kill(
          consumeTempXpThreshold: xpResult.thresholdReached,
        ),
      );
    } else {
      _setRunState(xpResult.state);
    }

    _publishHud();
  }

  int _tempXpFor(MonsterComponent monster) {
    var amount = monster.tempXp.toDouble();
    if (ownedRunUpgradeIds.contains('temp_xp_boost')) {
      amount *= 1.25;
    }
    return amount.round().clamp(1, Balance.tempXpPerUpgrade).toInt();
  }

  bool get _isUpgradePickerActive => _pendingUpgradeOffers.isNotEmpty;

  void _requestUpgradeOffer(_PendingOfferRequest request) {
    if (_finished) {
      return;
    }
    if (_isUpgradePickerActive) {
      _queuedOfferRequests.add(request);
      return;
    }
    _tryPresentUpgradeOffer(request);
  }

  void _tryPresentUpgradeOffer(_PendingOfferRequest request) {
    final offers = UpgradeOfferService.rollOffer(
      classId: hero.classId,
      owned: ownedRunUpgradeIds,
      rng: _rng,
    );
    if (offers.isEmpty) {
      _applyOfferRequestWithoutOffer(request);
      return;
    }

    _applyOfferRequestWithOffer(request);
    _pendingUpgradeOffers = offers;
    pauseEngine();
    overlays.add(upgradePickerOverlayKey);
    _publishHud();
  }

  void _applyOfferRequestWithoutOffer(_PendingOfferRequest request) {
    // Kill temp XP is already applied; chest stays uncollected on empty offers.
  }

  void _applyOfferRequestWithOffer(_PendingOfferRequest request) {
    final chest = request.chest;
    if (chest != null && !chest.isCollected) {
      chest.collect();
      _chests.remove(chest);
    }

    if (request.consumeTempXpThreshold) {
      _setRunState(UpgradeOfferService.consumeTempXpThreshold(_runState));
    }
  }

  void _drainQueuedOfferRequests() {
    while (!_finished && !_isUpgradePickerActive && _queuedOfferRequests.isNotEmpty) {
      _tryPresentUpgradeOffer(_queuedOfferRequests.removeAt(0));
    }
  }

  void chooseUpgrade(String id) {
    if (!_pendingUpgradeOffers.any((offer) => offer.id == id)) {
      return;
    }

    ownedRunUpgradeIds.add(id);
    _setRunState(_runState.copyWith(ownedUpgradeIds: {...ownedRunUpgradeIds}));
    _pendingUpgradeOffers = const [];
    overlays.remove(upgradePickerOverlayKey);
    if (!_finished) {
      resumeEngine();
      _drainQueuedOfferRequests();
    }
    _publishHud();
  }

  void _publishHudIfNeeded() {
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  void _publishHud() {
    _syncRunDistance();
    hudRevision.value += 1;
  }

  void _syncRunDistance() {
    final distancePx = distance.round();
    if (_runState.distancePx == distancePx) {
      return;
    }
    _setRunState(_runState.copyWith(distancePx: distancePx));
  }

  void _setRunState(RunState state) {
    _runState = state;
    onRunStateChanged?.call(_runState);
  }

  void _finishRun() {
    if (_finished) {
      return;
    }
    _finished = true;
    pauseEngine();
    onDeath(rewards.toRewards());
  }
}

class _PendingOfferRequest {
  const _PendingOfferRequest.chest(this.chest) : consumeTempXpThreshold = false;

  const _PendingOfferRequest.kill({required this.consumeTempXpThreshold})
    : chest = null;

  final ChestComponent? chest;
  final bool consumeTempXpThreshold;
}
