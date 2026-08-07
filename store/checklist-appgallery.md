# Чеклист публикации — Huawei App Gallery

Package ID: `com.midgard.outpost.midgard_outpost` · версия: `1.0.0+1` (проверить `pubspec.yaml` / Gradle перед загрузкой).

## Аккаунт и приложение

- [ ] Аккаунт Huawei Developer / AppGallery Connect активен
- [ ] Создано приложение «Мидгард: Аванпост» в консоли
- [ ] Контакт разработчика указан (email / телефон)

## Графика и медиа

- [ ] Иконка 512×512 PNG (`store/icons/ic_launcher_512.png`) загружена в консоль
- [ ] Mipmap-иконки в APK/AAB (mdpi–xxxhdpi из master 512)
- [ ] ≥4 landscape-скриншота 1920×1080 (`store/screenshots/01_hub.png` …)
- [ ] Скриншоты с русским UI / подписями

## Тексты витрины (RU)

- [ ] Название: **Мидгард: Аванпост** (из `store/listing.ru.md`)
- [ ] Краткое описание — скопировать из `store/listing.ru.md`
- [ ] Полное описание — скопировать из `store/listing.ru.md`
- [ ] «Что нового» (1.0.0) — скопировать из `store/listing.ru.md`
- [ ] Ключевые слова — из `store/listing.ru.md`

## Метаданные

- [ ] Категория: **Игры → Экшен / Аркада**
- [ ] Возрастной рейтинг: **для всех / 0+** (пиксельный фэнтези-бой без жестокого контента; финальный рейтинг — по форме стора)
- [ ] **Privacy policy URL** — ⚠️ **БЛОКЕР:** URL политики конфиденциальности ещё не опубликован; без него публикация невозможна
- [ ] `versionName` / `versionCode` согласованы с билдом (`1.0.0+1` или актуальные)

## Сборка и загрузка

- [ ] Release APK или AAB собран и подписан (upload keystore — вне репозитория)
- [ ] APK/AAB загружен в AppGallery Connect
- [ ] Тестовые аккаунты / internal testing настроены
- [ ] Отправлено на review

## Вне этого прохода

- [ ] IAP products в AppGallery Connect (`crystals_100`, `crystals_550`, бусты) — **позже / не в MVP-витрине**
- [ ] Подключение `AppGalleryBillingPort` (SDK + credentials)
- [ ] Облачный сейв через Huawei Account Kit
