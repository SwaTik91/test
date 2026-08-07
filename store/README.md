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
| `screenshots/01_hub.png` … `06_progress.png` | Gallery screenshots (landscape, ≥4) |
| `checklist-appgallery.md` | Чеклист Huawei App Gallery |
| `checklist-rustore.md` | Чеклист RuStore |

## Перегенерация арта

Иконки и скриншоты собираются скриптом из игровых ассетов:

```bash
python3 store/tools/compose_store_art.py
```

Скрипт (Tasks 2–3) создаёт `store/icons/ic_launcher_512.png`, mipmap-экспорты и `store/screenshots/*.png` из `midgard_outpost/assets/images/`.

## Чеклисты

- [checklist-appgallery.md](checklist-appgallery.md) — Huawei App Gallery
- [checklist-rustore.md](checklist-rustore.md) — RuStore
