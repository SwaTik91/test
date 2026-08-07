import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art/art_atlas.dart';
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
import 'components/vfx_component.dart';
import 'run_rewards.dart';
import 'run_state.dart';
import 'run_upgrade_effects.dart';
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

  final List<SpriteComponent> _groundTiles = [];
  final List<MonsterComponent> _monsters = [];
  final List<ChestComponent> _chests = [];

  late final Sprite _projectileSprite;
  late final Sprite _bgFieldsSprite;
  late final Sprite _bgForestSprite;
  SpriteComponent? _biomeBackground;
  Biome _displayedBiome = Biome.fields;

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
  double _regenAccumulator = 0;
  double _jumpShieldTimer = 0;
  bool _secondWindConsumed = false;

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

    final groundSprite = await ArtAtlas.loadSprite(ArtAtlas.groundTile);
    _bgFieldsSprite = await ArtAtlas.loadSprite(ArtAtlas.bgFields);
    _bgForestSprite = await ArtAtlas.loadSprite(ArtAtlas.bgForest);
    _projectileSprite = await ArtAtlas.loadSprite(
      ArtAtlas.projectilePath(hero.classId),
    );

    _biomeBackground = SpriteComponent(
      sprite: _bgFieldsSprite,
      anchor: Anchor.center,
    );
    camera.backdrop.add(_biomeBackground!);
    _syncBiomeBackgroundLayout();
    _displayedBiome = biome;

    _addGroundTiles(groundSprite);

    player = await PlayerComponent.create(
      classId: hero.classId,
      maxHp: CombatMath.maxHp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
      maxSp: CombatMath.maxSp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
      moveSpeed: CombatMath.moveSpeed(
        hero,
        ownedUpgradeIds: ownedRunUpgradeIds,
      ),
      groundY: _groundY,
    );
    autoSkillSystem = AutoSkillSystem(
      classId: hero.classId,
      ranks: hero.skillRanks,
      upgrades: ownedRunUpgradeIds,
      maxSp: player.maxSp,
    );

    world.add(player);
    _spawnMonster();
    _spawnMonster();
    camera.follow(player, horizontalOnly: true, snap: true);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _syncBiomeBackgroundLayout();
  }

  void _syncBiomeBackgroundLayout() {
    final background = _biomeBackground;
    if (background == null) {
      return;
    }
    final viewportSize = camera.viewport.virtualSize;
    if (viewportSize.x <= 0 || viewportSize.y <= 0) {
      return;
    }
    const bgBottomCrop = 32.0;
    background
      ..size = Vector2(viewportSize.x, viewportSize.y + bgBottomCrop)
      ..position = Vector2(
        viewportSize.x / 2,
        viewportSize.y / 2 - bgBottomCrop / 2,
      );
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
    _syncBiomeIfNeeded();
    _spawnAheadIfNeeded();
    _spawnMilestonesIfNeeded();
    _handleAutoSkills(dt);
    _handleAutoAttack();
    _handleChestContact();
    _handleMonsterContact();
    _collectReadyKills();
    _tickPlayerUpgradeTimers(dt);
    _applyPlayerRegen(dt);
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
      _jumpPlayer();
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
    _jumpPlayer();
  }

  void _jumpPlayer() {
    if (!player.jump()) {
      return;
    }
    final shieldSeconds = RunUpgradeEffects.jumpShieldSeconds(
      ownedRunUpgradeIds,
    );
    if (shieldSeconds > 0) {
      _jumpShieldTimer = shieldSeconds;
    }
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

  void _addGroundTiles(Sprite groundSprite) {
    for (var i = 0; i < 8; i += 1) {
      final tile = SpriteComponent(
        sprite: groundSprite,
        position: Vector2(i * _tileWidth, _groundY),
        size: Vector2(_tileWidth, 72),
      );
      _groundTiles.add(tile);
      world.add(tile);
    }
  }

  void _syncBiomeIfNeeded() {
    final currentBiome = biome;
    if (currentBiome == _displayedBiome) {
      return;
    }
    _displayedBiome = currentBiome;
    _biomeBackground?.sprite = switch (currentBiome) {
      Biome.fields => _bgFieldsSprite,
      Biome.forest => _bgForestSprite,
    };
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
      _nextChestX += _chestDistanceIntervalPx;
    }
    while (_nextBossX <= aheadDistance) {
      if (SpawnSystem.shouldSpawnBoss(_nextBossX.round())) {
        _spawnMonster(spawnX: _nextBossX, isBoss: true);
      }
      _nextBossX += Balance.bossEveryDistancePx;
    }
  }

  void _spawnChest(double x) {
    ChestComponent.create(position: Vector2(x, _groundY - 34)).then((chest) {
      _chests.add(chest);
      world.add(chest);
    });
  }

  void _spawnMonster({double? spawnX, bool isBoss = false}) {
    final x = spawnX ?? _nextSpawnX;
    final monsterBiome = SpawnSystem.biomeAt(x);
    final spec = MonstersCatalog.forDistance(
      distancePx: x,
      biome: monsterBiome,
      isBoss: isBoss,
    );
    if (!isBoss) {
      _nextSpawnX += 430;
    }
    MonsterComponent.create(
      isBoss: spec.isBoss,
      target: player,
      position: Vector2(x, _groundY - spec.height),
      maxHp: _monsterMaxHp(spec),
      touchDamage: _monsterTouchDamage(spec),
      baseXp: spec.baseXp,
      jobXp: spec.jobXp,
      gold: spec.gold,
      tempXp: spec.tempXp,
      upgradeDropChance: _upgradeDropChanceFor(spec),
      moveSpeed: spec.moveSpeed,
      size: Vector2(spec.width, spec.height),
    ).then((monster) {
      _monsters.add(monster);
      world.add(monster);
    });
  }

  double get _chestDistanceIntervalPx =>
      Balance.chestEveryDistancePx *
      RunUpgradeEffects.chestDistanceMultiplier(ownedRunUpgradeIds);

  int _monsterMaxHp(MonsterSpec spec) {
    var maxHp = spec.maxHp.toDouble();
    if (spec.isBoss) {
      maxHp *= RunUpgradeEffects.bossMaxHpMultiplier(ownedRunUpgradeIds);
    }
    return maxHp.round().clamp(1, double.infinity).toInt();
  }

  int _monsterTouchDamage(MonsterSpec spec) {
    var touchDamage = spec.touchDamage.toDouble();
    if (spec.isBoss) {
      touchDamage *= RunUpgradeEffects.bossTouchDamageMultiplier(
        ownedRunUpgradeIds,
      );
    }
    return touchDamage.round().clamp(1, double.infinity).toInt();
  }

  double _upgradeDropChanceFor(MonsterSpec spec) {
    if (spec.isBoss) {
      return Balance.bossUpgradeDropChance;
    }
    final boostMultiplier = hero.hasActiveBoost('boost_drop')
        ? Balance.iapDropBoostMultiplier
        : 1.0;
    return (Balance.monsterUpgradeDropChance *
            boostMultiplier *
            RunUpgradeEffects.monsterDropChanceMultiplier(ownedRunUpgradeIds))
        .clamp(0, 1)
        .toDouble();
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

    _damageMonster(
      target,
      CombatMath.basicAttackDamage(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    _tryCollectKill(target);
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
    player.playCastAnimation();
    final targets = _targetsInRange(
      event.range,
    ).take(event.targetCount).toList(growable: false);
    if (targets.isEmpty) {
      _spawnSkillVfx(player.center);
    } else {
      for (final target in targets) {
        _spawnSkillVisual(event, target);
        _spawnSkillVfx(target.center);
        _damageMonster(target, event.damage, skillId: event.skillId);
        _tryCollectKill(target);
      }
    }
  }

  void _damageMonster(MonsterComponent target, int amount, {String? skillId}) {
    final before = target.currentHp;
    target.takeDamage(amount);
    final damageDealt = before - target.currentHp;
    if (damageDealt <= 0) {
      return;
    }

    final healFraction = RunUpgradeEffects.lifestealFraction(
      skillId,
      ownedRunUpgradeIds,
    );
    if (healFraction > 0) {
      player.heal((damageDealt * healFraction).round());
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
        sprite: _projectileSprite,
        start: event.projectile ? start : end,
        end: end,
        duration: event.projectile ? 0.18 : 0.14,
        radiusSize: event.kind == SkillCastKind.ultimate ? 14 : 7,
      ),
    );
  }

  void _spawnSkillVfx(Vector2 position) {
    VfxComponent.create(
      kind: VfxComponent.forClass(hero.classId),
      position: position,
    ).then((vfx) => world.add(vfx));
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
    final touchingMonsters = touching.toList(growable: false);
    final rawDamage = touchingMonsters.fold<int>(
      0,
      (sum, monster) => sum + monster.touchDamage,
    );
    final effectiveDamage = _incomingDamage(rawDamage);
    _applyThorns(touchingMonsters, effectiveDamage);
    _damagePlayer(effectiveDamage);
    _publishHud();
    if (player.isDead) {
      _finishRun();
    }
  }

  int _incomingDamage(int rawDamage) {
    if (_jumpShieldTimer > 0) {
      return 0;
    }
    return (rawDamage *
            RunUpgradeEffects.incomingDamageMultiplier(ownedRunUpgradeIds))
        .round()
        .clamp(0, double.infinity)
        .toInt();
  }

  void _damagePlayer(int amount) {
    if (amount <= 0) {
      return;
    }
    if (!_secondWindConsumed &&
        RunUpgradeEffects.hasSecondWind(ownedRunUpgradeIds) &&
        amount >= player.currentHp) {
      _secondWindConsumed = true;
      player.currentHp = 1;
      return;
    }
    player.takeDamage(amount);
  }

  void _applyThorns(List<MonsterComponent> touchingMonsters, int damageTaken) {
    final thornsFraction = RunUpgradeEffects.thornsFraction(ownedRunUpgradeIds);
    if (thornsFraction <= 0 || damageTaken <= 0) {
      return;
    }

    final reflectedDamage = (damageTaken * thornsFraction).round().clamp(
      1,
      9999,
    );
    for (final monster in touchingMonsters) {
      if (!monster.isAlive) {
        continue;
      }
      monster.takeDamage(reflectedDamage.toInt());
      _tryCollectKill(monster);
    }
  }

  void _tryCollectKill(MonsterComponent monster) {
    if (monster.canCollect) {
      _collectKill(monster);
    }
  }

  void _collectReadyKills() {
    for (final monster in _monsters.toList(growable: false)) {
      if (monster.canCollect) {
        _collectKill(monster);
      }
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
      gold: _goldFor(monster),
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
      monsterDropChance: monster.upgradeDropChance,
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
    var amount =
        monster.tempXp.toDouble() *
        RunUpgradeEffects.tempXpMultiplier(ownedRunUpgradeIds);
    return amount.round().clamp(1, Balance.tempXpPerUpgrade).toInt();
  }

  int _goldFor(MonsterComponent monster) {
    return (monster.gold *
            RunUpgradeEffects.goldMultiplier(
              ownedRunUpgradeIds,
              isBoss: monster.isBoss,
            ))
        .round();
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
    while (!_finished &&
        !_isUpgradePickerActive &&
        _queuedOfferRequests.isNotEmpty) {
      _tryPresentUpgradeOffer(_queuedOfferRequests.removeAt(0));
    }
  }

  void chooseUpgrade(String id) {
    if (!_pendingUpgradeOffers.any((offer) => offer.id == id)) {
      return;
    }

    ownedRunUpgradeIds.add(id);
    _syncPlayerUpgradeStats();
    _setRunState(_runState.copyWith(ownedUpgradeIds: {...ownedRunUpgradeIds}));
    _pendingUpgradeOffers = const [];
    overlays.remove(upgradePickerOverlayKey);
    if (!_finished) {
      resumeEngine();
      _drainQueuedOfferRequests();
    }
    _publishHud();
  }

  void _syncPlayerUpgradeStats() {
    player.setMaxHp(
      CombatMath.maxHp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    player.setMaxSp(
      CombatMath.maxSp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    player.setMoveSpeed(
      CombatMath.moveSpeed(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    autoSkillSystem.setMaxSp(player.maxSp);
  }

  void _tickPlayerUpgradeTimers(double dt) {
    if (_jumpShieldTimer > 0) {
      _jumpShieldTimer = (_jumpShieldTimer - dt)
          .clamp(0, double.infinity)
          .toDouble();
    }
  }

  void _applyPlayerRegen(double dt) {
    final hpPerSecond = RunUpgradeEffects.hpRegenPerSecond(ownedRunUpgradeIds);
    if (hpPerSecond <= 0 || player.currentHp >= player.maxHp) {
      _regenAccumulator = 0;
      return;
    }

    _regenAccumulator += hpPerSecond * dt;
    final healing = _regenAccumulator.floor();
    if (healing <= 0) {
      return;
    }
    player.heal(healing);
    _regenAccumulator -= healing;
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
