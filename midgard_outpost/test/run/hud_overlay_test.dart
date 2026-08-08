import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/run/components/hud_overlay.dart';

void main() {
  test('HUD panel constraints cap at 28% width and 30% height', () {
    const screen = Size(1280, 720);
    final constraints = HudOverlay.panelConstraintsFor(screen);

    expect(constraints.maxWidth, closeTo(1280 * 0.28, 0.01));
    expect(constraints.maxHeight, closeTo(720 * 0.30, 0.01));
  });
}
