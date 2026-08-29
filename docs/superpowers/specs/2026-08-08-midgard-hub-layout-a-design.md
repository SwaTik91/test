# Мидгард: Аванпост — хаб Layout A (дизайн)

Связано с: `2026-08-07-midgard-outpost-art-hub-canon-design.md`, эталон `docs/superpowers/art-canon/hub-skills-canon.png`.

## 1. Цель

Текущий хаб **не совпадает** с skills-canon: кремовая панель перекрывает город и героя, visual language ушёл в «пергамент».  
Нужно привести оболочку к **каркасу кадра E / skills-canon** (вариант реализации **A**): слева всегда видна сцена, справа тёмный flat UI.

Это **supersedes** cream-card restyle из Task 5 art-hub-canon (`HubTheme` cream palette) для оболочки и вкладок хаба.

## 2. Выбранный подход

**A — Layout-first 1:1 каркас** (утверждено):

- Слева город + герой всегда видны.
- Справа одна тёмная панель + узкий rail + «В поля».
- Вкладки перекрасить в dark/orange.
- Без полного RO-хрома (нет status-окна HP/SP слева, нет хотбара 1–0, нет `[-]` deallocate).

Отложено (вариант B, отдельная спека при необходимости): status overlay, hotbar, pixel-clone skill rows.

## 3. Оболочка `HubShell`

### 3.1 Геометрия (landscape SafeArea)

| Зона | Доля ширины | Содержание |
|------|-------------|------------|
| Stage (лево) | ~55–60% | `town_bg` full-bleed + спрайт текущего класса, bottom-center, nearest-neighbor |
| UI (право) | ~40–45% | Одна тёмная flat-панель |

Правая панель внутри себя:

1. **Body** вкладки (flex grow) — Главная / Статы / Умения / Магазин.
2. **Rail** — узкая колонка справа внутри панели или соседняя колонка внутри правого блока: иконка + подпись, active = оранжевый фон.
3. **В поля** — оранжевая кнопка внизу rail (или низа правого блока, выровнена с rail).

Рекомендуемая внутренняя раскладка правого блока: `Row( Expanded(body), railColumn )`, rail ~72–96 dp.

### 3.2 Жёсткие запреты

- **Запрещено** класть полупрозрачную/кремовую/`Positioned.fill` панель поверх stage так, чтобы герой/город пропадали.
- **Запрещено** cream/parchment (`#FFF8E7` / `#F5E6C8`) как основной фон вкладок хаба.
- **Запрещён** Material `AppBar` на embedded-вкладках внутри shell.
- Без Windows98 / классического RO window chrome.

### 3.3 Палитра (dark flat)

| Токен | Значение | Назначение |
|-------|----------|------------|
| `panelBg` | `#1E293B` / `#2A2E35` | Правая панель, rail фон |
| `cardBg` | чуть светлее панели (`#334155` family) | Строки/карточки внутри вкладок |
| `textPrimary` | белый / near-white | Заголовки, имена |
| `textMuted` | slate-300/400 | Вторичный текст |
| `accent` | оранжевый `#E69526` / amber-600 | Active tab, «В поля», основные CTA/`+` |
| `border` | subtle slate border | Опционально, тонкая |

Обновить `HubTheme` под эти токены (или заменить cream API), чтобы Stats/Skills/Shop/Home делили один language.

## 4. Вкладки

Логика прогрессии, IAP и RU-копирайт **без смены модели**. Меняется только визуал + встраивание в shell.

| Вкладка | Содержание |
|---------|------------|
| Главная | Класс, Base/Job (или уровни как в текущей модели), золото, кристаллы |
| Статы | STR…LUK, «+», очки статов |
| Умения | Список умений класса, ранги, очки умений, «+» allocate |
| Магазин | Каталог IAP, «Купить» |
| В поля | Переход в `RunScreen` (подтверждение — если уже есть, сохранить; иначе прямой push OK для A) |

Создание героя: тот же dark flat language на фоне города (не cream overlay).

## 5. Вне scope (явно)

- Run/Flame арт, мобы, боссы, HUD забега — не трогаем в этом проходе.
- Wave-2 анимации героев.
- RO status window / hotbar / skill `[-]`.
- Переименование умений под текст на макете (имена остаются из `SkillsCatalog`).

## 6. Файлы (ориентир)

- Переписать layout: `lib/hub/hub_shell.dart`
- Палитра/виджеты: `lib/hub/hub_theme.dart`
- Вкладки: `hub_home_tab.dart`, `stats_screen.dart`, `skills_screen.dart`, `shop_screen.dart`, `create_hero_screen.dart`
- Тесты: `test/hub/hub_shell_test.dart`, `hub_theme_test.dart`, `hub_flow_test.dart` — обновить под dark UI / отсутствие overlay на stage

## 7. Acceptance

1. На landscape (напр. 1280×720) в hub видны **и** `town_bg`, **и** спрайт героя; правая панель их не перекрывает.
2. Active tab и «В поля» — оранжевый акцент; фон панели тёмный.
3. Нет cream panel как основного look.
4. `flutter test` зелёный.
5. Debug APK обновлён на release `midgard-debug-apk` после реализации.

## 8. Связь с предыдущей спекой

`2026-08-07-midgard-outpost-art-hub-canon-design.md` §4 остаётся целью кадра E; эта спека уточняет **как** чинить расхождение после cream restyle: только layout A, без полного clone B.
