# Midgard Outpost Balance Pass 1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tune combat and progression to medium difficulty targets (death ~2–4 min, boss checkpoint, meaningful drops/XP) with sanity tests.

**Architecture:** Centralize knobs in `Balance` + `CombatMath` + monster catalog + XP curves in `ProgressService`. Add pure sanity tests that encode target ranges from the balance design spec. No Flame simulation required for pass 1.

**Tech Stack:** Existing Dart/`flutter_test`; edit `lib/content/balance.dart`, `lib/run/combat_math.dart`, `lib/content/monsters.dart` (or equivalent), `lib/progress/progress_service.dart`, kill rewards in run code.

## Global Constraints

- Medium difficulty metrics from `docs/superpowers/specs/2026-08-07-midgard-outpost-balance-design.md`
- Prefer Composer 2.5 / Grok 4.5 if user model constraint still applies
- Do not change IAP product prices; boost multipliers may stay
- Do not rewrite skill upgrade effect tables wholesale
- Keep Russian UI; keep existing tests green
- Exact target constants from spec §4 (drop 0.11, tempXp 90, chest 1000, boss 4000)

## File Structure

```
midgard_outpost/lib/content/balance.dart
midgard_outpost/lib/run/combat_math.dart
midgard_outpost/lib/content/monsters.dart          # or MonstersCatalog
midgard_outpost/lib/progress/progress_service.dart
midgard_outpost/lib/run/midgard_run_game.dart      # kill XP/gold if hardcoded
midgard_outpost/test/balance/balance_sanity_test.dart
midgard_outpost/README.md                         # short «баланс» note
```

---

### Task 1: Sanity tests (RED) encoding target ranges

**Files:**
- Create: `test/balance/balance_sanity_test.dart`

**Interfaces:**
- Consumes: `CombatMath`, `Balance`, `HeroProgress`, monster specs, `ProgressService`
- Produces: failing tests until constants/formulas updated

- [ ] **Step 1: Write tests**

```dart
test('L1 maxHp in medium band', () {
  final h = HeroProgress.createNew(HeroClassId.paladin);
  expect(CombatMath.maxHp(h), inInclusiveRange(140, 200));
});

test('L1 hits-to-kill goblin between 2 and 5', () { /* use catalog goblin hp / basic dmg */ });

test('Balance drop and intervals match design targets', () {
  expect(Balance.monsterUpgradeDropChance, closeTo(0.11, 1e-9));
  expect(Balance.tempXpPerUpgrade, 90);
  expect(Balance.chestEveryDistancePx, 1000);
  expect(Balance.bossEveryDistancePx, 4000);
});

test('simulated kill package yields about 1-2 base levels', () {
  // apply N * killXp via ProgressService; expect baseLevel gain 1..2
});
```

Inspect actual monster catalog API and kill reward helpers; adapt tests to real symbols.

- [ ] **Step 2: Run — expect FAIL** on old constants

```bash
export PATH="/opt/flutter/bin:$PATH"
cd /workspace/midgard_outpost && flutter test test/balance/balance_sanity_test.dart
```

- [ ] **Step 3: Commit** `test: add balance sanity ranges for medium difficulty`

---

### Task 2: Update Balance + XP curves + kill rewards

**Files:**
- Modify: `balance.dart` (0.11 / 90 / 1000 / 4000)
- Modify: `progress_service.dart` XP curves per spec example
- Modify: kill XP/gold sources (midgard_run_game or rewards helper)

- [ ] **Step 1: Apply Balance constants**
- [ ] **Step 2: Soften early XP curves** (`15+level*12` base, `12+level*10` job — or values that pass simulated package test)
- [ ] **Step 3: Tune per-kill and boss rewards**
- [ ] **Step 4: Run balance tests — partial green**
- [ ] **Step 5: Commit** `feat: tune Balance constants and XP/gold rewards`

---

### Task 3: Tune CombatMath + monster stats

**Files:**
- Modify: `combat_math.dart` HP/damage formulas to hit L1 bands
- Modify: monster catalog HP/damage/moveSpeed for goblin & boss ratios (boss HP ~8–12× pack)

- [ ] **Step 1: Adjust formulas until hits-to-kill tests pass**
- [ ] **Step 2: Ensure existing combat_math tests still pass (update expectations if intentionally changed)**
- [ ] **Step 3: Commit** `feat: retune CombatMath and monster stats for medium difficulty`

---

### Task 4: Full suite + README note

- [ ] **Step 1:** `flutter test` all green
- [ ] **Step 2:** README short section: where balance lives (`Balance`, `CombatMath`, monsters, XP curves)
- [ ] **Step 3:** Commit `docs: document balance knobs for medium difficulty pass`

---

## Plan Self-Review

| Spec metric | Task |
|-------------|------|
| Drop 0.11 / chest 1000 / tempXp 90 / boss 4000 | 1, 2 |
| L1 HP/damage bands | 1, 3 |
| Mob TTK / TTD | 1, 3 |
| XP 1–2 levels per ~3 min package | 1, 2 |
| README knobs | 4 |
| IAP out of scope | respected |
