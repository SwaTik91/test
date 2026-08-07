# Midgard Outpost Art Wave 2 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-frame pixel animations for heroes (idle/run/jump/cast), goblin/ogre (walk/hurt), chest open, and three skill VFX, wired through Flame `SpriteAnimation`.

**Architecture:** `AnimationAtlas` lists frame paths + stepTimes. Components load `SpriteAnimation`s and switch by gameplay state. Wave 1 static PNGs remain as fallback. VFX are short-lived animation components spawned on skill hit/cast.

**Tech Stack:** Flutter/Flame SpriteAnimation, PNG frames via GenerateImage + PIL NEAREST, flutter_test.

## Global Constraints

- Models for SDD (if user-constrained): composer-2.5 / composer-2.5-fast / cursor-grok-4.5-high / cursor-grok-4.5-high-fast only
- Separate PNG frames (no sprite sheets)
- Sizes: heroes/mob/chest/vfx 64×64; boss 96×96
- RO-light pixel style matching Wave 1
- Nearest-neighbor scaling
- Russian UI unchanged
- Wave 1 static paths must keep working
- Paths exactly as Wave 2 design spec §4

## File Structure

```
midgard_outpost/
  assets/images/heroes/{archer,mage,paladin}/{idle_*,run_*,jump_*,cast_*}.png
  assets/images/enemies/{goblin,ogre}/{walk_*,hurt_*}.png
  assets/images/props/chest/{open_*}.png
  assets/images/vfx/{slash_*,flame_*,holy_*}.png
  lib/art/animation_atlas.dart
  lib/art/hero_anim_state.dart          # pure state selector
  lib/run/components/player_component.dart
  lib/run/components/monster_component.dart
  lib/run/components/chest_component.dart
  lib/run/components/vfx_component.dart
  lib/run/midgard_run_game.dart
  test/art/animation_atlas_test.dart
  test/art/hero_anim_state_test.dart
  test/art/animation_assets_exist_test.dart
```

---

### Task 1: AnimationAtlas + hero state selector (TDD)

**Files:**
- Create: `lib/art/animation_atlas.dart`
- Create: `lib/art/hero_anim_state.dart`
- Create: `test/art/animation_atlas_test.dart`
- Create: `test/art/hero_anim_state_test.dart`
- Modify: `pubspec.yaml` if new folders need listing (subdir of existing assets/images/ usually covered)

**Interfaces:**
- Consumes: `HeroClassId`
- Produces:
  - `enum HeroAnimName { idle, run, jump, cast }`
  - `HeroAnimName selectHeroAnim({required bool grounded, required double vx, required bool casting})`
  - `AnimationAtlas.heroFrames(HeroClassId, HeroAnimName) -> List<String>` relative paths
  - `AnimationAtlas.goblinWalkFrames`, `ogreHurtFrames`, `chestOpenFrames`, `vfxSlashFrames`, etc.
  - `static Future<SpriteAnimation> load(List<String> frames, double stepTime, {bool loop = true})`

- [ ] **Step 1: Write failing tests** for path counts (archer run has 4 frames) and selector logic (air→jump, cast priority, run vs idle)

- [ ] **Step 2: Run — FAIL**

```bash
export PATH="/opt/flutter/bin:$PATH"
cd /workspace/midgard_outpost && flutter test test/art/animation_atlas_test.dart test/art/hero_anim_state_test.dart
```

- [ ] **Step 3: Implement atlas + selector** with stepTimes from design spec §5

- [ ] **Step 4: Tests PASS**

- [ ] **Step 5: Commit** `feat: add AnimationAtlas and hero animation state selector`

---

### Task 2: Generate hero animation frames (3 classes)

**Files:** all `assets/images/heroes/{archer,mage,paladin}/*.png` per spec counts

- [ ] **Step 1: GenerateImage** each frame — same class look as Wave 1 static; side view facing right; transparent BG; pose matches anim name
- [ ] **Step 2: PIL** RGBA + NEAREST to 64×64; verify corner alpha
- [ ] **Step 3: Commit** `feat: add hero idle/run/jump/cast animation frames`

---

### Task 3: Generate enemy, chest, VFX frames

**Files:** goblin/ogre walk+hurt; chest open; vfx slash/flame/holy

- [ ] **Step 1: Generate + PIL** (boss 96×96, others 64×64; ogre facing left)
- [ ] **Step 2: Alpha check**
- [ ] **Step 3: Commit** `feat: add enemy, chest, and VFX animation frames`

---

### Task 4: Wire PlayerComponent animations

**Files:**
- Modify: `player_component.dart` → `SpriteAnimationComponent` or keep SpriteComponent and swap animation via ticker
- Prefer `SpriteAnimationComponent` with map of animations; `current` switches from `selectHeroAnim`
- On cast event from game: set casting flag for duration of cast anim

- [ ] **Step 1: Unit test already covers selector; integration via existing suite**
- [ ] **Step 2: Implement load of all hero anims in factory `create`**
- [ ] **Step 3: `flutter test` green
- [ ] **Step 4: Commit** `feat: wire hero SpriteAnimations for idle/run/jump/cast`

---

### Task 5: Wire Monster + Chest animations

**Files:** `monster_component.dart`, `chest_component.dart`

- [ ] **Step 1: Monsters play walk loop; on damage play hurt then return to walk**
- [ ] **Step 2: Chest plays open (loop false) when collected / offer opens**
- [ ] **Step 3: Tests green
- [ ] **Step 4: Commit** `feat: wire monster walk/hurt and chest open animations`

---

### Task 6: VFX component + spawn on skills

**Files:**
- Create: `lib/run/components/vfx_component.dart`
- Modify: `midgard_run_game.dart` (on skill cast / hit)

- [ ] **Step 1: VfxComponent plays once and removesSelf**
- [ ] **Step 2: Map class/skill → slash/flame/holy**
- [ ] **Step 3: `animation_assets_exist_test` loads all AnimationAtlas frame paths**
- [ ] **Step 4: `flutter test` all green
- [ ] **Step 5: Commit** `feat: spawn skill VFX animations on cast`

---

### Task 7: Docs + collage verification

- [ ] **Step 1: PIL collage** of a few anim frame strips → `/opt/cursor/artifacts/art-wave2-collage.png`
- [ ] **Step 2: README** Art Wave 2 section
- [ ] **Step 3: Commit** `docs: document art wave 2 animations`

---

## Plan Self-Review

| Spec item | Task |
|-----------|------|
| Hero idle/run/jump/cast ×3 | 1, 2, 4 |
| Goblin/ogre walk/hurt | 3, 5 |
| Chest open | 3, 5 |
| VFX ×3 | 3, 6 |
| AnimationAtlas | 1 |
| Fallback static Wave 1 | 4 (try/catch or missing→static) |
| Tests assets exist | 6 |

No TBD steps. Frame generation is AI+PIL as Wave 1.
