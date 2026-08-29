# Midgard Outpost Art + Hub Canon — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import approved RO art canon into the Flutter/Flame game and rebuild the hub as flat mobile shell E (skills-tab layout), so playtest matches the locked mockups.

**Architecture:** Canon PNGs live in `docs/superpowers/art-canon/`; a resize script writes game-sized assets under `midgard_outpost/assets/images/`. `ArtAtlas` / `MonstersCatalog` gain mob/boss IDs. Hub becomes `HubShell` with a right rail and tab bodies (home/stats/skills/shop). Run keeps Flame paths (no double `assets/images/` prefix) and uses new world/enemy/projectile art; Wave-2 goblin/ogre animations fall back to static canon sprites when frames are absent.

**Tech Stack:** Flutter, Flame, Python Pillow for resize, `flutter_test`.

## Global Constraints

- Art style: classic RO for sprites/backgrounds; flat mobile UI for hub
- Hub shell E; skills tab is visual canon
- Fields/forest: Mario composition (sky + ground strip) — already in canon files
- Russian UI only
- Flame `Sprite.load` paths relative to `assets/images/` (no double prefix)
- HUD only after `isRunReady`
- Keep `flutter test` green
- Out of scope: full Wave-2 re-animation for every new mob; live IAP SDKs

## File Structure

```
docs/superpowers/art-canon/          # locked sources (already in repo)
midgard_outpost/
  tool/import_art_canon.py           # resize + copy into assets/
  assets/images/
    heroes/{archer,mage,paladin}.png
    hub/{town_bg,icon_*}.png
    enemies/{slime,lunatic,wolf,mushroom,bee,crab,ghost,plant}.png
    enemies/boss_{demon,spider,undead,golem}.png
    props/chest.png
    projectiles/{arrow,fireball,holy_bolt}.png
    world/{bg_fields,bg_forest,ground_tile}.png
    ui/{btn_jump,btn_ult}.png
  lib/art/art_atlas.dart
  lib/content/monsters.dart          # + MonsterKind / boss rotation
  lib/run/components/monster_component.dart
  lib/hub/hub_shell.dart             # NEW shell E
  lib/hub/{hub_home,stats,skills,shop}_tab.dart  # or keep screens restyled
  lib/app.dart                       # HubShell instead of HubScreen
  test/art/art_atlas_test.dart
  test/art/assets_exist_test.dart
  test/hub/hub_shell_test.dart
```

---

### Task 1: Import and resize canon into assets/

**Files:**
- Create: `midgard_outpost/tool/import_art_canon.py`
- Create/overwrite: game PNGs under `midgard_outpost/assets/images/` per mapping below
- Modify: `midgard_outpost/pubspec.yaml` if new enemy folders need listing (directory globs already cover `enemies/`)

**Interfaces:**
- Consumes: `docs/superpowers/art-canon/*.png`
- Produces: resized files at exact paths used by ArtAtlas (Task 2)

**Mapping (source → dest, max edge):**

