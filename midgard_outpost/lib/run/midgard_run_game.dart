import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/skills.dart';
import '../core/ids.dart';
import '../progress/hero_progress.dart';
import 'combat_math.dart';
import 'components/monster_component.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';
import 'run_rewards.dart';
import 'systems/auto_skill_system.dart';

class MidgardRunGame extends FlameGame with KeyboardEvents {
  MidgardRunGame({
    required this.hero,
    required this.onDeath,
    Set<String> ownedRunUpgradeIds = const {},
  }) : ownedRunUpgradeIds = {...ownedRunUpgradeIds};

  static const String hudOverlayKey = 'hud';
  static const double _groundY = 330;
  static const double _tileWidth = 360;
  static const double _attackInterval = 0.75;
  static const double _collisionInterval = 0.65;

  final HeroProgress hero;
  final void Function(RunRewards rewards) onDeath;
  final Set<String> ownedRunUpgradeIds;
  final RunRewardsAccumulator rewards = RunRewardsAccumulator();
  final ValueNotifier<int> hudRevision = ValueNotifier<int>(0);

  late final PlayerComponent player;
  late final AutoSkillSystem autoSkillSystem;
  late final String autoSkillName;

  final List<RectangleComponent> _groundTiles = [];
  final List<MonsterComponent> _monsters = [];

  bool _leftPressed = false;
  bool _rightPressed = false;
  bool _finished = false;
  double _attackTimer = 0;
  double _collisionTimer = 0;
  double _hudTimer = 0;
  double _nextSpawnX = 520;

  double get distance => player.position.x;

  double get hpFraction => player.currentHp / player.maxHp;

  double get spFraction => player.currentSp / player.maxSp;

  double get ultimateCooldownRemaining =>
      autoSkillSystem.ultimateCooldownRemaining;

  RunRewards get currentRewards => rewards.toRewards();

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
    _handleAutoSkills(dt);
    _handleAutoAttack();
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

  void _spawnMonster() {
    final wave = (_nextSpawnX / 500).floor();
    final maxHp = 18 + (wave * 3);
    final monster = MonsterComponent(
      target: player,
      position: Vector2(_nextSpawnX, _groundY - 44),
      maxHp: maxHp,
      touchDamage: 7 + wave,
      baseXp: 5 + wave,
      jobXp: 3 + (wave ~/ 2),
      gold: 2 + (wave ~/ 3),
      moveSpeed: 50 + (wave * 2),
    );
    _nextSpawnX += 430;
    _monsters.add(monster);
    world.add(monster);
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

  void _collectKill(MonsterComponent monster) {
    rewards.addKill(
      baseXp: monster.baseXp,
      jobXp: monster.jobXp,
      gold: monster.gold,
    );
    monster.removeFromParent();
    _monsters.remove(monster);
    _publishHud();
  }

  void _publishHudIfNeeded() {
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      _publishHud();
    }
  }

  void _publishHud() {
    hudRevision.value += 1;
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
