import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/art_atlas.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  test('hero paths match art spec filenames', () {
    expect(ArtAtlas.heroPath(HeroClassId.archer), 'heroes/archer.png');
    expect(ArtAtlas.heroPath(HeroClassId.mage), 'heroes/mage.png');
    expect(ArtAtlas.heroPath(HeroClassId.paladin), 'heroes/paladin.png');
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

  test('world and enemy paths are registered', () {
    expect(ArtAtlas.groundTile, 'world/ground_tile.png');
    expect(ArtAtlas.bgFields, 'world/bg_fields.png');
    expect(ArtAtlas.bgForest, 'world/bg_forest.png');
    expect(ArtAtlas.mobGoblin, 'enemies/mob_goblin.png');
    expect(ArtAtlas.bossOgre, 'enemies/boss_ogre.png');
  });

  test('props, projectiles, hub, and ui paths are registered', () {
    expect(ArtAtlas.chest, 'props/chest.png');
    expect(ArtAtlas.arrow, 'projectiles/arrow.png');
    expect(ArtAtlas.fireball, 'projectiles/fireball.png');
    expect(ArtAtlas.holyBolt, 'projectiles/holy_bolt.png');
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
  });

  test('allPaths lists every game asset and excludes _style', () {
    const expected = {
      'heroes/archer.png',
      'heroes/mage.png',
      'heroes/paladin.png',
      'enemies/mob_goblin.png',
      'enemies/boss_ogre.png',
      'props/chest.png',
      'projectiles/arrow.png',
      'projectiles/fireball.png',
      'projectiles/holy_bolt.png',
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
    };

    expect(ArtAtlas.allPaths.toSet(), expected);
    for (final path in ArtAtlas.allPaths) {
      expect(path.contains('_style'), isFalse);
    }
  });
}