| Source | Dest | Max edge |
|--------|------|----------|
| hero-*.png | heroes/*.png | 128 |
| hero-* | hub/icon_*.png | 64 (square crop/fit) |
| bg-town.png | hub/town_bg.png | 1920 |
| bg-fields/forest | world/bg_*.png | 1920 |
| ground-tile.png | world/ground_tile.png | 256 |
| mob-*.png | enemies/{name}.png | 96 |
| boss-*.png | enemies/boss_{name}.png | 160 |
| prop-chest.png | props/chest.png | 96 |
| proj-* | projectiles/* | 64 |
| ui-btn-* | ui/btn_*.png | 128 |

- [ ] **Step 1: Write import script**

```python
# midgard_outpost/tool/import_art_canon.py
# PIL resize LANCZOS, RGBA, write to assets/images/...
# argparse --canon ../../docs/superpowers/art-canon --out ../assets/images
```

- [ ] **Step 2: Run import**

```bash
cd midgard_outpost && python3 tool/import_art_canon.py
```

Expected: all dest files exist, non-zero size.

- [ ] **Step 3: Commit**

```bash
git add midgard_outpost/tool/import_art_canon.py midgard_outpost/assets/images
git commit -m "feat: import resized art canon into game assets"
```

---

### Task 2: ArtAtlas paths for new enemies/bosses

**Files:**
- Modify: `midgard_outpost/lib/art/art_atlas.dart`
- Modify: `midgard_outpost/test/art/art_atlas_test.dart`
- Modify: `midgard_outpost/test/art/assets_exist_test.dart` (uses `allPaths`)

**Interfaces:**
- Produces:
  - `ArtAtlas.mobSlime`, `mobLunatic`, … (or `mobPath(MonsterKind)`)
  - `ArtAtlas.bossDemon`, `bossSpider`, `bossUndead`, `bossGolem`
  - `enemyMobPath` → default slime; `bossPath(int index)` or kind-based
  - Updated `allPaths`

- [ ] **Step 1: Failing tests for new paths**

```dart
test('canon enemy paths are registered', () {
  expect(ArtAtlas.mobSlime, 'enemies/slime.png');
  expect(ArtAtlas.bossDemon, 'enemies/boss_demon.png');
  expect(ArtAtlas.allPaths, contains(ArtAtlas.mobWolf));
  expect(ArtAtlas.allPaths, isNot(contains('enemies/mob_goblin.png')));
});
```

- [ ] **Step 2: RED** — `flutter test test/art/art_atlas_test.dart`

- [ ] **Step 3: Implement ArtAtlas** — replace goblin/ogre constants; keep `flameAsset`/`flutterAsset`/`loadSprite` as-is.

- [ ] **Step 4: GREEN** + `assets_exist_test` passes for new files.

- [ ] **Step 5: Commit** `feat: point ArtAtlas at art-canon enemy and boss paths`

---

### Task 3: Monster kinds + boss rotation in catalog/spawn

**Files:**
- Modify: `midgard_outpost/lib/content/monsters.dart` — add `enum MonsterKind`, fields on `MonsterSpec`, selection helpers
- Modify: `midgard_outpost/lib/run/components/monster_component.dart` — load sprite by kind (static ArtAtlas; try anim only if frames exist / skip goblin anim)
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart` — pass kind into create
- Test: `midgard_outpost/test/run/spawn_system_test.dart` or new `test/content/monsters_catalog_test.dart`

**Interfaces:**
- Produces:
  - `MonsterKind { slime, lunatic, wolf, mushroom, bee, crab, ghost, plant, bossDemon, bossSpider, bossUndead, bossGolem }`
  - `MonstersCatalog.kindForDistance(distancePx, biome, isBoss)`
  - Boss order: demon → spider → undead → golem → repeat by boss index
  - Non-boss: rotate among slime/lunatic/wolf/… by wave + biome

- [ ] **Step 1: Catalog test**

```dart
test('boss kinds rotate in canon order', () {
  expect(MonstersCatalog.bossKindAt(0), MonsterKind.bossDemon);
  expect(MonstersCatalog.bossKindAt(1), MonsterKind.bossSpider);
  expect(MonstersCatalog.bossKindAt(3), MonsterKind.bossGolem);
  expect(MonstersCatalog.bossKindAt(4), MonsterKind.bossDemon);
});
```

- [ ] **Step 2: Implement catalog + wire MonsterComponent.create(kind: …)**  
  Prefer static `ArtAtlas` sprite for new kinds; keep anim try/catch for legacy ogre/goblin folders optional — may delete goblin anim dependency from create path.

- [ ] **Step 3: Fix animation_assets tests** if they still require goblin/ogre frames — either keep old frames as unused OR update `AnimationAtlas.allFramePaths` to not require removed packs. Prefer: leave Wave-2 files on disk but stop requiring them for new kinds; if tests fail, narrow `allFramePaths` / mark obsolete.

- [ ] **Step 4: Commit** `feat: spawn canon mobs and rotating bosses`

---

### Task 4: HubShell E (navigation + home)

**Files:**
- Create: `midgard_outpost/lib/hub/hub_shell.dart`
- Create: `midgard_outpost/lib/hub/hub_home_tab.dart`
- Modify: `midgard_outpost/lib/app.dart` — use `HubShell`
- Modify or wrap: stats/skills/shop into tabs
- Test: `midgard_outpost/test/hub/hub_shell_test.dart`

**Interfaces:**
- `enum HubTab { home, stats, skills, shop }`
- `HubShell({required GameController controller})`
- Right rail labels: Главная, Статы, Умения, Магазин, В поля
- Town background + class art on left

- [ ] **Step 1: Widget test** — after create hero, expect rail labels; tap Умения sees skill UI; tap В поля opens run (or confirmation).

- [ ] **Step 2: Implement HubShell** matching flat E layout (SafeArea, Row, right panel ~0.38 width, amber В поля).

- [ ] **Step 3: Deprecate raw HubScreen navigation or make HubScreen thin alias to HubShell.

- [ ] **Step 4: Commit** `feat: flat RO hub shell with right-rail tabs`

---

### Task 5: Restyle Stats / Skills / Shop tabs inside shell

**Files:**
- Modify: `lib/hub/stats_screen.dart`, `skills_screen.dart`, `shop_screen.dart` → tab bodies without AppBar (or `embed` mode)
- Create hero screen: same flat panel language

- [ ] **Step 1: Skills tab matches canon structure** (list + points) inside shell content area.

- [ ] **Step 2: Stats/Shop same padding/cards language.

- [ ] **Step 3: hub_flow_test + hub_shell_test green.

- [ ] **Step 4: Commit** `feat: restyle hub tabs for shell E`

---

### Task 6: Full verification + playtest APK

**Files:**
- Modify: `midgard_outpost/pubspec.yaml` version bump `1.0.3+4`
- Modify: `midgard_outpost/README.md` — short note on art-canon import

- [ ] **Step 1:** `flutter test` — all pass

- [ ] **Step 2:** `flutter build apk --debug`; copy to `/opt/cursor/artifacts/midgard-outpost-debug.apk`

- [ ] **Step 3:** Refresh GitHub release `midgard-debug-apk`

- [ ] **Step 4:** Commit `chore: bump version and document art-canon import`

---

## Spec coverage

| Spec § | Task |
|--------|------|
| §3 asset mapping | 1–2 |
| §3.2–3.3 mobs/bosses | 3 |
| §4 Hub E | 4–5 |
| §5 Run art | 1–3 |
| §8 Acceptance | 6 |

Self-review: no TBD; Wave-2 anim gap explicitly fallback-to-static.
