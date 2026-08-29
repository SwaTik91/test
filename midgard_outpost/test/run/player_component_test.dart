import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/hero_anim_state.dart';
import 'package:midgard_outpost/run/components/player_component.dart';
import 'package:midgard_outpost/run/run_layout.dart';

Future<Sprite> _testSprite() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(1, 1);
  return Sprite(image);
}

Future<Sprite> _testSpriteSized(int width, int height) async {
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
  test('player flips horizontally when moving left and back', () async {
    final player = PlayerComponent.forTest(
      groundY: 500,
      sprite: await _testSprite(),
    );

    player.setHorizontal(0);
    player.update(0.016);
    expect(player.isFacingLeft, isFalse);

    player.setHorizontal(-1);
    player.update(0.016);
    expect(player.isFacingLeft, isTrue);
    expect(player.transform.scale.x, isNegative);

    player.setHorizontal(1);
    player.update(0.016);
    expect(player.isFacingLeft, isFalse);
    expect(player.transform.scale.x, isPositive);
  });

  test('setGroundY snaps grounded player when ground line rises', () async {
    final shortLayout = RunLayout(500);
    final tallLayout = RunLayout(800);
    final player = PlayerComponent.forTest(
      groundY: shortLayout.groundY,
      sprite: await _testSprite(),
      position: Vector2(120, shortLayout.groundY),
      size: shortLayout.playerSize,
    );

    expect(player.isGrounded, isTrue);
    player.setGroundY(tallLayout.groundY);
    expect(player.position.y, closeTo(tallLayout.groundY, 0.01));
  });

  test('setGroundY does not snap airborne player when ground line rises', () async {
    final shortLayout = RunLayout(500);
    final tallLayout = RunLayout(800);
    final player = PlayerComponent.forTest(
      groundY: shortLayout.groundY,
      sprite: await _testSprite(),
      position: Vector2(120, shortLayout.groundY - 80),
      size: shortLayout.playerSize,
    );

    expect(player.isGrounded, isFalse);
    player.setGroundY(tallLayout.groundY);
    expect(player.position.y, closeTo(shortLayout.groundY - 80, 0.01));
  });

  test('isGrounded uses bottom-center anchor', () async {
    final layout = RunLayout(RunLayout.referenceHeight);
    final player = PlayerComponent.forTest(
      groundY: layout.groundY,
      sprite: await _testSprite(),
      size: layout.playerSize,
    );

    player.position.y = layout.groundY;
    expect(player.isGrounded, isTrue);

    player.position.y = layout.groundY - 1;
    expect(player.isGrounded, isFalse);

    player.position.y = layout.groundY - 0.4;
    expect(player.isGrounded, isTrue);
  });

  test('player falls when the floor drops into a pit', () async {
    final player = PlayerComponent.forTest(
      groundY: 500,
      sprite: await _testSprite(),
      position: Vector2(40, 500),
      moveSpeed: 190,
    );
    player.floorYAt = (x, y) => x >= 80 && x < 188 ? 650 : 500;
    player.setHorizontal(1);
    var maxY = player.position.y;
    for (var i = 0; i < 90; i++) {
      player.update(1 / 60);
      if (player.position.y > maxY) {
        maxY = player.position.y;
      }
    }
    expect(maxY, greaterThan(520));
  });

  test('running jump clears a 108px pit', () async {
    final player = PlayerComponent.forTest(
      groundY: 500,
      sprite: await _testSprite(),
      position: Vector2(50, 500),
      moveSpeed: 190,
    );
    player.floorYAt = (x, y) => x >= 80 && x < 188 ? 650 : 500;
    player.setHorizontal(1);
    player.update(1 / 60);
    expect(player.jump(), isTrue);
    for (var i = 0; i < 80; i++) {
      player.update(1 / 60);
    }
    expect(player.position.x, greaterThan(188));
    expect(player.position.y, closeTo(500, 1));
    expect(player.isGrounded, isTrue);
  });

  test('sprite render size preserves frame aspect ratio', () async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 75, 96),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(75, 96);
    final sprite = Sprite(image);

    final layout = RunLayout(RunLayout.referenceHeight);
    final player = PlayerComponent.forTest(
      groundY: layout.groundY,
      sprite: sprite,
      size: layout.playerSize,
    );

    expect(player.size.y, layout.playerSize.y);
    expect(
      player.size.x / player.size.y,
      closeTo(75 / 96, 0.01),
    );
    expect(player.footprintSize, layout.playerSize);
  });

  test('render width stays constant across frames of same animation', () async {
    final narrow = await _testSpriteSized(60, 96);
    final wide = await _testSpriteSized(100, 96);
    final runAnim = SpriteAnimation.spriteList(
      [narrow, wide, narrow, wide],
      stepTime: 0.05,
      loop: true,
    );
    final idleAnim = SpriteAnimation.spriteList(
      [await _testSpriteSized(75, 96)],
      stepTime: 1.0,
      loop: true,
    );
    final animations = {
      for (final anim in HeroAnimName.values)
        anim: anim == HeroAnimName.run ? runAnim : idleAnim,
    };

    final layout = RunLayout(RunLayout.referenceHeight);
    final player = PlayerComponent.forTestWithAnimations(
      groundY: layout.groundY,
      animations: animations,
      size: layout.playerSize,
      current: HeroAnimName.run,
      moveSpeed: 200,
    );
    player.setHorizontal(1);

    final stableWidth = player.size.x;
    for (var i = 0; i < 40; i++) {
      player.update(0.05);
      expect(player.size.x, stableWidth);
    }
  });
}
