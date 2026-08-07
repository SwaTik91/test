# Task 11 Report: Cloud save wiring + README for stores

## Status: Complete

## Summary

Added `InMemoryCloudSavePort` with roundtrip test, `resolveCloudSavePort()` (debug → in-memory, release → noop, overridable via `CLOUD_SAVE`), wired `main.dart` + `app.dart` bootstrap with `StoreIapService(target: resolveStoreTarget())`, and documented run/architecture/store checklist in `midgard_outpost/README.md` plus root README link.

## Files Created

- `lib/save/cloud_save_port.dart` — `InMemoryCloudSavePort`, `resolveCloudSavePort()`
- `test/save/cloud_save_port_test.dart` — in-memory roundtrip test
- `midgard_outpost/README.md` — run, architecture, StoreTarget/cloud hooks, App Gallery + RuStore checklist, spec link

## Files Modified

- `lib/main.dart` — resolves cloud + store targets, passes to `MidgardApp`
- `lib/app.dart` — accepts `cloud`/`storeTarget`, wires `StoreIapService`
- `lib/iap/store_billing_port.dart` — `resolveStoreTarget()`
- `README.md` (root) — link to game README and design spec

## Tests

```
export PATH="/opt/flutter/bin:$PATH"
cd midgard_outpost && flutter test
00:06 +55: All tests passed!
```

New: `in-memory cloud roundtrip` in `cloud_save_port_test.dart`.

## Concerns / Follow-ups

- `InMemoryCloudSavePort` is process-local only; production needs Huawei Account / REST backend implementing `CloudSavePort`.
- `AppGalleryBillingPort` / `RuStoreBillingPort` still throw `UnimplementedError` until SDK credentials are wired.
- Optional `http_cloud_save_port.dart` stub deferred — port interface is sufficient for MVP hook.

## Commit

`feat: wire cloud save port and document store release checklist`
