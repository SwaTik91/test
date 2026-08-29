# Archer Skill Art Quality Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace noisy low-res archer skill icons/VFX with clean painted RPG art and code-drawn glow so HUD and combat effects look polished.

**Architecture:** Overwrite seven PNGs (5 icons 256×256, 3 projectiles ~256×128) with rembg-cleaned painted assets; remove concentrate aura frame strip; draw concentrate aura + wind trail in Flame with soft paint; use `FilterQuality.medium` for all skill art surfaces.

**Tech Stack:** Flutter/Flame, Higgsfield image API (`nano_banana_pro` or equivalent), rembg/Pillow, `flutter_test`.

## Global Constraints

- Style: clean painted RPG (RO / AFK Arena), **not** pixel art
- Mechanics unchanged from parent archer Design A
- Skill icons: 256×256 RGBA transparent
- Skill projectiles: ~256×128 RGBA transparent
- Filter: `FilterQuality.medium` for skill icons/projectiles/glow
- Delete `vfx/concentrate_0..3.png` (code aura instead)
- Do not regenerate heroes/mobs/ground
- Branch: `cursor/midgard-ui-redesign-final-f916`
- Full `flutter test` green before APK

## File map

| File | Responsibility |
|---|---|
| `assets/images/ui/skills/*.png` | Five painted icons |
| `assets/images/projectiles/{double_strafe,wind,arrow_shower}_arrow.png` | Three projectiles |
| `assets/images/vfx/concentrate_*.png` | **Delete** |
| `lib/art/art_atlas.dart` | Drop aura frame paths |
| `lib/run/midgard_run_game.dart` | Code aura + wind trail + medium filter |
| `lib/run/components/hud_overlay.dart` | Medium filter on skill icons |
| `lib/hub/skills_screen.dart` | Medium filter on skill icons |
| `test/art/art_atlas_test.dart` | Expect no concentrate aura frames |
| `test/art/assets_exist_test.dart` / animation tests | Update if they list aura frames |

---

### Task 1: Update atlas + tests for removed aura frames

**Files:**
- Modify: `midgard_outpost/lib/art/art_atlas.dart`
- Modify: `midgard_outpost/test/art/art_atlas_test.dart`
- Delete: `midgard_outpost/assets/images/vfx/concentrate_0.png` … `concentrate_3.png`

- [ ] **Step 1:** Remove `concentrateAura*` constants / `concentrateAuraFrames` / entries from `allPaths`.
- [ ] **Step 2:** Update tests so they assert aura frames are absent and skill icon/projectile paths remain.
- [ ] **Step 3:** Delete the four concentrate PNG files.
- [ ] **Step 4:** Commit.

### Task 2: Code concentrate aura + wind trail + FilterQuality.medium

**Files:**
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Modify: `midgard_outpost/lib/run/components/hud_overlay.dart`
- Modify: `midgard_outpost/lib/hub/skills_screen.dart`

- [ ] **Step 1:** Replace sprite aura load/show with a soft golden `CircleComponent` (or custom glow) parented/positioned on hero while `_concentrateTimer > 0`.
- [ ] **Step 2:** Add cyan trail/glow on wind-arrow projectiles (short-lived circles or trail component).
- [ ] **Step 3:** Set `FilterQuality.medium` on skill projectiles and skill icon `Image` widgets (HUD + hub).
- [ ] **Step 4:** Run focused tests; commit.

### Task 3: Regenerate painted skill art (7 assets)

**Files:**
- Overwrite: `assets/images/ui/skills/{double_strafe,wind_arrow,concentrate,eagle_eye,arrow_shower}.png`
- Overwrite: `assets/images/projectiles/{double_strafe_arrow,wind_arrow,arrow_shower_arrow}.png`

- [ ] **Step 1:** Generate 5 icons + 3 projectiles via Higgsfield (painted, non-pixel prompts).
- [ ] **Step 2:** rembg cutout + resize/pad to target sizes; verify clean alpha (no noise halo).
- [ ] **Step 3:** Install into asset paths; run `assets_exist` / atlas tests.
- [ ] **Step 4:** Commit assets.

### Task 4: Verify, APK, PR

- [ ] **Step 1:** `cd midgard_outpost && flutter test`
- [ ] **Step 2:** `flutter build apk --debug`; upload to `midgard-debug-apk` as `midgard-outpost-debug.apk`
- [ ] **Step 3:** Update PR #7 body with quality-pass notes + APK link
- [ ] **Step 4:** Push branch
