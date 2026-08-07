# Midgard Outpost Store Listing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare App Gallery + RuStore listing materials (icons, landscape screenshots, RU copy, checklists) and wire the Android app label/icon to «Мидгард: Аванпост».

**Architecture:** Marketing assets live under repo-root `store/` (not loaded by Flutter). A small Python compositor builds the 512 icon and 1920×1080 screenshots from existing `midgard_outpost/assets/images/` pixel art. Android mipmaps and `android:label` are updated from that master icon. A Dart test asserts required `store/` files exist and PNGs meet size floors.

**Tech Stack:** Python 3 + Pillow for compositing; Flutter/Android resources; `flutter_test` + `dart:io` for file checks.

## Global Constraints

- Scope: store listing only — no live IAP SDKs, no upload keystore in repo, no production cloud save
- Stores: Huawei App Gallery + RuStore
- Language: Russian only for listing copy
- Screenshots: landscape **1920×1080** PNG; minimum **4**, target **5–6**
- Icon master: **512×512** opaque PNG; mipmaps 48/72/96/144/192
- Compose from existing art under `midgard_outpost/assets/images/`
- Do not break gameplay; `flutter test` must stay green
- App display name: **Мидгард: Аванпост**

## File Structure

```
store/
  README.md
  listing.ru.md
  checklist-appgallery.md
  checklist-rustore.md
  icons/ic_launcher_512.png
  screenshots/01_hub.png … 05_boss_chest.png (+ optional 06)
  tools/compose_store_art.py          # generator; run once, commit outputs
midgard_outpost/
  android/app/src/main/AndroidManifest.xml
  android/app/src/main/res/mipmap-*/ic_launcher.png
  pubspec.yaml                        # description one-liner
  README.md                           # link to store/
  test/store/store_listing_assets_test.dart
docs/superpowers/specs/2026-08-07-midgard-outpost-store-listing-design.md
```

---

### Task 1: Listing copy + store checklists

**Files:**
- Create: `store/README.md`
- Create: `store/listing.ru.md`
- Create: `store/checklist-appgallery.md`
- Create: `store/checklist-rustore.md`
- Create: `midgard_outpost/test/store/store_listing_assets_test.dart` (text-file portion first)
- Modify: `midgard_outpost/README.md` — add «Витрина сторов» section linking to `../store/`

**Interfaces:**
- Consumes: design spec §6–§7
- Produces: RU listing fields and two store checklists; test helpers `_repoRoot()` and expected relative paths

- [ ] **Step 1: Write failing test for required markdown files**

```dart
// midgard_outpost/test/store/store_listing_assets_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final store = Directory('${dir.path}/store');
    if (store.existsSync()) return dir;
    dir = dir.parent;
  }
  return Directory.current.parent; // midgard_outpost/ → repo root
}

void main() {
  final root = _repoRoot();

  test('store listing markdown files exist', () {
    for (final rel in [
      'store/README.md',
      'store/listing.ru.md',
      'store/checklist-appgallery.md',
      'store/checklist-rustore.md',
    ]) {
      final f = File('${root.path}/$rel');
      expect(f.existsSync(), isTrue, reason: rel);
      expect(f.readAsStringSync().trim().isNotEmpty, isTrue, reason: rel);
    }
  });
}
```

- [ ] **Step 2: Run test — expect FAIL (missing store/)**

```bash
export PATH="/opt/flutter/bin:$PATH"
cd midgard_outpost && flutter test test/store/store_listing_assets_test.dart
```

Expected: FAIL — `store/listing.ru.md` (or sibling) not found.

- [ ] **Step 3: Write listing + checklists**

`store/listing.ru.md` must include at least:

```markdown
# Витрина — Мидгард: Аванпост

## Название
Мидгард: Аванпост

## Краткое описание
Пиксельный side-scroller: город-аванпост, бесконечный забег, три класса и прокачка в духе классического фэнтези.

## Полное описание
Мидгард: Аванпост — пиксельный 2D side-scroller в светлом фэнтези.

Выберите класс — лучника, мага или паладина — в городе Аванпост, распределите статы и умения, затем отправляйтесь в поля. В забеге бегите и прыгайте, авто-умения бьют врагов, ульт активируется кнопкой. Собирайте золото, опыт и временные улучшения из сундуков и дропа. Смерть возвращает в город с сохранённым прогрессом героя.

Игра бесплатна; доступны внутриигровые покупки кристаллов и ускорителей (подключение сторов — по мере публикации).

## Что нового (1.0.0)
Первый релиз MVP: город, забег, три класса, боссы и сундуки, локальный сейв.

## Ключевые слова
пиксель, фэнтези, side-scroller, экшен, аркада, RPG, забег, Мидгард
```

