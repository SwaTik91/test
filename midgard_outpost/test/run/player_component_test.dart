import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
