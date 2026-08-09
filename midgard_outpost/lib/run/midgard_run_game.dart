import 'dart:async';
import 'dart:math' as math;

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
import 'run_layout.dart';
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
    math.Random? rng,
  }) : _runState = initialRunState,
       ownedRunUpgradeIds = {...initialRunState.ownedUpgradeIds},
       _rng = rng ?? math.Random();

  static const String hudOverlayKey = 'hud';
  static const String upgradePickerOverlayKey = 'upgradePicker';
  static const double _attackInterval = 0.75;
  static const double _collisionInterval = 0.65;

  final HeroProgress hero;
  final void Function(RunRewards rewards) onDeath;
  final ValueChanged<RunState>? onRunStateChanged;
  final Set<String> ownedRunUpgradeIds;
  final RunRewardsAccumulator rewards = RunRewardsAccumulator();
  final ValueNotifier<int> hudRevision = ValueNotifier<int>(0);
  final math.Random _rng;

  late final PlayerComponent player;
  late final AutoSkillSystem autoSkillSystem;
  late final String autoSkillName;

  /// False until [onLoad] finishes creating [player] and systems.
  /// HUD overlays must check this — they can mount before [onLoad] completes.
  bool isRunReady = false;

  /// Debug/test breadcrumb for where [onLoad] is / last failed.
  String loadStage = 'constructed';
  Object? loadError;

  final List<SpriteComponent> _groundTiles = [];
  Sprite? _groundSprite;

  @visibleForTesting
  List<SpriteComponent> get groundTilesForTest => _groundTiles;

  @visibleForTesting
  bool groundCoversVisibleSpan({double? viewportWidth}) {
    if (_groundTiles.isEmpty) {
      return false;
    }
    final width = viewportWidth ?? _viewportWidth;
    final visible = _visibleWorldHorizontalSpan(width);
    final minX = _groundTiles
        .map((tile) => tile.position.x)
        .reduce(math.min);
    final maxX = _groundTiles
        .map((tile) => tile.position.x + tile.size.x)
        .reduce(math.max);
    return minX <= visible.left && maxX >= visible.right;
  }

  @visibleForTesting
  bool groundCoversViewportBottom({double? viewportHeight}) {
    if (_groundTiles.isEmpty) {
      return false;
    }
    final height = viewportHeight ?? camera.viewport.virtualSize.y;
    if (height <= 0) {
      return false;
    }
    final maxBottom = _groundTiles
        .map((tile) => tile.position.y + tile.size.y)
        .reduce(math.max);
    final viewportBottomY = camera.viewfinder.globalToLocal(
      Vector2(_groundCameraCenterX, maxBottom),
    ).y;
    return viewportBottomY >= height - 0.5;
  }

  @visibleForTesting
  bool backdropCoversViewport({double? viewportWidth, double? viewportHeight}) {
    final background = _biomeBackground;
    if (background == null) {
      return false;
    }
    final width = viewportWidth ?? _viewportWidth;
    final height = viewportHeight ?? camera.viewport.virtualSize.y;
    if (width <= 0 || height <= 0) {
      return false;
    }
    final bounds = _layout.backdropViewportBounds(
      size: background.size,
      viewportWidth: width,
      viewportHeight: height,
    );
    return bounds.left <= 0 &&
        bounds.top <= 0 &&
        bounds.right >= width &&
        bounds.bottom >= height;
  }

  @visibleForTesting
  bool leftEdgeCoveredAtStart({double? viewportWidth, double? viewportHeight}) {
    final width = viewportWidth ?? _viewportWidth;
    final height = viewportHeight ?? camera.viewport.virtualSize.y;
    return groundCoversVisibleSpan(viewportWidth: width) &&
        backdropCoversViewport(viewportWidth: width, viewportHeight: height);
  }

  @visibleForTesting
  bool groundTilesAreContiguous() {
    if (_groundTiles.length < 2) {
      return true;
    }
    final tiles = List<SpriteComponent>.from(_groundTiles)
      ..sort((a, b) => a.position.x.compareTo(b.position.x));
    for (var i = 0; i < tiles.length - 1; i++) {
      final gap = tiles[i + 1].position.x - (tiles[i].position.x + tiles[i].size.x);
      if (gap.abs() > 0.5) {
        return false;
      }
    }
    return true;
  }

  @visibleForTesting
  SpriteComponent? get biomeBackgroundForTest => _biomeBackground;

  @visibleForTesting
  void registerMonsterForTest(MonsterComponent monster) {
    _monsters.add(monster);
  }
  final List<MonsterComponent> _monsters = [];
  final List<ChestComponent> _chests = [];

  late final Sprite _projectileSprite;
  late final Sprite _bgFieldsSkySprite;
  late final Sprite _bgForestSkySprite;
  SpriteComponent? _biomeBackground;
  Biome _displayedBiome = Biome.fields;
  RunLayout _layout = RunLayout(RunLayout.referenceHeight);

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

  double get distance => isRunReady ? player.position.x : 0;

  Biome get biome => SpawnSystem.biomeAt(distance);

  String get biomeLabel => biome.label;

  double get hpFraction =>
      isRunReady ? player.currentHp / player.maxHp : 1;

  double get spFraction =>
      isRunReady ? player.currentSp / player.maxSp : 1;

  double get ultimateCooldownRemaining =>
      isRunReady ? autoSkillSystem.ultimateCooldownRemaining : 0;

  RunRewards get currentRewards => rewards.toRewards();

  RunState get runState => _runState;

  List<RunUpgradeDef> get pendingUpgradeOffers => _pendingUpgradeOffers;

  @override
  Color backgroundColor() => const Color(0xFF101826);

  @override
  FutureOr<void> onLoad() async {
    try {
      loadStage = 'super';
      await super.onLoad();

      loadStage = 'autoSkillName';
      autoSkillName = _autoSkillNameForHero();

      loadStage = 'sprites';
      final groundSprite = await ArtAtlas.loadSprite(ArtAtlas.groundTile);
      final bgFieldsSprite = await ArtAtlas.loadSprite(ArtAtlas.bgFields);
      final bgForestSprite = await ArtAtlas.loadSprite(ArtAtlas.bgForest);
      _bgFieldsSkySprite = _skyBackdropCrop(bgFieldsSprite);
      _bgForestSkySprite = _skyBackdropCrop(bgForestSprite);
      _projectileSprite = await ArtAtlas.loadSprite(
        ArtAtlas.projectilePath(hero.classId),
      );

      loadStage = 'layout';
      _layout = _currentLayout();

      loadStage = 'backdrop';
      _biomeBackground = SpriteComponent(
        sprite: _bgFieldsSkySprite,
        anchor: Anchor.bottomLeft,
      );
      ArtAtlas.applyNearestNeighbor(_biomeBackground!);
      camera.backdrop.add(_biomeBackground!);
      _syncBiomeBackgroundLayout();
      // Do not read [biome]/[distance] before [player] exists.
      _displayedBiome = SpawnSystem.biomeAt(0);

      loadStage = 'ground';
      _addGroundTiles(groundSprite);

      loadStage = 'player';
      player = await PlayerComponent.create(
        classId: hero.classId,
        maxHp: CombatMath.maxHp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
        maxSp: CombatMath.maxSp(hero, ownedUpgradeIds: ownedRunUpgradeIds),
        moveSpeed: CombatMath.moveSpeed(
          hero,
          ownedUpgradeIds: ownedRunUpgradeIds,
        ),
        groundY: _layout.groundY,
        size: _layout.playerSize,
      );
      autoSkillSystem = AutoSkillSystem(
        classId: hero.classId,
        ranks: hero.skillRanks,
        upgrades: ownedRunUpgradeIds,
        maxSp: player.maxSp,
      );

      loadStage = 'world';
      world.add(player);
      _spawnMonster();
      _spawnMonster();
      _configureCameraFollow();

      loadStage = 'hud';
      isRunReady = true;
      _applyLayout();
      overlays.add(hudOverlayKey);
      loadStage = 'ready';
    } catch (e, st) {
      loadError = e;
      loadStage = 'error:$loadStage';
      Error.throwWithStackTrace(e, st);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyLayout();
  }

  RunLayout _currentLayout() {
    final height = camera.viewport.virtualSize.y;
    return RunLayout(
      height > 0 ? height : RunLayout.referenceHeight,
    );
  }

  double get _viewportWidth {
    final width = camera.viewport.virtualSize.x;
    return width > 0 ? width : 1280;
  }

  double get _groundCameraCenterX =>
      isRunReady ? player.position.x : PlayerComponent.startX;

  ({double left, double right}) _visibleWorldHorizontalSpan(double viewportWidth) {
    if (isRunReady && camera.parent != null) {
      final rect = camera.visibleWorldRect;
      return (left: rect.left, right: rect.right);
    }
    final centerX = _groundCameraCenterX;
    return (
      left: centerX - viewportWidth / 2,
      right: centerX + viewportWidth / 2,
    );
  }

  ({double left, double right}) _groundSpanForLayout() {
    if (isRunReady && camera.parent != null) {
      return _layout.groundWorldSpanFromVisibleRect(
        visibleWorldRect: camera.visibleWorldRect,
      );
    }
    return _layout.groundWorldSpan(
      cameraCenterX: _groundCameraCenterX,
      viewportWidth: _viewportWidth,
      extraLeftMarginTiles: 1,
    );
  }

  Sprite _skyBackdropCrop(Sprite full) {
    final skyHeight = full.srcSize.y * RunLayout.backdropSkyFraction;
    return Sprite(
      full.image,
      srcPosition: Vector2.zero(),
      srcSize: Vector2(full.srcSize.x, skyHeight),
    );
  }

  void _applyLayout() {
    _layout = _currentLayout();
    _syncBiomeBackgroundLayout();
    _syncGroundTilesLayout();
    _syncCameraLayout();
    if (isRunReady) {
      player
        ..setGroundY(_layout.groundY)
        ..setSize(_layout.playerSize);
    }
  }

  void _configureCameraFollow() {
    camera.viewfinder.anchor = Anchor(0.5, RunLayout.groundTopFraction);
    camera.follow(player, horizontalOnly: true, snap: true);
    _syncCameraLayout();
  }

  void _syncCameraLayout() {
    if (!isRunReady) {
      return;
    }
    camera.viewfinder.anchor = Anchor(0.5, RunLayout.groundTopFraction);
    camera.viewfinder.position = Vector2(
      player.position.x,
      _layout.groundY,
    );
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
    final coverSize = _layout.backdropCoverSize(
      regionWidth: viewportSize.x,
      regionHeight: viewportSize.y,
      srcSize: background.sprite!.srcSize,
    );
    background
      ..size = coverSize
      ..position = Vector2(-RunLayout.backdropBleedPx, viewportSize.y);
  }

  void _syncGroundTilesLayout() {
    _layoutGroundTilePositions();
  }

  void _layoutGroundTilePositions() {
    final groundY = _layout.groundY;
    final tileWidth = _layout.groundTileWidth;
    var tileHeight = _layout.groundTileHeight;
    if (isRunReady && camera.parent != null) {
      final visibleBottom = camera.visibleWorldRect.bottom;
      tileHeight = math.max(
        tileHeight,
        visibleBottom - groundY + RunLayout.groundBottomBleedPx,
      );
    }
    final span = _groundSpanForLayout();
    final needed = _layout.groundTileCountForSpan(
      worldLeft: span.left,
      worldRight: span.right,
    );
    _ensureGroundTileCount(needed);

    final startX = _layout.groundTileStartX(span.left);
    final tiles = List<SpriteComponent>.from(_groundTiles)
      ..sort((a, b) => a.position.x.compareTo(b.position.x));
    for (var i = 0; i < tiles.length; i++) {
      tiles[i]
        ..position = Vector2(startX + i * tileWidth, groundY)
        ..size = Vector2(tileWidth, tileHeight);
    }
  }

  void _ensureGroundTileCount(int needed) {
    final sprite = _groundSprite;
    if (sprite == null || _groundTiles.length >= needed) {
      return;
    }
    while (_groundTiles.length < needed) {
      final tile = SpriteComponent(
        sprite: sprite,
        anchor: Anchor.topLeft,
      );
      // Soft filter — grass tile is painterly, not pixel-grid art.
      tile.paint.filterQuality = FilterQuality.low;
      _groundTiles.add(tile);
      world.add(tile);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished || !isRunReady) {
      return;
    }

    _attackTimer += dt;
    _collisionTimer += dt;
    _hudTimer += dt;

    _syncGroundTilesLayout();
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
    _groundSprite = groundSprite;
    final span = _layout.groundWorldSpan(
      cameraCenterX: PlayerComponent.startX,
      viewportWidth: _viewportWidth,
      extraLeftMarginTiles: 1,
    );
    final needed = _layout.groundTileCountForSpan(
      worldLeft: span.left,
      worldRight: span.right,
    );
    for (var i = 0; i < needed; i++) {
      final tile = SpriteComponent(
        sprite: groundSprite,
        anchor: Anchor.topLeft,
      );
      tile.paint.filterQuality = FilterQuality.low;
      _groundTiles.add(tile);
      world.add(tile);
    }
    _layoutGroundTilePositions();
  }

  void _syncBiomeIfNeeded() {
    final currentBiome = biome;
    if (currentBiome == _displayedBiome) {
      return;
    }
    _displayedBiome = currentBiome;
    _biomeBackground?.sprite = switch (currentBiome) {
      Biome.fields => _bgFieldsSkySprite,
      Biome.forest => _bgForestSkySprite,
    };
    _syncBiomeBackgroundLayout();
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
    ChestComponent.create(
      position: Vector2(x, _layout.groundY),
      size: _layout.chestSize,
    ).then((chest) {
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
      _nextSpawnX += _layout.mobSpawnSpacing;
    }
    final mobSize = _layout.mobSize(isBoss: spec.isBoss);
    MonsterComponent.create(
      kind: spec.kind,
      isBoss: spec.isBoss,
      target: player,
      position: Vector2(x, _layout.groundY),
      maxHp: _monsterMaxHp(spec),
      touchDamage: _monsterTouchDamage(spec),
      baseXp: spec.baseXp,
      jobXp: spec.jobXp,
      gold: spec.gold,
      tempXp: spec.tempXp,
      upgradeDropChance: _upgradeDropChanceFor(spec),
      moveSpeed: spec.moveSpeed,
      attackRange: spec.attackRange,
      attackInterval: spec.attackInterval,
      onRangedAttack: spec.attackRange > 0 ? _onMonsterRangedAttack : null,
      size: mobSize,
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

    player.playCastAnimation();
    _spawnBasicAttackVisual(target);
    _damageMonster(
      target,
      CombatMath.basicAttackDamage(hero, ownedUpgradeIds: ownedRunUpgradeIds),
    );
    _tryCollectKill(target);
  }

  void _spawnBasicAttackVisual(MonsterComponent target) {
    final start = player.center;
    final end = target.center;
    final isRanged = hero.classId != HeroClassId.paladin;
    if (isRanged) {
      world.add(
        ProjectileComponent(
          sprite: _projectileSprite,
          start: start,
          end: end,
          duration: 0.18,
          visualHeight: ProjectileComponent.basicVisualHeight,
        )..paint.filterQuality = FilterQuality.none,
      );
      return;
    }

    _spawnSkillVfx(end);
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
      return dx <= range && dy < _layout.verticalCombatReach;
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
          return dy < _layout.verticalCombatReach;
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
        visualHeight: event.kind == SkillCastKind.ultimate
            ? ProjectileComponent.ultimateVisualHeight
            : ProjectileComponent.skillVisualHeight,
      )..paint.filterQuality = FilterQuality.none,
    );
  }

  void _onMonsterRangedAttack(MonsterComponent monster) {
    if (_finished || !isRunReady || !monster.isAlive) {
      return;
    }

    final start = monster.center;
    final end = player.center;
    world.add(
      ProjectileComponent(
        sprite: _projectileSprite,
        start: start,
        end: end,
        duration: 0.22,
        visualHeight: ProjectileComponent.skillVisualHeight,
      )..paint.filterQuality = FilterQuality.none,
    );

    final dx = (player.position.x - monster.position.x).abs();
    final dy = (player.position.y - monster.position.y).abs();
    if (dx <= monster.attackRange + 24 && dy < _layout.verticalCombatReach) {
      final damage = _incomingDamage(monster.touchDamage);
      _damagePlayer(damage);
      _publishHud();
      if (player.isDead) {
        _finishRun();
      }
    }
  }

  void _spawnSkillVfx(Vector2 position) {
    VfxComponent.create(
      kind: VfxComponent.forClass(hero.classId),
      position: position,
    ).then(
      (vfx) {
        if (vfx != null) {
          world.add(vfx);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'MidgardRunGame',
            context: ErrorDescription('while spawning skill VFX'),
          ),
        );
      },
    );
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
