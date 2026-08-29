# Как скачать с GitHub и запустить (Windows)

Нужен **другой компьютер на Windows**. Игра — оконный или borderless, не exclusive fullscreen.

Автоматизация может нарушать правила Hero Siege.

## 1. Скачать файлы

Самый простой способ — ZIP ветки (там и AHK, и Python):

1. Открой в браузере:  
   https://github.com/SwaTik91/test/archive/refs/heads/cursor/hero-siege-ahk-autopots-7f21.zip
2. Распакуй архив (ПКМ → «Извлечь всё»).
3. Зайди в папку:  
   `test-cursor-hero-siege-ahk-autopots-7f21\tools\hero-siege-autopots`

Либо со страницы пулл-реквеста:  
https://github.com/SwaTik91/test/pull/15  
→ зелёная **Code** → **Download ZIP** (скачается эта ветка).

Если установлен Git:

```text
git clone -b cursor/hero-siege-ahk-autopots-7f21 https://github.com/SwaTik91/test.git
cd test\tools\hero-siege-autopots
```

## 2. Поставить программы

### AutoHotkey v2 (банки)

1. https://www.autohotkey.com/ — качай **v2**, не v1.
2. Установи как обычно.

### Python (ходьба по карте)

1. https://www.python.org/downloads/windows/
2. В установщике **обязательно галочка «Add python.exe to PATH»**.
3. Дальше «Install Now».

Проверка: Win+R → `cmd` → Enter:

```text
python --version
```

Должно быть 3.10 или новее (3.11 / 3.12 — нормально).

## 3. Библиотеки для фарма

В `cmd`:

```text
cd путь\к\hero-siege-autopots\python-farm
pip install -r requirements.txt
```

Если `pip` не находится:

```text
python -m pip install -r requirements.txt
```

Закрой OBS, Xbox Game Bar, Discord overlay — они занимают DXGI (захват экрана).

## 4. Запуск пот (AHK)

1. Повесь в игре банки: **1** = HP, **2** = MP (или другие — потом F10).
2. Если Hero Siege запущен **от администратора**, `HeroSiegeAutoPots.ahk` тоже запускай от администратора (ПКМ → «Запуск от имени администратора»).
3. Двойной клик по  
   `tools\hero-siege-autopots\HeroSiegeAutoPots.ahk`
4. Кликни окно игры (полное HP) → **F6** (найти HP). По желанию **F7** — мана.
5. **F8** — включить автопоты.

**F4 в AHK не нажимай.** Ходьбой занимается Python.

Стоп пот: F8 ещё раз. Выход: **Shift+Esc**.

## 5. Запуск фарма (Python)

Игра в фокусе, ты **в данже**, миникарта включена (**M**).

`cmd`:

```text
cd путь\к\hero-siege-autopots\python-farm
python farm.py --debug
```

(окно сетки: белое = стена, чёрное = туман, жёлтое = путь)

1. Наведи мышь на **левый верхний** угол самой миникарты (внутри рамки) → **F3**.
2. Наведи на **правый нижний** → **F3**.
3. **F4** — ходьба. Ещё раз F4 — стоп.
4. **Shift+Esc** — закрыть python.

Окно игры должно быть активным. Иначе скрипт не жмёт клавиши.

## Если не работает

| Симптом | Что сделать |
|--------|-------------|
| `python` не является командой | Переустанови Python с галочкой PATH, закрой и открой `cmd` заново |
| `pip` не находится | `python -m pip install -r requirements.txt` |
| AHK: Property is read-only / старый скрипт | Нужен файл из **этого** ZIP, не старая копия из Downloads |
| Цвет HP всегда 3F3949 | Это норма для GDI. Нужен dxgi. Закрой OBS / Game Bar, перезапусти AHK |
| dxcam не ставится | `pip install mss` — хуже на DirectX, лучше починить dxcam |
| Python не видит карту | Калибруй F3 ближе к самой карте, не захватывай золотую рамку HUD |
| Персонаж дёргается | Выключи F4 в AHK, ходьбу оставь только python |
| Клавиши не доходят | Игра и скрипты от администратора — оба или никто |

## Клавиши кратко

**AHK:** F6 HP, F7 MP, F8 поты, F10 настройки, Shift+Esc выход.

**Python:** F3 два угла карты, F4 ходьба, Shift+Esc выход.
