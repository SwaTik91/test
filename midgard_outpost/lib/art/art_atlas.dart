import 'package:flame/components.dart';
import 'package:midgard_outpost/core/ids.dart';

/// Static art paths relative to [assetRoot] (`assets/images/`).
class ArtAtlas {
  ArtAtlas._();

  static const assetRoot = 'assets/images/';

  // Heroes
  static const heroArcher = 'heroes/archer.png';
  static const heroMage = 'heroes/mage.png';
  static const heroPaladin = 'heroes/paladin.png';

  // Enemies
  static const mobGoblin = 'enemies/mob_goblin.png';
  static const bossOgre = 'enemies/boss_ogre.png';

  // Props
  static const chest = 'props/chest.png';

  // Projectiles
  static const arrow = 'projectiles/arrow.png';
  static const fireball = 'projectiles/fireball.png';
  static const holyBolt = 'projectiles/holy_bolt.png';

  // World
  static const groundTile = 'world/ground_tile.png';
  static const bgFields = 'world/bg_fields.png';
  static const bgForest = 'world/bg_forest.png';

  // Hub
  static const townBg = 'hub/town_bg.png';
  static const iconArcher = 'hub/icon_archer.png';
  static const iconMage = 'hub/icon_mage.png';
  static const iconPaladin = 'hub/icon_paladin.png';

  // UI
  static const hpBarFrame = 'ui/hp_bar_frame.png';
  static const btnJump = 'ui/btn_jump.png';
  static const btnUlt = 'ui/btn_ult.png';

  /// Every game asset path from art spec §4 (excludes `_style/` reference art).
  static const allPaths = [
    heroArcher,
    heroMage,
    heroPaladin,
    mobGoblin,
    bossOgre,
    chest,
    arrow,
    fireball,
    holyBolt,
    groundTile,
    bgFields,
    bgForest,
    townBg,
    iconArcher,
    iconMage,
    iconPaladin,
    hpBarFrame,
    btnJump,
    btnUlt,
  ];

  static String heroPath(HeroClassId id) => switch (id) {
        HeroClassId.archer => heroArcher,
        HeroClassId.mage => heroMage,
        HeroClassId.paladin => heroPaladin,
      };

  static String heroIconPath(HeroClassId id) => switch (id) {
        HeroClassId.archer => iconArcher,
        HeroClassId.mage => iconMage,
        HeroClassId.paladin => iconPaladin,
      };

  static String projectilePath(HeroClassId id) => switch (id) {
        HeroClassId.archer => arrow,
        HeroClassId.mage => fireball,
        HeroClassId.paladin => holyBolt,
      };

  /// Alias for [mobGoblin].
  static String get enemyMobPath => mobGoblin;

  /// Alias for [bossOgre].
  static String get enemyBossPath => bossOgre;

  /// Alias for [chest].
  static String get chestPath => chest;

  /// Full Flutter asset path (`assets/images/...`) for [AssetImage] / [rootBundle].
  static String flutterAsset(String relativePath) => '$assetRoot$relativePath';

  /// Flame [Sprite.load] path. Flame's Images cache already prefixes `assets/images/`.
  static String flameAsset(String relativePath) => relativePath;

  static Future<Sprite> loadSprite(String path) {
    return Sprite.load(flameAsset(path));
  }
}
