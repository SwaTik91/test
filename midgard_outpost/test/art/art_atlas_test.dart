import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/art_atlas.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  test('hero paths match art spec filenames', () {
    expect(ArtAtlas.heroPath(HeroClassId.archer), 'heroes/archer.png');
    expect(ArtAtlas.heroPath(HeroClassId.mage), 'heroes/mage.png');
    expect(ArtAtlas.heroPath(HeroClassId.paladin), 'heroes/paladin.png');
    expect(
      ArtAtlas.heroPreviewPath(HeroClassId.archer),
      'heroes/archer/idle_0.png',
    );
    expect(
      ArtAtlas.heroPreviewPath(HeroClassId.mage),
      'heroes/mage/idle_0.png',
    );
    expect(
      ArtAtlas.heroPreviewPath(HeroClassId.paladin),
      'heroes/paladin/idle_0.png',
    );
  });

  test('Flame sprite paths omit assets/images prefix (Flame adds it)', () {
    expect(ArtAtlas.flameAsset(ArtAtlas.groundTile), 'world/ground_tile.png');
    expect(
      ArtAtlas.flutterAsset(ArtAtlas.groundTile),
      'assets/images/world/ground_tile.png',
    );
    expect(
      ArtAtlas.flameAsset(ArtAtlas.groundTile),
      isNot(contains('assets/images/assets/images/')),
    );
  });

  test('world paths are registered', () {
    expect(ArtAtlas.groundTile, 'world/ground_tile.png');
    expect(ArtAtlas.bgFields, 'world/bg_fields.png');
    expect(ArtAtlas.bgForest, 'world/bg_forest.png');
  });

  test('canon enemy paths are registered', () {
    expect(ArtAtlas.mobSlime, 'enemies/slime.png');
    expect(ArtAtlas.mobLunatic, 'enemies/lunatic.png');
    expect(ArtAtlas.mobWolf, 'enemies/wolf.png');
    expect(ArtAtlas.mobMushroom, 'enemies/mushroom.png');
    expect(ArtAtlas.mobBee, 'enemies/bee.png');
    expect(ArtAtlas.mobCrab, 'enemies/crab.png');
    expect(ArtAtlas.mobGhost, 'enemies/ghost.png');
    expect(ArtAtlas.mobPlant, 'enemies/plant.png');
    expect(ArtAtlas.bossDemon, 'enemies/boss_demon.png');
    expect(ArtAtlas.bossSpider, 'enemies/boss_spider.png');
    expect(ArtAtlas.bossUndead, 'enemies/boss_undead.png');
    expect(ArtAtlas.bossGolem, 'enemies/boss_golem.png');
    expect(ArtAtlas.allPaths, contains(ArtAtlas.mobWolf));
    expect(ArtAtlas.allPaths, isNot(contains('enemies/mob_goblin.png')));
  });

  test('deprecated enemy aliases point at canon defaults', () {
    expect(ArtAtlas.enemyMobPath, ArtAtlas.mobSlime);
    expect(ArtAtlas.enemyBossPath, ArtAtlas.bossDemon);
    expect(ArtAtlas.mobGoblin, ArtAtlas.mobSlime);
    expect(ArtAtlas.bossOgre, ArtAtlas.bossDemon);
  });

  test('props, projectiles, hub, and ui paths are registered', () {
    expect(ArtAtlas.chest, 'props/chest.png');
    expect(ArtAtlas.arrow, 'projectiles/arrow.png');
    expect(ArtAtlas.fireball, 'projectiles/fireball.png');
    expect(ArtAtlas.holyBolt, 'projectiles/holy_bolt.png');
    expect(ArtAtlas.doubleStrafeArrow, 'projectiles/double_strafe_arrow.png');
    expect(ArtAtlas.windArrow, 'projectiles/wind_arrow.png');
    expect(ArtAtlas.arrowShowerArrow, 'projectiles/arrow_shower_arrow.png');
    expect(ArtAtlas.projectilePath(HeroClassId.archer), ArtAtlas.arrow);
    expect(ArtAtlas.projectilePath(HeroClassId.mage), ArtAtlas.fireball);
    expect(ArtAtlas.projectilePath(HeroClassId.paladin), ArtAtlas.holyBolt);
    expect(ArtAtlas.townBg, 'hub/town_bg.png');
    expect(ArtAtlas.iconArcher, 'hub/icon_archer.png');
    expect(ArtAtlas.iconMage, 'hub/icon_mage.png');
    expect(ArtAtlas.iconPaladin, 'hub/icon_paladin.png');
    expect(ArtAtlas.heroIconPath(HeroClassId.archer), ArtAtlas.iconArcher);
    expect(ArtAtlas.hpBarFrame, 'ui/hp_bar_frame.png');
    expect(ArtAtlas.btnJump, 'ui/btn_jump.png');
    expect(ArtAtlas.btnUlt, 'ui/btn_ult.png');
    expect(ArtAtlas.skillIconPath('concentrate'), ArtAtlas.skillConcentrate);
  });

  test('skill icon paths map archer skills', () {
    expect(ArtAtlas.skillIconPath('double_strafe'), ArtAtlas.skillDoubleStrafe);
    expect(ArtAtlas.skillIconPath('wind_arrow'), ArtAtlas.skillWindArrow);
    expect(ArtAtlas.skillIconPath('eagle_eye'), ArtAtlas.skillEagleEye);
    expect(ArtAtlas.skillIconPath('arrow_shower'), ArtAtlas.skillArrowShower);
    expect(ArtAtlas.skillIconPath('fire_bolt'), isNull);
  });

  test('allPaths lists every game asset and excludes _style', () {
    const expected = {
      'heroes/archer.png',
      'heroes/mage.png',
      'heroes/paladin.png',
      'enemies/slime.png',
      'enemies/lunatic.png',
      'enemies/wolf.png',
      'enemies/mushroom.png',
      'enemies/bee.png',
      'enemies/crab.png',
      'enemies/ghost.png',
      'enemies/plant.png',
      'enemies/boss_demon.png',
      'enemies/boss_spider.png',
      'enemies/boss_undead.png',
      'enemies/boss_golem.png',
      'props/chest.png',
      'projectiles/arrow.png',
      'projectiles/fireball.png',
      'projectiles/holy_bolt.png',
      'projectiles/double_strafe_arrow.png',
      'projectiles/wind_arrow.png',
      'projectiles/arrow_shower_arrow.png',
      'world/ground_tile.png',
      'world/bg_fields.png',
      'world/bg_forest.png',
      'hub/town_bg.png',
      'hub/icon_archer.png',
      'hub/icon_mage.png',
      'hub/icon_paladin.png',
      'ui/hp_bar_frame.png',
      'ui/btn_jump.png',
      'ui/btn_ult.png',
      'ui/skills/double_strafe.png',
      'ui/skills/wind_arrow.png',
      'ui/skills/concentrate.png',
      'ui/skills/eagle_eye.png',
      'ui/skills/arrow_shower.png',
      'vfx/concentrate_0.png',
      'vfx/concentrate_1.png',
      'vfx/concentrate_2.png',
      'vfx/concentrate_3.png',
    };

    expect(ArtAtlas.allPaths.toSet(), expected);
    for (final path in ArtAtlas.allPaths) {
      expect(path.contains('_style'), isFalse);
    }
  });
}
