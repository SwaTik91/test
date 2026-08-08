import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/components/projectile_component.dart';

Future<Sprite> _wideSprite() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 64, 28),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 28);
  return Sprite(image);
}

void main() {
  test('projectile visual height preserves sprite aspect ratio', () async {
    final sprite = await _wideSprite();
    final projectile = ProjectileComponent(
      sprite: sprite,
      start: Vector2.zero(),
      end: Vector2(100, 0),
      duration: 0.2,
      visualHeight: ProjectileComponent.basicVisualHeight,
    );

    expect(projectile.size.y, ProjectileComponent.basicVisualHeight);
    expect(
      projectile.size.x / projectile.size.y,
      closeTo(64 / 28, 0.01),
    );
    expect(projectile.size.x, greaterThan(ProjectileComponent.basicVisualHeight));
  });
}
