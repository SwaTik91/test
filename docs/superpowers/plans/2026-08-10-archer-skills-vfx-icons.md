# Archer Skills VFX + Icons + Concentrate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Trap with Concentrate, give each archer skill distinct projectiles/VFX and icons, and show skill descriptions on long-press in the hub Skills menu.

**Architecture:** Content catalog rename + delete trap upgrades; `AutoSkillSystem` allows self-cast for concentrate; `MidgardRunGame` owns buff timer and per-skill visual spawners; `ArtAtlas` registers new icon/projectile paths; hub `SkillsScreen` uses image icons + long-press overlay.

**Tech Stack:** Flutter/Flame, Dart tests, Higgsfield image gen + Pillow cutout into `assets/images/`.

## Global Constraints

- Approach A from `docs/superpowers/specs/2026-08-10-archer-skills-vfx-icons-design.md`
- Concentrate bonus = `rank + 1` for 20s to all stats; no enemy required
- Delete `trap` and all `trap__*` upgrades; no rank migration
- Long-press description only in hub Skills screen
- No auto-cast; damage on projectile impact
- Avoid regenerating unrelated hero/mob/ground art

---

### Task 1: Content — trap → concentrate

**Files:**
- Modify: `midgard_outpost/lib/content/skills.dart`
- Modify: `midgard_outpost/lib/content/run_upgrades.dart`
- Modify: `midgard_outpost/lib/run/run_upgrade_effects.dart`
- Test: `midgard_outpost/test/run/auto_skill_system_test.dart`

- [ ] Replace skill def `trap` with `concentrate` (name/description)
- [ ] Delete three trap run upgrades and their effect map entries
- [ ] Update tests that list archer skill ids
- [ ] Commit

### Task 2: AutoSkillSystem — self-buff cast + tuning

**Files:**
- Modify: `midgard_outpost/lib/run/systems/auto_skill_system.dart`
- Test: `midgard_outpost/test/run/auto_skill_system_test.dart`

- [ ] For `concentrate`, allow cast with 0 enemies in range
- [ ] Tuning: CD ~8s, SP ~14, projectile false, damage 0, range handled in game
- [ ] Tests: cast without enemies; ranks give events; trap id absent
- [ ] Commit

### Task 3: Run buff overlay + CombatMath

**Files:**
- Modify: `midgard_outpost/lib/run/combat_math.dart`
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Test: new or extend combat/auto skill tests

- [ ] Add run-local `_concentrateBonus` / timer; apply on concentrate cast; tick down
- [ ] `_stat` path adds temporary bonus for all StatId while active
- [ ] Refresh resets to 20s; no stacking
- [ ] Commit

### Task 4: Per-skill visuals

**Files:**
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Modify: `midgard_outpost/lib/run/components/projectile_component.dart` (if needed)
- Modify: `midgard_outpost/lib/art/art_atlas.dart`

- [ ] `double_strafe`: two projectiles, 50% damage each, shared crit
- [ ] `wind_arrow`: wind projectile sprite + trail VFX along path
- [ ] `arrow_shower`: 15–20 falling arrows staggered onto targets, damage on impact
- [ ] `concentrate`: spawn aura VFX on player while buff active
- [ ] Commit

### Task 5: Art generation + import

**Files:**
- Create under `midgard_outpost/assets/images/ui/skills/*.png`
- Create under `midgard_outpost/assets/images/projectiles/*.png`
- Create under `midgard_outpost/assets/images/vfx/concentrate_*.png` (optional frames)
- Modify: `art_atlas.dart`, `pubspec.yaml` if needed

- [ ] Higgsfield batch: 5 icons + double arrow + wind arrow + shower arrow + concentrate aura
- [ ] Cutout/process to transparent PNG, register in ArtAtlas/allPaths
- [ ] Asset existence tests pass
- [ ] Commit

### Task 6: HUD icons + hub long-press

**Files:**
- Modify: `midgard_outpost/lib/run/components/hud_overlay.dart`
- Modify: `midgard_outpost/lib/hub/skills_screen.dart`
- Test: `midgard_outpost/test/run/hud_overlay_test.dart` + hub widget test

- [ ] HUD buttons use skill icons; concentrate short label
- [ ] SkillsScreen: image icons for all skills; long-press shows name+description
- [ ] Commit

### Task 7: Verify + APK + PR

- [ ] `flutter test` all green
- [ ] Build/upload debug APK
- [ ] Update PR #7
