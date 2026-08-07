# Мидгард: Аванпост

Пиксельный 2D side-scroller на Flutter + Flame. Город (hub) → бесконечный забег → смерть → мета-прогресс.

Полная дизайн-спека: [docs/superpowers/specs/2026-08-07-midgard-outpost-design.md](../docs/superpowers/specs/2026-08-07-midgard-outpost-design.md)

## Как запустить

```bash
export PATH="/opt/flutter/bin:$PATH"
cd midgard_outpost
flutter pub get
flutter run
```

Только альбомная ориентация. UI — русский.

Тесты:

```bash
cd midgard_outpost && flutter test
```

Сборка APK (debug):

```bash
flutter build apk --debug
```

## Архитектура hub / run

| Модуль | Назначение |
|--------|------------|
| `lib/hub/` | Город: создание героя, статы, умения, магазин, старт забега |
| `lib/run/` | Flame-сессия: бег, авто-скиллы, мобы, боссы, сундуки, temp XP |
| `lib/progress/` | Base/Job уровни, статы, валюты, награды забега |
| `lib/save/` | Локальный сейв (`SharedPreferences`) + облачный порт |
| `lib/iap/` | IAP через `StoreIapService` и адаптеры сторов |
| `lib/content/` | Таблицы контента (умения, улучшения, баланс) |

**Цикл:** `GameController` загружает героя через `SaveService` → hub-экраны → `RunScreen` (Flame) → смерть → `RunSummaryScreen` → начисление наград → возврат в hub.

## StoreTarget и cloud save

Порты выбираются в `main.dart` через `--dart-define` (см. `resolveCloudSavePort`, `resolveStoreTarget`).

### Cloud save (`CLOUD_SAVE`)

| Значение | Поведение |
|----------|-----------|
| *(не задано)* | **debug** → `InMemoryCloudSavePort`; **release** → `NoopCloudSavePort` |
| `memory` | `InMemoryCloudSavePort` (in-process; для dev/QA) |
| `noop` | Без облака |

Пример:

```bash
flutter run --dart-define=CLOUD_SAVE=memory
flutter build apk --release --dart-define=CLOUD_SAVE=noop
```

MVP-путь: `InMemoryCloudSavePort` → заменить на реальный backend (Huawei Account / REST API), реализовав `CloudSavePort`.

### Store / IAP (`STORE_TARGET`)

| Значение | Адаптер |
|----------|---------|
| `fake` (default) | `FakeBillingPort` — покупки всегда успешны |
| `appGallery` | `AppGalleryBillingPort` (stub, нужны ключи Huawei) |
| `ruStore` | `RuStoreBillingPort` (stub, нужны ключи RuStore) |

```bash
flutter run --dart-define=STORE_TARGET=fake
```

## Чеклист публикации App Gallery + RuStore

### Общее

- [ ] **Package ID:** `com.midgard.outpost.midgard_outpost` (согласован в Android manifest / Gradle)
- [ ] **Ориентация:** только landscape (задано в `main.dart`)
- [ ] **Язык:** русские тексты UI, описания в сторах, скриншоты с русским интерфейсом
- [ ] Иконка и feature graphic (placeholder → финальный арт)
- [ ] Политика конфиденциальности (облачный сейв, IAP)

### IAP products (создать в консолях сторов)

| Product ID | Тип |
|------------|-----|
| `crystals_100` | Кристаллы ×100 |
| `crystals_550` | Кристаллы ×550 |
| `boost_base_job_xp` | Буст Base/Job XP 24ч |
| `boost_drop` | Буст дропа 24ч |
| `boost_run_start` | Буст старта забега 24ч |

Каталог: `lib/iap/iap_catalog.dart`.

### Huawei App Gallery

- [ ] AppGallery Connect: приложение, подпись, IAP products
- [ ] Подключить `AppGalleryBillingPort` (SDK + credentials)
- [ ] Облачный сейв через Huawei Account Kit (замена `InMemoryCloudSavePort`)
- [ ] Тестовые аккаунты, review build

### RuStore

- [ ] RuStore Console: приложение, подпись, IAP products
- [ ] Подключить `RuStoreBillingPort` (SDK + credentials)
- [ ] Облачный backend или RuStore-совместимый провайдер
- [ ] Тестовые покупки, review build

## Связанные документы

- [Дизайн-спека MVP](../docs/superpowers/specs/2026-08-07-midgard-outpost-design.md)
