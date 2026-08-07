# Мидгард: Аванпост — Art Wave 2 (анимации)

Связано с: `docs/superpowers/specs/2026-08-07-midgard-outpost-art-design.md` (волна 1 — статика).

## 1. Цель

Добавить покадровые пиксель-анимации для забега: герои, мобы/босс, сундук и простые VFX скиллов — без перехода на sprite sheets.

## 2. Решения

| Параметр | Выбор |
|----------|--------|
| Объём | Герои idle/run/jump/cast; моб+босс walk/hurt; сундук open; 3 VFX |
| Формат кадров | Отдельные PNG на кадр |
| Движок | Flame `SpriteAnimation` / `SpriteAnimationComponent` |
| Размеры | Герои/моб/сундук/VFX база 64×64; босс 96×96 |
| Scale | Nearest-neighbor (`FilterQuality.none` / Flame default paint) |
| Fallback | Статичные спрайты волны 1, если анимация не загрузилась |

## 3. Подход

**Отдельные кадры PNG + Flame SpriteAnimation** — проще генерировать и править кадры по одному; `AnimationAtlas` описывает списки путей и stepTime.

## 4. Структура файлов

```
assets/images/
  heroes/archer/{idle_0,idle_1,run_0..3,jump_0,jump_1,cast_0..2}.png
  heroes/mage/…   (то же)
  heroes/paladin/… (то же)
  enemies/goblin/{walk_0..2,hurt_0,hurt_1}.png
  enemies/ogre/{walk_0..2,hurt_0,hurt_1}.png
  props/chest/{open_0,open_1,open_2}.png
  vfx/{slash_0..2,flame_0..2,holy_0..2}.png
```

Статичные `heroes/archer.png` и т.д. из волны 1 **остаются** как fallback / иконки.

## 5. Таблица анимаций

### 5.1 Герои (каждый класс)

| Имя | Кадры | stepTime (старт) | Триггер |
|-----|-------|------------------|---------|
| idle | 2 | 0.35s | на земле, горизонтальная скорость ≈ 0 |
| run | 4 | 0.10s | на земле, есть движение |
| jump | 2 | 0.12s | `!isGrounded` |
| cast | 3 | 0.08s | при касте авто-скилла или ульта (одноразовая, потом возврат) |

### 5.2 Моб (goblin)

| Имя | Кадры | stepTime | Триггер |
|-----|-------|----------|---------|
| walk | 3 | 0.12s | жив, двигается |
| hurt | 2 | 0.08s | после `takeDamage` (короткий one-shot) |

### 5.3 Босс (ogre)

| Имя | Кадры | stepTime | Триггер |
|-----|-------|----------|---------|
| walk | 3 | 0.14s | жив |
| hurt | 2 | 0.08s | после урона |

### 5.4 Сундук

| Имя | Кадры | stepTime | Триггер |
|-----|-------|----------|---------|
| open | 3 | 0.10s | при подборе / открытии оффера; loop: false, остаётся на последнем кадре |

### 5.5 VFX

| ID | Кадры | Назначение |
|----|-------|------------|
| `slash` | 3 | физ/лучник/паладин ближний след |
| `flame` | 3 | маг / огненные скиллы |
| `holy` | 3 | паладин holy / ульт |

Спавнятся как короткоживущий `SpriteAnimationComponent` у цели или у игрока; удаляются по окончании анимации.

## 6. Код

- `lib/art/animation_atlas.dart` — пути кадров, `stepTime`, хелперы `heroAnim(classId, name)`, `loadAnimation(...)`.
- `PlayerComponent` — переключение idle/run/jump/cast по состоянию.
- `MonsterComponent` — walk + hurt one-shot.
- `ChestComponent` — open one-shot при collect.
- `MidgardRunGame` / auto-skill apply — спавн VFX по классу/скиллу.
- Тесты: пути анимаций существуют (`rootBundle`); логика выбора состояния героя (pure helper) покрыта unit-тестом.

## 7. Пайплайн ассетов

1. Генерация кадров в том же RO-light пиксель-стиле, что волна 1 (силуэт класса узнаваем).
2. PIL: RGBA, NEAREST resize до целевого размера, проверка alpha.
3. Коммит пачками: герои → враги/сундук → VFX → wiring.

## 8. Вне скоупа

- Полные attack combos / death animations
- Sprite sheets
- Анимации UI кнопок
- Смена направления (flip) кроме текущего facing

## 9. Критерий готовности

- В забеге видны run/jump у героя, walk у моба/босса, open у сундука, вспышка VFX при скилле.
- `flutter test` зелёный.
- Статичные ассеты волны 1 не ломаются как fallback.