`store/checklist-appgallery.md` and `store/checklist-rustore.md`: checkbox lists covering icon 512, ≥4 screenshots, RU texts, version, category Games/Action-Arcade, age rating, privacy policy URL (mark as blocker if URL missing), developer contact, APK/AAB upload; note IAP console setup is **out of this pass**.

`store/README.md`: table mapping files → which console field; how to regenerate art via `store/tools/compose_store_art.py`.

README project section:

```markdown
## Витрина сторов (App Gallery / RuStore)

Материалы для публикации: [store/](../store/) — иконки, скриншоты, RU-тексты и чеклисты.
Спека: [docs/.../store-listing-design.md](../docs/superpowers/specs/2026-08-07-midgard-outpost-store-listing-design.md).
```

- [ ] **Step 4: Re-run markdown test — expect PASS**

```bash
cd midgard_outpost && flutter test test/store/store_listing_assets_test.dart
```

Expected: PASS for markdown test (PNG tests not added yet or skipped until Task 2–3).

- [ ] **Step 5: Commit**

```bash
git add store/ midgard_outpost/test/store/store_listing_assets_test.dart midgard_outpost/README.md
git commit -m "docs: add App Gallery and RuStore listing copy and checklists"
```

---

### Task 2: Launcher icon + Android label

**Files:**
- Create: `store/tools/compose_store_art.py` (icon mode first; screenshots can share the script)
- Create: `store/icons/ic_launcher_512.png`
- Modify: `midgard_outpost/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`
- Modify: `midgard_outpost/android/app/src/main/AndroidManifest.xml` — `android:label`
- Modify: `midgard_outpost/pubspec.yaml` — `description`
- Modify: `midgard_outpost/test/store/store_listing_assets_test.dart` — icon size asserts

**Interfaces:**
- Consumes: `assets/images/hub/town_bg.png`, `assets/images/heroes/paladin.png` (or archer)
- Produces: opaque 512×512 master; mipmap sizes 48,72,96,144,192; label `Мидгард: Аванпост`

- [ ] **Step 1: Extend test for icon files**

```dart
  test('store icon master is 512x512 PNG', () async {
    final f = File('${root.path}/store/icons/ic_launcher_512.png');
    expect(f.existsSync(), isTrue);
    final bytes = f.readAsBytesSync();
    expect(bytes.length, greaterThan(1000));
    // PNG IHDR width/height at bytes 16..23 big-endian
    expect(bytes[0], 0x89);
    final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    expect(w, 512);
    expect(h, 512);
  });

  test('android mipmap launchers exist', () {
    for (final dens in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      final f = File(
        '${root.path}/midgard_outpost/android/app/src/main/res/mipmap-$dens/ic_launcher.png',
      );
      expect(f.existsSync(), isTrue, reason: dens);
    }
  });
```

- [ ] **Step 2: Run — expect FAIL on missing store/icons**

- [ ] **Step 3: Implement compositor icon path**

`store/tools/compose_store_art.py` responsibilities:

1. Load `midgard_outpost/assets/images/hub/town_bg.png`, cover-scale into 512×512, opaque.
2. Paste scaled hero (~280px) centered from `heroes/paladin.png` (RGBA → composite).
3. Save `store/icons/ic_launcher_512.png` (RGB, no alpha).
4. Resize nearest-neighbor (or LANCZOS then optional pixel feel) to mipmap sizes and overwrite `midgard_outpost/android/.../mipmap-*/ic_launcher.png`.

CLI:

```bash
python3 store/tools/compose_store_art.py --icons
```

- [ ] **Step 4: Wire Android label + pubspec description**

`AndroidManifest.xml`:

```xml
android:label="Мидгард: Аванпост"
```

`pubspec.yaml`:

```yaml
description: "Мидгард: Аванпост — пиксельный side-scroller (Flutter + Flame)."
```

- [ ] **Step 5: Run icon tests — PASS; run full suite smoke**

```bash
cd midgard_outpost && flutter test test/store/store_listing_assets_test.dart && flutter test
```

- [ ] **Step 6: Commit**

