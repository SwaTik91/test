import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:midgard_outpost/core/ids.dart';

/// Static art paths relative to [assetRoot] (`assets/images/`).
class ArtAtlas {
  ArtAtlas._();

  static const assetRoot = 'assets/images/';

  // Heroes
  static const heroArcher = 'heroes/archer.png';
  static const heroMage = 'heroes/mage.png';
  static const heroPaladin = 'heroes/paladin.png';

  // Enemies — mobs
  static const mobSlime = 'enemies/slime.png';
  static const mobLunatic = 'enemies/lunatic.png';
  static const mobWolf = 'enemies/wolf.png';
  static const mobMushroom = 'enemies/mushroom.png';
  static const mobBee = 'enemies/bee.png';
  static const mobCrab = 'enemies/crab.png';
  static const mobGhost = 'enemies/ghost.png';
  static const mobPlant = 'enemies/plant.png';

  // Enemies — bosses
  static const bossDemon = 'enemies/boss_demon.png';
  static const bossSpider = 'enemies/boss_spider.png';
  static const bossUndead = 'enemies/boss_undead.png';
  static const bossGolem = 'enemies/boss_golem.png';

  // Props
  static const chest = 'props/chest.png';

  // Projectiles
  static const arrow = 'projectiles/arrow.png';
  static const fireball = 'projectiles/fireball.png';
  static const holyBolt = 'projectiles/holy_bolt.png';
  static const doubleStrafeArrow = 'projectiles/double_strafe_arrow.png';
  static const windArrow = 'projectiles/wind_arrow.png';
  static const arrowShowerArrow = 'projectiles/arrow_shower_arrow.png';

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

  // Skill icons
  static const skillDoubleStrafe = 'ui/skills/double_strafe.png';
  static const skillWindArrow = 'ui/skills/wind_arrow.png';
  static const skillConcentrate = 'ui/skills/concentrate.png';
  static const skillEagleEye = 'ui/skills/eagle_eye.png';
  static const skillArrowShower = 'ui/skills/arrow_shower.png';

  // Concentrate aura frames
  static const concentrateAura0 = 'vfx/concentrate_0.png';
  static const concentrateAura1 = 'vfx/concentrate_1.png';
  static const concentrateAura2 = 'vfx/concentrate_2.png';
  static const concentrateAura3 = 'vfx/concentrate_3.png';

  static const concentrateAuraFrames = [
    concentrateAura0,
    concentrateAura1,
    concentrateAura2,
    concentrateAura3,
  ];

  /// Every game asset path from art spec §4 (excludes `_style/` reference art).
  static const allPaths = [
    heroArcher,
    heroMage,
    heroPaladin,
    mobSlime,
    mobLunatic,
    mobWolf,
    mobMushroom,
    mobBee,
    mobCrab,
    mobGhost,
    mobPlant,
    bossDemon,
    bossSpider,
    bossUndead,
    bossGolem,
    chest,
    arrow,
    fireball,
    holyBolt,
    doubleStrafeArrow,
    windArrow,
    arrowShowerArrow,
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
    skillDoubleStrafe,
    skillWindArrow,
    skillConcentrate,
    skillEagleEye,
    skillArrowShower,
    concentrateAura0,
    concentrateAura1,
    concentrateAura2,
    concentrateAura3,
  ];

  static String? skillIconPath(String skillId) => switch (skillId) {
        'double_strafe' => skillDoubleStrafe,
        'wind_arrow' => skillWindArrow,
        'concentrate' => skillConcentrate,
        'eagle_eye' => skillEagleEye,
        'arrow_shower' => skillArrowShower,
        _ => null,
      };

  static String heroPath(HeroClassId id) => switch (id) {
        HeroClassId.archer => heroArcher,
        HeroClassId.mage => heroMage,
        HeroClassId.paladin => heroPaladin,
      };

  /// Clean single-hero preview for hub/create screens.
  /// Root `heroes/<class>.png` are single idle cutouts; prefer per-frame
  /// animations when a larger in-game preview is needed.
  static String heroPreviewPath(HeroClassId id) => switch (id) {
        HeroClassId.archer => 'heroes/archer/idle_0.png',
        HeroClassId.mage => 'heroes/mage/idle_0.png',
        HeroClassId.paladin => 'heroes/paladin/idle_0.png',
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

  /// Default mob sprite (slime).
  static String get enemyMobPath => mobSlime;

  /// Default boss sprite (demon).
  static String get enemyBossPath => bossDemon;

  /// Boss sprite by wave index (0–3 cycle).
  static String bossPath(int index) => switch (index % 4) {
        0 => bossDemon,
        1 => bossSpider,
        2 => bossUndead,
        _ => bossGolem,
      };

  /// @deprecated Use [mobSlime]. Task 3 removes goblin references.
  static String get mobGoblin => mobSlime;

  /// @deprecated Use [bossDemon]. Task 3 removes ogre references.
  static String get bossOgre => bossDemon;

  /// Alias for [chest].
  static String get chestPath => chest;

  /// Full Flutter asset path (`assets/images/...`) for [AssetImage] / [rootBundle].
  static String flutterAsset(String relativePath) => '$assetRoot$relativePath';

  /// Flame [Sprite.load] path. Flame's Images cache already prefixes `assets/images/`.
  static String flameAsset(String relativePath) => relativePath;

  static Future<Sprite> loadSprite(String path) {
    return Sprite.load(flameAsset(path));
  }

  /// RO pixel art — nearest-neighbor scaling in Flame world space.
  static void applyNearestNeighbor(HasPaint component) {
    component.paint.filterQuality = FilterQuality.none;
  }
}
