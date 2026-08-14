import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/run/components/hud_overlay.dart';

void main() {
  test('HUD panel constraints cap at 28% width and 30% height', () {
    const screen = Size(1280, 720);
    final constraints = HudOverlay.panelConstraintsFor(screen);

    expect(constraints.maxWidth, closeTo(1280 * 0.28, 0.01));
    expect(constraints.maxHeight, closeTo(720 * 0.30, 0.01));
  });

    test('action cluster places skills in an arc above the jump button', () {
      final offsets = HudOverlay.skillOffsets(4);
      expect(offsets, hasLength(4));
      expect(offsets[0], const Offset(68, 132));
      expect(offsets[1], const Offset(128, 60));
      expect(offsets[2], const Offset(60, 68));
      expect(offsets[3], const Offset(8, 108));
    });

    test('archer skill buttons use short HUD labels', () {
    expect(
      HudOverlay.shortSkillLabel(SkillsCatalog.byId('double_strafe')),
      'ДС',
    );
    expect(
      HudOverlay.shortSkillLabel(SkillsCatalog.byId('wind_arrow')),
      'ВС',
    );
    expect(
      HudOverlay.shortSkillLabel(SkillsCatalog.byId('concentrate')),
      'Конц',
    );
    expect(
      HudOverlay.shortSkillLabel(SkillsCatalog.byId('arrow_shower')),
      'Град',
    );
  });
}
