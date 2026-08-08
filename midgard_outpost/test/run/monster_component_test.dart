import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/monsters.dart';
import 'package:midgard_outpost/run/components/monster_component.dart';
import 'package:midgard_outpost/run/components/player_component.dart';
import 'package:midgard_outpost/run/run_layout.dart';

Future<Sprite> _testSprite({int width = 96, int height = 95}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  return Sprite(image);
}

void main() {
  test('monster flips toward target while chasing', () async {
    final layout = RunLayout(RunLayout.referenceHeight);
    final player = PlayerComponent.forTest(
      groundY: layout.groundY,
      sprite: await _testSprite(),
      position: Vector2(300, layout.groundY),
      size: layout.playerSize,
    );
    final monster = MonsterComponent.forTest(
      kind: MonsterKind.slime,
      target: player,
      position: Vector2(100, layout.groundY),
      sprite: await _testSprite(),
      maxHp: 20,
      touchDamage: 5,
      baseXp: 1,
      jobXp: 1,
      gold: 1,
      tempXp: 1,
      upgradeDropChance: 0,
      moveSpeed: 120,
    );

    monster.update(1 / 60);
    expect(monster.scale.x, greaterThan(0));

    player.position.x = 50;
    monster.update(1 / 60);
    expect(monster.scale.x, lessThan(0));
  });

  test('ranged monster telegraphs then fires callback', () async {
    final layout = RunLayout(RunLayout.referenceHeight);
    final player = PlayerComponent.forTest(
      groundY: layout.groundY,
      sprite: await _testSprite(),
      position: Vector2(360, layout.groundY),
      size: layout.playerSize,
    );
  var fired = 0;
    final monster = MonsterComponent.forTest(
      kind: MonsterKind.bee,
      target: player,
      position: Vector2(100, layout.groundY),
      sprite: await _testSprite(),
      maxHp: 20,
      touchDamage: 5,
      baseXp: 1,
      jobXp: 1,
      gold: 1,
      tempXp: 1,
      upgradeDropChance: 0,
      attackRange: 260,
      attackInterval: 1.2,
      onRangedAttack: (_) => fired++,
    );

    monster.update(0.5);
    expect(monster.isTelegraphing, isTrue);

    monster.update(0.35);
    expect(monster.isTelegraphing, isFalse);
    expect(fired, 1);
  });
}
