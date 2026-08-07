# Витрина сторов — Мидгард: Аванпост

Материалы для публикации в **Huawei App Gallery** и **RuStore**: тексты, чеклисты, иконки и скриншоты.

Спека: [docs/superpowers/specs/2026-08-07-midgard-outpost-store-listing-design.md](../docs/superpowers/specs/2026-08-07-midgard-outpost-store-listing-design.md).

## Файлы → поля консоли

| Файл | Куда в консоли |
|------|----------------|
| `listing.ru.md` → **Название** | App name / Название приложения |
| `listing.ru.md` → **Краткое описание** | Short description / Краткое описание |
| `listing.ru.md` → **Полное описание** | Full description / Описание |
| `listing.ru.md` → **Что нового** | What's new / История версий |
| `listing.ru.md` → **Ключевые слова** | Keywords / Теги (где поддерживается) |
| `icons/ic_launcher_512.png` | App icon 512×512 |
| `android/.../mipmap-*/ic_launcher.png` | Иконка в APK (генерируется из master 512) |
| `screenshots/01_hub.png` | Screenshot 1 — город, выбор класса («Выбери класс») |
| `screenshots/02_run_archer.png` | Screenshot 2 — забег лучника |
| `screenshots/03_run_mage.png` | Screenshot 3 — забег мага |
| `screenshots/04_run_paladin.png` | Screenshot 4 — забег паладина |
| `screenshots/05_boss_chest.png` | Screenshot 5 — босс и сундук («Боссы и сундуки») |
| `checklist-appgallery.md` | Чеклист Huawei App Gallery |
| `checklist-rustore.md` | Чеклист RuStore |

В консолях App Gallery и RuStore загружайте скриншоты **по порядку 01→05** (landscape PNG 1920×1080, минимум 4).

## Перегенерация арта

Иконки и скриншоты собираются скриптом из игровых ассетов:

```bash
python3 store/tools/compose_store_art.py --icons
python3 store/tools/compose_store_art.py --screenshots
python3 store/tools/compose_store_art.py --all
```

Флаги:

- `--icons` — master 512×512 и mipmap-экспорты в `midgard_outpost/android/.../mipmap-*`
- `--screenshots` — landscape PNG 1920×1080 в `store/screenshots/` (RU-подписи; нужен `store/tools/fonts/DejaVuSans-Bold.ttf`)
- `--all` — оба режима

Шрифт подписей: **DejaVu Sans Bold** (Bitstream Vera / DejaVu Fonts License) в `store/tools/fonts/`.

Скрипт читает `midgard_outpost/assets/images/` (hub, heroes, enemies, props, world).

## Чеклисты

- [checklist-appgallery.md](checklist-appgallery.md) — Huawei App Gallery
- [checklist-rustore.md](checklist-rustore.md) — RuStore
