# Midgard UI Redesign Final Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make hub and run look like a real mobile RPG: Living Stage + Side Dock hub, and a clean side-scroller level with one ground strip and readable scale.

**Architecture:** Replace cream `HubTheme` and stage-covering shell with dark dock layout from `2026-08-08-midgard-ui-art-direction-design.md`; align Flame run layout to same art direction (ground 72% H, actors 18–48% H).

**Tech Stack:** Flutter, Flame, existing `ArtAtlas`, `GameController`, RU UI.

## Global Constraints

- Branch: `cursor/midgard-ui-redesign-final-f916`
- Spec: `docs/superpowers/specs/2026-08-08-midgard-ui-art-direction-design.md`
- Landscape-first; reference viewport 1280×720
- No cream `#FFF8E7` / `#F5E6C8` in hub
- No content overlay on stage (town/hero)
- One accent: `#E69526`
- `flutter test` green
- RU copy preserved

---

### Task 1: Hub shell + theme (Living Stage + Side Dock)

**Files:**
- Modify: `midgard_outpost/lib/hub/hub_theme.dart`
- Modify: `midgard_outpost/lib/hub/hub_shell.dart`
- Modify: `midgard_outpost/test/hub/hub_theme_test.dart`
- Modify: `midgard_outpost/test/hub/hub_shell_test.dart`

**Interfaces:**
- Consumes: `GameController`, `ArtAtlas.townBg`, `ArtAtlas.heroPath`
- Produces: dark tokens (`panelBg`, `cardBg`, `accent`, text colors), dock widgets used by tabs

- [ ] **Step 1: Update tests (RED)**
  - Assert no cream colors in `HubTheme`
  - Assert dock rail + CTA exist and stage is not covered by content panel

- [ ] **Step 2: Replace `HubTheme` cream palette with locked dark tokens**
  - Keep widget API names where possible to minimize tab churn (`HubCard`, `HubPointsHeader`, `HubRankPips`, `HubIncrementButton`, `HubUltBadge`) but dark/orange styling

- [ ] **Step 3: Rewrite `HubShell` layout**
  - Full-bleed town bg
  - `Row( Expanded(58, stage), Expanded(42, dock) )`
  - Stage: hero bottom-center + top-left gold/crystal chips; NO `Positioned.fill` content panel
  - Dock: `panelBg`, radius 16; `Column(Expanded(Row(Expanded(body), rail 72)), CTA В поля 56)`
  - Active rail = accent

- [ ] **Step 4: Update shell tests + run `flutter test test/hub/hub_shell_test.dart test/hub/hub_theme_test.dart`**

- [ ] **Step 5: Commit**
  - `feat(hub): living stage + dark side dock shell`

---

### Task 2: Restyle tab bodies + create hero to dark dock language

**Files:**
- Modify: `midgard_outpost/lib/hub/hub_home_tab.dart`
- Modify: `midgard_outpost/lib/hub/stats_screen.dart`
- Modify: `midgard_outpost/lib/hub/skills_screen.dart`
- Modify: `midgard_outpost/lib/hub/shop_screen.dart`
- Modify: `midgard_outpost/lib/hub/create_hero_screen.dart`
- Modify: related tests (`test/hub/hub_flow_test.dart`, any tab tests)

**Interfaces:**
- Consumes: Task 1 `HubTheme` dark widgets, existing progression/IAP calls
- Produces: embedded tab bodies fitting dock body

- [ ] **Step 1: Swap tab visuals to dark cards/rows**
  - Remove parchment/brown defaults
  - Compact rows, one scroll list, accent `+`
  - Home: class + Base/Job + currency summary in dock body

- [ ] **Step 2: Create Hero same language**
  - Town stage + dark right panel; use class icons/previews; accent CTA

- [ ] **Step 3: Update tests and run hub tests green**

- [ ] **Step 4: Commit**
  - `feat(hub): dark dock tabs and create hero`

---

### Task 3: Run level layout pass (single ground, readable scale)

**Files:**
- Modify: `midgard_outpost/lib/run/midgard_run_game.dart`
- Modify (if needed): run components touching ground/backdrop/actors/hud
- Modify: `midgard_outpost/test/run/*` or add layout tests

**Interfaces:**
- Consumes: canon `ArtAtlas` world/enemy paths, spec §3
- Produces: `groundY = size.y * 0.72`, tile height `~0.28 * size.y`, actor sizes vs `size.y`

- [ ] **Step 1: Fix ground composition**
  - Remove double-floor look: choose one strategy and implement consistently (prefer keep backdrop art visible + live ground strip aligned at 72%; avoid mismatched seam)
  - Ground strip fills from 72% to bottom, no squash

- [ ] **Step 2: Scale pass**
  - Player ~30% H, mobs ~18–24%, bosses ~40–48%, chest ~12–16%
  - Keep nearest-neighbor feel for world sprites

- [ ] **Step 3: Spawn/anchor sanity**
  - Feet on ground line, consistent anchors, reduce visual pile-up if needed for readability

- [ ] **Step 4: Add/update tests for ground ratio / sizes if practical; run `flutter test`**

- [ ] **Step 5: Commit**
  - `feat(run): clean ground strip and readable actor scale`

---

### Task 4: Full verification + APK

**Files:**
- Modify: `midgard_outpost/pubspec.yaml` (bump next patch/build)
- Modify: `midgard_outpost/README.md` short redesign note
- Artifact: `/opt/cursor/artifacts/midgard-outpost-debug.apk`
- Release: GitHub `midgard-debug-apk`

- [ ] **Step 1:** `flutter test` all green
- [ ] **Step 2:** `flutter build apk --debug`
- [ ] **Step 3:** Copy APK to `/opt/cursor/artifacts/midgard-outpost-debug.apk`
- [ ] **Step 4:** Refresh GitHub release asset `midgard-outpost-debug.apk` with `--clobber`
- [ ] **Step 5:** Commit `chore: bump version and document ui redesign final`

---

## Spec coverage

| Spec § | Task |
|--------|------|
| §1 Hub pattern | 1 |
| §2 Colors | 1–2 |
| §3 Run recipe | 3 |
| §4 Type/spacing | 1–3 |
| §6 Acceptance | 4 |
