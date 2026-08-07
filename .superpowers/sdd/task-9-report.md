# Task 9 Report: Chests, monster drops, bosses, biomes, upgrade picker

## Status

Implemented and pushed on `cursor/midgard-outpost-game-design-f916`.

## What changed

- Added `SpawnSystem` with boss/chest interval checks and biome switching:
  `Поля` before 8000px, `Лес` from 8000px onward.
- Added a distance-scaled monster catalog and boss specs with larger HP,
  higher damage/rewards, temp XP, and guaranteed upgrade-drop chance.
- Added chest spawning every `Balance.chestEveryDistancePx` and boss spawning
  every `Balance.bossEveryDistancePx` in `MidgardRunGame`.
- Wired chest collection, monster upgrade drops, boss drops, and temp XP
  thresholds into `UpgradeOfferService.rollOffer`.
- Added a paused Russian `UpgradePickerOverlay` with three upgrade cards.
- On pick, the upgrade ID is added to `RunState.ownedUpgradeIds` and to the
  live `MidgardRunGame.ownedRunUpgradeIds` set used by `AutoSkillSystem`.
- Added a HUD biome label.

## Tests

- Red check observed first:
  `flutter test test/run/spawn_system_test.dart` failed because
  `lib/run/systems/spawn_system.dart`, `SpawnSystem`, and `Biome` did not exist.
- Focused green:
  `flutter test test/run/spawn_system_test.dart` ended `+3: All tests passed!`.
- Full suite:
  `flutter test` ended `+44: All tests passed!`.

## Commits

- `2d1a75f feat: add chests bosses biomes and upgrade picker`
- `e5b402e fix: use double boss movement speed`

## Concerns / follow-ups

- Upgrade picker flow is covered through service/spawn tests and full widget
  regression tests, but not by a dedicated Flame overlay interaction test.
- Existing run-upgrade effects remain simplified; this task wires acquisition
  and live visibility rather than implementing every catalog effect.
