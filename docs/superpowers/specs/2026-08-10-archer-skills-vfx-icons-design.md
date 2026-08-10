# Archer Skills VFX + Icons + Concentrate — Design

**Date:** 2026-08-10  
**Approach:** A — dedicated skill art + icons + code behavior  
**Branch:** `cursor/midgard-ui-redesign-final-f916`

## Goal

Make archer combat skills visually distinct and mechanically correct:

1. Skill animations match the skill fantasy (two arrows, wind, sky rain).
2. Replace Trap with Concentrate (timed all-stat buff).
3. Draw icons for every archer skill including the passive.
4. Long-press skill description in the hub Skills menu only.

## Decisions (locked)

| Topic | Choice |
|---|---|
| Implementation package | A — new sprites + icons + behavior |
| Concentrate scaling | Rank 1 → +2, rank 2 → +3, rank 3 → +4 … i.e. `+(rank + 1)` to all stats for 20s |
| Long-press description | Hub Skills screen only (not in-run HUD) |
| Trap / trap upgrades | Delete skill and all `trap__*` run upgrades; no migration of ranks |

## Skill roster (archer)

| ID | Name | Kind | Combat |
|---|---|---|---|
| `double_strafe` | Двойная стрела | auto | Two projectiles toward target(s); dedicated arrow art |
| `wind_arrow` | Ветряная стрела | auto | One wind-wrapped arrow; dedicated art + wind trail |
| `concentrate` | Сосредоточиться | auto | Self-buff only; no enemy required; +stats for 20s |
| `eagle_eye` | Глаз орла | passive | Unchanged combat effect; gets an icon |
| `arrow_shower` | Град стрел | ultimate | AOE rain: 15–20 arrows fall from above onto enemies in range |

Removed: `trap` and upgrades `trap__spiked_trap`, `trap__sticky_resin`, `trap__double_setup`.

## Mechanics

### Manual cast (unchanged policy)

- No auto-cast. HUD buttons for castables; tick only CD + SP regen.
- Passive never gets a cast button.

### Double Strafe

- On cast with ≥1 enemy in range: spawn **two** projectiles at the same target (or nearest), offset vertically/horizontally so both read as a pair.
- Damage: existing skill damage split or full per arrow? **Full event damage applied once on first impact; second arrow is visual companion that also deals a small fixed share** — simpler and fairer for RO feel: **each arrow deals 50% of rolled skill damage** (rounded, min 1), crit rolled once and shared.
- Projectile sprite: `projectiles/double_strafe_arrow.png` (not the basic arrow).

### Wind Arrow

- Single projectile with wind trail VFX following the path.
- Sprite: `projectiles/wind_arrow.png`.
- On impact: existing skill VFX + damage on arrival.

### Concentrate

- Castable with **0 enemies** in range (self-target).
- Costs SP; starts cooldown; duration **20 seconds**.
- Stat bonus: `rank + 1` added to **every** `StatId` while active (STR/AGI/VIT/INT/DEX/LUK).
- CombatMath / move speed / HP-SP derived stats that read hero stats during the run must include this temporary bonus (run-local overlay, not written into saved `hero.stats`).
- Refreshing while active: **refresh duration** to 20s; bonus uses current rank (no stacking).
- Visual: soft aura on the hero for the buff duration (`vfx/concentrate_*` or single looping frame set).
- HUD: optional small timer badge near SP or skill button while active (nice-to-have; not required for v1 if aura is clear).

### Arrow Shower (ultimate)

- Targets all living monsters in ultimate range (up to tuning `targetCount`, keep ≥5).
- Visual: for each hit target (and filler shots up to 15–20 total), spawn falling arrows from above the enemy head toward impact point over ~0.35–0.55s with slight random X offset and stagger.
- Damage applies **on impact** of the rain (AOE per target once), not on cast frame.
- Art: `projectiles/arrow_shower_arrow.png` and/or short fall-frame strip.

### Save / migration

- Catalog drops `trap`. Hub and cast lists never show it.
- If `hero.skillRanks` still contains `trap`, ignore it (do not convert to `concentrate`).
- Run upgrade pool removes all `trap__*` ids; owned dead ids in a run save do nothing and are filtered from offers.

## Icons

Five square icons (~64–96px), transparent background, RO / midgard pixel-fantasy style consistent with existing UI gold/teal accents:

| Asset | Skill |
|---|---|
| `ui/skills/double_strafe.png` | Двойная стрела |
| `ui/skills/wind_arrow.png` | Ветряная стрела |
| `ui/skills/concentrate.png` | Сосредоточиться |
| `ui/skills/eagle_eye.png` | Глаз орла |
| `ui/skills/arrow_shower.png` | Град стрел |

Usage:

- Hub Skills cards: real image instead of kind Material icons.
- In-run HUD skill buttons: icon + optional short label; CD overlay unchanged.

## Hub long-press description

- Only on Skills screen cards/icons.
- Long-press (≥ ~400ms) shows a modal or overlay with **name + description** (and rank line).
- Short tap / `+` button behavior unchanged (allocate point).
- Not implemented on in-run HUD buttons.

## Art pipeline (Higgsfield)

Prerequisite: Higgsfield MCP session must be authorized before generation.

Generate (batch, cutout/process into repo assets):

1. Five skill icons.
2. Double-strafe arrow projectile.
3. Wind arrow projectile (+ optional 2–3 wind trail frames).
4. Concentrate aura frames (2–4).
5. Arrow-shower falling arrow (and optional impact spark reuse of existing VFX).

No expensive regenerations of unrelated assets (heroes/mobs/ground).

## Architecture touchpoints

| Area | Change |
|---|---|
| `lib/content/skills.dart` | Replace trap → concentrate |
| `lib/content/run_upgrades.dart` | Delete trap upgrades |
| `lib/run/systems/auto_skill_system.dart` | Concentrate tuning (self-cast, no enemy gate); remove trap |
| `lib/run/midgard_run_game.dart` | Per-skill visuals; buff timer; rain ult; dual projectiles |
| `lib/run/combat_math.dart` | Optional run buff stat overlay hook |
| `lib/run/components/hud_overlay.dart` | Icons; label for concentrate |
| `lib/hub/skills_screen.dart` | Image icons + long-press description |
| `lib/art/art_atlas.dart` | Register new paths |
| Tests | Catalog, cast rules, buff math, no trap refs |

## Testing

- Unit: concentrate bonus = rank+1; cast without enemies; duration refresh; trap absent from catalog/upgrades.
- Unit: double_strafe cast event still spends SP once.
- Widget: skills screen long-press reveals description text.
- Existing run/combat tests updated for renamed skill ids.
- Full `flutter test` green before APK.

## Out of scope

- Mage/paladin unique skill art.
- Keyboard binds.
- Migrating old trap ranks to concentrate.
- In-run long-press tooltips.
- Redesigning ground/mobs.