```bash
git add store/tools/compose_store_art.py store/icons/ midgard_outpost/android/ midgard_outpost/pubspec.yaml midgard_outpost/test/store/
git commit -m "feat: add branded launcher icon and Russian Android app label"
```

---

### Task 3: Landscape store screenshots

**Files:**
- Create: `store/screenshots/01_hub.png`
- Create: `store/screenshots/02_run_archer.png`
- Create: `store/screenshots/03_run_mage.png`
- Create: `store/screenshots/04_run_paladin.png`
- Create: `store/screenshots/05_boss_chest.png`
- Optional: `store/screenshots/06_progress.png`
- Modify: `store/tools/compose_store_art.py` — `--screenshots` mode
- Modify: `midgard_outpost/test/store/store_listing_assets_test.dart`

**Interfaces:**
- Consumes: hub/town_bg, heroes/*, enemies/*, props/chest, world/bg_*
- Produces: ≥4 PNGs at exactly 1920×1080 with short RU captions

- [ ] **Step 1: Extend test for screenshots**

```dart
  test('store screenshots are 1920x1080 and at least four', () {
    final dir = Directory('${root.path}/store/screenshots');
    expect(dir.existsSync(), isTrue);
    final pngs = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    expect(pngs.length, greaterThanOrEqualTo(4));
    for (final f in pngs) {
      final bytes = f.readAsBytesSync();
      final w = (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      final h = (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
      expect(w, 1920, reason: f.path);
      expect(h, 1080, reason: f.path);
    }
  });
```

- [ ] **Step 2: Run — FAIL until PNGs exist**

- [ ] **Step 3: Implement screenshot compositions**

Extend `compose_store_art.py --screenshots`:

| File | Layout |
|------|--------|
| `01_hub.png` | `town_bg` cover + three class icons + caption «Выбери класс» |
| `02_run_archer.png` | `bg_fields` + archer + goblin + caption «Лучник» |
| `03_run_mage.png` | `bg_forest` + mage + caption «Маг» |
| `04_run_paladin.png` | `bg_fields` + paladin + caption «Паладин» |
| `05_boss_chest.png` | forest/fields + boss_ogre + chest + caption «Боссы и сундуки» |

Use Pillow default font or bundled DejaVu if available for RU captions (large, high-contrast, bottom bar). Keep composition readable; nearest-neighbor upscale for sprites.

```bash
python3 store/tools/compose_store_art.py --screenshots
# or: python3 store/tools/compose_store_art.py --all
```

- [ ] **Step 4: Tests PASS**

```bash
cd midgard_outpost && flutter test test/store/store_listing_assets_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add store/screenshots/ store/tools/compose_store_art.py midgard_outpost/test/store/
git commit -m "feat: add landscape store screenshots from game pixel art"
```

---

### Task 4: README store index polish + full verification

**Files:**
- Modify: `store/README.md` — final file table with exact screenshot names
- Modify: `midgard_outpost/README.md` if paths need tweak
- Verify: checklists mention privacy URL blocker explicitly

**Interfaces:**
- Consumes: outputs of Tasks 1–3
- Produces: acceptance checklist green against design spec §10

- [ ] **Step 1: Update `store/README.md` inventory** listing every committed PNG and which console slot it fills

- [ ] **Step 2: Full test suite**

```bash
export PATH="/opt/flutter/bin:$PATH"
cd midgard_outpost && flutter test
```

Expected: all tests PASS including `test/store/`.

- [ ] **Step 3: Spec acceptance self-check**

Confirm against design §10:

1. `store/` has texts, checklists, icon 512, ≥4 screenshots — yes
2. mipmaps + label «Мидгард: Аванпост» — yes
3. project README links to `store/` — yes
4. gameplay tests untouched/green — yes

- [ ] **Step 4: Commit**

```bash
git add store/README.md midgard_outpost/README.md
git commit -m "docs: finalize store listing inventory and verification notes"
```

---

## Spec coverage (self-review)

| Spec section | Task |
|--------------|------|
| §3 artifact tree | 1–3 |
| §4 icon + mipmaps | 2 |
| §5 screenshots | 3 |
| §6 RU texts | 1 |
| §7 checklists | 1, 4 |
| §8 app label/icon/README | 2, 1, 4 |
| §9 out of scope | not implemented |
| §10 acceptance | 4 |

No TBD placeholders. PNG dimension checks use IHDR bytes (no extra Dart image package).
