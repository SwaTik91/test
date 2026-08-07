# Midgard Outpost Art Wave 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace colored rectangle placeholders with static pixel-art sprites for heroes, enemies, props, world, hub icons, and run UI so Wave 1 looks like a RO-light fantasy game.

**Architecture:** PNG assets live under `midgard_outpost/assets/images/`. An `ArtAtlas` maps logical IDs → asset paths and loads Flame `Sprite`s with nearest-neighbor filtering. Game components (`PlayerComponent`, `MonsterComponent`, etc.) become `SpriteComponent`s (or wrap sprites) instead of `RectangleComponent`s. Hub uses Flutter `Image.asset` for town background and class icons.

**Tech Stack:** Flutter/Flame, PNG sprites (~64×64 heroes, ~96×96 boss), GenerateImage / image tooling for pixel-art generation, `flutter_test` for atlas path tests.

## Global Constraints

- Style: light RO-like fantasy pixel art (not horror)
- Character size ~48–64×64; boss ~96×96
- Static only in Wave 1 (no SpriteAnimation yet)
- Paths exactly as art spec §4 under `midgard_outpost/assets/images/`
- Palette accents from art spec §5
- Russian UI copy unchanged
- Nearest-neighbor scaling (no blur)
- Do not remove gameplay systems; art swap only
- Wave 2 animations are out of scope

## File Structure

```
midgard_outpost/
  assets/images/
    heroes/{archer,mage,paladin}.png
    enemies/{mob_goblin,boss_ogre}.png
    props/chest.png
    projectiles/{arrow,fireball,holy_bolt}.png
    world/{ground_tile,bg_fields,bg_forest}.png
    hub/{town_bg,icon_archer,icon_mage,icon_paladin}.png
    ui/{hp_bar_frame,btn_jump,btn_ult}.png
    _style/style_bible.png          # reference only, not loaded in game
  lib/art/
    art_atlas.dart                  # path map + load helpers
  lib/run/components/…              # sprite wiring
  lib/hub/…                         # Image.asset wiring
  pubspec.yaml                      # assets: declaration
  test/art/art_atlas_test.dart
```

---

### Task 1: ArtAtlas + pubspec asset registration

**Files:**
- Create: `midgard_outpost/lib/art/art_atlas.dart`
- Create: `midgard_outpost/test/art/art_atlas_test.dart`
- Modify: `midgard_outpost/pubspec.yaml` — add `assets/images/` tree
- Create: placeholder 1×1 PNGs OR skip until Task 2 (prefer create empty dirs + register folder)

**Interfaces:**
- Consumes: none
- Produces:
  - `class ArtAtlas` with `static const` path strings matching spec §4
  - `static String heroPath(HeroClassId id)`
  - `static String enemyMobPath`, `enemyBossPath`, `chestPath`, projectile helpers
  - `static Future<Sprite> loadSprite(String path)` for Flame (used later)

- [ ] **Step 1: Write failing atlas test**

```dart
// test/art/art_atlas_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:midgard_outpost/art/art_atlas.dart';
import 'package:midgard_outpost/core/ids.dart';

void main() {
  test('hero paths match art spec filenames', () {
    expect(ArtAtlas.heroPath(HeroClassId.archer), 'heroes/archer.png');
    expect(ArtAtlas.heroPath(HeroClassId.mage), 'heroes/mage.png');
    expect(ArtAtlas.heroPath(HeroClassId.paladin), 'heroes/paladin.png');
  });

  test('world and enemy paths are registered', () {
    expect(ArtAtlas.groundTile, 'world/ground_tile.png');
    expect(ArtAtlas.bgFields, 'world/bg_fields.png');
    expect(ArtAtlas.bgForest, 'world/bg_forest.png');
    expect(ArtAtlas.mobGoblin, 'enemies/mob_goblin.png');
    expect(ArtAtlas.bossOgre, 'enemies/boss_ogre.png');
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
export PATH="/opt/flutter/bin:$PATH"
cd /workspace/midgard_outpost && flutter test test/art/art_atlas_test.dart
```

- [ ] **Step 3: Implement ArtAtlas + pubspec**

```yaml
flutter:
  assets:
    - assets/images/heroes/
    - assets/images/enemies/
    - assets/images/props/
    - assets/images/projectiles/
    - assets/images/world/
    - assets/images/hub/
    - assets/images/ui/
```

Implement path constants. `loadSprite` can wrap `Sprite.load(path)` once images exist (Task 2+).

