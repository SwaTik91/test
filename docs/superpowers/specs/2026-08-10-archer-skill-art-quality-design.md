# Archer Skill Art Quality Pass — Design

**Date:** 2026-08-10  
**Approach:** A — hi-res painted icons + clean projectile sprites + code glow/trail/aura  
**Branch:** `cursor/midgard-ui-redesign-final-f916`  
**Parent:** `2026-08-10-archer-skills-vfx-icons-design.md` (mechanics unchanged)

## Goal

Replace noisy low-res “pixel-AI” skill icons and VFX with clean **painted RPG** art (RO / AFK Arena quality) so HUD buttons and in-run skill effects no longer look grainy or blocky.

## Problem (locked)

| Symptom | Cause |
|---|---|
| Grain / noise on icons and projectiles | Tiny assets (64×64 / 96×48 / 96×96) cut from noisy AI gens |
| Blocky / dirty upscale | `FilterQuality.none` on soft painted sprites |
| Dirty concentrate aura | Noisy frame strip with bad alpha halo |

## Decisions (locked)

| Topic | Choice |
|---|---|
| Visual style | Clean painted RPG (not pixel art) |
| Implementation package | **A** — hi-res icons + clean projectile sprites + code glow/trail/aura |
| Mechanics | Unchanged from parent archer Design A (Concentrate, dual arrows, wind, shower, long-press, etc.) |
| Filter for skill art | `FilterQuality.medium` (not `none`) for skill icons, skill projectiles, and code glow |
| Pixel heroes/world | Out of scope — keep existing hero/mob/ground filtering policy |

## Icons

Regenerate all five archer skill icons:

| Asset | Skill | Motif |
|---|---|---|
| `ui/skills/double_strafe.png` | Двойная стрела | Two parallel golden arrows |
| `ui/skills/wind_arrow.png` | Ветряная стрела | Cyan wind-wrapped arrow |
| `ui/skills/concentrate.png` | Сосредоточиться | Focused eye / golden focus sigil |
| `ui/skills/eagle_eye.png` | Глаз орла | Eagle eye |
| `ui/skills/arrow_shower.png` | Град стрел | Many arrows falling from sky |

Requirements:

- **256×256** PNG, RGBA, transparent background (no checkerboard leftovers, no gray noise halo).
- Painted RPG look: smooth gradients, readable silhouette at HUD button size (~40–48 logical px).
- No pixel-art prompt language; no dither / grain / CRT texture.
- Hub Skills screen + in-run HUD continue to use `ArtAtlas.skillIconPath`.

## Projectiles

Regenerate three dedicated skill projectiles:

| Asset | Use |
|---|---|
| `projectiles/double_strafe_arrow.png` | Dual-strafe arrows |
| `projectiles/wind_arrow.png` | Wind Arrow body |
| `projectiles/arrow_shower_arrow.png` | Falling shower arrows |

Requirements:

- Target size about **256×128** (or similar landscape), clean alpha.
- Readable as a single arrow silhouette; soft painted shading; no noise field.
- Render with `FilterQuality.medium`.

Basic `projectiles/arrow.png` (auto-attack) is out of scope unless it is already used as a fallback and looks broken; prefer dedicated skill sprites only.

## In-run VFX (code)

Replace sprite-based concentrate aura frames with code-drawn effects:

1. **Concentrate aura** — soft golden ring / radial glow attached to hero while buff active (CircleComponent or custom glow; pulse optional). Remove `vfx/concentrate_0..3.png` from atlas, assets, and tests.
2. **Wind Arrow trail** — cyan soft trail / glow following the projectile path (simple trail segments or additive glow sprites generated in code / solid circles).
3. **Arrow Shower impact** — keep falling arrow sprites; add a brief soft impact glow on hit (reuse or tiny code flash).

No new concentrate PNG frame strip.

## Rendering policy

| Surface | Filter |
|---|---|
| Skill icons (HUD + hub) | `FilterQuality.medium` |
| Skill projectiles (strafe / wind / shower) | `FilterQuality.medium` |
| Code glow / trail / aura | Soft paint (default / medium); never nearest-neighbor |
| Existing pixel heroes / tiles | Unchanged existing policy |

## Art pipeline

1. Generate via Higgsfield API (or MCP if session valid): nano / painted image model, **explicitly non-pixel**, transparent or solid bg then rembg cutout.
2. Post-process: remove background, strip fringe noise, pad to exact sizes, verify no checkerboard baked in.
3. Overwrite the seven PNG paths above; delete concentrate aura PNGs.
4. Do **not** regenerate heroes, mobs, ground, or unrelated UI.

Credits note: generation costs credits; batch only the seven assets listed.

## Code touchpoints

| Area | Change |
|---|---|
| `lib/art/art_atlas.dart` | Drop concentrate aura frame constants; keep skill icon/projectile paths |
| `lib/run/midgard_run_game.dart` | Code aura; medium filter on skill projectiles; wind trail; remove aura sprite load |
| `lib/run/components/hud_overlay.dart` | Skill icon `FilterQuality.medium` |
| `lib/hub/skills_screen.dart` | Skill icon `FilterQuality.medium` |
| Assets | Overwrite icons + skill projectiles; delete `vfx/concentrate_*.png` |
| Tests | `art_atlas_test` / asset existence tests updated for removed aura frames |

## Testing

- Asset existence / atlas: five icons + three projectiles present; concentrate aura frames absent.
- Widget: hub skills still show icons; long-press description still works.
- Full `flutter test` green.
- Rebuild debug APK and refresh release `midgard-debug-apk`.

## Out of scope

- Changing skill damage / CD / Concentrate math.
- Mage / paladin skill icons.
- Redesigning heroes, monsters, ground, or hub chrome.
- In-run buff timer badge.
- Migrating trap ranks.
