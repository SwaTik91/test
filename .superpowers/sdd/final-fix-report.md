# Final Fix Report

## Summary

- Added `HeroProgress.hasActiveBoost(String id, {DateTime? now})`.
- Applied `boost_base_job_xp` in `ProgressService.applyRunRewards` with `Balance.iapBaseJobXpBoostMultiplier` (`1.5x`).
- Applied `boost_drop` through monster upgrade drop chances with `Balance.iapDropBoostMultiplier` (`1.5x`).
- Applied `boost_run_start` through run-start HP/SP scaling with `Balance.iapRunStartResourceMultiplier` (`1.2x`).
- Implemented approach A for run upgrades: every catalog upgrade now has a runtime consumer via `RunUpgradeEffects` and is wired through combat math, auto skills, run rewards, drop/chest cadence, player survival, healing, regen, thorns, and boss tuning.
- Fixed `StoreIapService` and `FakeBillingPort` so unknown product IDs return `false`.
- Updated README IAP product IDs to match `iap_catalog.dart`.

## Verification

Command:

```bash
export PATH="/opt/flutter/bin:$PATH"
cd /workspace/midgard_outpost && flutter test
```

Output:

```text
00:07 +60: All tests passed!
```
