import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/sprite_fit.dart';

void main() {
  group('SpriteFit', () {
    test('containHeight preserves aspect ratio', () {
      final size = SpriteFit.containHeight(
        srcSize: Vector2(75, 96),
        targetHeight: 216,
      );
      expect(size.y, 216);
      expect(size.x, closeTo(216 * (75 / 96), 0.01));
    });

    test('containSquare fits inside target extent', () {
      final size = SpriteFit.containSquare(
        srcSize: Vector2(64, 28),
        targetExtent: 24,
      );
      expect(size.x, lessThanOrEqualTo(24));
      expect(size.y, lessThanOrEqualTo(24));
      expect(size.x / size.y, closeTo(64 / 28, 0.01));
    });

    test('stableContainHeight uses widest frame width', () async {
      final narrow = Sprite(
        await _testImage(60, 96),
        srcSize: Vector2(60, 96),
      );
      final wide = Sprite(
        await _testImage(100, 96),
        srcSize: Vector2(100, 96),
      );
      final animation = SpriteAnimation.spriteList(
        [narrow, wide, narrow],
        stepTime: 0.1,
      );
      final size = SpriteFit.stableContainHeight(
        animation: animation,
        targetHeight: 216,
      );
      expect(size.y, 216);
      expect(size.x, closeTo(216 * (100 / 96), 0.01));
    });
  });
}

Future<ui.Image> _testImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}