- [ ] **Step 4: Run test — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add midgard_outpost/lib/art midgard_outpost/test/art midgard_outpost/pubspec.yaml
git commit -m "feat: add ArtAtlas paths and asset folder registration"
```

---

### Task 2: Style bible + hero static sprites

**Files:**
- Create: `midgard_outpost/assets/images/_style/style_bible.png`
- Create: `midgard_outpost/assets/images/heroes/archer.png`
- Create: `midgard_outpost/assets/images/heroes/mage.png`
- Create: `midgard_outpost/assets/images/heroes/paladin.png`

**Interfaces:**
- Consumes: art spec palette + sizes
- Produces: approved-looking side-view idle PNGs with transparency

- [ ] **Step 1: Generate style bible**

Use image generation with prompt constraints: 16-bit pixel art, light RO fantasy, side view archer + goblin on grass tile, limited palette, transparent or flat backdrop for cutout, no blur, no photorealism.

Save to `_style/style_bible.png` and copy preview to `/opt/cursor/artifacts/` for review.

- [ ] **Step 2: Generate three hero sprites**

Separate generations: side-view idle, transparent background, ~64×64 after crop/resize (ImageMagick `convert -filter point -resize 64x64`).

- [ ] **Step 3: Visual sanity check**

Open/read images; reject if not pixel-readable or wrong facing. Regenerate once if needed.

- [ ] **Step 4: Commit assets**

```bash
git add midgard_outpost/assets/images
git commit -m "feat: add style bible and static hero pixel sprites"
```

---

### Task 3: Enemies, chest, projectiles

**Files:**
- Create: `enemies/mob_goblin.png`, `enemies/boss_ogre.png`
- Create: `props/chest.png`
- Create: `projectiles/arrow.png`, `fireball.png`, `holy_bolt.png`

- [ ] **Step 1: Generate each asset** (pixel art, transparent BG, correct size)
- [ ] **Step 2: Point-filter resize** to target sizes
- [ ] **Step 3: Commit**

```bash
git commit -m "feat: add enemy, chest, and projectile pixel sprites"
```

---

### Task 4: World tiles + hub + UI chrome

**Files:**
- Create: `world/ground_tile.png`, `bg_fields.png`, `bg_forest.png`
- Create: `hub/town_bg.png`, `icon_*.png`
- Create: `ui/hp_bar_frame.png`, `btn_jump.png`, `btn_ult.png`

- [ ] **Step 1: Generate tileable ground + two biome backgrounds** (fields brighter, forest darker greens)
- [ ] **Step 2: Generate town background + class icons** (icons can be cropped busts of heroes)
- [ ] **Step 3: Generate simple pixel button faces for jump/ult**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat: add world, hub, and run UI pixel assets"
```

---

### Task 5: Wire Flame run components to sprites

**Files:**
- Modify: `lib/run/components/player_component.dart`
- Modify: `lib/run/components/monster_component.dart`
- Modify: `lib/run/components/chest_component.dart`
- Modify: `lib/run/components/projectile_component.dart`
- Modify: `lib/run/midgard_run_game.dart` (ground tiles + biome background)
- Modify: `lib/run/components/hud_overlay.dart` (optional frame/buttons)
- Test: keep existing suite green; add `test/art/assets_exist_test.dart` that checks `File`/`rootBundle` load for each ArtAtlas path

**Interfaces:**
- Consumes: `ArtAtlas`, Flame `Sprite.load`
- Produces: run scene without colored rect placeholders for hero/mob/boss/chest/ground

- [ ] **Step 1: Write assets_exist_test** loading each path via `rootBundle`

```dart
test('all atlas images load from assets', () async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final path in ArtAtlas.allPaths) {
    final data = await rootBundle.load('assets/images/$path');
    expect(data.lengthInBytes, greaterThan(0), reason: path);
  }
});
```

- [ ] **Step 2: Run — FAIL until assets+pubspec ready (should PASS after Tasks 2–4)**

- [ ] **Step 3: Convert components**

Pattern:

```dart
class PlayerComponent extends SpriteComponent {
  static Future<PlayerComponent> create(HeroClassId classId) async {
    final sprite = await Sprite.load(ArtAtlas.heroPath(classId));
    return PlayerComponent._(sprite);
  }
  // keep size ~64x64, anchor bottom-center
}
```

Update `MidgardRunGame.onLoad` to `await` component factories. Ground: sprite-tiled instead of green rects. Biome BG: one `SpriteComponent` swapped on biome change.

Keep collision boxes via `size` / position logic unchanged.

- [ ] **Step 4: `flutter test` all green**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat: wire Flame run components to pixel sprites"
```

---

### Task 6: Wire hub Flutter images

**Files:**
- Modify: `lib/hub/hub_screen.dart` and/or `create_hero_screen.dart`
- Optionally wrap with `DecorationImage` for `ArtAtlas.townBg`

- [ ] **Step 1: Show town_bg behind hub / create hero**
- [ ] **Step 2: Replace class ChoiceChips labels with Row(icon + name) using hub icons**
- [ ] **Step 3: Widget test still finds «Лучник» / «В поля»**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat: wire hub town background and class icons"
```

---

### Task 7: Manual/visual verification checklist

**Files:** none (or short note in `midgard_outpost/README.md` Art section)

- [ ] **Step 1: Run app** `flutter run -d linux` (or android) — create each class, enter fields, confirm sprites
- [ ] **Step 2: Capture 2 screenshots** to `/opt/cursor/artifacts/` (hub + run)
- [ ] **Step 3: Append Art Wave 1 section to game README** (how to regenerate assets)
- [ ] **Step 4: Commit docs/screenshots references if any**

```bash
git commit -m "docs: document art wave 1 assets and verification"
```

---

## Plan Self-Review

| Spec item | Task |
|-----------|------|
| Heroes ×3 static | 2, 5 |
| Mob + boss | 3, 5 |
| Chest + projectiles | 3, 5 |
| Ground + biomes | 4, 5 |
| Hub bg + icons | 4, 6 |
| UI jump/ult/hp frame | 4, 5 |
| ArtAtlas paths | 1 |
| No animations Wave 1 | all |
| Nearest-neighbor | 5 (Paint filter / sprite paint) |

Intentional deferral: Wave 2 animations, full pixel Material replacement.
