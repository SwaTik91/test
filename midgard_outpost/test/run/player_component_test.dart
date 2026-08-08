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
