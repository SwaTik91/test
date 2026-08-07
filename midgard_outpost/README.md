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

## Баланс (Balance Pass 1 — medium)

Где крутить числа для следующего прохода баланса:

| Файл | Что менять |
|------|------------|
| `lib/content/balance.dart` | Дроп улучшений (0.11), temp XP за оффер (90), интервалы сундука/босса (1000 / 4000 px), IAP-множители |
| `lib/run/combat_math.dart` | Базовые HP/SP/урон/скорость героя от статов, крит, множители run-upgrades |
| `lib/content/monsters.dart` (`MonstersCatalog`) | HP/урон/награды мобов и боссов по волне и биому |
| `lib/progress/progress_service.dart` | Кривые XP: `xpToNextBase` (15 + level×12), `xpToNextJob` (12 + level×10) |

Sanity-тесты medium difficulty: `test/balance/balance_sanity_test.dart` (L1 HP/TTK/TTD, дроп, XP за ~3 мин пакет). Прогон всего набора: `flutter test`.

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

## Art Wave 1 (статичные спрайты)

Wave 1 заменяет цветные прямоугольники на пиксель-арт PNG. Пути централизованы в `lib/art/art_atlas.dart`; Flame загружает спрайты через `ArtAtlas.loadSprite`, hub — через `Image.asset`.

### Папки ассетов

| Папка | Содержимое |
|-------|------------|
| `assets/images/heroes/` | `archer.png`, `mage.png`, `paladin.png` (64×64, idle, прозрачный фон) |
| `assets/images/enemies/` | `mob_goblin.png` (64×64), `boss_ogre.png` (96×96) |
| `assets/images/props/` | `chest.png` |
| `assets/images/projectiles/` | `arrow.png`, `fireball.png`, `holy_bolt.png` |
| `assets/images/world/` | `ground_tile.png`, `bg_fields.png`, `bg_forest.png` |
| `assets/images/hub/` | `town_bg.png`, `icon_archer.png`, `icon_mage.png`, `icon_paladin.png` |
| `assets/images/ui/` | `hp_bar_frame.png`, `btn_jump.png`, `btn_ult.png` |
| `assets/images/_style/` | `style_bible.png` — референс, **не** грузится в игру |

### Как генерировали

1. **GenerateImage** — 16-bit RO-light пиксель-арт по промптам из art spec (герои, мобы, мир, hub, UI).
2. **PIL post-process** — RGBA, flood-fill удаления белого/серого фона (где нужен alpha), tight crop, `Image.NEAREST` resize до целевого размера.
3. **Проверка** — `flutter test test/art/` (пути `ArtAtlas` + `rootBundle` load всех `ArtAtlas.allPaths`).

Стиль: светлая RO-like фантазия, персонажи смотрят вправо, **без анимаций** в Wave 1. Масштабирование в рантайме — nearest-neighbor (Flame `Paint` / `FilterQuality.none`).

### Как перегенерировать

1. Сгенерировать новый PNG (тот же стиль/размер/ориентация).
2. Положить файл по пути из `ArtAtlas` (имя файла не менять без правки `art_atlas.dart`).
3. Прогнать PIL-пайплайн (crop → NEAREST resize → alpha key при необходимости).
4. `flutter test test/art/` — убедиться, что все пути грузятся.
5. Визуально: `flutter run -d linux` (hub + забег) или смотреть превью в `/opt/cursor/artifacts/art-wave1-collage.png`.

План и таски: [docs/superpowers/plans/2026-08-07-midgard-outpost-art-wave1.md](../docs/superpowers/plans/2026-08-07-midgard-outpost-art-wave1.md).

## Art Wave 2 (покадровые анимации)

Wave 2 добавляет покадровые PNG-анимации для забега: герои (idle/run/jump/cast), моб и босс (walk/hurt), сундук (open), VFX скиллов. Пути и `stepTime` — в `lib/art/animation_atlas.dart`; Flame грузит через `SpriteAnimation` / `AnimationAtlas.load`. Статичные PNG волны 1 остаются fallback, если анимация не загрузилась.

### Папки анимаций

| Папка | Содержимое |
|-------|------------|
| `assets/images/heroes/{archer,mage,paladin}/` | `idle_0..1`, `run_0..3`, `jump_0..1`, `cast_0..2` (64×64) |
| `assets/images/enemies/goblin/` | `walk_0..2`, `hurt_0..1` (64×64) |
| `assets/images/enemies/ogre/` | `walk_0..2`, `hurt_0..1` (96×96) |
| `assets/images/props/chest/` | `open_0..2` (64×64) |
| `assets/images/vfx/` | `slash_0..2`, `flame_0..2`, `holy_0..2` (64×64) |

### Триггеры в рантайме

| Анимация | Компонент | Условие |
|----------|-----------|---------|
| idle / run / jump / cast | `PlayerComponent` | grounded + velocity; `!isGrounded`; one-shot cast on skill |
| walk / hurt | `MonsterComponent` | alive + moving; one-shot after damage |
| open | `ChestComponent` | on collect; loop false, last frame held |
| slash / flame / holy | `VfxComponent` | archer / mage / paladin on auto-skill or ult |

### Как генерировали

1. **GenerateImage** — кадры в том же RO-light стиле, что Wave 1 (силуэт класса узнаваем).
2. **PIL post-process** — RGBA, flood-fill magenta→alpha, tight crop, `Image.NEAREST` resize до 64×64 (ogre 96×96), corner alpha check.
3. **Проверка** — `flutter test test/art/` (`AnimationAtlas.allFramePaths` + `rootBundle`; unit-тесты `HeroAnimState` / atlas paths).

### Как перегенерировать

1. Сгенерировать новый кадр (тот же стиль/размер; ogre смотрит влево).
2. Положить по пути из `AnimationAtlas` (имя `{anim}_{index}.png` без смены индексов).
3. PIL-пайплайн (crop → NEAREST resize → alpha key).
4. `flutter test test/art/` — все 55 frame paths грузятся.
5. Визуально: `flutter run -d linux` или превью `/opt/cursor/artifacts/art-wave2-collage.png` (strips: archer run, goblin walk, chest open, VFX slash).

План и таски: [docs/superpowers/plans/2026-08-07-midgard-outpost-art-wave2.md](../docs/superpowers/plans/2026-08-07-midgard-outpost-art-wave2.md). Дизайн-спека: [docs/superpowers/specs/2026-08-07-midgard-outpost-art-wave2-design.md](../docs/superpowers/specs/2026-08-07-midgard-outpost-art-wave2-design.md).

## Связанные документы

- [Дизайн-спека MVP](../docs/superpowers/specs/2026-08-07-midgard-outpost-design.md)
