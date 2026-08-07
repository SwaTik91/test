# Task 7 Report: Flame Run Vertical Slice

## Status: Complete

## Summary

Implemented the Flame run MVP from hub «В поля»: player movement/jump, class-based auto basic attack, simple monster spawning/contact damage, run reward accumulation, death transition to `RunSummaryScreen`, and reward application through `GameController.onRunFinished`.

## TDD Evidence

### Red

Command:

```
export PATH="/opt/flutter/bin:$PATH" && cd /workspace/midgard_outpost && flutter test test/run/player_combat_math_test.dart test/run/run_rewards_test.dart
```

Expected failures observed:

- `lib/run/combat_math.dart`: no such file
- `CombatMath`: undefined
- `RunRewardsAccumulator`: method not found

### Green

Command:

```
export PATH="/opt/flutter/bin:$PATH" && cd /workspace/midgard_outpost && flutter test test/run/player_combat_math_test.dart test/run/run_rewards_test.dart
```

Result:

```
00:01 +7: All tests passed!
```

## Files Created

- `lib/run/combat_math.dart`
- `lib/run/midgard_run_game.dart`
- `lib/run/components/player_component.dart`
- `lib/run/components/monster_component.dart`
- `lib/run/components/hud_overlay.dart`
- `lib/hub/run_screen.dart`
- `test/run/player_combat_math_test.dart`
- `test/run/run_rewards_test.dart`

## Files Modified

- `lib/run/run_rewards.dart` — added `RunRewardsAccumulator`
- `lib/hub/hub_screen.dart` — «В поля» opens `RunScreen`
- `lib/hub/run_summary_screen.dart` — continue awaits reward application
- `test/content/content_tables_test.dart` — removed stale unused import
- `test/progress/hero_progress_test.dart` — removed stale unused import

## Verification

```
export PATH="/opt/flutter/bin:$PATH" && cd /workspace/midgard_outpost && flutter analyze
No issues found! (ran in 6.7s)
```

```
export PATH="/opt/flutter/bin:$PATH" && cd /workspace/midgard_outpost && flutter test
00:05 +28: All tests passed!
```

Linux desktop device was detected by `flutter devices`; I did not launch `flutter run -d linux` because it is a persistent foreground app process in this agent session. Automated tests are the gate.

## Commits

- `64de8b2 feat: add Flame run slice with auto-combat and death summary`
- `5b7e3b4 chore: remove unused Dart imports`

## Concerns / Follow-ups

- Ultimate is intentionally a cooldown stub for Task 8.
- MVP visuals are colored rectangles; no pixel art in this task.

## Review Fixes (Task 7)

### Changes

1. **Russian HUD labels** — `hud_overlay.dart` now shows `Базовый опыт / Проф. опыт / Золото` instead of English `Base / Job / Gold`.
2. **RunSummaryScreen guarded exit** — Converted to `StatefulWidget` with `PopScope(canPop: false)`, shared `_finishAndLeave()` for continue/AppBar back/system back, and `_isLeaving` flag to prevent double reward application.

### Tests

Added `test/hub/run_summary_test.dart` (4 cases):

- System back (`handlePopRoute`) applies rewards and pops
- «Продолжить» applies rewards and returns
- AppBar back applies rewards before leaving
- Double continue invokes `onContinue` only once

Command:

```
export PATH="/opt/flutter/bin:$PATH" && cd /workspace/midgard_outpost && flutter test test/hub/ test/run/
```

Result:

```
00:03 +16: All tests passed!
```

### Commits

- `fix: Russian HUD labels and guarded RunSummaryScreen exit`
