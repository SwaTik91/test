import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/content/skills.dart';
import 'package:midgard_outpost/core/ids.dart';
import 'package:midgard_outpost/run/components/hud_overlay.dart';

void main() {
  test('HUD panel constraints fit variant B combat plate', () {
    const screen = Size(1280, 720);
    final constraints = HudOverlay.panelConstraintsFor(screen);

    expect(constraints.maxWidth, closeTo(1280 * 0.30, 0.01));
    expect(constraints.maxHeight, double.infinity);
  });

  test('status plate bars column stays within portrait height', () {
    expect(
      HudOverlay.statusBarsColumnMinHeight,
      lessThanOrEqualTo(HudOverlay.statusPortraitSize),
    );
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

  test('status plate uses short class labels and one meta line', () {
    expect(HudOverlay.shortClassLabel(HeroClassId.archer), 'лук');
    expect(HudOverlay.shortClassLabel(HeroClassId.mage), 'маг');
    expect(HudOverlay.shortClassLabel(HeroClassId.paladin), 'пал');
    expect(
      HudOverlay.statusMetaLine(
        baseXp: 120,
        jobXp: 80,
        gold: 64,
        biomeLabel: 'Поля',
      ),
      'XP 120/80  ·  Золото 64  ·  Поля',
    );
  });
}
