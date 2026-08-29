# Hero Siege — фарм по миникарте (Python)

Ищет путь **A\*** по снимку миникарты: белые линии = стены, тёмное = туман, цветное = пол. Жмёт WASD (или стрелки). Это не чтение памяти.

Банки — в `HeroSiegeAutoPots.ahk` (F6/F8). Если AHK тоже запущен, **не жми F4 в AHK**: оба скрипта начнут жать ходьбу.

Автоматизация может нарушать правила игры.

## Windows (A*)

```text
pip install -r requirements.txt
python farm.py --debug
```

Если в игре ходишь **стрелками**, а WASD — скиллы:

```text
python farm.py --debug --keys arrows
```

Окно сетки: белое = стена, чёрное = туман, жёлтый = путь, **красная точка = герой**. Если красная точка не на тебе — калибровка или цвет иконки не те.

1. Игра в фокусе, данж, миникарта **M**.
2. Наведи на левый верхний угол **самой карты** (не золотая рамка HUD) → **F3**.
3. Правый нижний → **F3**.
4. **F4** — ходьба. Ещё раз F4 — стоп. **Shift+Esc** — выход.

Координаты карты пишутся в `farm.json` рядом со скриптом.

`dxcam` — тот же DXGI, что в AHK. Если не ставится, останется `mss` (на DirectX часто слепой).

## Маленькая модель с YouTube

Клавиш в ролике нет: скрипт режет кадры, ищет миникарту справа сверху и ставит метку WASD по движению иконки / сдвигу карты.

Нужны ролики, где **миникарта видна** (не закрыта вебкамерой), лучше данж, не хаб.

```text
pip install -r requirements.txt
python from_youtube.py "https://www.youtube.com/watch?v=XXXX" "https://youtu.be/YYYY"
python train.py recordings/yt_dataset.npz
python farm.py --debug --policy walk.npz
```

Видео в git не кладём.

## Тесты (любая ОС)

```text
python test_nav.py
python test_policy.py
python test_youtube.py
```
